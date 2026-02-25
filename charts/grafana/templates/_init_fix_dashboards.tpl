{{/*
  Init container: 将 provisioning 的 dashboard 设为可编辑，并从 JSON 中移除指定变量（如 $pod、$monitor）。
  需在 init-grafana-ds-dh 之后执行，故在 extraInitContainers 之后渲染。
*/}}
{{- define "grafana.initFixDashboards" -}}
- name: fix-grafana-dashboards-provisioning
  image: python:3-alpine
  imagePullPolicy: IfNotPresent
  env:
  - name: REMOVE_VARS
    value: {{ (.Values.dashboardProvisioning.removeVariables | default list) | join "," | quote }}
  - name: REMOVE_WHERE_KEYS
    value: {{ (.Values.dashboardProvisioning.removeWhereKeys | default list) | join "," | quote }}
  - name: ALLOW_UI_UPDATES
    value: {{ (.Values.dashboardProvisioning.allowUiUpdates | default true) | quote }}
  command: ["python3", "-c"]
  args:
  - |
    import json, os, re, sys
    from pathlib import Path

    print("=== Fix Grafana dashboard provisioning ===")

    allow_ui_updates = os.environ.get("ALLOW_UI_UPDATES", "true").strip().lower() == "true"
    remove_names = set(n.strip() for n in os.environ.get("REMOVE_VARS", "").split(",") if n.strip())
    # 只删硬编码值（isVariable!=true）的 WHERE 条件，不影响同字段的变量引用
    remove_where_keys = set(n.strip() for n in os.environ.get("REMOVE_WHERE_KEYS", "").split(",") if n.strip())

    # ── 1) provisioning provider yaml: allowUiUpdates → true ──────────────
    if allow_ui_updates:
        prov_dir = Path("/etc/grafana/provisioning/dashboards")
        files = (list(prov_dir.glob("*.yaml")) + list(prov_dir.glob("*.yml"))) if prov_dir.exists() else []
        for f in files:
            try:
                content = f.read_text(encoding="utf-8")
                new_content = re.sub(r'allowUiUpdates:\s*\S+', 'allowUiUpdates: true', content)
                if new_content != content:
                    f.write_text(new_content, encoding="utf-8")
                    print("Updated allowUiUpdates:", f)
                else:
                    print("No change needed:", f)
            except Exception as e:
                print("Error processing", f, ":", e)

    # ── 2) 处理 dashboard JSON ─────────────────────────────────────────────
    if not remove_names and not remove_where_keys:
        print("REMOVE_VARS and REMOVE_WHERE_KEYS both empty, skip")
        print("=== Fix done ===")
        sys.exit(0)

    def should_remove_where(where_item):
        """判断一个 WHERE 条件是否需要删除：
        1. val 里有 isVariable=True 且 value 在 remove_names 中 → 删（变量引用条件）
        2. key 在 remove_where_keys 中，且 val 里没有任何 isVariable=True → 删（硬编码条件）
           注意：同一字段如果在别的 dashboard 里是变量引用（isVariable=True），则不会被删。
        """
        val = where_item.get("val")
        key = where_item.get("key", "")
        # 规则1：变量引用（removeVariables）
        if isinstance(val, list):
            for v in val:
                if isinstance(v, dict) and v.get("isVariable") and v.get("value") in remove_names:
                    return True
        # 规则2：硬编码 WHERE 条件（removeWhereKeys），只有 val 里完全没有 isVariable=True 才删
        if key in remove_where_keys:
            has_variable = False
            if isinstance(val, list):
                for v in val:
                    if isinstance(v, dict) and v.get("isVariable"):
                        has_variable = True
                        break
            if not has_variable:
                return True
        return False

    def fix_query_text(query_text_str):
        """解析 queryText JSON 字符串，删除 where 中需要移除的条件，返回新字符串。"""
        try:
            q = json.loads(query_text_str)
        except Exception:
            return query_text_str, False
        where = q.get("where")
        if not isinstance(where, list):
            return query_text_str, False
        new_where = [w for w in where if not should_remove_where(w)]
        if len(new_where) == len(where):
            return query_text_str, False
        q["where"] = new_where
        return json.dumps(q, ensure_ascii=False, separators=(',', ':')), True

    def fix_panels(panels):
        """递归处理 panels（兼容 row 类型的嵌套 panels）。"""
        changed = False
        for panel in panels:
            # row 面板内嵌 panels
            sub = panel.get("panels")
            if isinstance(sub, list):
                changed |= fix_panels(sub)
            for target in panel.get("targets", []):
                qt = target.get("queryText")
                if not isinstance(qt, str):
                    continue
                new_qt, c = fix_query_text(qt)
                if c:
                    target["queryText"] = new_qt
                    changed = True
        return changed

    dash_dir = Path("/tmp/dashboards")
    if not dash_dir.exists():
        print("Dashboard dir not found, skip")
        print("=== Fix done ===")
        sys.exit(0)

    var_count = 0
    query_count = 0
    for path in dash_dir.rglob("*.json"):
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                data = json.load(f)
        except Exception as e:
            print("Skip (invalid json):", path, e)
            continue

        file_changed = False

        # 2a) 删除 templating.list 中的变量定义
        tmpl = data.get("templating")
        if isinstance(tmpl, dict) and isinstance(tmpl.get("list"), list):
            before = len(tmpl["list"])
            tmpl["list"] = [v for v in tmpl["list"] if v.get("name") not in remove_names]
            if len(tmpl["list"]) != before:
                var_count += 1
                file_changed = True
                print("Removed var def:", path.name)

        # 2b) 删除 panel targets queryText 中 where 里对应的过滤条件
        panels = data.get("panels")
        if isinstance(panels, list):
            if fix_panels(panels):
                query_count += 1
                file_changed = True
                print("Removed where conditions:", path.name)

        if file_changed:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Done: {var_count} dashboards had var defs removed, {query_count} had where conditions removed")
    print("=== Fix done ===")
  volumeMounts:
  - name: sc-dashboard-volume
    mountPath: /tmp/dashboards
  - name: grafana-dashboards-config
    mountPath: /etc/grafana/provisioning/dashboards
{{- end -}}

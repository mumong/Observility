{{/*
  Sidecar 容器：Grafana 启动后通过 API 修复数据库里存储的 dashboard（DB 版本）。
  解决问题：DeepFlow init 写入文件后 Grafana 加载到 DB，或用户在 UI 复制/保存的 dashboard，
  这些无法通过 init 容器（文件操作）修复，需要在 Grafana 就绪后调用 API 处理。
*/}}
{{- define "grafana.sidecarFixDashboards" -}}
- name: fix-grafana-db-dashboards
  image: xnet.registry.io:8443/observability/python:3-alpine
  imagePullPolicy: IfNotPresent
  env:
  - name: REMOVE_VARS
    value: {{ (.Values.dashboardProvisioning.removeVariables | default list) | join "," | quote }}
  - name: REMOVE_WHERE_KEYS
    value: {{ (.Values.dashboardProvisioning.removeWhereKeys | default list) | join "," | quote }}
  - name: GF_URL
    value: "http://localhost:3000"
  - name: GF_USER
    valueFrom:
      secretKeyRef:
        name: {{ include "grafana.fullname" . }}
        key: admin-user
  - name: GF_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ include "grafana.fullname" . }}
        key: admin-password
  command: ["python3", "-c"]
  args:
  - |
    import json, os, sys, time, urllib.request, urllib.error

    GF_URL      = os.environ.get("GF_URL", "http://localhost:3000")
    GF_USER     = os.environ.get("GF_USER", "admin")
    GF_PASSWORD = os.environ.get("GF_PASSWORD", "admin")
    remove_names      = set(n.strip() for n in os.environ.get("REMOVE_VARS", "").split(",") if n.strip())
    remove_where_keys = set(n.strip() for n in os.environ.get("REMOVE_WHERE_KEYS", "").split(",") if n.strip())

    if not remove_names and not remove_where_keys:
        print("Nothing to fix, exit")
        sys.exit(0)

    import base64
    token = base64.b64encode(f"{GF_USER}:{GF_PASSWORD}".encode()).decode()
    headers = {"Authorization": f"Basic {token}", "Content-Type": "application/json"}

    def api(method, path, body=None):
        url = GF_URL + path
        data = json.dumps(body).encode() if body else None
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=10) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            print(f"HTTP {e.code} {method} {path}: {e.read().decode()[:200]}")
            return None
        except Exception as e:
            print(f"Error {method} {path}: {e}")
            return None

    # ── 等待 Grafana 就绪 ─────────────────────────────────────────────────
    print("Waiting for Grafana to be ready...")
    for i in range(60):
        try:
            req = urllib.request.Request(GF_URL + "/api/health", headers=headers)
            with urllib.request.urlopen(req, timeout=5) as r:
                health = json.loads(r.read())
                if health.get("database") == "ok":
                    print("Grafana is ready")
                    break
        except Exception:
            pass
        time.sleep(3)
    else:
        print("Grafana not ready after 3 minutes, exit")
        sys.exit(1)

    # ── 辅助：判断 WHERE 条件是否需要删除 ────────────────────────────────
    def should_remove_where(w):
        val = w.get("val")
        key = w.get("key", "")
        if isinstance(val, list):
            for v in val:
                if isinstance(v, dict) and v.get("isVariable") and v.get("value") in remove_names:
                    return True
        if key in remove_where_keys:
            has_var = any(isinstance(v, dict) and v.get("isVariable") for v in (val if isinstance(val, list) else []))
            if not has_var:
                return True
        return False

    def fix_query_text(qt_str):
        try:
            q = json.loads(qt_str)
        except Exception:
            return qt_str, False
        where = q.get("where")
        if not isinstance(where, list):
            return qt_str, False
        new_where = [w for w in where if not should_remove_where(w)]
        if len(new_where) == len(where):
            return qt_str, False
        q["where"] = new_where
        return json.dumps(q, ensure_ascii=False, separators=(",", ":")), True

    def fix_panels(panels):
        changed = False
        for panel in panels:
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

    def fix_dashboard(dash):
        changed = False
        # 1) templating.list
        tmpl = dash.get("templating")
        if isinstance(tmpl, dict) and isinstance(tmpl.get("list"), list):
            before = len(tmpl["list"])
            tmpl["list"] = [v for v in tmpl["list"] if v.get("name") not in remove_names]
            if len(tmpl["list"]) != before:
                changed = True
        # 2) panel queryText where
        panels = dash.get("panels")
        if isinstance(panels, list):
            changed |= fix_panels(panels)
        return changed

    # ── 遍历所有 dashboard ────────────────────────────────────────────────
    dashboards = api("GET", "/api/search?type=dash-db&limit=5000") or []
    print(f"Found {len(dashboards)} dashboards in DB")

    fixed = skipped_provisioned = 0
    for item in dashboards:
        uid   = item.get("uid")
        title = item.get("title", "")
        if not uid:
            continue

        result = api("GET", f"/api/dashboards/uid/{uid}")
        if not result:
            continue

        dash       = result.get("dashboard", {})
        meta       = result.get("meta", {})
        folder_id  = result.get("folderId", 0)
        folder_uid = result.get("folderUid", "")

        # 跳过 Provisioned dashboard：它们已由 init 容器（文件修改）处理，
        # 且 API 不允许直接保存 provisioned dashboard（返回 400）。
        if meta.get("provisioned"):
            skipped_provisioned += 1
            continue

        if not fix_dashboard(dash):
            continue

        payload = {
            "dashboard": dash,
            "folderId":  folder_id,
            "folderUid": folder_uid,
            "overwrite": True,
            "message":   "auto-fix: removed unused variables/where conditions"
        }
        save = api("POST", "/api/dashboards/db", payload)
        if save and save.get("status") == "success":
            print(f"Fixed: [{title}] uid={uid}")
            fixed += 1
        else:
            print(f"Failed to save [{title}]: {save}")

    print(f"Done: fixed {fixed} non-provisioned dashboards via API (skipped {skipped_provisioned} provisioned)")

    # ── 保持容器运行，避免 Kubernetes 因退出而不断重启 ───────────────────
    print("Fix complete, sleeping to prevent restart loop...")
    while True:
        time.sleep(3600)
{{- end -}}

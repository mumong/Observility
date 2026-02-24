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
  - name: ALLOW_UI_UPDATES
    value: {{ (.Values.dashboardProvisioning.allowUiUpdates | default true) | quote }}
  command: ["python3", "-c"]
  args:
  - |
    import json, os, re, sys
    from pathlib import Path

    print("=== Fix Grafana dashboard provisioning ===")

    allow_ui_updates = os.environ.get("ALLOW_UI_UPDATES", "true").strip().lower() == "true"
    remove_names = [n.strip() for n in os.environ.get("REMOVE_VARS", "").split(",") if n.strip()]

    # 1) 将 provisioning 中所有 provider yaml 的 allowUiUpdates 设为 true
    if allow_ui_updates:
        prov_dir = Path("/etc/grafana/provisioning/dashboards")
        files = list(prov_dir.glob("*.yaml")) + list(prov_dir.glob("*.yml")) if prov_dir.exists() else []
        for f in files:
            try:
                content = f.read_text(encoding="utf-8")
                new_content = re.sub(r'allowUiUpdates:\s*\S+', 'allowUiUpdates: true', content)
                if new_content != content:
                    f.write_text(new_content, encoding="utf-8")
                    print("Updated allowUiUpdates in", f)
                else:
                    print("No change needed in", f)
            except Exception as e:
                print("Error processing", f, ":", e)

    # 2) 从所有 dashboard JSON 中移除指定变量
    if not remove_names:
        print("REMOVE_VARS empty, skip variable removal")
        print("=== Fix done ===")
        sys.exit(0)

    dash_dir = Path("/tmp/dashboards")
    if not dash_dir.exists():
        print("Dashboard dir not found, skip")
        print("=== Fix done ===")
        sys.exit(0)

    count = 0
    for path in dash_dir.rglob("*.json"):
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                data = json.load(f)
        except Exception as e:
            print("Skip (invalid json):", path, e)
            continue
        tmpl = data.get("templating")
        if not isinstance(tmpl, dict):
            continue
        var_list = tmpl.get("list")
        if not isinstance(var_list, list):
            continue
        filtered = [v for v in var_list if v.get("name") not in remove_names]
        if len(filtered) != len(var_list):
            tmpl["list"] = filtered
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            count += 1
            print("Removed variables from:", path)

    print("Updated", count, "dashboard(s)")
    print("=== Fix done ===")
  volumeMounts:
  - name: sc-dashboard-volume
    mountPath: /tmp/dashboards
  - name: grafana-dashboards-config
    mountPath: /etc/grafana/provisioning/dashboards
{{- end -}}

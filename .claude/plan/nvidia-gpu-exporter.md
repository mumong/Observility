# nvidia-gpu-exporter 融入规划

## 目标
将独立的 nvidia-gpu-exporter chart 融入主 observability chart 的 `customer` 体系下，遵循现有组件模式，不影响任何已有文件。

## 融合规律总结（供未来新组件参考）

1. **values.yaml**：在 `customer:` 下新增 `<组件名>:` 节点，首行 `enabled: true/false`
2. **templates**：在 `templates/customer/<组件名>/` 下创建模板文件
3. **双层 if 守卫**：`{{- if .Values.customer.enabled }}` + `{{- if .Values.customer.<组件名>.enabled }}`
4. **镜像本地化**：`xnet.registry.io:8443/observability/<原始镜像路径>:<tag>`
5. **Values 引用路径**：原 `.Values.xxx` → `.Values.customer.<组件名>.xxx`
6. **Labels**：复用 `monitoring-stack.labels` + `app.kubernetes.io/component: <组件名>`
7. **命名**：`{{ include "monitoring-stack.fullname" . }}-<组件名>`

## 需要创建的文件（全部新增，零修改已有文件）

### 1. `templates/customer/nvidia-gpu-exporter/_helpers.tpl`
- 定义 nvidia-gpu-exporter 专用 helper（fullname、serviceAccountName 等）
- 基于 `monitoring-stack.fullname` 拼接 `-nvidia-gpu-exporter` 后缀

### 2. `templates/customer/nvidia-gpu-exporter/daemonset.yaml`
- DaemonSet 部署，从原始 daemonset.yaml 改造
- 镜像：`xnet.registry.io:8443/observability/utkuozdemir/nvidia_gpu_exporter:{{ tag }}`
- 所有 `.Values.xxx` → `.Values.customer.nvidiaGpuExporter.xxx`
- 双层 if 守卫

### 3. `templates/customer/nvidia-gpu-exporter/service.yaml`
- Service 资源

### 4. `templates/customer/nvidia-gpu-exporter/serviceaccount.yaml`
- ServiceAccount（可选创建）

### 5. `templates/customer/nvidia-gpu-exporter/servicemonitor.yaml`
- Prometheus ServiceMonitor（可选启用）

### 6. `values.yaml` 追加
在 `customer:` 节点末尾追加 `nvidiaGpuExporter:` 配置块：
```yaml
  nvidiaGpuExporter:
    enabled: false
    image:
      repository: xnet.registry.io:8443/observability/utkuozdemir/nvidia_gpu_exporter
      tag: "1.2.0"
      pullPolicy: IfNotPresent
    serviceAccount:
      create: true
      name: ""
    securityContext:
      privileged: true
    service:
      type: ClusterIP
      port: 9835
    port: 9835
    hostPort:
      enabled: false
      port: 9835
    log:
      level: info
      format: logfmt
    queryFieldNames:
      - AUTO
    nvidiaSmiCommand: nvidia-smi
    telemetryPath: /metrics
    resources: {}
    nodeSelector: {}
    tolerations: []
    affinity: {}
    volumes: [...]
    volumeMounts: [...]
    serviceMonitor:
      enabled: false
      additionalLabels: {}
      interval: ""
      scrapeTimeout: 10s
```

## 不创建的文件
- ingress.yaml — 原始 chart 中默认 disabled，GPU exporter 不需要 ingress
- NOTES.txt — 非必要
- tests/ — 非必要

## 验证方式
```bash
helm template test . --set customer.nvidiaGpuExporter.enabled=true | grep -A 50 nvidia-gpu-exporter
```

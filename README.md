# 统一可观测性平台

![版本: 1.0.2](https://img.shields.io/badge/版本-1.0.2-informational?style=flat-square) ![类型: application](https://img.shields.io/badge/类型-application-informational?style=flat-square)

企业级 Kubernetes 可观测性解决方案，整合指标、日志、分布式追踪和客户化数据服务，统一通过父层 `values.yaml` 管理。

## 项目说明

当前 Chart 的使用方式是：

- 直接安装当前目录，不需要额外预处理
- 正常安装命令仍然是 `helm install observability ./ -n xnet --create-namespace`
- 组件开关和配置统一从父层 `values.yaml` 控制
- 主要控制入口保持为 `metric.*`、`logging.*`、`tracing.*`、`customer.*`

这意味着即使底层包含原始子组件能力，日常使用时也只需要改父层参数，然后直接执行 Helm 命令即可。

## 架构组件

### 指标监控

- Prometheus Operator
- Grafana
- Alertmanager
- kube-state-metrics
- Prometheus Node Exporter
- Kepler

### 日志管理

- Elasticsearch 8.5.1
- Kibana 8.5.1
- Filebeat

### 分布式追踪

- DeepFlow v7.0
- ClickHouse 23.10
- MySQL 8.0.39
- ByConity

### 客户化服务

- API Server
- Data Service
- Telegraf
- InfluxDB v2

## 安装前准备

- Kubernetes 集群已经可用
- 本机已安装 Helm 3
- 集群节点能够拉取 `xnet.registry.io:8443/observability/*` 相关镜像
- 如果需要持久化存储，请提前确认默认 `StorageClass` 或在父层 `values.yaml` 中显式指定

## 安装

### 1. 默认安装

默认安装会使用仓库根目录的 `values.yaml`：

```bash
helm install observability ./ -n xnet --create-namespace
```

如果你希望安装或升级都复用同一条命令，建议直接使用：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace
```

### 2. 全组件安装

如果你要一次性把当前仓库中已经接入的组件全部打开，可以使用覆盖文件：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace -f observability-all-enabled.yaml
```

`observability-all-enabled.yaml` 只是额外覆盖，不会替代默认 `values.yaml`，最终生效结果是两者合并后的配置。

### 3. 自定义安装

你有两种常见方式：

方式一，直接修改根目录 [values.yaml](/root/test/observability/values.yaml)，然后安装：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace
```

方式二，单独准备自定义覆盖文件，例如 `custom-values.yaml`：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace -f custom-values.yaml
```

## 配置方式

当前建议只从父层参数入口控制，不直接改底层子组件默认文件。

常见控制方式示例：

```yaml
metric:
  grafana:
    enabled: true
    service:
      nodePort: 30300

logging:
  kibana:
    enabled: true
    service:
      type: NodePort
      nodePort: 30223

tracing:
  clickhouse:
    enabled: true
  byconity:
    enabled: false
  mysql:
    enabled: true
```

如果你要控制某个追踪子组件参数，直接在父层按对应路径配置即可，例如：

- `tracing.clickhouse.xxx`
- `tracing.byconity.xxx`
- `metric.grafana.xxx`
- `metric.kube-state-metrics.xxx`
- `logging.filebeat.xxx`
- `logging.kibana.xxx`

## 安装前检查

建议在正式安装前至少执行下面两个命令：

```bash
helm lint .
helm template observability ./ -n xnet > rendered.yaml
```

如果要验证全组件开启场景：

```bash
helm lint . -f observability-all-enabled.yaml
helm template observability ./ -n xnet -f observability-all-enabled.yaml > rendered-all.yaml
```

## 安装后验证

```bash
kubectl get pods -n xnet
kubectl get svc -n xnet
kubectl get pvc -n xnet
```

常见服务名示例：

- Grafana: `observability-grafana`
- Kibana: `observability-kibana`
- Alertmanager: `observability-alertmanager`
- DeepFlow App: `observability-deepflow-app`
- ClickHouse: `observability-clickhouse`
- MySQL: `observability-mysql`

例如访问 Grafana：

```bash
kubectl port-forward -n xnet svc/observability-grafana 3000:80
```

例如访问 Kibana：

```bash
kubectl port-forward -n xnet svc/observability-kibana 5601:5601
```

## 升级

如果你修改了父层 `values.yaml`，直接执行：

```bash
helm upgrade observability ./ -n xnet
```

如果你使用单独的覆盖文件：

```bash
helm upgrade observability ./ -n xnet -f custom-values.yaml
```

如果当前 release 还不存在，统一用下面这条最稳妥：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace -f custom-values.yaml
```

## 卸载

### 1. 卸载 Helm Release

```bash
helm uninstall observability -n xnet
```

注意，卸载命令中的 release 名必须和安装时保持一致。当前 README 中统一使用 `observability`，不是 `obs`。

### 2. 可选的资源清理

如果你需要把命名空间内的运行资源一并清掉，可以继续执行：

```bash
kubectl delete namespace xnet
```

如果你只想清理数据卷而保留命名空间：

```bash
kubectl delete pvc --all -n xnet
```

### 3. 关于 CRD

如果你启用了监控 CRD 相关能力，例如 `metric.crds.enabled=true`，那么集群级 CRD 是否需要删除要单独判断。

只有在下面条件同时满足时，才建议手动删除：

- 当前集群没有其他系统在复用这些 Prometheus Operator CRD
- 你确认要彻底清掉整套监控能力

否则不要直接删除集群级 CRD。

## 服务访问

默认值中常见访问端口包括：

- Grafana: `30300`
- Alertmanager: `30903`
- Kibana: `30223`
- DeepFlow App: `20418`
- API Server: `31520`
- InfluxDB: `31521`

访问地址形式通常为：

```text
http://<node-ip>:<nodePort>
```

## 参考文件

- 默认配置入口: [values.yaml](/root/test/observability/values.yaml)
- 全组件覆盖文件: [observability-all-enabled.yaml](/root/test/observability/observability-all-enabled.yaml)
- 历史渲染基线: [final.yaml](/root/test/observability/final.yaml)
- 子组件默认配置归档: [files](/root/test/observability/files)
- 子组件模板展开目录: [templates/childcharts](/root/test/observability/templates/childcharts)
- 原始 Chart 参考: [chart-sources](/root/test/observability/chart-sources)

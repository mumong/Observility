# 统一可观测性平台

![版本: 1.0.2](https://img.shields.io/badge/版本-1.0.2-informational?style=flat-square) ![类型: application](https://img.shields.io/badge/类型-application-informational?style=flat-square)

这是一个面向 Kubernetes 的统一可观测性 Helm Chart，用来把指标监控、日志管理、分布式追踪和客户化数据服务部署到同一套平台中，并统一通过根目录的 `values.yaml` 管理配置。

## 这个项目是做什么的

这个 Chart 用于在集群中部署一套完整的可观测性能力，常见用途包括：

- 采集和展示集群指标
- 收集和检索日志
- 提供分布式追踪能力
- 为客户化场景提供 API、Telegraf、InfluxDB 等数据服务

## 项目由什么组成

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

- DeepFlow
- ClickHouse
- MySQL
- ByConity

### 客户化服务

- API Server
- Data Service
- Telegraf
- InfluxDB v2

## 配置入口

日常使用时，主要通过根目录 [values.yaml](/root/huhu/helm-chart/modify-observability/values.yaml) 控制参数，常见入口如下：

- `metric.*`
- `logging.*`
- `tracing.*`
- `customer.*`

## 安装前准备

- Kubernetes 集群已经可用
- 本机已安装 Helm 3
- 集群节点能够拉取 `xnet.registry.io:8443/observability/*` 相关镜像
- 如需持久化，请提前确认默认 `StorageClass` 是否可用

建议先做一次渲染检查：

```bash
helm lint .
helm template observability ./ -n xnet > rendered.yaml
```

## 安装

下面的示例统一使用：

- Release 名：`observability`
- Namespace：`xnet`

### 1. 普通安装

普通安装直接使用仓库根目录默认配置：

```bash
helm install observability ./ -n xnet --create-namespace
```

### 2. 边缘测安装

边缘测场景通常由 Telegraf 把数据写到云侧已经存在的 InfluxDB 地址，因此重点是覆盖 `customer.dataservice.telegraf.config.global_tags.output`。

你现在使用的边缘测方式可以直接写成：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace \
  --set customer.dataservice.telegraf.config.global_tags.output=http://10.2.0.48:31521 \
  --set customer.dataservice.telegraf.config.global_tags.cluster=agent-cluster
```

如果还需要区分集群标识，也可以继续增加：

```bash
--set customer.dataservice.telegraf.config.global_tags.cluster_id=<cluster_id>
```

### 3. 云管测安装

云管测场景需要在当前集群内启用 InfluxDB，因此要打开 `customer.dataservice.influxdb2.enabled=true`。一个常见示例如下：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace \
  --set customer.dataservice.influxdb2.enabled=true \
  --set customer.dataservice.telegraf.config.global_tags.cluster=cloud-control \
  --set customer.dataservice.telegraf.config.global_tags.cluster_id=test-id \
  --set customer.dataservice.telegraf.config.global_tags.output=http://influxdb2.xnet.svc.cluster.local:8086
```

如果你已经在别的地方准备好了自定义参数文件，也可以使用：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace -f custom-values.yaml
```

## 安装后验证

```bash
kubectl get pods -n xnet
kubectl get svc -n xnet
kubectl get pvc -n xnet
```

常见访问端口：

- Grafana：`30300`
- Alertmanager：`30903`
- Kibana：`30223`
- DeepFlow App：`20418`
- API Server：`31520`
- InfluxDB：`31521`

访问方式通常为：

```text
http://<node-ip>:<nodePort>
```

例如访问 Grafana：

```bash
kubectl port-forward -n xnet svc/observability-grafana 3000:80
```

## 升级

如果只是调整参数，继续执行相同的 `helm upgrade --install` 命令即可。

例如：

```bash
helm upgrade --install observability ./ -n xnet --create-namespace -f custom-values.yaml
```

## 卸载

### 1. 卸载 Helm Release

```bash
helm uninstall observability -n xnet
```

卸载时 `observability` 必须和安装时使用的 Release 名保持一致。

### 2. 可选清理命名空间

如果你希望把命名空间一起删除：

```bash
kubectl delete namespace xnet
```

### 3. 可选清理持久化数据

如果只想清理 PVC，但保留命名空间：

```bash
kubectl delete pvc --all -n xnet
```

### 4. 关于 CRD

如果当前集群还有其他系统在复用 Prometheus Operator 相关 CRD，不要直接删除集群级 CRD。只有在你确认没有其他系统依赖这些 CRD 时，才建议单独清理。

## 参考文件

- 默认配置入口：[values.yaml](/root/huhu/helm-chart/modify-observability/values.yaml)
- Chart 元数据：[Chart.yaml](/root/huhu/helm-chart/modify-observability/Chart.yaml)
- 旧版说明参考：[README_chart.md](/root/huhu/helm-chart/modify-observability/README_chart.md)

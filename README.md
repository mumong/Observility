# 统一可观测性平台

![版本: 1.0.0](https://img.shields.io/badge/版本-1.0.0-informational?style=flat-square) ![类型: application](https://img.shields.io/badge/类型-application-informational?style=flat-square)

企业级 Kubernetes 可观测性解决方案，整合监控指标、日志管理、分布式追踪和客户化数据服务的一体化平台。

## 🎯 项目特点

- **一体化解决方案**: 集成 Prometheus、Grafana、Elasticsearch、DeepFlow 等业界领先组件
- **开箱即用**: 预配置的仪表盘、告警规则和数据收集器
- **灵活扩展**: 支持外部数据库和自定义配置
- **企业级特性**: 高可用、安全认证、多租户支持
- **客户化集成**: 内置 API 服务器和数据服务模块

## 🏗️ 架构组件

### 指标监控 (Metrics)
- **Prometheus Operator** - 自动化监控部署和管理
- **Grafana** - 数据可视化和仪表盘 (NodePort: 30300)
- **Alertmanager** - 告警聚合和通知 (NodePort: 30903)
- **kube-state-metrics** - Kubernetes 对象状态指标
- **Node Exporter** - 主机系统指标采集
- **Kepler** - 容器能效和资源监控

### 日志管理 (Logging)
- **Elasticsearch 8.5.1** - 日志存储和搜索引擎 (NodePort: 30988)
- **Kibana 8.5.1** - 日志可视化和分析 (NodePort: 30223)
- **Filebeat** - 轻量级日志收集器

### 分布式追踪 (Tracing)
- **DeepFlow v7.0** - 全栈可观测性平台
  - DeepFlow Server - 数据处理和查询服务
  - DeepFlow Agent - 分布式数据采集
  - DeepFlow App - 可视化应用 (NodePort: 20418)
- **ClickHouse 23.10** - 高性能时序数据库
- **MySQL 8.0.39** - 元数据存储

### 客户化服务 (Customer)
- **API Server** - RESTful API 服务 (NodePort: 31520)
- **Data Service** - 数据处理和分析服务
  - Telegraf - 指标收集和处理
  - InfluxDB v2 - 时序数据库 (NodePort: 31521)

## 🚀 快速开始

### 安装

```bash
# 安装到默认命名空间
helm install obs . -n xnet --create-namespace


```

### 验证安装

```bash
# 检查 Pod 状态
kubectl get pods -n xnet

# 检查服务
kubectl get svc -n xnet

# 查看 Grafana 仪表盘
kubectl port-forward -n xnet svc/obs-grafana 3000:80
```

### 卸载

```bash
helm uninstall obs -n xnet
```

## ⚙️ 重要配置

### 全局配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `global.timezone` | 时区设置 | `Asia/Shanghai` |
| `global.storageClass` | 存储类名 | `""` |
| `global.hostNetwork` | 主机网络模式 | `false` |

### 监控配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `metric.enabled` | 启用监控组件 | `true` |
| `metric.grafana.adminPassword` | Grafana 管理员密码 | `changeme` |
| `metric.grafana.service.nodePort` | Grafana 端口 | `30300` |
| `metric.prometheus.prometheusSpec.retention` | 数据保留时间 | `10d` |
| `metric.prometheus.prometheusSpec.replicas` | 副本数 | `1` |

### 日志配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `logging.enabled` | 启用日志组件 | `true` |
| `logging.elasticsearch.imageTag` | ES 版本 | `8.5.1` |
| `logging.elasticsearch.volumeClaimTemplate.resources.requests.storage` | ES 存储大小 | `30Gi` |
| `logging.kibana.service.nodePort` | Kibana 端口 | `30223` |

### 追踪配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `tracing.enabled` | 启用追踪组件 | `true` |
| `tracing.global.storageEngine` | 存储引擎 | `clickhouse` |
| `tracing.global.replicas` | 副本数 | `1` |
| `tracing.global.externalClickHouse.enabled` | 外部 ClickHouse | `false` |
| `tracing.global.externalMySQL.enabled` | 外部 MySQL | `false` |

### 客户化服务配置

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `customer.enabled` | 启用客户化服务 | `true` |
| `customer.apiserver.nodePort` | API 服务端口 | `31520` |
| `customer.dataservice.influxdb2.service.nodePort` | InfluxDB 端口 | `31521` |

## 🔗 服务访问

### Grafana
- **地址**: `http://<node-ip>:30300`
- **用户名**: `admin`
- **密码**: `changeme` (可在 values.yaml 中修改)

### Kibana
- **地址**: `http://<node-ip>:30223`

### Alertmanager
- **地址**: `http://<node-ip>:30903`

### DeepFlow App
- **地址**: `http://<node-ip>:20418`

### API Server
- **地址**: `http://<node-ip>:31520`

### InfluxDB
- **地址**: `http://<node-ip>:31521`

## 📊 默认仪表盘

预置的 Grafana 仪表盘包括：

- **Kubernetes 资源监控**
  - 集群总览
  - 节点资源使用
  - Pod 性能监控
  - 工作负载分析

- **系统组件监控**
  - API Server 状态
  - etcd 性能
  - 调度器监控
  - CoreDNS 监控

- **应用性能监控**
  - 容器资源使用
  - 网络流量分析
  - 存储性能监控

## 🔧 自定义配置

### 外部数据库集成

```yaml
# 使用外部 ClickHouse
tracing:
  global:
    externalClickHouse:
      enabled: true
      hosts: ["clickhouse.example.com"]
      username: "admin"
      password: "password"
      clusterName: "cluster"

# 使用外部 MySQL
tracing:
  global:
    externalMySQL:
      enabled: true
      ip: "mysql.example.com"
      port: 3306
      username: "admin"
      password: "password"
```

### 自定义告警规则

```yaml
metric:
  prometheus:
    additionalPrometheusRules:
      - name: custom-alerts
        groups:
          - name: custom.rules
            rules:
              - alert: HighCPUUsage
                expr: sum(rate(container_cpu_usage_seconds_total[5m])) by (pod) > 0.9
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Pod CPU usage > 90%"
```

### 存储配置

```yaml
# 配置持久化存储
logging:
  elasticsearch:
    volumeClaimTemplate:
      resources:
        requests:
          storage: 100Gi
      storageClass: "fast-ssd"

tracing:
  clickhouse:
    storageConfig:
      persistence:
        - name: clickhouse-path
          size: 200Gi
          storageClass: "fast-ssd"
```

## 🛠️ 故障排除

### 常见问题

1. **Pod 启动失败**
   ```bash
   kubectl describe pod <pod-name> -n xnet
   kubectl logs <pod-name> -n xnet
   ```

2. **存储卷挂载失败**
   - 检查 StorageClass 配置
   - 确认 PVC 状态

3. **网络连接问题**
   - 检查 Service 和 Endpoint 状态
   - 验证网络策略配置

### 性能优化

- 调整 Prometheus 数据保留时间
- 配置合适的资源限制和请求
- 使用 SSD 存储提升 I/O 性能
- 根据集群规模调整副本数

## 📝 版本信息

- **Chart 版本**: 1.0.0
- **应用版本**: 1.0.0
- **支持的 Kubernetes 版本**: 1.20+
- **Prometheus Operator**: v0.83.0
- **DeepFlow**: v7.0

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 📄 许可证

本项目采用 MIT 许可证。
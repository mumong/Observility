# 统一可观测性

![版本: 1.0.0](https://img.shields.io/badge/版本-1.0.0-informational?style=flat-square) ![类型: application](https://img.shields.io/badge/类型-application-informational?style=flat-square)

集成监控指标、日志和追踪的Kubernetes可观测性解决方案。

## 快速开始

```bash
helm install obs . -n observability --create-namespace
```

## 简介

本Chart整合了三大可观测性支柱：

- **指标监控**: 系统和应用性能监控
- **日志**: 集中式日志收集分析
- **分布式追踪**: 请求链路追踪

## 组件列表

### 指标监控
- Grafana - 数据可视化
- Kube-state-metrics - Kubernetes对象指标
- Node Exporter - 主机指标采集
- Prometheus operator
- Alertmanager
- Prometheus

### 日志
- Elasticsearch - 日志存储和搜索引擎
- Filebeat - 日志收集和转发
- Kibana - 日志可视化和分析

### 追踪
- DeepFlow - 全栈可观测性平台
  - ClickHouse - 高性能分析数据库
  - MySQL - 元数据存储
  - DeepFlow Agent - 分布式数据采集
  - DeepFlow Server 

## 安装

```bash
helm install obs . -n observability --create-namespace
```

## 卸载

```bash
helm uninstall obs -n observability
```

## 主要参数

### 指标监控配置

| 参数名称                              | 描述                              | 默认值  |
| ----------------------------------- | --------------------------------- | ------- |
| `metric.enabled`                | 启用监控组件                       | `true`  |
| `metric.grafana.enabled`        | 启用Grafana                       | `true`  |
| `metric.kube-state-metrics.enabled` | 启用kube-state-metrics        | `true`  |
| `metric.prometheus-node-exporter.enabled` | 启用node-exporter       | `true`  |

### 日志配置

| 参数名称                   | 描述                              | 默认值  |
| ------------------------ | --------------------------------- | ------- |
| `logging.enabled`        | 启用日志组件                       | `true`  |
| `logging.elasticsearch.enabled` | 启用Elasticsearch           | `true`  |
| `logging.filebeat.enabled` | 启用Filebeat                    | `true`  |
| `logging.kibana.enabled` | 启用Kibana                        | `true`  |

### 追踪配置

| 参数名称                         | 描述                           | 默认值  |
| ------------------------------ | ------------------------------ | ------- |
| `tracing.enabled`              | 启用追踪组件                    | `true`  |
| `tracing.clickhouse.enabled`   | 启用ClickHouse                 | `true`  |
| `tracing.mysql.enabled`        | 启用MySQL                      | `true`  |
| `tracing.deepflow-agent.enabled` | 启用DeepFlow agent          | `true`  |
| `tracing.grafana.enabled`      | 启用DeepFlow专用Grafana        | `true`  |

> 更多参数请参考`values.yaml`文件。

查看Pod日志：
```bash
kubectl logs -f <pod名称> -n observability
``` 
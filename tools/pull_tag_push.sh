#!/bin/bash
# pull_tag_push.sh
# 从外网 pull 所有镜像，tag 为内部仓库地址，push 到 xnet.registry.io:8443/observability/
# 覆盖 image.txt 中所有镜像 + final.yaml 中渲染出的镜像，确保未来开启任何组件都能用

set -uo pipefail

# 代理设置
export http_proxy=http://192.168.20.46:7890
export https_proxy=http://192.168.20.46:7890
export no_proxy=localhost,127.0.0.1,.example.com,xnet.registry.io

SUCCESS=0
FAIL=0
TOTAL=0

do_image() {
    local src="$1"
    local dst="$2"
    ((TOTAL++))
    echo "========================================"
    echo "[$TOTAL] $src"
    echo "    -> $dst"

    # pull
    if ! docker pull "$src" 2>&1 | tail -1; then
        echo "  [FAIL] pull 失败: $src"
        ((FAIL++))
        return
    fi

    # tag
    if ! docker tag "$src" "$dst"; then
        echo "  [FAIL] tag 失败"
        ((FAIL++))
        return
    fi

    # push (不走代理)
    if ! env http_proxy= https_proxy= docker push "$dst" 2>&1 | tail -1; then
        echo "  [FAIL] push 失败: $dst"
        ((FAIL++))
        return
    fi

    echo "  [OK]"
    ((SUCCESS++))

    # 清理
    docker rmi "$dst" &>/dev/null || true
}

echo "=== 开始 pull / tag / push 所有镜像 ==="
echo ""

# 1. final.yaml 中渲染出的 26 个镜像（带确切 tag）
do_image "quay.io/prometheus/alertmanager:v0.28.1" "xnet.registry.io:8443/observability/prometheus/alertmanager:v0.28.1"
do_image "quay.io/prometheus/prometheus:v3.4.1" "xnet.registry.io:8443/observability/prometheus/prometheus:v3.4.1"
do_image "quay.io/prometheus-operator/prometheus-operator:v0.83.0" "xnet.registry.io:8443/observability/prometheus-operator/prometheus-operator:v0.83.0"
do_image "busybox:latest" "xnet.registry.io:8443/observability/busybox:latest"
do_image "registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.5.4" "xnet.registry.io:8443/observability/ingress-nginx/kube-webhook-certgen:v1.5.4"
do_image "quay.io/sustainable_computing_io/kepler:release-0.8.0" "xnet.registry.io:8443/observability/sustainable_computing_io/kepler:release-0.8.0"
do_image "docker.elastic.co/elasticsearch/elasticsearch:8.5.1" "xnet.registry.io:8443/observability/elasticsearch/elasticsearch:8.5.1"
do_image "docker.elastic.co/kibana/kibana:8.5.1" "xnet.registry.io:8443/observability/kibana/kibana:8.5.1"
do_image "docker.elastic.co/beats/filebeat:8.5.1" "xnet.registry.io:8443/observability/beats/filebeat:8.5.1"
do_image "grafana/grafana:12.0.2" "xnet.registry.io:8443/observability/grafana/grafana:12.0.2"
do_image "curlimages/curl:8.9.1" "xnet.registry.io:8443/observability/curlimages/curl:8.9.1"
do_image "bats/bats:v1.4.1" "xnet.registry.io:8443/observability/bats/bats:v1.4.1"
do_image "alpine/git:latest" "xnet.registry.io:8443/observability/alpine/git:latest"
do_image "python:3-alpine" "xnet.registry.io:8443/observability/python:3-alpine"
do_image "quay.io/kiwigrid/k8s-sidecar:1.30.0" "xnet.registry.io:8443/observability/kiwigrid/k8s-sidecar:1.30.0"
do_image "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0" "xnet.registry.io:8443/observability/kube-state-metrics/kube-state-metrics:v2.15.0"
do_image "quay.io/prometheus/node-exporter:v1.9.1" "xnet.registry.io:8443/observability/prometheus/node-exporter:v1.9.1"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/clickhouse-server:23.10" "xnet.registry.io:8443/observability/clickhouse-server:23.10"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/mysql:8.0.39" "xnet.registry.io:8443/observability/mysql:8.0.39"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflow-agent:v7.0" "xnet.registry.io:8443/observability/deepflow-agent:v7.0"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflow-server:v7.0" "xnet.registry.io:8443/observability/deepflow-ce/deepflow-server:v7.0"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflow-app:v7.0" "xnet.registry.io:8443/observability/deepflow-ce/deepflow-app:v7.0"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflowio-init-grafana:v7.0" "xnet.registry.io:8443/observability/deepflow-ce/deepflowio-init-grafana:v7.0"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflowio-init-grafana-ds-dh:latest" "xnet.registry.io:8443/observability/deepflow-ce/deepflowio-init-grafana-ds-dh:latest"
do_image "telegraf:1.32-alpine" "xnet.registry.io:8443/observability/telegraf:1.32-alpine"
do_image "grafana/otel-lgtm:latest" "xnet.registry.io:8443/observability/grafana/otel-lgtm:latest"

# 2. image.txt 中额外的镜像（values 中定义但未被当前 helm template 渲染）
do_image "quay.io/prometheus-operator/prometheus-config-reloader:v0.83.0" "xnet.registry.io:8443/observability/prometheus-operator/prometheus-config-reloader:v0.83.0"
do_image "quay.io/thanos/thanos:v0.38.0" "xnet.registry.io:8443/observability/thanos/thanos:v0.38.0"
do_image "quay.io/brancz/kube-rbac-proxy:v0.19.1" "xnet.registry.io:8443/observability/brancz/kube-rbac-proxy:v0.19.1"
do_image "quay.io/sustainable_computing_io/kepler_model_server:v0.7.12" "xnet.registry.io:8443/observability/sustainable_computing_io/kepler_model_server:v0.7.12"
do_image "busybox:1.31.1" "xnet.registry.io:8443/observability/library/busybox:1.31.1"
do_image "influxdb:2.7.4-alpine" "xnet.registry.io:8443/observability/influxdb:2.7.4-alpine"
do_image "alpine:3.10.2" "xnet.registry.io:8443/observability/alpine:3.10.2"
do_image "foundationdb/fdb-kubernetes-operator:v1.9.0" "xnet.registry.io:8443/observability/fdb-kubernetes-operator:v1.9.0"
do_image "foundationdb/foundationdb-kubernetes-sidecar:6.2.30-1" "xnet.registry.io:8443/observability/foundationdb-kubernetes-sidecar:6.2.30-1"
do_image "foundationdb/foundationdb-kubernetes-sidecar:6.3.23-1" "xnet.registry.io:8443/observability/foundationdb-kubernetes-sidecar:6.3.23-1"
do_image "foundationdb/foundationdb-kubernetes-sidecar:7.1.15-1" "xnet.registry.io:8443/observability/foundationdb-kubernetes-sidecar:7.1.15-1"
do_image "gchq/hdfs:3.2.2" "xnet.registry.io:8443/observability/hdfs:3.2.2"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/byconity:1.0.0" "xnet.registry.io:8443/observability/byconity:1.0.0"
do_image "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflowio-stella-agent-ce:latest" "xnet.registry.io:8443/observability/deepflowio-stella-agent-ce:latest"

# 3. 已在内部仓库的镜像（只需 retag）
echo ""
echo "=== 处理内部仓库 retag ==="
SRC="xnet.registry.io:8443/apiserver/apiserver:v1.0"
DST="xnet.registry.io:8443/observability/apiserver:v1.0"
echo "[$((++TOTAL))] $SRC -> $DST"
# 这个不需要代理，从 containerd 导出
if docker image inspect "$SRC" &>/dev/null; then
    true
else
    ctr -n k8s.io images export /tmp/_apiserver.tar "$SRC" 2>/dev/null && docker load -i /tmp/_apiserver.tar 2>/dev/null && rm -f /tmp/_apiserver.tar
fi
if docker tag "$SRC" "$DST" 2>/dev/null && env http_proxy= https_proxy= docker push "$DST" 2>&1 | tail -1; then
    echo "  [OK]"
    ((SUCCESS++))
    docker rmi "$DST" &>/dev/null || true
else
    echo "  [FAIL]"
    ((FAIL++))
fi

echo ""
echo "========================================"
echo "=== 全部完成 ==="
echo "总计: $TOTAL | 成功: $SUCCESS | 失败: $FAIL"
if [ $FAIL -gt 0 ]; then
    echo "警告: 有 $FAIL 个镜像失败，请检查上方日志"
fi

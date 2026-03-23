#!/bin/bash
# retag_and_push.sh
# 从 containerd (crictl/ctr) 导出镜像，docker tag 为内部仓库地址，然后 push
# 用法: 在每个节点上执行 bash retag_and_push.sh

set -euo pipefail

TARGET_REGISTRY="xnet.registry.io:8443/observability"
TMPDIR_EXPORT="/tmp/image_retag_$$"
mkdir -p "$TMPDIR_EXPORT"

SUCCESS=0
FAIL=0
SKIP=0

# 所有需要迁移的镜像映射: "containerd中的原始镜像|目标镜像"
IMAGE_MAP=(
  # --- final.yaml 渲染出的镜像 ---
  "quay.io/prometheus/alertmanager:v0.28.1|${TARGET_REGISTRY}/prometheus/alertmanager:v0.28.1"
  "quay.io/prometheus/prometheus:v3.4.1|${TARGET_REGISTRY}/prometheus/prometheus:v3.4.1"
  "quay.io/prometheus-operator/prometheus-operator:v0.83.0|${TARGET_REGISTRY}/prometheus-operator/prometheus-operator:v0.83.0"
  "docker.io/library/busybox:latest|${TARGET_REGISTRY}/busybox:latest"
  "registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.5.4|${TARGET_REGISTRY}/ingress-nginx/kube-webhook-certgen:v1.5.4"
  "quay.io/sustainable_computing_io/kepler:release-0.8.0|${TARGET_REGISTRY}/sustainable_computing_io/kepler:release-0.8.0"
  "docker.elastic.co/elasticsearch/elasticsearch:8.5.1|${TARGET_REGISTRY}/elasticsearch/elasticsearch:8.5.1"
  "docker.elastic.co/kibana/kibana:8.5.1|${TARGET_REGISTRY}/kibana/kibana:8.5.1"
  "docker.elastic.co/beats/filebeat:8.5.1|${TARGET_REGISTRY}/beats/filebeat:8.5.1"
  "docker.io/grafana/grafana:12.0.2|${TARGET_REGISTRY}/grafana/grafana:12.0.2"
  "docker.io/curlimages/curl:8.9.1|${TARGET_REGISTRY}/curlimages/curl:8.9.1"
  "docker.io/bats/bats:v1.4.1|${TARGET_REGISTRY}/bats/bats:v1.4.1"
  "docker.io/alpine/git:latest|${TARGET_REGISTRY}/alpine/git:latest"
  "docker.io/library/python:3-alpine|${TARGET_REGISTRY}/python:3-alpine"
  "quay.io/kiwigrid/k8s-sidecar:1.30.0|${TARGET_REGISTRY}/kiwigrid/k8s-sidecar:1.30.0"
  "registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.15.0|${TARGET_REGISTRY}/kube-state-metrics/kube-state-metrics:v2.15.0"
  "quay.io/prometheus/node-exporter:v1.9.1|${TARGET_REGISTRY}/prometheus/node-exporter:v1.9.1"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/clickhouse-server:23.10|${TARGET_REGISTRY}/clickhouse-server:23.10"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/mysql:8.0.39|${TARGET_REGISTRY}/mysql:8.0.39"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflow-agent:v7.0|${TARGET_REGISTRY}/deepflow-agent:v7.0"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflow-server:v7.0|${TARGET_REGISTRY}/deepflow-ce/deepflow-server:v7.0"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflow-app:v7.0|${TARGET_REGISTRY}/deepflow-ce/deepflow-app:v7.0"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflowio-init-grafana:v7.0|${TARGET_REGISTRY}/deepflow-ce/deepflowio-init-grafana:v7.0"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflowio-init-grafana-ds-dh:latest|${TARGET_REGISTRY}/deepflow-ce/deepflowio-init-grafana-ds-dh:latest"
  "docker.io/library/telegraf:1.32-alpine|${TARGET_REGISTRY}/telegraf:1.32-alpine"
  "docker.io/grafana/otel-lgtm:latest|${TARGET_REGISTRY}/grafana/otel-lgtm:latest"
  # --- values.yaml 中定义但未渲染的镜像 ---
  "xnet.registry.io:8443/apiserver/apiserver:v1.0|${TARGET_REGISTRY}/apiserver:v1.0"
  "docker.io/library/influxdb:2.7.4-alpine|${TARGET_REGISTRY}/influxdb:2.7.4-alpine"
  "quay.io/prometheus-operator/prometheus-config-reloader:v0.83.0|${TARGET_REGISTRY}/prometheus-operator/prometheus-config-reloader:v0.83.0"
  "quay.io/thanos/thanos:v0.38.0|${TARGET_REGISTRY}/thanos/thanos:v0.38.0"
  "quay.io/brancz/kube-rbac-proxy:v0.19.1|${TARGET_REGISTRY}/brancz/kube-rbac-proxy:v0.19.1"
  "quay.io/sustainable_computing_io/kepler_model_server:v0.7.12|${TARGET_REGISTRY}/sustainable_computing_io/kepler_model_server:v0.7.12"
  "docker.io/library/busybox:1.31.1|${TARGET_REGISTRY}/library/busybox:1.31.1"
  "foundationdb/fdb-kubernetes-operator:v1.9.0|${TARGET_REGISTRY}/fdb-kubernetes-operator:v1.9.0"
  "foundationdb/foundationdb-kubernetes-sidecar:6.2.30-1|${TARGET_REGISTRY}/foundationdb-kubernetes-sidecar:6.2.30-1"
  "foundationdb/foundationdb-kubernetes-sidecar:6.3.23-1|${TARGET_REGISTRY}/foundationdb-kubernetes-sidecar:6.3.23-1"
  "foundationdb/foundationdb-kubernetes-sidecar:7.1.15-1|${TARGET_REGISTRY}/foundationdb-kubernetes-sidecar:7.1.15-1"
  "docker.io/library/alpine:3.10.2|${TARGET_REGISTRY}/alpine:3.10.2"
  "docker.io/gchq/hdfs:3.2.2|${TARGET_REGISTRY}/hdfs:3.2.2"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/byconity:1.0.0|${TARGET_REGISTRY}/byconity:1.0.0"
  "registry.cn-hongkong.aliyuncs.com/deepflow-ce/deepflowio-stella-agent-ce:latest|${TARGET_REGISTRY}/deepflowio-stella-agent-ce:latest"
)

# 获取 containerd 中所有镜像列表（排除 digest 引用）
echo "=== 获取本节点 containerd 镜像列表 ==="
CTR_IMAGES=$(ctr -n k8s.io images list -q 2>/dev/null | grep -v '@sha256' | sort -u)
DOCKER_IMAGES=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -v '<none>' | sort -u)

# 检查镜像是否存在于 containerd
in_containerd() {
    echo "$CTR_IMAGES" | grep -qxF "$1"
}

# 检查镜像是否存在于 docker
in_docker() {
    echo "$DOCKER_IMAGES" | grep -qxF "$1"
}

# 确保镜像在 docker 中可用（如果不在则从 containerd 导入）
ensure_in_docker() {
    local src="$1"
    if in_docker "$src"; then
        return 0
    fi
    if in_containerd "$src"; then
        local tarfile="${TMPDIR_EXPORT}/$(echo "$src" | tr '/:' '__').tar"
        echo "  从 containerd 导出到 docker: $src"
        if ctr -n k8s.io images export "$tarfile" "$src" 2>/dev/null && docker load -i "$tarfile" 2>/dev/null; then
            rm -f "$tarfile"
            return 0
        fi
        rm -f "$tarfile"
    fi
    return 1
}

echo ""
echo "=== 开始 retag & push ==="
echo ""

for mapping in "${IMAGE_MAP[@]}"; do
    SRC="${mapping%%|*}"
    DST="${mapping##*|}"

    echo "[处理] $SRC -> $DST"

    if ! ensure_in_docker "$SRC"; then
        echo "  [SKIP] 本节点未找到: $SRC"
        ((SKIP++))
        echo ""
        continue
    fi

    if docker tag "$SRC" "$DST" 2>/dev/null; then
        echo "  tagged -> $DST"
        if docker push "$DST" 2>/dev/null; then
            echo "  [OK] pushed"
            ((SUCCESS++))
        else
            echo "  [FAIL] push 失败: $DST"
            ((FAIL++))
        fi
        docker rmi "$DST" &>/dev/null || true
    else
        echo "  [FAIL] tag 失败: $SRC -> $DST"
        ((FAIL++))
    fi

    echo ""
done

# 清理临时目录
rm -rf "$TMPDIR_EXPORT"

echo "=== 完成 ==="
echo "成功: $SUCCESS | 失败: $FAIL | 跳过: $SKIP"
echo ""
if [ $SKIP -gt 0 ]; then
    echo "提示: 跳过的镜像可能在其他节点上，请在所有节点执行此脚本"
fi
if [ $FAIL -gt 0 ]; then
    echo "警告: 有 $FAIL 个镜像处理失败，请检查日志"
fi

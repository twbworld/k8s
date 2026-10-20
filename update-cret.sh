#!/bin/bash
# 用法: ./update-cret.sh <SECRET_NAME> <CERT_FILE> <KEY_FILE> [ENABLE_RESTART(true/false)]
# 示例: ./update-cret.sh xray-secret /path/tls.crt /path/tls.key
#       ./update-cret.sh xray-secret /path/tls.crt /path/tls.key true  # 强制重启

# ----------------- 配置变量 -----------------
NAMESPACE="default"
SECRET_NAME="$1"
CERT_FILE="$2"
KEY_FILE="$3"

# 重启开关：默认 false (不重启)，支持通过第4个参数或环境变量覆盖
ENABLE_RESTART="${4:-${ENABLE_RESTART:-false}}"

# 重启白名单，需要关联匹配的 Deployment 关键字
DEPLOY_RESTART=("3x-ui" "xray")
# --------------------------------------------

# 参数校验
if [[ -z "$SECRET_NAME" || -z "$CERT_FILE" || -z "$KEY_FILE" ]]; then
    echo "❌ 参数缺失！用法: $0 <SECRET_NAME> <CERT_FILE> <KEY_FILE> [ENABLE_RESTART]" >&2
    exit 2
fi

if [[ ! -f "$CERT_FILE" ]]; then
    echo "❌ 证书文件 $CERT_FILE 不存在！" >&2
    exit 3
fi

if [[ ! -f "$KEY_FILE" ]]; then
    echo "❌ 密钥文件 $KEY_FILE 不存在！" >&2
    exit 3
fi

# 更新 Kubernetes Secret
echo "ℹ️ 正在更新 Kubernetes Secret: $SECRET_NAME"
if ! kubectl create secret tls "$SECRET_NAME" \
    --cert="$CERT_FILE" \
    --key="$KEY_FILE" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply --server-side --force-conflicts -f -; then
    echo "❌ 更新 Kubernetes Secret 失败！请检查 kubectl 配置或权限。" >&2
    exit 4
fi
echo "✅ K8S 的 $SECRET_NAME 证书 Secret 更新完成"

# 判断是否跳过重启 (Traefik 与 Xray oneTimeLoading:false 原生支持热重载)
if [[ "$ENABLE_RESTART" != "true" ]]; then
    echo "ℹ️ 已开启免重启热加载（K8s Secret 自动同步挂载，Xray/Traefik 自动热重载），跳过 Pod 重启。"
    exit 0
fi

# 执行重启逻辑 (仅当 ENABLE_RESTART=true 时运行)
echo "ℹ️ 检测到重启开关已开启，正在检查关联 Deployment..."
for keyword in "${DEPLOY_RESTART[@]}"; do
    if [[ "$SECRET_NAME" != *"$keyword"* ]]; then
        continue
    fi

    # 获取匹配的 Deployment 完整资源名称 (如 deployment.apps/3x-ui-deploy)
    DEPLOYMENT_NAME=$(kubectl get deployments -o name -n "$NAMESPACE" | grep -i -F "$keyword" | head -n 1)

    if [[ -z "$DEPLOYMENT_NAME" ]]; then
        echo "⚠️ 匹配关键字 [$keyword] 的 Deployment 不存在，跳过该项重启。"
        continue
    fi

    echo "ℹ️ 正在滚动重启 Deployment: $DEPLOYMENT_NAME"
    kubectl rollout restart "$DEPLOYMENT_NAME" -n "$NAMESPACE"
    if ! kubectl rollout status "$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=300s; then
        echo "❌ $DEPLOYMENT_NAME 重启失败，可能需要手动排查。" >&2
        exit 5
    fi
    echo "✅ $DEPLOYMENT_NAME 重启成功"
done

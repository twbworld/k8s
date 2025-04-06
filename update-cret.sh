#!/bin/bash
# acme.sh --install-cert -d "test.com" -d "*.test.com" --key-file test.com/key.pem --fullchain-file test.com/cert.pem --reloadcmd "update-cret.sh tls-secret test.com/cert.pem test.com/key.pem"

# 设置变量
DEPLOY_RESTART=("xray") # pod内需用证书,要重启的部署的关键字
NAMESPACE="default"
SECRET_NAME="$1"
CERT_FILE="$2"
KEY_FILE="$3"

# 参数校验
if [[ -z "$SECRET_NAME" || -z "$CERT_FILE" || -z "$KEY_FILE" ]]; then
    echo "❌ 参数缺失！用法: $0 <SECRET_NAME> <CERT_FILE> <KEY_FILE>" >&2
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
if ! kubectl create secret tls $SECRET_NAME --cert=$CERT_FILE --key=$KEY_FILE -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -; then
    echo "❌ 更新 Kubernetes Secret 失败！请检查 kubectl 配置或权限。" >&2
    exit 4
fi
echo "✅ K8S的 $SECRET_NAME 证书更新完成"

# 判断是否需要重启部署
for keyword in "${DEPLOY_RESTART[@]}"; do
    if [[ "$SECRET_NAME" != *"$keyword"* ]]; then
        echo "❌ 未找到包含关键字 $keyword" >&2
        continue
    fi
    DEPLOYMENT_NAME=$(kubectl get deployments -o name -n $NAMESPACE | grep -i -F "$keyword" | head -n 1)
    echo "ℹ️ 正在重启 Deployment: $DEPLOYMENT_NAME"
    kubectl rollout restart $DEPLOYMENT_NAME -n $NAMESPACE
    if ! kubectl rollout status $DEPLOYMENT_NAME -n $NAMESPACE --timeout=300s; then
        echo "❌ $DEPLOYMENT_NAME 重启失败，可能需要手动检查。" >&2
        exit 5
    fi
    echo "✅ $DEPLOYMENT_NAME 重启成功"
done

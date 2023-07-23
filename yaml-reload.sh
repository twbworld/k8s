#!/bin/bash -e
#此脚本作用为重载k8s配置文件, 使应用滚动更新

if [ ! -n "$1" ]; then
    echo "请提供参数[iashada]"
    exit 1
fi
fn=$1
fnp="config/$fn.yaml"
if [ ! -f "$fnp" ]; then
    echo "没有文件$fnp[igjdohdas]"
    exit 1
fi
n=${fn//-/_}
n=${n^^} #转大写
t=$(date "+%Y%m%d%H%M%S")
git checkout -- $fnp
sed -i "s/K8S_$n/$t/g" $(grep -rl "\${K8S_$n}" $fnp)
kubectl apply -f $fnp
sleep 2
exit 0

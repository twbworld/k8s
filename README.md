**k8s (个人的k8s搭建配置)**
===========
[![](https://github.com/twbworld/k8s/workflows/ci/badge.svg?branch=main)](https://github.com/twbworld/k8s/actions)
[![](https://img.shields.io/github/tag/twbworld/k8s?logo=github)](https://github.com/twbworld/k8s)

## 简介

* [k3s官网](https://docs.k3s.io/zh/installation/requirements)

* [k3d官网](https://k3d.io/v5.5.1/usage/configfile/)

* k3d部署:
    ``` sh
    k3d cluster delete mycluster && k3d cluster create --config k3d.yaml
    ```
* k8s面板部署:
    ``` sh
    ./kube-explorer-linux-amd64 --kubeconfig ~/.kube/config --http-listen-port=8888
    ```
* 证书更新(k8s更新secret证书后,traefik会自动reload)
  ``` sh
  ...
    acme.sh --install-cert -d "xxx.com" -d "*.xxx.com" \
        --fullchain-file /var/www/k8s/data/cert/xxx.com/tls.crt \
        --key-file /var/www/k8s/data/cert/xxx.com/tls.key \
        --reloadcmd "/var/www/k8s/update-cret.sh tls-secret /var/www/k8s/data/cert/xxx.com/tls.crt /var/www/k8s/data/cert/xxx.com/tls.key && exit"
  ```

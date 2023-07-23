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
  acme.sh --install-cert -d twbhub.com -d *.twbhub.com -d twbhub.top -d *.twbhub.top \
    --key-file /var/www/k8s/data/cert/twbhub.com_top/key.pem \
    --fullchain-file /var/www/k8s/data/cert/twbhub.com_top/cert.pem \
    --reloadcmd "cd /var/www/k8s/ && kubectl create secret tls tls-secret --cert=/var/www/k8s/data/cert/twbhub.com_top/cert.pem --key=/var/www/k8s/data/cert/twbhub.com_top/key.pem --dry-run -o yaml |kubectl apply -f - && git checkout -- yaml-reload.sh && ./yaml-reload.sh trojan-go && exit'"
  ```

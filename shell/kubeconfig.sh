#!/usr/bin/env bash

#create TLS Bootstrapping Token
export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
cat >/opt/kubernetes/cfg/token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

#create kubelet bootstrapping kubeconfig
export KUBE_APISERVER="http://192.168.56.101:6443"

#configure cluster parameter
kubectl config set-cluster kubernetes \
--certificate-authority=/opt/kubernetes/ssl/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig

#configure client ceritifcate parameter
kubectl config set-credentials kubelet-bootstrap \
--token=${BOOTSTRAP_TOKEN} \
--kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig

#configure updown parameter
kubectl config set-context default \
--cluster=kubernetes \
--user=kubelet-bootstrap \
--kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig

#configure updown default value
kubectl config use-context default --kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig

#create kube-proxy kubeconfig file
kubectl config set-cluster kubernetes \
--certificate-authority=/opt/kubernetes/ssl/ca.pem \
--embed-certs=true \
--server=\${KUBE_APISERVER} \
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
--client-certificate=/opt/kubernetes/ssl/kube-proxy.pem \
--client-key=/opt/kubernetes/ssl/kube-proxy-key.pem \
--embed-certs=true \
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig

kubectl config set-context default \
--cluster=kubernetes \
--user=kube-proxy \
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig

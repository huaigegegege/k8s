#!/usr/bin/env bash

cat <<EOF >/opt/kubernetes/cfg/etcd

#[Member]
ETCD_NAME="etcd01"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://192.168.56.101:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.56.101:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.56.101:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.56.101:2379"
ETCD_INITIAL_CLUSTER="etcd01=http://192.168.56.101:2380,etcd02=http://192.168.56.102:2380,etcd03=http://192.168.56.103:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

EOF

cat <<EOF >/usr/lib/systemd/system/etcd.service

[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=-/opt/kubernetes/cfg/etcd
ExecStart=/opt/kubernetes/bin/etcd \\
--name=\${ETCD_NAME} \\
--data-dir=\${ETCD_DATA_DIR} \\
--listen-peer-urls=\${ETCD_LISTEN_PEER_URLS} \\
--listen-client-urls=\${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \\
--advertise-client-urls=\${ETCD_ADVERTISE_CLIENT_URLS} \\
--initial-advertise-peer-urls=\${ETCD_INITIAL_ADVERTISE_PEER_URLS} \\
--initial-cluster=\${ETCD_INITIAL_CLUSTER} \\
--initial-cluster-token=\${ETCD_INITIAL_CLUSTER} \\
--initial-cluster-state=new \\
--cert-file=/opt/kubernetes/ssl/server.pem \\
--key-file=/opt/kubernetes/ssl/server-key.pem \\
--peer-cert-file=/opt/kubernetes/ssl/server.pem \\
--peer-key-file=/opt/kubernetes/ssl/server-key.pem \\
--trusted-ca-file=/opt/kubernetes/ssl/ca.pem \\
--peer-trusted-ca-file=/opt/kubernetes/ssl/ca.pem
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF

num=`less /etc/profile | grep -c /opt/kubernetes/bin`
if [[ $num -eq 0  ]]; then
	echo "PATH=\$PATH:/opt/kubernetes/bin">>/etc/profile
	source /etc/profile
fi



systemctl daemon-reload
systemctl enable etcd
systemctl restart etcd

cd /opt/kubernetes/ssl

etcdctl --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem --endpoints="http://192.168.56.101:2379,http://192.168.56.102:2379,http://192.168.56.103:2379" cluster-health


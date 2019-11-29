#/usr/bin/bash

cat <<EOF >/opt/kubernetes/cfg/flanneld
FLANNEL_OPTIONS="--etcd-endpoints=http://192.168.56.101:2379,http://192.168.56.102:2379,http://192.168.56.103:2379 -etcd-cafile=/opt/kubernetes/ssl/ca.pem -etcd-certfile=/opt/kubernetes/ssl/server.pem -etcd-keyfile=/opt/kubernetes/ssl/server-key.pem"

EOF

cat <<EOF >/usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld Overlay Address ETCD agent
After=network-online.target network.target
Before=docker.service

[Service]
Type=notify
EnvironmentFile=-/opt/kubernetes/cfg/flanneld
ExecStart=/opt/kubernetes/bin/flanneld --ip-masq \$FLANNELD_OPTIONS
ExecStartPost=/opt/kubernetes/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOF

cd /opt/kubernetes/ssl

etcdctl --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem --endpoints="http://192.168.56.101:2379,http://192.168.56.102:2379,http://192.168.56.103:2379" set /coreos.com/network/config '{ "Network":"172.17.0.0/16","Backend":{"Type":"vxlan"} }' { "Network":"172.17.0.0/16","Backend":{"Type":"vxlan"} }

systemctl daemon-reload
systemctl start flanneld
systemctl enable flanneld

cd /usr/bin
num=`ls -l | grep -c crudini`
 
if [[ $num -eq 0 ]]; then 
        yum install -y git; 
        git clone https://github.com/pixelb/crudini.git; 
        mv /usr/bin/crudini /usr/bin/crudinid;
        ln -s /usr/bin/crudinid/crudini /usr/bin/crudini; 

fi

crudini --set /usr/lib/systemd/system/docker.service Service EnvironmentFile /run/flannel/subnet.env
res=`crudini --get /usr/lib/systemd/system/docker.service Service ExecStart | awk -F $ '{ print $1" $DOCKER_NETWORK_OPTIONS"}'`
echo $res
crudini --set /usr/lib/systemd/system/docker.service Service ExecStart "${res}"
crudini --get /usr/lib/systemd/system/docker.service Service ExecStart

systemctl daemon-reload
systemctl enable docker
systemctl restart docker

cd /opt/kubernetes/ssl
etcdctl --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem --endpoints="http://192.168.56.101:2379,http://192.168.56.102:2379,http://192.168.56.103:2379" ls /coreos.com/network/subnets

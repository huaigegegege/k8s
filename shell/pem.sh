#!/usr/bin/bash
cat >ca-config.json<<EOF
{
        "signing":{
                "default":{
                        "expiry":"87600h"
                },
                "profiles":{
                        "kubernetes":{
                                "expiry":"87600h",
                                "usages":[
                                        "signing",
                                        "key encipherment",
                                        "server auth",
                                        "client auth"
                                ]
                        }
                }
        }
}
EOF
cat >ca-csr.json<<EOF
{
        "CN":"kubernetes",
        "key":{
                "algo":"rsa",
                "size":2048
        },
        "names":[
                {
                        "C":"CN",
                        "L":"Beijing",
                        "ST":"Beijing",
                        "O":"k8s",
                        "OU":"System"
                }
        ]
}
EOF
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
cat >server-csr.json<<EOF
{
        "CN":"kubernetes",
        "hosts":[
                "127.0.0.1",
                "192.168.56.101",
                "192.168.56.102",
                "192.168.56.103"
        ],
        "key":{
                "algo":"rsa",
                "size":2048
        },
        "names":[
                {
                        "C":"CN",
                        "L":"Beijing",
                        "ST":"Beijing",
                        "O":"k8s",
                        "OU":"System"
                }
        ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server
cat >admin-csr.json <<EOF
{
	"CN":"admin",
	"hosts":[],
	"key":{
		"algo":"rsa",
		"size":2048
	},
	"names":[
		{
			"C":"CN",
			"L":"Beijing",
			"ST":"Beijing",
			"O":"System:masters",
			"OU":"System"
		}
	]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
cat >kube-proxy-csr.json <<EOF
{
	"CN":"system:kube-proxy",
	"hosts":[],
	"key":{
		"algo":"rsa",
		"size":2048
	},
	"names":[{
		"C":"CN",
		"L":"Beijing",
		"ST":"Beijing",
		"O":"k8s",
		"OU":"System"
	}]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json  -profile=kubernetes kube-proxy-csr.json | cfssljson  -bare kube-proxy

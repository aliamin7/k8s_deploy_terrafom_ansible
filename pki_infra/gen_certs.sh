#!/bin/sh


# The CA Cert


echo "######Generating CA certificate#######"
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

if [ ! -f ca-key.pem ] || [ ! -f ca.pem ]; then
    echo "ERROR: CA is not created"
    exit 1
fi
# The Admin Client Certs


echo "######Generating admin certificate#######"
cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
admin-csr.json | cfssljson -bare admin

if [ ! -f admin-key.pem ] || [ ! -f admin.pem ]; then
    echo "ERROR: admin certificate is not created"
    exit 1
fi


# The Kubelet Client Certs

for instance in machine-0 machine-1 machine-2; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

INTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)')


echo "Generating workers certificates"
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}

if [ ! -f ${instance}-key.pem ] || [ ! -f ${instance}.pem ]; then
    echo "ERROR: ${instance} certificate is not created"
    exit 1
fi

done


# The Kube Controller Manager certificate

echo "###### Generating Kube Controller Manager certificate #######"
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager


if [ ! -f kube-controller-manager-key.pem ] || [ ! -f kube-controller-manager.pem ]; then
    echo "ERROR: Kube Controller Manager certificate is not created"
    exit 1
fi
# The kube-proxy Manager certificate

echo "###### Generating kube-proxy certificate #######"
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

if [ ! -f kube-proxy-key.pem ] || [ ! -f kube-proxy.pem ]; then
    echo "ERROR: kube-proxy certificate is not created"
    exit 1
fi

# The Kube Controller Manager certificate

echo "###### Generating kube-scheduler certificate #######"
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

if [ ! -f kube-scheduler-key.pem ] || [ ! -f kube-scheduler.pem ]; then
    echo "ERROR: kube-scheduler certificate is not created"
    exit 1
fi

# The Kube Apiserver certificate

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-address \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local


echo "###### Generating kube-apiserver certificate #######"

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

if [ ! -f kubernetes-key.pem ] || [ ! -f kubernetes.pem ]; then
    echo "ERROR: kube-apiserver certificate is not created"
    exit 1
fi

# The service account certificate

echo "Generating service account certificate..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

if [ ! -f service-account-key.pem ]||[ ! -f service-account.pem ]; then
    echo "Error creating service-account certificates"
    exit -1
fi

# The front-proxy ca certificate

echo "Generating front-proxy ca certificate..."
cfssl gencert -initca ca-front-proxy-csr.json | cfssljson -bare ca-front-proxy

if [ ! -f ca-front-proxy-key.pem ]||[ ! -f ca-front-proxy.pem ]; then
    echo "Error creating front-proxy CA certificates"
    exit -1
fi

# The front-proxy-client certificate

echo "Generating front-proxy-client certificate..."
cfssl gencert \
  -ca=ca-front-proxy.pem \
  -ca-key=ca-front-proxy-key.pem \
  -config=ca-front-proxy-config.json \
  -profile=kubernetes \
  front-proxy-client-csr.json | cfssljson -bare front-proxy-client

if [ ! -f front-proxy-client.pem ]||[ ! -f front-proxy-client.pem ]; then
    echo "Error creating front-proxy-client certificates"
    exit -1
fi
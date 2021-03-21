#!/bin/sh

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe k8s-address \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
echo "Kubernetes public address: ${KUBERNETES_PUBLIC_ADDRESS}"

for instance in machine-0 machine-1 machine-2; do
  echo "Generating ${instance} config..."
  kubectl config set-cluster kubernetes-cluster-1 \
    --certificate-authority=../pki_infra/output/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=../pki_infra/output/${instance}.pem \
    --client-key=../pki_infra/output/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-cluster-1 \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig

  if [ ! -f ${instance}.kubeconfig ]; then
    echo "Error creating ${instance} kube config"
    exit -1
  fi
done

echo "Generating kube-proxy config..."
kubectl config set-cluster kubernetes-cluster-1 \
  --certificate-authority=../pki_infra/output/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=../pki_infra/output/kube-proxy.pem \
  --client-key=../pki_infra/output/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-cluster-1 \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

if [ ! -f kube-proxy.kubeconfig ]; then
    echo "Error creating kube-proxy kube config"
    exit -1
fi

echo "Generating kube-controller-manager config..."
kubectl config set-cluster kubernetes-cluster-1 \
  --certificate-authority=../pki_infra/output/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials kube-controller-manager \
  --client-certificate=../pki_infra/output/kube-controller-manager.pem \
  --client-key=../pki_infra/output/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-cluster-1 \
  --user=kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

if [ ! -f kube-controller-manager.kubeconfig ]; then
    echo "Error creating kube-controller-manager kube config"
    exit -1
fi

echo "Generating kube-scheduler config..."
kubectl config set-cluster kubernetes-cluster-1 \
  --certificate-authority=../pki_infra/output/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials kube-scheduler \
  --client-certificate=../pki_infra/output/kube-scheduler.pem \
  --client-key=../pki_infra/output/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-cluster-1 \
  --user=kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

if [ ! -f kube-scheduler.kubeconfig ]; then
    echo "Error creating kube-scheduler kube config"
    exit -1
fi

echo "Generating admin config..."
kubectl config set-cluster kubernetes-cluster-1 \
  --certificate-authority=../pki_infra/output/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=../pki_infra/output/admin.pem \
  --client-key=../pki_infra/output/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-cluster-1 \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

if [ ! -f admin.kubeconfig ]; then
    echo "Error creating admin kube config"
    exit -1
fi
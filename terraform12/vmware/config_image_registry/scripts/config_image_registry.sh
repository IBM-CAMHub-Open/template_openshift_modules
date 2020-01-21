#!/bin/bash

###
# Check if boostrap is completed
###
KUBECONFIG_FILE=/installer/auth/kubeconfig

#TODO add code for production NFS image registry
#Following code is for test.

NFS_IP=$1
NFS_PATH=$2

# create pv.yaml file
touch /installer/pv.yaml
cat <<EOT >> /installer/pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv1
spec:
  storageClassName: image-registry-storage
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteMany
  claimRef:
    namespace: openshift-image-registry
    name: image-registry-storage
  nfs:
    path: ${NFS_PATH}
    server: ${NFS_IP}
EOT

# create sc.yaml file
touch /installer/sc.yaml
cat <<EOT >> /installer/sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/vsphere-volume
parameters:
  diskformat: eagerzeroedthick
EOT

# create sc and pv

count=1
while [ $count -le 360 ]
do
  if [ $(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get sc | awk '{print $1}' | grep thin) ] && [ $(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get config | awk '{print $1}' | grep cluster) ]; then
    echo "Storage Class 'thin' and config file are available now."
    break
  else
    echo "Waiting for storage class 'thin', sleep for 10 seconds..."
    sleep 10
    ((count++))
  fi
done
if [ "$count" -gt 360 ]; then
  echo "Storage Class 'thin' and config file are still unavailable after 1 hour waiting, exiting script..."
  exit 1
fi

sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc apply -f /installer/sc.yaml
sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/kubectl patch storageclass thin -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/kubectl patch storageclass fast -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc apply -f /installer/pv.yaml

# edit configs.imageregistry.operator.openshift.io
sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"pvc":{"claim":""}}}}'

# Check the clusteroperator status
counter=1
while [ $counter -le 10 ]
do
  if [ $(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get clusteroperator image-registry | awk '{print $3}' | sed -n 2p) == "False" ]; then
    echo "Creating cluster operator in progress, sleep for 10 seconds..."
    sleep 10
    ((counter++))
  else
    echo "Cluster operator is available now."
    break
  fi
done
if [ "$counter" -gt 10 ]; then
  echo "Cluster operator is still unavailable after 10 tries, exiting script..."
  exit 1
fi
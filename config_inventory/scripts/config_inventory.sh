#!/bin/bash

masterstr=$(echo $1 | sed 's/[][]//g' )
IFS=',' read -r -a masterhostnames <<< "$masterstr"

etcdstr=$(echo $2 | sed 's/[][]//g' )
IFS=',' read -r -a etcdhostnames <<< "$etcdstr"

computestr=$(echo $3 | sed 's/[][]//g' )
IFS=',' read -r -a computehostnames <<< "$computestr"

lbstr=$(echo $4 | sed 's/[][]//g' )
IFS=',' read -r -a lbhostnames <<< "$lbstr"

infrastr=$(echo $5 | sed 's/[][]//g' )
IFS=',' read -r -a infrahostnames <<< "$infrastr"

infrastr2=$(echo $6 | sed 's/[][]//g' )
IFS=',' read -r -a infraips <<< "$infrastr2"

rh_user=$7
rh_password=$8
vm_domain_name=$9
enable_lb=${10}
enable_glusterfs=${11}
os_password=${12}
disk=$(head -n 1 /tmp/glusterfs_disk.txt)

# SSH key
allhostnames=( "${masterhostnames[@]}" "${etcdhostnames[@]}" "${computehostnames[@]}" "${infrahostnames[@]}" )
if [[ $enable_lb == "true" ]]; then
  allhostnames=( "${allhostnames[@]}" "${lbhostnames[@]}" )
fi
yes y | ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
yum -y install sshpass
for index in "${!allhostnames[@]}"
do
    sshpass -p $os_password ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no ${allhostnames[index]}.$vm_domain_name
done

if [[ ${#computehostnames[@]} < 3 && $enable_glusterfs == "true" ]]; then
  printf "\033[31m[ERROR] You need at least 3 compute nodes to configure GlusterFS. Deploy Openshift Cluster Failed\033[0m\n"
  exit 1
fi

mv /etc/ansible/hosts /etc/ansible/hosts_old.backup
touch /etc/ansible/hosts

inventory_file=$(
  echo "[OSEv3:children]"
  echo "masters"
  echo "nodes"
  echo "etcd"
  if [[ $enable_lb == "true" ]]; then
    echo "lb"
  fi
  if [[ $enable_glusterfs == "true" ]]; then
    echo "glusterfs"
  fi
  echo "[OSEv3:vars]"
  echo "ansible_ssh_user=root"
  echo "openshift_deployment_type=openshift-enterprise"
  echo "openshift_disable_check=docker_storage,docker_image_availability"
  echo "openshift_master_default_subdomain=${infraips[0]}.nip.io"
  if [[ $enable_glusterfs == "true" ]]; then
    echo "openshift_storage_glusterfs_namespace=app-storage"
    echo "openshift_storage_glusterfs_storageclass=true"
    echo "openshift_storage_glusterfs_storageclass_default=true"
    echo "openshift_storage_glusterfs_block_deploy=true"
    echo "openshift_storage_glusterfs_block_host_vol_size=100"
    echo "openshift_storage_glusterfs_block_storageclass=true"
    echo "openshift_storage_glusterfs_block_storageclass_default=true"
    echo "openshift_storage_glusterfs_image=registry.redhat.io/rhgs3/rhgs-server-rhel7:v3.11"
    echo "openshift_storage_glusterfs_block_image=registry.redhat.io/rhgs3/rhgs-gluster-block-prov-rhel7:v3.11"
    echo "openshift_storage_glusterfs_heketi_image=registry.redhat.io/rhgs3/rhgs-volmanager-rhel7:v3.11"
    echo "openshift_storage_glusterfs_timeout=900"
  fi
  echo "os_firewall_use_firewalld=True"
  echo "oreg_auth_user=$rh_user"
  echo "oreg_auth_password=$rh_password"
  echo "openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider',}]"
  if [[ $enable_lb == "true" ]]; then
    echo "openshift_master_cluster_method=native"
    echo "openshift_master_cluster_hostname=${lbhostnames[0]}.$vm_domain_name"
    echo "openshift_master_cluster_public_hostname=${lbhostnames[0]}.$vm_domain_name"
  fi
  echo ""
  if [[ $enable_glusterfs == "true" ]]; then
    echo "[glusterfs]"
    for index in "${!computehostnames[@]}"
    do
      echo "${computehostnames[index]}.$vm_domain_name glusterfs_devices='[ \"$disk\" ]'"
    done
    echo ""
  fi
  echo "[masters]"
  for index in "${!masterhostnames[@]}"
  do
    echo "${masterhostnames[index]}.$vm_domain_name"
  done
  echo ""
  echo "[etcd]"
  for index in "${!etcdhostnames[@]}"
  do
    echo "${etcdhostnames[index]}.$vm_domain_name"
  done
  echo ""
  if [[ $enable_lb == "true" ]]; then
    echo "[lb]"
    for index in "${!lbhostnames[@]}"
    do
      echo "${lbhostnames[index]}.$vm_domain_name"
    done
    echo ""
  fi
  echo "[nodes]"
  for index in "${!infrahostnames[@]}"
  do
    echo "${infrahostnames[index]}.$vm_domain_name openshift_node_group_name='node-config-infra'"
  done
  for index in "${!masterhostnames[@]}"
  do
    echo "${masterhostnames[index]}.$vm_domain_name openshift_node_group_name='node-config-master'"
  done
  for index in "${!computehostnames[@]}"
  do
    echo "${computehostnames[index]}.$vm_domain_name openshift_node_group_name='node-config-compute'"
  done
)
echo "${inventory_file}" > /etc/ansible/hosts
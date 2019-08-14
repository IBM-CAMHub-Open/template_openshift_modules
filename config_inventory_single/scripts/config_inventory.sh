#!/bin/bash

set -e

single_hostname=$1
single_ip=$2
vm_domain_name=$3
rh_user=$4
rh_password=$5

mv /etc/ansible/hosts /etc/ansible/hosts_old.backup
touch /etc/ansible/hosts

inventory_file=$(
  echo "[OSEv3:children]"
  echo "masters"
  echo "nodes"
  echo "etcd"
  echo ""
  echo "[OSEv3:vars]"
  echo "ansible_ssh_user=root"
  echo "openshift_deployment_type=openshift-enterprise"
  echo "openshift_hosted_infra_selector=\"\""
  echo "openshift_disable_check=docker_storage,docker_image_availability"
  echo "openshift_master_default_subdomain=$2.nip.io"
  echo "os_firewall_use_firewalld=True"
  echo "oreg_auth_user=$rh_user"
  echo "oreg_auth_password=$rh_password"
  echo "openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]"
  echo ""
  echo "[masters]"
  echo "$1.$vm_domain_name"
  echo ""
  echo "[etcd]"
  echo "$1.$vm_domain_name"
  echo ""
  echo "[nodes]"
  echo "$1.$vm_domain_name openshift_node_group_name='node-config-all-in-one'"
)
echo "${inventory_file}" > /etc/ansible/hosts
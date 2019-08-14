#!/bin/bash

vm_domain_name=$1
os_password=$2

nodestr=$(echo $3 | sed 's/[][]//g' )
IFS=',' read -r -a nodehostnames <<< "$nodestr"

nodeipstr=$(echo $4 | sed 's/[][]//g' )
IFS=',' read -r -a nodeips <<< "$nodeipstr"

for index in "${!nodehostnames[@]}"
do
    sshpass -p $os_password ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no ${nodehostnames[index]}.$vm_domain_name
done
if ! grep -q "new_nodes" /etc/ansible/hosts; then
    sed -i -e '/^\[OSEv3\:vars\]/i new_nodes' /etc/ansible/hosts
    echo "[new_nodes]" >> /etc/ansible/hosts
fi
for index in "${!nodehostnames[@]}"
do
    echo "${nodehostnames[index]}.$vm_domain_name openshift_node_group_name='node-config-compute'" >> /etc/ansible/hosts
done
if grep -q "[glusterfs]" /etc/ansible/hosts; then
    disk=$(head -n 1 /tmp/glusterfs_disk.txt)
    for index in "${!nodehostnames[@]}"
    do
        sed -i -e "/^\[glusterfs\]/a ${nodehostnames[index]}.$vm_domain_name glusterfs_devices='[ \"$disk\" ]'" /etc/ansible/hosts
    done
fi
cd /usr/share/ansible/openshift-ansible
if ansible-playbook playbooks/openshift-node/scaleup.yml; then
    printf "\033[32m[*] Add new compute node successfully \033[0m\n"
    for index in "${!nodehostnames[@]}"
    do
        sed -i -e "/${nodehostnames[index]}/d" /etc/ansible/hosts
        sed -i -e "/^\[new\_nodes\]/i ${nodehostnames[index]}.$vm_domain_name openshift_node_group_name='node-config-compute'" /etc/ansible/hosts
        sed -i -e "/^\[glusterfs\]/a ${nodehostnames[index]}.$vm_domain_name glusterfs_devices='[ \"$disk\" ]'" /etc/ansible/hosts
    done
else
    printf "\033[31m[ERROR] Add new compute node failed\033[0m\n"
    exit 1
fi
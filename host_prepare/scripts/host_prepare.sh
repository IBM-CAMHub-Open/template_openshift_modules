#!/bin/bash

set -x

hostnamestr=$(echo $3 | sed 's/[][]//g' )
IFS=',' read -r -a allhostnames <<< "$hostnamestr"
installer_hostname=$4
domain_name=$5
os_password=$6

# Set hostname
hostnamectl set-hostname "$(hostname -f)"

# Registering hosts
sed -i -e '/^hostname/c\hostname = subscription.rhsm.redhat.com' /etc/rhsm/rhsm.conf
sed -i -e '/^prefix/c\prefix = /subscription' /etc/rhsm/rhsm.conf
sed -i -e '/^baseurl/c\baseurl = https://cdn.redhat.com' /etc/rhsm/rhsm.conf
sed -i -e '/^ca_cert_dir/c\ca_cert_dir = /etc/rhsm/ca/' /etc/rhsm/rhsm.conf
sed -i -e '/^repo_ca_cert/c\repo_ca_cert = %(ca_cert_dir)sredhat-uep.pem' /etc/rhsm/rhsm.conf

rm -rf /etc/sysconfig/rhn/systemid

subscription-manager remove --all
subscription-manager unregister
subscription-manager clean

yum clean all
yum clean metadata
yum clean dbcache
yum makecache

subscription-manager register --username=$1 --password=$2
subscription-manager refresh
subscription-manager attach --auto
subscription-manager repos --disable="*"
yum -y install yum-utils
yum-config-manager --disable \*
subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.11-rpms" \
    --enable="rhel-7-server-ansible-2.6-rpms"

# Install base packages
yum -y install wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct
yum -y update
yum -y install openshift-ansible

# SSH key
if [[ "$installer_hostname.$domain_name" == "$(hostname -f)" ]]; then
    yes y | ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
    yum -y install sshpass
    for index in "${!allhostnames[@]}"
    do
        sshpass -p $os_password ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no ${allhostnames[index]}.$domain_name
    done
fi

# Install docker 1.31.1
yum -y remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine
yum -y install docker-1.13.1

# Enable SELinux
# sed -i -e '/^SELINUX=/c\SELINUX=enforcing' /etc/selinux/config
# sed -i -e '/^SELINUXTYPE=/c\SELINUXTYPE=targeted' /etc/selinux/config


# GLusterfs
yum -y install glusterfs-fuse
subscription-manager repos --enable=rh-gluster-3-client-for-rhel-7-server-rpms
yum -y update glusterfs-fuse
sudo setsebool -P virt_sandbox_use_fusefs on
sudo setsebool -P virt_use_fusefs on
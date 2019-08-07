#!/bin/bash

cd /usr/share/ansible/openshift-ansible
if ansible-playbook -vvv playbooks/prerequisites.yml ; then
    printf "\033[32m[*] Prerequisites Succeeded \033[0m\n"
    if ansible-playbook -vvv playbooks/deploy_cluster.yml ; then
        printf "\033[32m[*] Deploy Openshift Cluster Succeeded \033[0m\n"
        #sed -i -e 's/DenyAllPasswordIdentityProvider/HTPasswdPasswordIdentityProvider/g' /etc/origin/master/master-config.yaml
        #sed -i -e '/HTPasswdPasswordIdentityProvider/a \ \ \ \ \ \ file: /etc/origin/master/htpasswd' /etc/origin/master/master-config.yaml
        #sed -ni '/provider:/{x;d;};1h;1!{x;p;};${x;p;}' /etc/origin/master/master-config.yaml
        #sed -i -e '/provider:/i \ \ \ \ name: htpasswd_auth provider' /etc/origin/master/master-config.yaml
        yum -y install httpd-tools
        touch /etc/origin/master/htpasswd
        htpasswd -b /etc/origin/master/htpasswd $1 $2
        master-restart api
        master-restart controllers
        oc login -u system:admin -n default
        oc adm policy add-cluster-role-to-user cluster-admin $1
        #oc project default
        printf "\033[32m[*] User Account Created Successfully \033[0m\n"
    else
        printf "\033[31m[ERROR] Deploy Openshift Cluster Failed\033[0m\n"
        exit 1
    fi
else
    printf "\033[31m[ERROR] Prerequisites Failed\033[0m\n"
    exit 1
fi
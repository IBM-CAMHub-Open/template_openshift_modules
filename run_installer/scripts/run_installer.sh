#!/bin/bash

masterstr=$(echo $3| sed 's/[][]//g' )
IFS=',' read -r -a masterips <<< "$masterstr"

cd /usr/share/ansible/openshift-ansible
if ansible-playbook -vvv playbooks/prerequisites.yml ; then
    printf "\033[32m[*] Prerequisites Succeeded \033[0m\n"
    if ansible-playbook -vvv playbooks/deploy_cluster.yml ; then
        printf "\033[32m[*] Deploy OpenShift Cluster Succeeded \033[0m\n"
        yum -y install httpd-tools
        touch /etc/origin/master/htpasswd
        htpasswd -b /etc/origin/master/htpasswd $1 $2
        # copy htpasswd file to other master nodes if needed
        if [[ ${#masterips[@]} > 1 ]]; then
            for index in "${!masterips[@]}"
            do
                scp /etc/origin/master/htpasswd root@${masterips[index]}:/etc/origin/master/htpasswd
            done
        fi
        # restart openshift
        master-restart api
        master-restart controllers
        for i in {1..10}
        do
            response=`curl -o /dev/null -s -w "%{http_code}" -k https://$(hostname -f):8443`
            if [ $response != 200 ]; then
                if [[ $i == 10 ]]; then
                    printf "\033[31m[ERROR] Unable to connect to the OCP server after 20 minutes\033[0m\n"
                else
                    echo "Login response is ${response}. Wait for OCP to be available ..."
                    sleep 120
                fi
            else
                echo "Login response is ${response}. OCP is available now ..."
                break
            fi
        done
        echo "Logging in as system:admin"
        oc login -u system:admin -n default
        echo "Successfully logged in as system:admin. Assigning cluster-admin role to $1 user"
        oc adm policy add-cluster-role-to-user cluster-admin $1
        echo "Successfully assigned cluster-admin role to $1 user. Logging in as $1 user"
        oc login -u $1 -p $2
        echo "Successfully logged in as $1. Listing the cluster nodes"
        oc get nodes
        #oc project default
        printf "\033[32m[*] User Account Created Successfully \033[0m\n"
    else
        printf "\033[31m[ERROR] Deploy OpenShift Cluster Failed\033[0m\n"
        exit 1
    fi
else
    printf "\033[31m[ERROR] Prerequisites Failed\033[0m\n"
    exit 1
fi
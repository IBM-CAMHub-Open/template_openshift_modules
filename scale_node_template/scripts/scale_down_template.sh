#!/bin/bash

nodestr=$(echo $1 | sed 's/[][]//g' )
IFS=',' read -r -a removed <<< "$nodestr"

for index in "${!removed[@]}"
do
    delnode=`oc get nodes | grep ${removed[index]} | awk '{print $1}'`
    oc adm manage-node $delnode --schedulable=false
    oc adm drain $delnode
    if oc delete node $delnode; then
        sed -i -e "/${removed[index]}/d" /etc/ansible/hosts
    else
        printf "\033[31m[ERROR] Delete compute node failed\033[0m\n"
        exit 1
    fi
done
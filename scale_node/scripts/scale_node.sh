#!/bin/bash

echo "scale_node"

NEWLIST=/tmp/new_compute.txt
OLDLIST=/tmp/old_compute.txt
vm_domain_name=$1
os_password=$2

declare -a newlist
IFS=', ' read -r -a newlist <<< $(cat ${NEWLIST})

declare -a oldlist
IFS=', ' read -r -a oldlist <<< $(cat ${OLDLIST})

declare -a added
declare -a removed

# As a precausion, if either list is empty, something might have gone wrong and we should exit in case we delete all nodes in error
# When using hostgroups this is expected behaviour, so need to exit 0 rather than cause error.
if [ ${#oldlist[@]} -eq 0 ]; then
  echo "Couldn't find any entries in old list of compute nodes. Exiting'"
  exit 0
fi
if [ ${#newlist[@]} -eq 0 ]; then
  echo "Couldn't find any entries in the new list compute nodes. Exiting'"
  exit 0
fi

#Filter duplicate entries.
declare -a unqoldlist
for oip in "${oldlist[@]}"; do	
	if [ ${#unqoldlist[@]} -eq 0 ]; then	    
    	unqoldlist+=(${oip})
	else
        found="false"
        for unoip in "${unqoldlist[@]}"; do
            if [[ "$unoip" == "$oip" ]]; then
                found="true"
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            unqoldlist+=(${oip})
        fi			
	fi	
done

# Cycle through old list to find removed compute nodes
for oip in "${unqoldlist[@]}"; do
  echo "process old list ip ${oip}"
  if  ping -c 1 -W 1 "${oip}"; then 

	  if [[ "${newlist[@]}" =~ "${oip}" ]]; then
	    echo "${oip} is still here"
	  fi

	  if [[ ! " ${newlist[@]} " =~ " ${oip} " ]]; then
	    # whatever you want to do when arr doesn't contain value
	    echo "remove ip ${oip}"
	    removed+=(${oip})
	  fi
  else
 	echo "${oip} cannot be accessed, remove it"
 	removed+=(${oip})
  fi 	
done

# Cycle through new list to find compute nodes
for nip in "${newlist[@]}"; do
  echo "process NEW list ip ${nip}"
  if [[ "${unqoldlist[@]}" =~ "${nip}" ]]; then
    echo "${nip} is still here, new list"
  fi

  if [[ ! " ${unqoldlist[@]} " =~ " ${nip} " ]]; then
    # whatever you want to do when arr doesn't contain value
    
    END=5
    x=$END
	while [ $x -gt 0 ]; 
	do 
		x=$(($x-1))	
    	pingcmd=$(ping -c 1 -W 1 "${nip}")
	    RC=$?
	    if [ $RC -eq 0 ]; then
	      break
	    else
	      echo "cannot ping ${nip} sleep 60s"
	      sleep 60  
	    fi
	    
    done
    added+=(${nip})
  fi
done

if [[ -n ${removed} ]]; then
    echo "sleep 300s to allow node destruction"
    sleep 300
    for index in "${!removed[@]}"
    do
        delnode=`oc get nodes | grep ${removed[index]} | awk '{print $1}'`
        oc adm manage-node $delnode --schedulable=false
        oc adm drain $delnode [--pod-selector=<pod_selector>]
        if oc delete node $delnode; then
            sed -i -e "/${removed[index]}/d" /etc/ansible/hosts
        else
            printf "\033[31m[ERROR] Delete compute node failed\033[0m\n"
            exit 1
        fi
    done
    # Backup the origin list and replace
    mv ${OLDLIST} ${OLDLIST}-$(date +%Y%m%dT%H%M%S)
    mv ${NEWLIST} ${OLDLIST}
fi

if [[ -n ${added} ]]; then
    echo "sleep 1200s to allow node preparation"
    sleep 1200
    for index in "${!added[@]}"
    do
        sshpass -p $os_password ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no ${added[index]}.$vm_domain_name
    done
    if ! grep -q "new_nodes" /etc/ansible/hosts; then
        sed -i -e '/^\[OSEv3\:vars\]/i new_nodes' /etc/ansible/hosts
        echo "[new_nodes]" >> /etc/ansible/hosts
    fi
    for index in "${!added[@]}"
    do
        echo "${added[index]}.$vm_domain_name openshift_node_group_name='node-config-compute'" >> /etc/ansible/hosts
    done
    cd /usr/share/ansible/openshift-ansible
    if ansible-playbook playbooks/openshift-node/scaleup.yml; then
        printf "\033[32m[*] Add new compute node successfully \033[0m\n"
        for index in "${!added[@]}"
        do
            sed -i -e "/^\[new\_nodes\]/i ${added[index]}.$vm_domain_name openshift_node_group_name='node-config-compute'" /etc/ansible/hosts
        done
        if grep -q "[glusterfs]" /etc/ansible/hosts; then
            for index in "${!added[@]}"
            do
                sed -i -e "/^\[glusterfs\]/a ${added[index]}.$vm_domain_name glusterfs_devices='[ \"\/dev\/sdb\" ]'" /etc/ansible/hosts
            done
        fi
        # Backup the origin list and replace
		mv ${OLDLIST} ${OLDLIST}-$(date +%Y%m%dT%H%M%S)
		mv ${NEWLIST} ${OLDLIST}
    else
        printf "\033[31m[ERROR] Add new compute node failed\033[0m\n"
        exit 1
    fi
fi
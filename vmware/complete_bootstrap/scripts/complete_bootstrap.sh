#!/bin/bash

###
# Check if boostrap is completed
###
KUBECONFIG_FILE=/installer/auth/kubeconfig
CLUSTER_NAME=$1
DOMAIN_NAME=$2
INFRA_IP=$3
NODES=$4

#echo ${INFRA_IP} api.${CLUSTER_NAME}.${DOMAIN_NAME} | sudo tee -a /etc/hosts

echo "Waiting 2 minutes for nodes to initialize."
sleep 120 

if [ -f "/installer/.install_complete" ]; then
	if [ $(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get nodes --no-headers | wc -l) -lt ${NODES} ]; then #scale up
		echo "Adding nodes..."
    	while [ $(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get nodes --no-headers | wc -l) -lt ${NODES} ]; do 
        	if [ $(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get csr | grep Pending | wc -l) -ne 0 ]; then
            	sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get csr | grep Pending | sed 's/\s.*$//' | xargs sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc adm certificate approve
        	fi
        	sleep 5
    	done

    	echo "Bootstrap CSRs approved, waiting 30 seconds for remaining node CSRs..."
    	sleep 30 
    	sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get csr | grep Pending | sed 's/\s.*$//' | xargs sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc adm certificate approve		
	fi
else
	#Initial Install
	sudo /usr/local/bin/openshift-install wait-for bootstrap-complete --dir=/installer --log-level info
	if [ $? -ne 0 ]; then
		exit 1
	fi	
	sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get csr
	if [ $? -ne 0 ]; then
		echo "No CSR found."
		exit 0
	fi
	
	while [ $(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get csr 2>/dev/null | grep Approved,Issued | wc -l) -lt $((${NODES}*2)) ]; do
    	if [ $(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get csr 2>/dev/null | grep Pending | wc -l) -ne 0 ]; then
        	sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get csr 2>/dev/null | grep Pending | sed 's/\s.*$//' | xargs sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc adm certificate approve
    	fi
    	sleep 5
	done

	echo "Waiting 2 minutes for Operators to initialize."
	sleep 120
fi






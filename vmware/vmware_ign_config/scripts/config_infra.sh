#!/bin/bash

WARN='\033[0;31m'
REGULAR='\033[0m'

function gen_key()
{
	yes y | ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa_ocp
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_rsa_ocp
}

function get_installer(){
	sudo mkdir -p /installer
	sudo curl -o /installer/openshift-install-linux-${1}.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${1}/openshift-install-linux-${1}.tar.gz
    sudo curl -o /installer/openshift-client-linux-${1}.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${1}/openshift-client-linux-${1}.tar.gz
    sudo tar xzvf /installer/openshift-install-linux-${1}.tar.gz -C /installer
    sudo tar xzvf /installer/openshift-client-linux-${1}.tar.gz -C /installer
    sudo mv /installer/oc /installer/kubectl /installer/openshift-install /usr/local/bin/
    sudo chmod +x /usr/local/bin/oc /usr/local/bin/kubectl /usr/local/bin/openshift-install
}

function create_ignition_config(){
	SSH_KEY=`sudo cat ~/.ssh/id_rsa_ocp.pub`
	sudo mv /tmp/install-config.yaml.tmpl /installer/install-config.yaml
	sudo mv /tmp/sec_bootstrap.ign /installer/sec_bootstrap.ign
	sudo mv /tmp/sec_master.ign /installer/sec_master.ign
	sudo mv /tmp/sec_worker.ign /installer/sec_worker.ign		
	sudo sed -i -e "s/@domain@/${DOMAIN}/" /installer/install-config.yaml
	sudo sed -i -e "s/@controlnodes@/${CONTROL_NODES}/" /installer/install-config.yaml
	sudo sed -i -e "s/@clustername@/${CLUSTER_NAME}/" /installer/install-config.yaml
	sudo sed -i -e "s/@vcenter@/${VCENTER}/" /installer/install-config.yaml
	sudo sed -i -e "s/@vcenteruser@/${VCENTER_USER}/" /installer/install-config.yaml
	sudo sed -i -e "s/@vcenterpassword@/${VCENTER_PASS}/" /installer/install-config.yaml
	sudo sed -i -e "s/@vcenterdatacenter@/${VCENTER_DC}/" /installer/install-config.yaml
	sudo sed -i -e "s|@vmwaredatastore@|${VM_DSTORE}|" /installer/install-config.yaml
	sudo sed -i -e "s/@pullsecret@/${PULL_SECRET_DECODE}/" /installer/install-config.yaml
	sudo sed -i -e "s|@sshkey@|${SSH_KEY}|" /installer/install-config.yaml
	sudo cp /installer/install-config.yaml /installer/install-config.yaml.bak
	sudo /usr/local/bin/openshift-install create manifests --dir=/installer/	
    sudo sed -i -e "s/mastersSchedulable: true/mastersSchedulable: false/" /installer/manifests/cluster-scheduler-02-config.yml
    sudo /usr/local/bin/openshift-install create ignition-configs --dir=/installer/
    if [ -d "/var/www/html/" ]; then
    	sudo cp /installer/bootstrap.ign /var/www/html/bootstrap.ign
    	sudo sed -i -e "s|@infra_ip@|${INFRA_IP}|" /installer/sec_bootstrap.ign
	else
		echo "Web server folder /var/www/html not found. You must copy the boostrap.ign to web server from terraform output."
	fi
}

function create_control_ign(){
	for (( i=0;i<$1;i++ )); do
		#sudo cp /installer/master.ign /installer/master${i}.ign
		sudo cp /installer/sec_master.ign /installer/sec_master${i}.ign
		sudo sed -i -e "s|@infra_ip@|${INFRA_IP}|" /installer/sec_master${i}.ign
	    CONTROL_HOST=etcd-${i}.${CLUSTER_NAME}.${DOMAIN}
		#sudo sed -i -e 's|"storage":{}|"storage": {"files": [{"filesystem": "root","group": {},"path": "/etc/hostname","user": {},"contents": {"source": "data:text/plain;charset=utf-8,controlhost","verification": {}},"mode": 420}]}|' /installer/master${i}.ign
		#sudo sed -i -e "s|controlhost|$CONTROL_HOST|" /installer/master${i}.ign
		sudo sed -i -e 's|"storage": {}|"storage": {"files": [{"filesystem": "root","group": {},"path": "/etc/hostname","user": {},"contents": {"source": "data:text/plain;charset=utf-8,controlhost","verification": {}},"mode": 420}]}|' /installer/sec_master${i}.ign
		sudo sed -i -e "s|controlhost|$CONTROL_HOST|" /installer/sec_master${i}.ign			
	done
	rm /installer/allmaster.ign
	for (( i=0;i<$1;i++ )); do
		sudo cat /installer/sec_master${i}.ign | base64 -w0 >> /installer/allmaster.ign
		echo -n , | sudo tee -a /installer/allmaster.ign
	done
}

function create_compute_ign(){
	for (( i=0;i<$1;i++ )); do
		#sudo cp /installer/worker.ign /installer/worker${i}.ign
		sudo cp /installer/sec_worker.ign /installer/sec_worker${i}.ign
		sudo sed -i -e "s|@infra_ip@|${INFRA_IP}|" /installer/sec_worker${i}.ign
		COMPUTE_HOST=compute-${i}.${CLUSTER_NAME}.${DOMAIN}
		#sudo sed -i -e 's|"storage":{}|"storage": {"files": [{"filesystem": "root","group": {},"path": "/etc/hostname","user": {},"contents": {"source": "data:text/plain;charset=utf-8,computehost","verification": {}},"mode": 420}]}|' /installer/worker${i}.ign
		#sudo sed -i -e "s|computehost|$COMPUTE_HOST|" /installer/worker${i}.ign
		sudo sed -i -e 's|"storage": {}|"storage": {"files": [{"filesystem": "root","group": {},"path": "/etc/hostname","user": {},"contents": {"source": "data:text/plain;charset=utf-8,computehost","verification": {}},"mode": 420}]}|' /installer/sec_worker${i}.ign
		sudo sed -i -e "s|computehost|$COMPUTE_HOST|" /installer/sec_worker${i}.ign						
	done	
	rm /installer/allworker.ign
	for (( i=0;i<$1;i++ )); do
		cat /installer/sec_worker${i}.ign | base64 -w0 >> /installer/allworker.ign
		echo -n , | sudo tee -a /installer/allworker.ign
	done	
}

function verifyInputs() {
    if [ -z "$(echo "${DOMAIN}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}Domain name is missing; Exiting...${REGULAR}"
        exit 1
    fi
	if [ -z "$(echo "${CLUSTER_NAME}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}Cluster name is missing; Exiting...${REGULAR}"
        exit 1
    fi
	if [ -z "$(echo "${VCENTER}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}vCenter name is missing; Exiting...${REGULAR}"
        exit 1
    fi
	if [ -z "$(echo "${VCENTER_USER}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}vCenter user name is missing; Exiting...${REGULAR}"
        exit 1
    fi
	if [ -z "$(echo "${VCENTER_PASS}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}vCenter user password is missing; Exiting...${REGULAR}"
        exit 1
    fi
	if [ -z "$(echo "${VCENTER_DC}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}vCenter data center name is missing; Exiting...${REGULAR}"
        exit 1
    fi
	if [ -z "$(echo "${VM_DSTORE}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}VMware data store name is missing; Exiting...${REGULAR}"
        exit 1
    fi
	if [ -z "$(echo "${PULL_SECRET}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}Image pull secret is missing; Exiting...${REGULAR}"
        exit 1
    fi
	if [ -z "$(echo "${OCP_VERSION}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}OCP version is missing; using default version 4.2.0...${REGULAR}"
    fi
	if [ -z "$(echo "${CONTROL_NODES}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}Number of control nodes is missing; using default nodes 3...${REGULAR}"
    fi
	if [ -z "$(echo "${COMPUTE_NODES}" | tr -d '[:space:]')" ]; then
        echo -e "${WARN}Number of compute nodes is missing; using default nodes 2...${REGULAR}"
    fi            
}    

## Gather information provided via the command line parameters
while test ${#} -gt 0; do
    [[ $1 =~ ^-oc|--ocversion ]]           && { OCP_VERSION="${2}";                      shift 2; continue; };
    [[ $1 =~ ^-d|--domain ]]          && { DOMAIN="${2}";                    shift 2; continue; };
    [[ $1 =~ ^-n|--controlnodes ]]     && { CONTROL_NODES="${2}";                     shift 2; continue; };    	
	[[ $1 =~ ^-m|--computenodes ]]     && { COMPUTE_NODES="${2}";                     shift 2; continue; };    	
    [[ $1 =~ ^-cn|--clustername ]]      && { CLUSTER_NAME="${2}";                shift 2; continue; };
    [[ $1 =~ ^-vc|--vcenter ]]          && { VCENTER="${2}";              shift 2; continue; };
    [[ $1 =~ ^-vu|--vcenteruser ]]      && { VCENTER_USER="${2}";          shift 2; continue; };
    [[ $1 =~ ^-vp|--vcenterpassword ]]  && { VCENTER_PASS="${2}";            shift 2; continue; };
    [[ $1 =~ ^-vd|--vcenterdatacenter ]]      && { VCENTER_DC="${2}";                shift 2; continue; };
    [[ $1 =~ ^-vs|--vmwaredatastore ]]     && { VM_DSTORE="${2}";               shift 2; continue; };
    [[ $1 =~ ^-s|--pullsecret ]]     && { PULL_SECRET="${2}";         shift 2; continue; };
    [[ $1 =~ ^-h|--host ]]     && { INFRA_IP="${2}";         shift 2; continue; };	
    break;
done

verifyInputs

OCP_VERSION=${OCP_VERSION:-"4.2.0"}
CONTROL_NODES=${CONTROL_NODES:-"3"}
COMPUTE_NODES=${COMPUTE_NODES:-"2"}
if [ -f "/installer/.install_complete" ]; then
	echo "Scaling operation"
	KUBECONFIG_FILE=/installer/auth/kubeconfig
	CURRENT_CONTROL_NODES=$(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get nodes --selector=node-role.kubernetes.io/master --no-headers | wc -l)
	CURRENT_COMPUTE_NODES=$(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get nodes --selector=node-role.kubernetes.io/worker --no-headers | wc -l)
	if [ $CURRENT_CONTROL_NODES -lt ${CONTROL_NODES} ]; then #scale up master
		echo "Scale up master, generate ign files for new nodes"
		sudo cp /installer/master /installer/master.bak
		sudo cp /var/www/html/master.ign /var/www/html/master.ign.bak		
		sudo curl -o /installer/master -k https://api-int.${CLUSTER_NAME}.${DOMAIN}:22623/config/master
		sudo cp /installer/master /var/www/html/master.ign		
		create_control_ign ${CONTROL_NODES}
	fi
	if [ $CURRENT_COMPUTE_NODES -lt ${COMPUTE_NODES} ]; then #scale up	worker
		echo "Scale up worker, generate ign files for new nodes"
		sudo cp /installer/worker /installer/worker.bak	
		sudo cp /var/www/html/worker.ign /var/www/html/worker.ign.bak		
		sudo curl -o /installer/worker -k https://api-int.${CLUSTER_NAME}.${DOMAIN}:22623/config/worker
		sudo cp /installer/worker /var/www/html/worker.ign		
		create_compute_ign ${COMPUTE_NODES}
	fi	
else
	echo "Initial install"
	PULL_SECRET_DECODE=`echo $PULL_SECRET | base64 -d`
	gen_key
	get_installer $OCP_VERSION		
	create_ignition_config
	create_control_ign ${CONTROL_NODES}
	create_compute_ign ${COMPUTE_NODES}
fi

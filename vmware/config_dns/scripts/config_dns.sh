#!/bin/bash

## Check if a command exists
function command_exists() {
    type "$1" &> /dev/null;
}

## Wait to obtain update lock
function wait_apt_lock()
{
    sleepC=5
    while [[ -f /var/lib/dpkg/lock  || -f /var/lib/apt/lists/lock ]]
    do
      sleep $sleepC
      echo "    Checking lock file /var/lib/dpkg/lock or /var/lib/apt/lists/lock"
      [[ `sudo lsof 2>/dev/null | egrep 'var.lib.dpkg.lock|var.lib.apt.lists.lock'` ]] || break
      let 'sleepC++'
      if [ "$sleepC" -gt "50" ] ; then
    lockfile=`sudo lsof 2>/dev/null | egrep 'var.lib.dpkg.lock|var.lib.apt.lists.lock'|rev|cut -f1 -d' '|rev`
        echo "Lock $lockfile still exists, waited long enough, attempt apt-get. If failure occurs, you will need to cleanup $lockfile"
        continue
      fi
    done
}

## Use Python installation to identify the platform and version
function identifyPlatform() {
    if command_exists python; then
        PLATFORM=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
        PLATFORM_VERSION=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f2 | rev`
    else
        if command_exists python3; then
            PLATFORM=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
            PLATFORM_VERSION=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f2 | rev`
        fi
    fi
    if [[ ${PLATFORM} == *"redhat"* ]]; then
        PLATFORM="rhel"
    fi
}

## Create backup of key files
function createBackups() {
    cp -p ${RESOLV_CONF} ${RESOLV_BACKUP}
    cp -p ${HOSTS_FILE}    ${HOSTS_BACKUP}
}

## Install the 'dnsmasq' package
function installDnsmasq() {
    echo "Installing 'dnsmasq' package..."
    if [[ ${PLATFORM} == *"ubuntu"* ]]; then
        wait_apt_lock
        sudo apt-get update -y
        wait_apt_lock
        sudo apt-get install -y dnsmasq
    elif [[ ${PLATFORM} == *"rhel"* ]]; then
        sudo yum install -y dnsmasq
    fi
}

## Configure dnsmasq using given cluster information
function configureDnsmasq() {
    echo "Configuring dnsmasq..."
    cp -p ${CONFIG_FILE} ${CONFIG_FILE}.orig
    cat > ${CONFIG_FILE} <<EOT
## General dnsmasq settings
domain-needed
strict-order
bogus-priv
expand-hosts
bind-dynamic
log-queries
resolv-file=${RESOLV_DNSMASQ}

listen-address=::1,127.0.0.1,${DNS_SERVER_IP},${CLUSTER_IP}
domain=${DOMAIN_NAME}
local=/${DOMAIN_NAME}/
EOT

    ## Add existing upstream name server(s) to config file
    echo "## Upstream DNS server(s)" >> ${CONFIG_FILE}
    for ns in `cat ${RESOLV_BACKUP} | grep nameserver | awk '{print $2}'`; do
        echo "server=${ns}" >> ${CONFIG_FILE}
    done
    
    ## Replace upstream server(s) in /etc/resolv.conf with localhost
    echo "nameserver 127.0.0.1" > ${RESOLV_CONF}
    
    ## Set cluster IP as primary name server to be used by dnsmasq
    touch ${RESOLV_DNSMASQ}
    echo "search ${DOMAIN_NAME}"       >  ${RESOLV_DNSMASQ}
    echo "nameserver ${DNS_SERVER_IP}" >> ${RESOLV_DNSMASQ}
}

## Add DNS records for the cluster and services
function addClusterDnsRecords() {
    echo "Adding Cluster DNS records..."
    ## Add DNS records for Kubernetes API to /etc/hosts
    echo "## Kubernetes API" >> ${HOSTS_FILE}
    for prefix in api api-int; do
        echo "${CLUSTER_IP}    ${prefix}.${CLUSTER_NAME}.${DOMAIN_NAME}" >> ${HOSTS_FILE}
    done

    ## Add wildcard DNS record for Routes to /etc/dnsmasq.conf
    echo "## Routes" >> ${CONFIG_FILE}
    echo "address=/apps.${CLUSTER_NAME}.${DOMAIN_NAME}/${CLUSTER_IP}" >> ${CONFIG_FILE}
}

## Add DNS records for the nodes in the cluster
function addNodeDnsRecords() {
	A_NODE_IP=$1
	A_NODE_NAME=$2
	CHANGED=false
    if [ "${ACTION}" == "addmaster" ]; then
    	if grep -q "$A_NODE_IP " ${HOSTS_FILE}
    	then
    		echo "addNodeDnsRecords Master IP ${A_NODE_IP} added to hosts file and DNS file. Skip ${A_NODE_IP}."
    	else
	        ## Determine next available index based on last index of any previously added master nodes
	        index=0
	        lastIndex=$(cat ${CONFIG_FILE} | grep srv-host=_etcd | awk -F',etcd-' '{print $2}' | cut -d'.' -f1 | sort -nr | head -n1)
	        if [ ! -z ${lastIndex} ]; then
	            ## Increment index to next available number
	            index=$((lastIndex+1))
	        fi
	    
	        ## Add service for master node to config file
	        port=2380
	        priority=0
	        weight=10
	        masterNode="etcd-${index}.${CLUSTER_NAME}.${DOMAIN_NAME}"
	        service="_etcd-server-ssl._tcp.${CLUSTER_NAME}.${DOMAIN_NAME}"
	        line=srv-host=${service},${masterNode},${port},${priority},${weight}
	        
			if grep -Fxq "$line" ${CONFIG_FILE}
			then
	    		echo "addNodeDnsRecords $line found, do not add to dnsmasq.conf"
			else
	   			echo "addNodeDnsRecords $line not found, add to dnsmasq.conf"
	   			echo "$line" >> ${CONFIG_FILE}
	   			CHANGED=true
			fi
	        ## Add IP address for master node to hosts file
	        line="${A_NODE_IP}  ${masterNode}  ${A_NODE_NAME}"
			if grep -Fxq "$line" ${HOSTS_FILE}
			then
	    		echo "addNodeDnsRecords $line found, do not add to ${HOSTS_FILE}"
			else
	   			echo "addNodeDnsRecords $line not found, add to ${HOSTS_FILE}"
	   			echo "$line" >> ${HOSTS_FILE}
	   			CHANGED=true
			fi
		fi
    elif [ "${ACTION}" == "addworker" ]; then
        ## Add IP address for worker node to hosts file
        line="${A_NODE_IP}  ${A_NODE_NAME}.${CLUSTER_NAME}.${DOMAIN_NAME}"
		if grep -Fxq "$line" ${HOSTS_FILE}
		then
    		echo "addNodeDnsRecords $line found, do not add to ${HOSTS_FILE}"
		else
   			echo "addNodeDnsRecords $line not found, add to ${HOSTS_FILE}"
   			echo "$line" >> ${HOSTS_FILE}
   			CHANGED=true
		fi        
    fi  
    if [[ "$CHANGED" == "true" ]]; then
    	touch /tmp/.restart_dnsmasq_dns
	fi   
}

## Configure dnsmasq for DHCP using given cluster information
function configureDhcp() {
    echo "Configuring DHCP within dnsmasq..."

    ## Append DHCP configuration to dnsmasq configuration file
    cat >> ${CONFIG_FILE} <<EOT

## DHCP configuration options
interface=${DHCP_INTERFACE}
dhcp-range=${DHCP_IP_START},${DHCP_IP_END},${DHCP_NETMASK},${DHCP_LEASE_TIME}
dhcp-option=option:router,${DHCP_ROUTER_IP}
dhcp-authoritative
log-dhcp
log-queries
log-async
log-facility=/var/log/dnsmasq.log
EOT
}

## Enable and start dnsmasq
function startDnsmasq() {
	now=$(date)
    echo "${now} Starting dnsmasq..."
    sudo systemctl stop   dnsmasq
    sudo systemctl enable dnsmasq
    sudo systemctl start  dnsmasq
    echo "${now} Started dnsmasq..."
}


## Check that appropriate input values were provided
function verifyInputs() {
    ## Verify inputs for 'setup' action
    if [ "${ACTION}" == "setup" ]; then
        if [ -z "$(echo "${CLUSTER_IP}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}IP address of the cluster has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
        if [ -z "$(echo "${DNS_SERVER_IP}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}IP address of the DNS server has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
    fi
    
    ## Verify inputs for 'setup' or 'addMaster' action
    if [ "${ACTION}" == "setup"  -o  "${ACTION}" == "addmaster" ]; then
        if [ -z "$(echo "${CLUSTER_NAME}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Name of the cluster has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
        if [ -z "$(echo "${DOMAIN_NAME}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Name of the domain has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
    fi
    
    ## Verify inputs for 'setup' or 'addMaster' action
    if [ "${ACTION}" == "addmaster"  -o  "${ACTION}" == "addworker" ]; then
        if [ -z "$(echo "${NODE_IP}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}IP address of the node has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
        if [ -z "$(echo "${NODE_NAME}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Name of the node has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
    fi
    
    ## Verify inputs for 'dhcp' action
    if [ "${ACTION}" == "dhcp" ]; then
        if [ -z "$(echo "${DHCP_INTERFACE}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Interface name for DHCP requests has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
        if [ -z "$(echo "${DHCP_IP_START}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Starting IP address for range of DHCP leases has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
        if [ -z "$(echo "${DHCP_IP_END}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Ending IP address for range of DHCP leases has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
        if [ -z "$(echo "${DHCP_ROUTER_IP}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Router IP address for DHCP requests has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
        if [ -z "$(echo "${DHCP_NETMASK}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Netmask for DHCP requests has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
        if [ -z "$(echo "${DHCP_LEASE_TIME}" | tr -d '[:space:]')" ]; then
            echo "${WARN_ON}Time for DHCP leases has not been provided; Exiting...${WARN_OFF}"
            exit 1
        fi
    fi
}

## Perform the requested action
function performAction() {
	echo "performAction Perform ${ACTION}"
    ## Determine the platform
    identifyPlatform
    
    ## Install and setup DNS
    if [ "${ACTION}" == "setup" ]; then
        createBackups
        installDnsmasq
        configureDnsmasq
        addClusterDnsRecords
    	## Configuration and/or DNS records have been updated; (Re)Start dnsmasq
    	startDnsmasq        
    fi
    
    ## Configure DHCP
    if [ "${ACTION}" == "dhcp" ]; then
        configureDhcp
		## Configuration and/or DNS records have been updated; (Re)Start dnsmasq
    	startDnsmasq        
    fi
    
    ## Add / Remove DNS record for node
    if [ "${ACTION}" == "addmaster"  -o  "${ACTION}" == "addworker" ]; then
    	NUM_IPS=${#nodeiparray[@]}
    	for ((i=0; i < ${NUM_IPS}; i++)); do
        	addNodeDnsRecords ${nodeiparray[i]} ${nodenamearray[i]}
    	done
    	
    	#Clean up removed entries -- scale down
		if [ "${ACTION}" == "addmaster" ]; then
			CONTROL_IPS=`cat /etc/hosts | grep -v 192.168.1.1 | grep 192.168.1 |  grep control-plane- | awk '{ print $1}'`
			CONTROL_IP_ARRAY=($CONTROL_IPS)
			
			
			for A_CURRENT_IP in "${CONTROL_IP_ARRAY[@]}"; do
				found=false
				for A_NEW_IP in "${nodeiparray[@]}"; do
					if [[ "$A_CURRENT_IP" == "$A_NEW_IP" ]]; then
						echo "performAction Control plane IP ${A_CURRENT_IP} is present in current list"
						found=true
						break
					fi
				done
				if [[ $found == "false" ]]; then
					echo "performAction Control IP ${A_CURRENT_IP} not in current list"
					HOST=`cat /etc/hosts | grep "${A_CURRENT_IP} " | awk '{ print $2}'`
					sed -i "/${A_CURRENT_IP} /d" /etc/hosts
					sed -i "/,${A_CURRENT_IP}$/d" /etc/dnsmasq.conf
					sed -i "/,${HOST},/d" /etc/dnsmasq.conf
					sudo touch /installer/.restart_dnsmasq
				fi
			done
		fi
		
		if [ "${ACTION}" == "addworker" ]; then
			COMPUTE_IPS=`cat /etc/hosts | grep -v 192.168.1.1 | grep 192.168.1 |  grep compute- | awk '{ print $1}'`
			COMPUTE_IP_ARRAY=($COMPUTE_IPS)		   	
			
			for A_CURRENT_IP in "${COMPUTE_IP_ARRAY[@]}"; do
				found=false
				for A_NEW_IP in "${nodeiparray[@]}"; do
					if [[ "$A_CURRENT_IP" == "$A_NEW_IP" ]]; then
						echo "performAction Compute IP ${A_CURRENT_IP} is present in current list"
						found=true
						break
					fi
				done
				if [[ $found == "false" ]]; then
					echo "performAction Compute IP ${A_CURRENT_IP} not in current list"
					HOST=`cat /etc/hosts | grep "${A_CURRENT_IP} " | awk '{ print $2}'`
					sed -i "/${A_CURRENT_IP} /d" /etc/hosts		
					sed -i "/,${A_CURRENT_IP}$/d" /etc/dnsmasq.conf		
					touch /tmp/.restart_dnsmasq_dns
				fi
			done
		fi
		
		if [ -f "/tmp/.restart_dnsmasq_dns" ]; then
			## Configuration and/or DNS records have been updated; (Re)Start dnsmasq
    		startDnsmasq
    		rm /tmp/.restart_dnsmasq_dns
		fi
    fi
    
}

## Gather and verify information provided via the command line parameters
while test ${#} -gt 0; do
    [[ $1 =~ ^-ac|--action ]]         && { ACTION="${2}";          shift 2; continue; };
    [[ $1 =~ ^-ci|--clusterip ]]      && { CLUSTER_IP="${2}";      shift 2; continue; };
    [[ $1 =~ ^-cn|--clustername ]]    && { CLUSTER_NAME="${2}";    shift 2; continue; };
    [[ $1 =~ ^-dn|--domainname ]]     && { DOMAIN_NAME="${2}";     shift 2; continue; };
    [[ $1 =~ ^-ip|--dnsserverip ]]    && { DNS_SERVER_IP="${2}";   shift 2; continue; };
    [[ $1 =~ ^-ni|--nodeip ]]         && { NODE_IP="${2}";         shift 2; continue; };
    [[ $1 =~ ^-nn|--nodename ]]       && { NODE_NAME="${2}";       shift 2; continue; };
    
    [[ $1 =~ ^-di|--dhcpinterface ]]  && { DHCP_INTERFACE="${2}";  shift 2; continue; };
    [[ $1 =~ ^-dr|--dhcprouterip ]]   && { DHCP_ROUTER_IP="${2}";  shift 2; continue; };
    [[ $1 =~ ^-ds|--dhcpipstart ]]    && { DHCP_IP_START="${2}";   shift 2; continue; };
    [[ $1 =~ ^-de|--dhcpipend ]]      && { DHCP_IP_END="${2}";     shift 2; continue; };
    [[ $1 =~ ^-dm|--dhcpnetmask ]]    && { DHCP_NETMASK="${2}";    shift 2; continue; };
    [[ $1 =~ ^-dl|--dhcpleasetime ]]  && { DHCP_LEASE_TIME="${2}"; shift 2; continue; }
    break;
done
ACTION="$(echo "${ACTION}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
if [ "${ACTION}" != "setup"  -a  "${ACTION}" != "dhcp"  -a  "${ACTION}" != "addmaster"  -a  "${ACTION}" != "addworker" ]; then
    echo "${WARN_ON}Action (e.g. setup, dhcp, addMaster, addWorker) has not been specified; Exiting...${WARN_OFF}"
    exit 1
fi
IFS=',' read -a NODEIPARR <<< "${NODE_IP}"
nodeiparray=()
for A_NODE_IP in "${NODEIPARR[@]}"; do
        if [[ $A_NODE_IP == "192.168.1"* ]]; then
                nodeiparray+=( $A_NODE_IP )
        fi
done
IFS=',' read -a nodenamearray <<< "${NODE_NAME}"
echo "IPs to process ${nodeiparray[*]}"
verifyInputs

## Default variable values
CONFIG_FILE="/etc/dnsmasq.conf"
HOSTS_BACKUP="/etc/hosts.backup"
HOSTS_FILE="/etc/hosts"
RESOLV_BACKUP="/etc/resolv.conf.backup"
RESOLV_CONF="/etc/resolv.conf"
RESOLV_DNSMASQ="/etc/resolv.dnsmasq"
WARN_ON='\033[0;31m'
WARN_OFF='\033[0m'
PLATFORM="unknown"


## Perform the requested action
performAction

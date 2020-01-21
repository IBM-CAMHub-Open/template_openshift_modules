#!/bin/bash

OPS=${1}
IFS=',' read -a NODEIPARR <<< "${2}"
iparray=()
for A_NODE_IP in "${NODEIPARR[@]}"; do
        if [[ $A_NODE_IP == "192.168.1"* ]]; then
                iparray+=( $A_NODE_IP )
        fi
done
echo "IPs to process ${iparray[*]}"
ISBOOT=${3:-"false"}

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

# Check if a command exists
function command_exists() {
  type "$1" &> /dev/null;
}

# Install the HAProxy, depending upon the platform
function install_haproxy() {
    echo "Installing HAProxy"
    if [[ $PLATFORM == *"ubuntu"* ]]; then
        wait_apt_lock
        sudo apt-get update -y
        wait_apt_lock
        sudo apt-get install -y haproxy
    elif [[ $PLATFORM == *"rhel"* ]]; then
        sudo yum -y install haproxy
    fi
    setsebool -P haproxy_connect_any=1
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
}

# Restart the HAProxy
function start_lb_server() {
    echo "Starting HAProxy"
    systemctl restart haproxy
}

function gen_random_name(){
	while true
	do
		NAME=$1$RANDOM
		FOUND=`sudo awk /" $NAME "/ /etc/haproxy/haproxy.cfg`
		if [ -n "$FOUND" ]; then
			continue		
		else
			break
		fi
	done
	echo $NAME
}

function create_api_lb_endpoints(){
    NUM_IPS=${#iparray[@]}
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
    for ((i=0; i < ${NUM_IPS}; i++)); do
        NAME=$(gen_random_name control)
        API="\ \ \ \ server ${NAME} ${iparray[i]}:6443 check"
        MCS="\ \ \ \ server ${NAME} ${iparray[i]}:22623 check"
        line="${iparray[i]}:6443 check"
        if grep -q "$line" /etc/haproxy/haproxy.cfg
        then 
        	echo "${API} and ${MCS} already added" 
        else 
        	echo "${API} and ${MCS} not found. Add ${API} and ${MCS}"        
        	LN=`sudo awk /^"backend openshift-api-server"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        	LN=$((LN + 2))
        	sudo sed -i -e "${LN} a ${API}" /etc/haproxy/haproxy.cfg
        	LN1=`sudo awk /^"backend machine-config-server"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        	LN1=$((LN1 + 2))
        	sudo sed -i -e "${LN1} a ${MCS}" /etc/haproxy/haproxy.cfg
    	fi
    done
	#Scale down remove ips    
	CURRENT_APIS=`cat /etc/haproxy/haproxy.cfg | grep "server control" | grep ":6443" | awk '{print $3}' | awk -F":" '{print $1}'`
	CURRENT_API_ARRAY=($CURRENT_APIS)
    for A_CURRENT_IP in "${CURRENT_API_ARRAY[@]}"; do
		found=false
		for A_NEW_IP in "${iparray[@]}"; do
			if [[ "$A_CURRENT_IP" == "$A_NEW_IP" ]]; then
				echo "Control plane IP ${A_CURRENT_IP} is present in current list"
				found=true
				break
			fi
		done
		if [[ $found == "false" ]]; then
			echo "Control IP ${A_CURRENT_IP} not in current list"
			delete_api_lb_endpoints ${A_CURRENT_IP}
		fi
	done    
    start_lb_server
}

function create_app_lb_endpoints(){
    NUM_IPS=${#iparray[@]}
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
	FOUND=`sudo awk /^"frontend ingress-http"$/ /etc/haproxy/haproxy.cfg`
	if [ -z "$FOUND" ]; then
		cat /tmp/lb_app.tmpl | sudo tee -a /etc/haproxy/haproxy.cfg > /dev/null	 		
	fi    	
    for ((i=0; i < ${NUM_IPS}; i++)); do
        NAME=$(gen_random_name compute)
        API="\ \ \ \ server ${NAME} ${iparray[i]}:80 check"
        MCS="\ \ \ \ server ${NAME} ${iparray[i]}:443 check"
		line="${iparray[i]}:80 check"
        if grep -q "$line" /etc/haproxy/haproxy.cfg
        then 
        	echo "${API} and ${MCS} already added"
    	else  
    		echo "${API} and ${MCS} not found. Add ${API} and ${MCS}"      
	        LN=`sudo awk /^"backend ingress-http"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
	        LN=$((LN + 2))
	        sudo sed -i -e "${LN} a ${API}" /etc/haproxy/haproxy.cfg
	        LN1=`sudo awk /^"backend ingress-https"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
	        LN1=$((LN1 + 2))
	        sudo sed -i -e "${LN1} a ${MCS}" /etc/haproxy/haproxy.cfg
	    fi
    done
	#Scale down remove ips    
	CURRENT_APIS=`cat /etc/haproxy/haproxy.cfg | grep "server compute" | grep ":80" | awk '{print $3}' | awk -F":" '{print $1}'`
	CURRENT_API_ARRAY=($CURRENT_APIS)
    for A_CURRENT_IP in "${CURRENT_API_ARRAY[@]}"; do
		found=false
		for A_NEW_IP in "${iparray[@]}"; do
			if [[ "$A_CURRENT_IP" == "$A_NEW_IP" ]]; then
				echo "Compute IP ${A_CURRENT_IP} is present in current list"
				found=true
				break
			fi
		done
		if [[ $found == "false" ]]; then
			echo "Compute IP ${A_CURRENT_IP} not in current list"
			delete_app_lb_endpoints ${A_CURRENT_IP}
		fi
	done
    start_lb_server
}

function create_boot_endpoints(){
	API="    server bootstrap ${iparray[0]}:6443 check"
	MCS="    server bootstrap ${iparray[0]}:22623 check"
	FOUND=`sudo awk /^"frontend openshift-api-server"$/ /etc/haproxy/haproxy.cfg`
	if [ -z "$FOUND" ]; then
		cp /tmp/lb_api.tmpl /tmp/lb_api.tmpl.orig
		sudo sed -i -e "s/@boot_6443@/${API}/" /tmp/lb_api.tmpl
		sudo sed -i -e "s/@boot_22623@/${MCS}/" /tmp/lb_api.tmpl
		cat /tmp/lb_api.tmpl | sudo tee -a /etc/haproxy/haproxy.cfg > /dev/null	
		start_lb_server
	fi
}

function delete_api_lb_endpoints(){
	sudo sed -i -e "/${1}:6443 check/d" /etc/haproxy/haproxy.cfg
	sudo sed -i -e "/${1}:22623 check/d" /etc/haproxy/haproxy.cfg
}

function delete_app_lb_endpoints(){
	sudo sed -i -e "/${1}:80 check/d" /etc/haproxy/haproxy.cfg
	sudo sed -i -e "/${1}:443 check/d" /etc/haproxy/haproxy.cfg
}

# Identify the platform and version using Python
PLATFORM="unknown"
if command_exists python; then
    PLATFORM=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
    PLATFORM_VERSION=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f2 | rev`
else
    if command_exists python3; then
        PLATFORM=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
        PLATFORM_VERSION=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f2 | rev`
    fi
fi
if [[ $PLATFORM == *"redhat"* ]]; then
    PLATFORM="rhel"
fi

# Perform tasks to setup HAProxy LB server
if [ "$OPS" = "install" ]; then
	install_haproxy
elif [ "$OPS" = "configapi" ]; then 
	if [ "$ISBOOT" = "true" ]; then	
		if [ -f "/installer/.install_complete" ]; then
			echo "Already bootstrapped. Ignore bootstrap step."
		else
			create_boot_endpoints
		fi
	else
		create_api_lb_endpoints
	fi
elif [ "$OPS" = "configapp" ]; then 
	create_app_lb_endpoints
elif [ "$OPS" = "removeapi" ]; then 
	sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
	NUM_IPS=${#iparray[@]}
	for ((i=0; i < ${NUM_IPS}; i++)); do
		delete_api_lb_endpoints ${iparray[i]}
	done
	start_lb_server
elif [ "$OPS" = "removeapp" ]; then 
	sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
	NUM_IPS=${#iparray[@]}
	for ((i=0; i < ${NUM_IPS}; i++)); do
		delete_app_lb_endpoints ${iparray[i]}
	done
	start_lb_server			
fi
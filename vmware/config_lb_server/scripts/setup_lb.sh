#!/bin/bash

OPS=${1}
IFS=',' read -a iparray <<< "${2}"
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
        LN=`sudo awk /^"backend openshift-api-server"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        LN=$((LN + 2))
        sudo sed -i -e "${LN} a ${API}" /etc/haproxy/haproxy.cfg
        LN1=`sudo awk /^"backend machine-config-server"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        LN1=$((LN1 + 2))
        sudo sed -i -e "${LN1} a ${MCS}" /etc/haproxy/haproxy.cfg
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
        LN=`sudo awk /^"backend ingress-http"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        LN=$((LN + 2))
        sudo sed -i -e "${LN} a ${API}" /etc/haproxy/haproxy.cfg
        LN1=`sudo awk /^"backend ingress-https"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        LN1=$((LN1 + 2))
        sudo sed -i -e "${LN1} a ${MCS}" /etc/haproxy/haproxy.cfg
    done
    start_lb_server
}

function create_boot_endpoints(){
	API="    server bootstrap ${iparray[0]}:6443 check"
	MCS="    server bootstrap ${iparray[0]}:22623 check"
	cp /tmp/lb_api.tmpl /tmp/lb_api.tmpl.orig
	sudo sed -i -e "s/@boot_6443@/${API}/" /tmp/lb_api.tmpl
	sudo sed -i -e "s/@boot_22623@/${MCS}/" /tmp/lb_api.tmpl
	cat /tmp/lb_api.tmpl | sudo tee -a /etc/haproxy/haproxy.cfg > /dev/null	
	start_lb_server
}

function delete_api_lb_endpoints(){
    NUM_IPS=${#iparray[@]}
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig	
	for ((i=0; i < ${NUM_IPS}; i++)); do
		sudo sed -i -e "/${iparray[i]}:6443 check/d" /etc/haproxy/haproxy.cfg
		sudo sed -i -e "/${iparray[i]}:22623 check/d" /etc/haproxy/haproxy.cfg
	done
	start_lb_server
}

function delete_app_lb_endpoints(){
    NUM_IPS=${#iparray[@]}
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig	
	for ((i=0; i < ${NUM_IPS}; i++)); do
		sudo sed -i -e "/${iparray[i]}:80 check/d" /etc/haproxy/haproxy.cfg
		sudo sed -i -e "/${iparray[i]}:443 check/d" /etc/haproxy/haproxy.cfg
	done
	start_lb_server
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
		create_boot_endpoints
	else
		create_api_lb_endpoints
	fi
elif [ "$OPS" = "configapp" ]; then 
	create_app_lb_endpoints
elif [ "$OPS" = "removeapi" ]; then 
	delete_api_lb_endpoints
elif [ "$OPS" = "removeapp" ]; then 
	delete_app_lb_endpoints			
fi
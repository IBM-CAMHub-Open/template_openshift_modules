#!/bin/bash

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

# Install the Web server, depending upon the platform
function install_web_server() {
    echo "Installing Web server"
    if [[ $PLATFORM == *"ubuntu"* ]]; then
        wait_apt_lock
        sudo apt-get update -y
        wait_apt_lock
        sudo apt-get install apache2
        sudo ufw allow 'Apache Full'
        #HAProxy LB is listening on 80/443
        echo "Change HTTP Listen port to 8080"
        sudo sed -i -e "s/Listen 80/Listen 8080/" /etc/apache2/ports.conf
        sudo sed -i -e "s/Listen 443/Listen 8443/" /etc/apache2/ports.conf
    elif [[ $PLATFORM == *"rhel"* ]]; then
        sudo yum install -y httpd
        #HAProxy LB is listening on 80/443
		echo "Change HTTP Listen port to 8080"
    	sudo sed -i -e "s/Listen 80/Listen 8080/" /etc/httpd/conf/httpd.conf        	
    fi
}


# Restart the Web server, depending upon the platform
function start_web_server() {
    echo "Starting Web server"
    if [[ $PLATFORM == *"ubuntu"* ]]; then
    	sudo systemctl status apache2
    elif [[ $PLATFORM == *"rhel"* ]]; then
    	sudo systemctl restart httpd
	fi
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

# Perform tasks to setup Apache Web server
install_web_server
start_web_server
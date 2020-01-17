#!/bin/bash

NODES=$1
TYPE=$2
if [ "${TYPE}" == "compute" ]; then
	echo {\"control\":\"\"}
else
	if [ -f /tmp/dhcp_control.log ]; then
		sudo rm /tmp/dhcp_control.log
	fi
	echo "Waiting 2 minutes for VMs to initialize." > /tmp/dhcp_control.log
	sleep 120	
	while true; do
		CURRENT_NODES_DHCP_LEASE=`sudo cat /var/lib/dnsmasq/dnsmasq.leases | awk '{print $4}' | grep "etcd-" | wc -l`
		CONTROL=`sudo cat /var/lib/dnsmasq/dnsmasq.leases | grep "etcd-"`
		if [ $NODES -eq $CURRENT_NODES_DHCP_LEASE ]; then
			echo "Found all etcd nodes $CONTROL in dnsmasq.leases. Get the assigned IP addresses." >> /tmp/dhcp_control.log
			break;
		else
			echo "Found nodes $CONTROL in dnsmasq.leases. Wait for all etcd to be assigned a DNS name" >> /tmp/dhcp_control.log
		fi
	done
	IPS=`sudo cat /var/lib/dnsmasq/dnsmasq.leases | grep etcd- | rev | sort -k2 -n | rev | awk '{print $3}'`
	FILTEREDARR=($IPS)
	FILTEREDARRLIST=$(IFS=, ; echo "${FILTEREDARR[*]}")
	echo {\"control\":\"${FILTEREDARRLIST}\"}
fi
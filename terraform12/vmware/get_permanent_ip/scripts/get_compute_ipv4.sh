#!/bin/bash

NODES=$1
TYPE=$2
if [ "${TYPE}" == "control" ]; then
	echo {\"compute\":\"\"}
else
	if [ -f /tmp/dhcp_computes.log ]; then
		sudo rm /tmp/dhcp_computes.log
	fi
	echo "Waiting 2 minutes for VMs to initialize." > /tmp/dhcp_computes.log
	sleep 120		
	while true; do
		CURRENT_NODES_DHCP_LEASE=`sudo cat /var/lib/dnsmasq/dnsmasq.leases | awk '{print $4}' | grep "compute" | wc -l`
		COMPUTES=`sudo cat /var/lib/dnsmasq/dnsmasq.leases | grep "compute"`
		if [ $NODES -eq $CURRENT_NODES_DHCP_LEASE ]; then
			echo "Found all compute nodes $COMPUTES in dnsmasq.leases. Get the assigned IP addresses." >> /tmp/dhcp_computes.log
			break;
		else
			echo "Found nodes $COMPUTES in dnsmasq.leases. Wait for all computes to be assigned a DNS name" >> /tmp/dhcp_computes.log
		fi
	done
	IPS=`sudo cat /var/lib/dnsmasq/dnsmasq.leases | grep compute- | rev | sort -k2 -n | rev | awk '{print $3}'`
	FILTEREDARR=($IPS)
	FILTEREDARRLIST=$(IFS=, ; echo "${FILTEREDARR[*]}")
	echo {\"compute\":\"${FILTEREDARRLIST}\"}
fi
#!/bin/bash

IFS=',' read -a nodeiparray <<< "${1}"

NUM_IPS=${#nodeiparray[@]}
OUT=
for ((i=0; i < ${NUM_IPS}; i++)); do
	MAC_ADDRESS=$(sudo ssh -o StrictHostKeyChecking=no -q -i ~/.ssh/id_rsa_ocp core@${nodeiparray[i]} ip addr | grep -B1 ${nodeiparray[i]} | head -1 | awk '{print $2'})
	sudo echo dhcp-host=${MAC_ADDRESS},${nodeiparray[i]} >> /etc/dnsmasq.conf
done
sudo systemctl restart dnsmasq
 

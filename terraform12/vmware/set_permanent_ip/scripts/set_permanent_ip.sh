#!/bin/bash

IFS=',' read -a NODEIPARR <<< "${1}"
nodeiparray=()
for A_NODE_IP in "${NODEIPARR[@]}"; do
        if [[ $A_NODE_IP == "192.168.1"* ]]; then
                nodeiparray+=( $A_NODE_IP )
        fi
done
echo "IPs to process ${nodeiparray[*]}"
CHANGED=false
NUM_IPS=${#nodeiparray[@]}
OUT=
for ((i=0; i < ${NUM_IPS}; i++)); do
	if grep ",${nodeiparray[i]}$" /etc/dnsmasq.conf
	then
		echo "MAC entry map for ${nodeiparray[i]} exists in /etc/dnsmasq.conf"
	else
		MAC_ADDRESS=$(sudo ssh -o StrictHostKeyChecking=no -q -i ~/.ssh/id_rsa_ocp core@${nodeiparray[i]} ip addr | grep -B1 ${nodeiparray[i]} | head -1 | awk '{print $2'})
		sudo echo dhcp-host=${MAC_ADDRESS},${nodeiparray[i]} >> /etc/dnsmasq.conf
		CHANGED=true
	fi
done
if [[ "$CHANGED" == "true" ]]; then
	now=$(date)
    echo "${now} Starting dnsmasq..."	
	sudo systemctl restart dnsmasq
	echo "${now} Started dnsmasq..."
fi
echo "Create install complete flag" 
touch /installer/.install_complete
 

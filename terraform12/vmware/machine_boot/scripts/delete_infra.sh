#!/bin/bash
TYPE=$1
NODES=$2
CLUSTER_NAME=$3
DOMAIN=$4
INDEX=$5
KUBECONFIG_FILE=/installer/auth/kubeconfig
if [ -f "/installer/.install_complete" ]; then	
	if [ "${TYPE}" == "compute" ]; then
		CURRENT_COMPUTE_NODES=$(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get nodes --selector=node-role.kubernetes.io/worker --no-headers | wc -l)
		if [ $CURRENT_COMPUTE_NODES -gt ${NODES} ]; then
			#for (( i=$NODES;i<$CURRENT_COMPUTE_NODES;i++ )); do
				echo "Remove compute node compute-${INDEX} from cluster"
				echo "Remove ign for worker ${INDEX}"
				sudo rm /installer/sec_worker${INDEX}.ign
				sudo rm /installer/allworker.ign
				echo "Re-generate ign for all workers"
				for (( i=0;i<$NODES;i++ )); do	
					cat /installer/sec_worker${i}.ign | base64 -w0 >> /installer/allworker.ign
					echo -n , | sudo tee -a /installer/allworker.ign
				done					
	    		sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc adm cordon compute-${INDEX}.${CLUSTER_NAME}.${DOMAIN}
	    		sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc adm drain compute-${INDEX}.${CLUSTER_NAME}.${DOMAIN} --force --delete-local-data --ignore-daemonsets
	    		sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc delete node compute-${INDEX}.${CLUSTER_NAME}.${DOMAIN}				
			#done
		fi
	elif [ "${TYPE}" == "control" ]; then
		CURRENT_CONTROL_NODES=$(sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc get nodes --selector=node-role.kubernetes.io/master --no-headers | wc -l)
		if [ $CURRENT_CONTROL_NODES -gt ${NODES} ]; then
			#for (( i=$NODES;i<$CURRENT_CONTROL_NODES;i++ )); do
				echo "Remove control node etcd-${INDEX} from cluster"
				echo "Remove ign for master ${INDEX}"
				sudo rm /installer/sec_master${INDEX}.ign		
				sudo rm /installer/allmaster.ign
				for (( i=0;i<$NODES;i++ )); do
					sudo cat /installer/sec_master${i}.ign | base64 -w0 >> /installer/allmaster.ign
					echo -n , | sudo tee -a /installer/allmaster.ign
				done						
				sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc adm cordon etcd-${INDEX}.${CLUSTER_NAME}.${DOMAIN}
	    		sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc adm drain etcd-${INDEX}.${CLUSTER_NAME}.${DOMAIN} --force --delete-local-data --ignore-daemonsets
	    		sudo KUBECONFIG=${KUBECONFIG_FILE} /usr/local/bin/oc delete node etcd-${INDEX}.${CLUSTER_NAME}.${DOMAIN}				
			#done			
		fi
	fi
else
	echo "Initial Install."
fi
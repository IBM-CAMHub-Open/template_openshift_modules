#!/bin/bash

###
# Check if boostrap node is done
###

FILE_PATH=/opt/openshift/.bootkube.done

for i in {1..60}
do
	sudo ssh -o StrictHostKeyChecking=no -q -i ~/.ssh/id_rsa_ocp core@${1} [[ -f ${FILE_PATH} ]] && echo "Bootstrap completed" && exit 0 
	echo "Wait for bootstrap node to finish control plane setup. You can login to bootstrap system ${1} from infrastructure node to monitor the progress." 
	sleep 60 
done

echo "Bootstrap of control plane failed to finish in one hour. You can login to bootstrap system ${1} from infrastructure node to monitor the progress. Terminating template setup."
exit 1
#!/bin/bash

CLUSTER_NAME=$1
DOMAIN_NAME=$2
#worker or master
TYPE=$3

for i in {1..60}
do
	response=`curl -s -o /dev/null -I -w "%{http_code}" -k https://api-int.${CLUSTER_NAME}.${DOMAIN_NAME}:22623/config/${TYPE}`
	if [ $response != 200 ]; then
		echo "Internal API returned ${response}. Wait for internal API URL to be up." 
		sleep 60
	else
		echo "Internal API can be reached."
		sudo curl -o /installer/${TYPE} -k https://api-int.${CLUSTER_NAME}.${DOMAIN_NAME}:22623/config/${TYPE}
		sudo cp /installer/${TYPE} /var/www/html/${TYPE}.ign
		exit 0
	fi	
done

echo "Internal API cannot be reached."
exit 1




	






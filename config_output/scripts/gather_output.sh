#!/bin/bash

#
#Licensed Materials - Property of IBM
#5737-E67
#(C) Copyright IBM Corporation 2019 All Rights Reserved.
#US Government Users Restricted Rights - Use, duplication or
#disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#

set -e

CLIENT_CERTIFICATE=/etc/origin/master/admin.crt
CLIENT_KEY=/etc/origin/master/admin.key
CA_CERT=/etc/origin/master/ca.crt
LOG_FILE=/tmp/gather_output.log
PARAM_ADMIN_USER=admin

while test $# -gt 0; do
  [[ $1 =~ ^-c|--cluster ]] && { PARAM_CLUSTER_NAME="${2}"; shift 2; continue; };
  [[ $1 =~ ^-as|--apisrvr ]] && { PARAM_OC_SERVER="${2}"; shift 2; continue; };
  [[ $1 =~ ^-ap|--apiport ]] && { PARAM_OC_PORT="${2}"; shift 2; continue; };
  [[ $1 =~ ^-u|--user ]] && { PARAM_ADMIN_USER="${2}"; shift 2; continue; };
  break
done

if [ -z "$PARAM_OC_SERVER" ]; then
	echo "OpenShift server name is missing" >> ${LOG_FILE}
	exit 1
fi

if [ -z "$PARAM_CLUSTER_NAME" ]; then
	PARAM_CLUSTER_NAME=$(echo ${PARAM_OC_SERVER} | sed "s/\./-/g"):${PARAM_OC_PORT}
	echo "Cluster name is missing. Using converted server name ${PARAM_CLUSTER_NAME} as clustername" >> ${LOG_FILE}
fi

if [ -z "$PARAM_OC_PORT" ]; then
	echo "OpenShift server port is missing" >> ${LOG_FILE}
	exit 1
fi

if [ -z "$PARAM_ADMIN_USER" ]; then
	echo "Admin user is missing. Using username admin" >> ${LOG_FILE}
fi



echo "Generate kube certificate data" >> ${LOG_FILE}
CLIENT_CERTIFICATE_BASE64=$(sudo cat ${CLIENT_CERTIFICATE} | base64 -w0)
CLIENT_KEY_BASE64=$(sudo cat ${CLIENT_KEY} | base64 -w0)
CA_CERTIFICATE_BASE64=$(sudo cat ${CA_CERT} | base64 -w0)
	
echo "construct kube config" >> ${LOG_FILE}	
sed -i -e "s/@@clustername@@/${PARAM_CLUSTER_NAME}/" /tmp/config_template
sed -i -e "s/@@host@@/${PARAM_OC_SERVER}/" /tmp/config_template
sed -i -e "s/@@port@@/${PARAM_OC_PORT}/" /tmp/config_template
sed -i -e "s/@@client-certificate@@/${CLIENT_CERTIFICATE_BASE64}/" /tmp/config_template
sed -i -e "s/@@client-key@@/${CLIENT_KEY_BASE64}/" /tmp/config_template
sed -i -e "s/@@certificate-authority@@/${CA_CERTIFICATE_BASE64}/" /tmp/config_template
sed -i -e "s/@@user@@/${PARAM_ADMIN_USER}/" /tmp/config_template

echo "Generate kube config" >> ${LOG_FILE}
CONFIG_BASE64=$(cat /tmp/config_template | base64 -w0)

echo "Output is:" >> ${LOG_FILE}
echo '{"cluster_name":"'"${PARAM_CLUSTER_NAME}"'","config":"'"${CONFIG_BASE64}"'","config_ca_cert_data":"'"${CA_CERTIFICATE_BASE64}"'"}' >> ${LOG_FILE}
echo '{"cluster_name":"'"${PARAM_CLUSTER_NAME}"'","config":"'"${CONFIG_BASE64}"'","config_ca_cert_data":"'"${CA_CERTIFICATE_BASE64}"'"}'

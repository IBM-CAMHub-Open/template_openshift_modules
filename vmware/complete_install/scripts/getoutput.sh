#!/bin/bash

###
# Get output for display
###
CONSOLE=""
PASSWORD=""
if [[ -f "/installer/creds" ]]; then	
	CONSOLE=`sudo awk -F " " '{print $NF}' /installer/creds | tail -2 | head -1 | cut -d'"' -f1`	
	PASSWORD=`sudo awk -F " " '{print $NF}' /installer/creds | tail -1 | cut -d'"' -f1`
fi		
BASE64_PASSWORD=`echo ${PASSWORD} | base64 -w0` 
echo {\"Console\": \"${CONSOLE}\", \"Password\": \"${BASE64_PASSWORD}\"}




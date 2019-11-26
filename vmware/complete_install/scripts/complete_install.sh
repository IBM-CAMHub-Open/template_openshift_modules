#!/bin/bash

###
# Check if boostrap is completed
###
sudo /usr/local/bin/openshift-install --dir=/installer wait-for install-complete
if [ $? -ne 0 ]; then
	exit 1
fi
sudo /usr/local/bin/openshift-install --dir=/installer wait-for install-complete 2>&1 | sudo tee /installer/creds



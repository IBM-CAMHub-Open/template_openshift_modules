# Configure DNS server (dnsmasq) for OpenShift Container Platform cluster installation
This module can be used to configure a DNS server, using the 'dnsmasq' utility, for the purposes of providing name resolution services to the OCP cluster.


## Hardware requirements

Linux VM on which the DNS server will be installed and configured.  Supported platforms include Ubuntu and RedHat.

The VM should be configured with appropriate subscriptions to any package repositories from which the 'dnsmasq' and dependent packages will be downloaded.

## Usage

This module may be used to perform four distinct actions related to configuring and maintaining the DNS server:

- Install and configure the 'dnsmasq' utility that provides the DNS functionality
- Configure the 'dnsmasq' utility to support DHCP requests
- Add one or more DNS records corresponding to the control plane (master) node(s) within the OCP cluster
- Add one or more DNS records corresponding to the worker node(s) within the OCP cluster

## Template input parameters

| Parameter Name                  | Parameter Description | Required | Allowed Values |
| :---                            | :--- | :--- | :--- |
| action                          | The action to be performed by the module execution | true | setup, dhcp, addMaster, addWorker |
| dns\_server\_ip                 | IP address of the server where DNS will be configured | true | |
| vm\_os\_user                    | Login name used to connect to the VM for the purpose of managing the DNS server; Must have 'sudo' privileges | true | |
| vm\_os\_password                | Password used to connect to the VM for the purpose of managing the DNS server; Alternative to using a private SSH key | | |
| private_key                     | Private SSH key used to connect to the VM for the purpose of managing the DNS server; Alternative to using a password | | |
| bastion_host                    | IP address or name of the server acting as a bastion host | | |
| bastion_port                    | Port used to connect to the bastion host | | |
| bastion_user                    | Login name used to connect to the bastion host | | |
| bastion_password                | Password used to connect to the bastion host | | |
| bastion\_public\_key            | Public SSH key used to connect to the bastion host | | |
| bastion\_private\_key           | Private SSH key used to connect to the bastion host | | |

For installation and configuration of the DNS server (action = setup)
| Parameter Name                  | Parameter Description | Required | Allowed Values |
| :---                            | :--- | :--- | :--- |
| cluster_ip                      | IP address (i.e. load balancer) used to access the OCP cluster | true | |
| cluster_name                    | Name of the OCP cluster | true | |
| domain_name                     | Base domain name of the OCP cluster | true | |

For configuration of the DHCP server (action = dhcp)
| Parameter Name                  | Parameter Description | Required | Allowed Values |
| :---                            | :--- | :--- | :--- |
| dhcp_interface                  | Name of the interface used to handle DHCP requests | true | |
| dhcp\_ip\_range\_start          | IP address for the start of the DHCP IP address range | true | |
| dhcp\_ip\_range\_end            | IP address for the end of the DHCP IP address range | true | |
| dhcp_netmask                    | Netmask used for the DHCP configuration | true | |
| dhcp\_lease\_time               | Length of time to be assigned to a DHCP lease | true | |

For adding DNS record(s) corresponding to the control plane (master) node(s) within the OCP cluster (action = addMaster)
| Parameter Name                  | Parameter Description | Required | Allowed Values |
| :---                            | :--- | :--- | :--- |
| cluster_name                    | Name of the OCP cluster | true | |
| domain_name                     | Base domain name of the OCP cluster | true | |
| node\_ips                       | Comma separated IP addresses corresponding to the control plane (master) nodes within the OCP cluster; List items must align with items in the node_names list | true | |
| node\_names                     | Comma separated hostnames corresponding to the control plane (master) nodes within the OCP cluster; List items must align with items in the node_ips list | true | |

For adding DNS record(s) corresponding to the worker node(s) within the OCP cluster (action = addWorker)
| Parameter Name                  | Parameter Description | Required | Allowed Values |
| :---                            | :--- | :--- | :--- |
| cluster_name                    | Name of the OCP cluster | true | |
| domain_name                     | Base domain name of the OCP cluster | true | |
| node\_ips                       | Comma separated IP addresses corresponding to the worker nodes within the OCP cluster; List items must align with items in the node_names list | true | |
| node\_names                     | Comma separated  corresponding to the worker nodes within the OCP cluster; List items must align with items in the node_ips list | true | |

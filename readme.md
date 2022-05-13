# How to deploy Openstack on Centos Stream 8

In this example we will be using Packstack to deploy Openstack on machines running Centos Stream 8. 

## Setting up Packstack host
```bash
dnf update -y

dnf config-manager --set-enable powertools
dnf install -y centos-release-openstack-yoga

dnf update -y
dnf install -y openstack-packstack

# Disable SELinux as packstack does not fully support it
setenforce 0

hostnamectl set-hostname packstack
exec bash

packstack --gen-answer-file=/root/packstack-answers.txt
```
Once the answer file has been generated we need to change the following attributes.
For our example the target host ips are as follows
- CONTROLLER 10.100.10.80
- COMPUTE 10.100.10.81, 10.100.10.82

```bash
# Default password to be used everywhere (overridden by passwords set
# for individual services or users).
CONFIG_DEFAULT_PASSWORD=hpc2022

# Specify 'y' to install OpenStack Orchestration (heat). ['y', 'n']
CONFIG_HEAT_INSTALL=y

# Comma-separated list of NTP servers. Leave plain if Packstack
# should not install ntpd on instances.
CONFIG_NTP_SERVERS=pool.ntp.org

# Server on which to install OpenStack services specific to the
# controller role (for example, API servers or dashboard).
CONFIG_CONTROLLER_HOST=10.100.10.80

# List the servers on which to install the Compute service.
CONFIG_COMPUTE_HOSTS=10.100.10.81,10.100.10.82

# List of servers on which to install the network service such as
# Compute networking (nova network) or OpenStack Networking (neutron).
CONFIG_NETWORK_HOSTS=10.100.10.80

# IP address of the server on which to install the AMQP service.
CONFIG_AMQP_HOST=10.100.10.80

# IP address of the server on which to install MariaDB. If a MariaDB
# installation was not specified in CONFIG_MARIADB_INSTALL, specify
# the IP address of an existing database server (a MariaDB cluster can
# also be specified).
CONFIG_MARIADB_HOST=10.100.10.80

# Password to use for the Identity service 'admin' user.
CONFIG_KEYSTONE_ADMIN_PW=hpc2022

# URL for the Identity service LDAP backend.
CONFIG_KEYSTONE_LDAP_URL=ldap://10.100.10.80

# Specify 'y' to provision for demo usage and testing. ['y', 'n']
CONFIG_PROVISION_DEMO=y

# IP address of the server on which to install the Redis server.
CONFIG_REDIS_HOST=10.100.10.80
```

## Setting up targets
As of this writing Packstack does not suport NetworkManager and as such we needed to fall back to network-scripts. Same applies with SELinux

- Configure network card to use a static address with network-scripts
- Disable NetworkManager and enable network
- Disable FirewallD as iptables will be configured
- Set SELinux to permissive mode


```bash
## Set the interface to static address
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-ens18
DEVICE=ens18
NAME=ens18
BOOTPROTO=static
NM_CONTROLLED=no
ONBOOT=yes
TYPE=Ethernet
IPV6INIT=no
IPADDR=10.100.10.80
NETMASK=255.255.255.0
GATEWAY=10.100.10.1
DNS1=10.100.10.1
EOF

dnf update -y

dnf config-manager --set-enabled powertools
dnf install -y network-scripts

systemctl stop NetworkManager.service
systemctl disable NetworkManager.service

systemctl start network.service
systemctl enable network.service

systemctl disable firewalld.service
systemctl stop firewalld.service; systemctl start iptables.service; systemctl start ip6tables.service

# Disable SELinux as packstack does not fully support it
setenforce 0

hostnamectl set-hostname opnstk-con-1
reboot
```

## Executing Packstack
Before we can execute packstack with our answer file we need to generate a ssh key and copy the public key to each of the node we specified in the answer file.

```bash
ssh-keygen
# Generating public/private rsa key pair.
# Enter file in wich to save the key (/root/.ssh/id_rsa):
# Enter passphrase (empty for no passphrase):
# Enter same passphrase again:

ssh-copy-id 10.100.10.80
# /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
# The authenticity of host '10.100.10.80 (10.100.10.80)' can't be established.
# ECDSA key fingerprint is SHA:...
# Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
# root@10.100.10.80's password:

# Number of key(s) added: 1

# Now try loggin into the machine, with: "ssh '10.100.10.80'"
# and check to make sure that only the key(s) you wanted were added.

ssh-copy-id 10.100.10.81
ssh-copy-id 10.100.10.82

packstack --answer-file=packstack-answers.txt
```

Once packstack finishes running (for our lab it took about 30 minuts) the Horizon dashboard should be available at <http://10.100.10.80/dashboard/>

To login use admin and the password you selected or check on the controller node in /root/keystonerc_admin.

If you selected yes for the demo then login with the user demo and use the password in the /root/keystonerc_demo file on the controller node.

## Next steps
The next step would be to figure out how to configure the nodes with multiple network cards so that we could differenciate between the type of network traffic, for example storage should run on a seperate network than the external (internet facing data).

As of this writing packstack does not fully support storage nodes, though it can be configured by enabling unsupported features, however it seems that you can configure it to work against a proffesional solution like NetApp according to the generated answers file.

## Resources
<https://www.rdoproject.org/install/packstack/>

<https://docs.openstack.org/openstack-ansible/latest/>
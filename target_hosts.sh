## Target hosts
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
setenforce 0
hostnamectl set-hostname opnstk-con-1
reboot

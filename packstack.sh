## Packstack
dnf update -y

dnf config-manager --set-enable powertools
dnf install -y centos-release-openstack-yoga

dnf update -y
dnf install -y openstack-packstack

setenforce 0
hostnamectl set-hostname packstack
exec bash

packstack --gen-answer-file=/root/packstack-ansers.txt

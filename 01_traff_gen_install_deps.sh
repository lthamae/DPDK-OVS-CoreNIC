#! /bin/bash

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y clean all
yum -y update
yum -y install dpdk dpdk-tools emacs gcc git lshw pciutils python-devel \
              python-setuptools python-pip tmux \
              tuned-profiles-cpu-partitioning wget
pip install --upgrade enum34 natsort netaddr matplotlib scapy spur

git clone https://github.com/fleitner/XenaPythonLib
cd XenaPythonLib/
python setup.py install

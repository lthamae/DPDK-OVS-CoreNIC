#! /bin/bash

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y clean all
yum -y update
yum -y install aspell aspell-en autoconf automake bc checkpolicy \
               desktop-file-utils dpdk dpdk-tools driverctl emacs gcc \
               gcc-c++ gdb git graphviz groff hwloc intltool kernel-devel \
               libcap-ng libcap-ng-devel libguestfs libguestfs-tools-c libtool \
               libvirt lshw openssl openssl-devel openvswitch procps-ng python \
               python-six python-twisted-core python-zope-interface \
               qemu-kvm-rhev rpm-build selinux-policy-devel sshpass sysstat \
               systemd-units tcpdump time tmux tuned-profiles-cpu-partitioning \
               virt-install virt-manager wget numactl-libs numactl-devel

echo "aspell-en might have complained during this step, if it did follow the"
echo "suggested steps to skip the broken packages, and then enable the disabled"
echo "repos as suggested by yum to install aspell-en"


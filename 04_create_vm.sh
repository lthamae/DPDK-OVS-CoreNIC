#! /bin/bash

grab_image () {
    echo "grabbing rhel-server-7.4-x86_64-kvm vm image from bonobo"
    scp bbslave@bonobo:/var/www/html/disa/rhel-server-7.4-x86_64-kvm.qcow2 .
}

grab_image
mkdir -p /opt/images
cp rhel-server-7.4-x86_64-kvm.qcow2 /opt/images

systemctl enable libvirtd.service
systemctl start libvirtd.service

cpulist=$(cat /etc/tuned/cpu-partitioning-variables.conf | grep ^isolated | cut -d '=' -f 2)
# Starting at cpu3, as 1 and 2 had been used for DPDK
cpu0=$(echo $cpulist | cut -d ',' -f 3)
cpu1=$(echo $cpulist | cut -d ',' -f 4)
cpu2=$(echo $cpulist | cut -d ',' -f 5)
cpu3=$(echo $cpulist | cut -d ',' -f 6)
cpu4=$(echo $cpulist | cut -d ',' -f 7)

define_vm () {
    echo "Assigning cpus: $cpu0,$cpu1,$cpu2,$cpu3 to the vm"
    virt-install --connect=qemu:///system \
      --name=rhel_loopback \
      --disk path=/opt/images/rhel-server-7.4-x86_64-kvm.qcow2,format=qcow2 \
      --ram 8192 \
      --memorybacking hugepages=on,size=1024,unit=M,nodeset=0 \
      --vcpus=4,cpuset=$cpu0,$cpu1,$cpu2,$cpu3 \
      --check-cpu \
      --cpu Haswell-noTSX,+pdpe1gb,cell0.id=0,cell0.cpus=0,cell0.memory=8388608 \
      --numatune mode=strict,nodeset=0 \
      --network vhostuser,source_type=unix,source_path=/tmp/vhost-sock0,source_mode=server,model=virtio,driver_queues=2 \
      --network network=default \
      --nographics --noautoconsole \
      --import \
      --os-variant=rhel7
}

define_vm
virsh shutdown rhel_loopback


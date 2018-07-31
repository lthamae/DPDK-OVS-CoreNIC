#! /bin/bash 


function list_running_domains {
  virsh --quiet list | grep running | awk '{print $2}'
}

function shutdown_all_vms {
list_running_domains | while read DOMAIN; do
  echo "Shutting down : $DOMAIN"
  virsh shutdown $DOMAIN
done

for i in $(seq 1 30);
do
  list_running_domains | while read DOMAIN; do
    sleep 1
  done
done

list_running_domains | while read DOMAIN; do
  echo "Forceful shutdown : $DOMAIN"
  virsh destroy $DOMAIN
done
}


function edit_vm {
VM_NAME=rhel_loopback
EDITOR='sed -i "/<cputune/,/<\/cputune>/d"' virsh edit $VM_NAME
EDITOR='sed -i "/<cpu/,/<\/cpu>/d"' virsh edit $VM_NAME
EDITOR='sed -i "/<vcpu/a \\ \\  <cputune>   \n    <vcpupin vcpu=\"0\" cpuset=\"3\"/>\n    <vcpupin vcpu=\"1\" cpuset=\"4\"/> \n    <vcpupin vcpu=\"2\" cpuset=\"5\"/>\n    <vcpupin vcpu=\"3\" cpuset=\"6\"/>\n    <emulatorpin cpuset=\"7\"/>\n   </cputune>  "' virsh edit $VM_NAME
EDITOR='sed -i "/<domain/a \<cpu mode=\"host-model\"><model fallback=\"forbid\"\/><numa><cell id=\"0\" cpus=\"0\" memory=\"8388608\" unit=\"KiB\" memAccess=\"shared\"\/><\/numa><\/cpu>"' virsh edit $VM_NAME
}


function customize_vm {
LIBGUESTFS_BACKEND=direct virt-customize -d rhel_loopback \
  --root-password password:root \
  --firstboot-command 'rm /etc/systemd/system/multi-user.target.wants/cloud-config.service' \
  --firstboot-command 'rm /etc/systemd/system/multi-user.target.wants/cloud-final.service' \
  --firstboot-command 'rm /etc/systemd/system/multi-user.target.wants/cloud-init-local.service' \
  --firstboot-command 'rm /etc/systemd/system/multi-user.target.wants/cloud-init.service' \
  --firstboot-command 'nmcli c | grep -o --  "[0-9a-fA-F]\{8\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{4\}-[0-9a-fA-F]\{12\}" | xargs -n 1 nmcli c delete uuid' \
  --firstboot-command 'nmcli con add con-name ovs-dpdk ifname eth0 type ethernet ip4 1.1.1.1/24' \
  --firstboot-command 'nmcli con add con-name management ifname eth1 type ethernet' \
  --firstboot-command 'reboot'
}



function configure_vm {
virsh start rhel_loopback

mac_addr=$(virsh dumpxml rhel_loopback | grep "mac address" | awk -F\' '{ print $2}' | tail -1)
while [ 1 ]
do
  VM_IP=$(sudo ip n show | grep $mac_addr | awk '{print $1}')
  if [ "$VM_IP" != "" ]; then
    break
    sleep 5
  fi
done
echo "The VM has be allocated IP =" $VM_IP
ssh-keyscan -H $VM_IP >> ~/.ssh/known_hosts


until ping -c1 $VM_IP &>/dev/null; do :; done


sshpass -p 'root' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$VM_IP \
'subscription-manager register --username ckleu.fae --password rhel-2018 --auto-attach; \
 subscription-manager attach; \
 subscription-manager repos --enable="rhel-7-server-ose-3.5-rpms"  --enable="rhel-7-server-extras-rpms" --enable="rhel-7-fast-datapath-rpms"; \
 yum clean all; \
 yum -y update; \
 yum -y install driverctl gcc kernel-devel numactl-devel tuned-profiles-cpu-partitioning vim dpdk dpdk-tools wget; \
 yum -y update kernel; \
 sed -i -e '"'"'s/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="isolcpus=1,2,3 default_hugepagesz=1G hugepagesz=1G hugepages=2 /'"'"'  /etc/default/grub; \
 grub2-mkconfig -o /boot/grub2/grub.cfg; \
 echo "options vfio enable_unsafe_noiommu_mode=1" > /etc/modprobe.d/vfio.conf; \
 driverctl -v set-override 0000:00:02.0 vfio-pci; \
 systemctl enable tuned; \
 systemctl start tuned; \
 echo isolated_cores=1,2,3 >> /etc/tuned/cpu-partitioning-variables.conf; \
 tuned-adm profile cpu-partitioning; \
 reboot'

}


function start_prep {
shutdown_all_vms
edit_vm
customize_vm
configure_vm
}

start_prep

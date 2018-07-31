#! /bin/bash

NFP_ID=4000
sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
setenforce permissive

if [ "$(cat /etc/default/grub | grep GRUB_CMDLINE_LINUX= | grep hugepage)" = "" ] && [ "$(cat /etc/default/grub | grep GRUB_CMDLINE_LINUX= | grep iommu)" = "" ]; then
    sed -i -e 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="default_hugepagesz=1G hugepagesz=1G hugepages=32 iommu=pt intel_iommu=on /'  /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
else
    echo "----------------------------"
    echo " Seems like some grub settings have already been configured, please check that /etc/default/grub"
    echo " have at least the following set for 'GRUB_CMDLINE_LINUX='"
    echo "     default_hugepagesz=1G hugepagesz=1G hugepages=32 iommu=pt intel_iommu=on"
    echo " and then execute 'grub2-mkconfig -o /boot/grub2/grub.cfg'"
    echo "----------------------------"
    echo
fi

card_node=$(cat /sys/bus/pci/drivers/nfp/0*/numa_node | head -n1 | cut -d " " -f1)
i40e_cpu_list=$(lscpu -a -p | awk -F',' -v var="$card_node" '$4 == var {printf "%s%s",sep,$1; sep=" "} END{print ""}')

# Remove first hyperthread pair from cpu-list
cpu0=$(echo $i40e_cpu_list | cut -d ' ' -f 1)
pair=$(cat /sys/devices/system/cpu/cpu$cpu0/topology/thread_siblings_list)
p1=$(echo $pair | cut -d ',' -f 1)
p2=$(echo $pair | cut -d ',' -f 2)

isolist=''
for cpu in $i40e_cpu_list; do
    if [ "$cpu" != "$p1" ] && [ "$cpu" != "$p2" ]; then
        if [ "$isolist" = "" ]; then isolist=$cpu; else isolist="$isolist,$cpu"; fi
    fi
done

systemctl enable tuned
systemctl start tuned
if [ "$(grep -e '^isolated_cores' /etc/tuned/cpu-partitioning-variables.conf)" = "" ]; then
    echo isolated_cores=$isolist >> /etc/tuned/cpu-partitioning-variables.conf
else
    echo "Some isolated cores already specified, was:"
    echo "  $(cat /etc/tuned/cpu-partitioning-variables.conf | grep -e '^isolated_cores')"
    echo "replacing with:"
    echo "  isolated_cores=$isolist"
    sed -i 's|^isolated_cores=.*|isolated_cores='${isolist}'|g' /etc/tuned/cpu-partitioning-variables.conf
fi

tuned-adm profile cpu-partitioning
reboot


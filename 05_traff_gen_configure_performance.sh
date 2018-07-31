#! /bin/bash

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

recompile_cpulist () {
   local input=$1
   local filter=$2
   newlist=''
   for cpu in $(echo $input | tr ',' ' '); do
       if [ "$cpu" != "$filter" ]; then
           if [ "$newlist" = "" ]; then newlist=$cpu; else newlist="$newlist,$cpu"; fi
       fi                                                                                                                                                                                       
   done                                                                                                                                                                                         
   echo $newlist                                                                                                                                                                                
}                                                                                                                                                                                                

YFL="/etc/trex_cfg.yaml"
flist=$(cat $YFL | grep threads | sed 's|.* threads: \[||g' | sed 's|\]||g')
echo $flist

echo "Removing two cpus + hyperthreads from trex config"
for i in $(seq 0 1); do
   cpu0=$(echo $flist | cut -d ',' -f 1)
   cpu0h=$(cat /sys/devices/system/cpu/cpu$cpu0/topology/thread_siblings_list | cut -d ',' -f 2)
   flist=$(recompile_cpulist $flist $cpu0)
   flist=$(recompile_cpulist $flist $cpu0h)
done

sed -i 's|threads: \[.*\]|threads: ['${flist}']|g' $YFL
systemctl enable tuned
systemctl start tuned

if [ "$(grep -e '^isolated_cores' /etc/tuned/cpu-partitioning-variables.conf)" = "" ]; then
   echo isolated_cores=$flist >> /etc/tuned/cpu-partitioning-variables.conf
else
   echo "Some isolated cores already specified, was:"
   echo "  $(cat /etc/tuned/cpu-partitioning-variables.conf | grep -e '^isolated_cores')"
   echo "replacing with:"
   echo "  isolated_cores=$flist"
   sed -i 's|^isolated_cores=.*|isolated_cores='${flist}'|g' /etc/tuned/cpu-partitioning-variables.conf
fi
tuned-adm profile cpu-partitioning


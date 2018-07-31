#! /bin/bash

BRNAME=ovs_pvp_br0
OVS_CTL=/usr/share/openvswitch/scripts/ovs-ctl
NSPCI="0000:$(lspci -d 19ee:4000 | head -n 1 | cut -d ' ' -f 1)"
#NSPCI1="0000:$(lspci -d 8086:1583 | head -n 1 | cut -d ' ' -f 1)"


bind_pci () {
modprobe vfio-pci
dpdk-devbind --bind=vfio-pci $NSPCI
}

prepare () {
    cpulist=$(cat /etc/tuned/cpu-partitioning-variables.conf | grep ^isolated | cut -d '=' -f 2)
    cpu0=$(echo $cpulist | cut -d ',' -f 1)
    cpu0h=$(cat /sys/devices/system/cpu/cpu$cpu0/topology/thread_siblings_list)
    cpu0mask=$((1<<$((cpu0))))
    cpu0hmask=$((1<<$((cpu0h))))  
    echo "CPU0 $cpu0"
    echo "CPU0h $cpu0h"

    cpu1=$(echo $cpulist | cut -d ',' -f 2)
    echo "CPU1 $cpu1"
    cpu1h=$(cat /sys/devices/system/cpu/cpu$cpu1/topology/thread_siblings_list)
    echo "CPU1h $cpu1h"
    cpu1mask=$((1<<$((cpu1))))
    cpu1hmask=$((1<<$((cpu1h))))
    
    cpu_tot_mask=$((cpu0mask+cpu0hmask))
    lcore_mask=$((cpu1mask+cpu1hmask))
    
    hex_mask=$(printf "0x%x\n" "$cpu_tot_mask")


    lmask=$(printf "0x%x\n" "$lcore_mask")

    echo "pmd mask = $hex_mask"
    echo "l mask = $lmask"
}

start_ovs_dpdk () {
    $OVS_CTL start
    ovs-vsctl set Open_vSwitch . other_config:dpdk-init=true
    ovs-vsctl set Open_vSwitch . other_config:dpdk-socket-mem=2048,2048
    ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=$hex_mask
    ovs-vsctl set Open_vSwitch . other_config:dpdk-lcore-mask=$lmask
#   ovs-vsctl set Open_vSwitch . other_config:tx-flush-interval=200
    $OVS_CTL restart
}

configure_bridge () {
    for br in $(ovs-vsctl list-br); do ovs-vsctl del-br $br; done
    ovs-vsctl add-br $BRNAME -- set bridge $BRNAME datapath_type=netdev
    ovs-vsctl add-port $BRNAME dpdk0 -- \
              set Interface dpdk0 type=dpdk -- \
              set Interface dpdk0 options:dpdk-devargs="0000:02:00.0" -- \
              set interface dpdk0 options:n_rxq=2 \
                other_config:pmd-rxq-affinity="0:$cpu0,1:$cpu0h" -- \
              set Interface dpdk0 ofport_request=1
ovs-vsctl add-port ovs_pvp_br0 vhost0 -- \
          set Interface vhost0 type=dpdkvhostuserclient -- \
          set Interface vhost0 options:vhost-server-path="/tmp/vhost-sock0" -- \
          set interface vhost0 options:n_rxq=2 \
            other_config:pmd-rxq-affinity="0:$cpu0,1:$cpu0h" -- \
          set Interface vhost0 ofport_request=2
}
bind_pci
prepare
start_ovs_dpdk
configure_bridge

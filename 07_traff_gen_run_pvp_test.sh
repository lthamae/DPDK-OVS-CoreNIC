#! /bin/bash

OVSMACHINE=icarium
VM_IP=192.168.122.129

if [ "$(grep MPLBACKEND ~/.bashrc)" = "" ]; then
   echo export MPLBACKEND="agg" >> ~/.bashrc
fi
source ~/.bashrc
mkdir ~/pvp_results
cd ~/pvp_results/

~/ovs_perf/ovs_performance.py \
 -d -l testrun_log.txt \
 --tester-type trex \
 --tester-address localhost \
 --tester-interface 0 \
 --ovs-address $OVSMACHINE \
 --ovs-user root \
 --ovs-password netronome \
 --dut-vm-address $VM_IP \
 --dut-vm-user root \
 --dut-vm-password root \
 --dut-vm-nic-queues=1 \
 --physical-interface enp179s0np0 \
 --virtual-interface eth2 \
 --dut-vm-nic-pci=0000:00:0a.0 \
 --flow-type=L3 \
 --run-time=40 \
 --warm-up \
 --stream-list=10,1000,2000,8000,16000,32000,64000,128000 \
 --packet-list=64,80,92,96,108,112,116,128,168,200,232,256,272,336,400,440,464,512,544,672,800,928,1024,1056,1184,1312,1408,1500,1518 \
 --physical-speed=25 \
 --no-bridge-config \
 --skip-pv-test

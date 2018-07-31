# DPDK-OVS-CoreNIC
## Automated RHEL PVP testing for DPDK-OVS CoreNIC

The goal for this PVP script is to have a quic way to verify the performance (change) of an Open vSwitch (DPDK) setup using the Physical to Virtual back to Physical topology. This configuration is also known as the PVP setup. The traffic will flow from a physical port to a virtual port on the Virtual Machine(VM), and then back to the physical port. This script uses the TRex Realistic Traffic Generator for generating and verifying the traffic.

## Register Red Hat Enterprise Linux

We continue here right after installing Red Hat Enterprise Linux. First need to register the system, so we can download all the packages we need. Both the DUT and the traffic generator have to be registered:

#### Register system
``` subscription-manager register --username <username> --password <password> --auto-attach ```

#### Add subscriptions
```
subscription-manager list --available
subscription-manager attach --pool=xxxxxxxxxxxxxxxxxx
```
#### Add packages
```
subscription-manager repos --enable=rhel-7-server-rhv-4-mgmt-agent-rpms
subscription-manager repos --enable rhel-7-server-extras-rpms
subscription-manager repos --enable rhel-7-server-optional-rpms
subscription-manager repos --enable=rhel-7-fast-datapath-rpms
```
## Setup the TRex traffic generator

One of the two machines we will use for the TRex traffic generator. We will also use this machine to run the actual PVP script.
After RHEL has been registered and the subscriptions with all the necessary packages have been added, the following scripts are too be executed in order on the traffic generator:

1. 01_traff_gen_install_deps.sh
2. 02_traff_gen_grab_trex.sh
3. 03_traff_gen_configure_trex.sh
4. 04_traff_gen_clone_pvp_repo.sh
5. 05_traff_gen_configure_performance.sh 

## Setup the Device Under Test (DUT), Open vSwitch
We use Open vSwitch in combination with the DPDK, userspace datapath. The following scripts should be on the DUT to prep the DUT for DPDK-OVS:

1. 01_install_deps.sh
2. 02_perf_configs.sh
3. 03_start_ovs_dpdk.sh
4. 04_create_vm.sh
5. 05_customize_vm.sh

*NB - NOTE that if you have a multi-NUMA system the cores you assign to both Open vSwitch and Qemu need to be one same NUMA node as the network card. Therefore the scripts `02_perf_configs.sh`, `03_start_ovs_dpdk.sh` and `04_create_vm.sh` have to be edited appropriately to isolate the right cores.*

## Running the PVP script 
Now we are all set to run the PVP script. We move back to the TRex host as we use this to execute the script.

*NOTE: The PVP script assumes both machines are directly attached, i.e. there is no switch in between. If you do have a switch in between the best option is to disable learning. If this is not possible you need to use the --mac-swap option. This will swap the MAC addresses on the VM side, so the switch in the middle does not get confused.*

The following scripts should be run in tmux session to start the tests:

1. 06_traff_gen_run_trex.sh
2. 07_traff_gen_run_pvp_test.sh

**NOTE**: The  `07_traff_gen_run_pvp_test.sh` must be edited approriately with the to include the hostname of DUT and  the IP of the VM. 

```
#Add the hostname of the DUT as shown
OVSMACHINE=icarium

# Add the IP of the VM on DUT as shown
VM_IP=192.168.122.129

if [ "$(grep MPLBACKEND ~/.bashrc)" = "" ]; then
   echo export MPLBACKEND="agg" >> ~/.bashrc
fi
source ~/.bashrc
mkdir ~/pvp_results
cd ~/pvp_results/

~/ovs_perf/ovs_performance.py \
  -d -l testrun_log.txt \              # Enable script debugging, and save the output to testrun_log.txt
  --tester-type trex \                 # Set tester type to TRex
  --tester-address localhost \         # IP address of the TRex server
  --tester-interface 0 \               # Interface number used on the TRex
  --ovs-address $OVSMACHINE  \         # DUT IP address
  --ovs-user root \                    # DUT login user name
  --ovs-password netronome \                # DUT login user password
  --dut-vm-address $VM_IP \            # Address on which the VM is reachable, see above
  --dut-vm-user root \                 # VM login user name
  --dut-vm-password root \             # VM login user password
  --dut-vm-nic-queues=2 \              # Number of rx/tx queues to use on the VM
  --physical-interface dpdk0 \         # OVS Physical interface, i.e. connected to TRex
  --physical-speed=10 \                # Speed of the physical interface, for DPDK we can not detect it reliably
  --virtual-interface vhost0 \         # OVS Virtual interface, i.e. connected to the VM
  --dut-vm-nic-pci=0000:00:0a.0 \      # PCI address of the interface in the VM
  --packet-list=64 \                   # Comma separated list of packets to test with
  --stream-list=1000 \                 # Comma separated list of number of flows/streams to test with
  --no-bridge-config \                 # Do not configure the OVS bridge, assume it's already done (see above)
  --skip-pv-test                       # Skip the Physical to Virtual test
```
The VM IP can be obtained by running the following command on the DUT:
```
virsh net-dhcp-leases default
```
**NOTE** Confirm that `--dut-vm-nic-pci` is correct by running `lspci` on the VM.

## Analyzing Results
The results will be in the directory `~/pvp_results`. A run will generate .png files ,log files and csv files which can then be analyzed. 

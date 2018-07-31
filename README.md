# DPDK-OVS-CoreNIC
## Automated RHEL PVP testing for DPDK-OVS CoreNIC

The goal for this PVP script is to have a quick (and dirty) way to verify the performance (change) of an Open vSwitch (DPDK) setup using the Physical to Virtual back to Physical topology. This configuration is also known as the PVP setup. The traffic will flow from a physical port to a virtual port on the Virtual Machine(VM), and then back to the physical port. This script uses the TRex Realistic Traffic Generator for generating and verifying the traffic.

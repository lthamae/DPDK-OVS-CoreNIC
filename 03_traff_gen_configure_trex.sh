#! /bin/bash

cwd=$(pwd)
mlx0="0000:$(lspci -d 15b3: | head -n1 | cut -d ' ' -f 1)"
mlx1="0000:$(lspci -d 15b3: | tail -n1 | cut -d ' ' -f 1)"

echo $mlx0 $mlx1
cd trex/v2.29
rm -rf /etc/trex_cfg.yaml
./dpdk_setup_ports.py -c $mlx0 $mlx1 --force-macs -o /etc/trex_cfg.yaml
cd $cwd

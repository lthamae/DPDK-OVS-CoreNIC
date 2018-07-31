#! /bin/bash

cwd=$(pwd)
git clone https://github.com/ctrautma/RHEL_NIC_QUALIFICATION.git
cd RHEL_NIC_QUALIFICATION
git submodule update --init --recursive
ln -s $cwd/RHEL_NIC_QUALIFICATION/ovs_perf/ ~/ovs_perf
cd $cwd

git clone https://github.com/fleitner/XenaPythonLib
cd XenaPythonLib/
python setup.py install
cd $cwd

cd trex/v2.29
tar -xzf trex_client_v2.29.tar.gz
cp -r trex_client/stl/trex_stl_lib/ ~/ovs_perf
cp -r trex_client/external_libs/ ~/ovs_perf/trex_stl_lib/

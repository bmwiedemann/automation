#!/bin/sh
# install media is not needed when we have the Pool repo
zypper rr SLES12-SP2-12.2-0
zypper --non-interactive in --no-recommends libvirt qemu-kvm
chkconfig libvirtd on
rclibvirtd restart

cd /tmp
wget http://clouddata.cloud.suse.de/images/x86_64/SLES12-SP2.qcow2
lvcreate -L 10G -n gatevm gate
qemu-img convert SLES12-SP2.qcow2 /dev/gate/gatevm



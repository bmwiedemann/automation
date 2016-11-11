#!/bin/sh
git config --global push.default simple
echo server ntp1.suse.de iburst minpoll 4 >> /etc/ntp.conf 
echo server ntp2.suse.de iburst >> /etc/ntp.conf
chkconfig ntpd on
rcntpd restart
# set secure root password
sed -i -e 's#^root:.*#root:$6$oh/u8h6j$876vgM2dJsuwRtfzlf6JlwYkxlY64jGKL5KFYqR51MLQLaVHlJ.V7ESn9OWlVbcNagSR.P4ON6uSONs60.iYv0:17116::::::#' /etc/shadow

cp -a network/* /etc/sysconfig/network/
rcnetwork restart

# install media is not needed when we have the Pool repo
zypper rr SLES12-SP2-12.2-0
zypper --non-interactive in --no-recommends libvirt qemu-kvm
chkconfig libvirtd on
rclibvirtd restart

cd /tmp
wget http://clouddata.cloud.suse.de/images/x86_64/SLES12-SP2.qcow2
lvcreate -L 10G -n gatevm gate
qemu-img convert SLES12-SP2.qcow2 /dev/gate/gatevm

virsh define gatevm.xml
virsh start gatevm


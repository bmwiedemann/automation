#!/bin/sh
# enable serial console
sed -i -e 's/quiet splash=silent/console=tty console=ttyS0,115200/' /etc/default/grub
update-bootloader --refresh

# set secure root password
sed -i -e 's#^root:.*#root:$6$oh/u8h6j$876vgM2dJsuwRtfzlf6JlwYkxlY64jGKL5KFYqR51MLQLaVHlJ.V7ESn9OWlVbcNagSR.P4ON6uSONs60.iYv0:17116::::::#' /etc/shadow

zypper -n in bridge-utils

echo gatevm.cloud.suse.de > /etc/HOSTNAME
cp -a network/* /etc/sysconfig/network/
rcnetwork restart



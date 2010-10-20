#!/bin/bash

# init.sh
# lucid specific
# tweek upstart to start in a container

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Let's go

#First divert (eg delete but dpkg friendly) some problematic init conf

init_to_divert="
/etc/init/control-alt-delete.conf
/etc/init/hwclock.conf
/etc/init/hwclock-save.conf
/etc/init/mountall.conf
/etc/init/mountall-net.conf
/etc/init/mountall-reboot.conf
/etc/init/mountall-shell.conf
/etc/init/procps.conf
/etc/init/rsyslog-kmsg.conf
/etc/init/upstart-udev-bridge.conf
/etc/init/networking.conf
/etc/init/network-interface.conf"

for initfile in $init_to_divert
do
	chroot ${rootfs} dpkg-divert --rename "$initfile"
	[[ -f ${rootfs}/$initfile ]] && die "$initfile not diverted"
	log "$initfile diverted"
done

#Put our workaround for initial mount
cat > "${rootfs}/etc/init/lxc.conf" <<EOF
#lxc-provider
# provide some workaround to make upstart to work with lxc
# Guillaume ZITTA

start on startup

task

script
	>/etc/mtab
        initctl emit virtual-filesystems
	initctl emit local-filesystems
        initctl emit remote-filesystems
        initctl emit filesystem
end script
EOF

if egrep -q '#lxc-provider' "${rootfs}/etc/init/lxc.conf"
then
	log "upstart conffile lxc.conf added"
else
	die "falied to add ${rootfs}/etc/init/lxc.conf"
fi

#Put our workaround for network start
cat > "${rootfs}/etc/init/networking.conf" << EOF
#lxc-provider 
# networking - configure virtual network devices
#
# This task causes virtual network devices that do not have an associated
# kernel object to be started on boot.
# Modified by lxc-provider
description	"configure virtual network devices"

start on local-filesystems

task

script
        mkdir -p /var/run/network || true
        ifdown -a
        ifup -a
end script

EOF

if egrep -q '#lxc-provider' "${rootfs}/etc/init/networking.conf"
then
        log "upstart conffile networking.conf added"
else
        die "falied to add ${rootfs}/etc/init/networking.conf"
fi

exit 0


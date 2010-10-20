#!/bin/bash

# network_workaround.sh
#Jaunty's init scripts does not creates /var/run/network
#FIXME is hardy impacted?

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Let's go
if mkdir -p "${rootfs}/dev/.initramfs/varrun/network"
then
	log "/var/run/network workaround done"
else
	die "unable to create ${rootfs}/dev/.initramfs/varrun/network"
fi

exit 0

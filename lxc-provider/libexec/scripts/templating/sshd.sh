#!/bin/bash

# sshd.sh
#Prepare configure sshd.sh
#For now, just add usedns=no
#@TODO make this configurable

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Disable DNS in sshd
echo "UseDNS no" >> "${rootfs}/etc/ssh/sshd_config"

if egrep -q "UseDNS no" "${rootfs}/etc/ssh/sshd_config"
then
	log \""UseDNS no"\"" added in sshd_config"
else
	die "unable to add "\""UseDNS no"\"" to ${rootfs}/etc/ssh/sshd_config"
fi

exit 0

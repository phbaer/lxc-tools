#!/bin/bash

# selinux.sh
# This script disables selinux

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Disable selinux
mkdir -p ${rootfs}/selinux || die "Unable to make ${rootfs}/selinux dir"
echo 0 > ${rootfs}/selinux/enforce || die "Unable to create ${rootfs}/selinux/enforce file"

log "selinux disabled"
exit 0

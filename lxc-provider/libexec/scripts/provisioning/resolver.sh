#!/bin/bash

# resolver.sh
# This script sets the /etc/resolv.conf
# By default it copies the host's one
# TODO: Make this configurable

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

cp /etc/resolv.conf "${rootfs}/etc/resolv.conf" || die "cp /etc/resolv.conf ${rootfs}/etc/resolv.conf : failed"
log "resolv.conf copied from host"

exit 0

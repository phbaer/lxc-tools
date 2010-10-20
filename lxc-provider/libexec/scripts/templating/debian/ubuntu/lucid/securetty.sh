#!/bin/bash

# securetty.sh
# This script enables root login on tty on lucid
#@TODO : make some post checks

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Pre-check
[[ -f "${rootfs}/etc/securetty" ]] || die "${rootfs}/etc/securetty not found"

#lxc's console is seen as "UNKNOWN"
#Make this a secure tty, so root can login
echo "UNKNOWN" >> "${rootfs}/etc/securetty"

#Post-check
if egrep -q 'UNKNOWN' "${rootfs}/etc/securetty"
then
	log "rootlogin enabled on : not verified"
else
	die "Unable to enable root login"
fi

exit 0


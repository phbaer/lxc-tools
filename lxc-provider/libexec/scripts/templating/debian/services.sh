#!/bin/bash

# services.sh
# This script disables some problematic services
# TODO: rename to services and manage service enabling ?

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS lxc_SVC_DISABLE"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#checks command presence
[[ -x "${rootfs}/usr/sbin/update-rc.d" ]] || die "No ${rootfs}/usr/sbin/update-rc.d executable found"

#let's go
LANGUAGE="C"
LC_ALL="C"
LANG="C"

for svc in ${lxc_SVC_DISABLE}
do
	if chroot ${rootfs} /usr/sbin/update-rc.d -f "${svc}" remove
	then
		log "svc ${svc} disabled"
	else
		die "/usr/sbin/update-rc.d -f ${svc} remove : failed"
	fi
done

log "Services management done"
exit 0

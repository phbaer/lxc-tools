#!/bin/bash

# hostname.sh
# This script creates /etc/hostname

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#vars checkings
needed_var_check "lxc_TMP_ROOTFS lxc_CONTAINER_NAME"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

cat <<EOF > "${rootfs}/etc/hostname"
${lxc_CONTAINER_NAME}
EOF

if egrep -q "${lxc_CONTAINER_NAME}" "${rootfs}/etc/hostname"
then
	log "hostname created"
else
	die "unable to set hostname in ${rootfs}/etc/hostname"
fi

exit 0

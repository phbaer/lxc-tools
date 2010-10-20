#!/bin/bash

# fstab.sh
# Prepare minimal fstab
# karmic container needs proc to be specified

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Let's go
cat <<EOF > ${rootfs}/etc/fstab
#lxc-provider
tmpfs  /dev/shm   tmpfs  defaults  0 0
none   /proc	  proc	 defaults  0 0
EOF

#Post-check
if egrep -q '#lxc-provider' "${rootfs}/etc/fstab"
then
        log "container's fstab done"
else
        die "failed make ${rootfs}/etc/fstab"
fi

exit 0

#!/bin/bash

# locales.sh
# This script configures locales

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Pre-checks
[[ -x "${rootfs}/usr/sbin/dpkg-reconfigure" ]] || die "executable ${rootfs}/usr/sbin/dpkg-reconfigure not found"

#Set conf
cat > "${rootfs}/etc/default/locale" << EOF
#lxc-provider
LANG=
EOF

if egrep -q '#lxc-provider' "${rootfs}/etc/default/locale"
then
	log "locale setted"
else
	die "unable to set locale"
fi

#Reconfigure locales

if chroot ${rootfs} /usr/sbin/dpkg-reconfigure -fnoninteractive locales
then
	log "locales reconfigured: OK"
else
	die "/usr/sbin/dpkg-reconfigure -fnoninteractive locales : failed"
fi

exit 0

#!/bin/bash
. ${lxc_PATH_LIBEXEC}/functions.sh

# tag.sh
# Add a tag file with lxc-provider version in the template

needed_var_check "lxc_TMP_ROOTFS lxc_TEMPLATE_VERSION"

#Shortcuts
rootfs="${lxc_TMP_ROOTFS}"

#Let's do some checks
[[ -d ${rootfs} ]] || die "cannot find ${rootfs} dir"
[[ "$(realpath "${rootfs}/")" == "/" ]] && die "tring to deploy to / !!!!\n i wont do this"

mkdir -p ${rootfs}/etc || die "unable to create ${rootfs}/etc"
echo ${lxc_TEMPLATE_VERSION} > "${rootfs}/etc/lxc-provider.tag" || die "unable to create tag : ${rootfs}/etc/lxc-provider.tag"

log "tag file created"

exit 0

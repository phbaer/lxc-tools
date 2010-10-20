#!/bin/bash
. ${lxc_PATH_LIBEXEC}/functions.sh

# 00_debootstrap.sh
# Launch initial bootstrap into then temporary template dir
# TODO Make cache of debootstrap on option

needed_var_check "lxc_TMP_ROOTFS lxc_ARCH lxc_RELEASE lxc_MIRROR lxc_PKGSUPP lxc_PATH_CACHE"

#Shortcuts
rootfs="${lxc_TMP_ROOTFS}"

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Let's go
cmd="debootstrap --verbose --variant=minbase --arch=${lxc_ARCH} --include ${lxc_PKGSUPP} ${lxc_RELEASE} ${rootfs} ${lxc_MIRROR}"

#Compute uniq identifier for this debootstrap to cache it
md5=$(echo "${lxc_ARCH}${lxc_PKGSUPP}${lxc_RELEASE}" | md5sum | cut -d ' ' -f 1)
cache="${lxc_PATH_CACHE}/debootstrap/${md5}.tgz"

if [[ -f $cache ]]
then
	log "debootstrap cache found, using it..."
	tar xzf $cache -C ${rootfs}
	ret=$?
	used_cache="with cache"
else
	warning "no debootstrap cache"
	$cmd
	ret=$?
fi

if [[ $ret == 0 ]]
then
	log "Bootstrap done ${used_cache}"
	if [[ -z ${used_cache} ]]
	then
		mkdir -p "${lxc_PATH_CACHE}/debootstrap"
		if tar -C ${lxc_TMP_ROOTFS} -c -z -f $cache .
		then	
			log "debootstrap cache stored : uuid $md5"
		else
			die "debootstrap cache storage failed"
		fi
	fi
else
	die "Failed to download the rootfs, aborting. Code: $RET"
fi

exit 0

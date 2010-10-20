#!/bin/bash

# auth.sh
# This script sets root password and authorized_keys

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_ROOTFS lxc_AUTH_PASSWORD lxc_AUTH_SSHPUBKEY lxc_AUTH_PASSWORDLESS"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

if echo "${lxc_AUTH_PASSWORDLESS}" | grep -iq '^yes$'
then
	sed -i "s|\(root:\)x\(:0:0:root:.*:.*\)|\1*\2|" "${rootfs}/etc/passwd"
	#Verification
	egrep -q '^root:[*]:' "${rootfs}/etc/passwd" || die "Unable to set passwdless login for root in ${rootfs}/etc/passwd"
	log "Passwordless login for root done"
else
	if echo "${lxc_AUTH_PASSWORD}" | grep -q '$1$.*'
	then
	        sed -i "s|\(root:\).*\(:.*:0:.*:.:::\)|\1${lxc_AUTH_PASSWORD}\2|" "${rootfs}/etc/shadow"
		egrep -q '^root:[$]1' "${rootfs}/etc/shadow" || die "Unable to set password for root in ${rootfs}/etc/shadow"
		log "Password setting for root done"
	else
		die "lxc_AUTH_PASSWORDLESS is set to no and lxc_AUTH_PASSWORD is not a valid crypted password"
	fi
fi

if [[ -f "${lxc_AUTH_SSHPUBKEY}" ]]
then
	mkdir -p "${rootfs}/root/.ssh"
	cat "${lxc_AUTH_SSHPUBKEY}" >> "${rootfs}/root/.ssh/authorized_keys"
	chmod 600 "${rootfs}/root/.ssh/authorized_keys"
	egrep -q '^ssh' "${rootfs}/root/.ssh/authorized_keys" || die "unable to set ${rootfs}/root/.ssh/authorized_keys"
	log "authorized_keys setting done"
else
	if [[ "${lxc_AUTH_SSHPUBKEY}" == "none" ]]
	then
		log "No authorized_keys required"
		exit 0
	else
		die "SSH pubkey : ${lxc_AUTH_SSHPUBKEY} no found"
	fi
fi

exit 0

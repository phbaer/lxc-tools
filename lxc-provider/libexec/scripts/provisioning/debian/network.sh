#!/bin/bash

# network.sh for debian
# This script sets network configuration
#TODO: add multiple interface capability
#TODO: add non ethernet interface support

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#vars checkings
needed_var_check "lxc_TMP_ROOTFS lxc_NET_GATEWAY lxc_NET_eth0_NETMASK lxc_NET_eth0_MTU lxc_CONTAINER_NAME"

#Shortcuts
rootfs=${lxc_TMP_ROOTFS}

#rootfs checking
[[ -f "${rootfs}/etc/lxc-provider.tag" ]] || die "${rootfs} is not a tagged rootfs"

#Let's see if we can deduce IP from name resolution
if [[ -z ${lxc_CONTAINER_IP} ]]
then
	lxc_CONTAINER_IP=$(getent hosts ${lxc_CONTAINER_NAME} | awk 'NR==1 { print $1 }')
	[[ "x${lxc_CONTAINER_IP}" == "x" ]] && die "IP address not provided and enable to find it from hostname"
	log "Found IP address ${lxc_CONTAINER_IP}"
fi

#/etc/network/interfaces file setup
[[ -d ${rootfs}/etc/network ]] || die "enable to find ${rootfs}/etc/network"

cat <<EOF > "${rootfs}/etc/network/interfaces"
#lxc-provider
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address ${lxc_CONTAINER_IP}
netmask ${lxc_NET_eth0_NETMASK}
gateway ${lxc_NET_GATEWAY}
mtu ${lxc_NET_eth0_MTU}
EOF

if egrep -q '#lxc-provider' "${rootfs}/etc/network/interfaces"
then
	log "interfaces conf done"
else
	die "there was a problem creating ${rootfs}/etc/network/interfaces"
fi

#Some releases needs this to be created
if [[ ! -d "${rootfs}/var/run/network" ]] 
then
	if mkdir -p "${rootfs}/var/run/network"
	then
		log "${rootfs}/var/run/network created"
	else
		die "unable to create ${rootfs}/var/run/network dir"
	fi
fi

#Initial /etc/hosts
cat <<EOF > "${rootfs}/etc/hosts"
#lxc-provider
127.0.0.1 localhost
${lxc_CONTAINER_IP} ${lxc_CONTAINER_NAME}
EOF

if egrep -q '#lxc-provider' "${rootfs}/etc/hosts"
then
        log "initial hosts file done"
else
        die "there was a problem creating ${rootfs}/etc/hosts"
fi

exit 0

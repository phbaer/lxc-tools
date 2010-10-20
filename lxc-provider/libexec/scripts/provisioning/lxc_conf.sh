#!/bin/bash

# lxc_conf.sh
#@TODO make interface name configurable
#@TODO Let's "cgroup device part" forceable (if repository is not a lxc host)

#Load functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#var checkings
needed_var_check "lxc_TMP_CONFIGDIR lxc_CONTAINER_NAME lxc_CONTAINER_ROOTFS lxc_NET_eth0_BRIDGE lxc_NET_eth0_MTU"

#Shortcuts
config="${lxc_TMP_CONFIGDIR}/config"

#create first part of the config
cat <<EOF > $config
#lxc-provider
lxc.utsname = ${lxc_CONTAINER_NAME}
lxc.tty = 6
lxc.pts = 1024
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = ${lxc_NET_eth0_BRIDGE}
lxc.network.name = eth0
lxc.network.mtu = ${lxc_NET_eth0_MTU}
lxc.rootfs = ${lxc_CONTAINER_ROOTFS}
EOF

if [[ -f "$config" ]]
then
	log "First part of config file done"
else
	die "unable to set $config"
fi

#This part is made if some needed kernel opts are setted
if lxc-checkconfig | grep -q 'Cgroup device:.*enabled';
then
        cat << EOF >> $config
lxc.cgroup.devices.deny = a
# /dev/null and zero
lxc.cgroup.devices.allow = c 1:3 rwm
lxc.cgroup.devices.allow = c 1:5 rwm
# consoles
lxc.cgroup.devices.allow = c 5:1 rwm
lxc.cgroup.devices.allow = c 5:0 rwm
lxc.cgroup.devices.allow = c 4:0 rwm
lxc.cgroup.devices.allow = c 4:1 rwm
# /dev/{,u}random
lxc.cgroup.devices.allow = c 1:9 rwm
lxc.cgroup.devices.allow = c 1:8 rwm
lxc.cgroup.devices.allow = c 136:* rwm
lxc.cgroup.devices.allow = c 5:2 rwm
# rtc
lxc.cgroup.devices.allow = c 254:0 rwm
EOF
	if egrep -q "lxc.cgroup.devices.allow" $config
	then
		log "Cgroup device specific part of config done"
	else
		die "enable to set Cgroup device specific part of $config"
	fi
else
	warning "Cgroup device not enabled"
fi

exit 0

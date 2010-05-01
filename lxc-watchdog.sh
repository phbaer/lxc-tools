#! /bin/sh
### BEGIN INIT INFO
# Provides:          lxc-watchdog
# Required-Start:    $remote_fs $named $network $time
# Required-Stop:     $remote_fs $named $network
# Required-Start:    
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Manage Linux Containers startup/shutdown
# Description:       Uses clever inotify hack to monitor container's
#                    halt/reboot events watching /var/run/utmp
### END INIT INFO

# Author: Dobrica Pavlinusic <dpavlin@rot13.org>
#
# based on Tony Risinger post to lxc-users mailing list
# http://www.mail-archive.com/lxc-users@lists.sourceforge.net/msg00074.html
#
# Install with:
# ln -sf /srv/sysadmin-cookbook/recepies/lxc/lxc-watchdog.sh /etc/init.d/lxc-watchdog
# update-rc.d lxc-watchdog defaults
#
# Changelog:
#
# 2010-05-01 phbaer <phbaer-git@npw.net>
#
#  * Dropped inittab modification in favour of upstart
#  * Added state tracking in order to get along with unknown runlevels

which inotifywait >/dev/null || apt-get install inotify-tools


lxc_exists() {
	name=$1

	if [ ! -e /var/lib/lxc/$name/config ] ; then
		echo "Usage: $0 name"
		lxc_status
		exit 1
	fi
}


lxc_rootfs() {
	grep '^ *lxc\.rootfs *=' "/var/lib/lxc/$1/config" | cut -d= -f2 | sed 's/^ *//'
}


lxc_status() {
	( find /var/lib/lxc/ -name "config" | cut -d/ -f5 | sort -u | xargs -i lxc-info -n {} | sed "s/'//g" | while read name is status ; do
		boot="-"
		test -s /var/lib/lxc/$name/on_boot && boot="boot"
		echo "$name $status $boot $(lxc_rootfs $name)"
	done ) | column -t
}


cleanup_init_scripts() {
	rootfs=$(lxc_rootfs $1)

	ls \
		$rootfs/etc/rc?.d/*umountfs \
		$rootfs/etc/rc?.d/*umountroot \
		$rootfs/etc/rc?.d/*hwclock* \
	2>/dev/null | xargs -i rm -v {}
}


lxc_log() {
	echo `date +%Y-%m-%dT%H:%M:%S` $*
}


lxc_kill() {
	name=$1
	command=$2

#	init_pid=`lxc-ps -C init -o pid | grep "^$name" | cut -d" " -f2-`
#	if [ -z "$init_pid" ] ; then
#		lxc-info -n $name
#		exit 1
#	fi
#	lxc_log "$name kill $sig $init_pid"
#	/bin/kill $sig $init_pid

	lxc_log "$name $command"
	ssh lxc-${name} ${command}
}

lxc_stop() {
	lxc_log "$name stop"
	lxc_kill $name "halt"
	lxc-wait -n $name -s STOPPED
	lxc_log "$name stoped"
#	rm -f /var/lib/lxc/${name}/on_boot
}


lxc_start() {
	name=$1

	if ! lxc-info -n $name | grep RUNNING ; then
		lxc_log "$name start"
		lxc-start -n $name -o /tmp/${name}.log -d
		lxc-wait  -n $name -s RUNNING
		lxc-info  -n $name
		test -f /var/lib/lxc/${name}/on_boot || echo $name > /var/lib/lxc/${name}/on_boot
	fi
}

lxc_watchdog() {
	name=$1
	rootfs=$(lxc_rootfs $1)
	state=""
	while true; do
		vps_utmp=${rootfs}/var/run/utmp
		tasks=`wc -l < /cgroup/${name}/tasks`

		# track the state in order to ignore unknown runlevels (e.g. "unknown")
		runlevel="$(runlevel ${vps_utmp})"
		case $runlevel in
		N*)
			state="booting"
		;;
		??2)
			state="running"
		;;
		??0)
			state="halt"
		;;
		??6)
			state="reboot"
		;;
		esac

		test -z "$tasks" && exit 1
		if [ "$tasks" -eq 1 ]; then

			lxc_log "$name runlevel $runlevel ($state)"

			case $state in
			"halt")
				lxc_log "$name halt"
				lxc-stop -n "${name}"
				lxc-wait -n ${name} -s STOPPED
				state="stopped"
				break
			;;
			"reboot")
				lxc_log "$name reboot";
				lxc-stop -n ${name}
				lxc-wait -n ${name} -s STOPPED
				lxc-start -d -n ${name} -o /tmp/${name}.log
				state="booting"
			;;
			*)
				# make sure vps is still running
				state="$(lxc-info -n "${name}" | sed -e 's/.* is //')"
				[ "$state" = "RUNNING" ] || break
			;;
			esac
		else
			lxc_log "$name $tasks tasks"
		fi

		# time of 5 minutes on it JUST IN CASE...
		inotifywait -qqt 300 ${vps_utmp}
	done

	lxc_log "$name watchdog exited"
}


usage() {
	echo "Usage: $0 {start|stop|restart|status|boot|disable} [name name ... ]" >&2
	exit 3
}

command_on_lxc() {
command=$1
shift

echo "# $command $1"

case "$command" in

start)
	lxc_exists $1
	cleanup_init_scripts $1
	lxc_start $1
	lxc-wait -n $1 -s RUNNING
	# give container 5 seconds to start more than one process
	( sleep 1 ; nohup $0 watchdog $1 >> /tmp/$1-watchdog.log 2>/dev/null ) &
	;;
stop|halt)
	lxc_exists $1
	lxc_stop $1
	;;
reload|force-reload|restart|reboot)
	lxc_kill $1 "reboot"
	;;
watchdog)
	lxc_watchdog $1
	;;
boot)
	echo $1 > /var/lib/lxc/$1/on_boot
	;;
disable)
	echo -n > /var/lib/lxc/$1/on_boot
	;;
*)
	usage
	;;

esac

}

command=$1
test -z "$command" && usage
test "$command" = "status" && lxc_status && exit
shift

if [ -z "$1" ] ; then
	ls /var/lib/lxc/*/on_boot | while read path ; do
		name=`echo $path | cut -d/ -f5`
		if [ "$command" != "start" -o "$command" = "start" -a -s $path ] ; then
			command_on_lxc $command $name
		else
			echo "# skip $command $name"
		fi
	done
else
	while [ ! -z "$1" ] ; do
		command_on_lxc $command $1
		shift
	done
fi


#!/bin/bash

#cfg_parse.sh 
#This script parses the configurations files into the tree corresponding to a query string
#
#Usage : cfg_parse.sh path_to_scripts_home query/string

path=$1
#query string, example : debian/ubuntu/hardy
query=$2

#Load some functions
. ${lxc_PATH_LIBEXEC}/functions.sh

#Does some checks
[[ -d ${path} ]] || die "'${path}' is not a dir"
[[ "X${query}" == "X" ]] && die "please provide a query string, example debian/ubuntu/hardy"

#initiate start point of conf
cur_dir="${path}"
[[ -d ${cur_dir} ]] || "configuration start point : ${cur_dir} does not exists"

#Makes a list of successive dirs to parse, example : ". debian ubuntu hardy"
directories=$(echo ${query} | sed 's|/| |g;s|^|. |g')

for dir in $directories
do
	#We add current dir to the path unless it is "."
	[[ "$dir" == '.' ]] || cur_dir="${cur_dir}/${dir}"

	debug "parsing $cur_dir"
	for conffile in $(find $cur_dir/*.conf 2>/dev/null)
	do
		debug "found $conffile"
		. $conffile
	done
done

envfile=$(mktemp --tmpdir=/tmp lxc-provider.cfg_parse.XXXXXXX)

#displaying result
for var in ${!lxc_*}
do
	echo ${var}=\'${!var}\' >> ${envfile}
done

echo ${envfile}

#function library

#Check if bash version is > 4.0
if [[ ${BASH_VERSINFO[0]} < 4 ]]
then
	die "please use bash > 4.0"
fi

#Colors
color_Green='\e[0;32m' 
color_Red='\e[0;31m'
color_Yellow='\e[0;33m'
color_Blue='\e[0;34m'
color_Cyan='\e[0;36m'
color_Magenta='\e[0;35m'
color_None='\e[0m'

ProgName=$(basename $0)

debug() {
	#  Function: debug
	#
	#  Displays/logs line if lxc_DEBUG is set to true
	#
	#  Parameters:
	#
	#    $1 - Message
	[[ -n $TERM && "${lxc_DEBUG}" == "true" ]] && echo -ne "${color_Blue}$(date) : ${ProgName} : debug : ${1}${color_None}\n" 1>&2
	[[ -n ${lxc_LOGFILE} ]] && echo -ne "$(date) : ${ProgName} : debug : ${1}\n" >> ${lxc_LOGFILE}
}

log() {
	#  Function: log
	#
	#  Displays/logs line at log level
        #
        #  Parameters:
        #
        #    $1 - Message
	[[ -n $TERM ]] && echo -ne "${color_Green}$(date) : ${ProgName} : log : ${1}${color_None}\n" 1>&2
	[[ -n ${lxc_LOGFILE} ]] && echo -ne "$(date) : ${ProgName} : log : ${1}\n" >> ${lxc_LOGFILE}
}

warning() {
	#  Function: warning
	#
	#  Displays/logs line at warning level
        #
        #  Parameters:
        #
        #    $1 - Message
	[[ -n $TERM ]] && echo -ne "${color_Yellow}$(date) : ${ProgName} : warning : ${1}${color_None}\n" 1>&2
	[[ -n ${lxc_LOGFILE} ]] && echo -ne "$(date) : ${ProgName} : warning : ${1}\n" >> ${lxc_LOGFILE}
}

alert() {
	#  Function: alert
	#
	#  Displays/logs line at alert level
        #
        #  Parameters:
        #
        #    $1 - Message
        [[ -n $TERM ]] && echo -ne "${color_Red}$(date) : ${ProgName} : alert : ${1}${color_None}\n" 1>&2
	[[ -n ${lxc_LOGFILE} ]] && echo -ne "$(date) : ${ProgName} : alert : ${1}\n" >> ${lxc_LOGFILE}
}


die() {
	#  Function: die
	#
	#  Display error message and exit
        #
        #  Parameters:
        #
        #    $1 - Message
	alert "$1"
	exit 1
}

needed_var_check() {
	#  Function: needed_var_check
	#
	#  Checks that needed env vars are setted
        #
        #  Parameters:
        #
        #    $1 - List if varnames
	debug "needed_var_check($*)"
	needed_vars=$1
	for var in ${needed_vars}
	do
		if [[ -z ${!var} ]] 
		then
			die "env var $var not available"
			needed_var_check_failed=1
		fi
	done
	[[ "${needed_var_check_failed}" == "1" ]] && die "Needed vars unavailable"
}

rm_rf() {
	#  Function: rm_rf
	#
	#  This function rm -rf but does some checks
        #
        #  Parameters:
        #
        #    $1 - Dir to delete
	debug "rm_rf($*)"
	dir=$1
	debug "rm_rf : about to delete $dir"
	real=$(realpath $dir)
	debug "rm_rf : about to delete $dir, which is ${real}"
	[[ "X${real}" == "X/" ]] && die "I don't want to rm -rf / !!!"

	rm -rf ${dir} && log "${dir} removed"
}

uncolor() {
	#  Function: uncolor
	#
	#  displays message whitout colors
        #
        #  Parameters:
        #
        #    $* - Message to be uncolored
	echo $* | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"
}

### Common Functions ###
c_InArray() {
	#  Function: c_InArray
	#
	#  test if an item is in an array
        #
        #  Parameters:
        #
        #    $1 - item to search
	#    $2-N - List in which we search for our item

	debug "c_InArray($*)"
	search=$1
	shift
	for i in $*
	do
		debug "c_InArray() : matching $search with $i"
		[[ $i == $search ]] && return 0
	done
	return 1
}

c_Select() {
	#  Function: c_Select
	#
	#  Display selection menu
        #
        #  Parameters:
        #
        #    $1 - Prompt message
	#    $2 - List of item to select
	debug "c_Select($*)"
        PS3="$1"
        select item in $2
        do
                uncolor "$item"
                break
        done
}

c_DebugInfo() {
	#  Function: c_DebugInfo
	#
	#  Display lxc_* vars
        #

	debug "c_DebugInfo($*)"
        for var in ${!lxc_*}
        do
                echo -e "${var}=${color_Yellow}${!var}${color_None}"
        done
}

c_LoadAvailable() {
        #  Function: c_LoadAvailable
        #
        #  Loads Available template/provider in global associative array
        #
        #  Parameters:
        #
        #       $1 - type (template/provider)
        #       $2 - etc_root
	debug "c_LoadAvailable($*)"
	
	Type=$1
	root=$2

	c_InArray $Type template provider || die "c_LoadAvailable : Type $Type not template or provider"

	marker="template.conf"
	[[ $Type == "provider" ]] && marker="provider.conf"

	for File in $(find -L ${root} -name "${marker}")
	do
                TreeString=$(echo $File | sed "s|^$root/||g;s|/$marker||g")
                debug "c_LoadAvailable : associating $name with $TreeString"
	
		if [[ "$Type" == "template" ]] 
		then
			name=$(cat $File | awk -F = '$1 ~ /^lxc_TEMPLATE_NAME/ { print $2 }')
			TemplateTree[$name]=$TreeString
		fi
		if [[ "$Type" == "provider" ]]
		then
			name=$(cat $File | awk -F = '$1 ~ /^lxc_PROVIDER_NAME/ { print $2 }')
			ProviderTree[$name]=$TreeString
		fi
	done
}

t_LoadCacheArchives() {
	#  Function: t_LoadCacheArchives
	#
	#  Loads template cache files into global associative array : TemplateCacheFile
	#
	#   Parameters:
	#
	#      	$1 - cachedir
	#	$2 - version
        
	debug "t_LoadCacheArchives($*)"
	[[ -d $1 ]] || die "Template Cache Dir $1 does not exists"
	for archive in $(ls -1 ${1}/*_${2}*)
	do
		template=$(basename $archive | cut -d _ -f 1)
		TemplateCacheFile[$template]=$archive
		debug "t_LoadCacheArchives : association of $template with $archive"
	done
	
	return 0
}

p_GetTemplate() {
	#  Function: p_GetTemplate
	#
	#  Display template corrsponding to provider
        #
        #  Parameters:
        #
        #    $1 - Provider name

	debug "p_GetTemplate($*)"
	echo $(. $lxc_PATH_ETC/provisioning/${ProviderTree[$1]}/provider.conf ; echo $lxc_TEMPLATE_NAME)
}

t_List() {
	#  Function: t_List
	#
	#  Display template list
	#  green already builded template 
	#  none ready to build template

        debug "t_List($*)"

	CacheList=${!TemplateCacheFile[@]}
	debug "available Cache0 templates : $CacheList"

	for template in ${!TemplateTree[@]}
	do
		if c_InArray $template $CacheList
                then
			debug "${template} cache archive is available"
                        echo -ne "${color_Green}${template}${color_None}\n"
                else
                        debug "t_list : ${template} not found in available archive"
                        echo -ne "${template}\n"
                fi
        done
}

p_List() {
	#  Function: p_List
	#
	#  Display colored provider list
	#  green available template
	#  red non available template
	debug "p_List($*)"
	
        CacheList=${!TemplateCacheFile[@]}
        debug "available templates for provisioning : $CacheList"

	for provider in ${!ProviderTree[@]}
        do
		template=$(p_GetTemplate $provider)
                if c_InArray $template $CacheList
                then
                        debug "${template} cache archive is available"
                        echo -ne "${color_Green}${provider}${color_None}\n"
                else
                        debug "t_list : template ${template} for provider ${provider} not found in available archive"
                        echo -ne "${color_Red}${template}${color_None}\n"
                fi
        done
}

t_LoadConf() {
	#  Function: t_LoadConf
	#
	#  Load configuration for templating
        debug "f_LoadConf($*)"

        list=$(t_List)

        #Check if lxc_TEMPLATE_WANTED is passed
        if [[ "X${lxc_TEMPLATE_WANTED}" == "X" ]]
        then
                #Interactive mode
                debug "Interactive mode\n"
                lxc_TEMPLATE_NAME=$(c_Select "Please select a template : " "$list")
        else
                debug "todo stub"
                #@TODO: create a non interactive mode and die here?
        fi

        debug "launching ${lxc_PATH_LIBEXEC}/cfg_parse.sh ${lxc_PATH_ETC}/templating ${TemplateTree[$lxc_TEMPLATE_NAME]}"

        envfile=$(${lxc_PATH_LIBEXEC}/cfg_parse.sh ${lxc_PATH_ETC}/templating ${TemplateTree[$lxc_TEMPLATE_NAME]})
        if [[ $? == 0 ]]
        then
                . $envfile && log "configuration loaded"
        else
                die "There was a problem loading configuration"
        fi

        #Compose some path
        lxc_TMP_ROOTFS="${lxc_PATH_TMP}/templating/${lxc_TEMPLATE_NAME}"
        lxc_TEMPLATE_ARCHIVE="${lxc_PATH_TEMPLATE}/${lxc_TEMPLATE_NAME}_${lxc_TEMPLATE_VERSION}.tgz"

        export ${!lxc_*}
}

p_LoadConf() {
	#  Function: p_LoadConf
	#
	#  Load configuration for provisioning
        debug "f_LoadConf($*)"

        list=$(p_List)

        #Check if lxc_PROVIDER_WANTED is passed
        if [[ "X${lxc_PROVIDER_WANTED}" == "X" ]]
        then
                #Interactive mode
                debug "Interactive mode"
                lxc_PROVIDER_NAME=$(c_Select "Please select a provider : " "$list")
        else
                debug "todo stub"
                #@TODO: create a non interactive mode and die here?
        fi

        #Load conf for provider 
        CfgParse="${lxc_PATH_LIBEXEC}/cfg_parse.sh ${lxc_PATH_ETC}/provisioning ${ProviderTree[$lxc_PROVIDER_NAME]}"
        debug "launching ${CfgParse}"
        envfile=$(${CfgParse})

        if [[ $? == 0 ]]
        then
                . $envfile && log "configuration loaded"
        else
                die "There was a problem loading configuration"
        fi

        #Compose some paths
        #Search template archive
        template=$(p_GetTemplate $lxc_PROVIDER_NAME)
        lxc_TEMPLATE_ARCHIVE=${TemplateCacheFile[$template]}

        #Temporary dirs
        lxc_TMP_ROOTFS="${lxc_PATH_TMP}/provisioning/${lxc_CONTAINER_NAME}"
        lxc_TMP_CONFIGDIR="${lxc_PATH_TMP}/provisioning/${lxc_CONTAINER_NAME}-config"

        #Final Rootfs
        lxc_CONTAINER_ROOTFS="${lxc_PATH_ROOTFS}/${lxc_CONTAINER_NAME}"

        export ${!lxc_*}
}

t_Create() {
	#  Function: t_Create
	#
	#  template build
        debug "t_Create($*)"
	[[ -n $lxc_DEBUG ]] && c_DebugInfo

	[[ -f $lxc_TEMPLATE_ARCHIVE ]] && die "There is a cached template at $lxc_TEMPLATE_ARCHIVE, please delete it"

        #Check preprare tmp
        [[ -d "${lxc_TMP_ROOTFS}" ]] && die "${lxc_TMP_ROOTFS} already exists"
        mkdir -p ${lxc_TMP_ROOTFS} && log "${lxc_TMP_ROOTFS} created"

        #Let's go
        debug "t_Create() : Launching scripts..."
        for script in $(${lxc_PATH_LIBEXEC}/get_scripts.pl ${lxc_PATH_SCRIPTS}/templating ${TemplateTree[$lxc_TEMPLATE_NAME]})
        do
                log "Executing ${script}"
                ${script} || die "${script} failed"
        done
        log "scripts execution done."

        #Archive creation
        log "creating archive..."
        [[ -f "${lxc_TEMPLATE_ARCHIVE}" ]] && warning "${lxc_TEMPLATE_ARCHIVE} exists, overwriting..."
        tar czf "${lxc_TEMPLATE_ARCHIVE}" -C "${lxc_TMP_ROOTFS}" . || die "tar cvf ${lxc_TEMPLATE_ARCHIVE} -C "\""${lxc_TMP_ROOTFS}"\"" failed ."

        #Clean
        rm_rf "${lxc_TMP_ROOTFS}"

        log "archive ${lxc_TEMPLATE_ARCHIVE} created."
}

p_Create() {
        #  Function: p_Create
	#
	#  provider execution
	debug "p_Create($*)"	
	[[ -n $lxc_DEBUG ]] && c_DebugInfo

        #do some checks
        [[ -f ${lxc_TEMPLATE_ARCHIVE} ]] || die "The template ${lxc_TEMPLATE_ARCHIVE} is not available"
        [[ -d ${lxc_CONTAINER_ROOTFS} ]] && die "Rootfs dir ${lxc_CONTAINER_ROOTFS} already exists"
        [[ -d ${lxc_PATH_ROOTFS} ]] || die "dir where container's rootfs will be doesn't exists : ${lxc_PATH_ROOTFS}"

        if [[ -d "${lxc_TMP_ROOTFS}" ]]
        then
                #@TODO make overwrite of the TMP_ROOTFS an option
                warning "${lxc_TMP_ROOTFS} already exists, overwriting"
                rm_rf "${lxc_TMP_ROOTFS}"
                mkdir -p "${lxc_TMP_ROOTFS}" && log "${lxc_TMP_ROOTFS} created"
        fi

        mkdir -p "${lxc_TMP_ROOTFS}" && log "${lxc_TMP_ROOTFS} created"
        #Template extraction
        log "extracting template ${lxc_TEMPLATE_ARCHIVE} ..."
        tar xzf "${lxc_TEMPLATE_ARCHIVE}" -C "${lxc_TMP_ROOTFS}" || die "tar xvzf "\""${lxc_TEMPLATE_ARCHIVE}"\"" -C "\""${lxc_TMP_ROOTFS}"\"

        [[ -d ${lxc_TMP_CONFIGDIR} ]] || rm_rf ${lxc_TMP_CONFIGDIR}

        mkdir -p ${lxc_TMP_CONFIGDIR}

        for script in $(${lxc_PATH_LIBEXEC}/get_scripts.pl ${lxc_PATH_SCRIPTS}/provisioning ${ProviderTree[$lxc_PROVIDER_NAME]})
        do
                log "Executing ${script}"
                ${script} || die "${script} failed"
        done

        #OK commit cache
        mv "${lxc_TMP_ROOTFS}" "${lxc_CONTAINER_ROOTFS}" || die "mv ${lxc_TMP_ROOTFS} ${lxc_CONTAINER_ROOTFS} failed"
        log "${lxc_TMP_ROOTFS} commited"
        lxc-create -n ${lxc_CONTAINER_NAME} -f ${lxc_TMP_CONFIGDIR}/config || die "Failed to create '${lxc_CONTAINER_NAME}'"
}


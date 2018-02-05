#!/bin/bash 


if [[ ${0:0:1} != "/" ]] ; then
  CWD="$PWD"/$(dirname "$0")
else
  CWD=$(dirname "$0")
fi
cd "$CWD"

ROOT="${CWD}"
CONFIG="${ROOT}/Configuration"
PACKAGE_DIR="${ROOT}/Repository"
SRC_DIR="${ROOT}/src"
SRC_PACKAGE="ap-kernelmodule.tar.bz2"
VAR_SYMC=/var/symantec/sep
ETC_SYMC=/etc/symantec/sep
SAVREPORTER="savreporter"
SYMC_CONF="/etc/Symantec.conf"

LOG=$(dirname ~/sepfl-install.log)/sepfl-install.log
PACKAGE_LIST=(sav \
		savap \
		savui \
		)
PACKAGE_LIST_X64=(sav \
		savap-x64 \
		savui \
		)
INSTALL_PKG_LIST="sep\
		  sepap\
		  sepui\
		  "
CONFIG_LIST="setup.ini\
	 setAid.ini\
	 "
IS_INSTALL=0
IS_UNINSTALL=0
IS_PRECHECK=0
PRECHECK_PACKAGE_NAME="all"
#0 check, 1 not check
UBUNTU_VERSION_REQUIRES_SNI=14

#savfl install configuration: this file will specify which daemon will not start during installation.
INSTALL_CFG="/etc/savfl_install.cfg"

#savfl install pre-check flag.
PRECHECK_CFG=$(dirname ~/SepPrecheck.cfg)/SepPrecheck.cfg

#savfl install data file.
INSTALL_DATA=$(dirname ~/SepInstallData)/SepInstallData


DAEMONS="symcfgd\
		 rtvscand\
		 smcd\
		 "

MSG_AV_INST_BEGIN="Begin installing virus protection component"
MSG_AV_INST_END="Virus protection component installed successfully"
MSG_AV_INST_FAIL="Virus protection component failed to install"
MSG_AP_INST_BEGIN="Begin installing Auto-Protect component"
MSG_AP_INST_END="Auto-Protect component installed successfully"
MSG_AP_INST_FAIL="Auto-Protect component failed to install"
MSG_UI_INST_BEGIN="Begin installing GUI component"
MSG_UI_INST_END="GUI component installed successfully"
MSG_UI_INST_FAIL="GUI component failed to install"
MSG_LU_INST_BEGIN="Begin installing LiveUpdate component"
MSG_LU_INST_END="LiveUpdate component installed successfully"
MSG_LU_INST_FAIL="LiveUpdate component failed to install"

MSG_AV_RM_BEGIN="Begin removing virus protection component"
MSG_AV_RM_END="Virus protection component removed successfully"
MSG_AV_RM_FAIL="Virus protection component failed to remove"
MSG_AP_RM_BEGIN="Begin removing Auto-Protect component"
MSG_AP_RM_END="Auto-Protect component removed successfully"
MSG_AP_RM_FAIL="Auto-Protect component failed to remove"
MSG_LEGACY_AP_RM_BEGIN="Begin removing legacy Auto-Protect component"
MSG_LEGACY_AP_RM_END="Legacy Auto-Protect component removed successfully"
MSG_LEGACY_AP_RM_FAIL="Legacy Auto-Protect component failed to remove"
MSG_UI_RM_BEGIN="Begin removing GUI component"
MSG_UI_RM_END="GUI component removed successfully"
MSG_UI_RM_FAIL="GUI component failed to remove"
MSG_LU_RM_BEGIN="Begin removing LiveUpdate component"
MSG_LU_RM_END="LiveUpdate component removed successfully"
MSG_LU_RM_FAIL="LiveUpdate component failed to remove"

SYMC_ROOT_DIR="/opt/Symantec"
SEPFL_PROD_ROOT_DIR="unassigned"
PROD_ROOT_TMP_DIR="unassigned"


###############
# Name        : export_and_apply_stickybit()

# Arguments   : na

# Description :
## - We choose directory defined by PROD_ROOT_TMP_DIR env variable for installing the product.
## install.sh script exports an environment variable named PROD_ROOT_TMP_DIR
## - Exported variable PROD_ROOT_TMP_DIR is used while installing and uninstalling of SEPFL
## - Modifies globally defined (scope through the entire script) SEPFL_PROD_ROOT_DIR and PROD_ROOT_TMP_DIR variables.
## - All the children processes use this variable.
## - Same function has been written in uninstall.sh script along with global definitions of SYMC_ROOT_DIR, SEPFL_PROD_ROOT_DIR,
## and PROD_ROOT_TMP_DIR (again, scope through the entire script). This's necessary in case uninstall.sh
## is invoked independenly (from /opt/Symantec/symantec_antivirus or /opt/Symantec/sep/symantec_antivirus directory) without using install.sh
## script, i.e., without install.sh -u.
## - Also, sticky-bit is applied to the directory defined by PROD_ROOT_TMP_DIR to protect the scripts being
## executed by any other user. And similarly, to protect the said directory from any changes being made by
## any other user.

# Assumptions : na

# Usage       :
# export_and_apply_stickybit

# Return Value: default, i.e., 0
###############
export_and_apply_stickybit()
{
	SEPFL_PROD_ROOT_DIR=""$SYMC_ROOT_DIR"/sep"	## effective when /opt/Symantec/sep directory place-holder for SEPFL is created.
	PROD_ROOT_TMP_DIR=""$SEPFL_PROD_ROOT_DIR"/tmp"
	if [ ! -d "$SEPFL_PROD_ROOT_DIR" ] ; then
		PROD_ROOT_TMP_DIR=""$SYMC_ROOT_DIR"/tmp"
	fi

	if [ ! -d "$PROD_ROOT_TMP_DIR" ] ; then
		mkdir -p "$PROD_ROOT_TMP_DIR"
		chmod +t "$PROD_ROOT_TMP_DIR"
		echo "Applied sticky-bit to directory $PROD_ROOT_TMP_DIR" >> "${LOG}"
		echo "Exported env variable PROD_ROOT_TMP_DIR: $PROD_ROOT_TMP_DIR" >> "${LOG}"
	fi

	export PROD_ROOT_TMP_DIR

	return 0
}

beginInst()
{
	local module="$1"
	
	case ${module} in
		sep)	writeLog "${MSG_AV_INST_BEGIN}" ;;
		sepap)	writeLog "${MSG_AP_INST_BEGIN}" ;;
		sepui)	writeLog "${MSG_UI_INST_BEGIN}" ;;
	esac
	
	return 0
}

endInst()
{
	local module="$1"
	
	case ${module} in
		sep)	writeLog "${MSG_AV_INST_END}" ;;
		sepap)	writeLog "${MSG_AP_INST_END}" ;;
		sepui)	writeLog "${MSG_UI_INST_END}" ;;
	esac

	return 0
}

failInst()
{
	local module="$1"
	local err="$2"

	case ${module} in
		sep)	writeLog "${MSG_AV_INST_FAIL}, with error: ${err}" ;;
		sepap)	writeLog "${MSG_AP_INST_FAIL}, with error: ${err}" ;;
		sepui)	writeLog "${MSG_UI_INST_FAIL}, with error: ${err}" ;;
	esac

	return 0
}

beginRm()
{
	local module="$1"
	
	case ${module} in
		sav)	writeLog "${MSG_AV_RM_BEGIN}" ;;
		savap)	writeLog "${MSG_AP_RM_BEGIN}" ;;
		savap-x64)	writeLog "${MSG_AP_RM_BEGIN}" ;;
		savap-legacy)	writeLog "${MSG_LEGACY_AP_RM_BEGIN}" ;;
		savap-x64-legacy)	writeLog "${MSG_LEGACY_AP_RM_BEGIN}" ;;
		savui)	writeLog "${MSG_UI_RM_BEGIN}" ;;
	esac
	
	return 0
}

endRm()
{
	local module="$1"

	case ${module} in
		sav)	writeLog "${MSG_AV_RM_END}" ;;
		savap)	writeLog "${MSG_AP_RM_END}" ;;
		savap-x64)	writeLog "${MSG_AP_RM_END}" ;;
		savap-legacy)	writeLog "${MSG_LEGACY_AP_RM_END}" ;;
		savap-x64-legacy)	writeLog "${MSG_LEGACY_AP_RM_END}" ;;
		savui)	writeLog "${MSG_UI_RM_END}" ;;
	esac
	
	return 0
}

failRm()
{
	local module="$1"
	local err="$2"

	case ${module} in
		sav)	writeLog "${MSG_AV_RM_FAIL}, with error: ${err}" ;;
		savap)	writeLog "${MSG_AP_RM_FAIL}, with error: ${err}" ;;
		savap-x64)	writeLog "${MSG_AP_RM_FAIL}, with error: ${err}" ;;
		savap-legacy)	writeLog "${MSG_LEGACY_AP_RM_FAIL}, with error: ${err}" ;;
		savap-x64-legacy)	writeLog "${MSG_LEGACY_AP_RM_FAIL}, with error: ${err}" ;;
		savui)	writeLog "${MSG_UI_RM_FAIL}, with error: ${err}" ;;
	esac
	
	return 0
}

IsRpmSupported()
{
	which rpm > /dev/null 2>&1
	if [ ! 0 -eq $? ] ; then
		return 0
	fi
	
	rpm -qa | grep rpm > /dev/null 2>&1

	if [ 0 -eq $? ]; then
		return 1
	fi

	return 0
}

IsPlatformX64()
{
	uname -m | grep i686 > /dev/null 2>&1
	if [ 0 -eq $? ]; then
		return 0
	fi

	return 1
}

writeLog()
{
    echo -e "$1" 2>&1 
    echo -e "$(date): $1" 2>&1 >> ${LOG}
    return 0
}

glibcCheck()
{
	chmod a+x "${curdir}/precheckglibc" >/dev/null 2>&1
	LC_ALL="C" ldd "${curdir}/precheckglibc" >/dev/null 2>&1
	if [ $? = 0 ] ; then
		LC_ALL="C" ldd "${curdir}/precheckglibc" 2>&1 | grep "not found" >/dev/null 2>&1
		if [ $? = 0 ] ; then
			return 1
		else
			# Run the check to validate the version of GLIBC is acceptable
			"${curdir}/precheckglibc" >/dev/null 2>&1
			return $?
		fi
	else
		return 1
	fi
}

X11Check()
{
	chmod a+x "${curdir}/precheckX11" >/dev/null 2>&1
	LC_ALL="C" ldd "${curdir}/precheckX11" >/dev/null 2>&1
	if [ $? = 0 ] ; then
		LC_ALL="C" ldd "${curdir}/precheckX11" 2>&1 | grep "not found" >/dev/null 2>&1
		if [ $? = 0 ] ; then
			return 1
		else
			return 0
		fi
	else
		return 1
	fi
}

#$1: string which may contains whitespaces. $1 must not be empty.
#return: 1 if contains whitespace, 0 if not. if $1 is empty, just return 0.
checkWhitespace()
{
	local str="$1"

	if [ -z "$str" ] ; then
		return 0
	fi

	local truncstr=$(echo "$str" | tr -cd "[\ \n\t]")

	if [ ! -z "$truncstr" ] ; then
		return 1
	fi

	return 0
}

#check if we are required to install qt4-based UI to handle display icon on Ubuntu 14.04 or higher.  Return 1 if new UI is needed for systray icon.
SniUiNeeded()
{
	local ret
	IsRpmSupported
	ret=$?
	if [ 1 -eq $ret ] ; then
		#writeLog "Installing RPM, will not be installing DEB"
		return 0
	fi

	which lsb_release > /dev/null 2>&1
	ret=$?
	if [ ! 0 = $ret ] ; then
		#writeLog "lsb_release is not present"
		return 0
	fi
	
	which dpkg > /dev/null 2>&1
	ret=$?
	if [ ! 0 = $ret ] ; then
		#writeLog "DEB installer not found"
		return 0
	fi

	OsName=$(lsb_release -is 2>&1)
	if [ "$OsName" != "Ubuntu" ] ; then
		#writeLog "SNI compatible ui is not required."
		return 0
	fi

	OsVer=$(lsb_release -rs 2>&1)
	OsMajorVer=$(echo $OsVer | cut -d. -f1 2>&1)
	if [ $OsMajorVer -lt $UBUNTU_VERSION_REQUIRES_SNI ] ; then
		#writeLog "SNI compatible ui is not required."
		return 0
	fi
	#Alter this test right here if we wish to use new ui on other Ubuntu desktop environments (should they require new tray icon interface)
	UnityInstallState=$(dpkg -l unity | grep "unity" | awk '{print $1}')
	if [ "$UnityInstallState" = "ii" ] ; then
		#writeLog "SNI compatible ui is required for System Tray support on this platform."
		return 1
	else
		#writeLog "SNI compatible ui is not required."
		return 0
	fi
}

#return 1 if all dependencies are met, return 0 if test fails.
SniUiCheck()
{
	#packagename * version to keeping these pairs easy to see and/or modify.
	dependencylist="libqtcore4*4:4.6.0 \
					libqtgui4*4:4.6.0 \
					libc6*2.6 \
					libgcc1*1:4.4.0 \
					libstdc++6*4.4.2 \
					"
	IsPlatformX64
	if [ 0 = $? ] ; then
		testarch=":i386"
	else
		testarch=":amd64"
	fi

	failcount=0
	for dependencyfull in $dependencylist
	do
		dependency=$(echo $dependencyfull | awk -F* '{print $1}' 2>&1)
		requiredver=$(echo $dependencyfull | awk -F* '{print $2}' 2>&1)

		resultcatch=$(dpkg -l ${dependency}${testarch} | grep "$dependency" 2>&1)

		if [ "x$resultcatch" != "x" ] ; then
			installstate=$(echo $resultcatch | cut -f 1 -d ' ' 2>&1)

			if [ "ii" != "$installstate" ] ; then
				writeLog "	${dependency}${testarch} dependency can not be found."
				failcount=$(( $failcount + 1 ))
			else
				depversion=$(echo $resultcatch | awk '{print $3}' 2>&1)
				dpkg --compare-versions $requiredver le $depversion
				if [ ! 0 -eq $? ] ; then
					writeLog "	SNI support requires ${dependency}${testarch} ${requiredver}, found $depversion"
					failcount=$(($failcount + 1))
				fi
			fi
		else 
			writeLog "	${dependency}${testarch} dependency can not be found."
			failcount=$(( $failcount + 1 ))
		fi
	done
	
	if [ $failcount -gt 0 ] ; then
		writeLog "	Dependency check failed on $failcount packages."
		writeLog "	Cannot install SNI compatible UI."
		return 0
	fi
	return 1
}

#check whether current env meets with the requirement for all packages or specified package.
preCheckEnv()
{
	local fail=0
	local subret=0
	local packagename=$1
        local prefix="$2"

	writeLog "Performing pre-check..."

	if [ "" = "${curdir}" ] ; then
		writeLog "Error:		Please export curdir='the current folder' and run install again."
		return 1
	fi

	if [ ${packagename} = "all" ] ; then
                #pre-check for --prefix folder
                checkWhitespace "${prefix}"
                subret=$?
                if [ $subret -ne 0 ] ; then
			writeLog "The \"--prefix\" path \"${prefix}\" contains whitespace which are not permitted. Please use another path which doesn't contain whitespace and try again."
			fail=1
		fi

		#pre-check for all packages

		#first check glibc.i686 in X64 platform
		IsPlatformX64
		if [ $? -eq 1 ] ; then
			glibcCheck
			subret=$?

			if [ $subret -ne 0 ] ; then
				writeLog "Error:		Installation requires 32bits glibc library. Please install it and try again."
				fail=1
			fi
		fi

		SniUiNeeded
		subret=$?

		if [ ! $subret -eq 0 ] ; then
			#conditions where sni compatible UI is required to display system tray have been met
			writeLog "Info:	SNI compatible ui is required for System Tray support on this platform"
			SniUiCheck
			subret=$?

			if [ ! $subret -eq 1 ] ; then
				writeLog "Warning:  GUI with support for Unity system tray icon cannot be installed!"
			fi
		fi

		#second check libX11 package
		#only show a waning to end user
		X11Check
		subret=$?

		if [ $subret -ne 0 ] ; then
			writeLog "Warning:	X11 libraries are missing, GUI component will not be installed!"
		fi

		if [ $fail -eq 0 ] ; then
			echo "yes" > "${PRECHECK_CFG}"
			if [ -f "${INSTALL_DATA}" ] ; then
				rm -f "${INSTALL_DATA}" >> ${LOG} 2>&1
			fi
			writeLog "Pre-check succeeded"
		fi
	else
		#pre-check for specified packages

		if [ -f "${PRECHECK_CFG}" ] ; then
			#check libX11 for savui package even the PRECHECK_CFG file exist
			#the rpm method will check it automatically
			#but it is hard to specify the dependence in deb because the package name is different in different distribution
			if [ ${packagename} = "savui" ] ; then
				X11Check
				subret=$?

				if [ $subret -ne 0 ] ; then
					writeLog "Error:	Installation GUI component requires X11 libraries. Please install them and try again."
					fail=1
				fi
			fi

			if [ ${packagename} = "savui-ub" ] ; then
				SniUiNeeded
				subret=$?

				if [ $subret -eq 0 ] ; then
					fail=1
				else
					SniUiCheck
					subret=$?
					if [ $subret -eq 0 ] ; then
						writeLog "Error:	SNI compatible UI dependencies were not found."
						fail=1
					fi
				fi
			fi

			if [ $fail -eq 0 ] ; then
				echo "Found ${PRECHECK_CFG}, no need to perform pre-check" >> ${LOG}
				writeLog "Pre-check is successful"
			fi
		else
                        #pre-check for --prefix folder
                        checkWhitespace "${prefix}"
                        subret=$?
                        if [ $subret -ne 0 ] ; then
        			writeLog "The \"--prefix\" path \"${prefix}\" contains whitespace which are not permitted. Please use another path which doesn't contain whitespace and try again."
        			fail=1
	        	fi

			#second check glibc.i686 in X64 platform
			IsPlatformX64
			if [ $? -eq 1 ] ; then
				glibcCheck
				subret=$?

				if [ $subret -ne 0 ] ; then
					writeLog "Error:	Installation requires 32bits glibc library. Please install it and try again."
					fail=1
				fi
			fi

			#third check libX11 for savui package
			#the rpm method will check it automatically
			#but it is hard to specify the dependence in deb because the package name is different in different distribution
			if [ ${packagename} = "savui" ] ; then
				X11Check
				subret=$?

				if [ $subret -ne 0 ] ; then
					writeLog "Error:	Installation GUI component requires X11 libraries. Please install them and try again."
					fail=1
				fi
			fi

			if [ ${packagename} = "savui-ub" ] ; then
				SniUiNeeded
				subret=$?

				if [ $subret -eq 0 ] ; then
					fail=1
				else
					SniUiCheck
					subret=$?
					if [ $subret -eq 0 ] ; then
						writeLog "Error:	SNI compatible UI dependencies were not found."
						fail=1
					fi
				fi
			fi
			
			if [ $fail -eq 0 ] ; then
				writeLog "Pre-check succeeded"
				if [ -f "${INSTALL_DATA}" ] ; then
					rm -f "${INSTALL_DATA}" >> ${LOG} 2>&1
				fi
			fi
		fi
	fi

	return $fail
}

#$1 package name to check such as 'sav'
#return 1 for upgrade.
checkUpgrade()
{
	local name="$1"
	if [ ! -f "${INSTALL_CFG}" ] ; then
		echo "${INSTALL_CFG} doesn't exist." >> ${LOG}
		return 0
	fi

	upgrade=$(cat "${INSTALL_CFG}" | grep -c upgrade_${name})

	if [ 0 -eq $upgrade ] ; then
		echo "cannot find upgrade_${name} at ${INSTALL_CFG}" >> ${LOG}
		return 0
	fi

	return 1
}

#$1 "/etc/symantec/sep/Sylink.xml"
#$2 "/Configuration/sylink.xml" under package media.
#return 1 for copy, 0 for doesn't.
checkCopySylink()
{
        local new_etc_sylink="$1"
        local pkg_sylink="$2"
        local old_etc_sylink="/etc/symantec/sylink.xml"

        #if "/etc/symantec/sep" and "/etc/symantec" doesn't contain Sylink.xml, need copy it.
        if [ ! -f "${old_etc_sylink}" ] && [ ! -f "${new_etc_sylink}" ] && [ -f "${pkg_sylink}" ]; then
                echo "Sylink.xml doesn't exist, need copy it" >> ${LOG}
                return 1
        fi

        # Prior to Lamborghini sylink.xml will be present at /etc/symantec, so moving to /etc/symantec/sep
        if [ -f "${old_etc_sylink}" ] && [ ! -f "${new_etc_sylink}" ]; then
                 mv -f "$old_etc_sylink" "$new_etc_sylink" >> ${LOG} 2>&1
                        if [ 0 -eq $? ] ; then
                                echo "Succeed to copy $old_etc_sylink to $new_etc_sylink" >> ${LOG}
                        fi
        fi
				
		if [ ! -f "${pkg_sylink}" ] ; then
                echo "'${pkg_sylink}' doesn't exist." >> ${LOG}
				return 0
		fi
        
		#if sylink.xml in package contains server list, copy it to replace current one.
        servers=$(cat "${pkg_sylink}" | grep -c "</ServerList>")

        if [ 0 -eq ${servers} ] ; then
                echo "'${pkg_sylink}' doesn't contain any server." >> ${LOG}
                return 0
        fi

        echo "'${pkg_sylink}' contains server." >> ${LOG}

        echo "Existing communication settings file will be replaced." >> ${LOG}

        return 1
}

#$1 "/etc/symantec/sep/sep.slf"
#$2 "/Configuration/sep.slf" under package media.
#$3 "/Configuration/sep_NE.slf" under package media.
#return 1 for copy, 0 for doesn't.
checkCopySepLicense()
{

        local new_sep_license="$1"
        local pkg_sepslf="$2"
        local pkg_sepNEslf="$3"
        local old_sep_license="/etc/symantec/sep.slf"

        if [ ! -f "${pkg_sepslf}" ] && [ ! -f "${pkg_sepNEslf}" ] ; then
				 echo "'${pkg_sepslf}' "and" '${pkg_sepNEslf}' doesn't exist." >> ${LOG}
        fi

        #if "/etc/symantec/sep" and "/etc/symantec" doesn't contain sep.slf, need copy it.
        if [[ ! -f "${new_sep_license}"  &&  ! -f "${old_sep_license}" ]] && [[ -f "${pkg_sepslf}"  ||  -f "${pkg_sepNEslf}" ]]; then
                echo "Sep License doesn't exist, need copy it" >> ${LOG}
                return 1
        fi

        # Prior to Lamborghini sep.slf will be present at /etc/symantec, so moving to /etc/symantec/sep
        if [ -f "${old_sep_license}" ] && [ ! -f "${new_sep_license}" ]; then
                 mv -f "$old_sep_license" "$new_sep_license" >> ${LOG} 2>&1
                        if [ 0 -eq $? ] ; then
                                echo "Succeed to copy $old_sep_license to $new_sep_license" >> ${LOG}
                        fi
        fi

        return 0
}

#Delete prior Lamborghini vpregdb files under /etc/symantec after upgrading
deleteFiles()
{
	#delete existing vpregdb files under /etc/symantec
	delete_files="/etc/symantec/VPREGDB.SAV \
			/etc/symantec/VPREGDB.BAK \
			/etc/symantec/VPREGDB.DAT \
			"
	
	for deletefile in $delete_files
	do
		if [ -f $deletefile -o -L $deletefile ] ; then
                        rm -f $deletefile >> "${LOG}" 2>&1 
								if [ 0 -eq $? ] ; then
                                        echo "Successfully delete $deletefile" >> ${LOG}
                                fi
                fi
        done
}

#Prior to Lamborghini vpregdb files will be under /etc/symantec,so coping to /etc/symantec/sep before install packages
#Prior to Lamborghini upgrade installation retained the contents of /var/symantec to /var/symantec/sep
moveFiles()
{
	
	#copy existing files under /etc/symantec to /etc/symantec/sep
	remain_files="/etc/symantec/VPREGDB.SAV \
                       /etc/symantec/VPREGDB.BAK \
                       /etc/symantec/VPREGDB.DAT \
                                "
	
	local new_etc_dir="/etc/symantec/sep/"
	
    for remainfile in $remain_files
        do
                if [ -f $remainfile -o -L $remainfile ] ; then
                        #We need to make sure these files exist in both old and new location before packages are installed
                        cp -f $remainfile $new_etc_dir >> "${LOG}" 2>&1 
								if [ 0 -eq $? ] ; then
                                        echo "Successfully copied $remainfile to $new_etc_dir" >> ${LOG}
                                fi
                fi
        done
	
	#move files under remaining folders from /var/symantec to /var/symantec/sep
    dirs="/Logs/ \
          /Quarantine/ \
	      /sent/ \
	      /auto/ \
	      /cve/ \
	      /pending/ \
         "

    local old_var_dir="/var/symantec"
    local new_var_dir="/var/symantec/sep"

		for dir in $dirs
        do
                if [ -d $old_var_dir$dir ] ; then
			if [ ! -d $new_var_dir$dir ] ; then
				mkdir -p $new_var_dir$dir
			fi
                        mv -f $old_var_dir$dir* $new_var_dir$dir >> "${LOG}" 2>&1
                                if [ 0 -eq $? ] ; then
                                        echo "Successfully moved contents from $old_var_dir$dir to $new_var_dir$dir" >> ${LOG}
                                fi
                fi
        done

	#move existing files from /var/symantec to /var/symantec/sep
    remain_files="/heartbeatStatus.txt \
                  /registration.xml \
                  /registrationInfo.xml \
                  /index2.xml \
                  /serdef.dat \
                  /luProfile.xml \
                  /licenseInfo.xml \
                  /sepOpstateInfo.xml \
                  /commandStatus.xml \
                  /communicationData.xml \
                                "
        for remainfile in $remain_files
        do
                if [ -f $old_var_dir$remainfile ] ; then
                        mv -f $old_var_dir$remainfile $new_var_dir$remainfile >> "${LOG}" 2>&1
								if [ 0 -eq $? ] ; then
                                        echo "Successfully moved $old_var_dir$remainfile to $new_var_dir$remainfile" >> ${LOG}
                                fi
				fi
        done

	return 0
}

#$1 from_build
#$2 to_build
CopyCfg()
{
	if [ ! -d ${ETC_SYMC} ] ; then
		mkdir -p ${ETC_SYMC}
	fi
	
	if [ ! -d ${VAR_SYMC} ] ; then
		mkdir -p ${VAR_SYMC}
	fi

	
	#copy setup.ini and setAid.ini
	local from_build="$1"
	local to_build="$2"
	isNewBuild "${from_build}" "${to_build}"
	local isnewer=$?
	if [ $isnewer -eq 1 ] ; then
		echo "${to_build} is newer than ${from_build}, need to copy setup.ini & setAid.ini" >> ${LOG}
		for cfg in ${CONFIG_LIST}
		do
			local src=${CONFIG}/${cfg}
			local dest=${ETC_SYMC}/${cfg}
			if [ -f "$src" ] ; then
				cp -f "$src" "$dest" >> ${LOG} 2>&1
				if [ 0 -eq $? ] ; then
					echo "Succeed to copy $src to $dest" >> ${LOG}
				fi
			fi

		done
	fi

	#copy sylink.xml
	local etc_sylink="${ETC_SYMC}/sylink.xml"
	local pkg_sylink=${CONFIG}/sylink.xml

	checkCopySylink "${etc_sylink}" "${pkg_sylink}"

	local replace=$?

	if [ 1 -eq $replace ] ; then
		cp -f "${pkg_sylink}" "${etc_sylink}" >> ${LOG} 2>&1
		if [ ! 0 -eq $? ] ; then
				writeLog "Failed to copy '${pkg_sylink}' to '${etc_sylink}', err: $?"
				return 1
		fi
		echo  "Succeed to copy '${pkg_sylink}' to '${etc_sylink}'." >> ${LOG}
	fi
	
    local etc_cert_bundle="${ETC_SYMC}/sepfl.pem"
    local pkg_cert_bundle="${CONFIG}/sepfl.pem"
    #copy certificate bundle file
    if [ ! -f  etc_cert_bundle ] ; then
        cp -f "$pkg_cert_bundle" "$etc_cert_bundle" >> ${LOG} 2>&1
                    if [ 0 -eq $? ] ; then
                            echo "Succeed to copy $pkg_cert_bundle to $etc_cert_bundle" >> ${LOG}
                    fi
    fi    
    
	#copy serdef.dat
	local serdef=${CONFIG}/serdef.dat
	local profile=${VAR_SYMC}/serdef.dat

	if [ -f "$serdef" ] ; then
		cp -f "$serdef" "$profile" >> ${LOG} 2>&1
			if [ 0 -eq $? ] ; then
					echo "Succeed to copy $serdef to $profile" >> ${LOG}
			fi
	fi
		
	#copy sep.slf or sep_NE.slf
    local etc_sepslf="${ETC_SYMC}/sep.slf"
    local pkg_sepslf="${CONFIG}/sep.slf"
    local pkg_sepNEslf="${CONFIG}/sep_NE.slf"

    checkCopySepLicense "${etc_sepslf}" "${pkg_sepslf}" "${pkg_sepNEslf}"

    local replace=$?

    if [ 1 -eq $replace ]; then
        if [ -f "$pkg_sepslf" ] ; then
					cp -f "$pkg_sepslf" "$etc_sepslf" >> ${LOG} 2>&1
                    if [ 0 -eq $? ] ; then
                            echo "Succeed to copy $pkg_sepslf to $etc_sepslf" >> ${LOG}
                    fi
        else
        if [ -f "$pkg_sepNEslf" ] ; then
                     cp -f "$pkg_sepNEslf" "$etc_sepslf" >> ${LOG} 2>&1
                    if [ 0 -eq $? ] ; then
                             echo "Succeed to copy $pkg_sepNEslf to $etc_sepslf" >> ${LOG}
                    fi
        fi

        fi
        return 0
    fi

	#Prior to Lamborghini vpregdb files will be present under /etc/symantec, so copying to /etc/symantec/sep
	#Prior to Lamborghini retaining the contents of /var/symantec to /var/symantec/sep during upgrade
	#check older product version to move existing vpregdb files from /etc/symantec to /etc/symantec/sep 
	#check product version less than Lamborghini i.e. < 14.0
	
    from_build_min=$(echo $from_build | awk -F'.' '{print $1}')   
	
	if [ $from_build_min -lt 14 ] ; then
                moveFiles
    fi
    
	echo "No need to replace configuration files." >> ${LOG}

    return 0
}

#we will not start symcfgd, rtvscand & smcd during install.
#after install, we will start symcfgd, rtvscand & smcd.
#by doing this, it will speed up the installation process.
disableDaemon()
{
#first remove the old install configuration file if it exists.
	rm -f ${INSTALL_CFG} >> ${LOG} 2>&1
	for daemon in ${DAEMONS}
	do
		echo "${daemon}_enable=0" >> ${INSTALL_CFG}
		if [ -f /etc/init.d/${daemon} ] ; then
			/etc/init.d/${daemon} stop >> ${LOG} 2>&1
		fi
	done
}

isprecompilesymevreloaded()
{
	local symev=$(/sbin/lsmod | grep -e "^symev" | awk -F' ' '{print $1}' | sed -e 's/_/\-/g' -e 's/\./-/g')
	if [ "" = "$symev" ] ; then
		return 1 #no driver found.
	fi

	echo ${symev} | grep -e "^symev-custom" > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
		return 1 #no pre-compiled driver found.
	fi

	local symc_dir=$(cat /etc/Symantec.conf | grep BaseDir | awk -F'=' '{print $2}')
	local ap_dir="${symc_dir}/autoprotect"
	pushd ${ap_dir} > /dev/null 2>&1
	local apfiles=$(ls symev* | xargs | sed -e 's/\.ko//g' -e 's/\./-/g' -e 's/_/-/g')
	for file in $apfiles
	do
		if [ "$file" = "${symev}" ] ; then
			echo "found ${symev}" >> ${LOG}
			popd > /dev/null 2>&1
			return 0
		fi
	done
	popd > /dev/null 2>&1
	
	echo "Cannot found ${symev}.ko" >> ${LOG}
	return 1
}

removeselfcompiledsymevrm()
{
	local symc_dir=$(cat /etc/Symantec.conf | grep BaseDir | awk -F'=' '{print $2}')
	local ap_dir="${symc_dir}/autoprotect"
	pushd ${ap_dir} > /dev/null 2>&1
	local apfiles=$(ls .symevrm-custom-*)
	for file in $apfiles
	do
		rm -f "${file}"
	done
	popd > /dev/null 2>&1
}

## o/p of ls <dirname>/<regx>* is of the following form:
## - each regular-file on a separte line.
## - each directory-file on a separate line with ':' character appended at the end of the directory name.
rm_prev_kmod_dirs()
{
	local srcdir="$1"
	[ ! -d "$srcdir" ] && return

	local adirlist=( $(ls -d "$srcdir"/ap-kernelmodule-* 2>/dev/null | tr ":" " " ) )
	local acntdirlist="${#adirlist[@]}"
	let "acntdirlist += 0"

	for (( i = 0; i < acntdirlist; i++ )) ; do
		[ -d "${adirlist["$i"]}" ] && rm -fr "${adirlist["$i"]}"
	done
}

compilekernelmodules()
{
	local err=0
	writeLog "Pre-compiled Auto-Protect kernel modules are not loaded yet, need compile them from source code"
	pushd "${SRC_DIR}" > /dev/null 2>&1
	rm_prev_kmod_dirs "$PWD"
	if [ -e ${SRC_PACKAGE} ] ; then
		tar -jxvf ${SRC_PACKAGE} >> ${LOG} 2>&1
		err=$?
		if [ ${err} -eq 0 ] ; then
			pushd `ls -d ap-kernelmodule-*` > /dev/null 2>&1
			./build.sh >> /dev/null 2>&1
			err=$?
			if [ ${err} -eq 0 ] ; then
				writeLog "Build Auto-Protect kernel modules from source code successfully"
			else
				writeLog "Build Auto-Protect kernel modules from source code failed with error: ${err}"
			fi
			popd > /dev/null 2>&1
		else
			writeLog "Fail to extract Auto-Protect source code package with error: ${err}"
		fi
	else
		writeLog "Auto-Protect source code package does not exist"
	fi
	popd > /dev/null 2>&1
}

enableDaemon()
{
#enable autoprotect.
	if [ -f /etc/init.d/autoprotect ] ; then
		/etc/init.d/autoprotect start >> ${LOG} 2>&1

		isprecompilesymevreloaded
		if [ $? -eq 1 ] ; then
			compilekernelmodules
		fi
	fi

#remove install configuration file.
	rm -f ${INSTALL_CFG} >> ${LOG} 2>&1
	
	for daemon in ${DAEMONS}
	do
		if [ ! -f /etc/init.d/${daemon} ] ; then
			echo "/etc/init.d/${daemon} doesn't exist, skip enable it." >> ${LOG}
			continue
		fi

		/etc/init.d/${daemon} start >> ${LOG} 2>&1
		if [ ! 0 -eq $? ] ; then
			writeLog "failed to start $daemon ."
		else
			echo "$daemon is started successfully." >> ${LOG}
		fi
	
		#enable ap
		if [ "${daemon}" = "rtvscand" ] ; then
			local symc_dir=$(cat /etc/Symantec.conf | grep BaseDir | awk -F'=' '{print $2}')
			local savtool=${symc_dir}/symantec_antivirus/sav
			if [ -f $savtool ] ; then
				$savtool autoprotect -e >> ${LOG} 2>&1
				local ret=$?
				if [ 0 -eq $ret ] ; then
					echo "Succeed to enable ap" >> ${LOG}
				else
					echo "Failed to enable ap, err: ${ret}" >> ${LOG}
				fi
				local apstatus=$(${savtool} info -a 2>>${LOG})
				echo "AP status: ${apstatus}" >> ${LOG}
			fi
		fi

	done
}

selinuxSupport()
{
	which getenforce > /dev/null 2>&1
	if [ ! 0 -eq $? ] ; then
		writeLog "getenforce is not installed, SELinux is not enabled, skip setting selinux attribute."
		return 0
	fi
	
	which chcon > /dev/null 2>&1
	if [ ! 0 -eq $? ] ; then
		writeLog "chcon is not installed, skip setting selinux attribute."
		return 0
	fi

	if [ "${PREFIX}" != "" ] ; then
		dir="${PREFIX}/symantec_antivirus"
	else
		dir=/opt/Symantec/symantec_antivirus
	fi

	chcon -R -t texrel_shlib_t $dir >> "${LOG}" 2>&1
	
	return 0
}

InstallDeb()
{
	local ret=0
	IsX64=0
	IsSniUiNeeded=0
	IsSniUiPossible=0
	IsPlatformX64
	if [ 1 -eq $? ] ; then
		IsX64=1
	fi

	SniUiNeeded
	if [ 1 -eq $? ] ; then
		IsSniUiNeeded=1
		SniUiCheck
		if [ 1 -eq $? ] ; then
			IsSniUiPossible=1
		fi
	fi

	export curdir="${PACKAGE_DIR}"

	for pa in ${INSTALL_PKG_LIST}
	do
		if [ "${pa}" = "sepap" -a 1 -eq ${IsX64} ] ; then
			package=${pa}-x64.deb
		elif [ "${pa}" = "sepui" -a 1 -eq ${IsSniUiPossible} ] ; then
			if [ 1 -eq ${IsX64} ] ; then
				package=${pa}-ub-x64.deb
			else
				package=${pa}-ub.deb
			fi
		else
			package=${pa}.deb
		fi

		deb="${PACKAGE_DIR}/${package}"

		if [ ! -f "$deb" ] ; then
			if [ "${pa}" = "sep" ] ; then
				writeLog "${deb} doesn't exist, install failed."
				ret=1
				break
			else
				writeLog "${deb} package is missing. Skipping ..."
				continue
			fi
		fi

		beginInst "${pa}"
		dpkg -i "$deb" 2>>"${LOG}"

		if [ 0 -eq $? ] ; then
			endInst "${pa}"
			continue
		else
			local errmsg=$(awk '{a[NR]=$0} END{print a[NR=FNR]}' "${LOG}")
			failInst "${pa}" "${errmsg}"
			if [ "${pa}" = "sep" ] ; then
				ret=1
				break
			else
				continue
			fi
		fi
	done

	unset curdir

	return $ret
}

InstallRpm()
{
	local ret=0
	IsX64=0
	IsPlatformX64
	if [ 1 -eq $? ] ; then
		IsX64=1
	fi

	#export curdir so that rpm scripts can get the current folder.
	export curdir="${PACKAGE_DIR}"

	for pa in ${INSTALL_PKG_LIST}
	do
		# we don't need to check whether existing rpm is installed or not.
		# this should be done by RPM DB and if the rpm is installed before, 
		# upgrade will be performed.
		if [ ${pa} = "sepap" -a 1 -eq ${IsX64} ] ; then
			package=${pa}-x64.rpm
		else
			package=${pa}.rpm
		fi

		pkg="${PACKAGE_DIR}/${package}"

		if [ ! -f "${pkg}" ] ; then
			if [ "${pa}" = "sep" ] ; then
				writeLog "${pkg} doesn't exist, install failed."
				ret=1
				break
			else
				writeLog "${pkg} package is missing. Skipping ..."
				continue
			fi
		fi
		local module=$(echo $package | sed -e 's/sep/sav/g' -e 's/.rpm//g')
		beginInst "${pa}"

		doubleref=0
		rpm -qpi "${pkg}" 2>/dev/null | grep 'Vendor: Symantec Corporation' > /dev/null 2>&1
		if [ ! 0 -eq $? ] ; then
			rpm -qpi "\"${pkg}\"" 2>/dev/null | grep 'Vendor: Symantec Corporation' > /dev/null 2>&1
			if [ 0 -eq $? ] ; then
				doubleref=1
			fi
		fi

		if [ "${PREFIX}" != "" ] ; then
			if [ 1 -eq $doubleref ] ; then
				rpm -Uvh "--prefix=${PREFIX}" "\"${pkg}\"" 2>>"${LOG}"
			else
				rpm -Uvh "--prefix=${PREFIX}" "${pkg}" 2>>"${LOG}"
			fi
		else
			if [ 1 -eq $doubleref ] ; then
				rpm -Uvh "\"${pkg}\"" 2>>"${LOG}"
			else
				rpm -Uvh "${pkg}" 2>>"${LOG}"
			fi
		fi

		if [ 0 -eq $? ] ; then
			endInst "${pa}"
			continue
		else
			local errmsg=$(awk '{a[NR]=$0} END{print a[NR=FNR]}' "${LOG}")
			failInst "${pa}" "${errmsg}"
			if [ "${pa}" = "sep" ] ; then
				ret=1
				break
			else
				continue
			fi
		fi
	done

	unset curdir
	return $ret
}

getOldProductVersion()
{
	if [ -f ${ETC_SYMC}/setup.ini ] ; then
		local FromProduct=$(cat ${ETC_SYMC}/setup.ini | grep ProductVersion | awk -F'=' '{print $2}' | sed -e 's/^ //g' -e 's/\r//g')
		echo $FromProduct
		return 0
	else
		local pkgs="sav savap"
		IsRpmSupported
		if [ 0 -eq $? ] ; then #rpm not supported.
			for pkg in $pkgs
			do
				local FromProduct=$(dpkg -s $pkg 2>/dev/null | grep Version | awk -F':' '{print $2}' | sed -e 's/ //g' -e 's/-/./g')
				if [ ! "" = "$FromProduct" ] ; then
					echo $FromProduct
					return 0
				fi
			done
		else
			for pkg in $pkgs
			do
				local FromProduct=$(rpm -qa $pkg 2>/dev/null | cut -d '-' -f 2- | sed -e 's/ //g' -e 's/-/./g')
				if [ ! "" = "$FromProduct" ] ; then
					echo $FromProduct
					return 0
				fi
			done
		fi

		echo ""
		return 0
	fi
}

getInstallProductVersion()
{
	if [ -f "${CONFIG}/setup.ini" ] ; then
		local ToProduct=$(cat "${CONFIG}/setup.ini" | grep ProductVersion | awk -F'=' '{print $2}' | sed -e 's/^ //g' -e 's/\r//g')
		echo $ToProduct
		return 0
	fi

	echo ""
	return 0
}

#$1 from build.
#$2 to build.
isNewBuild()
{
	from="$1"
	to="$2"

	if [ "${from}" = "" ] ; then #fresh install
		return 1
	fi
	old_maj=$(echo $from | awk -F'.' '{print $1}')
	old_min=$(echo $from | awk -F'.' '{print $2}')
	old_sub=$(echo $from | awk -F'.' '{print $3}')
	old_build=$(echo $from | awk -F'.' '{print $4}')

	new_maj=$(echo $to | awk -F'.' '{print $1}')
	new_min=$(echo $to | awk -F'.' '{print $2}')
	new_sub=$(echo $to | awk -F'.' '{print $3}')
	new_build=$(echo $to | awk -F'.' '{print $4}')

	if [ "" = "${old_maj}" ] ; then 
		return 1
	elif [ "" = "${new_maj}" ] ; then
		return 0
	fi

	if [ ${old_maj} -lt ${new_maj} ] ; then
		return 1
	elif [ ${old_maj} -gt ${new_maj} ] ; then
		return 0
	fi

	#$old_maj=$new_maj
	if [ "" = "${old_min}" ] ; then
		return 1
	elif [ "" = "${new_min}" ] ; then
		return 0
	fi

	if [ ${old_min} -lt ${new_min} ] ; then
		return 1
	elif [ ${old_min} -gt ${new_min} ] ; then
		return 0
	fi

	#$old_min=$new_min
	if [ "" = "${old_sub}" ] ; then
		return 1
	elif [ "" = "${new_sub}" ] ; then
		return 0
	fi

	if [ ${old_sub} -lt ${new_sub} ] ; then
		return 1
	elif [ ${old_sub} -gt ${new_sub} ] ; then
		return 0
	fi

	#$old_sub=$new_sub
	if [ ${old_build} -lt ${new_build} ] ; then
		return 1
	else #$old_build >= $new_build
		return 0
	fi
}

#Prior to Lamborghini we are retaining the registry files during upgrade.
#The earlier registry files have the path to the home directory as /var/symantec
#Post Lamborghini the path to the Home Directory is /var/symantec/sep , so updating the registry path for home directory
updateRegistry()
{
	local baseDir=$(getBaseDir)
        local symcfg="${baseDir}/symantec_antivirus/symcfg"
        local key="\Symantec Endpoint Protection\AV"
        local value="Home Directory"
        local data="/var/symantec/sep"
        local type="REG_SZ"

        #Update the existing key-value in the registry
        $symcfg add -k "${key}" -v "${value}" -d "${data}" -t ${type} >> "${LOG}" 2>&1
	
	# Update/Add LUX
	$symcfg add -k "${key}" -v "LUX Directory" -d "${baseDir}/LiveUpdate" -t ${type} >> "${LOG}" 2>&1

	return 0
}

install()
{
	local ret=0

	writeLog "Starting to install Symantec Endpoint Protection for Linux"

	#try to get old product version.
	local former_build=$(getOldProductVersion)
	local current_build=$(getInstallProductVersion)
	if [ "${current_build}" = "" ] ; then
		writeLog "Cannot complete installation. setup.ini is missing."
		return 1
	fi
	echo "FromProduct=${former_build}" >> ${LOG}
	echo "ToProduct=${current_build}" >> ${LOG}

	#check version first, make sure not downgrade
	isNewBuild "${former_build}" "${current_build}"
	local isnewer=$?
	if [ $isnewer -eq 0 ] ; then
		writeLog "Downgrade is not supported. Please make sure the target version is newer than the original one."
		return 1
	fi
    
	#Defect #3865652
	#Remove the self-compiled .symevrm-custom-xxx.ko file on 12.1 RU6 RTM+ (not include) ~ 14.0 Lambo- (not include) builds
	isNewBuild "12.1.6168.6000" "${former_build}"
	local isnewer=$?
	if [ $isnewer -eq 1 ] ; then
		isNewBuild "${former_build}" "14.0.0.0"
                isnewer=$?
		if [ $isnewer -eq 1 ] ; then
			removeselfcompiledsymevrm
		fi
	fi

	export curdir="${PACKAGE_DIR}"
	preCheckEnv "all" "${PREFIX}"
	ret=$?
	unset curdir

	if [ $ret -ne 0 ] ; then
		writeLog "Pre-check failed."
		return 1
	fi

	#check older product version to update registry home directory path to /var/symantec/sep during upgrade
	#For etrack 3881186 : To update the registry Home directory path using symcfg we need daemons running
    #check older product version less than Lamborghini i.e. < 14.0
    
	if [ ! "" = "${former_build}" ] ; then
			former_build_min=$(echo $former_build | awk -F'.' '{print $1}')
			if [ $former_build_min -lt 14 ] ; then
				updateRegistry
			fi
	fi
	
	#first set flag to disable dameons during the installation.
	disableDaemon

	if [ ! "" = "${former_build}" ] ; then
		preInst "${former_build}"
	fi

	#copy SyLink.xml, then install rpm or deb.
	CopyCfg "${former_build}" "${current_build}"

	IsRpmSupported
	if [ 0 -eq $? ] ; then
		InstallDeb
		ret=$?
	else
		InstallRpm
		ret=$?
	fi

	#exit when the packages are not installed successfully
	if [ ! 0 -eq $ret ] ; then
		return $ret
	fi

	#set selinux attributes for savfl folders.
	selinuxSupport

	#start daemons after install.
	enableDaemon

	#make modprobe -l symap* and modprobe -l symev* work fine.
	depmodkernel
	
	if [ ! "" = "${former_build}" ] ; then
		postInst "${former_build}"
	fi

	# Run LiveUpdate post install
	local basedir=$(getBaseDir)
	if [ ! -f "$basedir/LiveUpdate/{9F634534-BAF4-444B-B823-F14C1C80A8FD}.lck" ] ; then
	    echo "Running LiveUpdate to get the latest defintions..."
	    $basedir/symantec_antivirus/sav liveupdate -u
	fi

	from_build_min=$(echo ${former_build} | awk -F'.' '{print $1}')   
	
	if [ $from_build_min -lt 14 ] ; then
		deleteFiles
	fi

	writeLog "Installation completed"

	return $ret
}

UninstallDeb()
{
	num=${#PACKAGE_LIST[@]}
	local failnum=0
	for ((i=1; i<=${num};i++));
	do
		idx=$(($num - $i))
		pa=${PACKAGE_LIST[$idx]}

		dpkg -s ${pa} > /dev/null 2>&1
		if [ ! 0 -eq $? ] ; then
			echo "${pa} has not been installed yet." >> ${LOG}
			continue
		fi

		beginRm "${pa}"
		dpkg -P ${pa} | tee -a "${LOG}"
		if [ 0 -eq $? ] ; then
			endRm "${pa}"
			continue
		fi

		failRm "${pa}" "$?"
		failnum=$((failnum +1))
	done

	if [ $failnum -eq 0 ] ; then
		echo "Perform post uninstall operations." >> ${LOG}
		postrm
		echo "Post uninstall operations finished." >> ${LOG}
	fi

	return 0
}

UninstallRpm()
{
	local num
	local isX64=0
	IsPlatformX64
	isX64=$?
	if [ ${isX64} -eq 1 ] ; then
		#x86_64
		num=${#PACKAGE_LIST_X64[@]}
	else
		#i386
		num=${#PACKAGE_LIST[@]}
	fi

	local failnum=0
	for ((i=1;i<=${num};i++))
	do
		idx=$(($num - $i))

		if [ ${isX64} -eq 1 ] ; then
			#x86_64
			pa=${PACKAGE_LIST_X64[$idx]}
		else
			#i386
			pa=${PACKAGE_LIST[$idx]}
		fi

		rpm -qa ${pa} | grep ${pa} > /dev/null 2>&1
		if [ 0 -eq $? ] ; then
			beginRm "${pa}"
			rpm -e ${pa} | tee -a "${LOG}"
			if [ 0 -eq $? ] ; then
				endRm "${pa}"
			else
				failRm "${pa}" "$?"
				failnum=$((failnum + 1))
			fi
		else
			echo "The package ${pa} has not been installed yet." >> ${LOG}
		fi
	done

	if [ $failnum -eq 0 ] ; then
		echo "Perform post uninstall operations" >> ${LOG}
		postrm
		echo "Post uninstall operations finished" >> ${LOG} 
	fi

	return 0
}

postrm()
{
	#remove unnecessary files.
# defect 3407299. The /etc/Symantec.conf file may also remain for other Symantec product may use it (MR14 Impl.pdf)
	#rmfiles="/etc/Symantec.conf"
	#for file in $rmfiles
	#do
	#	if [ -f "$file" ] ; then
	#		rm -f "$file" >> ${LOG} 2>&1
	#	fi
	#done

	#remove avdefs group.
	groupdel avdefs >> ${LOG} 2>&1

	#remove some the remaining folders
	local basedir=$(getBaseDir)
	if [ "${basedir}" = "" ] ; then
		basedir="/opt/Symantec"
	fi

	if [ -d "${basedir}/virusdefs" ] ; then
		rm -rf "${basedir}/virusdefs"
	fi
}

prerm()
{
	#remove soft link of kernel drivers under /lib/modules/kernelversion/kernel/drivers/char 
	#for all Kernel versions on the machine this is possible when multiple kernel versions are installed.
	local kerneldir="/lib/modules/*/kernel/drivers/char"
	local symap=$(ls $kerneldir/symap* 2>/dev/null | xargs)
	local symev=$(ls $kerneldir/symev* 2>/dev/null | xargs)
        local symevrm=$(ls $kerneldir/-symevrm* 2>/dev/null | xargs)

	for ap in $symap
	do
		echo "remove $ap" >> "${LOG}"
		rm -f $ap >> "${LOG}" 2>&1
	done

	for ev in $symev
	do
		echo "remove $ev" >> "${LOG}"
		rm -f $ev >> "${LOG}" 2>&1
	done

	for evrm in $symevrm
	do
		echo "remove $evrm" >> "${LOG}"
		rm -f $evrm >> "${LOG}" 2>&1
	done
}

uninstall()
{
	local retval=0
	echo "Starting to uninstall Symantec Endpoint Protection for Linux."
	echo "$(date): Starting to uninstall Symantec Endpoint Protection for Linux." >> "${LOG}"

	prerm
	IsRpmSupported

	if [ 0 -eq $? ] ; then
		UninstallDeb
		retval=$?
	else
		UninstallRpm
		retval=$?
	fi

	echo "Uninstall completed"
	echo "$(date): Uninstall completed" >> "${LOG}"

	setSplit
	writeLog "The log files for uninstallation of Symantec Endpoint Protection for Linux are under ~/:"
	local logfiles="sepfl-install.log\
			sep-install.log\
			sepap-install.log\
			sepui-install.log\
			"

	for logfile in $logfiles
	do
		writeLog "${logfile}"
	done

	return $retval
}

usage()
{
	echo "Usage: install.sh [options]
the options are:
		-i install SEP for Linux.
		-u uninstall SEP for Linux.
		--prefix <dir> install to alternate location if <dir> exists. Note, this option is only for RPM package.
		"
	return 0
}


###############
# Name        : checkRunningEnv()

# Arguments   : na

# Description :
# - Identifies the effective user ID of the user who's executing the script.
# - Only root user (id 0) is allowed to execute the install.sh script.

# Assumptions : na

# Usage       :
# checkRunningEnv

# Return Value:
## 0: if effective user ID of the user who's executing the script is "root" user.
## 1: otherwise. 
###############
checkRunningEnv()
{
	local owner="$USER"
	local user_id="$(id -u)"

	if [ "$user_id" -ne 0 ] ; then  ## user isn't the "root" user.
		echo "You are logged on as $owner. Log off, log on as a superuser, and try again."
		return 1
	fi

	return 0
}

setSplit()
{
	writeLog "============================================================="
}

getBaseDir()
{
	if [ ! -f /etc/Symantec.conf ] ; then
		echo ""
		return 1
	fi

	local dir=$(cat /etc/Symantec.conf | grep BaseDir | awk -F'=' '{print $2}')
	echo $dir
	return 0
}

postCheck()
{
	setSplit
	writeLog "Daemon status:"
	for daemon in ${DAEMONS}
	do
		local status=""
		if [ ! -f /etc/init.d/${daemon} ] ; then
			status="not enabled"
		else
			status=$(/etc/init.d/${daemon} status 2>/dev/null)
			if [ 0 -eq $? ] ; then
				status="running"
			else
				status="stopped"
			fi
		fi

		if [ "smcd" = "${daemon}" -o "symcfgd" = "${daemon}" ] ; then
			writeLog "${daemon}\t\t\t\t[${status}]"
		else
			writeLog "${daemon}\t\t\t[${status}]"
		fi
	done

	setSplit
	local lsmodtool=/bin/lsmod
	if [ ! -f $lsmodtool ] ; then
		lsmodtool=/sbin/lsmod
	fi
	local drivers=$($lsmodtool | grep symap | awk -F' ' '{print $1}')
	if [ ! "" = "${drivers}" ] ; then
		writeLog "Drivers loaded:"
		writeLog "${drivers}"
	else
		writeLog "Error: No drivers are loaded into kernel."
	fi

	setSplit
	local basedir=$(getBaseDir)
	local sav=${basedir}/symantec_antivirus/sav
	local apstatus=$(${sav} info -a 2>>${LOG})
	writeLog "Auto-Protect starting"
	for ((i=1; i<=10; i++))
	do
		echo "AP status: ${apstatus} in ${i} time." >> ${LOG}
		local needwait=0
		if [ "" = "${apstatus}" ] ; then
			needwait=1
		elif [ "Disabled" = "${apstatus}" ] ; then
			needwait=1
		else
			needwait=0
		fi

		if [ 0 -eq $needwait ] ; then
			break
		fi

		sleep 2s
		apstatus=$(${sav} info -a 2>>${LOG})		
	done
	local defstatus=$(${sav} info -d 2>>${LOG})
	writeLog "Protection status:"
	writeLog "Definition:\t${defstatus}"
	writeLog "AP:\t\t${apstatus}"

	setSplit
	writeLog "The log files for installation of Symantec Endpoint Protection for Linux are under ~/:"
	local logfiles="sepfl-install.log\
			sep-install.log\
			sepap-install.log\
			sepui-install.log\
			sepfl-kbuild.log\
			"

	for logfile in $logfiles
	do
		writeLog "${logfile}"
	done
}

#operations before install is started.
#$1 from_build which is used to check whether upgrade from MR14 or before.
preInst()
{
	local isRpm=0
	IsRpmSupported
	if [ 1 -eq $? ] ; then
		isRpm=1
	fi

	#perform check for presence of only sepap-legacy
	#in which case, we need to remove this package for upgrade.
	local savapLegacyName="savap-legacy"

	IsPlatformX64
	if [ $? -eq 1 -a 1 -eq ${isRpm} ] ; then
		savapLegacyName=$"savap-x64-legacy"		
	fi

	if [ 0 -eq ${isRpm} ] ; then
		dpkg -s $savapLegacyName > /dev/null 2>&1
		if [ 0 -eq $? ] ; then
			beginRm "${savapLegacyName}"
			prerm
			dpkg -P ${savapLegacyName} | tee -a "${LOG}"
			if [ 0 -eq $? ] ; then
				endRm "${savapLegacyName}"
			else
				failRm "${savapLegacyName}" "$?"
			fi
		fi
	else
		rpm -qa ${savapLegacyName} | grep ${savapLegacyName} > /dev/null 2>&1
		if [ 0 -eq $? ] ; then
			beginRm "${savapLegacyName}"
			prerm
			rpm -e ${savapLegacyName} | tee -a "${LOG}"
			if [ 0 -eq $? ] ; then
				endRm "${savapLegacyName}"
			else
				failRm "${savapLegacyName}" "$?"
			fi
		fi
	fi

	# This check has to be done in preInst(), if done postInst() the entire LU folder will be deleted
	if [ 1 -eq ${isRpm} ] ; then #perform rpm check for savjlu.
	    rpm -q "savjlu" >> "${LOG}" 2>&1
	    if [ 0 -eq $? ] ; then
		echo "JLU found, uninstalling: $1" >> "${LOG}"
		rpm -e "savjlu" >> "${LOG}"
		if [ 0 -eq $? ] ; then
		    echo "Successfully uninstalled JLU: $1" >> "${LOG}"
		else
		    echo "Failed to uninstall JLU: $1, err: $?" >> "${LOG}"
		fi
	    fi
	else
	    dpkg -s "savjlu" >> "${LOG}" 2>&1
	    if [ 0 -eq $? ] ; then
		echo "JLU found, uninstalling: $1" >> "${LOG}"
		dpkg -P "savjlu" >> "${LOG}"
		if [ 0 -eq $? ] ; then
		    echo "Successfully uninstalled JLU: $1" >> "${LOG}"
		else
		    echo "Failed to uninstall JLU: $1, err: $?" >> "${LOG}"
		fi
	    fi
	fi

	return 0
}

depmodkernel()
{
	local apdir="$(getBaseDir)/autoprotect"
	local kerneldir="/lib/modules/$(uname -r)/kernel/drivers/char"
	local symev=$(/sbin/lsmod | grep -e "^symev" | awk -F' ' '{print $1}')
	local symap=$(/sbin/lsmod | grep -e "^symap" | awk -F' ' '{print $1}')

	if [ "$symev" = "" ] ; then
		echo "kernel drivers are not loaded." >> "${LOG}"
		return 0
	fi

	if [ -f $kerneldir/$symev.ko ] ; then
		rm -f $kerneldir/$symev.ko >> "${LOG}" 2>&1
	fi

	if [ -f $kerneldir/$symap.ko ] ; then
		rm -f $kerneldir/$symap.ko >> "${LOG}" 2>&1
	fi

	pushd $apdir >> "${LOG}" 2>&1
	local evfiles=$(ls symev* | xargs)
	for ev in $evfiles
	do
		local tempevfile=$(echo $ev | sed -e 's/\.ko//g' -e 's/\./-/g' -e 's/_/-/g')
		local tempev=$(echo $symev | sed -e 's/\./-/g' -e 's/_/-/g')
		if [ "$tempev" = "$tempevfile" ] ; then
			ln -s $apdir/$ev $kerneldir/$symev.ko >> "${LOG}" 2>&1
			if [ 0 -eq $? ] ; then
				echo "succeed to make link $kerneldir/$symev.ko" >> "${LOG}"
			else
				echo "failed to make link $kerneldir/symev.ko , err: $?" >> "${LOG}"
			fi
			break
		fi
	done

	if [ "$symap" = "" ] ; then
		echo "symap is not loaded." >> "${LOG}"
		popd >> "${LOG}" 2>&1
		return 0
	fi

	local apfiles=$(ls symap* | xargs)
	for ap in $apfiles
	do
		local tempapfile=$(echo $ap | sed -e 's/\.ko//g' -e 's/\./-/g' -e 's/_/-/g')
		local tempap=$(echo $symap | sed -e 's/\./-/g' -e 's/_/-/g')
		if [ "$tempapfile" = "$tempap" ] ; then
			ln -s $apdir/$ap $kerneldir/$symap.ko >> "${LOG}" 2>&1
			if [ 0 -eq $? ] ; then
				echo "succeed to make link $kerneldir/$symap.ko" >> "${LOG}"
			else
				echo "failed to make link $kerneldir/$symap.ko, err: $?" >> "${LOG}"
			fi

			break
		fi
	done

	/sbin/depmod -A >> "${LOG}" 2>&1

	popd >> "${LOG}" 2>&1
	return 0
}

#Prior to Lamborghini delete the existing contents of /etc/symantec and /var/symantec if exists during upgrade
do_cleanup()
{
	 # remove existing files under /etc/symantec and /var/symantec
	 remain_files="   /etc/symantec/setup.ini \
                      /etc/symantec/setAid.ini \
                      /etc/symantec/cvelog.properties \
                      /var/symantec/heartbeatStatus.txt \
                      /var/symantec/registration.xml \
                      /var/symantec/registrationInfo.xml \
                      /var/symantec/index2.xml \
                      /var/symantec/serdef.dat \
                      /var/symantec/luProfile.xml \
                      /var/symantec/licenseInfo.xml \
                      /var/symantec/sepOpstateInfo.xml \
                      /var/symantec/commandStatus.xml \
                      /var/symantec/communicationData.xml \
                                "
        for remainfile in $remain_files
        do
                if [ -f $remainfile -o -L $remainfile ] ; then
                        rm -f $remainfile >> "${LOG}" 2>&1
                fi
        done

        # remove remaining folders under /etc/symantec and /var/symantec 
        dirs="/var/symantec/auto \
              /var/symantec/sent \
              /var/symantec/Logs \
              /var/symantec/pending \
              /var/symantec/Quarantine \
	          /var/symantec/cve \
              /etc/symantec/NLS \
                "

        for dir in $dirs
        do
                if [ -d $dir ] ; then
                        rm -rf $dir >> "${LOG}" 2>&1
                fi
        done
	
	return 0
}

#operations after install is finished.
#$1 from_build which is used to check whether upgrade from MR14 or before.
#1. check whether savreporter is installed, if so, remove it.
postInst()
{
	#check older product version to do cleanup of existing contents from /etc/symantec and /var/symantec
	#check product version less than Lamborghini i.e. < 14.0
	from_build="$1"
    from_build_min=$(echo $from_build | awk -F'.' '{print $1}')   
	if [ $from_build_min -lt 14 ] ; then
                do_cleanup
    fi

	isNewBuild "1.0.14.999" "$1"
	if [ 1 -eq $? ] ; then #not upgrade from 1.0.14 or before.
		echo "from $1, not upgrade from 1.0.14 or before." >> "${LOG}"
		return 0
	fi

	IsRpmSupported
	if [ 1 -eq $? ] ; then #perform rpm check for savreporter.
		rpm -q "$SAVREPORTER" >> "${LOG}" 2>&1
		if [ 0 -eq $? ] ; then
			echo "found $SAVREPORTER, need to remove it." >> "${LOG}"
			rpm -e "$SAVREPORTER" >> "${LOG}" 2>&1
			if [ 0 -eq $? ] ; then
				echo "succeeded to remove $SAVREPORTER" >> "${LOG}"
			else
				echo "failed to remove $SAVREPORTER, err: $?" >> "${LOG}"
			fi
		fi
	else
		dpkg -s "$SAVREPORTER" >> "${LOG}" 2>&1
		if [ 0 -eq $? ] ; then
			echo "found $SAVREPORTER, need to remove it." >> "${LOG}"
			dpkg -P "$SAVREPORTER" >> "${LOG}" 2>&1
			if [ 0 -eq $? ] ; then
				echo "succeeded to remove $SAVREPORTER" >> "${LOG}"
			else
				echo "failed to remove $SAVREPORTER" >> "${LOG}"
			fi
		fi
	fi

	return 0
}

## main() starts here:
if [ "$1" = "" ] ; then
	usage
	exit 1
fi

while [ "$1" != "" ] ; 
do
	case $1 in
		-h | --help)	usage
						exit 0
						;;
		-i)				export IS_INSTALL=1
						;;
		-u)				export IS_UNINSTALL=1
						;;
		--prefix)		shift ; export PREFIX=$1
						;;
		--precheck)		IS_PRECHECK=1 ; shift ; PRECHECK_PACKAGE_NAME=$1 ; shift ; PREFIX="$1"
						;;
		*)				usage
						exit 1
						;;
		esac
		shift
done

if [ 0 -eq ${IS_PRECHECK} ] ; then 
	#normal installation
	# Rename logfile if already exists, use pid for extension
	if [ -f ${LOG} ] ; then
		mv -f ${LOG} ${LOG}.$$
	fi

	## Checks who's executing the install.sh script. Only "root" user can do it.
	checkRunningEnv
	if [ $? -ne 0 ] ; then
		exit 1
	fi


	ret=0

	if [ 1 -eq ${IS_INSTALL} ] ; then
		if [ -f "${PRECHECK_CFG}" ] ; then
			rm -f "${PRECHECK_CFG}" >> ${LOG} 2>&1
		fi

		## - Exports PROD_ROOT_TMP_DIR variable to make it a part of current environment.
		## - All the children processes use this variable.
		export_and_apply_stickybit

		install

		ret=$?

		if [ -f "${PRECHECK_CFG}" ] ; then
			rm -f "${PRECHECK_CFG}" >> ${LOG} 2>&1
		fi

		if [ -f "${INSTALL_DATA}" ] ; then
			rm -f "${INSTALL_DATA}" >> ${LOG} 2>&1
		fi

		if [ 0 -eq ${ret} ] ; then
			postCheck
		fi

	elif [ 1 -eq ${IS_UNINSTALL} ] ; then
		uninstall
		ret=$?
	fi
else
	#precheck for specified package and --prefix folder
	preCheckEnv ${PRECHECK_PACKAGE_NAME} "${PREFIX}"
	ret=$?
fi

exit ${ret}

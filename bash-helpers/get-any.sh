#!/bin/bash

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>
#
#   (c) 2011 - Manuel Tortosa <manutortosa[at]chakra-project[dot]org>

#
# global vars
#
_script_name="Get «Any» Package(s)"
_ver="1.0"
_args=$(echo $1)
_dest_repo=$(echo $2)
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_needed_functions="config_handling helpers messages"
_build_arch="$_arch"
_carch="x86_64"
[[ ${_arch} = *x*64* ]] && _carch="i686"

# helper functions
for subroutine in ${_needed_functions} ; do
	source _buildscripts/functions/${subroutine}
done

for cr in core platform desktop apps games lib32 ; do
	if [ "$(echo "${_cur_repo}" | cut -d- -f1)" == ${cr} ] ; then
		_cur=$(echo "${_cur_repo}" | cut -d- -f2)
	fi
	if [ "$(echo "${_dest_repo}" | cut -d- -f1)" == ${cr} ] ; then
		_dest=$(echo "${_dest_repo}" | cut -d- -f2)
	fi
done
if [ "$_cur" == "" ] ; then 
	_cur=$_cur_repo
fi
if [ "$_dest" == "" ] ; then 
	_dest=$_dest_repo
fi

#
# Functions
#
lock_repo()
{
	newline
	status_start "locking «$(echo "${1}" | sed 's/ /» «/g' | sed 's/+/» «/g')» i686 and x86_64"
	locker="$(echo "${_packer}" | cut -d ' ' -f1)+$(echo "${_packer}" | cut -d ' ' -f2)"
	lock=$(curl --silent --data "r=$(echo "${1}" | sed 's/ /+/g')&a=both&u=${_up}&n=${locker}" ${_rsync_server}/akabei/add-lock.php)
	if [ "$lock" = "ok" ] ; then
		status_ok
	else
		status_fail
		error "${lock}"
		newline
		exit 1
	fi
}

unlock_repo()
{
	newline
	status_start "unlocking «$(echo "${1}" | sed 's/ /» «/g' | sed 's/+/» «/g')» i686 and x86_64"
	unlock=$(curl --silent --data "r=$(echo "${1}" | sed 's/ /+/g')&a=both&u=${_up}" ${_rsync_server}/akabei/remove-lock.php)
	if [ "$unlock" = "ok" ] ; then
		status_ok
	else
		status_fail
		error "${unlock}"
	fi
}		

repo_clean()
{
	newline
	status_start "cleaning «$1-${_arch}»"
	recreate_db=$(curl --silent --data "r=$1&a=${_arch}&u=${_up}" http://chakra-project.org/packages/repo-clean.php)
	if [ "$recreate_db" = "ok" ] ; then
		status_done
	else
		status_fail
		error "${recreate_db}"
	fi
}

copy_packages_from_target()
{
	lock_repo "${final_dest}"
    
	newline
	for pkg in $copy_list ; do
		status_start "copying «$pkg» from «${final_dest}-${_carch}» to «${final_dest}-${_arch}»"
		unset copypkg
		#stripped_pkg_name=$(echo "${pkg}" | sed 's/\.pkg\.tar\..z//g')
		copypkg=$(curl --silent --data "r=${final_dest}&a=${_carch}&u=${_up}&n=${pkg}" http://chakra-project.org/packages/copy-any-pkg.php)
		if [ "$copypkg" = "ok" ] ; then
			status_done
		else
			status_fail
			error "${copypkg}"
		fi
	done

	repo_clean "${final_dest}"

	unlock_repo "${final_dest}"
}

check_available_repos()
{
	msg "Checking repos"
	unset checktr
	checktr=$(curl --silent --data "u=${_up}" http://chakra-project.org/packages/available-repos.php)
	if [ "$(echo "$checktr" | cut -d+ -f1)" = 'ok' ] ; then
		for _repo_check in ${checktr} ; do
		if [ "${_repo_check}" = "${_dest}" ] ; then 
			repo_exist="yes"
		fi
		done
		if [ "${repo_exist}" != "yes" ] ; then
			newline
			error "the target repo «${_dest}» it is unknown"
			error "$(echo "$checktr" | sed 's/ok+/available repos:/g')"
			newline
			exit 1
		fi
	else
		newline
		error "unable to check available repos"
		if [ "$checktr" != "" ] ; then
			error "$checktr"
		fi
		newline
		exit 1
	fi
}

copy_any_packages()
{
     	if [ "${_dest}" != "" ] ; then
		check_available_repos
		final_dest=${_dest}

	else
		final_dest=${_cur}
	fi
	
	newline
	msg "searching for «${_args}» in «${final_dest}-${_carch}»"
	export RSYNC_PASSWORD=$(echo ${_rsync_pass})
	repo_files=$(rsync -avh --list-only ${_rsync_user}@${_rsync_server}::dev/${final_dest}/${_carch}/ | cut -d ":" -f 3 | cut -d " " -f 2)

	# Parses more than an arg separated by comma
	parse_args=$(echo "${_args}" | sed 's/,/\n/g')
	for each_arg in $parse_args ; do
		partial_list=$(echo "$repo_files" | grep ${each_arg} | grep 'any.pkg.tar..*z$')
		parse_list=$(echo ${partial_list} ${parse_list})
	done	
	copy_list=''
	for each_file in $parse_list ; do
		file_exist='false'
		for each_add in $copy_list ; do
			if [ "${each_file}" = "${each_add}" ] ; then
				file_exist='true'
			fi
		done
		if [ "${file_exist}" = "false" ] ; then
			copy_list=$(echo "${copy_list} ${each_file}")
		fi
	done

	unset how_mani
	for count in $copy_list ; do
		  ((how_mani++))
	done
	  
	if [ "$copy_list" != "" ] ; then
		newline
		warning "(${how_mani}) packages match your search criteria:"
		newline
		echo "$(echo ${copy_list} | tr ' ' '\012')"
		newline
		question "Do you really want to copy the package(s)? (y/n) "
		while true ; do
			read yn
			case ${yn} in
			[yY]* )
				time copy_packages_from_target
				newline 
				title "All done"
				break
			;;
			[nN]* )
				newline 
				title "no packages are copied" 
				newline 
				break
			;;
			* )
				echo "Enter (y)es or (n)o"
			;;
			esac
		done
	else
		newline
		error "no packages match your search criteria"
		newline
		exit 1
	fi
}

#
# startup
#

clear
title "${_script_name} v${_ver} - $_cur_repo-$_build_arch"

if [ "${_args}" = "" ] ; then
	error " !! You need to specify a target to copy,"
	error "    single names like «attica» or simple regexp like ^kde are allowed."
	newline
	exit 1
fi

load_configs

check_rsync
check_accounts

# NOTE: Don't move this variable, need to be here.
_up=$(echo -n "$(date -u +%W)${_rsync_user}$(echo -n "${_rsync_pass}"|sha1sum|awk '{print $1}')"|sha1sum|awk '{print $1}')

copy_any_packages

newline

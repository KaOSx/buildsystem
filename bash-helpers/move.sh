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
_script_name="Move Package(s)"
_ver="1.3"
_args=$(echo $1)
_dest_repo=$(echo $2)
_srce_repo=$(echo $3)
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_needed_functions="config_handling helpers messages"
_build_arch="$_arch"
_sarch="x32"
[[ ${_arch} = *x*64* ]] && _sarch="x64"

for cr in core platform desktop apps games lib32 ; do
	if [ "$(echo "${_cur_repo}" | cut -d- -f1)" == ${cr} ] ; then
		_cur=$(echo "${_cur_repo}" | cut -d- -f2)
	fi
	if [ "$(echo "${_dest_repo}" | cut -d- -f1)" == ${cr} ] ; then
		_dest=$(echo "${_dest_repo}" | cut -d- -f2)
	fi
done
if [ "$_cur" = "" ] ; then 
	_cur=$_cur_repo
fi
if [ "$_dest" = "" ] ; then 
	_dest=$_dest_repo
fi

# Determine the sync folder
if [ "${_cur}" = "testing" ] ; then
    _sync_folder="_testing-${_sarch}/"
elif [ "${_cur}" = "unstable" ] ; then
    _sync_folder="_unstable-${_sarch}/"
else
    _sync_folder="_repo/remote/"
fi

# helper functions
for subroutine in ${_needed_functions} ; do
	source _buildscripts/functions/${subroutine}
done


#
# Functions
#

lock_repo()
{
	newline
	status_start "locking «$(echo "${1}" | sed 's/ /» «/g' | sed 's/+/» «/g')» ${_arch}"
	locker="$(echo "${_packer}" | cut -d ' ' -f1)+$(echo "${_packer}" | cut -d ' ' -f2)"
	lock=$(curl --silent --data "r=$(echo "${1}" | sed 's/ /+/g')&a=${_arch}&u=${_up}&n=${locker}" ${_rsync_server}/akabei/add-lock.php)
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
	status_start "unlocking «$(echo "${1}" | sed 's/ /» «/g' | sed 's/+/» «/g')» ${_arch}"
	unlock=$(curl --silent --data "r=$(echo "${1}" | sed 's/ /+/g')&a=${_arch}&u=${_up}" ${_rsync_server}/akabei/remove-lock.php)
	if [ "$unlock" = "ok" ] ; then
		status_ok
	else
		status_fail
		error "${unlock}"
	fi
}	

recreate_db()
{
	newline
	status_start "recreating the «$1-${_arch}» database, please wait ..."
	recreate_db=$(curl --silent --data "r=$1&a=${_arch}&u=${_up}" http://chakra-project.org/packages/recreate-database.php)
	if [ "$recreate_db" = "ok" ] ; then
		status_done
	else
		status_fail
		error "${recreate_db}"
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


move_and_recreate_db()
{
	lock_repo "${_cur}+${final_dest}"

	newline
	for pkg in $move_list ; do
		status_start "moving $pkg to «${final_dest}»"
		unset moval
		moval=$(curl --silent --data "rs=${_cur}&rt=${final_dest}&a=${_arch}&u=${_up}&n=$(echo ${pkg} | sed 's/+/%2B/g')" http://chakra-project.org/packages/move-pkg.php)
		if [ "$moval" = "ok" ] ; then
			status_done
			mv -f ${_sync_folder}/$pkg _temp &>/dev/null
		else
			status_fail
			error "${moval}"
		fi
	done

	repo_clean "${final_dest}"

	unlock_repo "${_cur}+${final_dest}"

	newline
	msg "running repo-clean on ${_sync_folder}"
	repo-clean -q -m c -s ${_sync_folder} &>/dev/null
}

move_and_recreate_db_smart()
{
	# Get the list of repos for locking
	repos_to_lock="${_cur}"
	unset pkgs
	for pkgs in $move_list ; do
		chr="$(echo $pkgs | cut -d '|' -f2)"
		addrepo="true"
		for repo_exist in ${repos_to_lock} ; do
			if [ "$chr" = "${repo_exist}" ] ; then
				addrepo="false"
			fi
		done
		if [ "$addrepo" = "true" ] ; then
			repos_to_lock="${repos_to_lock} ${chr}"
		fi
	done

	lock_repo "${repos_to_lock}"

	newline
	unset pkgs
	for pkgs in $move_list ; do
		status_start "moving $(echo $pkgs | cut -d '|' -f1) to «$(echo $pkgs | cut -d '|' -f2)»"
		unset moval

		moval=$(curl --silent --data-ascii "rs=${_cur}&rt=$(echo $pkgs | cut -d '|' -f2)&a=${_arch}&u=${_up}&n=$(echo $pkgs | sed 's/+/%2B/g' | cut -d '|' -f1)" http://chakra-project.org/packages/move-pkg.php)
		if [ "$moval" = "ok" ] ; then
			status_done
			mv -f ${_sync_folder}/$pkg _temp &>/dev/null
		else
			status_fail
			error "${moval}"
		fi
	done

	unset dtbs
	for dtbs in ${repos_to_lock} ; do
		if [ "${dtbs}" != "${_cur}" ] ; then 
			repo_clean "${dtbs}"
		fi
	done
	
	unlock_repo "${repos_to_lock}"

	newline
	msg "running repo-clean on ${_sync_folder}"
	repo-clean -q -m c -s ${_sync_folder} &>/dev/null
}

check_available_repos()
{
	msg "searching for «${1}»"
	unset checktr
	checktr=$(curl --silent --data "u=${_up}" http://chakra-project.org/akabei/available-repos.php)
	if [ "$(echo "$checktr" | cut -d+ -f1)" = 'ok' ] ; then
		for _repo_check in ${checktr} ; do
		if [ "${_repo_check}" = "${1}" ] ; then 
			repo_exist="yes"
		fi
		done
		if [ "${repo_exist}" != "yes" ] ; then
			newline
			error "the repo «${1}» it is unknown"
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

move_packages()
{
	if [ "${_dest}" != "" ] ; then
		check_available_repos "${_dest}"
		if [ "${_dest}" = "${_cur}" ] ; then 
			newline
			error "you cannot move packages from «${_dest}» to «${_cur}» !"
			newline
			exit 1
		fi
		final_dest=${_dest}
		newline
		msg "searching for «${_args}» in «${_cur}-${_arch}»"
		export RSYNC_PASSWORD=$(echo ${_rsync_pass})
		repo_files=$(rsync -avh --list-only ${_rsync_user}@${_rsync_server}::dev/${_cur}/${_arch}/*.pkg.* | cut -d ":" -f 3 | cut -d " " -f 2)

		# Parses more than an arg separated by comma
		parse_args=$(echo "${_args}" | sed 's/,/\n/g')
		for each_arg in $parse_args ; do
		partial_list=$(echo "$repo_files" | grep ${each_arg} | grep '.pkg.tar..*z$')
			parse_list=$(echo ${partial_list} ${parse_list})
		done	
		move_list=''
		for each_file in $parse_list ; do
			file_exist='false'
			for each_add in $move_list ; do
				if [ "${each_file}" = "${each_add}" ] ; then
					file_exist='true'
				fi
			done
			if [ "${file_exist}" = "false" ] ; then
				move_list=$(echo "${move_list} ${each_file}")
			fi
		done

	else
		newline
		msg "searching for «${_args}» in «${_cur}-${_arch}»"
		unset target_data
		move_list=$(curl --silent --data "r=${_cur}&a=${_arch}&u=${_up}&n=${_args}" http://chakra-project.org/packages/query-pkgs.php)
		if [ "$(echo "$move_list" | cut -d: -f1)" = "error" ] ; then
			newline
			error "${move_list}"
			newline
			exit 1
		fi
		
	fi

	unset how_mani
	for count in $move_list ; do
		((how_mani++))
	done

	if [ "$move_list" != "" ] ; then
		newline
		warning "(${how_mani}) packages match your search criteria:"
		newline

		no_data=0
		for pkgs in $move_list ; do
			if [ "$(echo $pkgs | cut -d '|' -f1)" != "$(echo $pkgs | cut -d '|' -f2)" ] ; then
				printf "$(echo $pkgs | cut -d '|' -f1)\033[1;34m [$(echo $pkgs | cut -d '|' -f2)]\033[1;0m\n"
			else
				echo "$(echo $pkgs | cut -d '|' -f1)"	
				((no_data++))
			fi 
		done

		if [[ $how_mani > 1 ]] ; then
			if [ "${final_dest}" == "" ] ; then
				if [[ $no_data != 0 ]] ; then
					newline
					error "some packages does not provide target info"
					error "you should expecify a target repo, exiting..."
					newline
					exit 1
				else
					newline
					msg "each package will be moved to the repo provided by the package itself"
				fi
				
			else
				newline
				msg "the packages will be moved to «${final_dest}»"
			fi
		else
			if [ "$(echo $move_list | cut -d '|' -f1)" != "$(echo $move_list | cut -d '|' -f2)" ] ; then
				if [ "${final_dest}" == "$(echo $move_list | cut -d '|' -f2)" ] ; then
					newline
					msg "the package will be moved to «${final_dest}»"
				fi
				if [ "${final_dest}" != "" ] ; then
					newline
					msg "the package will be moved to «$final_dest» but belongs to «$(echo "$target_data" | cut -d '+' -f2)»"
				fi
			else
				if [ "${final_dest}" == "" ] ; then
					newline
					error "this package does not provide target info"
					error "you should expecify a target repo, exiting..."
					newline
					exit 1
				else
					newline
					msg "the package will be moved to «$final_dest»"
				fi
			fi

		fi
	  
		newline
		question "Do you really want to move the package(s)? (y/n) "
		while true ; do
			read yn
			case ${yn} in
			[yY]* )
				if [ "${final_dest}" != "" ] ; then
					time move_and_recreate_db
					
				else
					time move_and_recreate_db_smart
	
				fi
				newline 
				title "All done"
				break
			;;
			[nN]* )
				newline 
				title "no packages are moved" 
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
    error " !! You need to specify a pattern to move and optionally a target repo"
    eroor "    and a source repo, both target and source args are optional."
    error "    single names like «attica» or simple regexp like ^kde are allowed"
    error "    you can also provide a comma separated list like kde,calligra."
    error "    syntax: move.sh <pattern> <target repo> <source repo>"
    newline
    exit 1
fi

load_configs

check_rsync
check_accounts

if [ "${_srce_repo}" != "" ] ; then
     check_available_repos "$_srce_repo"
    _cur=$_srce_repo
fi

# NOTE: Don't move this variable, need to be here.
_up=$(echo -n "$(date -u +%W)${_rsync_user}$(echo -n "${_rsync_pass}"|sha1sum|awk '{print $1}')"|sha1sum|awk '{print $1}')

move_packages

newline

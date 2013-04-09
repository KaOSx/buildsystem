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
_script_name="Upload Package(s)"
_ver="1.4"
_dest_repo=$(echo $1)
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_needed_functions="config_handling helpers messages"
_build_arch="$_arch"
_sarch="x32"
[[ ${_arch} = *x*64* ]] && _sarch="x64"

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

#
# Functions
#

lock_repo()
{
	newline
	status_start "locking «${final_dest}-${_arch}»"
	locker="$(echo "${_packer}" | cut -d ' ' -f1)+$(echo "${_packer}" | cut -d ' ' -f2)"
	lock=$(curl --silent --data "r=${final_dest}&a=${_arch}&u=${_up}&n=${locker}" ${_rsync_server}/akabei/add-lock.php)
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
	status_start "unlocking «${final_dest}-${_arch}»"
	unlock=$(curl --silent --data "r=${final_dest}&a=${_arch}&u=${_up}" ${_rsync_server}/akabei/remove-lock.php)
	if [ "$unlock" = "ok" ] ; then
		status_ok
	else
		status_fail
		error "${unlock}"
	fi
}	

exit_with_error()
{
	newline
	error "failed performing the current operation, aborting..."
	unlock_repo
	exit 1
}

upload_to_target()
{
	newline
	msg "uploading to «${final_dest}»"
	export RSYNC_PASSWORD=$(echo ${_rsync_pass})
	rsync -avh --progress --delay-updates _temp/ ${_rsync_user}@${_rsync_server}::dev/${final_dest}/$_arch/ || exit_with_error
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

clean_temp_folder()
{
	newline
	msg "cleaning the _temp folder"
	pushd _temp &>/dev/null
		rm -rf *
	popd &>/dev/null
}

upload_and_recreate_db()
{
	lock_repo
	clean_temp_folder

	newline
	msg "adding packages to _temp"
	mv -f _repo/local/*.pkg.* _temp

	upload_to_target

	newline
	for pkg in $upload_list ; do
		status_start "Adding «$pkg» to «${final_dest}-${_arch}»"
		unset removal
		upload=$(curl --silent --data "r=${final_dest}&a=${_arch}&u=${_up}&n=${pkg}" http://chakra-project.org/packages/add-pkg.php)
		if [ "$upload" = "ok" ] ; then
			status_done
		else
			status_fail
			error "${upload}"
		fi
	done

	repo_clean "${final_dest}"

	unlock_repo

	newline
	if [ "${final_dest}" = "${_cur}" ] ; then
		msg "adding packages to «${_sync_folder}»"
		mv -f _temp/*.pkg.* ${_sync_folder} &>/dev/null
		msg "running repo-clean on «${_sync_folder}»"
		repo-clean -q -m c -s ${_sync_folder} &>/dev/null
	fi
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

upload_packages()
{
	# Upload the packages to a repo
     	if [ "${_dest}" != "" ] ; then
		check_available_repos
		final_dest=${_dest}

	else
		final_dest=${_cur}
	fi
	
	pkgz_to_upload=$(ls _repo/local | cut -d/ -f2)
	upload_list=$(ls _repo/local | cut -d/ -f2 | grep ".xz$")
	if [ "$pkgz_to_upload" != "" ] ; then 
		newline
		msg "uploading to target repo: «${final_dest}»"
		unset how_man
		unset sig_mani
		for count in $pkgz_to_upload ; do
			if [ "$(echo "${count}" | awk -F '.' '{print $NF}')" == "sig" ] ; then
			      ((sig_mani++))
			else
			      ((how_mani++))
			fi
		done
		newline
		warning "(${how_mani}) packages (${sig_mani}) signatures will be uploaded:"
		newline
		echo "$upload_list"
		newline
		warning "(${how_mani}) packages and (${sig_mani}) signatures will be uploaded:"
		newline
		echo "$pkgz_to_upload"
		newline
		time upload_and_recreate_db
		newline 
		title "All done"
	else
		newline 
		error "No packages found in «_repo/local», there's nothing to upload"
		newline
		exit 1
	fi

}

#
# startup
#

clear
title "${_script_name} v${_ver} - $_cur_repo-$_build_arch"

load_configs

check_rsync
check_accounts

# NOTE: Don't move this variable, need to be here.
_up=$(echo -n "$(date -u +%W)${_rsync_user}$(echo -n "${_rsync_pass}"|sha1sum|awk '{print $1}')"|sha1sum|awk '{print $1}')

upload_packages 
newline

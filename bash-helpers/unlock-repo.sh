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
_script_name="Unlock Repo"
_ver="0.2"
_dest_repo=$(echo $1)
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_needed_functions="config_handling helpers messages"
_build_arch="$_arch"

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

#
# Functions
#

unlock_repo()
{
	newline
	status_start "unlocking «${final_dest}-${_arch}»"
	unlock=$(curl --silent --data "r=${final_dest}&a=${_arch}&u=${_up}" "${_rsync_server}/akabei/remove-lock.php")
	if [ "$unlock" = "ok" ] ; then
		status_ok
	else
		status_fail
		error "${unlock}"
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

unlock()
{
     	if [ "${_dest}" != "" ] ; then
		check_available_repos
		final_dest=${_dest}

	else
		final_dest=${_cur}
	fi
	
	newline
	msg "You are about to unlock «${final_dest}-${_arch}»"
	msg "please consider asking the repo locker first!"
	newline
	question "Do you really want to continue? (y/n) "
	while true ; do
		read yn
		case $yn in
			[yY]* )
				question "lol really? (y/n) "
				while true ; do
					read yn
					case $yn in
						[yY]* )
							unlock_repo
							newline 
							title "All done"
							break
						;;
						* )
							newline
							exit
					esac
				done
				break
			;;
			[nN]* )
				newline
				exit
			;;
			q* )
				exit
			;;
			* )
				echo "Enter (y)es or (n)o"
			;;
		esac
	done
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

unlock

newline

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


_script_name="Sync Up"
_cur_repo=`pwd | awk -F '/' '{print $NF}'`
_ver="1.2"
_needed_functions="config_handling helpers messages"
_build_arch="$_arch"
_sarch="x32"
[[ ${_arch} = *x*64* ]] && _sarch="x64"

# helper functions
for subroutine in ${_needed_functions} ; do
    source _buildscripts/functions/${subroutine}
done

for cr in core platform desktop apps games ; do
	if [ "$(echo "${_cur_repo}" | cut -d- -f1)" == ${cr} ] ; then
		final_dest=$(echo "${_cur_repo}" | cut -d- -f2)
	fi
done
if [ "$final_dest" == "" ] ; then 
	final_dest=${_cur_repo}
fi

# Determine the sync folder
if [ "${final_dest}" = "testing" ] ; then
    _sync_folder="_testing-${_sarch}/"
elif [ "${final_dest}" = "unstable" ] ; then
    _sync_folder="_unstable-${_sarch}/"
else
    _sync_folder="_repo/remote/"
fi

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

sync_up()
{

    lock_repo

    export RSYNC_PASSWORD=$(echo ${_rsync_pass})

    # move new packages from $ROOT/repos/$REPO/build into thr repo dir
    newline
    msg "adding new packages"
    local pkg_names=$(ls _repo/local | sed -nr 's/(-[^-]*){3}\.pkg\..*z$//p')
    mv -v _repo/local/*.pkg.* ${_sync_folder}
    msg "removing packages from [local]"
    repo-remove _repo/local/local-${_cur_repo}.db.tar $pkg_names

    # run repo-clean on it
    newline
    msg "running repo-clean"
    repo-clean -m c -s ${_sync_folder}

    # create new pacman database
    newline
    msg "creating pacman database"
    rm -rf ${_sync_folder}*.db.tar.*

    pushd ${_sync_folder}
	repo-add ${final_dest}.db.tar.gz *.pkg.tar.*z
    popd

    # sync local -> server
    newline
    msg "sync local -> server"
    rsync -avh --progress --delay-updates --delete-after  ${_sync_folder} ${_rsync_user}@${_rsync_server}::dev/${final_dest}/$_arch/

    unlock_repo
}



title "${_script_name} v${_ver} - $_cur_repo-$_build_arch"

load_configs

check_rsync
check_accounts

# NOTE: Don't move this variable, need to be here.
_up=$(echo -n "$(date -u +%W)${_rsync_user}$(echo -n "${_rsync_pass}"|sha1sum|awk '{print $1}')"|sha1sum|awk '{print $1}')

time sync_up

title "All done"
newline

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


_script_name="repoclean remote"
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_sarch="x32"
[[ ${_arch} = *x*64* ]] && _sarch="x64"

source _buildscripts/functions/config_handling
source _buildscripts/functions/messages

# Determine the sync folder
if [[ ${_cur_repo} = *-testing ]] ; then
    _sync_folder="_testing-${_sarch}/"
elif [[ ${_cur_repo} = *-unstable ]] ; then
    _sync_folder="_unstable-${_sarch}/"
else
    _sync_folder="_repo/remote/"
fi


title "${_script_name}"

check_configs
load_configs

msg "running repo-clean"

repo-clean -m c -s ${_sync_folder}

title "All done"
newline

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
# setup
#
_script_name="build(er)"
_build_arch="$_arch"
_args=`echo $1`
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_current_repo=$(echo ${_cur_repo} | cut -d- -f1)
_available_pkglists=$(cat _buildscripts/${_current_repo}-${_arch}-pkgs.conf | grep "_" | cut -d "=" -f 1 | awk 'BEGIN {FS="_"} {print $NF}' | sed '/^$/d' | grep -v branch)
_needed_functions="config_handling messages dependency_handling"

for subroutine in ${_needed_functions} ; do
    source _buildscripts/functions/${subroutine}
done

current_repo=${_cur_repo}

#
# main
#
build_it()
{
    if [ "$_args" = "" ] ; then
        error "you need to specify a package list defined in _/buildscripts/${_current_repo}-${_build_arch}-pkgs.conf\n -> ${_available_pkglists}" && exit
    fi

    cd $_build_work

    for module in ${whattodo[*]}; do
        [[ `echo $module | cut -c1` == '#' ]] && continue
        msg "Downloading for $module."
        pushd $module &>/dev/null

        if [ -e "$_build_work/$module/PKGBUILD" ] ; then
            msg "Getting tar."
            ../makepkg -g

        else
            newline
            echo "No PKGBUILD found, exiting... :("
            newline
            exit 1
        fi

        popd &>/dev/null
    done
}

#
# startup
#
title "${_script_name}"

check_configs
load_configs

# we take the repo name + the job/stage to reconstruct the variable name
# in $repo_pkgs.cfg and echo its contents... 
whattodo=($(eval echo "\${_build_${_current_repo}_${_args}[@]}"))

time build_it

if [ -z "$BROKEN_PKGS" ] ; then
    title2 "All done"
fi

newline

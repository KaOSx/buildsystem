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
_args=`echo $1`
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_current_repo=$(echo ${_cur_repo} | cut -d- -f1)
_available_pkglists=$(cat _buildscripts/${_current_repo}-${_arch}-pkgs.conf | grep "_build_" | cut -d "=" -f 1 | awk 'BEGIN {FS="_"} {print $NF}' | sed '/^$/d' | grep -v branch)
_args=$(echo $1)
_needed_functions="config_handling messages dependency_handling"

# load functions
for subroutine in ${_needed_functions} ; do
    source _buildscripts/functions/${subroutine}
done

current_repo="${_cur_repo}"


#
# main
#
build_it()
{
    if [ "${_args}" = "" ] ; then
        error "you need to specify a package list (as defined in _/buildscripts/${_current_repo}-${_arch}-pkgs.conf)\n\n${_available_pkglists}" && exit
    fi

    cd ${_build_work}

    for pkg in ${whattodo[*]} ; do
        [[ `echo ${pkg} | cut -c1` == '#' ]] && continue
        msg "building ${pkg}."
        pushd ${pkg} &>/dev/null
            if [ -e "${_build_work}/${pkg}/PKGBUILD" ] ; then
                ../makepkg -rs --noconfirm || BUILD_BROKEN="1"
                if [ "$BUILD_BROKEN" = "1" ] ; then
                    newline
                    newline
                    echo "ERROR BUILDING $module"
                    newline
                    newline
                    exit 1
                fi
            else
                newline
                echo "No PKGBUILD found, exiting... :("
                newline
                exit 1
            fi

            # Upload packages (enable if needed)
		cd ..
                 ./upload1.sh staging
                 sudo pacman -Syu --noconfirm
        popd &>/dev/null
    done

    newline
    newline
}


#
# startup
#

title "${_script_name}"

check_configs
load_configs

whattodo=($(eval echo "\${_build_${_current_repo}_${_args}[@]}"))

time build_it

if [ -z "$BROKEN_PKGS" ] ; then
    msg "All done"
else
    msg "All done"
    error "SOME PACKAGES WERE NOT BUILT: $BROKEN_PKGS"
fi

newline

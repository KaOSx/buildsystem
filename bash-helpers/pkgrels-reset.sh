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


_script_name="reset pkgrels"
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_current_repo=$(echo ${_cur_repo} | cut -d- -f1)
_available_pkglists=`cat _buildscripts/${_current_repo}-${_arch}-pkgs.conf | grep "_" | cut -d "=" -f 1 | awk 'BEGIN {FS="_"} {print $NF}' | sed '/^$/d' | grep -v branch`

source _buildscripts/functions/config_handling
source _buildscripts/functions/helpers
source _buildscripts/functions/messages



decrease_pkgrels()
{
    [ -n "${_args}" ] || error "you need to specify a package list (as defined in _/buildsystem/${_current_repo}-${_arch}-pkgs.conf)\n\n${_available_pkglists}"

    case "${_args}" in
        all)
            msg "Resetting all pkgrels"
            for _pkg in ${whattodo[*]} ; do
                status_start "${_pkg}"
                    pushd ${_pkg} &>/dev/null
                        _rel=$(cat PKGBUILD | grep pkgrel= | cut -d= -f2)
                        sed -i -e "s/pkgrel=${_rel}/pkgrel=1/g" PKGBUILD
                    popd &>/dev/null
                status_done
            done
        ;;

        support)
            msg "Resetting support pkgrels"
            for _pkg in ${whattodo[*]} ; do
                status_start "${_pkg}"
                    pushd ${_pkg} &>/dev/null
                        _rel=$(cat PKGBUILD | grep pkgrel= | cut -d= -f2)
                        sed -i -e "s/pkgrel=${_rel}/pkgrel=1/g" PKGBUILD
                    popd &>/dev/null
                status_done
            done
        ;;

        qt)
            msg "Resetting Qt pkgrels"
            for _pkg in ${whattodo[*]} ; do
                status_start "${_pkg}"
                    pushd ${_pkg} &>/dev/null
                        _rel=$(cat PKGBUILD | grep pkgrel= | cut -d= -f2)
                        sed -i -e "s/pkgrel=${_rel}/pkgrel=1/g" PKGBUILD
                    popd &>/dev/null
                status_done
            done
        ;;

        kde)
            msg "Resetting KDE pkgrels"
            for _pkg in ${whattodo[*]} ; do
                status_start "${_pkg}"
                    pushd ${_pkg} &>/dev/null
                        _rel=$(cat PKGBUILD | grep pkgrel= | cut -d= -f2)
                        sed -i -e "s/pkgrel=${_rel}/pkgrel=1/g" PKGBUILD
                    popd &>/dev/null
                status_done
            done
        ;;

        tools)
            msg "Resetting tool pkgrels"
            for _pkg in ${whattodo[*]} ; do
                status_start "${_pkg}"
                    pushd ${_pkg} &>/dev/null
                        _rel=$(cat PKGBUILD | grep pkgrel= | cut -d= -f2)
                        sed -i -e "s/pkgrel=${_rel}/pkgrel=1/g" PKGBUILD
                    popd &>/dev/null
                status_done
            done
        ;;
    esac
}



title "${_script_name}"

check_configs
load_configs

_args=$(echo $1)

whattodo=($(eval echo "\${_build_${_current_repo}_${_args}[@]}"))

decrease_pkgrels

title "All done"
newline

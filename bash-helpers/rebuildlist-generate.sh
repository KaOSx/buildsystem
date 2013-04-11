#! /bin/bash

#   based on
#   rebuildlist - list packages needing rebuilt for a soname bump
#
#   Copyright (c) 2009 by Allan McRae <allan@archlinux.org>
#   (some destructive) modifications: <jan.mette@berlin.de>
#
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


_script_name="gen rebuild list"
_cur_repo=`pwd | awk -F '/' '{print $NF}'`

source _buildscripts/functions/config_handling
source _buildscripts/functions/messages


title "${_script_name}"

check_configs
load_configs

if [ -z "$1" ]; then
    error "Usage: $0 <name of the package to be rebuilt>"
    newline
    exit
fi

_pkg="$1"
_libs=$(pacman -Ql ${_pkg} | grep "\.so" | grep -v "/engines/" | cut -d " " -f 2 | awk 'BEGIN {FS="/"} {print $NF}' | cut -d "." -f 1 | uniq | tr '\n' ' ')

for _sofile in ${_libs} ; do
	grepexpr="${grepexpr} -e ${_sofile%%.so}.so"
done

if [ -e "_temp/rebuildlist-$package.txt" ]; then
    rm -rf _temp/rebuildlist-$package.txt
fi

tmpdir=$(mktemp -d)
cd $tmpdir

newline
msg "Scanning packages"
msg "This can take a lot of time"

for pkg in $(ls /var/cache/pacman/pkg/*.pkg.*) ; do
    pkg=${pkg##*\/}
    status_start "Scanning ${pkg}"
        mkdir ${tmpdir}/extract
        cp /var/cache/pacman/pkg/${pkg} ${tmpdir}/extract
        pushd ${tmpdir}/extract &>/dev/null
            tar -xf /var/cache/pacman/pkg/${pkg} 2>/dev/null
            rm ${pkg}
            found=$(readelf --dynamic $(find -type f) 2>/dev/null | grep ${grepexpr} | wc -l)
            if [ ${found} -ne 0 ]; then
                echo ${pkg%-*-*-*} >> ../rebuildlist-${_pkg}.txt
            fi
        popd &>/dev/null
        rm -rf extract
    status_done
done

status_start "saving _temp/rebuildlist-${_pkg}.txt"
    cp ${tmpdir}/rebuildlist-${_pkg}.txt _temp/
status_done

newline
title "All done, rebuild list created in _temp/"
newline

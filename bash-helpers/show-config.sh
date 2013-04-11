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
_script_name="configuration"
_build_arch="$_arch"
_cur_repo=`pwd | awk -F '/' '{print $NF}'`
_needed_functions="config_handling helpers messages"
# load functions
for subroutine in ${_needed_functions}
do
    source _buildscripts/functions/${subroutine}
done

#
# main
#
show_config()
{
	clear
	echo " "
	echo -e "$_g >$_W $_script_name$_n"
        echo " "
        echo -e "  $_W _cur_repo          :$_n $_cur_repo"
	echo " "
        echo -e "$_g   _buildscripts/user.conf: $_n"
        echo -e "$_W   ----------------------- $_n"
        echo -e "  $_W _rsync_server      :$_n $_rsync_server"
        echo -e "  $_W _rsync_dir         :$_n $_rsync_dir"
        echo -e "  $_W _rsync_user        :$_n $_rsync_user"
        echo -e "  $_W _rsync_pass        :$_n $_rsync_pass"
        echo " "
	echo -e "$_g   _buildscripts/cfg_$_cur_repo.conf: $_n"
        echo -e "$_W   ------------------------------- $_n"
        echo -e "  $_W _build_work        :$_n $_build_work"
	echo -e "  $_W _build_autoinstall :$_n $_build_autoinstall"
        echo -e "  $_W _build_autodepends :$_n $_build_autodepends"
        echo -e "  $_W _build_stop        :$_n $_build_stop"
        echo " "
	echo -e "$_g   _buildscripts/makepkg-$_cur_repo.conf: $_n"
        echo -e "$_W   ----------------------------------- $_n"
        echo -e "  $_W CARCH              :$_n $CARCH"
        echo -e "  $_W CHOST              :$_n $CHOST"
        echo " "
	echo -e "  $_W CFLAGS             :$_n $CFLAGS"
	echo -e "  $_W CXXFLAGS           :$_n $CXXFLAGS"
	echo -e "  $_W MAKEFLAGS          :$_n $MAKEFLAGS"
        echo " "
	echo -e "  $_W BUILDENV           :$_n ${BUILDENV[@]}"
	echo -e "  $_W OPTIONS            :$_n ${OPTIONS[@]}"
        echo " "
        echo -e "  $_W PKGDEST            :$_n $PKGDEST"
        echo -e "  $_W SRCDEST            :$_n $SRCDEST"
        echo " "
        echo -e "  $_W PACKAGER           :$_n $PACKAGER"
        echo " "
        echo " "
}

#
# startup
#
check_configs
load_configs

get_colors
show_config

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
_script_name="package lists"
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
show_pkglists()
{
	clear
	echo " "
	echo -e "$_g >$_W $_script_name$_n"
	cat _buildscripts/${_cur_repo}_pkgs.conf | sed 's/"/ /g'
	echo " "
}

#
# startup
#
check_configs
load_configs

get_colors
show_pkglists

#
# setup
#
curdir=`pwd`
repodir="_repo/repo"

_script_name="gen rebuild list"
_build_arch="$_arch"
_cur_repo=`pwd | awk -F '/' '{print $NF}'`
_needed_functions="config_handling messages"
# load functions
for subroutine in ${_needed_functions}
do
    source _buildscripts/functions/${subroutine}
done

#
# startup
#
title "${_script_name}"

check_configs
load_configs

if [ -z "$1" ]; then
	error "Usage: $0 <rebuild list>"
	newline
	exit
fi

list="$1"
startdir=$(pwd)
packages=`cat $startdir/_temp/rebuildlist-$list.txt | grep -v "$list"`

pushd $list
	../makepkg -si
popd

for pkg in $packages; do

	pushd $pkg

		sed -i -e 's/\<pkgrel=20\>/pkgrel=21/g' PKGBUILD
		sed -i -e 's/\<pkgrel=19\>/pkgrel=20/g' PKGBUILD
		sed -i -e 's/\<pkgrel=18\>/pkgrel=19/g' PKGBUILD
		sed -i -e 's/\<pkgrel=17\>/pkgrel=18/g' PKGBUILD
		sed -i -e 's/\<pkgrel=16\>/pkgrel=17/g' PKGBUILD
		sed -i -e 's/\<pkgrel=15\>/pkgrel=16/g' PKGBUILD
		sed -i -e 's/\<pkgrel=14\>/pkgrel=15/g' PKGBUILD
		sed -i -e 's/\<pkgrel=13\>/pkgrel=14/g' PKGBUILD
		sed -i -e 's/\<pkgrel=12\>/pkgrel=13/g' PKGBUILD
		sed -i -e 's/\<pkgrel=11\>/pkgrel=12/g' PKGBUILD
		sed -i -e 's/\<pkgrel=10\>/pkgrel=11/g' PKGBUILD
		sed -i -e 's/\<pkgrel=9\>/pkgrel=10/g' PKGBUILD
		sed -i -e 's/\<pkgrel=8\>/pkgrel=9/g' PKGBUILD
		sed -i -e 's/\<pkgrel=7\>/pkgrel=8/g' PKGBUILD
		sed -i -e 's/\<pkgrel=6\>/pkgrel=7/g' PKGBUILD
		sed -i -e 's/\<pkgrel=5\>/pkgrel=6/g' PKGBUILD
		sed -i -e 's/\<pkgrel=4\>/pkgrel=5/g' PKGBUILD
		sed -i -e 's/\<pkgrel=3\>/pkgrel=4/g' PKGBUILD
		sed -i -e 's/\<pkgrel=2\>/pkgrel=3/g' PKGBUILD
		sed -i -e 's/\<pkgrel=1\>/pkgrel=2/g' PKGBUILD

	../makepkg -si

	popd
done






















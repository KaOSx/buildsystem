#!/bin/bash
#
# Update Buildsystem Script
#


# global vars
_arg=`echo $1`
REPOS=`ls -1 $(pwd) | grep -e 86`

# formatted output functions
msg() {
    local mesg=$1; shift
    echo -e "\033[1;32m ::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

error() {
    local mesg=$1; shift
    printf "\033[1;31m ::\033[1;0m\033[1;0m ${mesg}\033[1;0m\n"
}

# main function
msg "Updating _buildscripts"
pushd _buildscripts &>/dev/null
    git pull || error "failed to sync the buildsystem with git.."
popd &>/dev/null

# disable if needed the update-buildsystem.sh script itself update for development
if [ "${_arg}" == "-d" ] ; then
    rm -rf {upgrade,e}*.sh
    cp _buildscripts/scripts/{upgrade,e}*.sh .
else
    rm -rf {up,e}*.sh
    cp _buildscripts/scripts/{up,e}*.sh .
fi
chmod +x *.sh

msg "Updating bashrc"
for _repo in $REPOS ; do
    rm -f $_repo/chroot/home/$(whoami)/.bashrc
    cp _buildscripts/skel/bashrc $_repo/chroot/home/$(whoami)/.bashrc
    echo "export _arch=$(echo $_repo | sed "s/-testing//" | sed "s/-unstable//" | cut -d- -f2)" >> $_repo/chroot/home/$(whoami)/.bashrc
    echo "cd /chakra/$(echo $_repo | sed "s/-x86_64//" | sed "s/-i686//")" >> $_repo/chroot/home/$(whoami)/.bashrc
    echo "ls" >> $_repo/chroot/home/$(whoami)/.bashrc
    echo 'echo " "' >> $_repo/chroot/home/$(whoami)/.bashrc
done
unset _repo

msg "Updating bash helpers and makepkg"
for _next_repo in $REPOS ; do
    if [[ "$_next_repo" != bundles* ]] ; then
	for _repo in $REPOS ; do
	    if [[ ${_repo} != live* ]] ; then 
		if [[ ${_repo} == desktop* ]] ; then
		    cp -f _buildscripts/scripts/makepkg $_repo/chroot/buildsys/${_repo%-*}/makepkg
		else
		    cp -f _buildscripts/scripts/makepkg $_repo/chroot/buildsys/${_repo%-*}/makepkg
		fi
		if [[ ${_repo} = core* ]] || [[ ${_repo} = main* ]] ; then
		    rm -f $_repo/chroot/buildsys/${_repo%-*}/fakeuname
		    cp _buildscripts/bash-helpers/fakeuname $_repo/chroot/buildsys/${_repo%-*}/fakeuname
		fi
		rm -f $_repo/chroot/buildsys/${_repo%-*}/{pkgrels-,clean-,repoclean-,sync-,show-,upload,remove,move,recreate,unlock,copy-any,get-any}*.sh
		cp _buildscripts/bash-helpers/{pkgrels-,clean-,repoclean-,sync-down,show-,upload,remove,move,recreate,unlock,copy-any,get-any}*.sh $_repo/chroot/buildsys/${_repo%-*}/
                rm -f $_repo/chroot/buildsys/${_repo%-*}/build.sh
                cp _buildscripts/bash-helpers/build.sh $_repo/chroot/buildsys/${_repo%-*}/build.sh
	    fi
	done
    fi
    unset _repo
done

msg "All done"
echo " "

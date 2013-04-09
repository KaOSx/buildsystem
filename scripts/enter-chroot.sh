#!/bin/bash
#
# Chakra Enter-Chroot Script
#    to handle mounting/unmounting special directories
#    and extra sanity checks
#

# version
VER="1.0"

# global vars

source _buildscripts/user.conf

_chroot=$(echo $1 | sed -e 's,/,,g')
_chroots=$(ls -1 $(pwd) | grep -e 86 | sed 's,/,,g')
_chroot_branch=$(echo ${_chroot} | sed "s/-i686//g" | sed "s/-x86_64//g")
_user=$(whoami)
_carch="x32"
[[ ${_chroot} = *x*64* ]] && _carch="x64"


# formated output functions
error() {
    printf "\033[1;31m ::\033[1;0m\033[1;0m $1\033[1;0m\n"
}

msg() {
    printf "\033[1;32m ::\033[1;0m\033[1;0m $1\033[1;0m\n"
}

if [ "$_chroot" == "" ] ; then
	echo " "
	error "you should specify a repository!"
	error "available repos:\n\n${_chroots}"
	exit
fi


# don't forget which chroot you are entering.. ;)
clear
msg "Chakra Packager's Enter Chroot Script v$VER"
msg "Entering chroot..."
sleep 1
msg "Repository: ${_chroot} (${_chroot_branch})" # Example: apps-i686 (apps)
sleep 1
msg "User: ${_user}"
sleep 2

if [ -d ${_chroot} ] ; then
    sed -i -e s,#PKGDEST,PKGDEST,g _buildscripts/${_chroot}-makepkg.conf
    sed -i -e s,#SRCDEST,SRCDEST,g _buildscripts/${_chroot}-makepkg.conf
    sed -i -e s,#PACKAGER,PACKAGER,g _buildscripts/${_chroot}-makepkg.conf
    sed -i -e s,SRCDEST.*,SRCDEST=\"/chakra/${_chroot_branch}/_sources\",g _buildscripts/${_chroot}-makepkg.conf
    sed -i -e s,PACKAGER.*,PACKAGER="\"$_packer\"",g _buildscripts/${_chroot}-makepkg.conf
    sed -i -e s#_build_work.*#_build_work=\"/chakra/${_chroot_branch}/\"#g _buildscripts/${_chroot}-cfg.conf
    sed -i -e s,"_chroot_branch=".*,"_chroot_branch=\"${_chroot_branch}\"",g ${_chroot}/chroot/home/${_user}/.bashrc
    sed -i -e s,"cd /chakra/".*,"cd /chakra/${_chroot_branch}/",g ${_chroot}/chroot/home/${_user}/.bashrc
    if [[ "${_chroot}" = bundles* ]] ; then
	sed -i -e s,PKGDEST.*,PKGDEST=\"/chakra/${_chroot_branch}/_temp\",g _buildscripts/${_chroot}-makepkg.conf
    else
	sed -i -e s,PKGDEST.*,PKGDEST=\"/chakra/${_chroot_branch}/_repo/local\",g _buildscripts/${_chroot}-makepkg.conf
    fi

    source _buildscripts/${_chroot}-cfg.conf

    echo " "
    echo " "

    if [ "$(mount | grep ${_chroot}/chroot/dev)" == "" ] ; then
        sudo mount -v /dev ${_chroot}/chroot/dev --bind &>/dev/null
    else
        sudo umount -v ${_chroot}/chroot/dev &>/dev/null
        sudo mount -v /dev ${_chroot}/chroot/dev --bind &>/dev/null
    fi

    if [ "$(mount | grep ${_chroot}/chroot/sys)" == "" ] ; then
        sudo mount -v /sys ${_chroot}/chroot/sys --bind &>/dev/null
    else
        sudo umount -v ${_chroot}/chroot/sys &> /dev/null
        sudo mount -v /sys ${_chroot}/chroot/sys --bind &>/dev/null
    fi

    if [ "$(mount | grep ${_chroot}/chroot/proc)" == "" ] ; then
        sudo mount -v /proc ${_chroot}/chroot/proc --bind &>/dev/null
    else
        sudo umount -v ${_chroot}/chroot/proc &> /dev/null
        sudo mount -v /proc ${_chroot}/chroot/proc --bind &>/dev/null
    fi

    if [ "$(mount | grep ${_chroot}/chroot/var/cache/pacman/pkg)" == "" ] ; then
        sudo mount -v _cache-${_carch} ${_chroot}/chroot/var/cache/pacman/pkg --bind &>/dev/null
    else
        sudo umount -v ${_chroot}/chroot/var/cache/pacman/pkg &> /dev/null
        sudo mount -v _cache-${_carch} ${_chroot}/chroot/var/cache/pacman/pkg --bind &>/dev/null
    fi

    if [ "$(mount | grep ${_chroot}/chroot/dev/pts)" == "" ] ; then
        sudo mount -v /dev/pts ${_chroot}/chroot/dev/pts --bind &>/dev/null
    else
        sudo umount -v ${_chroot}/chroot/dev/pts &>/dev/null
        sudo mount -v /dev/pts ${_chroot}/chroot/dev/pts --bind &>/dev/null
    fi

    if [ "$(mount | grep ${_chroot}/chroot/dev/shm)" == "" ] ; then
        sudo mount -v /dev/shm ${_chroot}/chroot/dev/shm --bind &>/dev/null
    else
        sudo umount -v ${_chroot}/chroot/dev/shm &>/dev/null
        sudo mount -v /dev/shm ${_chroot}/chroot/dev/shm --bind &>/dev/null
    fi


    sudo mount _buildscripts/ ${_chroot}/chroot/chakra/${_chroot_branch}/_buildscripts --bind &>/dev/null
    sudo mount _sources/ ${_chroot}/chroot/chakra/${_chroot_branch}/_sources --bind &>/dev/null
    sudo mount _testing-${_carch}/ ${_chroot}/chroot/chakra/${_chroot_branch}/_testing-${_carch} --bind &>/dev/null
    sudo mount _unstable-${_carch}/ ${_chroot}/chroot/chakra/${_chroot_branch}/_unstable-${_carch} --bind &>/dev/null
    sudo cp -f /etc/mtab ${_chroot}/chroot/etc/mtab &>/dev/null
    sudo cp -f /etc/resolv.conf ${_chroot}/chroot/etc/resolv.conf &>/dev/null

    # actual chroot call (blocking, until exit())
    sudo chroot ${_chroot}/chroot su - ${_user}

    #/// exit() called, unmount all

    for __chroot in ${_chroots}; do
        __chroot_name=`echo ${__chroot} | sed "s/-i686//g" | sed "s/-x86_64//g"`
        sudo umount -v ${__chroot}/chroot/{dev/shm,dev/pts,dev,sys,proc,var/cache/pacman/pkg} &>/dev/null
        sudo umount -v ${__chroot}/chroot/chakra/${__chroot_name}/{_buildscripts,_sources} &>/dev/null
	sudo umount -v ${__chroot}/chroot/chakra/${__chroot_name}/_testing-${_carch} &>/dev/null
	sudo umount -v ${__chroot}/chroot/chakra/${__chroot_name}/_unstable-${_carch} &>/dev/null
    done

else
    echo " "
    error "the repository ${_chroot} does not exist!"
    error "available repos:\n\n${_chroots}"
    echo " "
    exit 1
fi

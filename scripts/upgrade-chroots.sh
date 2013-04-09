#!/bin/bash
#
# Chakra Upgrade Chroots Script
#   loops through each installed chroot, and calls 
#   pacman -Syu --cachedir _cache-${_arch}
#


# global vars
CHROOTS=`ls -1 $(pwd) | grep -e 86`

# formatted output functions
msg() {
    local mesg=$1; shift
    echo -e "\033[1;32m ::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

# for each chroot, call pacman -Syu
for _chroot in $CHROOTS ; do
    msg "upgrading chroot: $_chroot"
    echo " "
    if [[ $_chroot == *i686 ]] ; then
        sudo pacman -r $_chroot/chroot --config $_chroot/chroot/etc/pacman.conf --cachedir _cache-x32 -Syu
    else
        sudo pacman -r $_chroot/chroot --config $_chroot/chroot/etc/pacman.conf --cachedir _cache-x64 -Syu
    fi
    echo " "
    msg "config /etc/locale.conf"
    echo "LANG=C" > $_chroot/chroot/etc/locale.conf
    echo "LC_MESSAGES=C" >> $_chroot/chroot/etc/locale.conf
done

echo " :: all done ::"
echo " "

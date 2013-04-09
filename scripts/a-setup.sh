#!/bin/bash
#
# a-Setup.sh, an automatic buildsystem setup for Chakra GNU/Linux
#
# Copyright (c) 2010-2013 - Originally developed by Jan Mette
#
#                       Contributors, alphabetically sorted:
#
#                       Adrián Chaves Fernández <gallaecio[at]chakra-project[dot]org
#                       Drake Justice <djustice[at]chakra-project[dot]org
#                       Manuel Tortosa <manutortosa[at]chakra-project[dot]org
#                       Phil Miller <philm[at]chakra-project[dot]org
#
#
# GPL

# version
VER="0.7.9"

# local root name (safe to change)
BASENAME="buildroot"

# dir vars
CURDIR="${PWD}"
BASEPATH="${CURDIR}/${BASENAME}"

# argument vars
REPO="${1}"
BRANCH="${2}"
IARCH="${3}"
COMMITMODE="${4}"

# user vars
USERID="$(getent passwd "${USER}" | cut -d: -f3)"

# Pkgs to install
if [[ "$BRANCH" == "testing" ]]; then
    INSTALLPKGS=('device-mapper' 'filesystem' 'lvm2' 'pcmciautils' 'attr' 'bash'
                 'binutils' 'bzip2' 'chakra-signatures' 'coreutils' 'cryptsetup' 'dcron'
                 'device-mapper' 'dhcpcd' 'diffutils' 'e2fsprogs' 'file' 'filesystem'
                 'findutils' 'gawk' 'gcc-libs' 'gen-init-cpio' 'gettext' 'glibc' 'grep'
                 'gzip' 'iputils' 'jfsutils' 'less' 'libpipeline' 'licenses'
                 'linux' 'logrotate' 'lvm2' 'mailx' 'man-pages' 'mdadm' 'nano' 'net-tools'
                 'pacman' 'pacman-mirrorlist' 'pciutils' 'pcmciautils' 'perl'
		 'ppp' 'procps-ng'
                 'psmisc' 'reiserfsprogs' 'rp-pppoe' 'sed' 'shadow' 'sysfsutils' 'syslog-ng'
                 'systemd' 'tar' 'tcp_wrappers' 'texinfo' 'usbutils' 'util-linux' 'vi' 'wget'
                 'which' 'wpa_supplicant' 'xfsprogs' 'base-devel' 'cmake' 'openssh' 'git' 'sudo'
                 'boost' 'vim' 'rsync' 'repo-clean' 'squashfs-tools' 'curl' 'libusb-compat'
                 'gnupg' 'cdrkit' 'bash-completion')
else
    INSTALLPKGS=('base' 'base-devel' 'cmake' 'openssh' 'git' 'sudo' 'boost' 'vim'
                 'rsync' 'repo-clean' 'squashfs-tools' 'curl' 'libusb-compat'
                 'gnupg' 'cdrkit' 'bash-completion')
fi

if [ "${REPO}" == "chakra-live" ] ; then
    INSTALLPKGS+=('syslinux' 'nbd' 'mkinitcpio-nfs-utils')
fi

# Remote paths
PKGSOURCE="http://chakra-project.org/repo"
BUILDSYS_BASE="git://gitorious.org/chakra-packages"
GIT_BUILDSYS="${BUILDSYS_BASE}/buildsystem.git"
PKGS_BASE="git@gitorious.org:chakra-packages"
PKGS_BASE_N="git://gitorious.org/chakra-packages"
CL_BASE="git@gitorious.org:chakra"
CL_BASE_N="git://gitorious.org/chakra"

# setup local root dir
PM_CONF="pacman.conf"
mkdir -p "${BASEPATH}"
rm -rf "${BASEPATH}/${PM_CONF}"

#
# formatted output functions
#
title() {
    local mesg="${1}"; shift
    echo " "
    printf "\033[1;33m>>>\033[1;0m\033[1;1m ${mesg}\033[1;0m\n"
    echo " "
}

msg() {
    local mesg="${1}"; shift
    echo -e "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

question() {
    local mesg="${1}"; shift
    echo -e -n "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

notice() {
    local mesg="${1}"; shift
    echo -e -n ":: ${mesg}\n"
}

warning() {
    local mesg="${1}"; shift
    printf "\033[1;33m::\033[1;0m\033[1;1m ${mesg}\033[1;0m\n"
}

error() {
    local mesg="${1}"; shift
    printf "\033[1;31m::\033[1;0m\033[1;0m ${mesg}\033[1;0m\n"
}

newline() {
    echo
}

status_start() {
    local mesg="${1}"; shift
    echo -e -n "\033[1;32m::\033[1;0m\033[1;0m ${mesg}\033[1;0m"
}

status_ok() {
    echo -e "\033[1;32m OK \033[1;0m"
}

status_done() {
    echo -e "\033[1;32m DONE \033[1;0m"
}

banner() {
    newline
    printf '\e[1;36m'
    echo "  .,-:::::   ::   .:   :::.      :::  .   :::::::..    :::.     "
    echo ",;;;'\`\`\`\`'  ,;;   ;;,  ;;\`;;     ;;; .;;,.;;;;\`\`;;;;   ;;\`;;    "
    echo "[[[        ,[[[,,,[[[ ,[[ '[[,   [[[[[/'   [[[,/[[['  ,[[ '[[,  "
    echo " \$\$\$       \"\$\$\$\"\"\"\$\$\$c\$\$\$cc\$\$\$c _\$\$\$\$,     $\$\$\$\$\$c   c\$\$\$cc\$\$\$c "
    echo "\`88bo,__,o, 888   \"88o888   888,\"888\"88o,  888b \"88bo,888   888,"
    echo "   YUMMMMMP\"MMM    YMMYMM   \"\"\`  MMM \"MMP\" MMMM   \"W\" YMM   \"\"\` "
    printf '\e[0m'
    newline
}

#
# check distro and needed packages
#
if [ ! -e "/usr/bin/git" ] ; then
    newline
    error "this script needs the package GIT installed, please install it before continuing."
    newline
    exit
fi

if [ -e "/etc/chakra-release" ] ; then
    CHAK_VER="$(cat /etc/chakra-release)"
    echo ":: running on Chakra linux: ${CHAK_VER}"
    unset CHAK_VER
    DISTRO="chakra"
else
    echo ":: running on a unsupported linux distro"
    echo ":: (everything could happen from here...)"
    DISTRO="unsupported"
fi

#
# check for package manager
#
if [ -e "/usr/bin/pacman.static" ] ; then
    PM_BIN="pacman.static"
    echo ":: using pacman.static"
elif [ -e "/usr/bin/pacman" ] ; then
    PM_BIN="pacman"
    echo ":: using pacman"
else
    echo ":: you need either pacman or pacman.static in /usr/bin"
    echo ":: can not proceed, stopping... "
    exit 0
fi

#
# {u,}mount chroot's {dev,sys,proc,cache} functions
#
mount_special() {
    sudo mount -v /dev "${CHROOT}/dev" --bind &>/dev/null
    sudo mount -v /sys "${CHROOT}/sys" --bind &>/dev/null
    sudo mount -v /proc "${CHROOT}/proc" --bind &>/dev/null
    sudo mount -v "${BASEPATH}/_cache-${CARCH}" "${CHROOT}/var/cache/pacman/pkg" --bind &>/dev/null
}
umount_special() {
    sudo umount -v "${CHROOT}/dev" &>/dev/null
    sudo umount -v "${CHROOT}/sys" &>/dev/null
    sudo umount -v "${CHROOT}/proc" &>/dev/null
    sudo umount -v "${CHROOT}/var/cache/pacman/pkg" &>/dev/null
}

#
# check the repo doing a query to the server, allow creatibg chroots for unknown repos
#
check_repos() {
    msg "checking repos"
    unset CHECKTR
    CHECKTR="$(curl --silent http://chakra-project.org/packages/check-repos.php)"
    if [ "$(echo "${CHECKTR}" | cut -d+ -f1)" = 'ok' ] ; then
	if [ -z "${REPO}" ] ; then 
	    newline
	    error "you need to specify a repository:"
	    error "$(echo "${CHECKTR}" | sed 's/ok+/available repos:/g' | sed 's/ testing//g' | sed 's/ unstable//g')"
	    newline
	    exit 1
	fi
	if [ "${REPO}" == "testing" ] || [ "${REPO}" == "unstable" ] ; then
	    newline
	    error "${REPO} is a branch - usage: c-setup.sh REPO BRANCH ARCH"
	    error "$(echo "${CHECKTR}" | sed 's/ok+/available repos:/g' | sed 's/ testing//g' | sed 's/ unstable//g')"
	    newline
	    exit 1
	fi
	for _repo_check in ${CHECKTR} ; do
	    if [ "${_repo_check}" = "${REPO}" ] ; then 
		REPO_EXISTS="yes"
	    fi
	done
	if [ "${REPO_EXISTS}" != "yes" ] ; then
	    newline
	    error "the repo «${REPO}» it is unknown"
	    error "$(echo "${CHECKTR} / chakra-live" | sed 's/ok+/available repos:/g' | sed 's/ testing//g' | sed 's/ unstable//g')"
	    newline
	    exit 1
	fi
    else
	newline
	error "unable to check available repos"
	if [ -n "${CHECKTR}" ] ; then
	    error "${CHECKTR}"
	fi
	newline
	exit 1
    fi
}

#
# generate a pacman manager conf
#
create_pacmanconf() {
    newline
    msg "creating ${PM_CONF}"

    # fetch pacman.conf from git
    wget -qO "${BASEPATH}/${PM_CONF}" "http://gitorious.org/chakra-packages/buildsystem/blobs/raw/master/skel/pacman.conf"

    sed -ri "s,@arch@,${CARCH}," "${BASEPATH}/${PM_CONF}"

    if [[ "${CARCH}" == "x86_64" ]]; then
        if [[ "${REPO}" == "lib32" || "${REPO}" == "bundles" ]]; then
            sed -ri "s,#(\[lib32\]),\1," "${BASEPATH}/${PM_CONF}"
            sed -ri "s,#(.*http.*/lib32/.*),\1," "${BASEPATH}/${PM_CONF}"
        fi
    fi

    if [[ "${BRANCH}" == "testing" ]]; then
        sed -ri "s,#(\[testing\]),\1,"    "${BASEPATH}/${PM_CONF}"
        sed -ri "s,#(.*/testing/.*),\1,"  "${BASEPATH}/${PM_CONF}"
    fi
    
    if [[ "${BRANCH}" == "systemd" ]]; then
        sed -ri "s,#(\[testing\]),\1,"    "${BASEPATH}/${PM_CONF}"
        sed -ri "s,#(.*/testing/.*),\1,"  "${BASEPATH}/${PM_CONF}"
    fi

    if [[ "${BRANCH}" == "unstable" ]]; then
        sed -ri "s,#(\[unstable\]),\1," "${BASEPATH}/${PM_CONF}"
        sed -ri "s,#(.*/unstable/.*),\1,"   "${BASEPATH}/${PM_CONF}"
    fi
}

#
# chroot creation functions
#
check_chroot() {
    if [ -d "${CHROOT}" ] ; then
	newline
	error "The chroot ${BRANCH}-${ARCH} already exists. Do you want to"
	newline
	msg "(k)eep chroot ${BRANCH}-${ARCH} and update it?"
	msg "(d)elete/reinstall chroot ${BRANCH}-${ARCH}?"
	msg "(u)ninstall chroot ${BRANCH}-${ARCH}?"
	question "(q)uit this script? "
	read OPTION
	case "${OPTION}" in
	    d* )
		newline
		status_start "chroot ${BRANCH}-${ARCH}  "
		    cd "${BASEPATH}"
		    sudo -v
		    sudo rm -rf -v "${CHROOT}" &>/dev/null
		    sudo rm -rf -v "${BASEPATH}/${REPO_NAME}-${CARCH}" &>/dev/null
		    sudo -v
		status_done
		;;
	    u* )
		newline
		status_start "uninstalling ${REPO_NAME}-${CARCH}  "
		    cd "${BASEPATH}"
		    sudo -v
		    sudo rm -rf -v "${CHROOT}" &>/dev/null
		    sudo rm -rf -v "${BASEPATH}/${REPO_NAME}-${CARCH}" &>/dev/null
		    sudo -v
		status_done
		newline
		exit 1
		;;
	    k* )
		newline
		msg "going on ..."
		newline
		;;
	    q* )
		newline
		msg "bye!"
		newline
		exit 1
		;;
	esac
    fi

    if [ -d "${BASEPATH}/${REPO_NAME}-${CARCH}" ] ; then
	newline
	error "The ${REPO_NAME}-${CARCH} already exists. Do you want to"
	newline
	msg "(d)elete and reinstall ${REPO_NAME}-${CARCH}?"
	msg "(u)ninstall ${REPO_NAME}-${CARCH}?"
	question "(q)uit this script? "
	read OPTION
	case "${OPTION}" in
	    d* )
		newline
		status_start "deleting ${REPO_NAME}-${CARCH}  "
		    uninstall_chroot
		status_done
		;;
	    u* )
		newline
		status_start "uninstalling ${REPO_NAME}-${CARCH}  "
		    uninstall_chroot
		status_done
		newline
		exit 1
		;;
	    q* )
		newline
		msg "bye!"
		newline
		exit 1
		;;
	esac
    fi
}

uninstall_chroot() {
    cd "${BASEPATH}"

    # Umount stuff.
    sudo umount -v "${CHROOT}/dev" &>/dev/null
    sudo umount -v "${CHROOT}/sys" &>/dev/null
    sudo umount -v "${CHROOT}/proc" &>/dev/null
    sudo umount -v "${CHROOT}/var/cache/pacman/pkg" &>/dev/null

    # Repository directory, check for backward compatibility.
    if [ -d "${REPODIR}" ]; then
	sudo umount -v "${REPODIR}/_buildscripts" &>/dev/null
	sudo umount -v "${REPODIR}/_sources" &>/dev/null
	sudo umount -v "${REPODIR}/_testing-${ARCH}" &>/dev/null
	sudo umount -v "${REPODIR}/_unstable-${ARCH}" &>/dev/null
    fi

    sudo rm -rf -v "${BASEPATH}/_buildscripts/${REPO_NAME}-${CARCH}"-*.conf &>/dev/null
    sudo rm -rf -v "${BASEPATH}/_buildscripts/conf/${REPO_NAME}-${CARCH}"-*.conf &>/dev/null
    sudo rm -rf -v "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}"-*.conf &>/dev/null
    sudo rm -rf -v "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}"-makepkg*.conf.* &>/dev/null

    sudo -v
    sudo rm -rf -v "${BASEPATH}/${REPO_NAME}-${CARCH}/pkgbuilds" &>/dev/null
    sudo rm -rf -v "${BASEPATH}/${REPO_NAME}-${CARCH}/packages" &>/dev/null
    sudo rm -rf -v "${BASEPATH}/${REPO_NAME}-${CARCH}/chakra-live" &>/dev/null

    # Repository directory, check for backward compatibility.
    if [ -d "${REPODIR}" ]; then
	sudo rm -rf -v "${REPODIR}" &>/dev/null
    fi

    sudo rm -rf -v "${BASEPATH}/${REPO_NAME}-${CARCH}" &>/dev/null
    sudo -v

}

pre_install_packages() {
    newline
    title "Creating chroot: ${REPO_NAME}-${CARCH}"
    newline
    status_start "creating special dirs"
	mkdir -p "${CHROOT}"/{dev,sys,proc,var/cache/pacman/pkg}
    status_done
    status_start "mounting special dirs"
	mount_special
    status_done
    status_start "creating pacman dirs"
	mkdir -p "${CHROOT}/var/lib/pacman" &>/dev/null
    status_done
}

install_packages() {
    if [ "${_creationLoop}" == "1" ] ; then
	unset _creationLoop 
	warning "Seems some went wrong. Check the pacman install log!"
	newline
	if [ "$_updateRet" == "1" ] ; then
	    msg "(r)etry package update?"
	    msg "(s)kip package update at your own risk?"
	else
	    msg "(r)etry package installation?"
	    msg "(s)kip package installation at your own risk?"
	fi
	question "(q)uit this script? "
	read OPTION
	case "${OPTION}" in
	    r* )
		newline 
		if [ "${_updateRet}" == "1" ] ; then
		    msg "retrying package update" 
		else
		    msg "retrying package installation" 
		fi
		sleep 4 
		install_packages 
		;;
            s* )
		newline 
		if [ "${_updateRet}" == "1" ] ; then
		    msg "skipping package update" 
		else
		    msg "skipping package installation" 
		fi
		return 0 
		;;
            q* )
		umount_special
		rm -f "${BASEPATH}/${PM_CONF}"
		newline 
		msg "bye!" 
		newline
		exit 1
		;;	
	esac
    fi
    sudo -v
    newline

    # Theorically if the user exists the chroot as been created
    if [ "${_installDone}" != "1" ] ; then
	if [ -d "${CHROOT}/home/${USER}" ] ; then
	    msg "updating chroot ${BRANCH}-${ARCH}"
	    unset _installDone
	    unset _updateRet
	    unset _creationLoop
	    sudo LC_ALL=C "${PM_BIN}" --noconfirm --needed --config "${BASEPATH}/${PM_CONF}" -r "${CHROOT}" --cachedir "${BASEPATH}/_cache-${ARCH}" -Syyu || _updateRet="1"
	    if [ "${_updateRet}" == "1" ] ; then
		error "!! failed to update the chroot (not good)..."
		_creationLoop="1"
		install_packages
	    else
		_installDone="1"
	    fi
	else
	    msg "installing chroot ${BRANCH}-${ARCH}"
	    unset _installDone
	    unset _installRet
	    unset _creationLoop
	    sudo LC_ALL=C "${PM_BIN}" --noconfirm --needed --config "${BASEPATH}/${PM_CONF}" -r "${CHROOT}" --cachedir "${BASEPATH}/_cache-${ARCH}" -Syy "${INSTALLPKGS[@]}" || _installRet="1"
	    if [ "${_installRet}" == "1" ] ; then
		error "!! failed to install the needed packages..."
		_creationLoop="1"
		install_packages
	    else
		_installDone="1"
	    fi
	fi
    fi
}

create_chroot() {
    sudo -v
    newline

    status_start "configuring system"
        mkdir -p "${CHROOT}/etc" &>/dev/null
        sudo cp /etc/resolv.conf "${CHROOT}/etc" &>/dev/null
        if [[ ! -f "${CHROOT}/etc/${PM_CONF}.bak" ]]; then
            sudo mv "${CHROOT}/etc/${PM_CONF}"{,.bak}
            sudo cp "${BASEPATH}/${PM_CONF}" "${CHROOT}/etc" &>/dev/null
        fi
        mkdir -p "${CHROOT}/etc/pacman.d" &>/dev/null
        sudo wget -q -O ${CHROOT}/etc/pacman.d/mirrorlist http://gitorious.org/chakra-packages/core/blobs/raw/testing/pacman-mirrorlist/mirrorlist
        sudo sed -i "s/#Server/Server/g" ${CHROOT}/etc/pacman.d/mirrorlist
        sudo sed -i -e "s/@carch@/${CARCH}/g" ${CHROOT}/etc/pacman.d/mirrorlist
    status_done

    status_start "setting up locale.conf"
	sudo touch "${CHROOT}/etc/locale.conf"
	sudo chmod 777 "${CHROOT}/etc/locale.conf"
	sudo echo "LANG=C" >> "${CHROOT}/etc/locale.conf"
	sudo echo "LC_MESSAGES=C" >> "${CHROOT}/etc/locale.conf"
    status_done

    # search for a user already existing or create it
    newline
    if [ "$(grep "^${USER}:" "${CHROOT}/etc/passwd" | cut -d ":" -f1)" != "${USER}" ] ; then
	title "User setup"

	sudo chroot "${CHROOT}" groupadd -f bundle &>/dev/null

	status_start "adding user: ${USER}"
	    sudo chroot "${CHROOT}" useradd -g users -u "${USERID}" -G audio,video,optical,storage,log,bundle -m "${USER}" &>/dev/null
	status_done

	warning "you will be asked to enter a password for the chroot's user account"

	sudo -v
	newline

	sudo chroot "${CHROOT}" passwd "${USER}"

	sudo -v
	newline

	status_start "setting up /etc/sudoers"
	    sudo chmod 777 "${CHROOT}/etc/sudoers"
	    sudo echo >> "${CHROOT}/etc/sudoers"
	    sudo echo "${USER}     ALL=(ALL) NOPASSWD: ALL" >> "${CHROOT}/etc/sudoers"
	    sudo chmod 0440 "${CHROOT}/etc/sudoers"
	status_done
    else
	msg "found user: ${USER}"
    fi

    status_start "setting up device permissions"
        sudo chroot "${CHROOT}" chmod 777 /dev/console &>/dev/null
        sudo chroot "${CHROOT}" chmod 777 /dev/null &>/dev/null
        sudo chroot "${CHROOT}" chmod 777 /dev/zero &>/dev/null
    status_done

    status_start "unmounting special dirs"
        umount_special
    status_done
}

#
# buildscript functions
#
create_buildscripts() {
    newline
    title "Installing buildscripts"

    status_start "creating needed directories"
        sudo chroot "${CHROOT}" su "${USER}" -c "mkdir -p /${CHAKRAFOLDER}/${REPO_NAME}" &>/dev/null
        sudo mkdir -p "${CHAKRADIR}"
        sudo chown "${USER}:users" "${CHAKRADIR}"
        sudo chown "${USER}:users" "${REPODIR}"
    status_done

    if [ -d "${BASEPATH}/_buildscripts" ] ; then
        notice "buildscripts already installed"
    else
        status_start "fetching buildscripts from GIT"
            newline
            git clone "${GIT_BUILDSYS}" "${BASEPATH}/_buildscripts" || _gitCloneRet="1"
            if [ "${_gitCloneRet}" == "1" ] ; then
                error "failed to clone the git repo (gitorious is down?), (d)elete and try again."
                exit 1
            fi
        status_done
    fi

    if [ -d "${BASEPATH}/_sources" ] ; then
        notice "sources dir exists already"
    else
        status_start "creating sources dir"
            mkdir -p "${BASEPATH}/_sources" &>/dev/null
        status_done
    fi

    if [ "${BRANCH}" = "testing" ] ; then
	if [ -d "${BASEPATH}/_testing-${ARCH}" ] ; then
	    notice "testing-${ARCH} sync dir exists already"
	else
	    status_start "creating testing-${ARCH} sync dir"
		mkdir -p "${BASEPATH}/_testing-${ARCH}" &>/dev/null
	    status_done
        fi
    fi

    if [ "${BRANCH}" = "unstable" ] ; then
	if [ -d "${BASEPATH}/_unstable-${ARCH}" ] ; then
	    notice "unstable-${ARCH} sync dir exists already"
	else
	    status_start "creating unstable-${ARCH} sync dir"
		mkdir -p "${BASEPATH}/_unstable-${ARCH}" &>/dev/null
	    status_done
        fi
    fi

    msg "fetching ${REPO} from GIT"
    newline
    cd "${REPODIR}" &>/dev/null

    if [ "${BRANCH}" = "master" ] ; then
	unset _gitCloneRet
	git clone "${GIT_REPO}" "${REPODIR}" || _gitCloneRet="1"
	if [ "${_gitCloneRet}" == "1" ] ; then
	    error "failed to clone the git repo (gitorious is down?), (d)elete and try again."
	    umount_special
	    exit 1
	fi
    else
	unset _gitCloneRet
	git clone -b "${BRANCH}" "${GIT_REPO}" "${REPODIR}" || _gitCloneRet="1"
	if [ "${_gitCloneRet}" == "1" ] ; then
	    error "failed to clone the git repo (gitorious is down?), (d)elete and try again."
	    umount_special
	    exit 1
	fi
    fi

    sudo chroot "${CHROOT}" su -c "chown -R ${USER}:users /${CHAKRAFOLDER}/${REPO_NAME}" &>/dev/null
    newline
    
    if [ "${REPO}" == "chakra-live" ] ; then
	status_start "installing chakra-live"
	    sudo chroot "${CHROOT}" su -c "cd /${CHAKRAFOLDER}/${REPO_NAME}/chakra-iso && make install" &> /dev/null
	status_done
    fi
}

preconfigure_buildscripts() {
    if [ "${REPO_NAME}" != "chakra-live" ] ; then
	newline
	title "Preconfiguring buildscripts"

	status_start "creating directories"
            mkdir -p "${REPODIR}"/{_buildscripts,_sources,_temp,_repo/{remote,local}} &>/dev/null
            # create empty tar, makepkg complains if there is no db
            tar cf "${REPODIR}/_repo/local/local-${REPO_NAME}.db.tar" --files-from /dev/null
            ln -s "local-${REPO_NAME}.db.tar" "${REPODIR}/_repo/local/local-${REPO_NAME}.db"


            # enable local repo
            sudo sed -ri "s,#(\[local-${REPO_NAME}\]),\1,"   "${CHROOT}/etc/pacman.conf"
            sudo sed -ri "s,#(.*/${REPO_NAME}/.*),\1," "${CHROOT}/etc/pacman.conf"

	    if [ "${REPO}" = "bundles" ] ; then
		mkdir -p "${REPODIR}/_pkgz" &>/dev/null
	    fi
	    if [ "${BRANCH}" = "testing" ] ; then
		mkdir -p "${REPODIR}/_testing-${ARCH}" &>/dev/null
	    fi
	    if [ "${BRANCH}" = "unstable" ] ; then
		mkdir -p "${REPODIR}/_unstable-${ARCH}" &>/dev/null
	    fi
	status_done
   
	status_start "installing makepkg"
	    if [[ "${REPO_NAME}" == desktop* ]] ; then
		cp -f "${BASEPATH}/_buildscripts/scripts/makepkg-chakra" "${REPODIR}/makepkg" &>/dev/null
	    else
		cp -f "${BASEPATH}/_buildscripts/scripts/makepkg" "${REPODIR}/makepkg" &>/dev/null
	    fi
	status_done
    
	status_start "installing .gitignore"
	    cp -f "${BASEPATH}/_buildscripts/.gitignore" "${REPODIR}/.gitignore" &>/dev/null
	status_done

	status_start "installing chroot scripts"
	    if [[ "${REPO}" != bundles ]] ; then 
		pushd "${BASEPATH}/_buildscripts/bash-helpers" &>/dev/null
		    if [[ "${REPO}" = core ]] || [[ "${REPO}" = platform ]] ; then
			cp -f "${BASEPATH}/_buildscripts/bash-helpers/fakeuname" "${REPODIR}/fakeuname"
		    fi
		    cp -f "${BASEPATH}/_buildscripts/bash-helpers"/{pkgrels-,clean-,repoclean-,sync-up,show-,upload,remove,move,recreate,unlock,copy-any,get-any}*.sh "${REPODIR}"
                    cp -f "${BASEPATH}/_buildscripts/bash-helpers/build.sh" "${REPODIR}/build.sh"
		popd &>/dev/null
	    fi
	    chmod +x "${BASEPATH}"/*.sh &>/dev/null

	 status_done
    else
	 status_start "creating directories"
	     mkdir -p "${REPODIR}"/_buildscripts &>/dev/null
	 status_done
    fi

    status_start "installing chroot configs"
	cp -f "${BASEPATH}/_buildscripts/skel/bashrc" "${CHROOT}/home/${USER}/.bashrc"
	cp -f "${BASEPATH}/_buildscripts/skel/screenrc" "${CHROOT}/home/${USER}/.screenrc"
	cp "${BASEPATH}/_buildscripts/scripts/enter-chroot.sh" "${BASEPATH}" &>/dev/null
	cp "${BASEPATH}/_buildscripts/scripts/update-buildsystem.sh" "${BASEPATH}" &>/dev/null
	cp "${BASEPATH}/_buildscripts/scripts/upgrade-chroots.sh" "${BASEPATH}" &>/dev/null
    status_done
     
}

configure_buildscripts() {
    newline
    title "Configuring buildscripts for: ${REPO_NAME}-${CARCH}"

    _REPO_NAME="$(echo "${REPO_NAME}" | cut -d- -f1)"

    status_start "creating config files"
	cp -f "${BASEPATH}/_buildscripts/skel/${BRANCH}-cfg.conf" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-cfg.conf" &>/dev/null
	cp -f "${BASEPATH}/_buildscripts/skel/${_REPO_NAME}-pkgs.conf" "${BASEPATH}/_buildscripts/conf/${_REPO_NAME}-${CARCH}-pkgs.conf" &>/dev/null
	cp -f "${BASEPATH}/_buildscripts/skel/${BRANCH}-makepkg.conf" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-makepkg.conf" &>/dev/null
    status_done

    status_start "creating user symlinks"
	pushd "${BASEPATH}/_buildscripts" &>/dev/null
	    ln -s "conf/${BRANCH}-${ARCH}-cfg.conf" "${REPO_NAME}-${CARCH}-cfg.conf" &>/dev/null
	    ln -s "conf/${_REPO_NAME}-${CARCH}-pkgs.conf" "${_REPO_NAME}-${CARCH}-pkgs.conf" &>/dev/null
	    ln -s "conf/${BRANCH}-${ARCH}-makepkg.conf" "${REPO_NAME}-${CARCH}-makepkg.conf" &>/dev/null
	    ln -s conf/user.conf user.conf &>/dev/null
	popd &>/dev/null
    status_done

    local CPU_NUM="$(grep processor /proc/cpuinfo | awk '{a++} END {print a}')"
    local CPU_NUM_MAKEFLAGS=$(( ${CPU_NUM} + 1 ));

    notice "${CPU_NUM} CPU(s) detected, setting MAKEFLAGS to -j${CPU_NUM_MAKEFLAGS}"

    status_start "setting up makepkg config"
	sed -i -e "s,#MAKEFLAGS.*,MAKEFLAGS=\"-j${CPU_NUM_MAKEFLAGS}\",g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-makepkg.conf"
	sed -i -e "s/___ARCH___/${CARCH}/g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-makepkg.conf"
	if [ "${CARCH}" = "x86_64" ] ; then
	    sed -i -e "s/___TYPE___/unknown/g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-makepkg.conf"
	    sed -i -e "s/-march=x86_64/-march=x86-64/g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-makepkg.conf"
	else
	    sed -i -e "s/___TYPE___/pc/g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-makepkg.conf"
	fi
    status_done

    status_start "setting up buildscripts config"
	sed -i -e "s/_build_autoinstall.*/_build_autoinstall=1/g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-cfg.conf"
	sed -i -e "s/_build_autodepends.*/_build_autodepends=1/g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-cfg.conf"
	sed -i -e "s/_build_configured.*/_build_configured=1/g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-cfg.conf"
	sed -i -e "s/___ARCH___/${CARCH}/g" "${BASEPATH}/_buildscripts/conf/${BRANCH}-${ARCH}-cfg.conf"
    status_done


    msg "configuring git"
    if [ ! -e "${BASEPATH}/_buildscripts/conf/user.conf" ] ; then
	cp -f "${BASEPATH}/_buildscripts/skel/user.conf" "${BASEPATH}/_buildscripts/conf" &>/dev/null
    fi

    if [ "${IARCH}" != "n" ] && [ "${COMMITMODE}" != "n" ] ; then
	if [ ! -f "${CHROOT}/home/${USER}/.gitconfig" ] ; then
	    newline
	    msg "setup your git crendentials"
	    msg "enter your full name (eg, John Smith):"
	    read _name
	    sudo chroot "${CHROOT}" su - "${USER}" -c "git config --global user.name ${_name}" &>/dev/null
	    msg "and your email (eg, jsmith@chakra-project.org):"
	    read _email
	    sudo chroot "${CHROOT}" su - "${USER}" -c "git config --global user.email ${_email}" &>/dev/null
	fi
	if [ -n "$(grep BuildDrone "${BASEPATH}/_buildscripts/conf/user.conf")" ] ; then
	    msg "enter your rsync user"
	    read -s _rsync_user
	    msg "enter your rsync password"
	    read -s _rsync_pass
	    sed -i -e "s#_rsync_user=\"#_rsync_user=\"${_rsync_user}#" "${BASEPATH}/_buildscripts/conf/user.conf"
	    sed -i -e "s#_rsync_pass=\"#_rsync_pass=\"${_rsync_pass}#" "${BASEPATH}/_buildscripts/conf/user.conf"
	    sed -i -e "s#Chakra BuildDrone <http://chakra-project.org>#${_name} <${_email}>#" "${BASEPATH}/_buildscripts/conf/user.conf"
	fi
	if [ -d "/home/${USER}/.ssh" ] ; then 
	    cp -rfa "/home/${USER}/.ssh" "${CHROOT}/home/${USER}" &>/dev/null
	fi
    fi

    status_start "finishing..."
	mkdir -p "${BASEPATH}/${REPO_NAME}-${CARCH}"
	ln -s "${CHROOT}" "${BASEPATH}/${REPO_NAME}-${CARCH}/chroot" &>/dev/null
	if [ "${REPO}" != "chakra-live" ] ; then
	    ln -s "${REPODIR}" "${BASEPATH}/${REPO_NAME}-${CARCH}/pkgbuilds" &>/dev/null
	    ln -s "${REPODIR}/_repo" "${BASEPATH}/${REPO_NAME}-${CARCH}/packages" &>/dev/null
	else
	    ln -s "${REPODIR}" "${BASEPATH}/${REPO_NAME}-${CARCH}/chakra-live" &>/dev/null
	fi
	echo "export _arch=${CARCH}" >> "${CHROOT}/home/${USER}/.bashrc"
	echo "cd /${CHAKRAFOLDER}/${REPO_NAME}" >> "${CHROOT}/home/${USER}/.bashrc"
	echo "ls" >> "${CHROOT}/home/${USER}/.bashrc"
	echo "echo" >> "${CHROOT}/home/${USER}/.bashrc"
        rm -rf "${BASEPATH}/${PM_CONF}"
    status_done
}

# initialize sudo and ssh
setup_ssh() {
    if [ -e "/usr/bin/sudo" ] ; then
	newline
	warning "initializing sudo, you may be asked for your password"
	newline
	sudo /bin/true &>/dev/null
    else
	newline
	error "please install and configure sudo"
	newline
	exit 1
    fi
    if [ "${IARCH}" != "n" ] && [ "${COMMITMODE}" != "n" ] ; then
	msg "setup ssh permissions:" ;
	ssh-add
    fi
}


# all done! :) print some information
all_done() {
    newline
    title "All done!"
    newline
    if [ "${REPO_NAME}" != "chakra-live" ] ; then
	msg "Finally open${_W} _buildscripts/${REPO_NAME}-${CARCH}-makepkg.conf"
	msg "and edit the DLAGENTS, CFLAGS, and CXXFLAGS settings to your"
	msg "liking and you are ready to build packages."
	newline
	msg "(Very) Quick Start:"
	msg "-------------------"
	msg "1 -> cd ${BASENAME}"
	msg "2 -> ./enter-chroot.sh ${REPO_NAME}-${CARCH}"
	msg "3 -> cd package"
	msg "4 -> ../makepkg"
	newline
    fi
}



#
# startup
#
clear
banner
title "Chakra Packager's and ISO creators Chroot Setup Script v${VER}"

# ensure we are not running as root
if [ ${UID} -ne 0 ]; then
    msg "running on user: ${USER}"
else
    newline
    error "do not run me on your root account, thanks."
    newline
    exit 1
fi

# check the repository name and branch but for chakra-live
if [ "${REPO}" != "chakra-live" ] ; then
    check_repos
    if [ "${BRANCH}" != "master" ] && [ "${BRANCH}" != "testing" ] && [ "${BRANCH}" != "unstable" ] ; then
	newline
	error "Incorrect branch «${BRANCH}»"
	error "possible branches: master testing unstable"
	newline
	exit 1
    fi
fi

# check the target repo branch
if [ -z "${BRANCH}" ] ; then
    newline
    error "you need to specify a branch"
    newline
    exit 1
fi

# check the architecture
if [ "${IARCH}" == "i686" ] || [ "${IARCH}" == "x32" ] ; then
    ARCH="x32"
    CARCH="i686"
elif [ "${IARCH}" == "x86_64" ] || [ "${IARCH}" == "x64" ] ; then
    ARCH="x64"
    CARCH="x86_64"
else
    CARCH=$(uname -m)
    if [ "${CARCH}" == "i686" ] ; then
	ARCH="x32"
    else
	ARCH="x64"
    fi
    newline
    if [ -n "${IARCH}" ] ; then 
	if [ "${IARCH}" == "n" ] ; then
	    error "you need to specify an architecture, defaulting to the host «${CARCH}»"
	else
	    error "incorrect architecture «${IARCH}», defaulting to the host «${CARCH}»"
	fi
    else
	error "you need to specify an architecture, defaulting to the host «${CARCH}»"
    fi
    newline
fi

# as the architechture is optional, check for commiter mode in both last args
if [ "${IARCH}" == "n" ] || [ "${COMMITMODE}" == "n" ] ; then
    if [ "${REPO}" == "chakra-live" ] ; then
	GIT_REPO="${CL_BASE_N}/chakra-live.git"
    else
        GIT_REPO="${PKGS_BASE_N}/${REPO}.git"
    fi
    warning "(n)on-commit enabled, no git write access."
else
    if [ "${REPO}" == "chakra-live" ] ; then
	GIT_REPO="${CL_BASE}/chakra-live.git"
    else
	GIT_REPO="${PKGS_BASE}/${REPO}.git"
    fi
    
fi

# real repo name constructor
if [ "${BRANCH}" = "master" ] ; then
    REPO_NAME="${REPO}"
else
    REPO_NAME="${REPO}-${BRANCH}"
fi
CHROOT="${BASEPATH}/_chroots/$BRANCH-${ARCH}"
CHAKRAFOLDER="chakra"
CHAKRADIR="${CHROOT}/${CHAKRAFOLDER}"
REPODIR="${CHAKRADIR}/${REPO_NAME}"

newline
warning "Root                 : ${BASEPATH}"
warning "Chroot Installation  : ${BASEPATH}/${REPO_NAME}-${ARCH}"
sleep 1
newline
question "Do you want to continue (y/n/q)? "

while true ; do
    read YN
    case $YN in
        [yY]* )
	    setup_ssh 
	    create_pacmanconf 
	    check_chroot 
	    pre_install_packages 
	    install_packages 
	    create_chroot 
	    create_buildscripts 
	    preconfigure_buildscripts 
	    configure_buildscripts 
	    all_done 
	    exit 
	    ;;
        [nN]* )
	    newline 
	    msg "bye!" 
	    newline 
	    exit 
	    ;;

        [qQ]* )
	    exit
	    ;;

	* )
	    echo "Enter (y)es, (n)o or (q)uit"
	    ;;
    esac
done

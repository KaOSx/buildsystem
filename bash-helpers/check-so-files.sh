#!/bin/bash
# check-sofiles.sh by philm[at]chakra-project[dot]org

export LANG=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8

if [ "$#" -ne 1 ]; then
  >&2 printf 'USAGE: %s pkgname\n' "$0"
  exit 1
fi

pkg=$1

lib=`readelf -d $(pacman -Qql $pkg) 2>/dev/null | grep NEEDED | sort | uniq | cut -d[ -f2 | cut -d] -f1`

echo "Checking in /usr/lib"
echo ">> there might be errors"
echo ">> check if those got found in /lib"

for i in $lib 
do
 pacman -Qo /usr/lib/$i
done
echo " "
echo ">> done"
echo " "
echo "Checking in /lib"
echo ">> Ignore already found libs"
echo " "

for i in $lib 
do
 pacman -Qo /lib/$i
done
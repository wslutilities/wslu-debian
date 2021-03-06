#!/bin/bash
# pre-configure.sh
# cdebian pre-configure script for wslu
# <https://github.com/wslutilities/wslu>
# Copyright (C) 2019 Patrick Wu
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script should be run with "./build.sh <version> <distribution> <codename> <changelog>"
# Available distributions:
#   - Ubuntu: ubuntu (amd64 arm64)
#   - Debian: debian (all) - buster, bullseye
#   - Kali Linux: kali (amd64)
#   - Pengwin: pengwin (all)
# Available versions:
#   - latest
#   - <version>
#   - dev

POSTFIX="${2}1"
DISTRO="${2}"

case "$2" in
  ubuntu)
    [[ "$3" == "bionic" || "$3" == "focal" || "$3" == "impish" || "$3" == "jammy" ]] || exit 1
    CODENAME="$3"
    ARCHITECTURE="amd64 arm64"
    case CODENAME in
      bionic)
        POSTFIX="$POSTFIX~18.04"
        ;;
      focal)
        POSTFIX="$POSTFIX~20.04"
        ;;
      impish)
        POSTFIX="$POSTFIX~20.10"
        ;;
    esac
    ;;
  debian)
    [[ "$3" == "buster" || "$3" == "bullseye" ]] || exit 1
    CODENAME="$3"
    ARCHITECTURE="all"
    ;;
  kali)
    [[ "$3" == "kali-rolling" || "$3" == "kali-dev" ]] || exit 1
    CODENAME="$3"
    ARCHITECTURE="amd64"
    ;;
  pengwin)
    CODENAME="bullseye"
    ARCHITECTURE="all"
    ;;
  *)
    exit 1
    ;;
esac

case $1 in
    dev)
        VERSION="$(curl -s https://raw.githubusercontent.com/wslutilities/wslu/dev/master/VERSION | sed 's/-/.d$(date +'%s')-/g')"
        tmp_version="$(echo "$VERSION" | sed 's/-.*$//g')"
        curl "https://github.com/wslutilities/wslu/archive/dev/master.tar.gz" -o "wslu-${tmp_version}.tar.gz"
        CHANGELOG="This is a dev build; Please check the dev/master branch to see the latest changes"
        ;;
    latest)
        tmp_info="$(curl -s https://api.github.com/repos/wslutilities/wslu/releases/latest)"
        tmp_version="$(echo "$tmp_info" | grep -oP '"tag_name": "v\K(.*)(?=")')"
        CHANGELOG="$(echo "$tmp_info" | grep -oP '"body": "\K(.*)(?=")')"
        CHANGELOG="$(echo -e "$CHANGELOG" | sed -e "s/\r//g" -e "s/^\s*##.*$//g" -e "/^$/d" -e "s/^-/  -/g" -e "s/$/|/g")"
        curl "https://github.com/wslutilities/wslu/archive/refs/tags/v${tmp_version}.tar.gz" -o "wslu-${tmp_version}.tar.gz"
        VERSION="$(curl -s https://raw.githubusercontent.com/wslutilities/wslu/v${tmp_version}/VERSION)"
        ;;
    *)
        tmp_info="$(curl -s https://api.github.com/repos/wslutilities/wslu/releases/tags/v${1})"
        CHANGELOG="$(echo "$tmp_info" | grep -oP '"body": "\K(.*)(?=")')"
        CHANGELOG="$(echo -e "$CHANGELOG" | sed -e "s/\r//g" -e "s/^\s*##.*$//g" -e "/^$/d" -e "s/^-/  -/g" -e "s/$/|/g")"
        curl "https://github.com/wslutilities/wslu/archive/refs/tags/v${1}.tar.gz" -o "wslu-${1}.tar.gz"
        VERSION="$(curl -s https://raw.githubusercontent.com/wslutilities/wslu/v${1}/VERSION)"
        ;;
esac

chmod +x ./debian/rules
sed -i s/DISTROPLACEHOLDER/"$CODENAME"/g ./debian/changelog
sed -i s/VERSIONPLACEHOLDER/"$VERSION"/g ./debian/changelog
sed -i s/POSTFIXPLACEHOLDER/"$POSTFIX"/g ./debian/changelog
sed -i s/DATETIMEPLACEHOLDER/"$(date +'%a, %d %b %Y %T %z')"/g ./debian/changelog
sed -i s/ARCHPLACEHOLDER/"$ARCHITECTURE"/g ./debian/control

OIFS=$IFS; IFS=$'|'; cl_arr=($CHANGELOG); IFS=$OIFS;
for q in "${cl_arr[@]}"; do
    tmp="$(echo "$q" | sed -e 's/|$//g' -e 's/^  - //g')"
    DEBFULLNAME="Patrick Wu" dch -a "$tmp"
    unset tmp
done

# case $DISTRO in
#     debian|pengwin)
#         tar xvf wslu-*.tar.gz
#         debuild -i -us -uc -b
#         ;;
#     *);;
# esac



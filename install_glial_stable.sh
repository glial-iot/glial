#!/bin/bash

unknown_os ()
{
  echo "Unfortunately, your operating system distribution and version are not supported by this script."
  exit 1
}

gpg_check ()
{
  echo "Checking for gpg..."
  if command -v gpg > /dev/null; then
    echo "Detected gpg..."
  else
    echo "Installing gnupg for GPG verification..."
    apt-get install -y gnupg
    if [ "$?" -ne "0" ]; then
      echo "Unable to install GPG! Your base system has a problem; please check your default OS's package repositories because GPG should work."
      echo "Repository installation aborted."
      exit 1
    fi
  fi
}

curl_check ()
{
  echo "Checking for curl..."
  if command -v curl > /dev/null; then
    echo "Detected curl..."
  else
    echo "Installing curl..."
    apt-get install -q -y curl
    if [ "$?" -ne "0" ]; then
      echo "Unable to install curl! Your base system has a problem; please check your default OS's package repositories because curl should work."
      echo "Repository installation aborted."
      exit 1
    fi
  fi
}

install_debian_keyring ()
{
  if [ "${os}" = "debian" ]; then
    echo "Installing debian-archive-keyring which is needed for installing "
    echo "apt-transport-https on many Debian systems."
    apt-get install -y debian-archive-keyring &> /dev/null
  fi
}


detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    # some systems dont have lsb-release yet have the lsb_release binary and
    # vice-versa
    if [ -e /etc/lsb-release ]; then
      . /etc/lsb-release

      if [ "${ID}" = "raspbian" ]; then
        os=${ID}
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      else
        os=${DISTRIB_ID}
        dist=${DISTRIB_CODENAME}

        if [ -z "$dist" ]; then
          dist=${DISTRIB_RELEASE}
        fi
      fi

    elif [ `which lsb_release 2>/dev/null` ]; then
      dist=`lsb_release -c | cut -f2`
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

    elif [ -e /etc/debian_version ]; then
      # some Debians have jessie/sid in their /etc/debian_version
      # while others have '6.0.7'
      os=`cat /etc/issue | head -1 | awk '{ print tolower($1) }'`
      if grep -q '/' /etc/debian_version; then
        dist=`cut --delimiter='/' -f1 /etc/debian_version`
      else
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      fi

    else
      unknown_os
    fi
  fi

  if [ -z "$dist" ]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"

  echo "Detected operating system as $os/$dist."
}


apt_get_update ()
{
  echo -n "Running apt-get update... "
  apt-get update &> /dev/null
  echo "done."
}

apt_transport_https_install ()
{
  echo -n "Installing apt-transport-https... "
  apt-get install -y apt-transport-https &> /dev/null
  echo "done."
}

install_tarantool_rep ()
{
  gpg_key_url="http://download.tarantool.org/tarantool/1.10/gpgkey"
  apt_source_path="/etc/apt/sources.list.d/tarantool_1_10.list"

  echo -n "Installing $apt_source_path..."

  # create an apt config file for this repository
  release=`lsb_release -c -s`
  rm -f /etc/apt/sources.list.d/*tarantool*.list
  echo "deb http://download.tarantool.org/tarantool/1.10/debian/ ${release} main" > $apt_source_path
  echo "deb-src http://download.tarantool.org/tarantool/1.10/debian/ ${release} main" >> $apt_source_path

  echo -n "Importing gpg key... "
  # import the gpg key
  curl -L "${gpg_key_url}" 2> /dev/null | apt-key add - &>/dev/null
  echo "done."
}

install_glial_rep ()
{
  gpg_key_url="https://glial-iot.github.io/glial-stable/PUBLIC.KEY"
  apt_source_path="/etc/apt/sources.list.d/glial.list"

  echo -n "Installing $apt_source_path..."

  # create an apt config file for this repository
  echo "deb http://glial-iot.github.io/glial-stable stretch main" > $apt_source_path

  echo -n "Importing gpg key... "
  # import the gpg key
  curl -L "${gpg_key_url}" 2> /dev/null | apt-key add - &>/dev/null
  echo "done."
}

detect_os
curl_check
gpg_check
apt_transport_https_install
apt_get_update
install_debian_keyring

install_tarantool_rep
install_glial_rep

apt_get_update

install_glial

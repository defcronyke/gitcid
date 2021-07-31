#!/bin/bash
#
#-----------------------------
#
# WARNING: THIS SCRIPT WILL DESTROY YOUR BIND DNS CONFIG FILES
# LOCATED IN THE FOLDER: /etc/bind
# 
# It won't ask first if you're sure that you want to destroy 
# the config! It's only meant to be used as a convenience for 
# developers.
#
# DON'T RUN THIS SCRIPT UNLESS YOU WANT TO DESTROY YOUR
# BIND /etc/bind CONFIG FILES!!
#
# YOU HAVE BEEN WARNED.
#
#-----------------------------
#

gitcid_remove_bind_dns_config_files() {
  current_gitcid_dir_before_util="$PWD"

  cd .gc || return 1

  cd discover-git-server-dns
  if [ $? -ne 0 ]; then
    git clone https://gitlab.com/defcronyke/discover-git-server-dns.git || \
      return 2

    cd discover-git-server-dns
  else
    git pull origin master
  fi

  ./util-remove-bind-config.sh

  cd "$current_gitcid_dir_before_util"
}

gitcid_remove_bind_dns_config_files $@

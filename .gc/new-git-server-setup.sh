#!/usr/bin/env bash

# Set up new git server OS after flashing it to a storage device.
gc_new_git_server_setup() {
  echo ""
  echo "info: Mounting the OS."
  echo ""

  mkdir -p tmp_os_mount_dir
  sudo mount "${2}1" tmp_os_mount_dir

  mkdir -p tmp_os_mount_dir2
  sudo mount "${2}2" tmp_os_mount_dir2

  echo ""
  echo "info: Enabling SSH server for remote access."
  echo ""

  cd tmp_os_mount_dir
  sudo touch ssh
  cd ..

  echo ""
  echo "info: Setting hostname..."
  echo ""

  GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME="$(.gc/new-git-server-hostname.sh $@)"

  if [ -z "$GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME" ]; then
    GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME="git1"
  fi

  echo "$GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME" | sudo tee tmp_os_mount_dir2/etc/hostname

  echo ""
  echo "/etc/hostname"
  echo ""
  cat tmp_os_mount_dir2/etc/hostname
  echo ""

  sudo sed -i 's/^127\.0\.1\.1\s*.*$//g' tmp_os_mount_dir2/etc/hosts

  sudo sed -i "s/^\(127\.0\.0\.1\s*\)\(.*\s*\)*\(${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}\s*\)*\(.*\)$/\1\2\4/g" tmp_os_mount_dir2/etc/hosts

  sudo sed -i "s/^\(127\.0\.0\.1\s*\)\(.*\)$/\1${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME} \2/g" tmp_os_mount_dir2/etc/hosts

  echo ""
  echo "/etc/hosts"
  echo ""
  cat tmp_os_mount_dir2/etc/hosts
  echo ""

  echo ""
  echo "info: Unmounting the OS."
  echo ""

  sudo umount "${2}1"
  sudo umount "${2}2"
}

gc_new_git_server_setup $@

#!/usr/bin/env bash

# Set up new git server OS after flashing it to a storage device.
gc_new_git_server_setup() {
  echo ""
  echo "info: Mounting the OS."
  echo ""

  mkdir -p tmp_os_mount_dir
  sudo mount "${2}1" tmp_os_mount_dir
  cd tmp_os_mount_dir

  echo ""
  echo "info: Enabling SSH server for remote access."
  echo ""

  sudo touch ssh
  cd ..

  echo ""
  echo "info: Setting hostname."
  echo ""

  GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME="$(.gc/new-git-server-hostname.sh $@)"

  if [ -z "$GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME" ]; then
    GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME="git1"
  fi

  echo "$GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME" | sudo tee tmp_os_mount_dir/etc/hostname

  sudo sed -i 's/^127\.0\.1\.1\s*.*$//g' tmp_os_mount_dir/etc/hosts

  sudo sed -i "s/^\(127\.0\.0\.1\s*\)\(.*\)$/\1${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME} \2/g" tmp_os_mount_dir/etc/hosts

  echo ""
  echo "info: Unmounting the OS."
  echo ""

  sudo umount "${2}1"
}

gc_new_git_server_setup $@

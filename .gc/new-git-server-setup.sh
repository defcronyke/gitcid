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

  echo ""
  echo "/etc/hostname"
  echo ""
  cat tmp_os_mount_dir2/etc/hostname
  echo ""

  sudo sed -i 's/^127\.0\.1\.1\s*.*$//g' tmp_os_mount_dir2/etc/hosts

  sudo sed -i "s/^\(127\.0\.0\.1\s*\)\(${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}\s*\)*\(.*\)$/\1\3/g" tmp_os_mount_dir2/etc/hosts

  sudo sed -i "s/^\(127\.0\.0\.1\s*\)\(.*\)$/\1${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME} \2/g" tmp_os_mount_dir2/etc/hosts

  echo ""
  echo "/etc/hosts"
  echo ""
  cat tmp_os_mount_dir2/etc/hosts
  echo ""
  echo ""

  echo ""
  echo "Installing systemd startup script."
  echo ""

  sudo cp -rf .gc/.gc-util/git-server-startup.service tmp_os_mount_dir2/etc/systemd/system/
  sudo ln -sf ../git-server-startup.service tmp_os_mount_dir2/etc/systemd/system/multi-user.target.wants/git-server-startup.service

  echo ""
  echo ""
  echo "Installing git server onto mounted disk..."
  echo ""

  rm -rf tmp_os_mount_dir2/home/pi/git-server

  sudo mkdir -p tmp_os_mount_dir2/home/pi

  sudo git clone https://gitlab.com/defcronyke/git-server.git tmp_os_mount_dir2/home/pi/git-server

  sudo chown -R 1000:1000 tmp_os_mount_dir2/home/pi/git-server

  sudo rm -rf tmp_os_mount_dir2/home/pi/git-server/gitcid

  sudo git clone https://gitlab.com/defcronyke/gitcid.git tmp_os_mount_dir2/home/pi/git-server/gitcid

  sudo chown -R 1000:1000 tmp_os_mount_dir2/home/pi/git-server/gitcid

  echo ""
  echo ""
  echo "info: Unmounting the OS. Please wait and don't remove the disk yet. This might take a few minutes..."
  echo ""

  sudo umount "${2}1"
  sudo umount "${2}2"

  echo "info: Unmounted the OS. You can remove the disk now."
  echo ""
}

gc_new_git_server_setup $@

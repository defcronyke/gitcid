#!/usr/bin/env bash

# Set up new git server OS after flashing it to a storage device.
gc_new_git_server_setup() {
  echo ""
  echo "info: Mounting the OS."
  echo ""

  mkdir -p tmp_os_mount_dir
  sudo mount "${2}1" tmp_os_mount_dir

  if [ $? -ne 0 ]; then
    return 9
  fi

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

  sudo sed -i "s/^\(127\.0\.0\.1\s*\)\(git[0-9]*\s*\)*\(.*\)$/\1\3/g" tmp_os_mount_dir2/etc/hosts

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
  echo "Installing ssh key onto mounted disk..."
  echo ""

  new_git_server_setup_previous_dir="$PWD"

  if [ ! -d "${HOME}/.ssh" ]; then
    mkdir "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
  fi

  if [ ! -f "${HOME}/.ssh/config" ]; then
    touch "${HOME}/.ssh/config"
    chmod 600 "${HOME}/.ssh/config"
  fi

  if [ ! -f "${HOME}/.ssh/known_hosts" ]; then
    touch "${HOME}/.ssh/known_hosts"
    chmod 600 "${HOME}/.ssh/known_hosts"
  fi

  if [ ! -f "${HOME}/.ssh/authorized_keys" ]; then
    touch "${HOME}/.ssh/authorized_keys"
    chmod 600 "${HOME}/.ssh/authorized_keys"
  fi

  if [ ! -f "${HOME}/.ssh/git-server.key" ]; then
    cd "${HOME}/.ssh"

    ssh-keygen -t rsa -b 4096 -q -f $HOME/.ssh/git-server.key -N "" -C git-server

    chmod 600 ${HOME}/.ssh/git-server.key*
    
    cd "$new_git_server_setup_previous_dir"
  fi


  cat "${HOME}/.ssh/config" | grep "^Host ${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}"
  if [ $? -ne 0 ]; then
    printf '%b\n' "\n\
Host ${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}\n\
  HostName ${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}\n\
  User pi\n\
  IdentityFile ~/.ssh/git-server.key\n\
  IdentitiesOnly yes\n\
  ConnectTimeout 5\n\
  ConnectionAttempts 3\n\
"   | tee -a "${HOME}/.ssh/config"
  fi

  
  cat "${HOME}/.ssh/known_hosts" | grep "^${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME} " >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    sed -i "/^${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}\s*.*$/d" "${HOME}/.ssh/known_hosts"
  fi


  ssh-keygen -F "${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}" 2>/dev/null || ssh-keyscan "${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}" 2>/dev/null | tee -a "${HOME}/.ssh/known_hosts" >/dev/null


  if [ ! -d "tmp_os_mount_dir2/home/pi/.ssh" ]; then
    sudo mkdir "tmp_os_mount_dir2/home/pi/.ssh"
    sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh"
    sudo chmod 700 "tmp_os_mount_dir2/home/pi/.ssh"
  fi

  if [ ! -f "tmp_os_mount_dir2/home/pi/.ssh/config" ]; then
    sudo touch "tmp_os_mount_dir2/home/pi/.ssh/config"
    sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/config"
    sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/config"
  fi

  if [ ! -f "tmp_os_mount_dir2/home/pi/.ssh/known_hosts" ]; then
    sudo touch "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"
    sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"
    sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"
  fi

  if [ ! -f "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys" ]; then
    sudo touch "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys"
    sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys"
    sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys"
  fi


  sudo cp ${HOME}/.ssh/git-server.key* "tmp_os_mount_dir2/home/pi/.ssh/"
  sudo chown 1000:1000 tmp_os_mount_dir2/home/pi/.ssh/git-server.key*
  sudo chmod 600 tmp_os_mount_dir2/home/pi/.ssh/git-server.key*



  cat "tmp_os_mount_dir2/home/pi/.ssh/config" | grep "^Host ${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}"
  if [ $? -ne 0 ]; then
    printf '%b\n' "\n\
Host ${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}\n\
  HostName ${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}\n\
  User pi\n\
  IdentityFile ~/.ssh/git-server.key\n\
  IdentitiesOnly yes\n\
  ConnectTimeout 5\n\
  ConnectionAttempts 3\n\
"   | sudo tee -a "tmp_os_mount_dir2/home/pi/.ssh/config"
  fi

  sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/config"
  sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/config"



  sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"
  sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"


  cat "tmp_os_mount_dir2/home/pi/.ssh/known_hosts" | grep "^${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME} " >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    sudo sed -i "/^${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}\s*.*$/d" "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"
  fi


  sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"
  sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"


  ssh-keygen -F "${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}" 2>/dev/null || ssh-keyscan "${GITCID_NEW_GIT_SERVER_INSTALL_NEW_SELECTED_HOSTNAME}" 2>/dev/null | sudo tee -a "tmp_os_mount_dir2/home/pi/.ssh/known_hosts" >/dev/null


  sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"
  sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/known_hosts"



  sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys"
  sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys"


  cat "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys" | grep ".* git-server$"
  if [ $? -eq 0 ]; then
    sudo sed -i "/^.*\s*git-server$/d" "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys"
  fi


  cat "tmp_os_mount_dir2/home/pi/.ssh/git-server.key.pub" | sudo tee -a "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys" >/dev/null


  sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys"
  sudo chmod 600 "tmp_os_mount_dir2/home/pi/.ssh/authorized_keys"


  echo ""
  echo ""
  echo "info: Adding things to ~/.bashrc so they happen when you log in on the server..."
  echo ""

  cat "tmp_os_mount_dir2/home/pi/.bashrc" | grep "journalctl -u git-server-startup -f" >/dev/null

  if [ $? -ne 0 ]; then
    printf '%b\n' 'echo ""\necho " ---------- Git Server Startup Logs (type ctrl-c to close this)  ---------- "\necho ""\n' | sudo tee -a "tmp_os_mount_dir2/home/pi/.bashrc"
    echo "journalctl -u git-server-startup -f" | sudo tee -a "tmp_os_mount_dir2/home/pi/.bashrc"
  fi

  sudo chown 1000:1000 "tmp_os_mount_dir2/home/pi/.bashrc"
  sudo chmod 644 "tmp_os_mount_dir2/home/pi/.bashrc"

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

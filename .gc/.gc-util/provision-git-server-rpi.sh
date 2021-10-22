#!/bin/bash

gitcid_install_new_git_server_rpi_auto_provision() {
  gc_ssh_host="$@"

  gc_ssh_username="pi"

  echo ""
  echo "NOTICE: Trying to auto-install our ssh key onto a host which is maybe a Raspberry Pi: ${gc_ssh_username}@${gc_ssh_host}"
  echo ""



  sed -i "/^${gc_ssh_host}\s.*$/d" "${HOME}/.ssh/known_hosts"; \
  sed -i '/^$/d' "${HOME}/.ssh/known_hosts"

  echo ""
  echo "Adding git-server key to local ssh config: \"${HOME}/.ssh/git-server.key\" >> \"${HOME}/.ssh/config\""
  cat "${HOME}/.ssh/config" | grep -P "^Host $gc_ssh_host" >/dev/null || printf "%b\n" "\nHost ${gc_ssh_host}\n\tHostName ${gc_ssh_host}\n\tUser ${gc_ssh_username}\n\tIdentityFile ~/.ssh/git-server.key\n\tIdentitiesOnly yes\n\tConnectTimeout 5\n\tConnectionAttempts 3\n" | tee -a "${HOME}/.ssh/config" >/dev/null
  echo ""
  echo "Added key to local \"${HOME}/.ssh/config\" for host: ${gc_ssh_username}@${gc_ssh_host}"


  echo ""
  echo "Verifying host: $gc_ssh_host"
  echo ""


  ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$gc_ssh_host"

  ssh-keygen -F "$gc_ssh_host" || ssh-keyscan "$gc_ssh_host" | tee -a "${HOME}/.ssh/known_hosts" >/dev/null


  echo ""
  echo "Pre-activating ssh key config on Raspberry Pi host: ${gc_ssh_username}@${gc_ssh_host}"
  { { sshpass -p 'raspberry' ssh -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=3 -tt ${gc_ssh_username}@${gc_ssh_host} 'mkdir -p $HOME/.ssh; chmod 700 $HOME/.ssh; touch $HOME/.ssh/config; chmod 600 $HOME/.ssh/config; touch $HOME/.ssh/authorized_keys; chmod 600 $HOME/.ssh/authorized_keys; echo ""; echo "This seems to be a freshly installed Raspberry Pi OS device. Creating .ssh/ directory and files."; echo ""; exit 0;'; }; }
  echo ""

  echo ""
  echo "Installing ssh key onto Raspberry Pi host: ${gc_ssh_username}@${gc_ssh_host}"

  sshpass -p 'raspberry' scp -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=3 "${HOME}/.ssh/git-server.key"* ${gc_ssh_username}@${gc_ssh_host}:"/home/${gc_ssh_username}/.ssh/"
  if [ $? -ne 0 ]; then
    sed -i "s/^${gc_ssh_host} .*$//g" "${HOME}/.ssh/known_hosts"
    # sed -i "s/^\n$//g" "${HOME}/.ssh/known_hosts"
    # cat 
    sshpass -p 'raspberry' scp -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=3 "${HOME}/.ssh/git-server.key"* ${gc_ssh_username}@${gc_ssh_host}:"/home/${gc_ssh_username}/.ssh/"
  fi
  
  echo ""
  echo "Activating ssh key config on Raspberry Pi host: ${gc_ssh_username}@${gc_ssh_host}"
  { { sshpass -p 'raspberry' ssh -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=3 -tt ${gc_ssh_username}@${gc_ssh_host} 'mkdir -p $HOME/.ssh; chmod 700 $HOME/.ssh; touch $HOME/.ssh/config; chmod 600 $HOME/.ssh/config; touch $HOME/.ssh/authorized_keys; chmod 600 $HOME/.ssh/authorized_keys; cat $HOME/.ssh/authorized_keys | grep "$(cat $HOME/.ssh/git-server.key.pub)" >/dev/null || cat $HOME/.ssh/git-server.key.pub | tee -a $HOME/.ssh/authorized_keys >/dev/null; cat $HOME/.ssh/config | grep -P "^Host '$gc_ssh_host'$" >/dev/null || printf "%b\n" "\nHost '$gc_ssh_host'\n\tHostName '$gc_ssh_host'\n\tUser '$gc_ssh_username'\n\tIdentityFile ~/.ssh/git-server.key\n\tIdentitiesOnly yes\n\tConnectTimeout 5\n\tConnectionAttempts 3\n" | tee -a $HOME/.ssh/config >/dev/null; ssh-keygen -F "$gc_ssh_host" || ssh-keyscan "$gc_ssh_host" | tee -a $HOME/.ssh/known_hosts >/dev/null; echo ""; echo "This seems to be a freshly installed Raspberry Pi OS device. It is required for better security that you change your user and root account passwords on this device. You will be prompted to change your passwords during an upcoming step soon."; echo ""; exit 0;'; exit 0; }; exit 0; }
  rpi_auto_activate_ssh_res=$?
  echo ""
  echo "Finished installing ssh key on Raspberry Pi host: ${gc_ssh_username}@${gc_ssh_host}"
  echo ""

  echo ""
  echo "Finished auto-installing ssh key onto a Raspberry Pi OS host: ${gc_ssh_username}@${gc_ssh_host}"
  echo ""

  return $rpi_auto_activate_ssh_res
}

gitcid_install_new_git_server_rpi_auto_provision $@

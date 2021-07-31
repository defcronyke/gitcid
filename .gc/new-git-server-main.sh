#!/bin/bash
# Run this to make a new git server.
#
# WARNING: The target is intended to be a freshly
# installed Linux distro which will become a
# dedicated git server. This command will attempt
# to install some dependencies, and it will do
# some system configurations on the target which
# you might not prefer to happen on a system that
# you're using for any other purposes!
# 
# PLEASE ONLY POINT THIS COMMAND AT A TARGET THAT
# YOU INTEND TO USE AS A DEDICATED GIT SERVER!
# IT COULD BREAK THE TARGET SYSTEM OTHERWISE!
#
# YOU HAVE BEEN WARNED!!
#

gitcid_new_git_server_usage() {
  echo ""
  echo "Install git servers at ssh target locations."
  echo "-------"
  echo ""
  echo "Currently supported target platforms are:"
  echo ""
  echo "  Debian Stable (amd64)"
  echo "  Debian Testing (amd64)"
  echo "  Raspberry Pi OS (armhf)"
  echo "  Raspberry Pi OS (aarch64)"
  echo ""
  echo "Usage:"
  echo "-----"
  echo ""
  echo "  $0 [-y[o] | -s[o]] [\$USER@]<target new git server's ssh path> [target2 [target3 ...]]"
  echo ""
  echo "Examples"
  echo "--------"
  echo ""
  echo "Interactive:"
  echo ""
  echo "  $0 git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Interactive, open web browser:"
  echo ""
  echo "  $0 -o git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Non-interactive:"
  echo ""
  echo "  $0 -y git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Non-interactive, open web browser:"
  echo ""
  echo "  $0 -yo git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Sequential mode (instead of the default parallel mode"
  echo "when installing multiple targets), non-interactive:"
  echo ""
  echo "  $0 -s git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "Sequential mode non-interactive, open web browser:"
  echo ""
  echo "  $0 -so git1 [pi@git2 [git3 ...]]"
  echo ""
  echo "--------"
  echo ""
  echo "Full instructions are here:"
  echo ""
  echo "  https://gitlab.com/defcronyke/gitcid#install-a-dedicated-git-server"
  echo ""
  echo "--------"
  echo ""
}

gc_new_git_server_install_cancel() {
  echo ""
  gitcid_new_git_server_usage $@
  echo ""
  echo "Cancelled git server installation."
  echo ""
  return 20
}

gc_new_git_server_get_raspios_lite_armhf_download_latest_version_zip_url() {
  GC_RASPIOS_LITE_ARMHF_DOWNLOAD_BASE_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/"; \
  GC_RASPIOS_LITE_ARMHF_DOWNLOAD_VERSIONS=( ); \
  GC_RASPIOS_LITE_ARMHF_DOWNLOAD_VERSIONS+=( "$(curl -sL $GC_RASPIOS_LITE_ARMHF_DOWNLOAD_BASE_URL | grep -P "^.*href=\"raspios.*\".*$" | sed 's@.*\(.*href=\"\)\(raspios.*\/\)\(\".*\).*@\2@g')" ); \
  GC_RASPIOS_LITE_ARMHF_DOWNLOAD_LATEST_VERSION_DIR="$(echo "${GC_RASPIOS_LITE_ARMHF_DOWNLOAD_VERSIONS[@]}" | tail -n1)"; \
  GC_RASPIOS_LITE_ARMHF_DOWNLOAD_LATEST_VERSION_ZIP_FILENAME="$(printf '%s\n' "$(curl -sL ${GC_RASPIOS_LITE_ARMHF_DOWNLOAD_BASE_URL}${GC_RASPIOS_LITE_ARMHF_DOWNLOAD_LATEST_VERSION_DIR}/ | grep -P "^.*href=\".*raspios.*.zip\".*$" | sed 's@.*\(.*href=\"\)\(.*raspios.*.zip\)\(\".*\).*@\2@g')")"; \
  GC_RASPIOS_LITE_ARMHF_DOWNLOAD_LATEST_VERSION_ZIP_URL="$(printf '%s\n' "${GC_RASPIOS_LITE_ARMHF_DOWNLOAD_BASE_URL}${GC_RASPIOS_LITE_ARMHF_DOWNLOAD_LATEST_VERSION_DIR}${GC_RASPIOS_LITE_ARMHF_DOWNLOAD_LATEST_VERSION_ZIP_FILENAME}")"; \
  echo "$GC_RASPIOS_LITE_ARMHF_DOWNLOAD_LATEST_VERSION_ZIP_URL"
}

gc_new_git_server_get_raspios_lite_arm64_download_latest_version_zip_url() {
  GC_RASPIOS_LITE_ARM64_DOWNLOAD_BASE_URL="https://downloads.raspberrypi.org/raspios_lite_arm64/images/"; \
  GC_RASPIOS_LITE_ARM64_DOWNLOAD_VERSIONS=( ); \
  GC_RASPIOS_LITE_ARM64_DOWNLOAD_VERSIONS+=( "$(curl -sL $GC_RASPIOS_LITE_ARM64_DOWNLOAD_BASE_URL | grep -P "^.*href=\"raspios.*\".*$" | sed 's@.*\(.*href=\"\)\(raspios.*\/\)\(\".*\).*@\2@g')" ); \
  GC_RASPIOS_LITE_ARM64_DOWNLOAD_LATEST_VERSION_DIR="$(echo "${GC_RASPIOS_LITE_ARM64_DOWNLOAD_VERSIONS[@]}" | tail -n1)"; \
  GC_RASPIOS_LITE_ARM64_DOWNLOAD_LATEST_VERSION_ZIP_FILENAME="$(printf '%s\n' "$(curl -sL ${GC_RASPIOS_LITE_ARM64_DOWNLOAD_BASE_URL}${GC_RASPIOS_LITE_ARM64_DOWNLOAD_LATEST_VERSION_DIR}/ | grep -P "^.*href=\".*raspios.*.zip\".*$" | sed 's@.*\(.*href=\"\)\(.*raspios.*.zip\)\(\".*\).*@\2@g')")"; \
  GC_RASPIOS_LITE_ARM64_DOWNLOAD_LATEST_VERSION_ZIP_URL="$(printf '%s\n' "${GC_RASPIOS_LITE_ARM64_DOWNLOAD_BASE_URL}${GC_RASPIOS_LITE_ARM64_DOWNLOAD_LATEST_VERSION_DIR}${GC_RASPIOS_LITE_ARM64_DOWNLOAD_LATEST_VERSION_ZIP_FILENAME}")"; \
  echo "$GC_RASPIOS_LITE_ARM64_DOWNLOAD_LATEST_VERSION_ZIP_URL"
}

gc_new_git_server_interactive() {
  echo ""
  echo "Are you sure you want to install git server(s) at the ssh path(s): $@ [ y / N ] ? "

  read gc_new_git_server_confirm
  if [ "$gc_new_git_server_confirm" != "y" ] && [ "$gc_new_git_server_confirm" != "Y" ]; then
    gc_new_git_server_install_cancel $@ || \
      return $?
  fi

  return 0
}

new_git_server_detect_other_git_servers() {
  echo ""
  echo "PWD=\"$PWD\""
  echo ""
  echo "GitWeb servers detected on your network (with args: $@):"
  echo ""
  if [ $gc_new_git_server_open_web_browser -eq 0 ]; then
    .gc/git-servers-open.sh $@
    echo ""
    echo "GitWeb pages launched in web browser. If any pages don't"
    echo "load on first attempt, try refreshing the page."
  else
    .gc/git-servers.sh $@
  fi

  echo ""
  echo "To open a web browser tab for each detected GitWeb"
  echo "server and any additional user-specified servers,"
  echo "run this command:"
  echo ""
  echo "  .gc/git-servers-open.sh [[git1] [git2] ...]"
  echo ""
}

gitcid_new_git_server_post() {
  if [ $# -gt 0 ]; then
    echo ""
    echo "args at return: $@"
    echo ""
    
    first_arg=$1
    shift
  fi

  no_sudo_hosts=( )

  new_install_success=1
  
  last_bad=0

  bad_hosts=( )

  for i in $@; do
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
    # ssh-keygen -F "$i" || ssh-keyscan "$i" >>$HOME/.ssh/known_hosts

    { ssh -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $i 'sudo -n cat /dev/null; res=$?; if [ $res -ne 0 ]; then echo ""; echo "ERROR: [ HOST: $USER@$(hostname) ]: Host failed running sudo non-interactively, so they cannot be used in parallel mode. Trying again in sequential mode..."; echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init) -s; res=$?; fi; exit $res'; }
    res=$?
    # res=$?

    echo "res=$res"

    if [ $res -eq 255 ]; then
      echo "error: Failed connecting with ssh to host: $i"
      continue

    elif [ $res -eq 19 ]; then
      echo ""
      echo "Succeeded at enabling passwordless sudo. Trying parallel mode install..."
      echo ""
      { ssh -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt $i 'echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init); res2=$?; exit $res2'; }
      res2=$?
      # res2=$?

      echo "res2=$res2"

      if [ $res2 -ne 0 ]; then
        last_bad=$res2
        bad_hosts+=( "$i" )
        echo ""
        echo "ERROR: [ HOST: $i ]: Failed parallel mode install. Sorry, it looks like it's going to take some manual intervention to install a git server on this host, this system can't seem to do it automatically. Giving up."
        echo ""
      else
        new_install_success=0
      fi

    elif [ $res -ne 0 ]; then
      last_bad=$res
      bad_hosts+=( "$i" )
      echo ""
      echo "ERROR: [ HOST: $i ]: Failed running in sequential mode. Return code: $res"
    else
      new_install_success=0
    fi
  done

  echo ""

  if [ $new_install_success -ne 0 ]; then
    gitcid_new_git_server_usage $@
    echo ""
    return 20
  else
    new_git_server_detect_other_git_servers $@
    echo ""
    return 20
  fi

  if [ $last_bad -ne 0 ]; then
    echo "ERROR: At least one git server install failed. The last exit error code was: $last_bad"
    echo ""
    echo "ERROR: Hosts that failed installation:"
    echo ""
    for h in ${bad_hosts[@]}; do
      echo "  $h"
    done
    echo ""
  fi

  # current_dir="$PWD"
  # cd ../discover-git-server-dns
  # # git fetch --all
  # git pull
  # ./git-update-srv.sh $@
  # cd "$current_dir"

  return $last_bad
}

# Install a new OS to a locally-connected disk.
gc_new_git_server_install_os() {
  if [ $# -ge 1 ]; then
    if [[ "$1" =~ ^\-[Rr]F?f?$ ]]; then
      if [ $# -lt 2 ]; then
        echo ""
        echo "error: New git server installation on a Raspberry Pi requested without a target device path."
        echo ""
        echo "error: Path needs to be similar to: /dev/sdx"
        echo ""

        return 20

      else
        echo "$2" | grep -P "^/dev/.+$"
        if [ $? -ne 0 ]; then
          echo ""
          echo "error: New git server installation on a Raspberry Pi requested at an invalid target device path: $2"
          echo ""
          echo "error: Path needs to be similar to: /dev/sdx"
          echo ""

          return 20
        fi

        if [[ ! "$1" =~ ^\-[Rr]Ff$ ]]; then
          sleep 2
        fi
        echo ""
        echo "New git server installation on a Raspberry Pi requested at target device path: $2"
        echo ""
        echo "WARNING: ----- !! --- !! BIG WARNING !! --- !! -----"
        echo "WARNING:"
        echo "WARNING: This procedure will DESTROY ALL DATA ON THE TARGET DEVICE at the path you specified!"
        echo "WARNING: All data on the target device will be permanently lost and unrecoverable!"
        echo "WARNING: The device you're about to erase is: $2"
        echo "WARNING: YOU HAVE BEEN WARNED !!"
        echo "WARNING:"
        echo "WARNING: ----- !! --- !! BIG WARNING !! --- !! -----"
        echo ""

        ls "$2"
        if [ $? -ne 0 ]; then
          echo ""
          echo "error: Target device path not found on local system, or an invalid target:"
          echo ""
          echo "  $2"
          echo ""
          echo "error: Not installing OS."
          echo ""
          return 20
        fi
        
        if [[ ! "$1" =~ ^\-[Rr]F?f$ ]]; then
          echo "Are you sure you want to install a new git server at this local device path?: $2"
          printf "[ y / N ] ? "
          read gitcid_new_git_server_confirm_destroy_all_data_on_target_device
          echo ""

          if [ "$gitcid_new_git_server_confirm_destroy_all_data_on_target_device" != "y" ] && \
            [ "$gitcid_new_git_server_confirm_destroy_all_data_on_target_device" != "Y" ]; then
            echo ""
            echo "Cancelling..."
            echo ""
            gc_new_git_server_install_cancel $@
            return $?
          fi
        else
          if [[ ! "$1" =~ ^\-[Rr]Ff$ ]]; then
            sleep 3
          fi
          echo "WARNING: ***** !! *** !! MASSIVELY HUGE WARNING !! *** !! *****"
          echo "WARNING:"
          echo "WARNING: You invoked this command with the NO CONFIRMATION REQUIRED option selected:"
          echo "WARNING:"
          echo "WARNING:   $0 $@"
          echo "WARNING:"
          echo "WARNING: ALL DATA ON THE FOLLOWING DEVICE WILL BE PERMANENTLY ERASED WITHOUT ASKING FIRST:"
          echo "WARNING:"
          echo "WARNING:   $0 $2"
          echo "WARNING:"
          echo "WARNING: You have been warned."
          echo "WARNING:"
          echo "WARNING: ***** !! *** !! MASSIVELY HUGE WARNING !! *** !! *****"
          echo ""
          if [[ ! "$1" =~ ^\-[Rr]Ff$ ]]; then
            sleep 2
            echo "To abort this data destroying operation, press CTRL-C within the next 10 seconds."
            echo "Waiting now for 10 seconds, in case you want to abort the operation before it starts..."
            sleep 3
            echo ""
            echo "Waiting.........."
            echo ""
            sleep 12
          fi
          
          echo "WARNING: Okay, it looks like you're sure you want to erase this device without confirmation:"
          echo ""
          echo "  $2"
          echo ""

          if [[ ! "$1" =~ ^\-[Rr]Ff$ ]]; then
            echo "WARNING: If it was a mistake, this is your last chance to cancel. Waiting 5 more seconds..."
            sleep 2
            echo ""
            echo "Waiting.........."
            echo ""
            sleep 7
          fi

          echo ""
          echo "Understood. Erasing data now... Please don't cancel. It would only cause problems and it's too late to stop now."
          echo ""
        fi

        if [[ "$1" =~ ^\-rF?f?$ ]]; then
          GITCID_OS_INSTALL_ARCH="armhf"
          GITCID_OS_INSTALL_LINK="$(gc_new_git_server_get_raspios_lite_armhf_download_latest_version_zip_url $@)"
        elif [[ "$1" =~ ^\-RF?f?$ ]]; then
          GITCID_OS_INSTALL_ARCH="aarch64"
          GITCID_OS_INSTALL_LINK="$(gc_new_git_server_get_raspios_lite_arm64_download_latest_version_zip_url $@)"
        else
          echo "error: Unexpected option. Not installing."
          return 20
        fi

        gc_dir_before_os_install="$PWD"
        
        GITCID_OS_INSTALL_TMP_DIR="$(mktemp -d)"

        if [ ! -d "$GITCID_OS_INSTALL_TMP_DIR" ]; then
          echo "error: Failed creating temporary directory for OS install. Not installing OS."
          return 20
        fi
        
        echo ""
        echo "Created temp dir: $GITCID_OS_INSTALL_TMP_DIR"

        cd "$GITCID_OS_INSTALL_TMP_DIR"

        if [ $? -ne 0 ]; then
          echo "error: Failed entering temporary directory for OS install. Not installing OS."
          return 20
        fi

        echo "Entered temp dir: $GITCID_OS_INSTALL_TMP_DIR"
        echo ""

        echo "Retreiving the latest \"Raspberry Pi OS Lite\" image from their official server if necessary..."
        echo ""
        
        if [ -f "${gc_dir_before_os_install}/gc_install_os_file_${GITCID_OS_INSTALL_ARCH}" ]; then
          echo "NOTICE: Using a previously downloaded OS file. If you'd prefer to fetch the"
          echo "latest version online and use that instead, you should delete the previous"
          echo "file first. You can delete the saved OS file if you want, by running this"
          echo "command:"
          echo ""
          echo "  rm \"${gc_dir_before_os_install}/gc_install_os_file_${GITCID_OS_INSTALL_ARCH}\""
          echo ""
         
          cp "${gc_dir_before_os_install}/gc_install_os_file_${GITCID_OS_INSTALL_ARCH}" .

          if [ $? -ne 0 ]; then
            echo "error: Copying OS install file failed. Not installing OS."
            return 20
          fi

        else
          echo ""
          echo "info: Retreiving the OS we will be installing, from URL:"
          echo ""
          echo "$GITCID_OS_INSTALL_LINK"
          echo ""
          echo "It might take several minutes. Please wait..."
          echo ""

          curl -sL "$GITCID_OS_INSTALL_LINK" > "gc_install_os_file_${GITCID_OS_INSTALL_ARCH}"

          if [ $? -ne 0 ]; then
            echo "error: Downloading OS install file failed. Not installing OS."
            return 20
          fi
        fi

        7z x "gc_install_os_file_${GITCID_OS_INSTALL_ARCH}"

        if [ $? -ne 0 ]; then
          echo "error: Extracting OS install file using the 7z command failed. Not installing OS."
          return 20
        fi

        for gc_os_install_target_device_mounted in $(lsblk -lpno NAME,MOUNTPOINT | grep -P "^$2[0-9]+\s+\S+$" | awk '{print $1}'); do
          umount "$gc_os_install_target_device_mounted" || \
          sudo umount "$gc_os_install_target_device_mounted" 
        
          if [ $? -ne 0 ]; then
            echo "error: Failed unmounting partition \"$gc_os_install_target_device_mounted\" on disk we wanted to install the OS onto. Not installing OS."
            return 20
          fi
        done

        lsblk -lpno NAME,MOUNTPOINT | grep -P "^$2[0-9]+\s+\S+$"

        if [ $? -eq 0 ]; then
          echo "error: The disk we wanted to install the OS onto is still mounted. It needs to be" 
          echo "unmounted first and we seem to have failed at unmounting it. Not installing OS."
          return 20
        fi

        GITCID_OS_INSTALL_IMAGE_FILE="$(ls *.img | head -n1)"

        if [ -z "$GITCID_OS_INSTALL_IMAGE_FILE" ]; then
          echo ""
          echo ""
          echo "error: Failed determining the OS install image filename to install. Not installing OS."
          echo ""
          echo "DEBUG: Files available in the current directory, which are possible install candidates:"
          echo ""
          echo "---------"
          echo ""
          echo "Directory: $PWD"
          echo "---------"
          echo ""
          ls -al
          echo ""
          echo "---------"
          echo ""
          echo "DEBUG: Please file a bug report with this portion of your log output included, if you'd"
          echo "like this OS to work."
          echo ""
          echo "DEBUG: You can file a new bug report here:"
          echo ""
          echo "  https://gitlab.com/defcronyke/gitcid/-/issues/new"
          echo ""
          echo ""
          return 20
        fi

        echo ""
        echo ""
        echo "---------"
        echo ""
        echo "Directory: $PWD"
        echo "---------"
        echo ""
        ls -al
        echo ""
        echo "---------"
        echo ""
        echo ""
        echo "info: Installing OS from disk image file:"
        echo ""
        echo "  $GITCID_OS_INSTALL_IMAGE_FILE"
        echo ""
        echo "info: Installing OS onto device (ERASING ALL CONTENTS ON IT IN THE PROCESS):"
        echo ""
        echo "  $2"
        echo ""
        echo "info: This might take several minutes. Please don't remove or mount"
        echo "the target disk."


        # Install the OS onto the target device.
        echo ""
        echo "info: Installing OS. Please wait.........."
        echo ""

        sudo dd if="$GITCID_OS_INSTALL_IMAGE_FILE" of="$2" bs=256 status=progress
        res2=$?

        if [ $res2 -eq 0 ]; then
          sync
          res=21

          echo ""
          echo "info: The OS installation appears to have succeeded! YAY!! :)"
          echo ""

          echo ""
          echo "info: Performing initial git server setup on newly installed OS..."
          echo ""

          mkdir -p tmp_os_mount_dir && \
          sudo mount "${2}1" tmp_os_mount_dir && \
          cd tmp_os_mount_dir && \
          sudo touch ssh && \
          cd .. && \
          sudo umount "${2}1"
          
          if [ $? -ne 0 ]; then
            echo ""
            echo "error: Failed inital git server setup on newly installed OS."
            echo ""
            return 20
          fi

        else
          echo ""
          echo "error: Failed installing OS. The \"dd\" command returned with error code: $res2"
          echo ""
          res=20
        fi

        if [ ! -f "${gc_dir_before_os_install}/gc_install_os_file_${GITCID_OS_INSTALL_ARCH}" ]; then
          echo ""
          echo "info: Saving OS install file for next time, at path:"
          echo ""
          echo "  \"${gc_dir_before_os_install}/gc_install_os_file_${GITCID_OS_INSTALL_ARCH}\""
          echo ""

          cp -f "gc_install_os_file_${GITCID_OS_INSTALL_ARCH}" "${gc_dir_before_os_install}/gc_install_os_file_${GITCID_OS_INSTALL_ARCH}"
        fi

        # echo ""
        # echo "Leaving temp dir: $GITCID_OS_INSTALL_TMP_DIR"
        # echo ""
        # echo "Returning to previous directory: $gc_dir_before_os_install"
        cd "$gc_dir_before_os_install"
        # echo ""

        # These checks are overkill, but I'm working on this list 
        # to use elsewhere later, so I put it here for now.
        if [ -d "$GITCID_OS_INSTALL_TMP_DIR" ]; then
          if [ ! -z "$GITCID_OS_INSTALL_TMP_DIR" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "/" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "/*" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "/home" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "$HOME" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "." ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "." ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "./" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "./*" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != ".*" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != ".." ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "../" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "../*" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "../.*" ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "../.." ] && \
            [ "$GITCID_OS_INSTALL_TMP_DIR" != "*" ]; then

            # echo "Removing temp dir: $GITCID_OS_INSTALL_TMP_DIR"
            rm -rf "$GITCID_OS_INSTALL_TMP_DIR"
            # echo ""
            
          else
            echo ""
            echo "WARNING: Something bad almost happened! We were instructed"
            echo "to delete something we shouldn't, so we didn't do it."
            echo ""
            echo "THE PATH WE ALMOST DELETED: $GITCID_OS_INSTALL_TMP_DIR"
            echo ""
          fi
        fi

        echo ""
        echo "Finished installing and configuring a new OS on the target device: $2"
        echo ""
        echo "Next, if you want to install a git server onto the device,"
        echo "put that disk in some system, boot up the system, and when"
        echo "it comes online, run the following command to install the"
        echo "git server software over ssh (Raspberry Pi OS example):"
        echo ""
        echo "  .gc/new-git-server.sh -o raspberrypi"
        echo ""

      fi
      
      return $res

    else
      echo ""
      printf "error: invalid args supplied to command: $0 $@"

      gc_new_git_server_install_cancel $@
      return $?
    fi
  fi
}

# #
# # NOTE: Moved this into a separate file: .gc/.gc-util/provision-git-server-rpi.sh
# #
# gitcid_install_new_git_server_rpi_auto_provision() {
#   gc_ssh_host="$@"

#   gc_ssh_username="pi"

#   echo ""
#   echo "NOTICE: Trying to auto-install our ssh key onto a host which is maybe a Raspberry Pi: ${gc_ssh_username}@${gc_ssh_host}"
#   echo ""

#   sshpass -p 'raspberry' scp -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 "${HOME}/.ssh/git-server.key"* ${gc_ssh_username}@${gc_ssh_host}:"/home/${gc_ssh_username}/.ssh/"
  
#   echo ""
#   echo "Activating ssh key config on host: ${gc_ssh_username}@${gc_ssh_host}"
#   { sshpass -p 'raspberry' ssh -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt ${gc_ssh_username}@${gc_ssh_host} 'mkdir -p $HOME/.ssh; chmod 700 $HOME/.ssh; touch $HOME/.ssh/config; chmod 600 $HOME/.ssh/config; touch $HOME/.ssh/authorized_keys; chmod 600 $HOME/.ssh/authorized_keys; cat $HOME/.ssh/authorized_keys | grep "$(cat $HOME/.ssh/git-server.key.pub)" >/dev/null || cat $HOME/.ssh/git-server.key.pub | tee -a $HOME/.ssh/authorized_keys >/dev/null; cat $HOME/.ssh/config | grep -P "^Host '$gc_ssh_host'$" >/dev/null || printf "%b\n" "\nHost '$gc_ssh_host'\n\tHostName '$gc_ssh_host'\n\tUser '$gc_ssh_username'\n\tIdentityFile ~/.ssh/git-server.key\n\tIdentitiesOnly yes\n" | tee -a $HOME/.ssh/config >/dev/null; ssh-keygen -F "$gc_ssh_host" || ssh-keyscan "$gc_ssh_host" | tee -a $HOME/.ssh/known_hosts >/dev/null; echo ""; echo "This seems to be a freshly installed Raspberry Pi OS device. It is required for better security that you change your user and root account passwords on this device. You will be prompted to change your passwords during an upcoming step soon."; echo ""; exit 0;'; };
#   echo ""
#   echo "Finished installing ssh key on host: ${gc_ssh_username}@${gc_ssh_host}"
#   echo ""

#   echo ""
#   echo "Finished auto-installing ssh key onto a Raspberry Pi OS host: ${gc_ssh_username}@${gc_ssh_host}"
#   echo ""
# }


gitcid_new_git_server_main() {
  tasks=( )

  trap 'for i in ${tasks[@]}; do kill $i 2>/dev/null; done; for i in $(jobs -p); do kill $i 2>/dev/null; done; gc_new_git_server_install_cancel $@ || return $?' INT

  GITCID_DIR=${GITCID_DIR:-"${PWD}/.gc/"}
	GITCID_NEW_REPO_PERMISSIONS=${GITCID_NEW_REPO_PERMISSIONS:-"0640"}

  # ----------
  # Do some minimal git config setup to make some annoying yellow warning text stop 
  # showing on newer versions of git.

  # When doing "git pull", merge by default instead of rebase.
  git config --global pull.rebase >/dev/null 2>&1 || \
  git config --global pull.rebase false >/dev/null 2>&1

  # When doing "git init", use "master" for the default branch name.
  git config --global init.defaultBranch >/dev/null 2>&1 || \
  git config --global init.defaultBranch master >/dev/null 2>&1
  # ----------

  "${GITCID_DIR}deps.sh" >/dev/null
	res_import_deps=$?
	if [ $res_import_deps -ne 0 ]; then
		gitcid_log_err "${BASH_SOURCE[0]}" $LINENO "Failed importing GitCid dependencies. I guess it's not going to work, sorry!"
		return $res_import_deps
	fi



  ####
  # --------------------  #
  # Install a new OS to a locally-connected disk if 
  # requested,by passing any of the following flags.
  #
  # WARNING: THIS WILL PERMANENTLY ERASE ANY DATA ON 
  # SPECIFIED THE DISK! IT WILL INSTALL A NEW OPERATING
  # SYSTEM ON IT, AND NOTHING WHICH WAS ON IT BEFORE
  # WILL BE RECOVERABLE! You have been warned.
  #
  # --------------------  #
  #
  # Install a new OS to a locally connected disk:
  # 
  #   ./new-git-server.sh [-r[f] | -R[f]] </path/to/device>
  #
  #   -r    Raspberry Pi OS Light armhf (32-bit)
  #
  #   -R    Raspberry Pi OS Light aarch64 (64-bit beta)
  #
  #   -rf   (WARNING: DANGEROUS!) Install Raspberry Pi OS 
  #         Light armhf, without prompting for confirmation.
  #
  #   -Rf   (WARNING: DANGEROUS!) Install Raspberry Pi OS 
  #         Light aarch64, without prompting for confirmation.
  #
  # --------------------  #
  #
  # Unsupported dangerous options for automation purposes:
  #
  #   ./new-git-server.sh [-rFf | -RFf] </path/to/device>
  #
  #   -rFf  (WARNING: VERY DANGEROUS!) Install Raspberry 
  #         Pi OS Light armhf, without any prompt and with all 
  #         failsafe delays disabled.
  #
  #   -RFf  (WARNING: VERY DANGEROUS!) Install Raspberry 
  #         Pi OS Light aarch64, without any prompt and with all 
  #         failsafe delays disabled.
  #
  # --------------------  #
  #
  if [ $# -ge 1 ]; then
    if [[ "$1" =~ ^-[Rr]F?f?$ ]]; then
      gc_new_git_server_install_os $@
      res=$?
      if [ $res -ne 0 ]; then
        if [ $res -eq 21 ]; then
          exit 0
        fi
        return $res
      fi
    fi
  fi
  # -------------------- #
  ####



  gc_new_git_server_open_web_browser=1
  gc_new_git_server_setup_sudo=1

  # ----------
  # Do some minimal git config setup to make some annoying yellow warning text stop 
  # showing on newer versions of git.

  # When doing "git pull", merge by default instead of rebase.
  git config --global pull.rebase >/dev/null 2>&1 || \
  git config --global pull.rebase false >/dev/null 2>&1

  # When doing "git init", use "master" for the default branch name.
  git config --global init.defaultBranch >/dev/null 2>&1 || \
  git config --global init.defaultBranch master >/dev/null 2>&1
  # ----------

  # last_dir="$PWD"

  # Install new SSH key for git servers to update DNS.
  start_dir="$PWD"
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  cd "${HOME}/.ssh"

  if [ ! -f "git-server.key" ]; then
    ssh-keygen -t rsa -b 4096 -q -f $HOME/.ssh/git-server.key -N "" -C git-server
    chmod 600 $HOME/.ssh/git-server.key*
  fi

  cd "${start_dir}"

  if [ $# -eq 1 ] && [ "$1" == "-h" ]; then
    shift 1
    gitcid_new_git_server_usage
    return 0

  elif [ $# -eq 0 ]; then
    gitcid_new_git_server_usage
    return 0

  elif [ $# -ge 1 ]; then
    if [ "$1" == "-s" ]; then
      shift 1
      gc_new_git_server_setup_sudo=0

    elif [ "$1" == "-y" ]; then
      shift 1
      
    elif [ "$1" == "-o" ]; then
      shift 1
      gc_new_git_server_open_web_browser=0
      gc_new_git_server_interactive $@ || \
      return $?

    elif [ "$1" == "-yo" ] || [ "$1" == "-oy" ]; then
      shift 1
      gc_new_git_server_open_web_browser=0
    
    elif [ "$1" == "-so" ] || [ "$1" == "-os" ]; then
      shift 1
      gc_new_git_server_setup_sudo=0
      gc_new_git_server_open_web_browser=0

    else
      echo "$1" | grep -P "^\-.+" >/dev/null
      if [ $? -eq 0 ]; then
        echo ""
        echo "error: Invalid arguments: $@"
        echo ""
        gitcid_new_git_server_usage $@
        return 20
      else
        if [ ! "$1" =~ ^/dev/ ]; then
          gc_new_git_server_interactive $@ || \
          return $?
        else
          echo ""
          echo "error: Invalid arguments: $@"
          echo ""
          gitcid_new_git_server_usage $@
          return 20
        fi
      fi
    fi
  fi

  echo ""
  echo ""
  echo "Installing new git server(s) at the following ssh path(s): $@"


  # Install ssh keys on servers.
  echo ""
  echo ""
  echo "Installing ssh keys if they aren't added yet."
  
  rpi_auto_res=1
  
  for j in $@; do
    gc_ssh_host="$(echo "$j" | cut -d@ -f2)"

    echo "$j" | grep "@" >/dev/null
    if [ $? -eq 0 ]; then
      gc_ssh_username="$(echo "$j" | cut -d@ -f1)"
    else
      gc_ssh_username="$(cat "${HOME}/.ssh/config" | grep -A2 -P "^Host ${gc_ssh_host}$" | tail -n1 | awk '{print $NF}')"
    fi


    if [ $gc_ssh_host == "raspberrypi" ] || ( [ $rpi_auto_res -eq 1 ] && [ -z "$gc_ssh_username" ] ); then
      echo ""
      echo "INFO: No ssh config for user found. Trying Raspberry Pi auto-config..."
      echo ""

      gc_ssh_username="pi"

      gc_ssh_host="raspberrypi"; \
      sed -i "/^${gc_ssh_host}\s.*$/d" "${HOME}/.ssh/known_hosts"; \
      sed -i '/^$/d' "${HOME}/.ssh/known_hosts"

      echo ""
      echo "Adding git-server key to local ssh config: \"${HOME}/.ssh/git-server.key\" >> \"${HOME}/.ssh/config\""
      cat "${HOME}/.ssh/config" | grep -P "^Host $gc_ssh_host" >/dev/null || printf "%b\n" "\nHost ${gc_ssh_host}\n\tHostName ${gc_ssh_host}\n\tUser ${gc_ssh_username}\n\tIdentityFile ~/.ssh/git-server.key\n\tIdentitiesOnly yes\n" | tee -a "${HOME}/.ssh/config" >/dev/null
      echo ""
      echo "Added key to local \"${HOME}/.ssh/config\" for host: ${gc_ssh_username}@${gc_ssh_host}"


      echo ""
      echo "Verifying host: $gc_ssh_host"
      echo ""

      ssh-keygen -F "$gc_ssh_host" || ssh-keyscan "$gc_ssh_host" | tee -a "${HOME}/.ssh/known_hosts" >/dev/null


      ${GITCID_DIR}.gc-util/provision-git-server-rpi.sh "$gc_ssh_host"
      rpi_auto_res=$?

      # gitcid_install_new_git_server_rpi_auto_provision "$gc_ssh_host"

      # gc_ssh_username="$USER"
    fi

    if [ $rpi_auto_res -ne 0 ]; then
      gc_ssh_host="$(echo "$j" | cut -d@ -f2)"

      echo "$j" | grep "@" >/dev/null
      if [ $? -eq 0 ]; then
        gc_ssh_username="$(echo "$j" | cut -d@ -f1)"
      else
        gc_ssh_username="$(cat "${HOME}/.ssh/config" | grep -A2 -P "^Host ${gc_ssh_host}$" | tail -n1 | awk '{print $NF}')"
      fi

      if [ -z "$gc_ssh_username" ]; then
        gc_ssh_username="$USER"
      fi

      
      echo ""
      echo "Adding git-server key to local ssh config: \"${HOME}/.ssh/git-server.key\" >> \"${HOME}/.ssh/config\""
      cat "${HOME}/.ssh/config" | grep -P "^Host $gc_ssh_host" >/dev/null || printf "%b\n" "\nHost ${gc_ssh_host}\n\tHostName ${gc_ssh_host}\n\tUser ${gc_ssh_username}\n\tIdentityFile ~/.ssh/git-server.key\n\tIdentitiesOnly yes\n" | tee -a "${HOME}/.ssh/config" >/dev/null
      echo ""
      echo "Added key to local \"${HOME}/.ssh/config\" for host: ${gc_ssh_username}@${gc_ssh_host}"
      
      echo ""
      echo "Verifying host: $gc_ssh_host"
      ssh-keygen -F "$gc_ssh_host" || ssh-keyscan "$gc_ssh_host" | tee -a "${HOME}/.ssh/known_hosts" >/dev/null
      
      # echo ""
      # echo "Verifying host: $gc_ssh_host"
      # ssh-keygen -F "$gc_ssh_host" || ssh-keyscan "$gc_ssh_host" | tee -a "${HOME}/.ssh/known_hosts" >/dev/null

      echo ""
      echo "Pre-activating ssh key config on host: ${gc_ssh_username}@${gc_ssh_host}"
      { { ssh -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt ${gc_ssh_username}@${gc_ssh_host} 'mkdir -p $HOME/.ssh; chmod 700 $HOME/.ssh; touch $HOME/.ssh/config; chmod 600 $HOME/.ssh/config; touch $HOME/.ssh/authorized_keys; chmod 600 $HOME/.ssh/authorized_keys; echo ""; echo "Creating .ssh/ directory and files."; echo ""; exit 0;'; }; }
      echo ""

      echo ""
      echo "Installing ssh key onto host: ${gc_ssh_username}@${gc_ssh_host}"

      scp -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 "${HOME}/.ssh/git-server.key"* ${gc_ssh_username}@${gc_ssh_host}:"/home/${gc_ssh_username}/.ssh/"
      
      echo ""
      echo "Activating ssh key config on host: ${gc_ssh_username}@${gc_ssh_host}"
      { { ssh -o IdentitiesOnly=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt ${gc_ssh_username}@${gc_ssh_host} 'mkdir -p $HOME/.ssh; chmod 700 $HOME/.ssh; touch $HOME/.ssh/config; chmod 600 $HOME/.ssh/config; touch $HOME/.ssh/authorized_keys; chmod 600 $HOME/.ssh/authorized_keys; cat $HOME/.ssh/authorized_keys | grep "$(cat $HOME/.ssh/git-server.key.pub)" >/dev/null || cat $HOME/.ssh/git-server.key.pub | tee -a $HOME/.ssh/authorized_keys >/dev/null; cat $HOME/.ssh/config | grep -P "^Host '${gc_ssh_host}'$" >/dev/null || printf "%b\n" "\nHost '${gc_ssh_host}'\n\tHostName '${gc_ssh_host}'\n\tUser '${gc_ssh_username}'\n\tIdentityFile ~/.ssh/git-server.key\n\tIdentitiesOnly yes\n" | tee -a $HOME/.ssh/config >/dev/null; ssh-keygen -F "$gc_ssh_host" || ssh-keyscan "$gc_ssh_host" | tee -a $HOME/.ssh/known_hosts >/dev/null; exit 0;'; }; }
      echo ""
      echo "Finished installing ssh key on host: ${gc_ssh_username}@${gc_ssh_host}"
      echo ""
    fi
  done

  echo "Finished installing ssh keys on hosts."
  echo ""
  echo ""

  for j in $@; do
    gc_ssh_host="$(echo "$j" | cut -d@ -f2)"

    echo "$j" | grep "@" >/dev/null
    if [ $? -eq 0 ]; then
      gc_ssh_username="$(echo "$j" | cut -d@ -f1)"
    else
      gc_ssh_username="$(cat "${HOME}/.ssh/config" | grep -A2 -P "^Host ${gc_ssh_host}$" | tail -n1 | awk '{print $NF}')"
    fi

    if [ -z "$gc_ssh_username" ]; then
      echo ""
      echo "INFO: No ssh config for user found. Trying Raspberry Pi auto-config..."
      echo ""

      ${GITCID_DIR}.gc-util/provision-git-server-rpi.sh "$gc_ssh_host"

      # gc_ssh_username="$USER"
    fi

    # gc_ssh_username="$(cat "${HOME}/.ssh/config" | grep -A2 -P "^Host ${gc_ssh_host}$" | tail -n1 | awk '{print $NF}')"

    # if [ -z "$gc_ssh_username" ]; then
    #   gc_ssh_username="$USER"
    # fi

    loop_res=22
    loop_res2=21
    if [ $gc_new_git_server_setup_sudo -eq 0 ]; then
      echo ""
      echo "NOTICE: Sequential mode: $0 -s $@"
      echo ""
      echo "NOTICE: Installing git server on host: ${gc_ssh_username}@${gc_ssh_host}"
      echo ""
      { bash -c "{ ssh -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt ${gc_ssh_username}@${gc_ssh_host} 'echo \"\"; echo \"-----\"; echo \"  hostname: $(hostname)\"; echo \"  user: $USER\"; echo \"-----\"; bash <(curl -sL https://tinyurl.com/git-server-init) -s; exit $?;'; loop_res=22; exit $loop_res; }"; loop_res=$?; }
      loop_res=$?
      # loop_res=22

      echo ""
    else
      echo ""
      echo "NOTICE: Parallel mode: $0 $@"
      echo ""
      echo "NOTICE: Installing git server on host: ${gc_ssh_username}@${gc_ssh_host}"
      echo ""
      echo "info: For sequential mode, use this command instead: $0 -s $@"
      echo ""
      echo "info: You need to use sequential mode the first time, to set up passwordless sudo so that parallel mode can work properly."
      echo ""
      { bash -c "{ ssh -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt ${gc_ssh_username}@${gc_ssh_host} 'alias sudo=\"sudo -n\"; echo \"\"; echo \"-----\"; echo \"  hostname: $(hostname)\"; echo \"  user: $USER\"; echo \"-----\"; bash <(curl -sL https://tinyurl.com/git-server-init); exit $?;'; loop_res2=21; exit $loop_res2; }"; loop_res2=$?; } & tasks+=( $! )
      # { bash -c "{ ssh -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt ${gc_ssh_username}@${gc_ssh_host} 'alias sudo=\"sudo -n\"; echo \"\"; echo \"-----\"; echo \"  hostname: $(hostname)\"; echo \"  user: $USER\"; echo \"-----\"; bash <(curl -sL https://tinyurl.com/git-server-init); exit $?;'; loop_res2=$?; }"; loop_res2=$?; } & tasks+=( $! )
      # { ssh -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 -o ConnectionAttempts=2 -tt ${gc_ssh_username}@${gc_ssh_host} 'alias sudo="sudo -n"; echo ""; echo "-----"; echo "  hostname: $(hostname)"; echo "  user: $USER"; echo "-----"; source <(curl -sL https://tinyurl.com/git-server-init); exit $?'; exit $?; } & tasks+=( $! )
    fi
  done

  echo "Finished iterating over hosts."

  gitcid_retry_install_git_server=1
  
  if [ $gc_new_git_server_setup_sudo -ne 0 ]; then
    echo "Entering job wait loop..."

    for i in ${tasks[@]}; do
      gitcid_retry_install_git_server2=1

      echo "Job wait loop iteration for task: $i"

      if [ -z "$(jobs -p)" ]; then
        echo "No more jobs at beginning of loop for task: $i"
        
        echo ""
        echo "Detecting git servers..."
        echo ""

        new_git_server_detect_other_git_servers $@
        if [ $? -ne 0 ] && [ $gitcid_retry_install_git_server2 -eq 1 ]; then
          echo ""
          echo "No git servers detected. Trying install one more time. It will probably work this time..."
          echo ""

          gitcid_retry_install_git_server2=0
          
          gitcid_new_git_server_main $@; loop_res2=$?
        fi

        return $loop_res2
      fi

      wait $i
      loop_res2=$?

      if [ $loop_res2 -eq 255 ]; then
        echo "error: Failed connecting with ssh to host in job wait loop. Error code: $loop_res2"
        continue

      elif [ $loop_res2 -ne 0 ]; then
        echo "error: Job wait loop ending with error code: $loop_res2"
        return $loop_res2
      fi

      if [ -z "$(jobs -p)" ]; then
        echo "No more jobs at end of loop for task: $i"

        echo ""
        echo "Detecting git servers..."
        echo ""

        new_git_server_detect_other_git_servers $@
        if [ $? -ne 0 ] && [ $gitcid_retry_install_git_server2 -eq 1 ]; then
          echo ""
          echo "No git servers detected. Trying install one more time. It will probably work this time..."
          echo ""

          gitcid_retry_install_git_server2=0
          
          gitcid_new_git_server_main $@; loop_res2=$?
        fi

        return $loop_res2
      fi
    done

    echo ""
    echo "Detecting git servers after job wait loop..."
    echo ""

    new_git_server_detect_other_git_servers $@
    if [ $? -ne 0 ] && [ $gitcid_retry_install_git_server -eq 1 ]; then
      echo ""
      echo "No git servers detected. Trying install one more time. It will probably work this time..."
      echo ""

      gitcid_retry_install_git_server=0
      
      gitcid_new_git_server_main $@; loop_res2=$?
    fi

    return $loop_res2
  fi

  # current_dir="$PWD"
  # cd ../discover-git-server-dns
  # # git fetch --all
  # git pull
  # ./git-update-srv.sh $@
  # cd "$current_dir"

  echo ""
  echo "Detecting git servers..."
  echo ""

  new_git_server_detect_other_git_servers $@
  if [ $? -ne 0 ] && [ $gitcid_retry_install_git_server -eq 1 ]; then
    echo ""
    echo "No git servers detected. Trying install one more time. It will probably work this time..."
    echo ""

    gitcid_retry_install_git_server=0
    
    gitcid_new_git_server_main $@; loop_res=$?
  fi

  # || \
  #   return $?

  return $loop_res
  # return 0
}

gitcid_new_git_server_main $@; res=$?

if [ $res -ne 0 ]; then
  # If cancelled.
  if [ $res -eq 20 ]; then
    exit $res
  fi

  gitcid_new_git_server_post $@; res2=$?
  if [ $res -eq 20 ]; then
    exit $res2
  fi

  new_git_server_detect_other_git_servers $@ 
  exit $res2
  # || \
    # exit $?
fi

# if [ $res -ne 20 ]; then
#   # Run the install a second time to make sure each
#   # stage has succeeded. Only really needed because
#   # Docker isn't usable immediately after installing 
#   # it.
#   gitcid_new_git_server_main $@; res=$?
# fi

exit $res

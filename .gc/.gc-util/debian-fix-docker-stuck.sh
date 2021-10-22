#!/bin/bash
# Fix docker getting stuck sometimes after install on Debian.
#
# TODO: Need to add a fix for Raspberry Pi Zero W, similar to:
#
#   sudo apt-get remove -y --purge docker-ce* container.io*; curl https://get.docker.com | sh
#

gitcid_debian_fix_docker_stuck() {
 
  docker ps >/dev/null 2>&1

  if [ $? -ne 0 ]; then
    sudo groupadd docker 2>/dev/null || true
    sudo gpasswd -a $USER docker 2>/dev/null || true

    # Skip everything in here if we're in Windows WSL2
    # because Docker works differently on Windows.
    uname -a | grep "microsoft" >/dev/null
    if [ $? -eq 0 ]; then
      echo ""
      echo ""
      echo "NOTICE: You appear to be on Windows ( maybe WSL2 ? ), and Docker isn't running."
      echo "For CI/CD features to work, you'll need to start Docker first on your own."
      echo ""
      echo ""
      # return 28
      return 0
    fi




    sudo systemctl disable docker
    sudo systemctl stop docker

    for i in `ps aux | grep /usr/bin/dockerd | awk '{print $2}'`; do sudo kill $i; done
    for i in `ps aux | grep /usr/bin/dockerd | awk '{print $2}'`; do sudo kill -9 $i; done

    sudo rm /var/run/docker.pid
    sudo rm /run/docker.pid

    sudo mv /usr/bin/docker "${HOME}/docker.orig.broken"
    sudo mv /bin/docker "${HOME}/docker.orig2.broken"
    sudo mv /usr/local/bin/docker "${HOME}/docker.orig3.broken"


    echo ""
    echo "info: Poking docker in case maybe it's stuck. Starting dockerd..."
    echo ""
    echo "info: Add network interface \"docker0\", since maybe it's missing for some reason..."
    echo ""
    sudo ip link add name docker0 type bridge
    sudo ip addr add dev docker0 172.17.0.1/16


    { bash -c 'curl https://get.docker.com | sh'; }
    # { bash -c 'curl https://get.docker.com | sh' || bash -c 'curl https://get.docker.com | sh'; }


    docker ps >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      return 0
    fi

    echo "NOTICE: Docker doesn't seem to be working."
    
    # echo "It's probably because Docker was newly installed on some system"
    # echo "which requries a reboot after Docker is first installed. We will reboot now. Please run the same command"
    # echo "again once we're back up."

    # sudo reboot

    # return 23

    # echo ""
    # echo "info: Poking docker in case maybe it's stuck. Starting dockerd..."
    # echo ""
    # echo "info: Add network interface \"docker0\", since maybe it's missing for some reason..."
    # echo ""
    # sudo ip link add name docker0 type bridge
    # sudo ip addr add dev docker0 172.17.0.1/16
    echo ""
    echo "Removing docker pid..."
    sudo systemctl stop docker
    for i in `ps aux | grep /usr/bin/dockerd | awk '{print $2}'`; do sudo kill $i; done
    sudo rm /var/run/docker.pid
    echo ""
    sudo /usr/bin/dockerd -H unix:// --containerd=/run/containerd/containerd.sock >/dev/null &
    DOCKERD_TMP_PID=$!
    echo "info: waiting 4 seconds..."
    sleep 4
    echo ""
    echo "info: Stopping dockerd..."
    echo ""
    sudo kill $DOCKERD_TMP_PID
    echo ""
    echo "waiting again, 3 seconds..."
    sleep 3
    echo ""
    echo "trying to restart docker..."
    echo ""

    sudo systemctl restart docker

    if [ $? -ne 0 ]; then
      echo ""
      echo "NOTICE: Docker is being mean. Probably the only way to make it work now"
      echo "is to reboot, since we tried lots of other things and nothing else worked so far. :("
      echo ""
      echo "Rebooting now. Please wait..."
      echo ""

      sudo reboot

      return 24

      # echo "error: Docker is being mean. It still didn't start after that? Okay checking if maybe we are running on an older model of arm chip, such as armv6..."
      # uname -a | grep armv6
      # if [ $? -eq 0 ]; then
      #   echo ""
      #   echo "error: Yes, this is an armv6 type of chip. We should be able to get docker installed and running by another method then. Trying:"
      #   echo ""
      #   echo "sudo apt-get remove -y --purge docker-ce* container.io*; curl https://get.docker.com | sh"
      #   echo ""
      #   sudo apt-get remove -y --purge docker-ce* container.io*; curl https://get.docker.com | sh
      #   echo ""
      # fi
    fi
  #   echo ""
  #   docker ps >/dev/null 2>&1
  #   if [ $? -ne 0 ]; then
  #     echo ""
  #     echo "error: Docker basic usage failed, but maybe it's installed properly by now and you just have to log out and log back in to gain Docker use privileges."
  #     echo ""
  #     echo "Please run whatever previous command lead to you seeing this message again, and it will hopefully work next time. Sorry for the inconvenience, Docker is a bit weird on some platforms."
  #     echo ""
  #   fi
  #   echo ""

    
    return 23

  fi

  return 23
}

gitcid_debian_fix_docker_stuck

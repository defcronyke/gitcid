#!/bin/bash
# Install Docker on Debian-like OS aarch64 
# (for example Raspberry Pi OS 64-bit)

gitcid_debian_install_docker_aarch64() {
  GITCID_ARCH=`uname -m`

  which docker >/dev/null 2>&1
  GITCID_HAS_DOCKER=$?
  if [ $GITCID_HAS_DOCKER -eq 0 ]; then
    echo "info: Not installing Docker because the docker command was already found in your \$PATH."
  return 1
  fi

  which apt-get >/dev/null 2>&1
  GITCID_HAS_APT_GET=$?
  if [ $GITCID_HAS_APT_GET -ne 0 ]; then
    echo "info: Not installing Docker aarch64 Debian package because we didn't find apt-get, so this probably isn't a Debian-like distro."
    return 2
  fi

  if [ "$GITCID_ARCH" != "aarch64" ]; then
    echo "info: Not installing Docker aarch64 Debian package because we detected a different architecture."
    return 3
  fi

  sudo apt-get update && \
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release && \
  curl -fsSL https://download.docker.com/linux/debian/gpg > tmp-key.txt && \
  cat tmp-key.txt | \
  sudo gpg --no-tty --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
  rm tmp-key.txt && \
  echo "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
  sudo apt-get update && \
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io && \
  sudo gpasswd -a $USER docker
}

gitcid_debian_install_docker_aarch64 "$@"

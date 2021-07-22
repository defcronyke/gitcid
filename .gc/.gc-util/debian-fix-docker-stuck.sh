#!/bin/bash
# Fix docker getting stuck sometimes after install on Debian.

gitcid_debian_fix_docker_stuck() {
  docker ps 2>/dev/null
  if [ $? -ne 0 ]; then
    echo ""
    echo "info: Poking docker in case maybe it's stuck. Starting dockerd..."
    echo ""
    sudo /usr/bin/dockerd -H unix:// --containerd=/run/containerd/containerd.sock >/dev/null &
    DOCKERD_TMP_PID=$!
    echo "info: waiting 4 seconds..."
    sleep 4
    echo ""
    echo "info: Stopping dockerd..."
    echo ""
    kill $DOCKERD_TMP_PID
    echo ""
    echo "waiting again, 3 seconds..."
    sleep 3
    echo ""
    echo "trying to restart docker..."
    echo ""
    sudo systemctl restart docker && \
    echo "docker restart success! yay, it's fixed!"
    echo ""
    docker ps
    echo ""
  fi
}

gitcid_debian_fix_docker_stuck

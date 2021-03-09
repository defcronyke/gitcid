#!/usr/bin/env bash

pwd="$PWD"
cd "$(dirname "${BASH_SOURCE[0]}")"

docker network create docker-compose-net --subnet 10.0.1.0/24 2>/dev/null

docker-compose up $@
docker-compose down $@

cd "$PWD"

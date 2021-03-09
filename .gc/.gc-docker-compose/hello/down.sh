#!/usr/bin/env bash

pwd="$PWD"
cd "$(dirname "${BASH_SOURCE[0]}")"

docker-compose down $@

cd "$PWD"

#!/usr/bin/env bash

# Kill all background jobs.
for i in $(jobs -p); do kill $i 2>/dev/null; done

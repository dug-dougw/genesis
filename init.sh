#!/usr/bin/env bash

# Install a pre-compiled binary of "just" into /tmp directory
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /tmp
echo 'Now run "/tmp/just install'

#!/usr/bin/env bash

set -e

apt update -yq
DEBIAN_FRONTEND=noninteractive \
apt install -yq \
  just

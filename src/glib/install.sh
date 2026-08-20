#!/usr/bin/env bash

set -e

function check_option() {
    var="$1"
    opt_name="$2"

    if [ -z "$var" ]; then
        echo "Please pass the \"${opt_name}\" option to the \"glib\" feature" >&2
        exit 1
    fi
}

function boolean_to_feature() {
    result=$1

    if [ "$result" = "true" ]; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

check_option "$GLIBVERSION" "libVersion"
check_option "$BUILDTYPE" "buildType"
check_option "$INTROSPECTION" "introspection"

apt update -yq
DEBIAN_FRONTEND=noninteractive \
apt install -yq \
  git \
  build-essential \
  ninja-build \
  pkg-config \
  python3 \
  python3-pip \
  python3-packaging \
  python3-gi \
  gobject-introspection \
  libatomic1 \
  libunwind-dev

python3 -m pip install --break-system-packages 'setuptools==68.1.2'

mkdir -p /usr/src
cd /usr/src

REPO_URL="https://gitlab.gnome.org/GNOME/glib.git"
git clone $REPO_URL \
  --depth 1 --single-branch --branch \
  $GLIBVERSION glib

cd glib
meson setup builddir \
  --prefix=/usr \
  --buildtype="$BUILDTYPE" \
  -Dsysprof=enabled \
  -Dtests=false \
  -Dnls=disabled \
  -Dglib_debug=enabled \
  -Dglib_assert=true \
  -Dglib_checks=true \
  -Dintrospection=$(boolean_to_feature "$INTROSPECTION") \
  $EXTRAARGS

meson compile -C builddir
meson install -C builddir

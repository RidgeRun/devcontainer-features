#!/usr/bin/env bash

set -e

function check_option() {
    var="$1"
    opt_name="$2"

    if [ -z "$var" ]; then
        echo "Please pass the \"${opt_name}\" option to the \"gstreamer\" feature" >&2
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

check_option "$GSTVERSION" "gstVersion"
check_option "$BUILDGLIB" "buildGlib"
check_option "$BUILDTYPE" "buildType"
check_option "$TESTS" "tests"
check_option "$DOCS" "docs"
check_option "$EXAMPLES" "examples"
check_option "$GPL" "gpl"
check_option "$INTROSPECTION" "introspection"

apt update -yq
DEBIAN_FRONTEND=noninteractive \
apt install -yq \
  git \
  build-essential \
  ninja-build \
  bison \
  flex \
  pkg-config \
  libatomic1 \
  libunwind-dev \
  libdw-dev \
  libpython3-dev \
  libxml2-dev \
  libsysprof-capture-4-dev \
  bash-completion \
  python3-pip \
  python3-gi \
  gobject-introspection \
  libgirepository1.0-dev

python3 -m pip install --break-system-packages 'setuptools==68.1.2'

mkdir -p /usr/src
cd /usr/src

GST_REPO_URL="https://gitlab.com/gstreamer/gstreamer.git"
git clone $GST_REPO_URL \
  --depth 1 --single-branch --branch \
  $GSTVERSION

cd gstreamer
FALLBACK_ARGS=""
if [ "$BUILDGLIB" = "true" ]; then
  FALLBACK_ARGS="--force-fallback-for=glib"
fi

meson setup builddir \
  --prefix=/usr \
  --buildtype="$BUILDTYPE" \
  -Dnls=disabled \
  -Dexamples=`boolean_to_feature $EXAMPLES` \
  -Dtests=`boolean_to_feature $TESTS` \
  -Dgpl=`boolean_to_feature $GPL` \
  -Ddoc=`boolean_to_feature $DOCS` \
  -Dintrospection=`boolean_to_feature $INTROSPECTION` \
  -Dgstreamer:libunwind=enabled \
  -Dgstreamer:libdw=enabled \
  -Dgstreamer:bash-completion=enabled \
  $FALLBACK_ARGS \
  $EXTRAARGS

meson compile -C builddir
meson install -C builddir

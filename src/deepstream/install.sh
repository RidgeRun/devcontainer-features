#!/usr/bin/env bash
set -euo pipefail

readonly DEEPSTREAM_REPOSITORY="https://github.com/NVIDIA/DeepStream.git"
readonly DRY_RUN="${DEEPSTREAM_DRY_RUN:-0}"

function die() {
    echo "deepstream: $*" >&2
    exit 1
}

function check_option() {
    local var="$1"
    local opt_name="$2"

    if [ -z "$var" ]; then
        echo "Please pass the \"${opt_name}\" option to the \"deepstream\" feature" >&2
        exit 1
    fi
}

DSVERSION="${DSVERSION:-}"
PLATFORM="${PLATFORM:-}"
CUDAVERSION="${CUDAVERSION:-}"

check_option "$DSVERSION" "dsVersion"
check_option "$PLATFORM" "platform"
check_option "$CUDAVERSION" "cudaVersion"

if [[ "$DSVERSION" == "latest" ]]; then
    DS_MAJOR="9"
    DS_GIT_REF="main"
elif [[ "$DSVERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
    DS_MAJOR="${DSVERSION%%.*}"
    DS_GIT_REF="v${DSVERSION}.0"
else
    die "dsVersion must be latest or use the major.minor format (for example, 7.1 or 9.1)"
fi
case "$DS_MAJOR" in
    9)
        DS_BUILD_PLATFORM=""
        ;;
    6|7|8)
        if [[ "$DSVERSION" != "6.3" && "$DSVERSION" != "6.4" && \
            "$DSVERSION" != "7.0" && "$DSVERSION" != "7.1" && \
            "$DSVERSION" != "8.0" ]]; then
            die "unsupported legacy DeepStream version: $DSVERSION (supported: 6.3, 6.4, 7.0, 7.1, 8.0)"
        fi
        ;;
    *)
        die "unsupported DeepStream major version: $DS_MAJOR (supported: 6.x, 7.x, and 9.x as documented)"
        ;;
esac

case "$PLATFORM" in
    x86_64)
        DS_BUILD_PLATFORM="x86"
        ;;
    jetson)
        DS_BUILD_PLATFORM="aarch64"
        ;;
    sbsa)
        if [[ "$DS_MAJOR" -lt 9 ]]; then
            die "platform sbsa is supported only for DeepStream 9.x and newer"
        fi
        DS_BUILD_PLATFORM="sbsa"
        ;;
    *)
        die "unsupported platform: $PLATFORM (supported: x86_64, jetson, sbsa)"
        ;;
esac

function validate_ds9_runtime() {
    local architecture
    local tegra_release

    if [[ "$DRY_RUN" == "1" ]]; then
        architecture="${DEEPSTREAM_DRY_RUN_ARCH:-$(uname -m)}"
        tegra_release="${DEEPSTREAM_DRY_RUN_TEGRA_RELEASE:-auto}"
    else
        architecture="$(uname -m)"
        if [[ -f /etc/nv_tegra_release ]]; then
            tegra_release="present"
        else
            tegra_release="absent"
        fi
    fi

    case "$PLATFORM" in
        x86_64)
            [[ "$architecture" == "x86_64" ]] || \
                die "platform x86_64 requires an x86_64 container (detected: $architecture)"
            ;;
        jetson)
            [[ "$architecture" == "aarch64" && "$tegra_release" != "absent" ]] || \
                die "platform jetson requires an aarch64 Jetson container with /etc/nv_tegra_release"
            ;;
        sbsa)
            [[ "$architecture" == "aarch64" && "$tegra_release" == "absent" ]] || \
                die "platform sbsa requires an aarch64 SBSA container without /etc/nv_tegra_release"
            ;;
    esac
}

function validate_ds9_os() {
    local os_id=""
    local os_version=""

    if [[ "$DRY_RUN" == "1" ]]; then
        os_id="${DEEPSTREAM_DRY_RUN_OS_ID:-ubuntu}"
        os_version="${DEEPSTREAM_DRY_RUN_OS_VERSION:-24.04}"
    elif [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        os_id="${ID:-}"
        os_version="${VERSION_ID:-}"
    fi

    [[ "$os_id" == "ubuntu" && "$os_version" == "24.04" ]] || \
        die "DeepStream 9.x builds require Ubuntu 24.04 (detected: ${os_id:-unknown} ${os_version:-unknown})"
}

function print_dry_run() {
    if [[ "$DS_MAJOR" == "9" ]]; then
        validate_ds9_os
        validate_ds9_runtime
        echo "DRY RUN: GitHub monorepo flow for DeepStream $DSVERSION (platform=$PLATFORM, build-platform=$DS_BUILD_PLATFORM)"
        echo "DRY RUN: CFLAGS=-ggdb3 -O0 CXXFLAGS=-ggdb3 -O0"
        echo "DRY RUN: git clone --branch $DS_GIT_REF --recurse-submodules $DEEPSTREAM_REPOSITORY"
        if [[ "$DSVERSION" == "latest" ]]; then
            echo "DRY RUN: CUDA_VER=$CUDAVERSION bash build/build.sh"
        else
            echo "DRY RUN: CUDA_VER=$CUDAVERSION NVDS_VERSION=$DSVERSION bash build/build.sh"
        fi
    else
        echo "DRY RUN: legacy NGC tarball flow for DeepStream $DSVERSION on $PLATFORM"
        echo "DRY RUN: deepstream_sdk_v${DSVERSION}.0_${PLATFORM}.tbz2"
    fi
}

if [[ "$DRY_RUN" == "1" ]]; then
    print_dry_run
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

apt update -yq
apt install -yq \
    curl \
    wget \
    cmake \
    git-lfs \
    libssl3 \
    libssl-dev \
    libgles2-mesa-dev \
    libjansson-dev \
    libyaml-cpp-dev \
    libjsoncpp-dev \
    libopencv-dev \
    protobuf-compiler \
    gcc \
    make \
    git \
    python3 \
    librabbitmq-dev \
    libhiredis-dev \
    libavahi-compat-libdnssd1

export CFLAGS="${CFLAGS:+$CFLAGS }-ggdb3 -O0"
export CXXFLAGS="${CXXFLAGS:+$CXXFLAGS }-ggdb3 -O0"
export CPPFLAGS="${CPPFLAGS:+$CPPFLAGS }-I/usr/include/opencv4"
export CUDA_VER="$CUDAVERSION"

# The legacy DeepStream Makefiles expect the Debian OpenCV headers at the
# /usr/local/include/opencv4 path, while libopencv-dev installs them under
# /usr/include/opencv4.
install -d /usr/local/include
ln -sfn /usr/include/opencv4 /usr/local/include/opencv4

function prepare_legacy_cuda_layout() {
    local cuda_root="/usr/local/cuda-${CUDAVERSION}"
    local cuda_header="${cuda_root}/include/cuda_runtime.h"
    local target_header=""

    if [[ -f "$cuda_header" ]]; then
        return
    fi

    target_header="$(find "$cuda_root/targets" -path '*/include/cuda_runtime.h' -print -quit 2>/dev/null || true)"
    if [[ -n "$target_header" && ! -e "$cuda_root/include" ]]; then
        ln -s "$(dirname "$target_header")" "$cuda_root/include"
    fi

    [[ -f "$cuda_header" ]] || \
        die "CUDA headers not found under $cuda_root/include; verify cudaVersion matches the base image"
}

BUILD_DIR="$(mktemp -d -t deepstream-build.XXXXXX)"
function cleanup() {
    rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

function build_legacy() {
    local target="deepstream_sdk_v${DSVERSION}.0_${PLATFORM}.tbz2"
    local url="https://api.ngc.nvidia.com/v2/resources/org/nvidia/deepstream/${DSVERSION}/files?redirect=true&path=${target}"

    prepare_legacy_cuda_layout

    curl -L "$url" -o "$BUILD_DIR/$target"
    tar -xvf "$BUILD_DIR/$target" -C /

    function build_current_dir() {
        local makefile
        while IFS= read -r -d '' makefile; do
            if [[ "$makefile" == */gst-nvdsudp/Makefile ]]; then
                echo "Skipping gst-nvdsudp Rivermax plugin"
                continue
            fi
            if [[ "$makefile" == */gst-dsexample/Makefile || \
                "$makefile" == */gst-dsexample-cuda/Makefile ]]; then
                echo "Skipping dsexample CUDA/OpenCV plugin (requires CUDA-enabled OpenCV)"
                continue
            fi
            (
                cd "$(dirname "$makefile")"
                make
                make install || true # some folders do not have an install target
            )
        done < <(find . -name "Makefile" -print0)
    }

    cd /opt/nvidia/deepstream/deepstream/sources/gst-plugins
    build_current_dir

    cd /opt/nvidia/deepstream/deepstream/sources/libs
    build_current_dir

    cd /opt/nvidia/deepstream/deepstream/sources/apps
    build_current_dir

    cd /opt/nvidia/deepstream/deepstream/
    ./install.sh
}

function build_ds9() {
    validate_ds9_os
    validate_ds9_runtime

    if ! git clone \
        --depth 1 \
        --branch "$DS_GIT_REF" \
        --recurse-submodules \
        "$DEEPSTREAM_REPOSITORY" \
        "$BUILD_DIR/DeepStream"; then
        die "unable to clone DeepStream ref $DS_GIT_REF; verify that the requested version is published"
    fi

    cd "$BUILD_DIR/DeepStream"
    if [[ "$DSVERSION" == "latest" ]]; then
        CUDA_VER="$CUDAVERSION" bash build/build.sh
    else
        CUDA_VER="$CUDAVERSION" NVDS_VERSION="$DSVERSION" bash build/build.sh
    fi
}

if [[ "$DS_MAJOR" == "9" ]]; then
    build_ds9
else
    build_legacy
fi

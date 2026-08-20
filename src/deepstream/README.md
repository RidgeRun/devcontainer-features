
# NVIDIA DeepStream (deepstream)

Add NVIDIA DeepStream to a devcontainer, built from source

## Example Usage

```json
"features": {
    "ghcr.io/ridgerun/devcontainer-features/deepstream:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| dsVersion | DeepStream version. Use latest to build NVIDIA's current main branch; legacy support is provided for 6.3–8.0 and 9.x versions use NVIDIA's GitHub monorepo build. | string | 7.1 |
| platform | Target platform. sbsa is supported only for DeepStream 9.x and newer. | string | x86_64 |
| cudaVersion | - | string | 12.8 |

## Compatibility

This feature builds shared libraries for NVIDIA DeepStream and is only useful for devcontainers that run on a host machine with an NVIDIA GPU. Within your devcontainer, use the `nvidia-smi` command to ensure that your GPU is available for CUDA.

> An image with CUDA and TensorRT is required for this feature.

DeepStream 9.x uses NVIDIA's GitHub monorepo build and requires Ubuntu 24.04.
The `sbsa` platform is supported only for DeepStream 9.x and newer. Legacy
DeepStream 6.3–8.0 use the NGC SDK tarball and support `x86_64` and `jetson`.

Set `dsVersion` to `latest` to clone NVIDIA's current `main` branch. The
upstream build script selects the current SDK version for that branch.

## Build examples

### Legacy DeepStream 7.1

DeepStream 6.3–8.0 is downloaded from NVIDIA NGC and built from the SDK's
legacy Makefiles.

```json
"ghcr.io/ridgerun/devcontainer-features/deepstream:0": {
    "dsVersion": "7.1",
    "platform": "x86_64",
    "cudaVersion": "12.8"
}
```

### DeepStream 9.1 on x86_64

DeepStream 9.x is cloned from NVIDIA's GitHub monorepo and built with its
official `build/build.sh` flow. The build script also installs the matching
proprietary runtime assets.

```json
"ghcr.io/ridgerun/devcontainer-features/deepstream:0": {
    "dsVersion": "9.1",
    "platform": "x86_64",
    "cudaVersion": "13.2"
}
```

### DeepStream 9.x on SBSA

Use `sbsa` for a DeepStream 9.x SBSA container. NVIDIA's build flow detects
SBSA from the container architecture and does not install bare-metal SDK
artifacts; use an NVIDIA DeepStream SBSA image with the runtime already
present.

```json
"ghcr.io/ridgerun/devcontainer-features/deepstream:0": {
    "dsVersion": "9.1",
    "platform": "sbsa",
    "cudaVersion": "13.2"
}
```

### Latest DeepStream development build

Use `latest` when you want the current NVIDIA DeepStream `main` branch rather
than a pinned release tag.

```json
"ghcr.io/ridgerun/devcontainer-features/deepstream:0": {
    "dsVersion": "latest",
    "platform": "x86_64",
    "cudaVersion": "13.2"
}
```

For example, `nvcr.io/nvidia/tensorrt:25.03-py3` from NVIDIA NGC is available.

### Enable GPU passthrough

Enable GPU passthrough to your devcontainer by using `hostRequirements`. Here's an example of a devcontainer with this property:

```json
{
  "hostRequirements": {
    "gpu": "optional" 
  }
}
```

> Note: Setting `gpu` property's value to `true` will work with GPU machine types, but fail with CPUs. Hence, setting it to `optional` works in both cases. See [schema](https://containers.dev/implementors/json_schema/#base-schema) for more configuration details.



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ridgerun/devcontainer-features/blob/main/src/deepstream/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

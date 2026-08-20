
# GStreamer (gstreamer)

Add a GStreamer build to a devcontainer

## Example Usage

```json
"features": {
    "ghcr.io/ridgerun/devcontainer-features/gstreamer:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| gstVersion | The GStreamer version to build | string | undefined |
| buildGlib | Whether to build GLib from fallback sources | boolean | false |
| buildType | The type of build to perform | string | debug |
| tests | Whether to build the tests or not | boolean | false |
| examples | Whether to build the examples or not | boolean | false |
| docs | Whether to build the docs or not | boolean | false |
| gpl | Whether to build GPL licenced projects or not | boolean | true |
| introspection | Whether to build GIR introspection libs or not | boolean | true |
| extraArgs | Any additional meson args to pass to the configuration step | string | undefined |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/ridgerun/devcontainer-features/blob/main/src/gstreamer/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._

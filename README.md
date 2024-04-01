# axdeps
Dependency for [axes](https://github.com/Adversarr/axes).

## Build

Before build, check all submodules are initialized correctly.
```sh
git submodule update --init --recursive # -f (if needed)
```

for Windows User:
```powershell
# First, set all the environment variables.
$env:SDK_PATH="<path-to-sdk>"    # default: ./sdk
$env:BUILD_TYPE="RelWithDebInfo" # default: "RelWithDebInfo"
# Other variables, e.g. cmake, extra cmake configure command, see implementation.
./build.ps1
```

for Unix User:

```shell
SDK_PATH="<path-to-sdk>" BUILD_TYPE="RelWithDebInfo" ./build.sh
```

The output should be:
```sh
<path-to-sdk>/<build-type>
  |- bin
  |- include
  |- lib
  |- share
```

## Known Issues

1. `glad` is likely to suffer from network issues, just remove `<build-dir>/glad/` and retry the script.
2. most libraries, like `boost`, build time is too long. (but once built, no more effort is required).


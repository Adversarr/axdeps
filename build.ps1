# Check and set AX_CMAKE
if ([string]::IsNullOrEmpty($env:AX_CMAKE)) {
    $env:AX_CMAKE = "cmake"
}

# Check if AX_CMAKE command is available
if (-not (Get-Command $env:AX_CMAKE -ErrorAction SilentlyContinue)) {
    Write-Host "$env:AX_CMAKE is not available. Please install cmake."
    exit 1
}
Write-Host "CMake Program: $env:AX_CMAKE"

# Set AX_CMAKE_CONFIGURE_COMMAND if not set
if ([string]::IsNullOrEmpty($env:AX_CMAKE_CONFIGURE_COMMAND)) {
    $env:AX_CMAKE_CONFIGURE_COMMAND = ""
}
Write-Host "CMake Extra Configure Command: $env:AX_CMAKE_CONFIGURE_COMMAND"

# Configure the build environment
if ([string]::IsNullOrEmpty($env:BUILD_TYPE)) {
    $env:BUILD_TYPE = "RelWithDebInfo"
}
Write-Host "Build Type: $env:BUILD_TYPE"

if ([string]::IsNullOrEmpty($env:AX_DEP_ROOT)) {
    $env:AX_DEP_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$env:AX_DEP_ROOT = Resolve-Path $env:AX_DEP_ROOT
Write-Host "Ax Dependency Root: $env:AX_DEP_ROOT"

if ([string]::IsNullOrEmpty($env:SDK_PATH)) {
    $env:SDK_PATH = Join-Path $env:AX_DEP_ROOT "sdk"
}
if (-not (Test-Path $env:SDK_PATH)) {
    Write-Host "Creating SDK Path: $env:SDK_PATH"
    New-Item -ItemType Directory -Force -Path $env:SDK_PATH
}

$env:SDK_PATH = Resolve-Path $env:SDK_PATH
$env:INSTALL_PREFIX_WITHOUT_LIBNAME = Join-Path $env:SDK_PATH $env:BUILD_TYPE
$env:BINARY_DIR = Join-Path $env:INSTALL_PREFIX_WITHOUT_LIBNAME "bin"
$env:BUILD_DIR = Join-Path $env:AX_DEP_ROOT "build/$env:BUILD_TYPE"

Write-Host "SDK PATH: $env:SDK_PATH"
Write-Host "Install Prefix: $env:INSTALL_PREFIX_WITHOUT_LIBNAME"
Write-Host "Binary Directory: $env:BINARY_DIR"
Write-Host "Build Directory: $env:BUILD_DIR"

# User confirmation
$UserInput = Read-Host "Do you want to continue? (y/n)"
if ($UserInput -ne 'y' -and $UserInput -ne 'Y') {
    Write-Host "Exiting..."
    exit 1
}

function cmake_build_install {
    Param (
        [string]$LIB_NAME
    )

    & $env:AX_CMAKE --build "$($env:BUILD_DIR)/$LIB_NAME" --config "$env:BUILD_TYPE" -j 10
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build $LIB_NAME"
        exit 1
    }

    & $env:AX_CMAKE --install "$($env:BUILD_DIR)/$LIB_NAME" --config "$env:BUILD_TYPE"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install $LIB_NAME"
        exit 1
    }
}

# Translating the library-specific commands from the shell script
# Eigen
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/eigen" `
  -B "$env:BUILD_DIR/eigen" `
  "-DCMAKE_BUILD_TYPE=$env:BUILD_TYPE" `
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DCMAKE_CXX_STANDARD=17 `
  -DEIGEN_BUILD_DOC=OFF `
  -DEIGEN_BUILD_TESTING=OFF `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "eigen"
Write-Host "Eigen3 is installed."
Copy-Item "$env:INSTALL_PREFIX_WITHOUT_LIBNAME/share/eigen3/cmake" "$env:INSTALL_PREFIX_WITHOUT_LIBNAME/lib/cmake/eigen3" -Recurse -Force

# EnTT
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/entt" `
  -B "$env:BUILD_DIR/entt" `
  "-DCMAKE_BUILD_TYPE=$env:BUILD_TYPE" `
  "-DCMAKE_INSTALL_PREFIX=$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "entt"
Write-Host "EnTT is installed."

# Ranges-v3
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/ranges-v3" `
  -B "$env:BUILD_DIR/ranges-v3" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DRANGE_V3_DOCS=OFF `
  -DRANGE_V3_EXAMPLES=OFF `
  -DRANGE_V3_TESTS=OFF `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "ranges-v3"
Write-Host "ranges-v3 is installed."

# doctest
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/doctest" `
  -B "$env:BUILD_DIR/doctest" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DDOCTEST_WITH_TESTS=OFF `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "doctest"
Write-Host "doctest is installed."

# libigl
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT" `
  -B "$env:BUILD_DIR/libigl" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DSDK_PATH="$env:SDK_PATH" `
  $env:AX_CMAKE_CONFIGURE_COMMAND

  # -S "$env:AX_DEP_ROOT/libigl" `
  # -B "$env:BUILD_DIR/libigl" `
  # -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  # -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  # -DLIBIGL_INSTALL=ON `
  # -DLIBIGL_BUILD_TESTS=OFF `
  # -DLIBIGL_BUILD_TUTORIALS=OFF `
  # -DLIBIGL_USE_STATIC_LIBRARY=OFF `
  # -DLIBIGL_EMBREE=OFF `
  # -DLIBIGL_GLFW=OFF `
  # -DLIBIGL_IMGUI=OFF `
  # -DLIBIGL_OPENGL=OFF `
  # -DLIBIGL_STB=OFF `
  # -DLIBIGL_PREDICATES=OFF `
  # -DLIBIGL_SPECTRA=OFF `
  # -DLIBIGL_XML=OFF `
  # -DLIBIGL_COPYLEFT_CORE=ON `
  # -DLIBIGL_COPYLEFT_CGAL=OFF `
  # -DLIBIGL_COPYLEFT_COMISO=OFF `
  # -DLIBIGL_COPYLEFT_TETGEN=ON `
  # -DLIBIGL_RESTRICTED_MATLAB=OFF `
  # -DLIBIGL_RESTRICTED_MOSEK=OFF `
  # -DLIBIGL_RESTRICTED_TRIANGLE=OFF `
  # -DLIBIGL_GLFW_TESTS=OFF `
  # $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "libigl"
Write-Host "libigl is installed."

# glfw
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/glfw" `
  -B "$env:BUILD_DIR/glfw" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DBUILD_SHARED_LIBS=ON `
  -DGLFW_BUILD_DOCS=OFF `
  -DGLFW_BUILD_EXAMPLES=OFF `
  -DGLFW_BUILD_TESTS=OFF `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "glfw"
Write-Host "glfw is installed."

# glm
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/glm" `
  -B "$env:BUILD_DIR/glm" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DGLM_BUILD_LIBRARY=ON `
  -DGLM_BUILD_TESTS=OFF `
  -DGLM_BUILD_INSTALL=ON `
  -DGLM_ENABLE_CXX_17=ON `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "glm"
Write-Host "glm is installed."

# abseil
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/abseil" `
  -B "$env:BUILD_DIR/abseil" `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON `
  -DBUILD_TESTING=OFF `
  -DABSL_BUILD_TESTING=OFF `
  -DCMAKE_CXX_STANDARD=20 `
  -DCMAKE_CXX_STANDARD_REQUIRED=ON `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "abseil"
Write-Host "abseil is installed."

# imgui, implot, and additional steps for setting up directories
New-Item -ItemType Directory -Path "$env:AX_DEP_ROOT/imgui_src_build/imgui/include", "$env:AX_DEP_ROOT/imgui_src_build/imgui/src", "$env:AX_DEP_ROOT/imgui_src_build/implot/include", "$env:AX_DEP_ROOT/imgui_src_build/implot/src" -Force

Copy-Item "$env:AX_DEP_ROOT/imgui/*.h" "$env:AX_DEP_ROOT/imgui_src_build/imgui/include"
Copy-Item "$env:AX_DEP_ROOT/imgui/*.cpp" "$env:AX_DEP_ROOT/imgui_src_build/imgui/src"
Copy-Item "$env:AX_DEP_ROOT/imgui/backends/imgui_impl_glfw.h" "$env:AX_DEP_ROOT/imgui_src_build/imgui/include"
Copy-Item "$env:AX_DEP_ROOT/imgui/backends/imgui_impl_glfw.cpp" "$env:AX_DEP_ROOT/imgui_src_build/imgui/src"
Copy-Item "$env:AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3.h" "$env:AX_DEP_ROOT/imgui_src_build/imgui/include"
Copy-Item "$env:AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3_loader.h" "$env:AX_DEP_ROOT/imgui_src_build/imgui/include"
Copy-Item "$env:AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3.cpp" "$env:AX_DEP_ROOT/imgui_src_build/imgui/src"

Copy-Item "$env:AX_DEP_ROOT/implot/*.h" "$env:AX_DEP_ROOT/imgui_src_build/implot/include"
Copy-Item "$env:AX_DEP_ROOT/implot/*.cpp" "$env:AX_DEP_ROOT/imgui_src_build/implot/src"

& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/imgui_src_build" `
  -B "$env:BUILD_DIR/imgui_src_build" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DCMAKE_PREFIX_PATH="$env:INSTALL_PREFIX_WITHOUT_LIBNAME/lib/cmake" `
  $env:AX_CMAKE_CONFIGURE_COMMAND

& $env:AX_CMAKE --build "$env:BUILD_DIR/imgui_src_build" --config $env:BUILD_TYPE -j 10
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build imgui"
    exit 1
}

& $env:AX_CMAKE --install "$env:BUILD_DIR/imgui_src_build" --config $env:BUILD_TYPE
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install imgui"
    exit 1
}

Write-Host "imgui and related components are installed."

# glad
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/glad" `
  -B "$env:BUILD_DIR/glad" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DGLAD_INSTALL=ON `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "glad"
Write-Host "glad is installed."

# Boost (Note: The actual Boost build might require additional handling if Boost.Build is used instead of CMake)
# & $env:AX_CMAKE `
#   -S "$env:AX_DEP_ROOT/boost" `
#   -B "$env:BUILD_DIR/boost" `
#   -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
#   -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
#   $env:AX_CMAKE_CONFIGURE_COMMAND

# cmake_build_install "boost"
Set-Location $env:AX_DEP_ROOT\boost
./bootstrap
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to bootstrap Boost"
    exit 1
}
./b2.exe --prefix="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install Boost"
    exit 1
}
Set-Location $env:AX_DEP_ROOT


Write-Host "Boost is installed."

# Blosc
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/c-blosc" `
  -B "$env:BUILD_DIR/blosc" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DBUILD_SHARED_LIBS=ON `
  -DTEST_INCLUDE_BENCH_SHUFFLE_1=OFF `
  -DTEST_INCLUDE_BENCH_SHUFFLE_N=OFF `
  -DTEST_INCLUDE_BENCH_BITSHUFFLE_1=OFF `
  -DTEST_INCLUDE_BENCH_BITSHUFFLE_N=OFF `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "blosc"
Write-Host "blosc is installed."

# zlib
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/zlib" `
  -B "$env:BUILD_DIR/zlib" `
  -DBUILD_SHARED_LIBS=ON `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DMSVC_MP_THREAD_COUNT=10 `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "zlib"
Write-Host "zlib is installed."

# oneTBB
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/oneTBB" `
  -B "$env:BUILD_DIR/tbb" `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DMSVC_MP_THREAD_COUNT=10 `
  -DCMAKE_DEBUG_POSTFIX="_debug" `
  -DTBB_TEST=OFF `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "tbb"
Write-Host "tbb is installed."

# openvdb
& $env:AX_CMAKE `
  -S "$env:AX_DEP_ROOT/openvdb" `
  -B "$env:BUILD_DIR/openvdb" `
  -DCMAKE_BUILD_TYPE="$env:BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DBUILD_SHARED_LIBS=ON `
  -DOPENVDB_BUILD_CORE=ON `
  -DUSE_EXPLICIT_INSTANTIATION=OFF `
  -DUSE_NANOVDB=OFF `
  -DOPENVDB_BUILD_DOCS=OFF `
  -DBlosc_ROOT=$env:INSTALL_PREFIX_WITHOUT_LIBNAME `
  -DZLIB_ROOT=$env:INSTALL_PREFIX_WITHOUT_LIBNAME `
  -DBoost_ROOT=$env:INSTALL_PREFIX_WITHOUT_LIBNAME `
  -DTBB_ROOT=$env:INSTALL_PREFIX_WITHOUT_LIBNAME `
  -DCMAKE_PREFIX_PATH="$env:INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DUSE_PKGCONFIG=OFF `
  -DMSVC_MP_THREAD_COUNT=10 `
  -DOPENVDB_BUILD_NANOVDB=OFF `
  -DOPENVDB_BUILD_UNITTESTS=OFF `
  -DOPENVDB_CORE_STATIC=ON `
  -DOPENVDB_BUILD_BINARIES=ON `
  -DDISABLE_DEPENDENCY_VERSION_CHECKS=ON `
  $env:AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "openvdb"
Write-Host "openvdb is installed."


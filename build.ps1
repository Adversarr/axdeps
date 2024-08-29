# Input Parameters:
#   - env:AX_CMAKE: Path to the cmake executable
#   - env:AX_CMAKE_CONFIGURE_COMMAND: Additional CMake configure command
#   - env:BUILD_TYPE: Build type (Debug, Release, RelWithDebInfo, MinSizeRel)
#   - env:AX_DEP_ROOT: Root directory of the dependencies
#   - env:SDK_PATH: Path to the SDK directory

# Check and set AX_CMAKE
if ([string]::IsNullOrEmpty($env:AX_CMAKE)) {
    $AX_CMAKE = "cmake"
} else {
    $AX_CMAKE = $env:AX_CMAKE
}

# Check if AX_CMAKE command is available
if (-not (Get-Command $AX_CMAKE -ErrorAction SilentlyContinue)) {
    Write-Host "$AX_CMAKE is not available. Please install cmake."
    exit 1
}
$AX_CMAKE = (Get-Command $AX_CMAKE).Definition
Write-Host "CMake Program: $AX_CMAKE"

# Set AX_CMAKE_CONFIGURE_COMMAND if not set
if ([string]::IsNullOrEmpty($env:AX_CMAKE_CONFIGURE_COMMAND)) {
    $AX_CMAKE_CONFIGURE_COMMAND = ""
} else {
    $AX_CMAKE_CONFIGURE_COMMAND = $env:AX_CMAKE_CONFIGURE_COMMAND
}
$AX_CPU_LOGICAL_PROCESSORS = [System.Environment]::ProcessorCount
$AX_CMAKE_CONFIGURE_COMMAND += "-DMSVC_MP_THREAD_COUNT=$AX_CPU_LOGICAL_PROCESSORS "

# Configure the build environment
if ([string]::IsNullOrEmpty($env:BUILD_TYPE)) {
    $BUILD_TYPE = "RelWithDebInfo"
} else {
    $BUILD_TYPE = $env:BUILD_TYPE
}
Write-Host "Build Type: $BUILD_TYPE"

if ([string]::IsNullOrEmpty($env:AX_DEP_ROOT)) {
    $AX_DEP_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition
} else {
    $AX_DEP_ROOT = $env:AX_DEP_ROOT
}

$AX_DEP_ROOT = Resolve-Path $AX_DEP_ROOT
$AX_DEP_ROOT = $AX_DEP_ROOT -replace "\\","/"
Write-Host "Ax Dependency Root: $AX_DEP_ROOT"

if ([string]::IsNullOrEmpty($env:SDK_PATH)) {
    $SDK_PATH = Join-Path $AX_DEP_ROOT "sdk"
} else {
    $SDK_PATH = $env:SDK_PATH
}
if (-not (Test-Path $SDK_PATH)) {
    Write-Host "Creating SDK Path: $SDK_PATH"
    New-Item -ItemType Directory -Force -Path $SDK_PATH
}

$SDK_PATH = Resolve-Path $SDK_PATH
$INSTALL_PREFIX_WITHOUT_LIBNAME = Join-Path $SDK_PATH $BUILD_TYPE
$BUILD_DIR = Join-Path $AX_DEP_ROOT "build/$BUILD_TYPE"

$SDK_PATH = $SDK_PATH -replace "\\","/"
$INSTALL_PREFIX_WITHOUT_LIBNAME = $INSTALL_PREFIX_WITHOUT_LIBNAME -replace "\\","/"
$BUILD_DIR = $BUILD_DIR -replace "\\","/"

$AX_CMAKE_CONFIGURE_COMMAND += "-DCMAKE_BUILD_TYPE=`"$BUILD_TYPE`" "
$AX_CMAKE_CONFIGURE_COMMAND += "-DCMAKE_INSTALL_PREFIX=`"$INSTALL_PREFIX_WITHOUT_LIBNAME`" "
$AX_CMAKE_CONFIGURE_COMMAND += "-DCMAKE_PREFIX_PATH=`"$INSTALL_PREFIX_WITHOUT_LIBNAME`" "

Write-Host "SDK PATH: $SDK_PATH"
Write-Host "Install Prefix: $INSTALL_PREFIX_WITHOUT_LIBNAME"
Write-Host "Build Directory: $BUILD_DIR"
Write-Host "CMake Common Configure Command: $AX_CMAKE_CONFIGURE_COMMAND"

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

    & $AX_CMAKE --build "$($BUILD_DIR)/$LIB_NAME" --config "$BUILD_TYPE" -j 10
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build $LIB_NAME" -ForegroundColor Red
        exit 1
    }

    & $AX_CMAKE --install "$($BUILD_DIR)/$LIB_NAME" --config "$BUILD_TYPE"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install $LIB_NAME" -ForegroundColor Red
        exit 1
    }

    Write-Host "$LIB_NAME is installed." -ForegroundColor Green
}

# Translating the library-specific commands from the shell script
# Eigen
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/eigen" `
  -B "$BUILD_DIR/eigen" `
  "-DCMAKE_BUILD_TYPE=$BUILD_TYPE" `
  "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DCMAKE_CXX_STANDARD=17 `
  -DEIGEN_BUILD_DOC=OFF `
  -DEIGEN_BUILD_TESTING=OFF `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "eigen"
Write-Host "Eigen3 is installed."
Copy-Item "$INSTALL_PREFIX_WITHOUT_LIBNAME/share/eigen3/cmake" "$INSTALL_PREFIX_WITHOUT_LIBNAME/lib/cmake/eigen3" -Recurse -Force

# EnTT
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/entt" `
  -B "$BUILD_DIR/entt" `
  "-DCMAKE_BUILD_TYPE=$BUILD_TYPE" `
  "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "entt"
Write-Host "EnTT is installed."

# Ranges-v3
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/ranges-v3" `
  -B "$BUILD_DIR/ranges-v3" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DRANGE_V3_DOCS=OFF `
  -DRANGE_V3_EXAMPLES=OFF `
  -DRANGE_V3_TESTS=OFF `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "ranges-v3"
Write-Host "ranges-v3 is installed."

# doctest
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/doctest" `
  -B "$BUILD_DIR/doctest" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DDOCTEST_WITH_TESTS=OFF `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "doctest"
Write-Host "doctest is installed."

# libigl
& $AX_CMAKE `
  -S "$AX_DEP_ROOT" `
  -B "$BUILD_DIR/libigl" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DSDK_PATH="$SDK_PATH" `
  $AX_CMAKE_CONFIGURE_COMMAND

  # -S "$AX_DEP_ROOT/libigl" `
  # -B "$BUILD_DIR/libigl" `
  # -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  # -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
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
  # $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "libigl"
Write-Host "libigl is installed."

# glfw
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/glfw" `
  -B "$BUILD_DIR/glfw" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DBUILD_SHARED_LIBS=ON `
  -DGLFW_BUILD_DOCS=OFF `
  -DGLFW_BUILD_EXAMPLES=OFF `
  -DGLFW_BUILD_TESTS=OFF `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "glfw"
Write-Host "glfw is installed."

# # glm
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/glm" `
  -B "$BUILD_DIR/glm" `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DGLM_BUILD_LIBRARY=ON `
  -DGLM_BUILD_TESTS=OFF `
  -DGLM_BUILD_INSTALL=ON `
  -DGLM_ENABLE_CXX_17=ON `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "glm"
Write-Host "glm is installed."

# # abseil
# & $AX_CMAKE `
#   -S "$AX_DEP_ROOT/abseil" `
#   -B "$BUILD_DIR/abseil" `
#   -DBUILD_SHARED_LIBS=OFF `
#   -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
#   -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
#   -DCMAKE_POSITION_INDEPENDENT_CODE=ON `
#   -DBUILD_TESTING=OFF `
#   -DABSL_BUILD_TESTING=OFF `
#   -DCMAKE_CXX_STANDARD=20 `
#   -DCMAKE_CXX_STANDARD_REQUIRED=ON `
#   $AX_CMAKE_CONFIGURE_COMMAND

# cmake_build_install "abseil"
# Write-Host "abseil is installed."

# imgui, implot, and additional steps for setting up directories
New-Item -ItemType Directory -Path "$AX_DEP_ROOT/imgui_src_build/imgui/include", "$AX_DEP_ROOT/imgui_src_build/imgui/src", "$AX_DEP_ROOT/imgui_src_build/implot/include", "$AX_DEP_ROOT/imgui_src_build/implot/src", "$AX_DEP_ROOT/imgui_src_build/imnode/include", "$AX_DEP_ROOT/imgui_src_build/imnode/src" -Force

Copy-Item "$AX_DEP_ROOT/imgui/*.h" "$AX_DEP_ROOT/imgui_src_build/imgui/include"
Copy-Item "$AX_DEP_ROOT/imgui/*.cpp" "$AX_DEP_ROOT/imgui_src_build/imgui/src"
Copy-Item "$AX_DEP_ROOT/imgui/backends/imgui_impl_glfw.h" "$AX_DEP_ROOT/imgui_src_build/imgui/include"
Copy-Item "$AX_DEP_ROOT/imgui/backends/imgui_impl_glfw.cpp" "$AX_DEP_ROOT/imgui_src_build/imgui/src"
Copy-Item "$AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3.h" "$AX_DEP_ROOT/imgui_src_build/imgui/include"
Copy-Item "$AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3_loader.h" "$AX_DEP_ROOT/imgui_src_build/imgui/include"
Copy-Item "$AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3.cpp" "$AX_DEP_ROOT/imgui_src_build/imgui/src"

Copy-Item "$AX_DEP_ROOT/imgui-node-editor/*.h" "$AX_DEP_ROOT/imgui_src_build/imnode/include"
Copy-Item "$AX_DEP_ROOT/imgui-node-editor/*.inl" "$AX_DEP_ROOT/imgui_src_build/imnode/include"
Copy-Item "$AX_DEP_ROOT/imgui-node-editor/*.cpp" "$AX_DEP_ROOT/imgui_src_build/imnode/src"
patch "$AX_DEP_ROOT/imgui_src_build/imnode/include/imgui_extra_math.h" "$AX_DEP_ROOT/imgui_extra_math.h.patch"
patch "$AX_DEP_ROOT/imgui_src_build/imnode/include/imgui_extra_math.inl" "$AX_DEP_ROOT/imgui_extra_math.inl.patch"


& $AX_CMAKE `
  -S "$AX_DEP_ROOT/imgui_src_build" `
  -B "$BUILD_DIR/imgui_src_build" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME/lib/cmake" `
  $AX_CMAKE_CONFIGURE_COMMAND

& $AX_CMAKE --build "$BUILD_DIR/imgui_src_build" --config $BUILD_TYPE -j 10
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build imgui"
    exit 1
}

& $AX_CMAKE --install "$BUILD_DIR/imgui_src_build" --config $BUILD_TYPE
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install imgui"
    exit 1
}

Write-Host "imgui and related components are installed."

# glad
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/glad" `
  -B "$BUILD_DIR/glad" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DGLAD_INSTALL=ON `
  -DBUILD_SHARED_LIBS=ON `
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "glad"
Write-Host "glad is installed."

# Boost (Note: The actual Boost build might require additional handling if Boost.Build is used instead of CMake)
# & $AX_CMAKE `
#   -S "$AX_DEP_ROOT/boost" `
#   -B "$BUILD_DIR/boost" `
#   -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
#   -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
#   $AX_CMAKE_CONFIGURE_COMMAND

# cmake_build_install "boost"
Set-Location $AX_DEP_ROOT\boost
./bootstrap
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to bootstrap Boost"
    exit 1
}
./b2.exe --prefix="$INSTALL_PREFIX_WITHOUT_LIBNAME" install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to install Boost"
    exit 1
}
Set-Location $AX_DEP_ROOT


Write-Host "Boost is installed."

# Blosc
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/c-blosc" `
  -B "$BUILD_DIR/blosc" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DBUILD_SHARED_LIBS=ON `
  -DTEST_INCLUDE_BENCH_SHUFFLE_1=OFF `
  -DTEST_INCLUDE_BENCH_SHUFFLE_N=OFF `
  -DTEST_INCLUDE_BENCH_BITSHUFFLE_1=OFF `
  -DTEST_INCLUDE_BENCH_BITSHUFFLE_N=OFF `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "blosc"
Write-Host "blosc is installed."

# zlib
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/zlib" `
  -B "$BUILD_DIR/zlib" `
  -DBUILD_SHARED_LIBS=ON `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DMSVC_MP_THREAD_COUNT=10 `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "zlib"
Write-Host "zlib is installed."

# oneTBB
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/oneTBB" `
  -B "$BUILD_DIR/tbb" `
  -DBUILD_SHARED_LIBS=OFF `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DMSVC_MP_THREAD_COUNT=10 `
  -DCMAKE_DEBUG_POSTFIX="_debug" `
  -DTBB_TEST=OFF `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "tbb"
Write-Host "tbb is installed."

# openvdb
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/openvdb" `
  -B "$BUILD_DIR/openvdb" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DBUILD_SHARED_LIBS=ON `
  -DOPENVDB_BUILD_CORE=ON `
  -DUSE_EXPLICIT_INSTANTIATION=OFF `
  -DUSE_NANOVDB=OFF `
  -DOPENVDB_BUILD_DOCS=OFF `
  -DBlosc_ROOT=$INSTALL_PREFIX_WITHOUT_LIBNAME `
  -DZLIB_ROOT=$INSTALL_PREFIX_WITHOUT_LIBNAME `
  -DBoost_ROOT=$INSTALL_PREFIX_WITHOUT_LIBNAME `
  -DTBB_ROOT=$INSTALL_PREFIX_WITHOUT_LIBNAME `
  -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DUSE_PKGCONFIG=OFF `
  -DMSVC_MP_THREAD_COUNT=10 `
  -DOPENVDB_BUILD_NANOVDB=OFF `
  -DOPENVDB_BUILD_UNITTESTS=OFF `
  -DOPENVDB_CORE_STATIC=ON `
  -DOPENVDB_BUILD_BINARIES=ON `
  -DDISABLE_DEPENDENCY_VERSION_CHECKS=ON `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "openvdb"
Write-Host "openvdb is installed."

# =================> X3. SuiteSparse <=================
# Not work on windows currently.

# & $AX_CMAKE `
#    -S "$AX_DEP_ROOT/OpenBLAS" `
#    -B "$BUILD_DIR/OpenBLAS" `
#     -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
#     -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
#     -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
#     -DBUILD_SHARED_LIBS=ON `
#     -DBUILD_WITHOUT_LAPACK=OFF `
#     -DBUILD_TESTING=OFF `
#     -DC_LAPACK=ON `
#     -DNO_WARMUP=OFF `
#     $AX_CMAKE_CONFIGURE_COMMAND
# cmake_build_install "OpenBLAS"
# Write-Host "OpenBLAS is installed."

# & $AX_CMAKE `
#   -S "$AX_DEP_ROOT/SuiteSparse" `
#   -B "$BUILD_DIR/SuiteSparse" `
#   -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
#   -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
#   -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
#   -DBUILD_SHARED_LIBS=ON `
#   -DSUITESPARSE_USE_CUDA=OFF `
#   -DSUITESPARSE_USE_STRICT=ON `
#   -DSUITESPARSE_ENABLE_PROJECTS="cholmod;cxsparse" `
#   -DSUITESPARSE_USE_FORTRAN=OFF `
#   -DMSVC_MP_THREAD_COUNT=10 `
#   $AX_CMAKE_CONFIGURE_COMMAND

# cmake_build_install "SuiteSparse"
# Write-Host "SuiteSparse is installed."


# =================> X4. AMGCL <=================

# & $AX_CMAKE `
#     -S "$AX_DEP_ROOT/amgcl" `
#     -B "$BUILD_DIR/amgcl" `
#     -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
#     -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
#     -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
#     -DBUILD_SHARED_LIBS=ON `
#     $AX_CMAKE_CONFIGURE_COMMAND

# cmake_build_install "amgcl"
# Write-Host "amgcl is installed."

# =================> X5. spdlog <=================
# =================> X5.1 fmt <=================
& $AX_CMAKE `
    -S "$AX_DEP_ROOT/fmt" `
    -B "$BUILD_DIR/fmt" `
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
    -DCMAKE_INSTALL_PREFIX"=$INSTALL_PREFIX_WITHOUT_LIBNAME" `
    -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
    -DFMT_DOC=OFF `
    -DFMT_TEST=OFF `
    -DFMT_INSTALL=ON `
    -DBUILD_SHARED_LIBS=OFF `
    $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install fmt
Write-Host "fmt is installed."

& $AX_CMAKE `
    -S "$AX_DEP_ROOT/spdlog" `
    -B "$BUILD_DIR/spdlog" `
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
    -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
    -DBUILD_SHARED_LIBS=OFF `
    -DSPDLOG_BUILD_EXAMPLE=OFF `
    -DSPDLOG_BUILD_TESTS=OFF `
    -DSPDLOG_FMT_EXTERNAL=ON `
    $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install spdlog
Write-Host "spdlog is installed."

# # =================> X6. cxxopts <=================
& $AX_CMAKE `
  -S "$AX_DEP_ROOT/cxxopts" `
  -B "$BUILD_DIR/cxxopts" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DCXXOPTS_BUILD_EXAMPLES=OFF `
  -DCXXOPTS_BUILD_TESTS=OFF `
  -DCXXOPTS_ENABLE_INSTALL=ON `
  -DCXXOPTS_ENABLE_WARNINGS=OFF `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install cxxopts
Write-Host "cxxopts is installed."

# =================> X7. GSL <=================
& $AX_CMAKE `
    -S "$AX_DEP_ROOT/GSL" `
    -B "$BUILD_DIR/GSL" `
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
    -DGSL_INSTALL=ON `
    -DGSL_TEST=OFF `
    $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install GSL
Write-Host "GSL is installed."


# =================> X8. benchmark <=================
& $AX_CMAKE `
    -S "$AX_DEP_ROOT/benchmark" `
    -B "$BUILD_DIR/benchmark" `
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
    -DBENCHMARK_ENABLE_TESTING=OFF `
    -DBENCHMARK_ENABLE_EXCEPTIONS=ON `
    -DBENCHMARK_ENABLE_LTO=OFF `
    -DBENCHMARK_ENABLE_WERROR=OFF `
    -DBENCHMARK_FORCE_WERROR=OFF `
    -DBENCHMARK_ENABLE_INSTALL=ON `
    -DBENCHMARK_ENABLE_DOXYGEN=OFF `
    -DBENCHMARK_INSTALL_DOCS=OFF `
    -DBENCHMARK_ENABLE_GTEST_TESTS=OFF `
    -DBENCHMARK_USE_BUNDLED_GTEST=ON `
    $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install benchmark
Write-Host "benchmark is installed."

# =================> X9. taskflow <=================

& $AX_CMAKE `
  -S "$AX_DEP_ROOT/taskflow" `
  -B "$BUILD_DIR/taskflow" `
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" `
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX_WITHOUT_LIBNAME" `
  -DTF_BUILD_EXAMPLES=OFF `
  -DTF_BUILD_TESTS=OFF `
  -DTF_BUILD_BENCHMARKS=OFF `
  -DTF_BUILD_CUDA=OFF `
  -DCMAKE_CXX_STANDARD=20 `
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install taskflow
Write-Host "taskflow is installed."


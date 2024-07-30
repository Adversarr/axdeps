###############################################################################
# Check cmake.
###############################################################################
if [ -z "$AX_CMAKE" ]; then
  export AX_CMAKE="cmake"
fi

if ! command -v $AX_CMAKE &> /dev/null; then
  echo "$AX_CMAKE is not available. Please install cmake."
  exit 1
fi
echo "CMake Program: $AX_CMAKE"

if [ -z "$AX_CMAKE_CONFIGURE_COMMAND" ]; then
  export AX_CMAKE_CONFIGURE_COMMAND=""
fi
echo "CMake Extra Configure Command: $AX_CMAKE_CONFIGURE_COMMAND"

###############################################################################
# Configure the build environment
###############################################################################

if [ -z "$BUILD_TYPE" ]; then
  export BUILD_TYPE="RelWithDebInfo"
fi
echo "Build Type: $BUILD_TYPE"

if [ -z "$AX_DEP_ROOT" ]; then
  export AX_DEP_ROOT="$(dirname $0)"
fi

export AX_DEP_ROOT="$(realpath $AX_DEP_ROOT)"
echo "Ax Dependency Root: $AX_DEP_ROOT"

if [ -z "$SDK_PATH" ]; then
  export SDK_PATH="$AX_DEP_ROOT/sdk"
fi
if [ ! -d "$SDK_PATH" ]; then
  echo "Creating SDK Path: $SDK_PATH"
  mkdir -p $SDK_PATH
fi

export SDK_PATH="$(realpath $SDK_PATH)"
export INSTALL_PREFIX_WITHOUT_LIBNAME="$SDK_PATH/$BUILD_TYPE"
export BINARY_DIR="$INSTALL_PREFIX_WITHOUT_LIBNAME/bin"
export BUILD_DIR="$AX_DEP_ROOT/build/$BUILD_TYPE"

echo "SDK PATH: $SDK_PATH"
echo "Install Prefix: $INSTALL_PREFIX_WITHOUT_LIBNAME"
echo "Binary Directory: $BINARY_DIR"
echo "Build Directory: $BUILD_DIR"

# wait for a y/n input:
read -p "Do you want to continue? (y/n) " -n 1 -r
# if the input is not 'y' or 'Y' then exit
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting..."
    exit 1
fi

cmake_build() {
  _LIB_NAME=$1
  $AX_CMAKE --build "$BUILD_DIR/$_LIB_NAME" --config "$BUILD_TYPE" -j10
  RET=$?
  if [ $RET -ne 0 ]; then
    echo "Failed to build $_LIB_NAME"
    exit 1
  fi
}

cmake_install() {
  _LIB_NAME=$1
  $AX_CMAKE --install "$BUILD_DIR/$_LIB_NAME"
  RET=$?
  if [ $RET -ne 0 ]; then
    echo "Failed to install $_LIB_NAME"
    exit 1
  fi
}

cmake_build_install() {
  _LIB_NAME=$1
  cmake_build $_LIB_NAME
  cmake_install $_LIB_NAME
}

###############################################################################
# Some Libraries have special build instructions
###############################################################################

# Boost: is huge to build, and we don't need to build it if it is already installed.
# Required by OpenVDB.

###############################################################################
# Build and install all libraries
###############################################################################

# =================> 1. Eigen <=================
# NOTE: Will be installed via libigl.
$AX_CMAKE \
 -S "$AX_DEP_ROOT/eigen" \
 -B "$BUILD_DIR/eigen" \
 -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
 -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
 -DEIGEN_TEST_OPENMP=ON \
 -DEIGEN_BUILD_DOC=OFF \
 -DEIGEN_BUILD_TESTING=OFF \
 $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install eigen
echo "Eigen is installed."

# =================> 2. entt <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/entt" \
  -B "$BUILD_DIR/entt" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install entt
echo "EnTT is installed."

# # =================> 3. range-v3 <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/ranges-v3" \
  -B "$BUILD_DIR/ranges-v3" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DRANGE_V3_DOCS=OFF \
  -DRANGE_V3_EXAMPLES=OFF \
  -DRANGE_V3_TESTS=OFF \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install ranges-v3
echo "ranges-v3 is installed."

# # =================> 4. doctest <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/doctest" \
  -B "$BUILD_DIR/doctest" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DDOCTEST_WITH_TESTS=OFF \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install doctest
echo "doctest is installed."

# =================> 5. benchmark <=================
# not used, ignore.

# =================> 6. libigl <=================
# libigl static library is HUGE. We don't need it.
$AX_CMAKE \
  -S "$AX_DEP_ROOT" \
  -B "$BUILD_DIR/libigl" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DSDK_PATH=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DLIBIGL_BUILD_TESTS=OFF \
  -DLIBIGL_BUILD_TUTORIALS=OFF \
  -DLIBIGL_USE_STATIC_LIBRARY=OFF \
  -DLIBIGL_EMBREE=OFF \
  -DLIBIGL_GLFW=OFF \
  -DLIBIGL_IMGUI=OFF \
  -DLIBIGL_INSTALL=ON \
  -DLIBIGL_OPENGL=OFF \
  -DLIBIGL_STB=OFF \
  -DLIBIGL_PREDICATES=OFF \
  -DLIBIGL_SPECTRA=OFF \
  -DLIBIGL_XML=OFF \
  -DLIBIGL_COPYLEFT_CORE=ON \
  -DLIBIGL_COPYLEFT_CGAL=OFF \
  -DLIBIGL_COPYLEFT_COMISO=OFF \
  -DLIBIGL_COPYLEFT_TETGEN=ON \
  -DLIBIGL_RESTRICTED_MATLAB=OFF \
  -DLIBIGL_RESTRICTED_MOSEK=OFF \
  -DLIBIGL_RESTRICTED_TRIANGLE=OFF \
  -DLIBIGL_GLFW_TESTS=OFF \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install libigl
echo "libigl is installed."

# =================> 7. glfw3 <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/glfw" \
  -B "$BUILD_DIR/glfw" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DBUILD_SHARED_LIBS=ON \
  -DGLFW_BUILD_DOCS=OFF \
  -DGLFW_BUILD_EXAMPLES=OFF \
  -DGLFW_BUILD_TESTS=OFF \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install glfw
echo "glfw is installed."

# =================> 8. glm <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/glm" \
  -B "$BUILD_DIR/glm" \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DGLM_BUILD_LIBRARY=ON \
  -DGLM_BUILD_TESTS=OFF  \
  -DGLM_BUILD_INSTALL=ON \
  -DGLM_ENABLE_CXX_17=ON \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install glm
echo "glm is installed."

# =================> 9. abseil <=================
# $AX_CMAKE \
#   -S "$AX_DEP_ROOT/abseil" \
#   -B "$BUILD_DIR/abseil" \
#   -DBUILD_SHARED_LIBS=ON \
#   -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
#   -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
#   -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
#   -DBUILD_TESTING=OFF \
#   -DABSL_BUILD_TESTING=OFF \
#   -DCMAKE_CXX_STANDARD=20 \
#   -DCMAKE_CXX_STANDARD_REQUIRED=ON \
#   $AX_CMAKE_CONFIGURE_COMMAND
#
# cmake_build_install abseil
# echo "abseil is installed."
#
# =================> X. imgui <=================
# =================> X1. implot <=================
# =================> X2. imgui-node-editor <=================
mkdir -p $AX_DEP_ROOT/imgui_src_build/imgui/include
mkdir -p $AX_DEP_ROOT/imgui_src_build/imgui/src
mkdir -p $AX_DEP_ROOT/imgui_src_build/imnode/include
mkdir -p $AX_DEP_ROOT/imgui_src_build/imnode/src
mkdir -p $AX_DEP_ROOT/imgui_src_build/implot/include
mkdir -p $AX_DEP_ROOT/imgui_src_build/implot/src

cp $AX_DEP_ROOT/imgui/*.h $AX_DEP_ROOT/imgui_src_build/imgui/include
cp $AX_DEP_ROOT/imgui/*.cpp $AX_DEP_ROOT/imgui_src_build/imgui/src
cp $AX_DEP_ROOT/imgui/backends/imgui_impl_glfw.cpp $AX_DEP_ROOT/imgui_src_build/imgui/src
cp $AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3.cpp $AX_DEP_ROOT/imgui_src_build/imgui/src
cp $AX_DEP_ROOT/imgui/backends/imgui_impl_glfw.h $AX_DEP_ROOT/imgui_src_build/imgui/include
cp $AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3.h $AX_DEP_ROOT/imgui_src_build/imgui/include
cp $AX_DEP_ROOT/imgui/backends/imgui_impl_opengl3_loader.h $AX_DEP_ROOT/imgui_src_build/imgui/include

# Currently not used
cp $AX_DEP_ROOT/imgui-node-editor/*.cpp $AX_DEP_ROOT/imgui_src_build/imnode/src
cp $AX_DEP_ROOT/imgui-node-editor/*.inl $AX_DEP_ROOT/imgui_src_build/imnode/include
cp $AX_DEP_ROOT/imgui-node-editor/*.h $AX_DEP_ROOT/imgui_src_build/imnode/include
# apply the patch
# diff -u imgui-node-editor/imgui_extra_math.h imgui_src_build/imnode/include/imgui_extra_math.h > imgui_extra_math.h.patch
# diff -u imgui-node-editor/imgui_extra_math.inl imgui_src_build/imnode/include/imgui_extra_math.inl > imgui_extra_math.inl.patch
# patch $AX_DEP_ROOT/imgui_src_build/imnode/include/imgui_extra_math.h < $AX_DEP_ROOT/imgui_extra_math.h.patch
# patch $AX_DEP_ROOT/imgui_src_build/imnode/include/imgui_extra_math.inl < $AX_DEP_ROOT/imgui_extra_math.inl.patch
patch $AX_DEP_ROOT/imgui_src_build/imnode/src/imgui_canvas.cpp < $AX_DEP_ROOT/imgui_canvas.patch


cp $AX_DEP_ROOT/implot/*.h $AX_DEP_ROOT/imgui_src_build/implot/include
cp $AX_DEP_ROOT/implot/*.cpp $AX_DEP_ROOT/imgui_src_build/implot/src

$AX_CMAKE \
  -S "$AX_DEP_ROOT/imgui_src_build" \
  -B "$BUILD_DIR/imgui_src_build" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME/lib/cmake" \
  $AX_CMAKE_CONFIGURE_COMMAND

$AX_CMAKE --build "$BUILD_DIR/imgui_src_build" --config "$BUILD_TYPE" -j10
RET=$?
if [ $RET -ne 0 ]; then
  echo "Failed to build imgui"
  exit 1
fi

$AX_CMAKE --install "$BUILD_DIR/imgui_src_build"
RET=$?
if [ $RET -ne 0 ]; then
  echo "Failed to install imgui"
  exit 1
fi

# =================> X2. glad <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/glad" \
  -B "$BUILD_DIR/glad" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DGLAD_INSTALL=ON \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install glad
echo "glad is installed."

# =================> X2.1 Boost <=================
cd $AX_DEP_ROOT/boost
./bootstrap.sh
if [ $? -ne 0 ]; then
  echo "Failed to bootstrap boost."
  exit 1
fi

./b2 install --prefix=$INSTALL_PREFIX_WITHOUT_LIBNAME
if [ $? -ne 0 ]; then
  echo "Failed to install boost."
  exit 1
fi

echo "boost is installed."
# =================> X2.2 Blosc <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/c-blosc" \
  -B "$BUILD_DIR/blosc" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DBUILD_SHARED_LIBS=ON \
  -DTEST_INCLUDE_BENCH_SHUFFLE_1=OFF \
  -DTEST_INCLUDE_BENCH_SHUFFLE_N=OFF \
  -DTEST_INCLUDE_BENCH_BITSHUFFLE_1=OFF \
  -DTEST_INCLUDE_BENCH_BITSHUFFLE_N=OFF \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install "blosc"
echo "blosc is installed."

# # =================> X2.3 zlib <=================

$AX_CMAKE \
  -S "$AX_DEP_ROOT/zlib" \
  -B "$BUILD_DIR/zlib" \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  $AX_CMAKE_CONFIGURE_COMMAND


cmake_build_install zlib
echo "zlib is installed."

# # =================> X2.4 oneTBB <=================

$AX_CMAKE \
  -S "$AX_DEP_ROOT/oneTBB" \
  -B "$BUILD_DIR/tbb" \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DTBB_TEST=OFF \
  $AX_CMAKE_CONFIGURE_COMMAND
  

cmake_build_install tbb
echo "tbb is installed."

# =================> X2. openvdb <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/openvdb" \
  -B "$BUILD_DIR/openvdb" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DBUILD_SHARED_LIBS=ON \
  -DOPENVDB_BUILD_CORE=ON \
  -DOPENVDB_BUILD_BINARIES=ON \
  -DUSE_EXPLICIT_INSTANTIATION=OFF \
  -DUSE_NANOVDB=OFF \
  -DOPENVDB_BUILD_DOCS=OFF \
  -DBlosc_ROOT=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DZLIB_ROOT=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DBoost_ROOT=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DTBB_ROOT=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME" \
  -DUSE_PKGCONFIG=OFF \
  -DOPENVDB_BUILD_NANOVDB=OFF \
  -DOPENVDB_BUILD_UNITTESTS=OFF \
  -DOPENVDB_CORE_STATIC=OFF \
  -DDISABLE_DEPENDENCY_VERSION_CHECKS=ON \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install openvdb
echo "openvdb is installed."

# =================> X3. SuiteSparse <=================
# if macos, disable cuda
if [ "$(uname)" == "Darwin" ]; then
  export SUITE_SPARSE_ENABLE_CUDA=OFF
else
  export SUITE_SPARSE_ENABLE_CUDA=ON
fi

$AX_CMAKE \
  -S "$AX_DEP_ROOT/SuiteSparse" \
  -B "$BUILD_DIR/SuiteSparse" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_STATIC_LIBS=ON \
  -DSUITESPARSE_USE_CUDA=$SUITE_SPARSE_ENABLE_CUDA \
  -DSUITESPARSE_USE_STRICT=ON \
  -DSUITESPARSE_ENABLE_PROJECTS="cholmod;cxsparse" \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install SuiteSparse
echo "SuiteSparse is installed."

# =================> X4. AMGCL <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/amgcl" \
  -B "$BUILD_DIR/amgcl" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DBUILD_SHARED_LIBS=ON \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install amgcl
echo "AMGCL is installed."

# =================> X5. spdlog <=================
# =================> X5.1 fmt <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/fmt" \
  -B "$BUILD_DIR/fmt" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DFMT_DOC=OFF \
  -DFMT_TEST=OFF \
  -DFMT_INSTALL=ON \
  -DBUILD_SHARED_LIBS=OFF \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install fmt
echo "fmt is installed."

$AX_CMAKE \
  -S "$AX_DEP_ROOT/spdlog" \
  -B "$BUILD_DIR/spdlog" \
  -DCMAKE_MODULE_PATH="$INSTALL_PREFIX_WITHOUT_LIBNAME/lib/cmake" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DBUILD_SHARED_LIBS=OFF \
  -DSPDLOG_BUILD_EXAMPLE=OFF \
  -DSPDLOG_BUILD_TESTS=OFF \
  -DSPDLOG_FMT_EXTERNAL=ON \
  $AX_CMAKE_CONFIGURE_COMMAND

cmake_build_install spdlog
echo "spdlog is installed."

# # =================> X6. cxxopts <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/cxxopts" \
  -B "$BUILD_DIR/cxxopts" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DCXXOPTS_BUILD_EXAMPLES=OFF \
  -DCXXOPTS_BUILD_TESTS=OFF \
  -DCXXOPTS_ENABLE_INSTALL=ON \
  -DCXXOPTS_ENABLE_WARNINGS=OFF

cmake_build_install cxxopts
echo "cxxopts is installed."


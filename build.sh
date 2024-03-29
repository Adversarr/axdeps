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
echo "Ax Dependency Root: $AX_DEP_ROOT"

export SDK_PATH="$AX_DEP_ROOT/sdk"
export INSTALL_PREFIX_WITHOUT_LIBNAME="$SDK_PATH/$BUILD_TYPE"
export BINARY_DIR="$SDK/extra/bin"
export BUILD_DIR="$AX_DEP_ROOT/build/$BUILD_TYPE"

echo "Install Prefix: $INSTALL_PREFIX_WITHOUT_LIBNAME"s
echo "Binary Directory: $BINARY_DIR"
echo "Build Directory: $BUILD_DIR"

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
# Build and install all libraries
###############################################################################

# # =================> 1. Eigen <=================
# NOTE: Will be installed via libigl.
# $AX_CMAKE \
#   -S "$AX_DEP_ROOT/eigen" \
#   -B "$BUILD_DIR/eigen" \
#   -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
#   -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
#   -DEIGEN_TEST_OPENMP=ON \
#   -DEIGEN_BUILD_DOC=OFF \
#   $AX_CMAKE_CONFIGURE_COMMAND

# cmake_build_install eigen
# echo "Eigen is installed."

# # # =================> 2. entt <=================
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
$AX_CMAKE \
  -S "$AX_DEP_ROOT/libigl" \
  -B "$BUILD_DIR/libigl" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DLIBIGL_BUILD_TESTS=OFF \
  -DLIBIGL_BUILD_TUTORIALS=OFF \
  -DLIBIGL_USE_STATIC_LIBRARY=ON \
  -DLIBIGL_EMBREE=OFF \
  -DLIBIGL_GLFW=OFF \
  -DLIBIGL_IMGUI=OFF \
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


# =================> 8. glm <=================
# =================> 9. stb <=================
# =================> X. imgui <=================
# =================> X1. implot <=================
# =================> X2. imgui-node-editor <=================
# =================> X2. glad <=================
# =================> X2. openvdb <=================
# =================> X2. blosc <=================
# =================> X2. zlib <=================
# 
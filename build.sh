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
  $AX_CMAKE --build "$BUILD_DIR/$_LIB_NAME" --config "$BUILD_TYPE"
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

# =================> 1. Eigen <=================
$AX_CMAKE \
  -S "$AX_DEP_ROOT/eigen" \
  -B "$BUILD_DIR/eigen" \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_WITHOUT_LIBNAME \
  -DEIGEN_TEST_OPENMP=ON \
  -DEIGEN_BUILD_DOC=OFF \
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
cmake_minimum_required(VERSION 3.20)
project(igl)
if (NOT DEFINED SDK_PATH)
    message(FATAL_ERROR "SDK_PATH is not defined")
endif()

message(STATUS "SDK Path: ${SDK_PATH}")
set(Eigen3_DIR ${SDK_PATH}/lib/cmake/eigen3)

find_package(Eigen3 CONFIG REQUIRED)

set(LIBIGL_BUILD_TESTS OFF)
set(LIBIGL_BUILD_TUTORIALS OFF)
set(LIBIGL_USE_STATIC_LIBRARY OFF)
set(LIBIGL_EMBREE OFF)
set(LIBIGL_GLFW OFF)
set(LIBIGL_IMGUI OFF)
set(LIBIGL_OPENGL OFF)
set(LIBIGL_STB OFF)
set(LIBIGL_PREDICATES OFF)
set(LIBIGL_SPECTRA OFF)
set(LIBIGL_XML OFF)
set(LIBIGL_COPYLEFT_CORE OFF)
set(LIBIGL_COPYLEFT_CGAL OFF)
set(LIBIGL_COPYLEFT_COMISO OFF)
set(LIBIGL_COPYLEFT_TETGEN OFF)
set(LIBIGL_RESTRICTED_MATLAB OFF)
set(LIBIGL_RESTRICTED_MOSEK OFF)
set(LIBIGL_RESTRICTED_TRIANGLE OFF)
set(LIBIGL_GLFW_TESTS OFF)
set(LIBIGL_INSTALL ON)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/libigl)

cmake_minimum_required(VERSION 3.20)
project(test_axdeps)
set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../sdk/RelWithDebInfo/")
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../sdk/RelWithDebInfo/lib/cmake/OpenVDB")
set(CMAKE_BUILD_TYPE "RelWithDebInfo")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(libigl_ROOT "${CMAKE_PREFIX_PATH}/lib/cmake/igl")
find_package(Eigen3 CONFIG REQUIRED)
find_package(absl CONFIG REQUIRED)
find_package(OpenMP)
find_package(range-v3 CONFIG REQUIRED)
find_package(EnTT CONFIG REQUIRED)
find_package(libigl CONFIG REQUIRED)
find_package(OpenVDB REQUIRED)
find_package(doctest CONFIG REQUIRED)
find_package(glad CONFIG REQUIRED)
find_package(OpenGL REQUIRED)
find_package(imgui CONFIG REQUIRED)
find_package(glm CONFIG REQUIRED)
find_package(glfw3 CONFIG REQUIRED)

add_executable(test_main main.cpp)
target_link_libraries(test_main PRIVATE 
  imgui::implot imgui::imgui_core
  OpenGL::GL
  glad::glad OpenVDB::openvdb)
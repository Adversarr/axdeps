# helper to build imgui, imgui-node-editor, and implot.
# This is a bit of a hack, but it works.
cmake_minimum_required(VERSION 3.20)
project(imgui VERSION 1.90.4 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(GLOB SRC "${CMAKE_CURRENT_SOURCE_DIR}/imgui/src/*.cpp")
file(GLOB CORE_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/imgui/include/*.h")
add_library(imgui_core STATIC ${SRC} ${CORE_HEADERS})
find_package(glfw3 CONFIG REQUIRED)

target_include_directories(imgui_core PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/imgui/include>
  $<INSTALL_INTERFACE:include/imgui>  # <prefix>/include/imgui
)
target_link_libraries(imgui_core PUBLIC glfw)


# implot
file(GLOB SRC "${CMAKE_CURRENT_SOURCE_DIR}/implot/src/*.cpp")
file(GLOB PLOT_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/implot/include/*.h")
add_library(implot STATIC ${SRC} ${HEADPLOT_HEADERSERS})
target_include_directories(implot PUBLIC
$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/implot/include>
$<INSTALL_INTERFACE:include/implot>  # <prefix>/include/implot
)
target_link_libraries(implot PUBLIC imgui_core)


if (MSVC)
  # /WHOLEARCHIVE
  target_link_options(imgui_core PUBLIC "/WHOLEARCHIVE:imgui_core")
  target_link_options(implot PUBLIC "/WHOLEARCHIVE:implot")
endif()

# Install this library
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

write_basic_package_version_file(
    imguiConfigVersion.cmake
    VERSION ${PACKAGE_VERSION}
    COMPATIBILITY AnyNewerVersion)

install(TARGETS imgui_core implot
        EXPORT imguiTargets
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin
        INCLUDES DESTINATION include)

install(EXPORT imguiTargets
        FILE imguiTargets.cmake
        NAMESPACE imgui::
        DESTINATION lib/cmake/imgui)

configure_file(imguiConfig.cmake.in imguiConfig.cmake @ONLY)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/imguiConfig.cmake"
              "${CMAKE_CURRENT_BINARY_DIR}/imguiConfigVersion.cmake"
        DESTINATION lib/cmake/imgui)

install(FILES ${CORE_HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/imgui)
install(FILES ${PLOT_HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/implot)

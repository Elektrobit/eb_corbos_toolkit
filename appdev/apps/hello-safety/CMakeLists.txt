# Copyright 2025 Elektrobit. All rights reserved.

cmake_minimum_required(VERSION 3.23)
project(Hello LANGUAGES C)

# Define hello executable
add_executable(hi_app hello.c)

# Include GNUInstallDirs to determine the correct values for CMAKE_INSTALL_*
include(GNUInstallDirs)

# Install binary
install(TARGETS hi_app DESTINATION ${CMAKE_INSTALL_BINDIR})

# Mark application as safety application
target_enable_hi(hi_app)

# Create gdbinit
if (${CMAKE_BUILD_TYPE} STREQUAL "Debug")
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/app_gdbinit.template ${CMAKE_CURRENT_BINARY_DIR}/.gdbinit USE_SOURCE_PERMISSIONS)
endif()

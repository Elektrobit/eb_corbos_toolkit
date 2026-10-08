# Copyright 2025 Elektrobit. All rights reserved.

cmake_minimum_required(VERSION 3.23)
project(Hello LANGUAGES C)

# Define hello executable
add_executable(hello hello.c)

# Include GNUInstallDirs to determine the correct values for CMAKE_INSTALL_*
include(GNUInstallDirs)

# Install binary
install(TARGETS hello DESTINATION ${CMAKE_INSTALL_BINDIR})

# Process crinit file and install
# Enable the following two lines for crinit integration
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/hello.crinit.template ${CMAKE_CURRENT_BINARY_DIR}/hello.crinit USE_SOURCE_PERMISSIONS)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/hello.crinit DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/crinit/crinit.d/)

# Create gdbinit
if (${CMAKE_BUILD_TYPE} STREQUAL "Debug")
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/app_gdbinit.template ${CMAKE_CURRENT_BINARY_DIR}/.gdbinit USE_SOURCE_PERMISSIONS)
endif()

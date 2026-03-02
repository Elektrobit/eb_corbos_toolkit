# Copyright 2025 Elektrobit Automotive GmbH
# All rights reserved

set(ECLFSA_ELF_ENABLER "${CMAKE_SYSROOT}/usr/bin/lisa-elf-enabler")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static")

if(IS_FASTDEV)
    add_definitions(-DIS_FASTDEV)
endif()

function(target_enable_hi target)
  add_custom_command(
    TARGET ${target}
    POST_BUILD
    COMMAND ${ECLFSA_ELF_ENABLER} $<TARGET_FILE:${target}>
  )
endfunction()

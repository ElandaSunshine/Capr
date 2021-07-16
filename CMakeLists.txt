cmake_minimum_required(VERSION 3.20.5)

set(CAPR_VERSION 0.1.0)
set(CAPR_VENDOR  "ElandaSunshine")
set(CAPR_NAME    "CAPR")
set(CAPR_WEBSITE "https://capr.elandasunshine.xyz/")
set(CAPR_TARGET  Capr)

project(Capr
    VERSION      "${CAPR_VERSION}"
    DESCRIPTION  "A plugin-manager for CMake, providing simple-to-use script packages to include in your CMake project"
    HOMEPAGE_URL "${CAPR_WEBSITE}"
    LANGUAGES    CXX)

add_executable(${CAPR_TARGET})
target_sources(${CAPR_TARGET}
    PRIVATE
        "src/capr.cpp")

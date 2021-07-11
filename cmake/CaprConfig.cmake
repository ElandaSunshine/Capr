############ CMAKE SETTINGS
cmake_minimum_required(3.20.5)

############ CAPR DETAILS
set(CAPR_INFO_VERSION_MAJOR 1)
set(CAPR_INFO_VERSION_MINOR 0)

############ INTERNAL VARIABLES
if (WIN32)
    set(CAPR_HOME_DIR "$ENV{USERPROFILE}/.capr")
    set(CAPR_NEW_LINE "\n\r")
else()
    set(CAPR_HOME_DIR "$ENV{HOME}/.capr")
    set(CAPR_NEW_LINE "\n")
endif()

set(CAPR_HASH_FAIL_MODES Terminate Delete Warn Ignore)
set(CAPR_CONFIG_FILE "${CAPR_HOME_DIR}/configuration.ini")
set(CAPR_INDEX_FILE  "${CAPR_HOME_DIR}/repositories.txt")

############ INTERNAL PATHS
get_filename_component(CAPR_MODULE_DIR "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)

############ PUBLIC SETTINGS
set(CAPR_CONFIG_DIR     "${CAPR_HOME_DIR}"        CACHE INTERNAL "The CAPR configuration directory")
set(CAPR_PLUGIN_DIR     "${CAPR_HOME_DIR}/plugin" CACHE STRING   "The CAPR local plugin repository")
set(CAPR_HASH_FAIL_MODE "Terminate"               CACHE STRING   "What should happen when a plugin wasn't succesfully verified")

############ OPTIONS
option(CAPR_FORCE_DOWNLOAD   "Whether downloads should be downloaded whether a local version already exists or not" OFF)
option(CAPR_VERIFY_DOWNLOADS "Whether to compare the file's checksum with the remote checksum"                      ON)

############ INCLUDES
include("${CAPR_MODULE_DIR}/CaprRepo.cmake")

############ LOGIC
set_property(CACHE CAPR_HASH_FAIL_MODE PROPERTY STRINGS ${CAPR_HASH_FAIL_MODES})

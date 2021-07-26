########################################################################################################################
include_guard()

########################################################################################################################
cmake_minimum_required(VERSION 3.20.5)

message(VERBOSE "=== Initialising Capr ===")

if (DEFINED CAPR_INITIALISED AND CAPR_INITIALISED)
    return()
endif()

############ CAPR DETAILS
set(CAPR_VERSION_MAJOR 0)
set(CAPR_VERSION_MINOR 1)
set(CAPR_VERSION_PATCH 0)
set(CAPR_VERSION ${CAPR_VERSION_MAJOR}.${CAPR_VERSION_MINOR}.${CAPR_VERSION_PATCH})

############ INTERNAL VARIABLES
# option sets
set(CAPR_HASH_FAIL_MODES Delete Warn Ignore)
set(CAPR_OPTION_MODES Inherit False True)
set(CAPR_INITIALISED FALSE)

get_filename_component(CAPR_PACKAGE_DIR "${CMAKE_CURRENT_LIST_FILE}" REALPATH)
get_filename_component(CAPR_PACKAGE_DIR "${CAPR_PACKAGE_DIR}"        DIRECTORY)
get_filename_component(CAPR_PACKAGE_DIR "${CAPR_PACKAGE_DIR}"        DIRECTORY)
get_filename_component(CAPR_MODULE_DIR  "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)

# include core components
include(${CAPR_MODULE_DIR}/CaprCore.cmake)

############ VARIABLES
message(VERBOSE "[Capr] Creating variables...")

if (WIN32)
    capr_internal_core_create_property(CAPR_HOME_DIR "The home directory of CAPR"
        TYPE PATH
        NO_CONFIG
        DEFAULT "$ENV{USERPROFILE}/.capr")
else()
    capr_internal_core_create_property(CAPR_HOME_DIR "The home directory of CAPR"
        TYPE PATH
        NO_CONFIG
        DEFAULT "$ENV{HOME}/.capr")
endif()

set(CAPR_REQUEST_DIR     "${CMAKE_BINARY_DIR}/_capr_requests")
set(CAPR_CONFIG_FILE     "${CAPR_HOME_DIR}/configuration.ini")
set(CAPR_INDEX_FILE      "${CAPR_HOME_DIR}/index.json")
set(CAPR_MODULE_DEFAULTS "${CAPR_PACKAGE_DIR}/default")
set(CAPR_MODULE_INBUILTS "${CAPR_PACKAGE_DIR}/inbuilt")
set(CAPR_MODULE_REQUESTS "${CAPR_PACKAGE_DIR}/_capr_api_request")

############ PROPERTIES
capr_internal_core_create_property(CAPR_PLUGIN_DIR
    "The CAPR local plugin repository"
    TYPE PATH)
capr_internal_core_create_property(CAPR_HASH_MISMATCH_MODE
    "What should happen when a plugin wasn't succesfully verified"
    VALUESET ${CAPR_HASH_FAIL_MODES})

############ OPTIONS
capr_internal_core_create_option(CAPR_FORCE_DOWNLOADS
    "Whether downloads should be downloaded regardless a local version already exists or not")
capr_internal_core_create_option(CAPR_VERIFY_DOWNLOADS
    "Whether to compare the file's checksum with the remote checksum")
capr_internal_core_create_option(CAPR_SAME_PLUGIN_TERMINATES
    "Whether the script should terminate or just warn when the same plugin was included twice (version ignored)")
capr_internal_core_create_option(CAPR_SKIP_INVALID_REPOSITORIES
    "Whether invalid repositories in the index should be skipped or otherwise terminate the script")

########################################################################################################################
set(CAPR_INITIALISED TRUE)

# include package components
include(${CAPR_MODULE_DIR}/CaprRepo.cmake)
include(${CAPR_MODULE_DIR}/CaprIndex.cmake)
include(${CAPR_MODULE_DIR}/CaprPlugin.cmake)

message(VERBOSE "===")
message(VERBOSE "[Capr] Copying Capr files...")
file(MAKE_DIRECTORY ${CAPR_HOME_DIR})
capr_internal_core_copy_file("index.json"        "${CAPR_INDEX_FILE}")
capr_internal_core_copy_file("configuration.ini" "${CAPR_CONFIG_FILE}")

message(VERBOSE "===")
message(VERBOSE "[Capr] Reading configuration...")
capr_internal_core_read_config("${CAPR_CONFIG_FILE}")

message(VERBOSE "===")
message(VERBOSE "[Capr] Parsing Capr index...")
capr_index_load("${CAPR_INDEX_FILE}")

########################################################################################################################
include_guard()

########################################################################################################################
cmake_minimum_required(3.20.5)

if (DEFINED CAPR_INITIALISED AND CAPR_INITIALISED)
    return()
endif()

############ CAPR DETAILS
set(CAPR_VERSION_MAJOR 0)
set(CAPR_VERSION_MINOR 1)
set(CAPR_VERSION_PATCH 0)

############ INTERNAL VARIABLES
set(CAPR_HASH_FAIL_MODES Terminate Delete Warn Ignore)
set(CAPR_OPTION_MODES Inherit False True)
set(CAPR_INITIALISED FALSE)

get_filename_component(CAPR_PACKAGE_DIR "${CMAKE_CURRENT_LIST_FILE}" REALPATH)
get_filename_component(CAPR_PACKAGE_DIR "${CAPR_PACKAGE_DIR}/.."     DIRECTORY)
get_filename_component(CAPR_MODULE_DIR  "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)

############ VARIABLES
if (WIN32)
    capr_internal_core_create_property(CAPR_HOME_DIR "The home directory of CAPR"
        TYPE PATH
        DEFAULT "$ENV{USERPROFILE}/.capr")
else()
    capr_internal_core_create_property(CAPR_HOME_DIR "The home directory of CAPR"
        TYPE PATH
        DEFAULT "$ENV{HOME}/.capr")
endif()

set(CAPR_CONFIG_FILE     "${CAPR_HOME_DIR}/configuration.ini")
set(CAPR_INDEX_FILE      "${CAPR_HOME_DIR}/index.json")
set(CAPR_MODULE_DEFAULTS "${CAPR_PACKAGE_DIR}/default")
set(CAPR_MODULE_INBUILTS "${CAPR_PACKAGE_DIR}/inbuilt")

############ PROPERTIES
capr_internal_core_create_property(CAPR_PLUGIN_DIR "The CAPR local plugin repository" TYPE PATH)
capr_internal_core_create_property(CAPR_HASH_FAIL_MODE "What should happen when a plugin wasn't succesfully verified"
    VALUESET ${CAPR_HASH_FAIL_MODES})

############ OPTIONS
capr_internal_core_create_option(CAPR_FORCE_DOWNLOAD
    "Whether downloads should be downloaded regardless a local version already exists or not")
capr_internal_core_create_option(CAPR_VERIFY_DOWNLOADS
    "Whether to compare the file's checksum with the remote checksum")
capr_internal_core_create_option(CAPR_SAME_PLUGIN_TERMINATES
    "Whether the script should terminate or just warn when the same plugin was included twice (version ignored)")

########################################################################################################################
function(capr_internal_core_create_property property_name description)
    cmake_parse_arguments(ARG "INTERNAL" "TYPE;DEFAULT" "VALUESET" ${ARGN})

    if ("${ARG_DEFAULT}" STREQUAL "" OR "DEFAULT" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
        set(default_value "")
    else()
        set(default_value "${ARG_DEFAULT}")
    endif()

    if ("${ARG_TYPE}" STREQUAL "" OR "TYPE" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
        set(${property_name} "${ARG_DEFAULT}" CACHE STRING "${description}" PARENT_SCOPE)
    else()
        set(${property_name} "${ARG_DEFAULT}" CACHE ${ARG_TYPE} "${description}" PARENT_SCOPE)
    endif()

    if (NOT "${ARG_VALUESET}" STREQUAL "" AND NOT "VALUESET" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
        set_property(CACHE ${property_name} PROPERTY STRINGS ${ARG_VALUESET})
    endif()

    if (ARG_INTERNAL)
        mark_as_advanced(${property_name})
    endif()
endfunction()

function(capr_internal_core_create_option option_name description)
    set(${option_name} "Inherit" CACHE STRING "${description}" PARENT_SCOPE)
    set_property(CACHE ${option_name} PROPERTY STRINGS ${CAPR_OPTION_MODES})
endfunction()

macro(capr_internal_core_set_option option_name value)
    string(TOLOWER "${${option_name}}" option_value)

    if (option_value STREQUAL "inherit")
        set(${option_name} "${value}" PARENT_SCOPE)
    endif()
endmacro()

macro(capr_internal_core_set_property property_name value)
    if ("${${property_name}}" STREQUAL "")
        set(${property_name} "${value}" PARENT_SCOPE)
    endif()
endmacro()

macro(capr_internal_core_include_inbuilt_plugin plugin_name)
    if (DEFINED capr_plugin_path_${plugin_name})
        message(FATAL_ERROR "Internal error: In-built plugin ${plugin_name} has already been included before")
    endif()

    string(TOLOWER ${plugin_name} plugin_name_lower)
    set(capr_plugin_path_${plugin_name} "${CAPR_MODULE_INBUILTS}/${plugin_name_lower}/${plugin_name}.cmake")

    if (NOT EXISTS capr_plugin_path_${plugin_name})
        message(FATAL_ERROR "Interanl error: In-built plugin ${plugin_name} does not exist")
    endif()

    include("${capr_plugin_path_${plugin_name}}")
endmacro()

function(capr_internal_core_read_config config_file)
    capr_internal_include_inbuilt_plugin("Houdini")

    houdini_set_defaults()
    set(HOUDINI_OVERRIDE_DUPLICATE ON)
    houdini_load(config "${config_file}")

    capr_internal_core_set_option(CAPR_FORCE_DOWNLOAD         "${config.core.forceDownloads}")
    capr_internal_core_set_option(CAPR_VERIFY_DOWNLOADS       "${config.core.verifyDownloads}")
    capr_internal_core_set_option(CAPR_SAME_PLUGIN_TERMINATES "${config.core.terminateOnClash}")

    capr_internal_core_set_property(CAPR_PLUGIN_DIR     "${config.paths.pluginDir}")
    capr_internal_core_set_property(CAPR_HASH_FAIL_MODE "${config.problems.hashMismatchMode}")
endfunction()

########################################################################################################################
set(CAPR_INITIALISED TRUE)

# include package components
include("${CAPR_MODULE_DIR}/CaprRepo.cmake")

# prepare filesets
file(MAKE_DIRECTORY ${CAPR_HOME_DIR})

if (NOT EXISTS CAPR_INDEX_FILE)
    file(COPY_FILE "${CAPR_MODULE_DEFAULTS}/repositories.json" "${CAPR_INDEX_FILE}")
endif()

if (NOT EXISTS CAPR_CONFIG_FILE)
    file(COPY_FILE "${CAPR_MODULE_DEFAULTS}/configuration.ini" "${CAPR_CONFIG_FILE}")
endif()

# configure capr
capr_internal_core_read_config("${CAPR_CONFIG_FILE}")
capr_internal_repository_parse_index("${CAPR_INDEX_FILE}")

include(${CAPR_MODULE_DIR}/CaprIniLoader.cmake)

macro(capr_internal_core_create_property property_name description)
    cmake_parse_arguments(ARG "INTERNAL" "TYPE;DEFAULT" "VALUESET" ${ARGN})

    if (NOT "${ARG_DEFAULT}" STREQUAL "" AND NOT "DEFAULT" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
        set(default_value "${ARG_DEFAULT}")
    endif()

    if ("${ARG_TYPE}" STREQUAL "" OR "TYPE" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
        set(${property_name} "${ARG_DEFAULT}" CACHE STRING "${description}")
    else()
        set(${property_name} "${ARG_DEFAULT}" CACHE ${ARG_TYPE} "${description}")
    endif()

    if (NOT "${ARG_VALUESET}" STREQUAL "" AND NOT "VALUESET" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
        set_property(CACHE ${property_name} PROPERTY STRINGS ${ARG_VALUESET})
    endif()

    if (ARG_INTERNAL)
        mark_as_advanced(${property_name})
    endif()

    unset(default_value)
endmacro()

macro(capr_internal_core_create_option option_name description)
    set(${option_name} "Inherit" CACHE STRING "${description}")
    set_property(CACHE ${option_name} PROPERTY STRINGS ${CAPR_OPTION_MODES})
endmacro()

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

function(capr_internal_core_include_inbuilt_plugin plugin_name required)
    string(TOLOWER ${plugin_name} plugin_name_lower)
    get_property(loaded_inbuilts GLOBAL PROPERTY CAPR_INBUILTS_LOADED)

    if (plugin_name_lower IN_LIST loaded_inbuilts)
        if (CAPR_SAME_PLUGIN_TERMINATES)
            message(FATAL_ERROR "In-built plugin '${plugin_name}' has already been applied before")
        endif()
    endif()

    if (NOT EXISTS "${CAPR_MODULE_INBUILTS}/${plugin_name_lower}.cmake")
        if (required)
            message(FATAL_ERROR "In-built plugin '${plugin_name}' could not be found, have you wrote it correctly?")
        else()
            message(WARNING "Could not find in-built plugin '${plugin_name}', skipping")
            return()
        endif()
    endif()

    include("${CAPR_MODULE_INBUILTS}/${plugin_name_lower}.cmake")
    set_property(GLOBAL APPEND PROPERTY CAPR_INBUILTS_LOADED ${plugin_name_lower})
endfunction()

macro(capr_internal_core_init_guard)
    if (NOT CAPR_INITIALISED)
        message(FATAL_ERROR "Tried to call a Capr module function before the plugin was initialised. \
            This can happen when you tried to include the wrong files or when Capr was modified")
    endif()
endmacro()

function(capr_internal_core_read_config config_file)
    capr_internal_load_config_file(config "${config_file}")

    # core settings
    capr_internal_core_set_option(CAPR_FORCE_DOWNLOAD         "${config.core.forceDownloads}")
    capr_internal_core_set_option(CAPR_VERIFY_DOWNLOADS       "${config.core.verifyDownloads}")
    capr_internal_core_set_option(CAPR_SAME_PLUGIN_TERMINATES "${config.core.terminateOnClash}")
    capr_internal_core_set_property(CAPR_HASH_FAIL_MODE       "${config.core.hashMismatchMode}")

    # path settings
    capr_internal_core_set_property(CAPR_PLUGIN_DIR "${config.paths.pluginDir}")
endfunction()

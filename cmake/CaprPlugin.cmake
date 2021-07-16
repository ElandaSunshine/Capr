########################################################################################################################
set(CAPR_PLUGIN_STRING_PATTERN
    [[^([a-zA-Z0-9_.]+):([a-zA-Z0-9_]+)@(([0-9].[0-9](.[0-9])?)|latest)(:(release|preview|beta))?$]])
set(CAPR_LOCAL_FOLDER_FORMAT "%package_path%/%id%/%version%-%version_type%/%id%-%version%.%ext%")

########################################################################################################################
function(capr_plugin)
    cmake_parse_arguments(ARG "DEFER" "PLUGIN;PACKAGE;ID;VERSION;VERSION_TYPE" "FALLBACK" ${ARGN})
    set(plugin_string_was_set TRUE)

    if ("${ARG_PLUGIN}" STREQUAL "" OR "PLUGIN" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
        set(temp_version_type "")

        if (NOT "${ARG_VERSION_TYPE}" STREQUAL "" AND NOT "VERSION_TYPE" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
            set(temp_version_type ":${ARG_VERSION_TYPE}")
        endif()

        set(ARG_PLUGIN "${ARG_PACKAGE}:${ARG_ID}@${ARG_VERSION}${temp_version_type}")
        set(plugin_string_was_set FALSE)
    elseif (   NOT "${ARG_PACKAGE}"      STREQUAL ""
            OR NOT "${ARG_ID}"           STREQUAL ""
            OR NOT "${ARG_VERSION}"      STREQUAL ""
            OR NOT "${ARG_VERSION_TYPE}" STREQUAL "")
        message(WARNING "Don't mix PLUGIN with any of PACKAGE, ID, VERSION, VERSION_TYPE")
    endif()

    capr_plugin_get_specs_from_string("${ARG_PLUGIN}" plugin DONT_WARN)

    if (NOT plugin_IS_VALID)
        if (plugin_string_was_set)
            message(FATAL_ERROR "The plugin string is insufficient, the format is 'package:id@version[:version_type]'")
        else()
            message(FATAL_ERROR "There was a problem with your plugin specification, one or multiple of ID, \
                                 PACKAGE, VERSION or VERSION_TYPE were invalid")
        endif()
    endif()

    string(REPLACE "." "_" plugin_PACKAGE_upper "${plugin_PACKAGE}")
    string(TOUPPER "${plugin_PACKAGE_upper}" plugin_PACKAGE_upper)
    string(TOUPPER "${plugin_ID}"            plugin_ID_upper)

    if ("CAPR_PLUGIN_${plugin_PACKAGE_upper}_${plugin_ID_upper}" IN_LIST CAPR_PLUGIN_LIST)

    endif()

    capr_plugin_convert_format_string("${CAPR_LOCAL_FOLDER_FORMAT}" plugin_path
        PACKAGE      "${plugin_PACKAGE}"
        ID           "${plugin_ID}"
        VERSION      "${plugin_VERSION}"
        VERSION_TYPE "${plugin_VERSION_TYPE}"
        EXTENSION    "cpa")

    capr_internal_include_inbuilt_plugin("cmaps")

    cmaps(PUT CAPR_PLUGIN_${plugin_PACKAGE_upper}_${plugin_ID_upper} "package"      "${plugin_PACKAGE}")
    cmaps(PUT CAPR_PLUGIN_${plugin_PACKAGE_upper}_${plugin_ID_upper} "id"           "${plugin_ID}")
    cmaps(PUT CAPR_PLUGIN_${plugin_PACKAGE_upper}_${plugin_ID_upper} "version"      "${plugin_VERSION}")
    cmaps(PUT CAPR_PLUGIN_${plugin_PACKAGE_upper}_${plugin_ID_upper} "version_type" "${plugin_VERSION_TYPE}")

    list(APPEND CAPR_PLUGIN_LIST CAPR_PLUGIN_${plugin_PACKAGE_upper}_${plugin_ID_upper})

    if (NOT EXISTS "${CAPR_PLUGIN_DIR}/${plugin_path}")
        set(plugin_must_download TRUE)
    endif()

    if (plugin_must_download AND NOT ARG_DEFER)

    endif()

endfunction()

function(capr_plugin_convert_format_string format_string out_string)
    cmake_parse_arguments(ARG "" "EXTENSION;PACKAGE;ID;VERSION;VERSION_TYPE" "" ${ARGN})

    string(REPLACE "." "/" package_parts "${ARG_PACKAGE}")
    string(REPLACE "." ";" version_parts "${ARG_VERSION}")

    list(GET    version_parts 0 plugin_version_major)
    list(GET    version_parts 1 plugin_version_minor)
    list(LENGTH version_parts   plugin_version_len)

    if (plugin_version_len EQUAL 3)
        list(GET version_parts 2 plugin_version_revision)
    endif()

    capr_internal_plugin_get_placeholder("package"      "${ARG_PACKAGE}"             "${format_string}")
    capr_internal_plugin_get_placeholder("id"           "${ARG_ID}"                  "${format_string}")
    capr_internal_plugin_get_placeholder("version"      "${ARG_VERSION}"             "${format_string}")
    capr_internal_plugin_get_placeholder("version_type" "${ARG_VERSION_TYPE}"        "${format_string}")
    capr_internal_plugin_get_placeholder("ext"          "${ARG_EXTENSION}"           "${format_string}")
    capr_internal_plugin_get_placeholder("package_path" "${package_parts}"           "${format_string}")
    capr_internal_plugin_get_placeholder("major"        "${plugin_version_major}"    "${format_string}")
    capr_internal_plugin_get_placeholder("minor"        "${plugin_version_minor}"    "${format_string}")
    capr_internal_plugin_get_placeholder("revision"     "${plugin_version_revision}" "${format_string}")

    set(${out_string} "${format_string}" PARENT_SCOPE)
endfunction()

function(capr_plugin_get_specs_from_string plugin_string out_prefix)
    cmake_parse_arguments(ARG "DONT_WARN" "" "" ${ARGN})

    if ("${plugin_string}" MATCHES CAPR_PLUGIN_STRING_PATTERN)
        set(${out_prefix}_PACKAGE      ${CMAKE_MATCH_1} PARENT_SCOPE)
        set(${out_prefix}_ID           ${CMAKE_MATCH_2} PARENT_SCOPE)
        set(${out_prefix}_VERSION      ${CMAKE_MATCH_3} PARENT_SCOPE)
        set(${out_prefix}_VERSION_TYPE ${CMAKE_MATCH_7} PARENT_SCOPE)
        set(${out_prefix}_IS_VALID     TRUE)
        return()
    elseif(NOT ARG_DONT_WARN)
        message(WARNING "Plugin string '${plugin_string}' was invalid, \
                         it must follow the format: package:id@version[:version_type]")
    endif()

    set(${out_prefix}_IS_VALID FALSE)
endfunction()

########################################################################################################################
macro(capr_internal_plugin_get_placeholder placeholder_name placeholder_replacement in_out_string)
    string(REPLACE "%${placeholder_name}%" "${placeholder_replacement}" in_out_string "${in_out_string}")
endmacro()

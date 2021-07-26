include(${CAPR_MODULE_DIR}/CaprIniLoader.cmake)

macro(capr_internal_core_create_property property_name description)
    cmake_parse_arguments(ARG "INTERNAL;NO_CONFIG" "TYPE;DEFAULT" "VALUESET" ${ARGN})

    if ("${ARG_TYPE}" STREQUAL "")
        set(${property_name} "${ARG_DEFAULT}" CACHE STRING "${description}")
    else()
        set(${property_name} "${ARG_DEFAULT}" CACHE ${ARG_TYPE} "${description}")
    endif()

    message(VERBOSE "[Capr] Created property ${property_name} with value \"${${property_name}}\"")

    if (NOT "${ARG_VALUESET}" STREQUAL "")
        set_property(CACHE ${property_name} PROPERTY STRINGS ${ARG_VALUESET})
    endif()

    if (${ARG_INTERNAL})
        mark_as_advanced(${property_name})
    endif()
    
    if (NOT ${ARG_NO_CONFIG})
        list(APPEND CAPR_CONFIG_PROPERTIES ${property_name})
    endif()
endmacro()

macro(capr_internal_core_create_option option_name description)
    cmake_parse_arguments(ARG "NO_CONFIG" "" "" ${ARGN})

    set(${option_name} "Inherit" CACHE STRING "${description}")
    set_property(CACHE ${option_name} PROPERTY STRINGS ${CAPR_OPTION_MODES})
    message(VERBOSE "[Capr] Created option ${option_name} with value \"${${option_name}}\"")

    if (NOT ${ARG_NO_CONFIG})
        list(APPEND CAPR_CONFIG_OPTIONS "${option_name}")
    endif()
endmacro()

macro(capr_internal_core_set_option option_name value)
    string(TOLOWER "${${option_name}}" option_value)

    if ("${option_value}" STREQUAL "inherit")
        set(${option_name} "${value}" PARENT_SCOPE)
        message(VERBOSE "[Capr] Set option ${option_name} to \"${value}\"")
    else()
        message(VERBOSE "[Capr] Option ${option_name} has been found in cache with value \"${value}\", skipping")
    endif()
endmacro()

macro(capr_internal_core_set_property property_name value)
    if ("${${property_name}}" STREQUAL "")
        set(${property_name} "${value}" PARENT_SCOPE)
        message(VERBOSE "[Capr] Set property ${property_name} to \"${value}\"")
    else()
        message(VERBOSE "[Capr] Property ${option_name} has been found in cache with value \"${value}\", skipping")
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
    if (NOT ${CAPR_INITIALISED})
        message(FATAL_ERROR "Tried to call a Capr module function before the plugin was initialised. \
            This can happen when you tried to include the wrong files or when Capr was modified")
    endif()
endmacro()

function(capr_internal_core_read_config config_file)
    capr_internal_load_config_file(config "${config_file}")
    
    foreach(option IN LISTS CAPR_CONFIG_OPTIONS)
        string(REPLACE "CAPR_" "" option_mod "${option}")
        string(TOLOWER "${option_mod}" option_mod)
        
        while("${option_mod}" MATCHES "_([a-z])")
            string(TOUPPER "${CMAKE_MATCH_1}" separator)
            string(REPLACE "_${CMAKE_MATCH_1}" "${separator}" option_mod "${option_mod}")
        endwhile()
        
        string(TOUPPER "${config.options.${option_mod}}" out_value)
        capr_internal_core_set_option(${option} "${out_value}")
    endforeach()
    
    foreach(property IN LISTS CAPR_CONFIG_PROPERTIES)
        string(REPLACE "CAPR_" "" property_mod "${property}")
        string(TOLOWER "${property_mod}" property_mod)
        
        while("${property_mod}" MATCHES "_([a-z])")
            string(TOUPPER "${CMAKE_MATCH_1}" separator)
            string(REPLACE "_${CMAKE_MATCH_1}" "${separator}" property_mod "${property_mod}")
        endwhile()

        capr_internal_core_set_property(${property} "${config.properties.${property_mod}}")
    endforeach()
endfunction()

function(capr_internal_core_http_request method)
    if ("${method}" STREQUAL "GET")
        if (${ARGC} LESS 3)
            message(FATAL_ERROR "No request url or output variable given")
        endif()

        cmake_parse_arguments(PARSE_ARGV 3 ARG "" "EXPORT;STATUS" "PARAMETERS")
        set(get_string "")

        if (NOT "${ARG_PARAMETERS}" STREQUAL "")
            list(LENGTH ARG_PARAMETERS parameter_len)
            math(EXPR parameter_last_index "${parameter_len}-1")

            foreach(i RANGE ${parameter_last_index})
                list(GET ARG_PARAMETERS ${i} parameter)

                if ("${parameter}" MATCHES "^([a-zA-Z0-9_\\-]+)=([a-zA-Z0-9_\\-]*)$")
                    if (${i} GREATER 0)
                        string(APPEND get_string "&")
                    endif()

                    string(APPEND get_string "${parameter}")
                else()
                    message(FATAL_ERROR "Internal error, GET parameter has invalid format: ${parameter}")
                endif()
            endforeach()

            if (NOT "${get_string}" STREQUAL "")
                set(get_string "?${get_string}")
            endif()
        endif()

        file(DOWNLOAD "${ARGV2}${get_string}" "${CMAKE_BINARY_DIR}/__cmake_http_request_response.json"
            STATUS op_status)
        file(READ   "${CMAKE_BINARY_DIR}/__cmake_http_request_response.json" response_output)
        file(REMOVE "${CMAKE_BINARY_DIR}/__cmake_http_request_response.json")
    elseif("${method}" STREQUAL "PUT")
        if (${ARGC} LESS 4)
            message(FATAL_ERROR "No request url, output variable or content was given")
        endif()

        cmake_parse_arguments(PARSE_ARGV 4 ARG "" "EXPORT;STATUS" "")

        file(WRITE "${CMAKE_BINARY_DIR}/__cmake_http_request_request.json" "${ARGV3}")
        file(UPLOAD "${CMAKE_BINARY_DIR}/__cmake_http_request_request.json" "${ARGV2}"
            HTTPHEADER "Content-Type: application/json"
            STATUS     op_status
            LOG        request_log)
        file(REMOVE "${CMAKE_BINARY_DIR}/__cmake_http_request_request.json")

        string(REPLACE "\n" ";" lines "${request_log}")

        foreach(line IN LISTS lines)
            if ("${line}" MATCHES "^([a-zA-Z0-9_\\-]+):[ \t\n\r]*$")
                if ("${CMAKE_MATCH_1}" STREQUAL "Response")
                    set(parse_response TRUE)
                    continue()
                endif()

                break()
            endif()

            if (${parse_response})
                string(APPEND response_output "${line}\n")
            endif()
        endforeach()
    else()
        message(FATAL_ERROR "Invalid request method '${method}', allowed are PUT and GET")
    endif()

    list(GET op_status 0 op_code)
    list(GET op_status 1 op_message)
    
    if (NOT "${ARG_STATUS}" STREQUAL "")
        set(${ARG_STATUS} ${op_status} PARENT_SCOPE)
    endif()
    
    if (${op_code} EQUAL 0)
        if (NOT "${ARG_EXPORT}" STREQUAL "")
            file(WRITE "${ARG_EXPORT}" "${response_output}")
        endif()

        set(${ARGV1} "${response_output}" PARENT_SCOPE)
        return()
    endif()

    if ("${ARG_STATUS}" STREQUAL "")
        message(FATAL_ERROR "Error (${op_code}) processing http request: ${op_message}")
    endif()
endfunction()

function(capr_internal_core_copy_file file_name destination)
    message(VERBOSE "[Capr] Copying '${file_name}'")
    
    if (NOT EXISTS "${destination}")
        file(COPY_FILE "${CAPR_MODULE_DEFAULTS}/${file_name}" "${destination}")
        message(VERBOSE "[Capr] Copied '${file_name}' to: ${destination}")
    else()
        message(VERBOSE "[Capr] File '${destination}' already exists, skipping")
    endif()
endfunction()

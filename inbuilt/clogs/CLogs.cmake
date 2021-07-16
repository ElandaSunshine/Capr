########################################################################################################################
include_guard()

########################################################################################################################
macro(clogs_create logger_name)
    string(TOLOWER "${logger_name}" logger_name_lower)
    clogs_internal_test_logger_exists("${logger_name_lower}" logger_exists)

    if (logger_exists)
        message(WARNING "Logger '${logger_name}' could not be created, there was already a logger with that name")
    else()
        cmake_parse_arguments(ARG "KEEP_UNKNOWN;KEEP_UNEXPANDED;NOCACHE" "TARGET" "LOG_FORMAT" ${ARGN})

        if (NOT "${ARG_TARGET}" STREQUAL "" AND NOT "TARGET" IN_LIST ARG_KEYWORDS_MISSING_VALUES AND NOT TARGET ARG_TARGET)
            message(WARNING "Logger could not be created for target '${ARG_TARGET}', target doesn't exist")
        else()
            if ("${ARG_LOG_FORMAT}" STREQUAL "" OR "LOG_FORMAT" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
                set(ARG_LOG_FORMAT "%message%")
            endif()

            set(CLOGS_${logger_name}_TARGET  "${ARG_TARGET}")
            set(CLOGS_${logger_name}_KUN     "${ARG_KEEP_UNKNOWN}")
            set(CLOGS_${logger_name}_KUX     "${ARG_KEEP_UNEXPANDED}")
            set(CLOGS_${logger_name}_FORMAT  "${ARG_LOG_FORMAT}")

            if (ARG_NOCACHE)
                set(CLOGS_${logger_name}_CACHING FALSE)
            else()
                set(CLOGS_${logger_name}_CACHING TRUE)
            endif()

            list(APPEND CLOGS_LOGGERS "${logger_name}")
            clogs_internal_create_log_functions(${logger_name})
        endif()
    endif()
endmacro()

function(clogs_internal_test_logger_exists logger_name out_var)
    foreach(lname IN LISTS CLOGS_LOGGERS)
        string(TOLOWER "${lname}" llname)

        if ("${logger_name}" STREQUAL "${llname}")
            set(${out_var} TRUE PARENT_SCOPE)
            return()
        endif()
    endforeach()

    set(${out_var} FALSE PARENT_SCOPE)
endfunction()

macro(clogs_internal_create_log_functions logger_name)
    function(${logger_name}_log level message)
        string(TOLOWER ${level} log_level)

        set(output "${CLOGS_${logger_name}_FORMAT}")

        if ("${log_level}" STREQUAL "fatal_error")
            clogs_internal_format_message(output ${CLOGS_${logger_name}_KUN} ${CLOGS_${logger_name}_KUX}
                "${message}" "${CLOGS_${logger_name}_TARGET}" "${logger_name}" "${level}")
            message(FATAL_ERROR "${output}")
        elseif("${log_level}" STREQUAL "send_error")
            clogs_internal_format_message(output ${CLOGS_${logger_name}_KUN} ${CLOGS_${logger_name}_KUX}
                "${message}" "${CLOGS_${logger_name}_TARGET}" "${logger_name}" "${level}")
            message(SEND_ERROR "${output}")
        elseif("${log_level}" STREQUAL "warning")
            clogs_internal_format_message(output ${CLOGS_${logger_name}_KUN} ${CLOGS_${logger_name}_KUX}
                "${message}" "${CLOGS_${logger_name}_TARGET}" "${logger_name}" "${level}")
            message(WARNING "${output}")
        elseif("${log_level}" STREQUAL "status")
            clogs_internal_format_message(output ${CLOGS_${logger_name}_KUN} ${CLOGS_${logger_name}_KUX}
                "${message}" "${CLOGS_${logger_name}_TARGET}" "${logger_name}" "${level}")
            message(STATUS "${output}")
        elseif("${log_level}" STREQUAL "verbose")
            clogs_internal_format_message(output ${CLOGS_${logger_name}_KUN} ${CLOGS_${logger_name}_KUX}
                "${message}" "${CLOGS_${logger_name}_TARGET}" "${logger_name}" "${level}")
            message(VERBOSE "${output}")
        elseif("${log_level}" STREQUAL "debug")
            clogs_internal_format_message(output ${CLOGS_${logger_name}_KUN} ${CLOGS_${logger_name}_KUX}
                "${message}" "${CLOGS_${logger_name}_TARGET}" "${logger_name}" "${level}")
            message(DEBUG "${output}")
        elseif("${log_level}" STREQUAL "trace")
            clogs_internal_format_message(output ${CLOGS_${logger_name}_KUN} ${CLOGS_${logger_name}_KUX}
                "${message}" "${CLOGS_${logger_name}_TARGET}" "${logger_name}" "${level}")
            message(TRACE "${output}")
        else()
            clogs_internal_format_message(output ${CLOGS_${logger_name}_KUN} ${CLOGS_${logger_name}_KUX}
                "${message}" "${CLOGS_${logger_name}_TARGET}" "${logger_name}" "NOTICE")
            message(NOTICE "${output}")
        endif()

        if (CLOGS_${logger_name}_CACHING)
            string(REPLACE ";" "\;" output "${output}")
            list(APPEND CLOGS_LOG_CACHE_${logger_name} "${output}")
            set(CLOGS_LOG_CACHE_${logger_name} "${CLOGS_LOG_CACHE_${logger_name}}" PARENT_SCOPE)
        endif()
    endfunction()

    macro(${logger_name}_error message)
        cmake_language(CALL "${logger_name}_log" SEND_ERROR "${message}")
    endmacro()
    macro(${logger_name}_fatal message)
        cmake_language(CALL "${logger_name}_log" FATAL_ERROR "${message}")
    endmacro()
    macro(${logger_name}_warn message)
        cmake_language(CALL "${logger_name}_log" WARNING "${message}")
    endmacro()
    macro(${logger_name}_status message)
        cmake_language(CALL "${logger_name}_log" STATUS "${message}")
    endmacro()
    macro(${logger_name}_verbose message)
        cmake_language(CALL "${logger_name}_log" VERBOSE "${message}")
    endmacro()
    macro(${logger_name}_debug message)
        cmake_language(CALL "${logger_name}_log" DEBUG "${message}")
    endmacro()
    macro(${logger_name}_trace message)
        cmake_language(CALL "${logger_name}_log" TRACE "${message}")
    endmacro()
    macro(${logger_name}_info message)
        cmake_language(CALL "${logger_name}_log" NOTICE "${message}")
    endmacro()
    macro(${logger_name}_notice message)
        cmake_language(CALL "${logger_name}_log" NOTICE "${message}")
    endmacro()
    macro(${logger_name}_empty)
        message("")
        list(APPEND CLOGS_LOG_CACHE_${logger_name} "")
    endmacro()
endmacro()

macro(clogs_internal_replace placeholder input)
    string(REPLACE "%${placeholder}%" "${input}" ${message_format} "${${message_format}}")
endmacro()

macro(clogs_internal_replace_target_properties target)
    get_target_property(target_defs ${target} COMPILE_DEFINITIONS)
    clogs_internal_replace("target_definitions" "${target_defs}")
    get_target_property(target_sources ${target} SOURCES)
    clogs_internal_replace("target_sources" "${target_sources}")
    get_target_property(target_headers_private ${target} PRIVATE_HEADER)
    clogs_internal_replace("target_headers_private" "${target_headers_private}")
    get_target_property(target_headers_public ${target} PUBLIC_HEADER)
    clogs_internal_replace("target_headers_public" "${target_headers_public}")
endmacro()

function(clogs_internal_format_message message_format keep_unknown keep_unexpanded message target logger_name logger_level)
    clogs_internal_replace("message" "${message}")

    string(TIMESTAMP ${message_format} "${${message_format}}")
    clogs_internal_replace("name" "${logger_name}")

    clogs_internal_replace("level" "${logger_level}")
    string(TOLOWER ${logger_level} logger_level)
    clogs_internal_replace("level_lower" "${logger_level}")
    string(TOUPPER ${logger_level} logger_level)
    clogs_internal_replace("level_upper" "${logger_level}")

    if ("${target}" STREQUAL "")
        if (NOT keep_unexpanded)
            clogs_internal_replace("target" "")
        endif()
    else()
        clogs_internal_replace("target" "${target}")
        clogs_internal_replace_target_properties(${target})
    endif()

    if (NOT keep_unknown)
        string(REGEX REPLACE "%[^ \t]+%" "" ${message_format} "${${message_format}}")
    endif()

    set(${message_format} "${${message_format}}" PARENT_SCOPE)
endfunction()

function(clogs_internal_get_log_cache_for_logger logger_name cache_out)
    foreach(lname IN LISTS CLOGS_LOGGERS)
        string(TOLOWER "${lname}" llname)

        if ("${logger_name}" STREQUAL "${llname}")
            set(${cache_out} CLOGS_LOG_CACHE_${lname} PARENT_SCOPE)
            return()
        endif()
    endforeach()
endfunction()

function(clogs_internal_get_property_for_logger logger_name property_name property_out)
    foreach(lname IN LISTS CLOGS_LOGGERS)
        string(TOLOWER "${lname}" llname)

        if ("${logger_name}" STREQUAL "${llname}")
            set(${property_out} CLOGS_${lname}_${property_name} PARENT_SCOPE)
            return()
        endif()
    endforeach()
endfunction()

function(clogs_dump logger_name output_file)
    string(TOLOWER ${logger_name} logger_name_lower)
    clogs_internal_test_logger_exists(${logger_name_lower} logger_exists)

    if (NOT logger_exists)
        message(WARNING "Could not dump log for logger '${logger_name}', no such logger")
        return()
    endif()

    clogs_internal_get_property_for_logger(${logger_name_lower} CACHING out_caching)

    if (NOT ${out_caching})
        message(WARNING "Could not dump log for logger '${logger_name}', caching was disabled")
    endif()

    clogs_internal_get_log_cache_for_logger(${logger_name_lower} out_cache)

    list(JOIN ${out_cache} "\n" content)
    file(WRITE ${output_file} "${content}")
    message(STATUS "Dumped log '${logger_name}': ${output_file}")
endfunction()


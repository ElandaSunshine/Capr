########################################################################################################################
include_guard()

########################################################################################################################
set(CSON_DEFAULT_SEVERITY "FATAL_ERROR" CACHE STRING "The default log level for any CSON function call")
set(CSON_COMMENT_KEYWORD  ""            CACHE STRING "Specifies a keyword that behaves as a comment and will not be included in the parse tree, if left empty no key will be treated as a comment")

option(CSON_ONLY_STRINGS_ARE_COMMENTS "If comments are enabled, then only string values will be treated as comments, otherwise all types will be treated as comments" ON)

########################################################################################################################
macro(cson_internal_log_message)
    if (NOT "${parse_error}" STREQUAL "NOTFOUND" AND NOT "${parse_error}" STREQUAL "")
        if (NOT DEFINED ARG_SEVERITY OR "SEVERITY" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
            set(ARG_SEVERITY "${CSON_DEFAULT_SEVERITY}")
        endif()

        string(TOLOWER ${ARG_SEVERITY} log_severity)

        if ("${log_severity}" STREQUAL "fatal_error")
            message(FATAL_ERROR "${parse_error}")
        elseif("${log_severity}" STREQUAL "send_error")
            message(SEND_ERROR "${parse_error}")
        elseif("${log_severity}" STREQUAL "warning")
            message(WARNING "${parse_error}")
        elseif("${log_severity}" STREQUAL "status")
            message(STATUS "${parse_error}")
        elseif("${log_severity}" STREQUAL "verbose")
            message(VERBOSE "${parse_error}")
        elseif("${log_severity}" STREQUAL "debug")
            message(DEBUG "${parse_error}")
        elseif("${log_severity}" STREQUAL "trace")
            message(TRACE "${parse_error}")
        else()
            message(NOTICE "${parse_error}")
        endif()
    endif()
endmacro()

macro(cson_internal_json output)
    string(JSON ${output} ERROR_VARIABLE parse_error ${ARGN})
    cson_internal_log_message()
endmacro()

macro(cson_internal_process_member member_prefix member type)
    if ("${member_prefix}" STREQUAL "")
        set(${member_prefix}_opt_dot "")
    else()
        set(${member_prefix}_opt_dot cson)
    endif()

    if ("${type}" STREQUAL "ARRAY" OR "${type}" STREQUAL "OBJECT")
        cson_internal_json(
            ${member_prefix}_member_length
            LENGTH ${member})

        math(EXPR ${member_prefix}_last_index "${${member_prefix}_member_length} - 1")

        if ("${type}" STREQUAL "ARRAY")
            if (${${member_prefix}_member_length} GREATER 0)
                foreach(${member_prefix}_i RANGE ${${member_prefix}_last_index})
                    cson_internal_json(
                        ${member_prefix}_${${member_prefix}_i}_type
                        TYPE ${member} ${${member_prefix}_i})

                    cson_internal_json(
                        ${member_prefix}_${${member_prefix}_i}_value
                        GET ${member} ${${member_prefix}_i})

                    if ("${${member_prefix}_${${member_prefix}_i}_type}" STREQUAL "ARRAY" OR "${${member_prefix}_${${member_prefix}_i}_type}" STREQUAL "OBJECT")
                        cson_internal_process_member(
                            ${member_prefix}+${${member_prefix}_i}
                            "${${member_prefix}_${${member_prefix}_i}_value}"
                            "${${member_prefix}_${${member_prefix}_i}_type}")
                        
                        list(APPEND ${member_prefix}_result ${prefix}${${member_prefix}_opt_dot}${member_prefix}+${${member_prefix}_i})
                    else()
                        list(APPEND ${member_prefix}_result ${${member_prefix}_${${member_prefix}_i}_value})
                        set(${prefix}${${member_prefix}_opt_dot}${member_prefix}+${${member_prefix}_i} ${${member_prefix}_${${member_prefix}_i}_value} PARENT_SCOPE)
                    endif()
                endforeach()
            endif()

            if (NOT "${member_prefix}" STREQUAL "")
                list(APPEND CSON_LIST_ARRAY_${prefix} ${prefix}${${member_prefix}_opt_dot}${member_prefix})
            endif()

            list(APPEND CSON_LIST_JSON_${prefix} "${prefix}${${member_prefix}_opt_dot}${member_prefix};${member}")
        else()
            if (${${member_prefix}_member_length} GREATER 0)
                foreach(${member_prefix}_i RANGE ${${member_prefix}_last_index})
                    cson_internal_json(
                        ${member_prefix}_${${member_prefix}_i}_name
                        MEMBER ${member} ${${member_prefix}_i})

                    cson_internal_json(
                        ${member_prefix}_${${member_prefix}_i}_type
                        TYPE ${member} ${${member_prefix}_${${member_prefix}_i}_name})

                    cson_internal_json(
                        ${member_prefix}_${${member_prefix}_i}_value
                        GET ${member} ${${member_prefix}_${${member_prefix}_i}_name})

                    if (NOT "${CSON_COMMENT_KEYWORD}" STREQUAL "" AND "${${member_prefix}_${${member_prefix}_i}_name}" STREQUAL "${CSON_COMMENT_KEYWORD}")
                        if (NOT CSON_ONLY_STRINGS_ARE_COMMENTS OR "${${member_prefix}_${${member_prefix}_i}_type}" STREQUAL "STRING")
                            list(APPEND CSON_LIST_COMMENTS_${prefix} "${prefix}${member_prefix}:${${member_prefix}_i}|${${member_prefix}_${${member_prefix}_i}_value}")
                            continue()
                        endif()
                    endif()

                    cson_internal_process_member(
                        ${member_prefix}${${member_prefix}_opt_dot}${${member_prefix}_${${member_prefix}_i}_name}
                        "${${member_prefix}_${${member_prefix}_i}_value}"
                        "${${member_prefix}_${${member_prefix}_i}_type}")

                    list(APPEND ${member_prefix}_result ${prefix}${${member_prefix}_opt_dot}${member_prefix}.${${member_prefix}_${${member_prefix}_i}_name})
                endforeach()

                list(APPEND CSON_LIST_JSON_${prefix} "${prefix}${${member_prefix}_opt_dot}${member_prefix};${member}")
            endif()

            if (NOT "${member_prefix}" STREQUAL "")
                list(APPEND CSON_LIST_OBJECT_${prefix} ${prefix}${${member_prefix}_opt_dot}${member_prefix})
            endif()
        endif()
    else()
        set(${member_prefix}_result ${member})

        if ("${type}" STREQUAL "NUMBER")
            list(APPEND CSON_LIST_NUMBER_${prefix} ${member_prefix})
        elseif("${type}" STREQUAL "STRING")
            list(APPEND CSON_LIST_STRING_${prefix} ${member_prefix})
        elseif("${type}" STREQUAL "BOOLEAN")
            list(APPEND CSON_LIST_BOOL_${prefix} ${member_prefix})
        else()
            list(APPEND CSON_LIST_NULL_${prefix} ${member_prefix})
        endif()
    endif()

    set(${prefix}${${member_prefix}_opt_dot}${member_prefix} ${${member_prefix}_result} PARENT_SCOPE)
endmacro()

function(cson_parse_json prefix json_text)
    cmake_parse_arguments(ARG "" "SEVERITY" "" ${ARGN})

    string(TOLOWER "${prefix}" lower_prefix)

    if ("${lower_prefix}" MATCHES "^cson")
        set(parse_error "A prefix can't start with ${prefix}")
        cson_internal_log_message()
    endif()

    cson_internal_json(
        root_type
        TYPE "${json_text}")

    cson_internal_process_member("" "${json_text}" "${root_type}")

    set(CSON_LIST_NUMBER_${prefix}   ${CSON_LIST_NUMBER_${prefix}}   PARENT_SCOPE)
    set(CSON_LIST_STRING_${prefix}   ${CSON_LIST_STRING_${prefix}}   PARENT_SCOPE)
    set(CSON_LIST_BOOL_${prefix}     ${CSON_LIST_BOOL_${prefix}}     PARENT_SCOPE)
    set(CSON_LIST_NULL_${prefix}     ${CSON_LIST_NULL_${prefix}}     PARENT_SCOPE)
    set(CSON_LIST_ARRAY_${prefix}    ${CSON_LIST_ARRAY_${prefix}}    PARENT_SCOPE)
    set(CSON_LIST_OBJECT_${prefix}   ${CSON_LIST_OBJECT_${prefix}}   PARENT_SCOPE)
    set(CSON_LIST_COMMENTS_${prefix} ${CSON_LIST_COMMENTS_${prefix}} PARENT_SCOPE)
    set(CSON_LIST_JSON_${prefix}     ${CSON_LIST_JSON_${prefix}}     PARENT_SCOPE)
endfunction()

function(cson_load prefix json_file)
    cmake_parse_arguments(ARG "" "SEVERITY" "" ${ARGN})

    if (NOT EXISTS json_file)
        set(parse_error "Could not find file ${json_file}")
        cson_internal_log_message()
        return()
    endif()

    file(READ ${json_file} json_file_output)
    cson_parse_json(${prefix} "${json_file_output}" SEVERITY ${ARG_SEVERITY})
endfunction()

macro(cson_set_defaults)
    set(CSON_DEFAULT_SEVERITY          "FATAL_ERROR")
    set(CSON_COMMENT_KEYWORD           "")
    set(CSON_ONLY_STRINGS_ARE_COMMENTS ON)
endmacro()

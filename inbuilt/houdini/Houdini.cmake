########################################################################################################################
include_guard()

########################################################################################################################
set(HOUDINI_DEFAULT_SEVERITY  "FATAL_ERROR" CACHE STRING "The default log level for any Houdini function call")

set(HOUDINI_COMMENT_CHARACTER "\;"          CACHE STRING
    "The character that should initiate a line as a comment, this is ';' by default, some parsers also use '#'")

########################################################################################################################
option(HOUDINI_OVERRIDE_DUPLICATE
       "Whether Houdini should error when a given key or value was found twice or if it should be overriden" OFF)
option(HOUDINI_IGNORE_LEADING_WHITESPACES
       "Whether whitespaces before a key, section, comment sign and equal sign and after an equal sign up to \
        the first non-space character should be ignored or not. If this is off, \
        subsequent spaces after an equal sign will error" ON)

########################################################################################################################
macro(houdini_internal_log_message)
    if (NOT "${parse_error}" STREQUAL "NOTFOUND" AND NOT "${parse_error}" STREQUAL "")
        if (NOT DEFINED ARG_SEVERITY OR "SEVERITY" IN_LIST ARG_KEYWORDS_MISSING_VALUES)
            set(ARG_SEVERITY "${HOUDINI_DEFAULT_SEVERITY}")
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

function(houdini_parse_ini prefix ini_text)
    cmake_parse_arguments(ARG "" "SEVERITY" "" ${ARGN})

    string(TOLOWER "${prefix}" lower_prefix)

    if ("${lower_prefix}" MATCHES "^houdini")
        set(parse_error "A prefix can't start with ${prefix}")
        houdini_internal_log_message()
    endif()

    string(REPLACE ";"    "\;" lines "${ini_text}" )
    string(REPLACE "\r\n" ";"  lines "${lines}")
    string(REPLACE "\n"   ";"  lines "${lines}")

    list(LENGTH lines lines_num)
    math(EXPR lines_num "${lines_num} - 1")

    foreach(i RANGE ${lines_num})
        list(GET lines ${i} line)

        math(EXPR line_info "${i}+1")

        # ignore sequences
        if ("${line}" MATCHES "^([\t ]*)${HOUDINI_COMMENT_CHARACTER}.*$" OR "${line}" MATCHES [[^[\t ]*$]])
            if (NOT HOUDINI_IGNORE_LEADING_WHITESPACES AND CMAKE_MATCH_COUNT GREATER 0)
                set(parse_error "Leading whitespaces are illegal, enable HOUDINI_IGNORE_LEADING_WHITESPACES to turn this rule off:${line_info}")
                houdini_internal_log_message()
                return()
            endif()
            continue()
        endif()

        if("${line}" MATCHES [[^([\t ]*)([^\t ]*)([\t ]*)=([\t ]*)(.*)$]])
            if ("${current_section}" STREQUAL "")
                set(parse_error "Trying to set properties without declaring a previous section:${line_info}")
                houdini_internal_log_message()
                return()
            endif()

            if (NOT HOUDINI_IGNORE_LEADING_WHITESPACES)
                if (NOT "${CMAKE_MATCH_1}" STREQUAL "" OR NOT "${CMAKE_MATCH_3}" STREQUAL "" OR NOT "${CMAKE_MATCH_4}" STREQUAL "")
                    set(parse_error "Leading whitespaces are illegal, enable HOUDINI_IGNORE_LEADING_WHITESPACES to turn this rule off:${line_info}")
                    houdini_internal_log_message()
                    return()
                endif()
            endif()

            if ("${CMAKE_MATCH_2}" STREQUAL "")
                set(parse_error "No key was specified:${line_info}")
                houdini_internal_log_message()
                return()
            endif()

            if ("${prefix}.${current_section}.${CMAKE_MATCH_2}" IN_LIST ${prefix}.${current_section})
                if (NOT HOUDINI_OVERRIDE_DUPLICATE)
                    set(parse_error "Key '${CMAKE_MATCH_2}' was already declared earlier for section '${current_section}', if you want to enable property overriding then make sure \
                                     to set HOUDINI_OVERRIDE_DUPLICATE to ON:${line_info}")
                    houdini_internal_log_message()
                endif()
            endif()

            set(${prefix}.${current_section}.${CMAKE_MATCH_2} "${CMAKE_MATCH_5}" PARENT_SCOPE)
            list(APPEND ${prefix}.${current_section} "${prefix}.${current_section}.${CMAKE_MATCH_2}")
        elseif("${line}" MATCHES [[^([\t ]*)\[([\t ]*)([^\t ]*)([\t ]*)\][\t ]*$]])
            if (NOT HOUDINI_IGNORE_LEADING_WHITESPACES)
                if (NOT "${CMAKE_MATCH_1}" STREQUAL "" OR NOT "${CMAKE_MATCH_2}" STREQUAL "" OR NOT "${CMAKE_MATCH_4}" STREQUAL "")
                    set(parse_error "Leading whitespaces are illegal, enable HOUDINI_IGNORE_LEADING_WHITESPACES to turn this rule off:${line_info}")
                    houdini_internal_log_message()
                    return()
                endif()
            endif()

            if ("${CMAKE_MATCH_3}" STREQUAL "")
                set(parse_error "Section contains no identifier:${line_info}")
                houdini_internal_log_message()
                return()
            endif()

            if ("${prefix}.${CMAKE_MATCH_3}" IN_LIST ${prefix})

                if (NOT HOUDINI_OVERRIDE_DUPLICATE)
                    set(parse_error "Section '${CMAKE_MATCH_3}' was already declared earlier, if you want to enable section overriding then make sure \
                                     to set HOUDINI_OVERRIDE_DUPLICATE to ON:${line_info}")
                    houdini_internal_log_message()
                endif()
            else()
                list(APPEND ${prefix} "${prefix}.${CMAKE_MATCH_3}")
            endif()

            set(current_section "${CMAKE_MATCH_3}")
        else()
            if (NOT HOUDINI_OVERRIDE_DUPLICATE)
                set(parse_error "Invalid character sequence, only section headings, key-value pairs, comments and empty lines are allowed:${line_info}")
                houdini_internal_log_message()
            endif()
        endif()
    endforeach()

    set(${prefix} "${${prefix}}" PARENT_SCOPE)

    foreach(section IN LISTS ${prefix})
        if ("${section}" STREQUAL "")
            set(${section} "IGNORE" PARENT_SCOPE)
        else()
            set(${section} "${${section}}" PARENT_SCOPE)
        endif()
    endforeach()
endfunction()

function(houdini_load prefix ini_file)
    cmake_parse_arguments(ARG "" "SEVERITY" "" ${ARGN})

    if (NOT EXISTS ini_file)
        set(parse_error "Could not find file ${ini_file}")
        houdini_internal_log_message()
        return()
    endif()

    file(READ ${ini_file} ini_file_output)
    houdini_parse_ini(${prefix} "${ini_file_output}" SEVERITY ${ARG_SEVERITY})
endfunction()

macro(houdini_set_defaults)
    set(HOUDINI_DEFAULT_SEVERITY "FATAL_ERROR")
    set(HOUDINI_COMMENT_CHARACTER "\;")
    set(HOUDINI_OVERRIDE_DUPLICATE OFF)
    set(HOUDINI_IGNORE_LEADING_WHITESPACES ON)
endmacro()

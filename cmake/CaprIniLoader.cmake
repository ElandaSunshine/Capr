########################################################################################################################
function(capr_internal_load_config_file prefix config_file)
    if (NOT EXISTS ${config_file})
        message(FATAL_ERROR "Could not find configuration at ${config_file}")
    endif()

    file(READ ${config_file} config_file_output)
    string(TOLOWER "${prefix}" prefix)

    string(REPLACE ";"    "\;" lines "${config_file_output}")
    string(REPLACE "\r\n" ";"  lines "${lines}")
    string(REPLACE "\n"   ";"  lines "${lines}")

    list(LENGTH lines lines_num)
    math(EXPR lines_num "${lines_num} - 1")

    foreach(i RANGE ${lines_num})
        list(GET lines ${i} line)
        math(EXPR line_info "${i}+1")
        
        
        # ignore sequences
        if ("${line}" MATCHES "^([ \t]*);.*$" OR "${line}" MATCHES "^[ \t]*$")
            continue()
        endif()

        if("${line}" MATCHES "^([ \t]*)([^ \t]+)([ \t]*)=([ \t]*)(.*)([ \t]*)$")
            if ("${current_section}" STREQUAL "")
                message(FATAL_ERROR "Error reading Capr config at line ${line_info}: Missing section name")
            endif()

            if ("${CMAKE_MATCH_2}" STREQUAL "")
                message(FATAL_ERROR "Error reading Capr config at line ${line_info}: Missing key")
            endif()

            set(${prefix}.${current_section}.${CMAKE_MATCH_2} "${CMAKE_MATCH_5}" PARENT_SCOPE)
            list(APPEND ${prefix}.${current_section} "${prefix}.${current_section}.${CMAKE_MATCH_2}")
        elseif("${line}" MATCHES "^([ \t]*)\\[([ \t]*)([^ \t]*)([ \t]*)\\][ \t]*$")
            if ("${CMAKE_MATCH_3}" STREQUAL "")
                message(FATAL_ERROR "Error reading Capr config at line ${line_info}: Empty section name")
            endif()

            if(NOT "${prefix}.${CMAKE_MATCH_3}" IN_LIST ${prefix})
                list(APPEND ${prefix} "${prefix}.${CMAKE_MATCH_3}")
            endif()

            set(current_section "${CMAKE_MATCH_3}")
        else()
            message(FATAL_ERROR
                "Error reading Capr config at line ${line_info}: Invalid character sequence, \
                only section headings, key-value pairs, comments and empty lines are allowed: ${line}")
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

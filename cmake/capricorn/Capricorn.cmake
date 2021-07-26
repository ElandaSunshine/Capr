########################################################################################################################
include_guard()

########################################################################################################################
set(CAPR_CAPRICORN_FORMATS
    Solar)
list(GET CAPR_CAPRICORN_FORMATS  0 CAPR_CAPRICORN_DEFAULT)
list(GET CAPR_CAPRICORN_FORMATS -1 CAPR_CAPRICORN_LATEST)

########################################################################################################################
macro(capr_capricorn_include format_name)
    capr_internal_core_init_guard()
    capr_internal_capricorn_get_real_name("${format_name}" real_format_name)
    
    if (NOT real_format_name)
        message(FATAL_ERROR "There is no Capricorn format by the name of '${format_name}'")
    endif()
    
    include("${CAPR_MODULE_DIR}/capricorn/Capricorn${real_format_name}.cmake")
    unset(real_format_name)
endmacro()

macro(capr_capricorn_invoke action format_name)
    capr_internal_core_init_guard()
    cmake_parse_arguments(ARG "" "" "ARGS" ${ARGN})
    capr_internal_capricorn_get_real_name("${format_name}" real_format_name)

    if (NOT real_format_name)
        message(FATAL_ERROR "There is no Capricorn format by the name of '${format_name}'")
    endif()
    
    cmake_language(CALL "capr_repository_${action}_${real_format_name}" ${ARG_ARGS})
    unset(real_format_name)
endmacro()

########################################################################################################################
function(capr_internal_capricorn_get_real_name format_name out_real_name)
    if ("${format_name}" STREQUAL "")
        set(${out_real_name} "${CAPR_CAPRICORN_DEFAULT}" PARENT_SCOPE)
        return()
    endif()
    
    string(TOLOWER "${format_name}" format_name_lower)
    
    foreach(format IN LISTS CAPR_CAPRICORN_FORMATS)
        string(TOLOWER "${format}" format_lower)

        if ("${format_name_lower}" STREQUAL "${format_lower}")
            set(${out_real_name} "${format_name}" PARENT_SCOPE)
            return()
        endif()
    endforeach()

    set(${out_real_name} "${format_name}-NOTFOUND" PARENT_SCOPE)
endfunction()

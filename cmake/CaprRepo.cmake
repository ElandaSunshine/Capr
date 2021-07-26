########################################################################################################################
include_guard()

########################################################################################################################
include("${CAPR_MODULE_DIR}/capricorn/Capricorn.cmake")

########################################################################################################################
function(capr_repository host)
    capr_internal_core_init_guard()
    cmake_parse_arguments(ARG "INDEX;REQUIRED" "FORMAT" "" ${ARGN})
    
    
endfunction()

########################################################################################################################
function(capr_repository_print_list)
    capr_internal_core_init_guard()
    
    get_property(out_repo_len GLOBAL PROPERTY CAPR_REPOSITORY_COUNT)
    math(EXPR out_repository_last_index "${out_repo_len}-1")
    message("====================================")
    message("[CAPR] Cached repositories (${out_repo_len}) =====")
    message("====================================")
    
    foreach(index RANGE ${out_repository_last_index})
        get_property(out_host GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_HOST)
        get_property(out_name GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_NAME)
        get_property(out_desc GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_DESC)
        get_property(out_fomt GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_FOMT)
        
        message("${out_name} (${out_host})")
        message("${out_desc}")
        message("Format: Capricorn ${out_fomt}")
        
        if (${index} LESS ${out_repository_last_index})
            message("-------")
        endif()
    endforeach()
    
    message("====================================")
endfunction()

function(capr_repository_verify_host url out_succeeded)
    capr_internal_core_init_guard()
    cmake_parse_arguments(ARG "" "FORMAT" "" ${ARGN})
    capr_capricorn_invoke(verify_host "${ARG_FORMAT}"
        ARGS "${url}" ${out_succeeded})
endfunction()

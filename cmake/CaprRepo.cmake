########################################################################################################################
function(capr_repository)
    
endfunction()

########################################################################################################################
function(capr_repository_print_list)
    get_property(out_repo_len GLOBAL PROPERTY CAPR_REPOSITORY_COUNT)
    math(EXPR out_repository_last_index "${out_repo_len}-1")
    message("====================================")
    message("[CAPR] Indexed repositories ========")
    message("====================================")

    foreach(index RANGE ${out_repository_last_index})
        get_property(out_host GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_HOST)
        get_property(out_name GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_NAME)
        get_property(out_desc GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_DESC)
        get_property(out_path GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_PATH_FORMAT)
        
        message("${out_name} (${out_host})")
        message("-- ${out_desc}")
        message("-- Format: ${out_path}")
        
        if (${index} LESS ${out_repository_last_index})
            message("-------")
        endif()
    endforeach()

    message("====================================")
    message("")
endfunction()

########################################################################################################################
function(capr_internal_repository_parse_index index_file)
    if (NOT EXISTS ${index_file})
        message(FATAL_ERROR "Could not find repository index at: ${index_file}")
    endif()
    
    file(READ "${index_file}" out_index_text)
    
    string(JSON out_repository_len LENGTH "${out_index_text}")
    math(EXPR out_repository_last_index "${out_repository_len}-1")
    
    foreach(index RANGE ${out_repository_last_index})
        string(JSON out_repo GET "${out_index_text}" ${index})
        
        string(JSON out_host                           GET "${out_repo}" host)
        string(JSON out_name                           GET "${out_repo}" name)
        string(JSON out_desc ERROR_VARIABLE null_error GET "${out_repo}" description)
        string(JSON out_path ERROR_VARIABLE null_error GET "${out_path}" path_format)
        
        set_property(GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_HOST "${out_host}")
        set_property(GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_NAME "${out_name}")
        
        if (out_desc)
            set_property(GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_DESC "${out_desc}")
        endif()
        
        if (out_path)
            set_property(GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_PATH_FORMAT "${out_path}")
        else()
            set_property(GLOBAL
                PROPERTY PLUGIN_REPOSITORY_${index}_PATH_FORMAT
                "%package_path%/%id%/%version_path%/%id%-%version%.%ext%")
        endif()
    endforeach()
    
    set_property(GLOBAL PROPERTY CAPR_REPOSITORY_COUNT ${out_repository_len})
endfunction()

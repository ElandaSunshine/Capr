########################################################################################################################
function(capr_index_load index_file)
    file(READ "${index_file}" index_text)
    capr_internal_index_parse_repositories("${index_text}")
endfunction()

########################################################################################################################
function(capr_internal_index_parse_repositories json_string)
    string(JSON repositories GET "${json_string}" repositories)
    set(repo_count 0)
    
    if (repositories)
        string(JSON repositories_type TYPE "${index_text}" repositories)
        
        if (NOT "${repositories_type}" STREQUAL "ARRAY")
            message(FATAL_ERROR "[Capr] Error parsing index file: 'repositories' must be an array")
        endif()
        
        string(JSON repositories_len LENGTH "${index_text}" repositories)
        math(EXPR repositories_last_index "${repositories_len}-1")
        
        foreach(i RANGE ${repositories_last_index})
            string(JSON repository      GET  "${repositories}" ${i})
            string(JSON repository_type TYPE "${repositories}" ${i})
            
            if (NOT "${repository_type}" STREQUAL "OBJECT")
                message(FATAL_ERROR "[Capr] Error parsing index file: A repository entry must be an object")
            endif()
            
            string(JSON repository_host GET "${repository}" host)
            
            if (NOT repository_host OR "${repository_host}" STREQUAL "")
                if (NOT ${CAPR_SKIP_INVALID_REPOSITORIES})
                    message(FATAL_ERROR "[Capr] Invalid repository entry, must at least have a host")
                endif()
                
                message(WARNING "[Capr] Invalid repository entry, must at least have a host, ignoring repository...")
                continue()
            endif()
            
            string(JSON repository_host_type TYPE "${repository}" host)
            
            if (NOT "${repository_host_type}" STREQUAL "STRING")
                message(FATAL_ERROR "[Capr] Error parsing index file: Host must be a valid string containing an url \
                    to the repository's API")
            endif()

            string(JSON repository_format
                ERROR_VARIABLE error
                GET "${repository}" format)

            if (NOT error)
                string(JSON repository_format_type
                    ERROR_VARIABLE error
                    TYPE "${repository}" format)

                if (NOT error)
                    if (NOT "${repository_format_type}" STREQUAL "STRING")
                        message(FATAL_ERROR "[Capr] Error parsing index file: A repository format must be a string")
                    endif()

                    if (NOT "${repository_format}" STREQUAL "")
                        capr_internal_capricorn_get_real_name("${repository_format}" real_format_name)
                        
                        if (NOT real_format_name)
                            if (NOT ${CAPR_SKIP_INVALID_REPOSITORIES})
                                message(FATAL_ERROR "Format '${repository_format_type}' is not a valid repository format")
                            endif()

                            message(WARNING "Format '${repository_format_type}' is not a valid repository format")
                            return()
                        endif()

                        set(repository_format "${real_format_name}")
                    endif()
                endif()
            else()
                set(repository_format "${CAPR_CAPRICORN_DEFAULT}")
            endif()

            capr_capricorn_include("${repository_format}")
            
            message(VERBOSE "[Capr] Reading repository '${repository_host}' from index")
            capr_repository_verify_host(${repository_host} could_be_verified)
            
            if (NOT ${could_be_verified})
                continue()
            endif()
            
            string(JSON repository_name
                ERROR_VARIABLE error
                GET "${repository}" name)
            
            if (NOT error)
                string(JSON repository_name_type
                    ERROR_VARIABLE error
                    TYPE "${repository}" name)
                
                if (NOT error)
                    if (NOT "${repository_name_type}" STREQUAL "STRING")
                        message(FATAL_ERROR "[Capr] Error parsing index file: A repository name must be a string")
                    endif()
                    
                    set(current_repo_name "${repository_name}")
                endif()
            endif()
            
            string(JSON repository_desc
                ERROR_VARIABLE error
                GET "${repository}" description)
            
            if (NOT error)
                string(JSON repository_desc_type
                    ERROR_VARIABLE error
                    TYPE "${repository}" description)
                
                if (NOT error)
                    if (NOT "${repository_desc_type}" STREQUAL "STRING")
                        message(FATAL_ERROR "[Capr] Error parsing index file: A repository description must be a string")
                    endif()
                    
                    set(current_repo_description "${repository_desc}")
                endif()
            endif()
            
            if ("${current_repo_name}" STREQUAL "")
                set(current_repo_name "${repository_host}")
            endif()
            
            set_property(GLOBAL PROPERTY PLUGIN_REPOSITORY_${i}_HOST "${repository_host}")
            set_property(GLOBAL PROPERTY PLUGIN_REPOSITORY_${i}_NAME "${current_repo_name}")
            set_property(GLOBAL PROPERTY PLUGIN_REPOSITORY_${i}_DESC "${current_repo_description}")
            set_property(GLOBAL PROPERTY PLUGIN_REPOSITORY_${i}_FOMT "${repository_format}")
            
            math(EXPR repo_count "${repo_count}+1")
            message(VERBOSE "[Capr] Added repository '${repository_host}' to the cache")
        endforeach()
        
        if (${repo_count} EQUAL 1)
            message(VERBOSE "[Capr] Found ${repo_count} valid repository from at least ${repositories_len}")
        else()
            message(VERBOSE "[Capr] Found ${repo_count} valid repositories from at least ${repositories_len}")
        endif()
    endif()
    
    set_property(GLOBAL PROPERTY CAPR_REPOSITORY_COUNT ${repo_count})
endfunction()

########################################################################################################################
function(parse_repository_index index_file)
    file(READ ${CAPR_INDEX_FILE} index_content)
    string(JSON repository_array_len ERROR_VARIABLE json_error LENGTH ${index_content} repositories)

    if (json_error)
        message(FATAL_ERROR "Couldn't read CAPR repository index: ${json_error}")
    endif()

    foreach(i RANGE )
        string(JSON repository_array ERROR_VARIABLE json_error GET ${index_content} repositories)
    endforeach()
endfunction()

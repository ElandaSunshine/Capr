########################################################################################################################
set(CAPR_REPOSITORY_LIST        "")
set(CAPR_REPOSITORY_FORMAT_LIST "")

########################################################################################################################
function(capr_internal_parse_repository_index index_file)
    capr_internal_include_inbuilt_plugin("Cson")
    cson_set_defaults()
    set(CSON_COMMENT_KEYWORD "//")
    cson_load(index "${index_file}")

    foreach(repository IN LISTS index.repositories)
        if ("${${repository}.host}" STREQUAL "")
            message(SEND_ERROR "Found empty host for repository")
        endif()

        set(repo_host "${${repository}.host}")
        set(repo_path_format "${${repository}.format.path}")
        set(repo_compression "${${repository}.format.compression}")
        set(repo_hashes      "${${repository}.format.hash_algorithms}")

        list(APPEND CAPR_REPOSITORY_LIST "${${repository}.host}")

        list(APPEND CAPR_REPOSITORY_FORMAT_LIST "${${repository}.format}")
    endforeach()

    set(CAPR_REPOSITORY_LIST        ${CAPR_REPOSITORY_LIST}        PARENT_SCOPE)
    set(CAPR_REPOSITORY_FORMAT_LIST ${CAPR_REPOSITORY_FORMAT_LIST} PARENT_SCOPE)
endfunction()

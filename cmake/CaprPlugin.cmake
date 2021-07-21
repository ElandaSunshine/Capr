########################################################################################################################
set(CAPR_PLUGIN_STRING_PATTERN "^([a-zA-Z0-9_.]+):([a-zA-Z0-9_]+)@(([0-9].[0-9](.[0-9])?)|latest)(:(.+))?$")
set(CAPR_LOCAL_FOLDER_FORMAT   "%package_path%/%id%/%version_path%")

########################################################################################################################
function(capr_plugin target)
    cmake_parse_arguments(ARG "REQUIRED" "" "" ${ARGN})
    capr_internal_core_init_guard()

    capr_plugin_has_target(${target} has_target)

    if (${has_target})
        message(FATAL_ERROR "[Capr] Plugin target '${target}' has already been declared before")
    endif()

    if (${is_target_defined})
        message(FATAL_ERROR )
    endif()
    
    if ("${ARGV1}" MATCHES "^[a-zA-Z0-9_]+$")
        capr_internal_core_include_inbuilt_plugin("${ARGV1}" ${ARG_REQUIRED})

        string(TOLOWER ${ARGV1} plugin_name_lower)
        get_property(loaded_inbuilts GLOBAL PROPERTY CAPR_INBUILTS_LOADED)
        
        if ("${plugin_name_lower}" IN_LIST loaded_inbuilts)
            message(STATUS "[Capr] Loaded in-built plugin '${ARGV1}'")

            set_property(GLOBAL PROPERTY PLUGIN_${target}_PACKAGE      "")
            set_property(GLOBAL PROPERTY PLUGIN_${target}_ID           "${ARGV1}")
            set_property(GLOBAL PROPERTY PLUGIN_${target}_VERSION      "${CAPR_VERSION}")
            set_property(GLOBAL PROPERTY PLUGIN_${target}_VERSION_TYPE "release")

            set_property(GLOBAL PROPERTY PLUGIN_${target}_SOURCE    "${CAPR_MODULE_INBUILTS}")
            set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_SHA1 "")
            set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_MD5  "")
            set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_ZIP  "")

            set_property(GLOBAL PROPERTY PLUGIN_${target}_NO_VERIFICATION TRUE)
            set_property(GLOBAL PROPERTY PLUGIN_${target}_REQUIRED        ${ARG_REQUIRED})

            # add plugin specification to the loaded plugin list
            set_property(GLOBAL APPEND PROPERTY CAPR_DECLARED_PLUGINS ${target})
            set_property(GLOBAL APPEND PROPERTY CAPR_APPLIED_PLUGINS ${target})
        endif()
        
        return()
    endif()

    capr_plugin_declare(${target} ${ARGN})

    if (${is_target_defined})
        capr_plugin_download(${target} ${ARGN})

        if (NOT ${CAPR_DOWNLOAD_SUCCEEDED})
            capr_plugin_undeclare(${target})
            return()
        endif()
        
        get_target_property(out_no_verification GLOBAL PROPERTY PLUGIN_${target}_NO_VERIFICATION)

        if (${CAPR_VERIFY_DOWNLOADS} AND NOT ${out_no_verification})
            capr_plugin_verify(${target} out_is_valid)

            if (NOT ${out_is_valid})
                get_target_property(out_plugin_root GLOBAL PROPERTY PLUGIN_${target}_SOURCE)
                get_filename_component(out_plugin_root "${CAPR_PLUGIN_DIR}/${out_plugin_root}" DIRECTORY)

                string(TOLOWER "${CAPR_HASH_FAIL_MODE}" out_hash_fail_mode)

                if (NOT "${out_hash_fail_mode}" STREQUAL "ignore")
                    if ("${out_hash_fail_mode}" STREQUAL "delete")
                        file(REMOVE_RECURSE "${out_plugin_root}")
                        message(WARNING
                            "[Capr] Verification for plugin failed, it did not match its hash keys, removing files...")
                        capr_plugin_undeclare(${target})
                    elseif("${out_hash_fail_mode}" STREQUAL "warn")
                        message(WARNING
                            "[Capr] Verification for plugin failed, it did not match its hash keys, keeping files...")
                    endif()
                endif()
                
                if (${ARG_REQUIRED})
                    message(FATAL_ERROR "[Capr] Verification for plugin target '${target}' did not succeed")
                endif()
                
                capr_plugin_undeclare(${target})
                return()
            endif()
        endif()

        capr_plugin_apply(${target})
        set(PLUGIN_${target}_FOUND ${PLUGIN_${target}_FOUND} PARENT_SCOPE)
    else()
        capr_plugin_undeclare(${target})
    endif()
endfunction()

function(capr_plugin_declare target)
    capr_internal_core_init_guard()
    capr_plugin_has_target(${target} has_target)

    if (${has_target})
        message(FATAL_ERROR "[Capr] Plugin target '${target}' has already been declared before")
    endif()

    capr_internal_plugin_resolve_arguments("${target}" plugin ${ARGN})

    if (NOT ${plugin_PARSED})
        return()
    endif()
    
    if ("${plugin_VERSION_TYPE}" STREQUAL "release")
        message(STATUS "[Capr] Declaring plugin '${plugin_PACKAGE}.${plugin_ID} (${plugin_VERSION})'...")
    else()
        message(STATUS
            "[Capr] Declaring plugin '${plugin_PACKAGE}.${plugin_ID} (${plugin_VERSION}-${plugin_VERSION_TYPE})'...")
    endif()

    capr_plugin_is_declared("${plugin_PACKAGE}" "${plugin_ID}" is_declared)

    if (${is_declared})
        if (${CAPR_SAME_PLUGIN_TERMINATES})
            message(FATAL_ERROR "[Capr] Tried to load a plugin twice: ${plugin_PACKAGE}.${plugin_ID}")
        else()
            message(WARNING
                "[Capr] Plugin '${plugin_PACKAGE}.${plugin_ID}' has been declared before, skipping operation...")
            return()
        endif()
    endif()

    capr_plugin_convert_format_string("${CAPR_LOCAL_FOLDER_FORMAT}" plugin_path
        PACKAGE      "${plugin_PACKAGE}"
        ID           "${plugin_ID}"
        VERSION      "${plugin_VERSION}"
        VERSION_TYPE "${plugin_VERSION_TYPE}")

    cmake_parse_arguments(ARG "NO_VERIFICATION;REQUIRED" "" "PROPERTIES" ${ARGN})

    # create plugin specification
    set_property(GLOBAL PROPERTY PLUGIN_${target}_PACKAGE      "${plugin_PACKAGE}")
    set_property(GLOBAL PROPERTY PLUGIN_${target}_ID           "${plugin_ID}")
    set_property(GLOBAL PROPERTY PLUGIN_${target}_VERSION      "${plugin_VERSION}")
    set_property(GLOBAL PROPERTY PLUGIN_${target}_VERSION_TYPE "${plugin_VERSION_TYPE}")

    set_property(GLOBAL PROPERTY PLUGIN_${target}_SOURCE    "${plugin_path}/data")
    set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_SHA1 "${plugin_path}/${plugin_ID}-${plugin_VERSION}.sha1")
    set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_MD5  "${plugin_path}/${plugin_ID}-${plugin_VERSION}.md5")
    set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_ZIP  "${plugin_path}/${plugin_ID}-${plugin_VERSION}.zip")

    set_property(GLOBAL PROPERTY PLUGIN_${target}_NO_VERIFICATION ${ARG_NO_VERIFICATION})
    set_property(GLOBAL PROPERTY PLUGIN_${target}_REQUIRED        ${ARG_REQUIRED})

    # add plugin specification to the loaded plugin list
    set_property(GLOBAL APPEND PROPERTY CAPR_DECLARED_PLUGINS ${target})

    # add property overrides
    if (NOT "${ARG_PROPERTIES}" STREQUAL "")
        foreach(property IN LISTS ARG_PROPERTIES)
            if (NOT "${property}" MATCHES "^[^=]+=.*$")
                message(FATAL_ERROR "[Capr] Invalid property syntax '${property}' for plugin target ${target}")
            endif()
        endforeach()

        set_property(GLOBAL PROPERTY PLUGIN_${target}_PROPERTIES ${ARG_PROPERTIES})
    endif()
endfunction()

function(capr_plugin_download target)
    capr_internal_core_init_guard()
    capr_plugin_has_target(${target} has_target)
    
    if (NOT ${has_target})
        message(FATAL_ERROR "[Capr] No plugin target '${target}' found")
    endif()

    cmake_parse_arguments(ARG "" "" "REPOSITORIES" ${ARGN})

    get_property(plugin_package      GLOBAL PROPERTY PLUGIN_${target}_PACKAGE)
    get_property(plugin_id           GLOBAL PROPERTY PLUGIN_${target}_ID)
    get_property(plugin_version      GLOBAL PROPERTY PLUGIN_${target}_VERSION)
    get_property(plugin_version_type GLOBAL PROPERTY PLUGIN_${target}_VERSION_TYPE)

    message(STATUS "[Capr] Starting download for plugin declaration '${plugin_package}.${plugin_id}'...")

    get_property(file_zip  GLOBAL PROPERTY PLUGIN_${target}_ZIP)
    get_property(file_sha1 GLOBAL PROPERTY PLUGIN_${target}_SHA1)
    get_property(file_md5  GLOBAL PROPERTY PLUGIN_${target}_MD5)

    get_property(dont_verify GLOBAL PROPERTY PLUGIN_${target}_NO_VERIFICATION)

    if (${CAPR_VERIFY_DOWNLOADS} AND NOT ${dont_verify})
        set(needs_verification TRUE)
    endif()
    
    if (NOT EXISTS "${CAPR_PLUGIN_DIR}/${file_zip}" OR ${CAPR_FORCE_DOWNLOAD})
        get_filename_component(plugin_root "${CAPR_PLUGIN_DIR}/${file_zip}" DIRECTORY)
        get_filename_component(plugin_root "${plugin_root}"                 DIRECTORY)

        file(REMOVE_RECURSE "${plugin_root}")
        file(MAKE_DIRECTORY "${plugin_root}")
        
        get_property(repository_list_len GLOBAL PROPERTY CAPR_REPOSITORY_COUNT)
        list(LENGTH ARG_REPOSITORIES list_len)
        
        math(EXPR repository_list_last_index "${repository_list_len}+${list_len}-1")
        
        foreach(index RANGE ${repository_list_last_index})
            if (${index} LESS ${repository_list_len})
                get_property(repository_host GLOBAL PROPERTY PLUGIN_REPOSITORY_${index}_HOST)
            else()
                math(EXPR repo_index "${index}-${repository_list_len}")
                list(GET ARG_REPOSITORIES ${repo_index} repository_host)
            endif()
            
            message(VERBOSE "[Capr] Searching for plugin '${plugin_package}.${plugin_id} \
                (${plugin_version}-${plugin_version_type})' at '${repository_host}'...")

            if (needs_verification)
                message(VERBOSE "[Capr] Verification is enabled, trying to fetch checksum files...")
            endif()

            message(VERBOSE "[Capr] Looking for SHA1 key...")
            file(DOWNLOAD "${repository_host}/${file_sha1}" "${CAPR_PLUGIN_DIR}/${file_sha1}" STATUS op_status)
            list(GET op_status 0 op_status_code)

            if (${needs_verification} AND NOT ${op_status_code} EQUAL 0)
                if ("${CMAKE_MESSAGE_LOG_LEVEL}" STREQUAL "VERBOSE")
                    list(GET op_status 1 op_status_message)
                    message(STATUS "[Capr] Could not fetch SHA1 key from repository: ${op_status_message}")
                    message(STATUS "[Capr] Skipping to next repository...")
                endif()

                continue()
            endif()

            message(VERBOSE "[Capr] Looking for MD5 key...")
            file(DOWNLOAD "${repository_host}/${file_md5}" "${CAPR_PLUGIN_DIR}/${file_md5}" STATUS op_status)
            list(GET op_status 0 op_status_code)

            if (${needs_verification} AND NOT ${op_status_code} EQUAL 0)
                if ("${CMAKE_MESSAGE_LOG_LEVEL}" STREQUAL "VERBOSE")
                    list(GET op_status 1 op_status_message)
                    message(STATUS "[Capr] Could not fetch MD5 key from repository: ${op_status_message}")
                    message(STATUS "[Capr] Skipping to next repository...")
                endif()

                continue()
            endif()

            message(VERBOSE "[Capr] Verifying archive download is available...")
            file(DOWNLOAD "${repository_host}/${file_zip}" STATUS op_status)
            list(GET op_status 0 op_status_code)

            if (NOT ${op_status_code} EQUAL 0)
                if ("${CMAKE_MESSAGE_LOG_LEVEL}" STREQUAL "VERBOSE")
                    list(GET op_status 1 op_status_message)
                    message(STATUS "[Capr] Could not download archive file from repository: ${op_status_message}")
                    message(STATUS "[Capr] Skipping to next repository...")
                endif()

                continue()
            endif()

            message(VERBOSE "[Capr] Found plugin in current repository, fetching archive...")

            if ("${CMAKE_MESSAGE_LOG_LEVEL}" STREQUAL "VERBOSE")
                file(DOWNLOAD "${repository_host}/${file_zip}" "${CAPR_PLUGIN_DIR}/${file_zip}" SHOW_PROGRESS)
            else()
                file(DOWNLOAD "${repository_host}/${file_zip}" "${CAPR_PLUGIN_DIR}/${file_zip}")
            endif()

            message(STATUS "[Capr] Successfully fetched plugin '${plugin_package}.${plugin_id}'")
        endforeach()
        
        if (NOT EXISTS "${CAPR_PLUGIN_DIR}/${file_zip}")
            file(REMOVE_RECURSE "${plugin_root}")

            get_property(plugin_required GLOBAL PROPERTY PLUGIN_${target}_REQUIRED)

            if (${plugin_required})
                message(FATAL_ERROR "[Capr] \
                     Could not download plugin because either it wasn't found or all found ones were invalid. One \
                     reason might be that the repository doesn't supply verification files, to disable verification \
                     for a plugin, append the NO_VERIFICATION flag to the plugin call or disable it globally")
            else()
                set(CAPR_DOWNLOAD_SUCCEEDED FALSE PARENT_SCOPE)
                return()
            endif()
        endif()

        set(CAPR_DOWNLOAD_SUCCEEDED TRUE PARENT_SCOPE)
    endif()
endfunction()

function(capr_plugin_verify target out_valid)
    capr_internal_core_init_guard()
    capr_plugin_has_target(${target} has_target)

    if (NOT ${has_target})
        message(FATAL_ERROR "[Capr] No plugin target '${target}' found")
    endif()

    get_property(plugin_package GLOBAL PROPERTY PLUGIN_${target}_PACKAGE)
    get_property(plugin_id      GLOBAL PROPERTY PLUGIN_${target}_ID)
    
    message(STATUS "[Capr] Starting verification for plugin declaration '${plugin_package}.${plugin_id}'...")

    get_property(file_zip  GLOBAL PROPERTY PLUGIN_${target}_ZIP)
    get_property(file_sha1 GLOBAL PROPERTY PLUGIN_${target}_SHA1)
    get_property(file_md5  GLOBAL PROPERTY PLUGIN_${target}_MD5)

    message(VERBOSE "[Capr] Starting plugin test...")
    set(${out_valid} FALSE PARENT_SCOPE)

    if (NOT EXISTS "${CAPR_PLUGIN_DIR}/${file_sha1}" OR NOT EXISTS "${CAPR_PLUGIN_DIR}/${file_md5}")
        message(VERBOSE "[Capr] Could not verify, either SHA1 or MD5 is missing")
    else()
        message(VERBOSE "[Capr] Checking against SHA1 checksum...")

        file(READ "${CAPR_PLUGIN_DIR}/${file_sha1}" read_hash)
        file(SHA1 "${CAPR_PLUGIN_DIR}/${file_zip}"  read_archive_hash)

        if (NOT "${read_archive_hash}" STREQUAL "${read_hash}")
            message(VERBOSE "[Capr] SHA1 checksum did not match the archive")
            return()
        endif()

        message(VERBOSE "[Capr] Checking against MD5 checksum...")

        file(READ "${CAPR_PLUGIN_DIR}/${file_md5}" read_hash)
        file(MD5  "${CAPR_PLUGIN_DIR}/${file_zip}" read_archive_hash)

        if (NOT "${read_archive_hash}" STREQUAL "${read_hash}")
            message(VERBOSE "[Capr] MD5 checksum did not match the archive")
            return()
        endif()

        set(${out_valid} TRUE PARENT_SCOPE)
    endif()
endfunction()

function(capr_plugin_apply target)
    capr_internal_core_init_guard()
    capr_plugin_is_applied(${target} is_applied)
    
    if (${is_applied})
        message(WARNING "[Capr] Plugin has already been applied previously")
        return()
    endif()

    capr_plugin_has_target(${target} has_target)

    if (NOT ${has_target})
        message(FATAL_ERROR "[Capr] No plugin target '${target}' found")
        return()
    endif()

    message(STATUS "[Capr] Applying plugin ${target} to project...")
    
    get_property(file_zip    GLOBAL PROPERTY PLUGIN_${target}_ZIP)
    get_property(is_required GLOBAL PROPERTY PLUGIN_${target}_REQUIRED)
    
    get_filename_component(plugin_root "${CAPR_PLUGIN_DIR}/${file_zip}" DIRECTORY)

    if (NOT EXISTS "${plugin_root}/data/plugin.json")
        message(VERBOSE "[Capr] Config file missing for '${target}, trying to extract the plugin...'")

        file(REMOVE_RECURSE "${plugin_root}/data")
        file(MAKE_DIRECTORY "${plugin_root}/data")

        if (NOT EXISTS "${CAPR_PLUGIN_DIR}/${file_zip}")
            if (${is_required})
                message(FATAL_ERROR "[Capr] Plugin archive was not found, could not extract plugin")
            endif()
            
            message(WARNING "[Capr] Plugin archive was not found, could not extract plugin")
            return()
        endif()

        file(ARCHIVE_EXTRACT
            INPUT       "${CAPR_PLUGIN_DIR}/${file_zip}"
            DESTINATION "${plugin_root}/data")

        if (NOT EXISTS "${plugin_root}/data/plugin.json")
            if (${is_required})
                message(FATAL_ERROR "[Capr] Plugin archive was corrupt or did not represent a valid plugin")
            endif()

            message(WARNING "[Capr] Plugin archive was corrupt or did not represent a valid plugin")
            return()
        endif()
    endif()

    if (NOT EXISTS "${plugin_root}/data/Plugin.cmake")
        if (${is_required})
            message(FATAL_ERROR "[Capr] Plugin archive was corrupt or did not represent a valid plugin")
        endif()

        message(WARNING "[Capr] Plugin archive was corrupt or did not represent a valid plugin")
        return()
    endif()
    
    capr_internal_plugin_load_config("${plugin_root}/data/plugin.json" ${is_required} config_parsing_failed)
    
    if (${config_parsing_failed})
        return()
    endif()
    
    include("${capr_plugin_folder}/data/cmake/Plugin.cmake")
    cmake_language(CALL "plugin_init_${package}_${id}" ${target} LOCAL_PROPERTIES_${target})
    set_property(GLOBAL APPEND PROPERTY CAPR_APPLIED_PLUGINS ${target})
endfunction()

function(capr_plugin_undeclare target)
    capr_plugin_has_target(${target} out_has_target)

    if (NOT ${out_has_target})
        if (NOT "QUIET" IN_LIST ${ARGN})
            message(FATAL_ERROR "[Capr] No plugin target '${target}' found")
        endif()
        
        return()
    endif()

    set_property(GLOBAL PROPERTY PLUGIN_${target}_PACKAGE)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_ID)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_VERSION)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_VERSION_TYPE)

    set_property(GLOBAL PROPERTY PLUGIN_${target}_SOURCE)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_SHA1)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_MD5)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_FILE_ZIP)

    set_property(GLOBAL PROPERTY PLUGIN_${target}_NO_VERIFICATION)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_IMPLICIT)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_DEPENDS_ON)
    set_property(GLOBAL PROPERTY PLUGIN_${target}_REQUIRED)

    set_property(GLOBAL PROPERTY PLUGIN_${target}_PROPERTIES)
    
    get_property(out_declared_plugins GLOBAL PROPERTY CAPR_DECLARED_PLUGINS)
    list(REMOVE_ITEM out_declared_plugins "${target}")
    set_property(GLOBAL APPEND PROPERTY CAPR_DECLARED_PLUGINS ${out_declared_plugins})
endfunction()

########################################################################################################################
function(capr_plugin_get_target package id out_target)
    capr_internal_core_init_guard()

    string(TOLOWER "${package}" package)
    string(TOLOWER "${id}"      id)

    get_property(property_targets GLOBAL PROPERTY CAPR_DECLARED_PLUGINS)

    foreach(target_name IN LISTS property_targets)
        get_property(target_package GLOBAL PROPERTY PLUGIN_${target_name}_PACKAGE)
        get_property(target_id      GLOBAL PROPERTY PLUGIN_${target_name}_ID)

        string(TOLOWER "${target_package}" target_package)
        string(TOLOWER "${target_id}"      target_id)

        if ("${package}" STREQUAL "${target_package}" AND "${id}" STREQUAL "${target_id}")
            set(${out_target} ${target_name} PARENT_SCOPE)
            return()
        endif()
    endforeach()
    
    set(${out_target} NOTFOUND PARENT_SCOPE)
endfunction()

function(capr_plugin_is_declared package id out_var)
    capr_internal_core_init_guard()
    capr_plugin_get_target("${package}" "${id}" out_target)
    
    if (out_target)
        set(${out_var} TRUE PARENT_SCOPE)
    else()
        set(${out_var} FALSE PARENT_SCOPE)
    endif()
endfunction()

function(capr_plugin_has_target target out_var)
    capr_internal_core_init_guard()

    get_property(property_targets GLOBAL PROPERTY CAPR_DECLARED_PLUGINS)

    if ("${target}" IN_LIST property_targets)
        set(${out_var} TRUE PARENT_SCOPE)
        return()
    endif()

    set(${out_var} FALSE PARENT_SCOPE)
endfunction()

function(capr_plugin_is_applied out_applied)
    cmake_parse_arguments(ARG "" "TARGET;PACKAGE;ID" "" ${ARGN})
    set(${out_applied} FALSE PARENT_SCOPE)

    if (NOT "${ARG_TARGET}" STREQUAL "")
        if (NOT "${ARG_PACKAGE}" STREQUAL "" OR NOT "${ARG_PACKAGE}" STREQUAL "")
            message(WARNING "[Capr] TARGET and one of PACKAGE or ID are set together, \
                TARGET has priority and will displace the PACKAGE/ID call")
        endif()
        
        get_property(applied_plugins GLOBAL PROPERTY CAPR_APPLIED_PLUGINS)
        
        if ("${ARG_TARGET}" IN_LIST applied_plugins)
            set(${out_applied} TRUE PARENT_SCOPE)
        endif()
        
        return()
    endif()
    
    if ("${ARG_ID}" STREQUAL "")
        message(FATAL_ERROR "[Capr] ID has not been set, this is a mandatory argument, \
            PACKAGE only for non-inbuilt plugins")
    endif()
    
    capr_plugin_get_target("${ARG_PACKAGE}" "${ARG_ID}" found_target)
    
    if (found_target)
        capr_plugin_is_applied(was_applied TARGET ${found_target})
        set(${out_applied} ${was_applied} PARENT_SCOPE)
        return()
    endif()
endfunction()

function(capr_plugin_convert_format_string format_string out_string)
    capr_internal_core_init_guard()
    cmake_parse_arguments(ARG "" "EXTENSION;PACKAGE;ID;VERSION;VERSION_TYPE" "" ${ARGN})

    string(REPLACE "." "/" package_parts "${ARG_PACKAGE}")
    string(REPLACE "." ";" version_parts "${ARG_VERSION}")

    list(GET    version_parts 0 plugin_version_major)
    list(GET    version_parts 1 plugin_version_minor)
    list(LENGTH version_parts   plugin_version_len)

    if (${plugin_version_len} EQUAL 3)
        list(GET version_parts 2 plugin_version_revision)
    else()
        set(plugin_version_revision 0)
    endif()
    
    if (NOT "${ARG_VERSION_TYPE}" STREQUAL "release" AND NOT "${ARG_VERSION_TYPE}" STREQUAL "")
        set(version_type_path "-${ARG_VERSION_TYPE}")
    endif()
    
    capr_internal_plugin_get_placeholder("package"      "${ARG_PACKAGE}"             format_string)
    capr_internal_plugin_get_placeholder("id"           "${ARG_ID}"                  format_string)
    capr_internal_plugin_get_placeholder("version"      "${ARG_VERSION}"             format_string)
    capr_internal_plugin_get_placeholder("version_type" "${ARG_VERSION_TYPE}"        format_string)
    
    capr_internal_plugin_get_placeholder("ext"          "${ARG_EXTENSION}"           format_string)
    capr_internal_plugin_get_placeholder("package_path" "${package_parts}"           format_string)
    capr_internal_plugin_get_placeholder("major"        "${plugin_version_major}"    format_string)
    capr_internal_plugin_get_placeholder("minor"        "${plugin_version_minor}"    format_string)
    capr_internal_plugin_get_placeholder("revision"     "${plugin_version_revision}" format_string)

    capr_internal_plugin_get_placeholder("version_path" "${ARG_VERSION}${version_type_path}"  format_string)
    capr_internal_plugin_get_placeholder("version_full" "${ARG_VERSION}-${ARG_VERSION_TYPE}" format_string)
    
    set(${out_string} "${format_string}" PARENT_SCOPE)
endfunction()

function(capr_plugin_get_specs_from_string plugin_string out_prefix)
    capr_internal_core_init_guard()
    cmake_parse_arguments(ARG "ERROR_OUT" "" "" ${ARGN})

    if ("${plugin_string}" MATCHES ${CAPR_PLUGIN_STRING_PATTERN})
        set(${out_prefix}_PACKAGE      "${CMAKE_MATCH_1}" PARENT_SCOPE)
        set(${out_prefix}_ID           "${CMAKE_MATCH_2}" PARENT_SCOPE)
        set(${out_prefix}_VERSION      "${CMAKE_MATCH_3}" PARENT_SCOPE)
        set(${out_prefix}_VERSION_TYPE "${CMAKE_MATCH_7}" PARENT_SCOPE)

        string(TOLOWER "${CMAKE_MATCH_7}" lower_version_type)

        if ("${lower_version_type}" STREQUAL "")
            set(${out_prefix}_VERSION_TYPE "release" PARENT_SCOPE)
        else()
            set(${out_prefix}_VERSION_TYPE "${lower_version_type}" PARENT_SCOPE)
        endif()

        set(${out_prefix}_IS_VALID TRUE PARENT_SCOPE)
        return()
    else()
        set(error_message "[Capr] \
            Plugin string '${plugin_string}' was invalid, must follow the format: package:id@version[:version_type]")
        
        if ("${ARG_ERROR_OUT}" STREQUAL "")
            message(FATAL_ERROR "${error_message}")
        else()
            set(${ARG_ERROR_OUT} "${error_message}" PARENT_SCOPE)
        endif()
    endif()

    set(${out_prefix}_IS_VALID FALSE PARENT_SCOPE)
endfunction()

function(capr_plugin_get_property out_value)
    cmake_parse_arguments(ARG "LOCAL;GLOBAL" "TARGET;PROPERTY" "" ${ARGN})

    if ("${ARG_TARGET}" STREQUAL "")
        message(FATAL_ERROR "[Capr] TARGET must be specified with a valid target")
    endif()
    
    if ("${ARG_PROPERTY}" STREQUAL "")
        message(FATAL_ERROR "[Capr] PROPERTY must be specified with a valid name")
    endif()
    
    if (${ARG_LOCAL})
        capr_internal_plugin_get_property(LOCAL_PROPERTIES_${ARG_TARGET} ${ARG_PROPERTY} map_value)
        
        if (map_value)
            set(${out_value} "${map_value}" PARENT_SCOPE)
            return()
        endif()
    endif()
    
    if (${ARG_GLOBAL})
        get_property(target_map GLOBAL PROPERTY PLUGIN_${ARG_TARGET}_PROPERTIES)
        capr_internal_plugin_get_property(target_map ${ARG_PROPERTY} map_value)

        if (map_value)
            set(${out_value} "${map_value}" PARENT_SCOPE)
            return()
        endif()
    endif()

    set(${out_value} ${ARG_PROPERTY}-NOTFOUND PARENT_SCOPE)
endfunction()

########################################################################################################################
function(capr_internal_plugin_get_property map name out_value)
    string(TOLOWER "${name}" name)
    
    foreach(property IN LISTS ${map})
        if ("${property}" MATCHES [[^([^=]+)=(.*)$]])
            string(TOLOWER "${CMAKE_MATCH_1}" key_lower)
            
            if ("${key_lower}" STREQUAL ${name})
                set(${out_value} "${CMAKE_MATCH_1}" PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()
    
    set(${out_value} ${name}-NOTFOUND PARENT_SCOPE)
endfunction()

function(capr_internal_plugin_set_property map name new_value out_map)
    string(TOLOWER "${name}" name)
    list(LENGTH ${map} out_length)
    
    math(EXPR out_length "${out_length}-1")
    
    foreach(index RANGE ${out_length})
        list(GET ${map} ${index} property)
        
        if ("${property}" MATCHES [[^([^= \t]+)=(.*)$]])
            string(TOLOWER "${CMAKE_MATCH_1}" key_lower)

            if ("${key_lower}" STREQUAL ${name})
                list(REMOVE_AT ${map} ${index})
                list(INSERT    ${map} ${index} "${CMAKE_MATCH_1}=${new_value}")
                set(${out_map} ${map} PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()
    
    list(APPEND ${map} "${name}=${new_value}")
    set(${out_map} ${map} PARENT_SCOPE)
endfunction()

macro(capr_internal_plugin_json_call out_object op json member)
    string(JSON ${out_object} ERROR_VARIABLE parse_error ${op} "${json}" ${member})

    cmake_parse_arguments(MARG "REQUIRED" "" "EXPECT;REPLACE" ${ARGN})
    
    if (${MARG_REQUIRED} AND "${out_object}" MATCHES "(-NOTFOUND)?$")
        capr_internal_optional_error("Problem loading plugin.json for '${target}': Required option 'member' was not \
            specified." ${is_required})
    endif()
    
    if (${parse_error} AND NOT "${out_object}" MATCHES "-NOTFOUND$")
        capr_internal_optional_error("Problem loading plugin.json for '${target}': ${parse_error}" ${is_required})
    endif()
    
    if (NOT "${MARG_EXPECT}" STREQUAL "")
        string(JSON out_type TYPE "${json}" ${member})
        
        if (NOT ${out_type} IN_LIST MARG_EXPECT)
            list(JOIN MARG_EXPECT ", " out_expect_list)
            
            capr_internal_optional_error("Problem loading plugin.json for '${target}': Invalid type,
                expected one of '${out_expect_list}' but found '${out_type}'" ${is_required})
            return()
        endif()
    endif()
    
    if (NOT "${MARG_REPLACE}" STREQUAL "")
        capr_internal_plugin_substitute_property("${out_object}" out_object ${MARG_REPLACE})
    endif()
endmacro()

function(capr_internal_plugin_substitute_property in_string out_string)
    set(temp_map ${ARGN})
    
    while("${in_string}" MATCHES [[%([^ \t%]+)%]])
        capr_internal_plugin_get_property(temp_map "${CMAKE_MATCH_1}" out_match)
        
        if (${out_match})
            string(REPLACE "${CMAKE_MATCH_0}" "${out_match}" in_string "${in_string}")
        else()
            string(REPLACE "${CMAKE_MATCH_0}" "" in_string "${in_string}")
        endif()
    endwhile()
    
    set(${out_string} "${in_string}" PARENT_SCOPE)
endfunction()

macro(capr_internal_optional_error message is_required)
    if (NOT "${message}" STREQUAL "")
        if (${is_required})
            message(FATAL_ERROR "[Capr] ${message}")
        endif()
        
        message(WARNING "[Capr] ${message}")
        return()
    endif()
endmacro()

function(capr_internal_plugin_config_parse_properties target config_json is_required out_got_error)
    capr_internal_plugin_json_call(properties GET "${config_text}" properties EXPECT "ARRAY")
    
    set(${out_got_error} TRUE PARENT_SCOPE)
    
    if (properties)
        capr_internal_plugin_json_call(config_properties_len LENGTH "${config_text}" properties)
        math(EXPR config_properties_last_index "${config_properties_len}-1")

        foreach(prop_index RANGE ${config_properties_last_index})
            capr_internal_plugin_json_call(property_name MEMBER "${properties}" ${prop_index}
                EXPECT "OBJECT" "STRING" "BOOLEAN" "NULL" "NUMBER")
            capr_internal_plugin_json_call(property_value GET "${properties}" ${prop_index}
                EXPECT "OBJECT")
            capr_internal_plugin_json_call(property_type TYPE "${properties}" ${prop_index})

            if ("${property_type}" STREQUAL "OBJECT")
                get_property(inherited_properties GLOBAL PROPERTY PLUGIN_${target}_PROPERTIES)

                capr_internal_plugin_json_call(property_advanced_value GET "${property_value}" value REQUIRED
                    EXPECT "STRING" "BOOLEAN" "NULL" "NUMBER")
                capr_internal_plugin_json_call(property_advanced_inherit GET "${property_value}" inherit
                    EXPECT "BOOLEAN")
                capr_internal_plugin_json_call(property_advanced_scope GET "${property_value}" scope EXPECT "STRING")

                if (property_advanced_inherit)
                    capr_internal_plugin_get_property(inherited_properties "${property_name}" inherited_value)

                    if (inherited_value)
                        set(property_advanced_value "${inherited_value}")
                    endif()
                endif()

                if (property_advanced_scope)
                    string(TOLOWER "${property_advanced_scope}" property_advanced_scope)

                    if ("${property_advanced_scope}" STREQUAL "global")
                        get_property(temp_property_map GLOBAL PROPERTY PLUGIN_${target}_PROPERTIES)
                        capr_internal_plugin_set_property(temp_property_map "${property_name}"
                            "${property_advanced_value}" new_property_map)
                        set_property(GLOBAL PROPERTY PLUGIN_${target}_PROPERTIES ${new_property_map})
                    elseif("${property_advanced_scope}" STREQUAL "plugin")
                        capr_internal_plugin_set_property(LOCAL_PROPERTIES_${target} "${property_name}"
                            "${property_advanced_value}" LOCAL_PROPERTIES_${target})
                    elseif("${property_advanced_scope}" STREQUAL "config")
                        capr_internal_plugin_set_property(CONFIG_PROPERTIES_${target} "${property_name}"
                            "${property_advanced_value}" CONFIG_PROPERTIES_${target})
                    else()
                        capr_internal_optional_error(
                            "Problem loading plugin.json for '${target}': Unknown property scope \
                            '${property_advanced_scope}' for property '${property_name}'." ${is_required})
                    endif()
                else()
                    capr_internal_plugin_set_property(LOCAL_PROPERTIES_${target} "${property_name}"
                        "${property_advanced_value}" LOCAL_PROPERTIES_${target})
                endif()
            else()
                if ("${property_name}" STREQUAL "")
                    capr_internal_optional_error(
                        "Problem loading plugin.json for '${target}': Property names can't be empty" ${is_required})
                endif()

                capr_internal_plugin_set_property(LOCAL_PROPERTIES_${target} "${property_name}"
                    "${property_value}" LOCAL_PROPERTIES_${target})
            endif()
        endforeach()
    endif()
    
    set(CONFIG_PROPERTIES_${target} ${CONFIG_PROPERTIES_${target}} PARENT_SCOPE)
    set(LOCAL_PROPERTIES_${target}  ${LOCAL_PROPERTIES_${target}}  PARENT_SCOPE)
    set(${out_got_error} FALSE PARENT_SCOPE)
endfunction()

function(capr_internal_plugin_config_test_requirements target config_json is_required out_passed)
    get_property(plugin_property_map GLOBAL PROPERTY PLUGIN_${target}_PROPERTIES)
    capr_internal_plugin_json_call(requirements GET "${config_json}" requirements EXPECT "OBJECT")

    set(${out_passed} FALSE PARENT_SCOPE)

    if (requirements)
        # Test capr requirements
        capr_internal_plugin_json_call(requirement_capr_min GET "${requirements}" capr_min
            REPLACE CONFIG_PROPERTIES_${target} LOCAL_PROPERTIES_${target} plugin_property_map
            EXPECT "STRING")

        if (requirement_capr_min)
            if (NOT "${requirement_capr_min}" MATCHES "([0-9]+.[0-9]+(.[0-9]+)?)?")
                capr_internal_optional_error(
                    "Problem loading plugin.json for '${target}': Requirement 'capr_min' is not a valid version string"
                    ${is_required})
            endif()

            if (${requirement_capr_min} VERSION_GREATER ${CAPR_VERSION})
                capr_internal_optional_error(
                    "Could not apply plugin '${target}', Capr version requirement is outdated. \n \
                    Capr: ${CAPR_VERSION} \n \
                    Min. required: ${requirement_capr_min}" ${is_required})
            endif()
        endif()
        
        # Test cmake requirements
        capr_internal_plugin_json_call(requirement_cmake_min GET "${requirements}" cmake_min REPLACE EXPECT "STRING")

        if (${requirement_cmake_min})
            if (NOT "${requirement_cmake_min}" MATCHES "([0-9]+.[0-9]+(.[0-9]+)?)?")
                capr_internal_optional_error(
                    "Problem loading plugin.json for '${target}': Requirement 'cmake_min' is not a \
                    valid version string" ${is_required})
            endif()

            if (${requirement_cmake_min} VERSION_GREATER CMAKE_VERSION)
                capr_internal_optional_error(
                    "Could not apply plugin '${target}', CMake version requirement is outdated. \n \
                    CMake: ${CMAKE_VERSION} \n \
                    Min. required: ${requirement_cmake_min}" ${is_required})
            endif()
        endif()
    endif()
    
    set(${out_passed} TRUE PARENT_SCOPE)
endfunction()

function(capr_internal_plugin_config_parse_dependencies target config_json is_required out_got_error)
    get_property(plugin_property_map GLOBAL PROPERTY PLUGIN_${target}_PROPERTIES)
    capr_internal_plugin_json_call(dependencies GET "${config_json}" dependencies EXPECT "ARRAY")

    set(${out_got_error} TRUE PARENT_SCOPE)

    if (dependencies)
        capr_internal_plugin_json_call(dependencies_len LENGTH "${config_json}" dependencies)

        if (${dependencies_len} GREATER 0)
            math(EXPR dependencies_last_index "${dependencies_len}-1")

            foreach(i RANGE ${dependencies_last_index})
                capr_internal_plugin_json_call(dependency GET "${dependencies}" ${i} EXPECT "OBJECT")
                
                capr_internal_plugin_json_call(dependency_id GET "${dependency}" id REQUIRED
                    REPLACE CONFIG_PROPERTIES_${target} LOCAL_PROPERTIES_${target} plugin_property_map
                    EXPECT "STRING")
                capr_internal_plugin_json_call(dependency_required GET "${dependency}" required EXPECT "BOOLEAN")

                if ("${dependency_id}" MATCHES "^[a-zA-Z0-9_]+$")
                    if (dependency_required AND ${dependency_required})
                        set(builtin_required TRUE)
                    else()
                        set(builtin_required FALSE)
                    endif()

                    capr_internal_core_include_inbuilt_plugin("${dependency_id}" ${builtin_required})
                else()
                    capr_internal_plugin_json_call(dependency_package GET "${dependency}" package REQUIRED
                        EXPECT "STRING"
                        REPLACE CONFIG_PROPERTIES_${target} LOCAL_PROPERTIES_${target} plugin_property_map)
                    capr_internal_plugin_json_call(dependency_version GET "${dependency}" version REQUIRED
                        EXPECT "STRING"
                        REPLACE CONFIG_PROPERTIES_${target} LOCAL_PROPERTIES_${target} plugin_property_map)
                    capr_internal_plugin_json_call(dependency_version_type GET "${dependency}" version_type
                        EXPECT "STRING"
                        REPLACE CONFIG_PROPERTIES_${target} LOCAL_PROPERTIES_${target} plugin_property_map)

                    if (dependency_version_type)
                        string(TOLOWER "${dependency_version_type}" dependency_version_type)

                        if (    NOT "${dependency_version_type}" STREQUAL "release"
                            AND NOT "${dependency_version_type}" STREQUAL "preview"
                            AND NOT "${dependency_version_type}" STREQUAL "beta")
                            capr_internal_optional_error(
                                "Problem loading plugin.json for '${target}': version_type has invalid value \
                             '${dependency_version_type}', valid are 'release', 'preview' and 'beta'" ${is_required})
                        endif()
                    else()
                        set(dependency_version_type "release")
                    endif()

                    capr_plugin_get_target("${dependency_package}" "${dependency_id}" found_target)
                    set(used_target ${target}_DEPENDENCY_${dep_index})

                    if (${found_target})
                        capr_plugin_is_applied(is_applied
                            PACKAGE "${dependency_package}"
                            ID      "${dependency_id}")
                        
                        if (${is_applied})
                            get_property(found_version GLOBAL PROPERTY PLUGIN_${found_target}_VERSION)

                            if (${found_version} VERSION_LESS ${dependency_version})
                                capr_internal_optional_error("Version of already declared dependency \
                                    (${found_version}) is less than the dependency's required version \
                                    (${dependency_version})" ${is_required})
                            else()
                                get_property(found_version_type GLOBAL PROPERTY PLUGIN_${found_target}_VERSION_TYPE)

                                if ("${dependency_version_type}" STREQUAL "release")
                                    if (NOT "${found_version_type}" STREQUAL "release")
                                        capr_internal_optional_error("Version type of dependency is release, \
                                            whereas of the previously declared plugin is just '${found_version_type}'"
                                            ${is_required})
                                    endif()
                                elseif("${dependency_version_type}" STREQUAL "preview")
                                    if ("${found_version_type}" STREQUAL "beta")
                                        capr_internal_optional_error("Version type of dependency is preview, \
                                            whereas of the previously declared plugin is just 'beta', \
                                            you need at least preview or release" ${is_required})
                                    endif()
                                endif()
                            endif()

                            message(STATUS "[Capr] Found a plugin that was already applied previously which meets the \ 
                            requirements for this dependency")

                            set(used_target "")
                        else()
                            message(STATUS
                                "[Capr] Found existing but not yet applied target (${found_target}) for dependency \
                                '${out_dep_package}.${out_dep_id}', undeclaring previous declaration...")
                            capr_plugin_undeclare(${found_target})

                            set(used_target ${found_target})
                        endif()
                    endif()

                    if (NOT "${used_target}" STREQUAL "")
                        get_property(target_no_verification GLOBAL PROPERTY PLUGIN_${target}_NO_VERIFICATION)

                        if (${target_no_verification})
                            list(APPEND opt_args NO_VERIFICATION)
                        endif()

                        if (${dependency_required})
                            list(APPEND opt_args REQUIRED)
                        endif()

                        capr_internal_plugin_json_call(dependency_repositories GET "${dependency}" repositories
                            EXPECT "ARRAY")

                        if (dependency_repositories)
                            capr_internal_plugin_json_call(dependency_repositories_len
                                LENGTH "${dependency}" repositories)
                            math(EXPR dependency_repositories_last_index "${dependency_repositories_len}-1")
                            
                            foreach(j RANGE ${dependency_repositories_last_index})
                                capr_internal_plugin_json_call(dependency_repository
                                    GET "${dependency_repositories}" ${j}
                                    EXPECT "STRING"
                                    REPLACE CONFIG_PROPERTIES_${target} LOCAL_PROPERTIES_${target} plugin_property_map)
                                list(APPEND list_additional_repos "${dependency_repository}")
                            endforeach()
                        endif()

                        capr_plugin(${used_target}
                            PACKAGE      "${out_dep_package}"
                            ID           "${out_dep_id}"
                            VERSION      "${out_dep_version}"
                            VERSION_TYPE "${out_dep_version_type}"
                            REPOSITORIES ${list_additional_repos}
                            ${opt_args})
                    endif()
                endif()
            endforeach()
        endif()
    endif()

    set(${out_got_error} FALSE PARENT_SCOPE)
endfunction()

function(capr_internal_plugin_load_config config_file is_required out_got_error)
    file(READ "${config_file}" config_text)
    set(${out_got_error} TRUE PARENT_SCOPE)
    
    capr_internal_plugin_config_parse_properties(${target} "${config_text}" ${is_required} property_parsing_failed)
    
    if (${property_parsing_failed})
        return()
    endif()
    
    capr_internal_plugin_config_test_requirements(${target} "${config_text}" ${is_required} requirements_passed)
    
    if (NOT ${requirements_passed})
        return()
    endif()

    capr_internal_plugin_config_parse_dependencies(${target} "${config_text}" ${is_required} dependency_parsing_failed)

    if (${dependency_parsing_failed})
        return()
    endif()
    
    set(LOCAL_PROPERTIES_${target} ${LOCAL_PROPERTIES_${target}} PARENT_SCOPE)
    set(${out_got_error} FALSE PARENT_SCOPE)
endfunction()

function(capr_internal_plugin_get_placeholder placeholder_name placeholder_replacement in_out_string)
    string(REPLACE "%${placeholder_name}%" "${placeholder_replacement}" ${in_out_string} "${${in_out_string}}")
    set(${in_out_string} "${${in_out_string}}" PARENT_SCOPE)
endfunction()

function(capr_internal_plugin_resolve_arguments target out_prefix)
    cmake_parse_arguments(ARG "REQUIRED" "PACKAGE;ID;VERSION;VERSION_TYPE" "" ${ARGN})
    set(plugin_string_was_set TRUE)
    
    set(${out_prefix}_PARSED FALSE PARENT_SCOPE)
    
    if (    NOT "${ARGV2}" STREQUAL "REQUIRED" AND NOT "${ARGV2}" STREQUAL "PACKAGE" AND NOT "${ARGV2}" STREQUAL "ID"
        AND NOT "${ARGV2}" STREQUAL "VERSION"  AND NOT "${ARGV2}" STREQUAL "VERSION_TYPE")
        message(VERBOSE "[Capr] Resolving plugin arguments for plugin string '${${ARGV2}}'")
        capr_plugin_get_specs_from_string("${ARGV2}" plugin ERROR_OUT error_message)
        capr_internal_optional_error("${error_message}" ${ARG_REQUIRED})
    endif()
    
    if (NOT "${ARG_PACKAGE}" STREQUAL "")
        if (NOT "${plugin_PACKAGE}" STREQUAL "")
            message(WARNING "[Capr] PACKAGE argument has been set in combination with a plugin string, \
                package will be overriden")
        endif()
        
        message(VERBOSE "[Capr] Changed PACKAGE '${plugin_PACKAGE}' to '${ARG_PACKAGE}'")
        set(plugin_PACKAGE "${ARG_PACKAGE}")
    endif()
    
    if (NOT "${ARG_ID}" STREQUAL "")
        if (NOT "${plugin_ID}" STREQUAL "")
            message(WARNING "[Capr] ID argument has been set in combination with a plugin string, id will be overriden")
        endif()

        message(VERBOSE "[Capr] Changed ID '${plugin_ID}' to '${ARG_ID}'")
        set(plugin_ID "${ARG_ID}")
    endif()

    if (NOT "${ARG_VERSION}" STREQUAL "")
        if (NOT "${plugin_VERSION}" STREQUAL "")
            message(WARNING "[Capr] VERSION argument has been set in combination with a plugin string, \
                version will be overriden")
        endif()
        
        if (NOT "${ARG_VERSION}" MATCHES "[0-9]+.[0-9](.[0-9]+)?")
            message(FATAL_ERROR "[Capr] VERSION argument '${ARG_VERSION}' was not a valid version string")
        endif()

        message(VERBOSE "[Capr] Changed VERSION '${plugin_VERSION}' to '${ARG_VERSION}'")
        set(plugin_VERSION "${ARG_VERSION}")
    endif()
    
    if (NOT "${ARG_VERSION_TYPE}" STREQUAL "")
        if (NOT "${plugin_VERSION_TYPE}" STREQUAL "")
            message(DEBUG "[Capr] \
                VERSION_TYPE argument has been set in combination with a plugin string, will be overriden")
        endif()

        message(VERBOSE "[Capr] Changed VERSION_TYPE '${plugin_VERSION_TYPE}' to '${ARG_VERSION_TYPE}'")
        set(plugin_VERSION_TYPE "${ARG_VERSION_TYPE}")
    endif()
    
    if ("${plugin_PACKAGE}" STREQUAL "")
        capr_internal_optional_error("Cannot declare plugin target '${target}', pacakge was missing" ${ARG_REQUIRED})
    endif()

    if ("${plugin_ID}" STREQUAL "")
        capr_internal_optional_error("Cannot declare plugin target '${target}', id was missing" ${ARG_REQUIRED})
    endif()

    if ("${plugin_VERSION}" STREQUAL "")
        capr_internal_optional_error("Cannot declare plugin target '${target}', version was missing" ${ARG_REQUIRED})
    endif()

    if ("${plugin_VERSION_TYPE}" STREQUAL "")
        set(plugin_VERSION_TYPE "release")
    endif()
    
    if (    NOT "${plugin_VERSION_TYPE}" STREQUAL "release"
        AND NOT "${plugin_VERSION_TYPE}" STREQUAL "preview"
        AND NOT "${plugin_VERSION_TYPE}" STREQUAL "beta")
        capr_internal_optional_error(
            "Invalid version type '${plugin_VERSION_TYPE}', allowed are release, preview, beta or empty"
            ${ARG_REQUIRED})
    endif()
    
    set(${out_prefix}_PACKAGE      ${plugin_PACKAGE}      PARENT_SCOPE)
    set(${out_prefix}_ID           ${plugin_ID}           PARENT_SCOPE)
    set(${out_prefix}_VERSION      ${plugin_VERSION}      PARENT_SCOPE)
    set(${out_prefix}_VERSION_TYPE ${plugin_VERSION_TYPE} PARENT_SCOPE)
    set(${out_prefix}_PARSED       TRUE                   PARENT_SCOPE)
endfunction()

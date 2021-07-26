########################################################################################################################
include_guard()

########################################################################################################################
macro(capr_repository_verify_host_solar url out_succeeded)
    set(${out_succeeded} FALSE PARENT_SCOPE)
    message(VERBOSE "[Capr] Starting online verification of repository '${url}'")

    capr_internal_core_http_request(GET status_request "${url}/status" STATUS request_status)

    list(GET request_status 0 request_code)
    list(GET request_status 1 request_msg)

    if (NOT ${request_code} EQUAL 0)
        if (NOT ${CAPR_SKIP_INVALID_REPOSITORIES})
            message(FATAL_ERROR "Repository '${url}' could not be verified: ${request_code} | ${request_msg}")
        endif()

        message(WARNING "Repository '${url}' could not be verified: ${request_code} | ${request_msg}")
        return()
    endif()

    string(JSON status_code
        ERROR_VARIABLE json_error
        GET "${status_request}" status)

    if (json_error)
        if (NOT ${CAPR_SKIP_INVALID_REPOSITORIES})
            message(FATAL_ERROR "Error reading response of host '${url}': ${json_error}")
        endif()

        message(WARNING "Error reading response of host '${url}': ${json_error}")
        return()
    endif()

    if (NOT ${status_code} EQUAL 0)
        string(JSON status_message GET "${status_text}" message)

        if (NOT ${CAPR_SKIP_INVALID_REPOSITORIES})
            message(FATAL_ERROR "Repository verification for '${url}' returned status code ${status_code}: ${message}")
        endif()

        message(WARNING "Repository verification for '${url}' returned status code ${status_code}: ${message}")
        return()
    endif()

    message(VERBOSE "[Capr] Repository '${url}' verified succesfully with status code 0")
    set(${out_succeeded} TRUE PARENT_SCOPE)
endmacro()


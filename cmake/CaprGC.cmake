########################################################################################################################
set(CAPR_GC_DEBUG TRUE)

########################################################################################################################
macro(capr_gc_push)
    if ("${name}" IN_LIST CAPR_INTERNAL_GC_SCOPES)
        message(WARNING "GC scope already on the stack")
        return()
    endif()

    list(LENGTH CAPR_INTERNAL_GC_SCOPES out_scopes_len)
    list(APPEND CAPR_INTERNAL_GC_SCOPES CAPR_INTERNAL_GC_SCOPE_${out_scopes_len})
    set(CAPR_INTERNAL_GC_CURRENT CAPR_INTERNAL_GC_SCOPE_${out_scopes_len})

    if (CAPR_GC_DEBUG)
        message(STATUS "Pushed new GC scope 'CAPR_INTERNAL_GC_SCOPE_${out_scopes_len}'")
    endif()

    unset(out_scopes_len)
endmacro()

macro(capr_gc_pop)
    if ("${CAPR_INTERNAL_GC_CURRENT}" STREQUAL "")
        message(WARNING "There are no GC stacks currently in use")
        return()
    endif()

    if (CAPR_GC_DEBUG)
        list(LENGTH ${CAPR_INTERNAL_GC_CURRENT} out_gc_len)
        message(STATUS "Popping GC scope 'CAPR_INTERNAL_GC_SCOPE_${out_scopes_len}'")
        message(STATUS "Cleaning ${out_gc_len} resources...")
        unset(out_gc_len)
    endif()

    foreach(resource IN LISTS ${CAPR_INTERNAL_GC_CURRENT})
        if (CAPR_GC_DEBUG)
            message(STATUS "Wiping resource '${resource}'...")
        endif()

        unset(${resource})
    endforeach()

    unset(${CAPR_INTERNAL_GC_CURRENT})
    list(POP_BACK CAPR_INTERNAL_GC_SCOPES)

    list(LENGTH CAPR_INTERNAL_GC_SCOPES scope_length)

    if (scope_length EQUAL 0)
        set(CAPR_INTERNAL_GC_CURRENT "")

        if (CAPR_GC_DEBUG)
            message(STATUS "All GC scopes cleaned up")
        endif()
    else()
        list(GET CAPR_INTERNAL_GC_SCOPES -1 scope_name)
        set(CAPR_INTERNAL_GC_CURRENT ${scope_name})

        if (CAPR_GC_DEBUG)
            message(STATUS "Returning to previous GC scope '${scope_name}'")
        endif()

        unset(scope_name)
    endif()

    unset(scope_length)
endmacro()

macro(capr_gc_add)
    if ("${CAPR_INTERNAL_GC_CURRENT}" STREQUAL "")
        message(WARNING "There are no GC stacks currently in use")
        return()
    endif()

    list(APPEND ${CAPR_INTERNAL_GC_CURRENT} ${ARGN})

    if (CAPR_GC_DEBUG)
        message(STATUS "Pushed existing resources '${ARGN}' onto GC stack '${CAPR_INTERNAL_GC_CURRENT}'")
    endif()
endmacro()

macro(capr_gc_set var_name var_val)
    if ("${CAPR_INTERNAL_GC_CURRENT}" STREQUAL "")
        message(WARNING "There are no GC stacks currently in use")
        return()
    endif()

    set(${var_name} "${var_val}")

    if (NOT "${var_name}" IN_LIST ${CAPR_INTERNAL_GC_CURRENT})
        list(APPEND ${CAPR_INTERNAL_GC_CURRENT} ${var_name})

        if (CAPR_GC_DEBUG)
            message(STATUS "Pushed resource '${var_name}=${var_val}' onto GC stack '${CAPR_INTERNAL_GC_CURRENT}'")
        endif()
    elseif (CAPR_GC_DEBUG)
        message(STATUS "Updated resource '${var_name}=${var_val}' from GC stack '${CAPR_INTERNAL_GC_CURRENT}'")
    endif()
endmacro()

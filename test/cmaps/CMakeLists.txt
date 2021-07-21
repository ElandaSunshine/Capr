cmake_minimum_required(VERSION 3.20.5) 

project(CmapsTest)

include("../../inbuilt/cmaps.cmake")

function(output_map_entries map)
    foreach(entry IN LISTS ${map})
        message("Entry ${entry}")
    endforeach()

    message("")
endfunction()

message("PUT: Put test_key into map:")
cmaps(PUT TEST_MAP "test_key" "someVal")
output_map_entries(TEST_MAP)

message("PUT: Put test_key2 into map:")
cmaps(PUT TEST_MAP "test_key2" "someVal2")
output_map_entries(TEST_MAP)

message("PUT: Put same entry test_key2 into map (value will be updated):")
cmaps(PUT TEST_MAP "test_key2" "someNewVal")
output_map_entries(TEST_MAP)

message("PUT_ABSENT: Put entry test_key2 into map only if absent (won't insert):")
cmaps(PUT_ABSENT TEST_MAP "test_key2" "weirdvaluewhatever")
output_map_entries(TEST_MAP)

message("PUT_ABSENT: Put entry test_key3 into map only if absent (will insert):")
cmaps(PUT_ABSENT TEST_MAP "test_key3" "someVal")
output_map_entries(TEST_MAP)

message("GET: Get test_key2 value from the map:")
cmaps(GET TEST_MAP "test_key2" value_out)
message("${value_out}")
message("")

message("GET: Get non-existent value from the map:")
cmaps(GET TEST_MAP "some_key" value_out)
message("${value_out}")
message("")

message("GET: Get value at index 1 from the map:")
cmaps(GET TEST_MAP 1 value_out)
message("${value_out}")
message("")

message("GET: Get value and key at index 1 from the map:")
cmaps(GET TEST_MAP 1 value_out key_out)
message("Key: ${key_out}")
message("Value: ${value_out}")
message("")

message("GET: Get value at index out of bounds of the map (with severity warning, so we don't terminate the script):")
cmaps(GET TEST_MAP 3 value_out SEVERITY WARNING)
message("Value will stay the same as previous output: ${value_out}")
message("")

message("LENGTH: Get amount of map entries:")
cmaps(LENGTH TEST_MAP len_out)
message("${len_out}")
message("")

message("FIND: Find all element keys of value 'someVal' (value exists):")
cmaps(FIND TEST_MAP "someVal" find_out)
message("${find_out}")
message("")

set(MAP_COPY ${TEST_MAP})
message("FILTER: Exclude all elements that contain the key or value 3:")
cmaps(FILTER MAP_COPY EXCLUDE REGEX "3")
output_map_entries(MAP_COPY)

set(MAP_COPY ${TEST_MAP})
message("FILTER: Exclude all elements that contain the key 3 (key only):")
cmaps(FILTER MAP_COPY EXCLUDE REGEX "3" BY_KEY)
output_map_entries(MAP_COPY)

set(MAP_COPY ${TEST_MAP})
message("FILTER: Exclude all elements that contain the value N (value only):")
cmaps(FILTER MAP_COPY EXCLUDE REGEX "N" BY_VALUE)
output_map_entries(MAP_COPY)

message("REMOVE: Remove the key test_key2:")
cmaps(REMOVE TEST_MAP "test_key2")
output_map_entries(TEST_MAP)

message("REMOVE: Remove the value at index 0:")
cmaps(REMOVE TEST_MAP 0)
output_map_entries(TEST_MAP)

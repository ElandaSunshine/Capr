cmake_minimum_required(VERSION 3.20.5) 

project(CsonTest)

include("${CMAKE_CURRENT_LIST_DIR}/../../cmake/inbuilt/cson/Cson.cmake")

set(TEST_JSON_STRING [[
    {
        "object": {
            "some_int": 42
        },
        
        "int_array": [420, 440, 460, 470],

        "object_array": [
            {
                "whatever": "a string"
            },
            {
                "whatever": "another string",
                "andalso": 290
            },
            {
                "whatever": 034
            }
        ],

        "nested_array": [
            [398, 234, 432],
            [3, 25, 253],
            [35]
        ]
    }]])

cson_parse_json(my_json ${TEST_JSON_STRING})

message("===== Objects")
message("List members of 'object':")
message("${my_json.object}")
message("")
message("Resolve 'some_int':")
message("${my_json.object.some_int}")
message("")

message("===== Arrays")
message("List values of 'int_array':")
message("${my_json.int_array}")
message("")
message("List values of 'object_array':")
message("${my_json.object_array}")
message("")
message("List values of 'nested_array':")
message("${my_json.nested_array}")
message("")
message("Get element at index 0 of 'int_array':")
message("${my_json.int_array+1}")
message("")
message("Get element at index 1 of 'object_array':")
message("${my_json.object_array+1}")
message("")
message("Get elements at index 2 of 'nested_array':")
message("${my_json.nested_array+2}")
message("")

cmake_minimum_required(VERSION 3.20.5) 

project(HoudiniTest)

include("../../inbuilt/houdini.cmake")

set(TEST_INI_STRING [[
    [SECTION1]
    key1=value1
    key2=value2
    key3=

    ;Test comment
    [SECTION2]
    key1=value1]])

houdini_parse_ini(my_ini "${TEST_INI_STRING}")

message("===== Sections")
message("List all sections:")
message("${my_ini}")
message("")
message("List all keys inside a section (SECTION1):")
message("${my_ini.SECTION1}")
message("")
message("===== Values")
message("Get a value of a key in a section (SECTION1 -> key2):")
message("${my_ini.SECTION1.key2}")
message("")

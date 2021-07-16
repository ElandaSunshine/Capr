cmake_minimum_required(VERSION 3.20.5)

project(CLogsTest)

include("${CMAKE_CURRENT_LIST_DIR}/../../inbuilt/clogs/CLogs.cmake")

# Here we define our own message format, this is optional and if not specified will just print the message alone
# Other options are KEEP_UNKNOWN to don't remove format keywords that are not specified and KEEP_UNEXPANDED to don't remove format keywords that don't have a value at that stage
# In addition, we also have NOCACHE to not put the logged messages in a list, the disadvantage is that non-cached loggers are not dumpable
# We can also specify a target our logger is attached to, to provide some more format keywords like SOURCES, COMPILE_DEFINITIONS ect.
clogs_create("testlog" LOG_FORMAT "[%d/%m/%Y-%I:%M][%level_upper%] %message%")

message("Let's test some messages:")
testlog_info("This is an info, I will inform you")
testlog_status("This is a status message, whatever I am")
testlog_warn("This is a warning, hello, pay attention")
testlog_error("This' an error, GRHHHHH MISTAKE")

message("And we can also have empty lines in the log")
testlog_empty()
testlog_empty()
testlog_empty()

message("What else can we do, maybe set the logging level by string:")
testlog_log("warning" "This is a warning message that was set by string level")

# testlog_fatal("This is a fatal error, but disabled due to its not so continuing nature")

message("Let's dump our log:")
clogs_dump("testlog" "${CMAKE_BINARY_DIR}/log.txt")

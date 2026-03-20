cmake_minimum_required(VERSION 3.18)
project(wangwang_core VERSION 3.2.0 LANGUAGES CXX)

# ========================================
# 汪汪机 C++ 核心层构建配置
# 目标：先完成开发环境依赖落地，确保 CMake / libcurl /
# RapidJSON / SQLite / spdlog / GoogleTest 都有明确配置入口
# ========================================

# C++17 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 编译输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 构建选项
option(WANGWANG_USE_SYSTEM_SQLITE "优先使用系统 SQLite 库" ON)
option(WANGWANG_USE_SYSTEM_CURL "优先使用系统 libcurl 库" ON)
option(WANGWANG_ENABLE_TESTS "构建 Google Test 单元测试" ON)

# 依赖根目录
set(WANGWANG_THIRD_PARTY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party)
set(WANGWANG_SQLITE_AMALGAMATION_DIR ${WANGWANG_THIRD_PARTY_DIR}/sqlite)
set(WANGWANG_RAPIDJSON_DIR ${WANGWANG_THIRD_PARTY_DIR}/rapidjson/include)
set(WANGWANG_SPDLOG_DIR ${WANGWANG_THIRD_PARTY_DIR}/spdlog/include)

# ========================================
# 第三方依赖：RapidJSON / spdlog（头文件库）
# ========================================

add_library(wangwang_rapidjson INTERFACE)
target_include_directories(wangwang_rapidjson INTERFACE
    ${WANGWANG_RAPIDJSON_DIR}
)

add_library(wangwang_spdlog INTERFACE)
target_include_directories(wangwang_spdlog INTERFACE
    ${WANGWANG_SPDLOG_DIR}
)

# ========================================
# 第三方依赖：SQLite
# 说明：优先走系统库；若不存在则回退到 amalgamation 单文件模式
# ========================================

if(WANGWANG_USE_SYSTEM_SQLITE)
    find_package(SQLite3 QUIET)
endif()

if(SQLite3_FOUND)
    message(STATUS "使用系统 SQLite: ${SQLite3_VERSION}")
    add_library(wangwang_sqlite INTERFACE)
    target_link_libraries(wangwang_sqlite INTERFACE SQLite::SQLite3)
else()
    message(STATUS "未找到系统 SQLite，使用 third_party/sqlite 单文件回退模式")
    if(EXISTS ${WANGWANG_SQLITE_AMALGAMATION_DIR}/sqlite3.c)
        add_library(wangwang_sqlite STATIC
            ${WANGWANG_SQLITE_AMALGAMATION_DIR}/sqlite3.c
        )
        set_target_properties(wangwang_sqlite PROPERTIES
            C_STANDARD 99
            POSITION_INDEPENDENT_CODE ON
        )
        target_include_directories(wangwang_sqlite PUBLIC
            ${WANGWANG_SQLITE_AMALGAMATION_DIR}
            ${WANGWANG_THIRD_PARTY_DIR}
        )
    else()
        add_library(wangwang_sqlite INTERFACE)
        target_include_directories(wangwang_sqlite INTERFACE
            ${WANGWANG_THIRD_PARTY_DIR}
        )
    endif()
endif()

# ========================================
# 第三方依赖：libcurl
# ========================================

if(WANGWANG_USE_SYSTEM_CURL)
    find_package(CURL REQUIRED)
else()
    find_package(CURL REQUIRED)
endif()

message(STATUS "libcurl include: ${CURL_INCLUDE_DIRS}")

# ========================================
# 核心占位源文件
# 说明：当前先保证开发环境可配置、可验证，避免引用不存在的业务文件
# ========================================

set(WANGWANG_CORE_SOURCES
    src/core/app_core.cpp
    src/database/database_manager.cpp
    src/ffi/wangwang_ffi.cpp
)

add_library(wangwang_core SHARED ${WANGWANG_CORE_SOURCES})

target_include_directories(wangwang_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${WANGWANG_THIRD_PARTY_DIR}
    ${WANGWANG_RAPIDJSON_DIR}
    ${WANGWANG_SPDLOG_DIR}
    ${WANGWANG_SQLITE_AMALGAMATION_DIR}
    ${CURL_INCLUDE_DIRS}
)

target_link_libraries(wangwang_core PUBLIC
    wangwang_rapidjson
    wangwang_spdlog
    wangwang_sqlite
    CURL::libcurl
)

if(ANDROID)
    target_link_libraries(wangwang_core PUBLIC log)
endif()

# ========================================
# Google Test 单元测试配置
# 说明：存在测试文件时才真正编译，避免空引用导致工程无法配置
# ========================================

if(WANGWANG_ENABLE_TESTS)
    enable_testing()
    find_package(GTest QUIET)

    if(GTest_FOUND)
        set(WANGWANG_TEST_SOURCES)

        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_database.cpp)
            list(APPEND WANGWANG_TEST_SOURCES tests/test_database.cpp)
        endif()
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_ai_manager.cpp)
            list(APPEND WANGWANG_TEST_SOURCES tests/test_ai_manager.cpp)
        endif()
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_network.cpp)
            list(APPEND WANGWANG_TEST_SOURCES tests/test_network.cpp)
        endif()

        if(WANGWANG_TEST_SOURCES)
            add_executable(wangwang_tests ${WANGWANG_TEST_SOURCES})
            target_link_libraries(wangwang_tests PRIVATE
                wangwang_core
                GTest::gtest
                GTest::gtest_main
            )
            include(GoogleTest)
            gtest_discover_tests(wangwang_tests)
            message(STATUS "Google Test 已启用")
        else()
            message(STATUS "已找到 Google Test，但 tests 目录暂无测试源码，跳过测试目标生成")
        endif()
    else()
        message(STATUS "未找到 Google Test，测试目标暂不生成")
    endif()
endif()

message(STATUS "汪汪机 C++ 核心层配置完成")
message(STATUS "版本: ${PROJECT_VERSION}")
message(STATUS "构建类型: ${CMAKE_BUILD_TYPE}")

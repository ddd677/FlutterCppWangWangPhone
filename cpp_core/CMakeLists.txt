cmake_minimum_required(VERSION 3.18)
project(wangwang_core VERSION 3.0.0 LANGUAGES CXX)

# C++17标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 编译输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 包含目录
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/rapidjson/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/spdlog/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/sqlite
)

# ========== 第三方库 ==========

# SQLite（单文件编译）
add_library(sqlite3 STATIC
    third_party/sqlite/sqlite3.c
)
set_target_properties(sqlite3 PROPERTIES
    C_STANDARD 99
    POSITION_INDEPENDENT_CODE ON
)

# spdlog（头文件库，使用静态编译模式）
add_library(spdlog INTERFACE)
target_include_directories(spdlog INTERFACE
    third_party/spdlog/include
)

# ========== 核心源文件 ==========

set(CORE_SOURCES
    # 核心模块
    src/core/app_core.cpp
    src/core/app_core.h

    # 数据库模块
    src/database/database_manager.cpp
    src/database/database_manager.h
    src/database/message_dao.cpp
    src/database/message_dao.h
    src/database/contact_dao.cpp
    src/database/contact_dao.h
    src/database/settings_dao.cpp
    src/database/settings_dao.h

    # 网络模块
    src/network/http_client.cpp
    src/network/http_client.h

    # AI接口模块
    src/ai/ai_manager.cpp
    src/ai/ai_manager.h
    src/ai/openai_provider.cpp
    src/ai/openai_provider.h
    src/ai/gemini_provider.cpp
    src/ai/gemini_provider.h
    src/ai/anthropic_provider.cpp
    src/ai/anthropic_provider.h

    # FFI导出接口
    src/ffi/wangwang_ffi.cpp
    src/ffi/wangwang_ffi.h
)

# ========== 构建动态库（供Flutter FFI调用）==========
add_library(wangwang_core SHARED
    ${CORE_SOURCES}
)

target_include_directories(wangwang_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/rapidjson/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/spdlog/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/sqlite
)

# 链接依赖库
target_link_libraries(wangwang_core
    sqlite3
    spdlog
)

# 平台特定配置
if(ANDROID)
    target_link_libraries(wangwang_core
        curl
        log  # Android日志
    )
elseif(IOS)
    target_link_libraries(wangwang_core
        curl
    )
    set_target_properties(wangwang_core PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
    )
endif()

# ========== 单元测试 ==========
option(BUILD_TESTS "构建单元测试" OFF)

if(BUILD_TESTS)
    enable_testing()
    find_package(GTest REQUIRED)

    add_executable(wangwang_tests
        tests/test_database.cpp
        tests/test_ai_manager.cpp
        tests/test_network.cpp
    )

    target_link_libraries(wangwang_tests
        wangwang_core
        GTest::GTest
        GTest::Main
    )

    include(GoogleTest)
    gtest_discover_tests(wangwang_tests)
endif()

message(STATUS "汪汪机C++核心层配置完成")
message(STATUS "版本: ${PROJECT_VERSION}")
message(STATUS "构建类型: ${CMAKE_BUILD_TYPE}")

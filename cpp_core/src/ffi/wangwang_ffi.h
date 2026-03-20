#pragma once

// ========================================
// 汪汪机 C++ 核心层 FFI 导出接口
// 供Flutter通过dart:ffi调用
// 所有函数返回值为JSON字符串，调用方负责释放内存
// ========================================

#ifdef _WIN32
  #define WANGWANG_EXPORT __declspec(dllexport)
#else
  #define WANGWANG_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// ========== 初始化与生命周期 ==========

/// 初始化C++核心层，传入数据库存储路径
/// 返回: {"success":true} 或 {"success":false,"error":"..."}
WANGWANG_EXPORT const char* wangwang_init(const char* db_path);

/// 释放C++核心层资源
WANGWANG_EXPORT void wangwang_cleanup();

/// 释放由C++分配的字符串内存
WANGWANG_EXPORT void wangwang_free_string(const char* str);

/// 获取SDK版本号
WANGWANG_EXPORT const char* wangwang_version();

// ========== 联系人管理 ==========

/// 获取所有联系人列表
/// 返回: JSON数组 [{"id":1,"name":"...","avatar":"...","persona":"..."},...]
WANGWANG_EXPORT const char* wangwang_get_contacts();

/// 创建新联系人
/// name: 联系人姓名
/// persona: 人设内容
/// avatar: 头像路径（可为空）
/// is_user_persona: 是否为用户自己的人设（0/1）
/// 返回: {"success":true,"id":1} 或错误信息
WANGWANG_EXPORT const char* wangwang_create_contact(
    const char* name,
    const char* persona,
    const char* avatar,
    int is_user_persona
);

/// 更新联系人信息
WANGWANG_EXPORT const char* wangwang_update_contact(
    int64_t contact_id,
    const char* name,
    const char* persona,
    const char* avatar
);

/// 删除联系人
WANGWANG_EXPORT const char* wangwang_delete_contact(int64_t contact_id);

/// 获取联系人详情
WANGWANG_EXPORT const char* wangwang_get_contact(int64_t contact_id);

// ========== 聊天会话管理 ==========

/// 获取所有聊天会话列表
WANGWANG_EXPORT const char* wangwang_get_chats();

/// 创建单聊会话
/// contact_id: 联系人ID
WANGWANG_EXPORT const char* wangwang_create_single_chat(int64_t contact_id);

/// 创建群聊会话
/// name: 群聊名称
/// contact_ids_json: JSON数组 [1,2,3]
WANGWANG_EXPORT const char* wangwang_create_group_chat(
    const char* name,
    const char* contact_ids_json
);

/// 删除聊天会话
WANGWANG_EXPORT const char* wangwang_delete_chat(int64_t chat_id);

// ========== 消息管理 ==========

/// 获取指定聊天的消息列表
/// limit: 获取数量（0表示全部）
/// before_id: 获取此消息ID之前的消息（分页用）
WANGWANG_EXPORT const char* wangwang_get_messages(
    int64_t chat_id,
    int limit,
    int64_t before_id
);

/// 发送消息并获取AI回复（异步，通过回调返回）
/// chat_id: 聊天ID
/// content: 消息内容
/// api_config_id: 使用的API配置ID
WANGWANG_EXPORT const char* wangwang_send_message(
    int64_t chat_id,
    const char* content,
    int64_t api_config_id
);

/// 标记消息为已读
WANGWANG_EXPORT const char* wangwang_mark_messages_read(int64_t chat_id);

// ========== API配置管理 ==========

/// 获取所有API配置
WANGWANG_EXPORT const char* wangwang_get_api_configs();

/// 创建API配置
WANGWANG_EXPORT const char* wangwang_create_api_config(
    const char* name,
    const char* base_url,
    const char* api_key,
    const char* model,
    int provider,
    int is_active
);

/// 更新API配置
WANGWANG_EXPORT const char* wangwang_update_api_config(
    int64_t config_id,
    const char* name,
    const char* base_url,
    const char* api_key,
    const char* model,
    int provider,
    int is_active
);

/// 删除API配置
WANGWANG_EXPORT const char* wangwang_delete_api_config(int64_t config_id);

/// 测试API连接
WANGWANG_EXPORT const char* wangwang_test_api_config(int64_t config_id);

// ========== 用户设置 ==========

/// 获取设置项
/// key: 设置键名
WANGWANG_EXPORT const char* wangwang_get_setting(const char* key);

/// 保存设置项
/// key: 设置键名
/// value: 设置值
WANGWANG_EXPORT const char* wangwang_set_setting(const char* key, const char* value);

// ========== 数据导入导出 ==========

/// 导出所有数据为JSON
WANGWANG_EXPORT const char* wangwang_export_data();

/// 导入JSON数据
WANGWANG_EXPORT const char* wangwang_import_data(const char* json_data);

#ifdef __cplusplus
} // extern "C"
#endif

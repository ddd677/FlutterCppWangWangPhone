#include "wangwang_ffi.h"
#include "../core/app_core.h"
#include <string>
#include <cstring>

// ========================================
// FFI导出函数实现
// 所有函数通过AppCore单例调用核心逻辑
// 返回的字符串由调用方通过wangwang_free_string释放
// ========================================

/// 分配并返回字符串（调用方必须调用wangwang_free_string释放）
static const char* allocString(const std::string& str) {
    char* result = new char[str.size() + 1];
    std::memcpy(result, str.c_str(), str.size() + 1);
    return result;
}

/// 返回错误JSON字符串
static const char* errorResult(const std::string& error, int code = -1) {
    std::string json = "{\"success\":false,\"error\":\"" + error
                       + "\",\"error_code\":" + std::to_string(code) + "}";
    return allocString(json);
}

/// 返回成功JSON字符串
static const char* successResult(const std::string& data = "") {
    std::string json = data.empty()
        ? "{\"success\":true}"
        : "{\"success\":true,\"data\":" + data + "}";
    return allocString(json);
}

extern "C" {

/// 初始化核心层
WANGWANG_EXPORT const char* wangwang_init(const char* db_path) {
    if (!db_path) return errorResult("db_path不能为空");
    bool ok = wangwang::AppCore::instance().initialize(db_path);
    if (!ok) return errorResult("核心层初始化失败");
    return allocString("{\"success\":true}");
}

/// 清理核心层
WANGWANG_EXPORT void wangwang_cleanup() {
    wangwang::AppCore::instance().cleanup();
}

/// 释放字符串内存
WANGWANG_EXPORT void wangwang_free_string(const char* str) {
    delete[] str;
}

/// 返回SDK版本
WANGWANG_EXPORT const char* wangwang_version() {
    return allocString("3.0.0");
}

// ========== 联系人 ==========

WANGWANG_EXPORT const char* wangwang_get_contacts() {
    auto result = wangwang::AppCore::instance().getContacts();
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_create_contact(
    const char* name, const char* persona,
    const char* avatar, int is_user_persona) {
    if (!name || !persona) return errorResult("参数不能为空");
    auto result = wangwang::AppCore::instance().createContact(
        name, persona ? persona : "",
        avatar ? avatar : "", is_user_persona != 0);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_update_contact(
    int64_t contact_id, const char* name,
    const char* persona, const char* avatar) {
    auto result = wangwang::AppCore::instance().updateContact(
        contact_id,
        name ? name : "",
        persona ? persona : "",
        avatar ? avatar : "");
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_delete_contact(int64_t contact_id) {
    auto result = wangwang::AppCore::instance().deleteContact(contact_id);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_get_contact(int64_t contact_id) {
    auto result = wangwang::AppCore::instance().getContact(contact_id);
    return allocString(result);
}

// ========== 聊天会话 ==========

WANGWANG_EXPORT const char* wangwang_get_chats() {
    auto result = wangwang::AppCore::instance().getChats();
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_create_single_chat(int64_t contact_id) {
    auto result = wangwang::AppCore::instance().createSingleChat(contact_id);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_create_group_chat(
    const char* name, const char* contact_ids_json) {
    if (!name || !contact_ids_json) return errorResult("参数不能为空");
    auto result = wangwang::AppCore::instance().createGroupChat(
        name, contact_ids_json);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_delete_chat(int64_t chat_id) {
    auto result = wangwang::AppCore::instance().deleteChat(chat_id);
    return allocString(result);
}

// ========== 消息 ==========

WANGWANG_EXPORT const char* wangwang_get_messages(
    int64_t chat_id, int limit, int64_t before_id) {
    auto result = wangwang::AppCore::instance().getMessages(
        chat_id, limit, before_id);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_send_message(
    int64_t chat_id, const char* content, int64_t api_config_id) {
    if (!content) return errorResult("消息内容不能为空");
    auto result = wangwang::AppCore::instance().sendMessage(
        chat_id, content, api_config_id);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_mark_messages_read(int64_t chat_id) {
    auto result = wangwang::AppCore::instance().markMessagesRead(chat_id);
    return allocString(result);
}

// ========== API配置 ==========

WANGWANG_EXPORT const char* wangwang_get_api_configs() {
    auto result = wangwang::AppCore::instance().getAPIConfigs();
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_create_api_config(
    const char* name, const char* base_url, const char* api_key,
    const char* model, int provider, int is_active) {
    if (!name || !base_url || !api_key || !model)
        return errorResult("参数不能为空");
    auto result = wangwang::AppCore::instance().createAPIConfig(
        name, base_url, api_key, model, provider, is_active != 0);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_update_api_config(
    int64_t config_id, const char* name, const char* base_url,
    const char* api_key, const char* model, int provider, int is_active) {
    auto result = wangwang::AppCore::instance().updateAPIConfig(
        config_id, name ? name : "", base_url ? base_url : "",
        api_key ? api_key : "", model ? model : "",
        provider, is_active != 0);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_delete_api_config(int64_t config_id) {
    auto result = wangwang::AppCore::instance().deleteAPIConfig(config_id);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_test_api_config(int64_t config_id) {
    auto result = wangwang::AppCore::instance().testAPIConfig(config_id);
    return allocString(result);
}

// ========== 设置 ==========

WANGWANG_EXPORT const char* wangwang_get_setting(const char* key) {
    if (!key) return errorResult("key不能为空");
    auto result = wangwang::AppCore::instance().getSetting(key);
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_set_setting(
    const char* key, const char* value) {
    if (!key || !value) return errorResult("参数不能为空");
    auto result = wangwang::AppCore::instance().setSetting(key, value);
    return allocString(result);
}

// ========== 数据导入导出 ==========

WANGWANG_EXPORT const char* wangwang_export_data() {
    auto result = wangwang::AppCore::instance().exportData();
    return allocString(result);
}

WANGWANG_EXPORT const char* wangwang_import_data(const char* json_data) {
    if (!json_data) return errorResult("数据不能为空");
    auto result = wangwang::AppCore::instance().importData(json_data);
    return allocString(result);
}

} // extern "C"

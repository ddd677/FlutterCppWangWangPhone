#include "app_core.h"
#include "../database/database_manager.h"
#include <iostream>
#include <sstream>

namespace wangwang {

/// 获取单例实例
AppCore& AppCore::instance() {
    static AppCore inst;
    return inst;
}

/// 初始化核心层：打开数据库、创建表结构
bool AppCore::initialize(const std::string& db_path) {
    if (initialized_) {
        std::cout << "[汪汪机] AppCore已初始化，跳过" << std::endl;
        return true;
    }

    std::cout << "[汪汪机] 正在初始化核心层..." << std::endl;

    // 初始化数据库
    if (!DatabaseManager::instance().initialize(db_path)) {
        std::cerr << "[汪汪机] 数据库初始化失败" << std::endl;
        return false;
    }

    initialized_ = true;
    std::cout << "[汪汪机] 核心层初始化成功" << std::endl;
    return true;
}

/// 清理所有资源
void AppCore::cleanup() {
    if (!initialized_) return;
    DatabaseManager::instance().close();
    initialized_ = false;
    std::cout << "[汪汪机] 核心层已清理" << std::endl;
}

// ===== 内部辅助函数 =====

/// 构造成功JSON响应
std::string AppCore::okJson(const std::string& data) {
    if (data.empty()) return "{\"success\":true}";
    return "{\"success\":true,\"data\":" + data + "}";
}

/// 构造失败JSON响应
std::string AppCore::errJson(const std::string& error, int code) {
    return "{\"success\":false,\"error\":\"" + error +
           "\",\"error_code\":" + std::to_string(code) + "}";
}

// ===== 联系人管理 =====

/// 获取所有联系人列表，返回JSON数组
std::string AppCore::getContacts() {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().getAllContacts();
}

/// 创建新联系人
std::string AppCore::createContact(const std::string& name,
                                   const std::string& persona,
                                   const std::string& avatar,
                                   bool is_user_persona) {
    if (!initialized_) return errJson("核心层未初始化");
    if (name.empty()) return errJson("联系人姓名不能为空");
    return DatabaseManager::instance().createContact(name, persona, avatar, is_user_persona);
}

/// 更新联系人信息
std::string AppCore::updateContact(int64_t id,
                                   const std::string& name,
                                   const std::string& persona,
                                   const std::string& avatar) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().updateContact(id, name, persona, avatar);
}

/// 删除联系人
std::string AppCore::deleteContact(int64_t id) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().deleteContact(id);
}

/// 获取单个联系人详情
std::string AppCore::getContact(int64_t id) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().getContact(id);
}

// ===== 聊天会话 =====

/// 获取所有聊天会话
std::string AppCore::getChats() {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().getAllChats();
}

/// 创建单聊会话
std::string AppCore::createSingleChat(int64_t contact_id) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().createSingleChat(contact_id);
}

/// 创建群聊会话
std::string AppCore::createGroupChat(const std::string& name,
                                     const std::string& contact_ids_json) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().createGroupChat(name, contact_ids_json);
}

/// 删除聊天会话
std::string AppCore::deleteChat(int64_t chat_id) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().deleteChat(chat_id);
}

// ===== 消息 =====

/// 获取聊天消息列表
std::string AppCore::getMessages(int64_t chat_id, int limit, int64_t before_id) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().getMessages(chat_id, limit, before_id);
}

/// 发送消息（暂时存储消息，AI接口后续集成）
std::string AppCore::sendMessage(int64_t chat_id,
                                 const std::string& content,
                                 int64_t api_config_id) {
    if (!initialized_) return errJson("核心层未初始化");
    if (content.empty()) return errJson("消息内容不能为空");
    // 存储用户消息
    auto result = DatabaseManager::instance().insertMessage(chat_id, 0, content, 0, 0);
    // TODO: 调用AI接口获取回复
    return result;
}

/// 标记消息已读
std::string AppCore::markMessagesRead(int64_t chat_id) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().markMessagesRead(chat_id);
}

// ===== API配置 =====

/// 获取所有API配置
std::string AppCore::getAPIConfigs() {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().getAllAPIConfigs();
}

/// 创建API配置
std::string AppCore::createAPIConfig(const std::string& name,
                                     const std::string& base_url,
                                     const std::string& api_key,
                                     const std::string& model,
                                     int provider,
                                     bool is_active) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().createAPIConfig(name, base_url, api_key, model, provider, is_active);
}

/// 更新API配置
std::string AppCore::updateAPIConfig(int64_t id,
                                     const std::string& name,
                                     const std::string& base_url,
                                     const std::string& api_key,
                                     const std::string& model,
                                     int provider,
                                     bool is_active) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().updateAPIConfig(id, name, base_url, api_key, model, provider, is_active);
}

/// 删除API配置
std::string AppCore::deleteAPIConfig(int64_t id) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().deleteAPIConfig(id);
}

/// 测试API连接（预留接口）
std::string AppCore::testAPIConfig(int64_t id) {
    if (!initialized_) return errJson("核心层未初始化");
    // TODO: 实现实际的API连通性测试
    return okJson();
}

// ===== 用户设置 =====

/// 获取设置项
std::string AppCore::getSetting(const std::string& key) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().getSetting(key);
}

/// 保存设置项
std::string AppCore::setSetting(const std::string& key, const std::string& value) {
    if (!initialized_) return errJson("核心层未初始化");
    return DatabaseManager::instance().setSetting(key, value);
}

// ===== 数据导入导出 =====

/// 导出所有数据为JSON
std::string AppCore::exportData() {
    if (!initialized_) return errJson("核心层未初始化");
    // TODO: 实现完整的数据导出
    return okJson("{\"version\":\"3.0.0\"}");
}

/// 导入数据
std::string AppCore::importData(const std::string& json_data) {
    if (!initialized_) return errJson("核心层未初始化");
    if (json_data.empty()) return errJson("导入数据不能为空");
    // TODO: 实现完整的数据导入
    return okJson();
}

} // namespace wangwang

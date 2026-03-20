#pragma once
#include <string>
#include <cstdint>
#include "../../third_party/sqlite/sqlite3.h"

namespace wangwang {

/**
 * DatabaseManager - 数据库管理器
 * 封装SQLite操作，提供联系人、聊天、消息、API配置、设置的CRUD接口
 * 所有方法返回JSON字符串
 */
class DatabaseManager {
public:
    /// 获取单例
    static DatabaseManager& instance();

    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;

    // ===== 生命周期 =====
    bool initialize(const std::string& db_path);
    void close();
    bool isOpen() const { return db_ != nullptr; }

    // ===== 基础SQL执行 =====
    bool execute(const std::string& sql);

    // ===== 联系人 =====
    std::string getAllContacts();
    std::string createContact(const std::string& name,
                              const std::string& persona,
                              const std::string& avatar,
                              bool is_user_persona);
    std::string updateContact(int64_t id,
                              const std::string& name,
                              const std::string& persona,
                              const std::string& avatar);
    std::string deleteContact(int64_t id);
    std::string getContact(int64_t id);

    // ===== 聊天会话 =====
    std::string getAllChats();
    std::string createSingleChat(int64_t contact_id);
    std::string createGroupChat(const std::string& name,
                                const std::string& contact_ids_json);
    std::string deleteChat(int64_t chat_id);

    // ===== 消息 =====
    std::string getMessages(int64_t chat_id, int limit, int64_t before_id);
    std::string insertMessage(int64_t chat_id,
                              int64_t sender_id,
                              const std::string& content,
                              int role,
                              int type);
    std::string markMessagesRead(int64_t chat_id);

    // ===== API配置 =====
    std::string getAllAPIConfigs();
    std::string createAPIConfig(const std::string& name,
                                const std::string& base_url,
                                const std::string& api_key,
                                const std::string& model,
                                int provider,
                                bool is_active);
    std::string updateAPIConfig(int64_t id,
                                const std::string& name,
                                const std::string& base_url,
                                const std::string& api_key,
                                const std::string& model,
                                int provider,
                                bool is_active);
    std::string deleteAPIConfig(int64_t id);

    // ===== 用户设置 =====
    std::string getSetting(const std::string& key);
    std::string setSetting(const std::string& key, const std::string& value);

private:
    DatabaseManager() = default;
    ~DatabaseManager();

    sqlite3* db_ = nullptr;
    std::string db_path_;

    /// 创建所有数据库表
    bool createTables();

    /// 转义JSON字符串中的特殊字符
    std::string escapeJson(const std::string& str);

    /// 构造成功JSON
    std::string okJson(const std::string& data = "");
    /// 构造失败JSON
    std::string errJson(const std::string& error);
};

} // namespace wangwang

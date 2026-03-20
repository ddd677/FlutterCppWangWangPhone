#include "database_manager.h"
#include <iostream>
#include <sstream>

namespace wangwang {

/// 获取单例实例
DatabaseManager& DatabaseManager::instance() {
    static DatabaseManager instance;
    return instance;
}

DatabaseManager::~DatabaseManager() {
    close();
}

/// 初始化数据库，创建或打开数据库文件
bool DatabaseManager::initialize(const std::string& db_path) {
    db_path_ = db_path;

    // 打开或创建SQLite数据库文件
    int rc = sqlite3_open(db_path.c_str(), &db_);
    if (rc != SQLITE_OK) {
        std::cerr << "[汪汪机] 数据库打开失败: " << sqlite3_errmsg(db_) << std::endl;
        db_ = nullptr;
        return false;
    }

    // 开启WAL模式提升并发性能
    execute("PRAGMA journal_mode=WAL;");
    // 开启外键约束
    execute("PRAGMA foreign_keys=ON;");
    // 设置缓存大小
    execute("PRAGMA cache_size=4096;");

    // 创建数据库表结构
    if (!createTables()) {
        std::cerr << "[汪汪机] 数据库表创建失败" << std::endl;
        return false;
    }

    std::cout << "[汪汪机] 数据库初始化成功: " << db_path << std::endl;
    return true;
}

/// 关闭数据库连接
void DatabaseManager::close() {
    if (db_ != nullptr) {
        sqlite3_close(db_);
        db_ = nullptr;
        std::cout << "[汪汪机] 数据库已关闭" << std::endl;
    }
}

/// 创建所有数据库表
bool DatabaseManager::createTables() {
    // 联系人表
    const char* create_contacts = R"(
        CREATE TABLE IF NOT EXISTS contacts (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            name         TEXT NOT NULL,
            avatar       TEXT DEFAULT '',
            persona      TEXT DEFAULT '',
            is_user_persona INTEGER DEFAULT 0,
            created_at   INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            updated_at   INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
    )";

    // 聊天会话表
    const char* create_chats = R"(
        CREATE TABLE IF NOT EXISTS chats (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            name            TEXT DEFAULT '',
            is_group        INTEGER DEFAULT 0,
            last_message    TEXT DEFAULT '',
            last_message_time INTEGER DEFAULT 0,
            created_at      INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
    )";

    // 聊天参与者表（多对多关联）
    const char* create_chat_participants = R"(
        CREATE TABLE IF NOT EXISTS chat_participants (
            chat_id    INTEGER NOT NULL,
            contact_id INTEGER NOT NULL,
            PRIMARY KEY (chat_id, contact_id),
            FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
            FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
        );
    )";

    // 消息表
    const char* create_messages = R"(
        CREATE TABLE IF NOT EXISTS messages (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            chat_id    INTEGER NOT NULL,
            sender_id  INTEGER NOT NULL,
            content    TEXT NOT NULL DEFAULT '',
            role       INTEGER NOT NULL DEFAULT 0,
            type       INTEGER NOT NULL DEFAULT 0,
            timestamp  INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            is_read    INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
            FOREIGN KEY (sender_id) REFERENCES contacts(id)
        );
    )";

    // 消息表索引（加速查询）
    const char* create_messages_index = R"(
        CREATE INDEX IF NOT EXISTS idx_messages_chat_id
        ON messages(chat_id, timestamp DESC);
    )";

    // API配置表
    const char* create_api_configs = R"(
        CREATE TABLE IF NOT EXISTS api_configs (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            name      TEXT NOT NULL,
            base_url  TEXT NOT NULL DEFAULT '',
            api_key   TEXT NOT NULL DEFAULT '',
            model     TEXT NOT NULL DEFAULT '',
            provider  INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
    )";

    // 用户设置表（键值对存储）
    const char* create_settings = R"(
        CREATE TABLE IF NOT EXISTS settings (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL DEFAULT ''
        );
    )";

    // 朋友圈动态表
    const char* create_moments = R"(
        CREATE TABLE IF NOT EXISTS moments (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            contact_id INTEGER NOT NULL,
            content    TEXT NOT NULL DEFAULT '',
            images     TEXT DEFAULT '',
            likes      INTEGER DEFAULT 0,
            timestamp  INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
        );
    )";

    // 依次执行建表语句
    return execute(create_contacts)
        && execute(create_chats)
        && execute(create_chat_participants)
        && execute(create_messages)
        && execute(create_messages_index)
        && execute(create_api_configs)
        && execute(create_settings)
        && execute(create_moments);
}

/// 执行SQL语句（无返回数据）
bool DatabaseManager::execute(const std::string& sql) {
    if (!db_) return false;
    char* err_msg = nullptr;
    int rc = sqlite3_exec(db_, sql.c_str(), nullptr, nullptr, &err_msg);
    if (rc != SQLITE_OK) {
        std::cerr << "[汪汪机] SQL执行错误: " << (err_msg ? err_msg : "未知错误") << std::endl;
        std::cerr << "[汪汪机] SQL语句: " << sql << std::endl;
        sqlite3_free(err_msg);
        return false;
    }
    return true;
}

/// 执行带参数的预处理SQL语句
bool DatabaseManager::executePrepared(
    const std::string& sql,
    const std::function<void(sqlite3_stmt*)>& bind_func) {
    if (!db_) return false;

    sqlite3_stmt* stmt = nullptr;
    int rc = sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr);
    if (rc != SQLITE_OK) {
        std::cerr << "[汪汪机] SQL预处理失败: " << sqlite3_errmsg(db_) << std::endl;
        return false;
    }

    // 执行参数绑定回调
    if (bind_func) {
        bind_func(stmt);
    }

    rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);

    if (rc != SQLITE_DONE && rc != SQLITE_ROW) {
        std::cerr << "[汪汪机] SQL执行失败: " << sqlite3_errmsg(db_) << std::endl;
        return false;
    }
    return true;
}

/// 开启事务
bool DatabaseManager::beginTransaction() {
    return execute("BEGIN TRANSACTION;");
}

/// 提交事务
bool DatabaseManager::commitTransaction() {
    return execute("COMMIT;");
}

/// 回滚事务
bool DatabaseManager::rollbackTransaction() {
    return execute("ROLLBACK;");
}

/// 获取最后插入的行ID
int64_t DatabaseManager::lastInsertRowId() const {
    if (!db_) return -1;
    return sqlite3_last_insert_rowid(db_);
}

/// 获取最后的错误信息
std::string DatabaseManager::lastError() const {
    if (!db_) return "数据库未初始化";
    return std::string(sqlite3_errmsg(db_));
}

} // namespace wangwang

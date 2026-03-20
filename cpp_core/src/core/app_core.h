#pragma once
#include <string>
#include <memory>
#include "../database/database_manager.h"

namespace wangwang {

/**
 * AppCore - 汪汪机C++核心层入口
 * 单例模式，管理所有子系统的生命周期
 * 通过此类统一对外提供业务接口
 */
class AppCore {
public:
    /// 获取单例
    static AppCore& instance();

    /// 禁止拷贝和赋值
    AppCore(const AppCore&) = delete;
    AppCore& operator=(const AppCore&) = delete;

    // ===== 生命周期 =====

    /// 初始化核心层，传入数据库路径
    bool initialize(const std::string& db_path);

    /// 清理所有资源
    void cleanup();

    /// 是否已初始化
    bool isInitialized() const { return initialized_; }

    // ===== 联系人管理 =====

    /// 获取所有联系人（返回JSON字符串）
    std::string getContacts();

    /// 创建联系人
    std::string createContact(const std::string& name,
                              const std::string& persona,
                              const std::string& avatar,
                              bool is_user_persona);

    /// 更新联系人
    std::string updateContact(int64_t id,
                              const std::string& name,
                              const std::string& persona,
                              const std::string& avatar);

    /// 删除联系人
    std::string deleteContact(int64_t id);

    /// 获取单个联系人
    std::string getContact(int64_t id);

    // ===== 聊天会话 =====

    /// 获取所有会话
    std::string getChats();

    /// 创建单聊
    std::string createSingleChat(int64_t contact_id);

    /// 创建群聊
    std::string createGroupChat(const std::string& name,
                                const std::string& contact_ids_json);

    /// 删除会话
    std::string deleteChat(int64_t chat_id);

    // ===== 消息 =====

    /// 获取消息列表
    std::string getMessages(int64_t chat_id, int limit, int64_t before_id);

    /// 发送消息并获取AI回复
    std::string sendMessage(int64_t chat_id,
                            const std::string& content,
                            int64_t api_config_id);

    /// 标记消息已读
    std::string markMessagesRead(int64_t chat_id);

    // ===== API配置 =====

    /// 获取所有API配置
    std::string getAPIConfigs();

    /// 创建API配置
    std::string createAPIConfig(const std::string& name,
                                const std::string& base_url,
                                const std::string& api_key,
                                const std::string& model,
                                int provider,
                                bool is_active);

    /// 更新API配置
    std::string updateAPIConfig(int64_t id,
                                const std::string& name,
                                const std::string& base_url,
                                const std::string& api_key,
                                const std::string& model,
                                int provider,
                                bool is_active);

    /// 删除API配置
    std::string deleteAPIConfig(int64_t id);

    /// 测试API连接
    std::string testAPIConfig(int64_t id);

    // ===== 用户设置 =====

    /// 获取设置项
    std::string getSetting(const std::string& key);

    /// 保存设置项
    std::string setSetting(const std::string& key, const std::string& value);

    // ===== 数据导入导出 =====

    /// 导出所有数据
    std::string exportData();

    /// 导入数据
    std::string importData(const std::string& json_data);

private:
    AppCore() = default;
    ~AppCore() = default;

    bool initialized_ = false;

    /// 构造成功/失败的JSON响应
    std::string okJson(const std::string& data = "");
    std::string errJson(const std::string& error, int code = -1);
};

} // namespace wangwang

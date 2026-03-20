#pragma once
#include <string>
#include <vector>
#include <cstdint>

namespace wangwang {

/// AI接口提供商枚举
enum class AIProvider {
    OpenAI = 0,      // OpenAI Chat Completion
    OpenAIResponse,  // OpenAI Response API
    Gemini,          // Google Gemini
    Anthropic        // Anthropic Claude
};

/// 消息角色枚举
enum class MessageRole {
    User = 0,    // 用户发送
    Assistant,   // AI回复
    System       // 系统消息
};

/// 消息类型枚举
enum class MessageType {
    Text = 0,   // 文字消息
    Voice,      // 语音消息
    Image       // 图片消息
};

/// 联系人数据结构
struct Contact {
    int64_t id = 0;
    std::string name;
    std::string avatar;
    std::string persona;       // AI人设内容
    bool is_user_persona = false; // 是否为用户自己的人设
    int64_t created_at = 0;
    int64_t updated_at = 0;
};

/// 聊天会话数据结构
struct Chat {
    int64_t id = 0;
    std::string name;
    bool is_group = false;
    std::string last_message;
    int64_t last_message_time = 0;
    int64_t created_at = 0;
    std::vector<int64_t> participant_ids;
};

/// 消息数据结构
struct Message {
    int64_t id = 0;
    int64_t chat_id = 0;
    int64_t sender_id = 0;
    std::string content;
    MessageRole role = MessageRole::User;
    MessageType type = MessageType::Text;
    int64_t timestamp = 0;
    bool is_read = false;
};

/// API配置数据结构
struct APIConfig {
    int64_t id = 0;
    std::string name;
    std::string base_url;
    std::string api_key;
    std::string model;
    AIProvider provider = AIProvider::OpenAI;
    bool is_active = false;
    int64_t created_at = 0;
};

} // namespace wangwang

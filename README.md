# 汪汪机 (WangWang Phone)

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue" alt="Platform">
  <img src="https://img.shields.io/badge/language-C%2B%2B%20%7C%20Flutter-yellow" alt="Language">
  <img src="https://img.shields.io/badge/license-CC%20BY-NC--SA%204.0-green" alt="License">
  <img src="https://img.shields.io/badge/version-1.0.0-orange" alt="Version">
</p>

<p align="center">
  <strong>像小狗一样陪伴你的AI-Native虚拟操作系统</strong>
</p>

---

## 📱 项目简介

汪汪机是一款AI-Native虚拟操作系统产品（行业内称为"小手机"），旨在为用户提供情感陪伴和社交体验。产品像小狗一样陪伴用户，主要面向18-28岁年轻女性（缺少陪伴的群体）。

### 核心特性

- 🔮 **虚拟操作系统**：在软件中实现完整的虚拟操作系统，包含微信等社交应用
- 🤖 **AI角色互动**：所有应用不连接真实环境，由用户导入TXT文件自定义AI角色人设
- 💬 **沉浸式社交**：支持单聊、群聊，AI角色间可形成社交网络
- ✨ **真实体验**：无限接近真实应用体验（文字聊天、语音通话、视频互动、朋友圈）
- 🏠 **本地部署**：所有内容均由AI生成，数据存储在用户本地

---

## 🛠️ 技术架构

### 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 后端核心 | C++ | 跨平台核心业务逻辑 |
| 前端UI | Flutter | 跨平台应用开发 |
| 通信方案 | Flutter FFI | 高性能原生调用 |

### C++ 核心层

- **HTTP库**: [libcurl](https://curl.se/libcurl/) - 最成熟的C++ HTTP库
- **JSON解析**: [RapidJSON](https://github.com/Tencent/rapidjson/) - 高性能JSON解析
- **数据库**: [SQLite](https://www.sqlite.org/) - 嵌入式数据库
- **日志**: [spdlog](https://github.com/gabime/spdlog) - 高性能日志库
- **测试**: Google Test - C++单元测试框架

### Flutter UI层

- **状态管理**: Riverpod - 现代化状态管理
- **网络请求**: dio - 功能强大的HTTP客户端
- **日志**: logging + logger - 完善的日志系统
- **测试**: flutter_test + mockito - 单元测试

### AI接口支持

- OpenAI Chat Completion
- OpenAI Response
- Google Gemini
- Anthropic (Claude)

---

## 📋 功能列表

### 当前开发阶段

- [x] 阶段一：启动与解锁（开屏动画、锁屏界面、密码解锁）
- [ ] 阶段二：主屏幕（桌面布局、应用图标、状态栏适配）
- [ ] 阶段三：微信应用（聊天、联系人、朋友圈、我）
- [ ] 阶段四：设置应用（启动设置、API配置、数据管理）
- [ ] 阶段五：数据存储（C++层SQLite）
- [ ] 阶段六：AI接口（C++层网络通信）
- [ ] 阶段七：Flutter与C++通信（FFI集成）
- [ ] 阶段八：测试与部署

### MVP功能范围

- 完整的聊天功能（文字消息）
- 单聊、群聊等核心交互
- AI角色人设导入（TXT文件）
- API配置（支持4种AI格式）

---

## 🚀 快速开始

### 环境要求

- **Flutter**: 3.x 或更高版本
- **C++编译器**: GCC/Clang/MSVC
- **CMake**: 3.16 或更高版本

### 构建步骤

```bash
# 1. 克隆项目
git clone https://github.com/Liunian06/FlutterCppWangWangPhone.git

# 2. 进入项目目录
cd FlutterCppWangWangPhone

# 3. 安装Flutter依赖
flutter pub get

# 4. 运行项目（开发模式）
flutter run

# 5. 构建Android
flutter build apk

# 6. 构建iOS（需要macOS或GitHub Actions）
flutter build ios
```

---

## 📁 项目结构

```
FlutterCppWangWangPhone/
├── version.properties          # 版本管理配置
├── DevelopBackground.md        # 项目背景文档
├── DevelopTechFramework.md     # 技术框架文档
├── DevelopRequirements.md      # 开发需求文档
├── TODO.md                     # 任务清单
├── README.md                   # 项目说明
└── (Flutter项目结构)            # Flutter应用代码
    ├── lib/                    # Dart源代码
    ├── android/                # Android平台代码
    ├── ios/                    # iOS平台代码
    └── cpp/                    # C++核心代码
```

---

## 📄 开源协议

### 许可证

本项目采用 [知识共享 署名-非商业性使用-相同方式共享 4.0 国际许可协议 (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/) 进行许可。

### 授权要求

#### ✅ 允许的行为

- 自由分享和传播本项目
- 对源代码进行二次修改
- 在保留原作者署名和项目链接的前提下进行分发

#### ❌ 禁止的行为

- 直接销售本项目的访问地址、下载链接或源代码
- 修改后作为商业付费软件或服务进行出售
- 源码交易（二次销售本项目代码）

#### 🔓 例外条款

上述限制仅限于保护本项目的核心代码与程序本身。

- **内容衍生物不受限**：基于本项目产生的内容衍生物（如角色人设卡、提示词预设、导出的聊天记录艺术加工等）可以商业化
- **版权归属**：衍生物的版权完全归属于创作者本人

#### 📜 相同方式共享

如果您基于本项目进行了修改或二次创作，您必须采用与本协议相同的 CC BY-NC-SA 4.0 协议来分发您的作品。

---

## 👤 作者

- **作者**: 汪汪机开发团队
- **邮箱**: [联系邮箱待补充]
- **GitHub**: https://github.com/Liunian06/FlutterCppWangWangPhone

---

## 🙏 致谢

感谢所有为汪汪机项目贡献力量的开发者，以及1500+公测群用户的宝贵反馈！

---

<p align="center">
  <strong>让AI像小狗一样陪伴你</strong>
</p>
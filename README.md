# AssetVault · 个人数字资产管理 App

> **面向技术从业者的一站式加密资产管理工具**

AssetVault 是一款为技术从业者（开发者、站长、加密货币用户）量身打造的数字资产管理工具，支持本地加密、离线优先、动态字段和到期提醒设计。

## 🌟 核心特性
1. **全类型资产支持**：预设域名、VPS、SSL证书、邮箱、SaaS订阅、服务 API Key。
2. **多重加密安全架构**：基于主密码和盐（Salt）利用 `Argon2id` 导出 AES-256 主密钥。结合手机底层安全区（Keychain / Keystore）+ 本地生物识别（Face ID / Touch ID）保护。数据库级密文存储基于 `SQLCipher`，关键字段运用 `AES-256-GCM` 额外套壳。
3. **离线与本地优先**：所有数据存放于设备本地独立运行。
4. **智能追踪提示**：本地调度系统级别定时/过期推送预警。
5. **数据无缝导出**：支持导出整个加密数据库 JSON 结构至剪贴板，用于跨设备快速手动接力。

## 🛠️ 技术栈
*   **框架**: Flutter (`v3.11+`)
*   **路由**: `go_router`
*   **状态管理**: `flutter_riverpod`
*   **本地数据库**: `sqflite_sqlcipher` (AES-256 数据库加密)
*   **安全与密码学**: `pointycastle` (AES-GCM), `dargon2_flutter` (Argon2id 加密分析)
*   **安全存储**: `flutter_secure_storage`, `local_auth`
*   **工程化 CodeGen**: `freezed`, `json_serializable`, `build_runner`

---

## 💻 本地工程运行指南

### 环境要求
1. macOS (推荐) / Linux / Windows 物理机
2. Flutter SDK v3.11 及以上 
3. Xcode (iOS 测试)及相关 Command Line Tools
4. Android Studio / Java 17+ (Android 测试)
5. CocoaPods (用于安装 iOS 平台依赖)

### 本地编译与调试
1. **克隆项目**:
   ```bash
   git clone https://github.com/app/assetvault.git
   cd asset_vault
   ```

2. **安装 Flutter 依赖**:
   ```bash
   flutter pub get
   ```

3. **执行代码生成 (CodeGen)**:
   > 🔴 必须执行此步骤生成 Freezed 模型及 JSON 序列化的相关底层代码。
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **运行 iOS / Android 开发版本**:
   ```bash
   # 测试 iOS
   flutter run -d ios
   
   # 测试 Android
   flutter run -d android
   ```

### 持续集成 (CI/CD)
本项目已集成 Github Actions 自动化的 CI 审计及编译链路（详见 `.github/workflows/ci.yml`）。
包含每次 PR/Push 时的:
- `flutter analyze` 语法校验
- `flutter test` 单元测试通过性
- Android APK 生产包构建
- iOS (No Codesign) 验证构建

## 🔮 Roadmap 计划
- [ ] Asset Form 的深色主题调优与更动态化的 Tags 添加逻辑
- [ ] iCloud / WebDAV 等自选通道的数据备份
- [ ] 桌面端（macOS / Windows）的键鼠适配增强优化

## 📄 协议许可
MIT License. All rights reserved.

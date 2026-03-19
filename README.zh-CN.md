# OctarqVault · 个人数字资产管理 App

> **面向技术从业者的一站式加密资产管理工具**

OctarqVault 是一款为技术从业者（开发者、站长、加密货币用户）量身打造的数字资产管理工具，支持本地加密、离线优先、动态字段和到期提醒设计。

- **官网**: [vault.octarq.org](https://vault.octarq.org)
- **帮助文档**: [vault.octarq.org/docs](https://vault.octarq.org/docs)

## 🌟 核心特性
1. **全类型资产支持**：预设域名、VPS、SSL证书、邮箱、SaaS订阅、服务 API Key。
2. **多重加密安全架构**：基于主密码和盐（Salt）利用 `Argon2id` 导出 AES-256 主密钥。结合手机底层安全区（Keychain / Keystore）+ 本地生物识别（Face ID / Touch ID）保护。数据库级密文存储基于 `SQLCipher`，关键字段运用 `AES-256-GCM` 额外套壳。
3. **离线与本地优先**：所有数据存放于设备本地独立运行。
4. **智能追踪提示**：本地调度系统级别定时/过期推送预警。
5. **导出与同步**：剪贴板导出；**E2EE `.enc` 快照** — 移动端/桌面 **WebDAV**；Web 端 **Google Drive** + **本地文件**（Chromium 文件句柄或下载降级）。
6. **国际化**：中 / 英界面。

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
   git clone https://github.com/Jungley8/octarq-vault.git
   cd octarq-vault
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

4. **（可选）pre-commit 钩子**  
   pre-commit 时：`dart format`、`build_runner`、`flutter analyze`；pre-push 时：`flutter test`。  
   ```bash
   pip install pre-commit
   pre-commit install && pre-commit install --hook-type pre-push
   ```

5. **运行 iOS / Android 开发版本**:
   ```bash
   # 测试 iOS
   flutter run -d ios

   # 测试 Android
   flutter run -d android
   ```

### 持续集成 (CI/CD)
每次 PR/Push（`.github/workflows/ci.yml`）：代码格式、`flutter analyze`、`flutter test`、**`flutter build web`**（冒烟构建）。

**发版**：打 tag 触发 Release，可选 Cloudflare Pages 部署，见 [docs/web-deploy.md](docs/web-deploy.md)。

### 构建发行版本 (Build Release)

如果你需要打包独立可执行文件用于分发，可以使用以下命令：

**构建 macOS 桌面版:**
```bash
flutter build macos
```
*构建产物输出于: `build/macos/Build/Products/Release/asset-vault.app`*

**构建 Web 静态版本:**
```bash
flutter build web
```
*构建产物输出于: `build/web/`，该目录下的文件可直接部署至任何静态服务器（如 Vercel, NGINX 等）*

## 📄 协议许可
MIT License. All rights reserved.

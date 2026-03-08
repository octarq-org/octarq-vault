# AssetVault

**一站式个人数字资产管理 App**

AssetVault 是一款专为技术从业者打造的数字资产管理工具。它集成了资产全生命周期管理、到期提醒、安全存储以及资产依赖关系建模等核心功能。

## 核心价值

- **统一入口**：管理域名、VPS、API Key、订阅服务、SSL 证书等。
- **本地优先**：数据存储在本地，不强依赖云端。
- **端到端加密**：采用 AES-256-GCM、Argon2id 等业界领先的安全架构。
- **到期提醒**：基于本地推送的智能到期提醒。

## 技术栈

- **框架**：Flutter (iOS / Android / macOS / Windows)
- **数据库**：SQLCipher (加密 SQLite)
- **安全**：Argon2id, AES-256-GCM
- **开发工具**：Dart, Riverpod, Local Notifications

## 开发计划

- [ ] 初始化 Flutter 项目
- [ ] 核心数据模型 (Assets, Fields, Reminders)
- [ ] 安全加密层 (Argon2id + SQLCipher)
- [ ] 资产管理 CRUD
- [ ] 本地提醒系统
- [ ] 多端同步与备份

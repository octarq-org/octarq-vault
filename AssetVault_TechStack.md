# AssetVault · 技术方案推荐

> 本文档针对 PRD v1.0 提出推荐的技术选型，核心原则：**安全优先、本地优先、跨平台一致性**。

---

## 目录

1. [整体架构原则](#1-整体架构原则)
2. [客户端技术栈](#2-客户端技术栈)
3. [本地数据库与加密](#3-本地数据库与加密)
4. [安全与加密实现](#4-安全与加密实现)
5. [提醒系统](#5-提醒系统)
6. [同步方案](#6-同步方案)
7. [备份格式](#7-备份格式)
8. [可选后端服务](#8-可选后端服务云同步)
9. [开发工具链](#9-开发工具链)
10. [技术风险与应对](#10-技术风险与应对)

---

## 1. 整体架构原则

```
┌─────────────────────────────────────────────┐
│                  客户端                      │
│  UI 层 → 业务逻辑层 → 加密层 → 本地存储层   │
│                    ↕（可选）                 │
│              E2EE 同步层                     │
└─────────────────────────────────────────────┘
         ↕ 端到端加密，服务端零明文
┌─────────────────────────────────────────────┐
│            可选：自托管 / 官方云             │
│        （仅存密文，无法解密用户数据）        │
└─────────────────────────────────────────────┘
```

**三项核心约束：**

- 主密码和明文数据永不离开用户设备
- 服务端只接触密文，架构上无法解密
- 离线状态下所有功能完整可用

---

## 2. 客户端技术栈

### 推荐方案：Flutter

| 维度 | 说明 |
|------|------|
| 覆盖平台 | iOS / Android / macOS / Windows / Linux（一套代码） |
| 性能 | 原生渲染引擎（Skia/Impeller），非 WebView |
| 安全生态 | `flutter_secure_storage` 原生 Keychain/Keystore 封装成熟 |
| 包体积 | Release APK 约 15–20MB，满足 < 30MB 要求 |
| 社区 | Google 维护，生态活跃，密码管理器类 App 有成熟先例 |

**替代方案对比：**

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| Flutter | 跨平台一致、原生性能 | Dart 学习成本 | ✅ 推荐 |
| React Native | JS 生态熟悉 | 桥接性能损耗，安全库生态弱 | ⚠️ 备选 |
| Swift/Kotlin 各自原生 | 性能最优 | 两套代码，维护成本翻倍 | ❌ 不推荐（除非预算充足） |
| Electron（桌面） | 快速开发 | 包体积大（100MB+），安全边界模糊 | ❌ 不推荐用于核心 App |

---

## 3. 本地数据库与加密

### 推荐：SQLCipher（加密 SQLite）

```
┌──────────────┐
│  应用业务层  │
└──────┬───────┘
       │ SQL 查询（明文）
┌──────▼───────┐
│  SQLCipher   │  ← AES-256 透明加密层
└──────┬───────┘
       │ 写磁盘（全密文）
┌──────▼───────┐
│  .db 文件    │  ← 文件本身不可读
└──────────────┘
```

- **SQLCipher**：SQLite 的加密分支，AES-256-CBC 透明加密整个数据库文件
- Flutter 对应库：`sqflite_sqlcipher` 或直接用 `flutter_sqlcipher`
- 数据库密钥由 Argon2id 从主密码派生，存于系统 Keychain/Keystore

**字段级敏感数据额外加密（纵深防御）：**

密码、API Key、备份码等敏感字段在写入 SQLCipher 前再用 AES-256-GCM 单独加密，每条记录独立 IV，防止数据库密钥泄露后的批量读取。

### 数据模型实现建议

```sql
CREATE TABLE assets (
  id          TEXT PRIMARY KEY,
  type_id     TEXT NOT NULL,
  name        TEXT NOT NULL,           -- 明文（用于搜索）
  expire_at   INTEGER,                 -- Unix timestamp
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  is_archived INTEGER DEFAULT 0
);

CREATE TABLE asset_fields (
  id          TEXT PRIMARY KEY,
  asset_id    TEXT NOT NULL,
  key         TEXT NOT NULL,
  value_enc   BLOB NOT NULL,           -- AES-256-GCM 密文
  iv          BLOB NOT NULL,           -- 每字段独立 IV
  is_sensitive INTEGER DEFAULT 0,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

---

## 4. 安全与加密实现

### 4.1 密钥派生

```
主密码（用户输入）
    │
    ▼
Argon2id（time=3, memory=64MB, parallelism=4）
    │
    ├─→ 数据库主密钥（256-bit）→ SQLCipher
    └─→ 字段加密密钥（256-bit）→ 敏感字段 AES-GCM
```

**参数选择依据：**

- Argon2id 是 Password Hashing Competition（2015）冠军算法，抗 GPU/ASIC 暴力破解
- `memory=64MB` 在移动端可接受（解锁耗时约 0.5–1s），大幅提升暴力破解成本
- 派生结果只在内存中存活，App 锁定后立即清零

**推荐库：**

```yaml
# pubspec.yaml
argon2_flutter: ^0.3.0      # Argon2id
pointycastle: ^3.7.0        # AES-256-GCM
flutter_secure_storage: ^9.0.0  # Keychain/Keystore
```

### 4.2 生物识别解锁流程

```
首次设置：
  主密码 → Argon2id → 派生密钥
  派生密钥 → 用系统生物识别保护的 Keychain 条目存储

后续解锁：
  Face ID / 指纹 → 系统验证 → 释放 Keychain 条目 → 取出派生密钥
  （主密码不参与，但用户随时可回退到主密码）
```

### 4.3 内存安全

- 解密后的明文只在内存中按需存在，不持久化到磁盘（除 SQLCipher 本身）
- App 进入后台超过设定时间：清零内存中的密钥，UI 进入锁定态
- 使用 `SecureRandom` 而非 `Random` 生成所有 IV / Salt

---

## 5. 提醒系统

### 5.1 本地提醒（核心）

**推荐：系统原生本地通知**

```yaml
flutter_local_notifications: ^17.0.0
```

- iOS：`UNUserNotificationCenter`，支持精确定时触发
- Android：`AlarmManager`（精确闹钟，需 `SCHEDULE_EXACT_ALARM` 权限）
- 所有提醒在本地计算触发时间，不依赖网络

**提醒调度策略：**

```
App 启动 / 资产变更时：
  1. 查询未来 90 天内到期资产
  2. 根据提前天数配置计算触发时间
  3. 注册本地通知（替换旧通知）
  4. 同时写入 reminders 表作为持久记录
```

### 5.2 邮件 / Webhook 提醒

- 由可选的自托管后端服务处理（见第 8 节）
- 客户端定期将「待发送提醒」同步到后端，后端负责发送
- 后端存储的也是密文，提醒内容在客户端加密后上传

---

## 6. 同步方案

### 推荐：CRDT + 端到端加密

```
设备 A                    服务端（中继）              设备 B
  │                           │                         │
  │── 操作日志（密文）──────→│                         │
  │                           │──── 转发密文 ─────────→│
  │                           │     （无法解密）        │
  │                           │                         │
  │←─ 设备 B 的操作日志 ─────│←──── 上传密文 ──────────│
```

**选型：**

| 方案 | 说明 |
|------|------|
| **Automerge / Yjs（CRDT）** | 天然无冲突合并，适合离线-优先场景 |
| **自定义 Operation Log** | 实现简单，够用，适合 MVP |

MVP 阶段推荐用**自定义 Operation Log**：每次修改生成一条操作记录（op_id, asset_id, field, encrypted_value, timestamp），同步时按时间戳合并，冲突时提供手动解决界面。

### 同步服务端选型

| 方案 | 适用场景 |
|------|----------|
| **自托管 Rust/Go 服务** | 用户自部署，最大隐私 |
| **Cloudflare Workers + R2** | 低成本官方云，边缘计算 |
| **Supabase（仅存密文）** | 快速 MVP，实时订阅能力 |

---

## 7. 备份格式

### `.avault` 文件规范

```
┌─────────────────────────────┐
│  Magic Bytes: "AVLT"（4B）  │
├─────────────────────────────┤
│  版本号（2B）               │
├─────────────────────────────┤
│  KDF 参数（Argon2id 盐等）  │
├─────────────────────────────┤
│  加密头（AES-256-GCM）      │
│  └ 包含：创建时间、设备信息  │
├─────────────────────────────┤
│  加密体（AES-256-GCM）      │
│  └ JSON 数据（全量资产快照）│
└─────────────────────────────┘
```

- 使用主密码重新派生密钥加密（与数据库密钥相同流程，但使用新 Salt）
- 文件本身不含任何明文，即使备份文件泄露也无法直接读取
- 版本号确保向后兼容

---

## 8. 可选后端服务（云同步）

如决定提供官方云同步，推荐以下最简栈：

### 技术选型

| 层 | 推荐 | 原因 |
|----|------|------|
| 语言/框架 | **Go + Gin** 或 **Rust + Axum** | 高性能、低内存占用、强类型 |
| 数据库 | **PostgreSQL** | 稳定、JSON 支持好 |
| 对象存储 | **Cloudflare R2 / MinIO（自托管）** | 存备份文件 |
| 认证 | **JWT + Refresh Token**，无密码（邮箱魔法链接）| 服务端不需要知道主密码 |
| 部署 | **Docker Compose**（自托管）/ **Fly.io**（官方云）| 轻量、易运维 |

### API 设计原则

- 服务端 API 只接受和返回密文 Blob，不感知数据结构
- 不提供「找回密码」功能（服务端无密钥，无法解密）
- 账号注销时物理删除所有密文数据

---

## 9. 开发工具链

| 工具 | 用途 |
|------|------|
| Flutter 3.x | 跨平台客户端开发 |
| Dart | 客户端语言 |
| `flutter_test` + `mockito` | 单元测试 / Mock |
| `integration_test` | 集成测试 |
| GitHub Actions | CI/CD，自动化测试 + 构建 |
| Fastlane | iOS/Android 自动发布 |
| Sentry（仅崩溃日志，不含用户数据）| 线上错误监控 |
| melos | Monorepo 多包管理（客户端 + 后端） |

---

## 10. 技术风险与应对

| 风险 | 概率 | 影响 | 应对策略 |
|------|------|------|----------|
| 主密码遗忘导致数据永久丢失 | 中 | 极高 | 引导用户在首次设置时创建备份，明确告知无找回机制 |
| SQLCipher 版本升级破坏兼容性 | 低 | 高 | 固定版本 + 迁移脚本，备份前验证可读性 |
| iOS 后台本地通知被系统限制 | 中 | 中 | 同时支持 APNs 静默推送作为保底（需可选后端） |
| Android 厂商 ROM 杀后台导致通知丢失 | 高 | 中 | 引导用户加入白名单，文档说明，提供手动检查入口 |
| Argon2id 参数在低端设备耗时过长 | 中 | 低 | 在低端设备自动降级参数，并在 UI 中展示安全等级 |
| 自托管同步服务配置门槛高 | 中 | 低 | 提供 Docker Compose 一键部署 + 详细文档 |

---

## 附录：推荐依赖清单（Flutter）

```yaml
dependencies:
  # 数据库
  sqflite_sqlcipher: ^2.3.0

  # 加密
  pointycastle: ^3.7.0        # AES-256-GCM
  argon2_flutter: ^0.3.0      # 密钥派生

  # 安全存储
  flutter_secure_storage: ^9.0.0

  # 本地通知
  flutter_local_notifications: ^17.0.0

  # 生物识别
  local_auth: ^2.2.0

  # 网络（可选同步）
  dio: ^5.4.0

  # 状态管理
  riverpod: ^2.5.0            # 或 flutter_bloc

  # 路由
  go_router: ^13.0.0

  # 工具
  uuid: ^4.3.0
  freezed: ^2.4.0             # 不可变数据模型
  json_serializable: ^6.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

---

*技术方案 v1.0 · 与 PRD v1.0 对应*

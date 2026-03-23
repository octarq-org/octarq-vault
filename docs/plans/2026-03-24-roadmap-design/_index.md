# OctarqVault 后期 Roadmap 设计

**日期:** 2026-03-24
**范围:** 4 个方向 — 附件 UI + 云同步、密码修改、开源社区建设、iCloud Drive 主动同步

---

## Context

OctarqVault v1.4.0 已完成 AVV3 delta sync oplog、附件加密、WebDAV/Google Drive 同步等核心后端功能。但以下功能**后端完整、UI/集成缺失**，是当前最高优先级的完成工作：

| 功能 | 后端状态 | 缺失 |
|---|---|---|
| 附件 UI | ✅ AttachmentService、DB 表、加密全部就位 | 无任何 UI 入口 |
| 附件云同步 | ✅ uploadAttachment/downloadAttachment 已实现 | 从未被调用 |
| 密码修改 | ✅ setupMasterPassword() 逻辑可复用 | 无 Change Password 流程 |
| iCloud 主动同步 | ⚠️ 只是本地文件 + iCloud Backup | 无 iCloud Drive API 集成 |
| CONTRIBUTING.md | ❌ README 引用但文件不存在 | 整个文件 |

---

## Requirements

### R1 — 附件 UI + 云同步
- 用户可在 asset detail 页看到该资产的所有附件（文件名、大小）
- 用户可上传新附件（文件选择器），附件在保存前即时加密
- 用户可下载/删除附件
- Web 平台优雅降级（AttachmentServiceStub 抛异常，UI 隐藏附件区域）
- Push sync 后自动上传缺失的附件 blob 到 WebDAV/Google Drive
- Pull sync 后自动下载 attachmentManifest 中本地缺失的 blob

### R2 — 密码修改
- 用户可在 Settings 中修改 master password
- 需验证当前密码正确后才允许修改
- 新密码通过 Argon2id 派生新 key，执行 SQLCipher `PRAGMA rekey`
- 所有 `asset_fields.value_enc` 用新 key 重新加密
- 完成后更新 secure storage 的 salt/key/verify blob
- 失败时能回滚（不损坏 vault）

### R3 — 开源社区基础建设
- `CONTRIBUTING.md` 覆盖：环境搭建、PR 流程、代码规范、安全披露
- Issue 模板：Bug Report + Feature Request
- CI 新增 macOS 原生单元测试 job

### R4 — iCloud Drive 主动同步
- 使用 iCloud Drive ubiquity container（非 iCloud Backup）
- 真正实现跨设备实时同步
- 需要 iCloud 相关 entitlements 和 `icloud_storage` 包
- 与现有 WebDAV/Google Drive sync 架构保持一致

---

## Rationale（优先级决策）

- **R1/R2 优先**：这两个功能 backend 已完整，只缺 UI/编排，性价比最高，完成后产品完整度大幅提升
- **R3 中等**：开源项目必须有 CONTRIBUTING.md，且 CI 改进成本低。同时需要更新 `README.md` 中对 CONTRIBUTING.md 的引用（当前链接指向不存在的文件）
- **R4 较复杂**：需要 Apple Developer 账号操作 + entitlements 配置，不能纯代码完成，列为 P2

---

## Detailed Design

### D1 — 附件 UI + 云同步

#### 新增 Provider

**文件:** `lib/providers/attachments_provider.dart`（仿 `relation_providers.dart`）

```dart
final attachmentsProvider =
    FutureProvider.family<List<AssetAttachment>, String>((ref, assetId) async {
  if (kIsWeb) return [];
  final dbSvc = ref.read(databaseServiceProvider);
  if (!dbSvc.isOpen) await dbSvc.ensureOpen(ref.read(encryptionServiceProvider).masterKey);
  return dbSvc.getAttachmentsForAsset(assetId);
});
```

**`lib/providers/service_providers.dart`** 末尾补充：

```dart
final attachmentServiceProvider = Provider<AttachmentService>(
  (ref) => AttachmentService(ref.read(encryptionServiceProvider)),
);
```

#### UI 变更

**`asset_detail_screen.dart`** — 在 Linked Assets 块之后插入附件区（仿 relationsAsync.when 结构）：
- Section header `_SectionTitle('ATTACHMENTS')` + `IconButton(Icons.attach_file)` 触发 `FilePicker`
- `attachmentsProvider(assetId).when(data: ...)` 列出附件
- 每行：文件名 + 大小 + 下载 icon + 删除 icon
- Web 平台：`kIsWeb` 时隐藏整个附件区

**`asset_form_screen.dart`** — 编辑模式下添加附件列表 + 上传按钮（仅 non-web）

**依赖:** 需确认 `file_picker: ^8.x` 是否在 `pubspec.yaml` 中（当前 pubspec 未包含，需添加）

#### 同步编排

在 `AssetsNotifier._pushToBackend()` 末尾，push 成功后：

```dart
// 上传本地有但远端缺失的附件 blob
final allAttachments = await db.getAllAttachments();
for (final att in allAttachments) {
  if (!await backend.attachmentExists(att)) {
    final encBytes = await attachSvc.loadEncryptedBytes(att);
    await backend.uploadAttachment(att, encBytes);
  }
}
```

在 `AssetsNotifier._pullFromBackend()` 后，merge 完成后：

```dart
// 下载 manifest 中本地缺失的 blob
for (final att in mergedSnapshot.attachmentManifest) {
  if (!await attachSvc.attachmentExists(att)) {
    final bytes = await backend.downloadAttachment(att);
    if (bytes != null) await attachSvc.saveEncryptedBytes(att, bytes);
  }
}
```

---

### D2 — 密码修改

#### 操作序列（原子性设计）

```
Step 1: 验证当前密码（内存比对 verify blob）→ 失败立即中止，零副作用
Step 2: 派生新 key（内存）
Step 3: PRAGMA rekey → 不可逆点！DB 文件已重加密
Step 4: 用新 key 重新加密所有 asset_fields（DB 事务）
Step 5: 更新 secure storage（salt/key/verify blob）
Step 6: 更新 EncryptionService.masterKey 内存状态
```

**Step 3 失败后的回滚策略:** 在 Step 3 之前，先 `PRAGMA wal_checkpoint(TRUNCATE)` 刷新 WAL，然后复制 DB 文件到临时路径作为备份。若 Step 4/5 失败，用旧 DB 文件覆盖恢复。

#### 架构归属

新建 `lib/providers/change_password_notifier.dart`（独立 `Notifier`，不修改 `AuthNotifier`）。逻辑：
1. `verifyCurrentPassword(current)` → 解密 verify blob
2. `changePassword(current, newPwd)` → 执行全部 6 步
3. 暴露 `AsyncValue<void>` 状态供 UI 展示进度

#### UI

在 `SettingsScreen` 的 Security 区，现有生物识别 toggle 下方，新增 `ListTile` "Change Master Password"，跳转 `showModalBottomSheet` 或独立页面，含：
- 当前密码输入框
- 新密码 + 确认密码输入框
- 强度提示（复用 `setup_screen.dart` 已有的逻辑）

---

### D3 — 开源社区建设

需新建文件（不修改现有文件）：

- `CONTRIBUTING.md` — 章节：Prerequisites、Setup、Code Style（`dart format`）、Commit Convention（conventional commits）、PR Process、Security Disclosure（链接到 SECURITY.md）
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/ISSUE_TEMPLATE/config.yml` — 禁用空白 issue，强制使用模板

**CI 改进** (`.github/workflows/ci.yml`):

```yaml
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter test
```

---

### D4 — iCloud Drive 主动同步

**当前现状:** `icloud_sync_service_io.dart` 使用 `getApplicationDocumentsDirectory()` + `dart:io` File 操作写文件。这是 **iCloud Backup**（被动、隔夜）而非 **iCloud Drive 主动同步**。`Runner.entitlements` 仅有 Keychain group，无 iCloud container。

**所需变更:**

1. **Entitlements** — `ios/Runner/Runner.entitlements` 和 `macos/Runner/Release.entitlements` 添加：
   ```xml
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array><string>iCloud.org.octarq.vault</string></array>
   <key>com.apple.developer.icloud-services</key>
   <array><string>CloudDocuments</string></array>
   ```

2. **Apple Developer Portal** — 需在 Developer 后台开启 iCloud capability 并配置 container ID（纯代码无法完成）

3. **Flutter 依赖** — `icloud_storage: ^2.x`（pub.dev 活跃维护包，封装 `NSFileManager` ubiquity API）

4. **实现策略** — 替换 `_vaultFile()` 中的路径解析，改为通过 `ICloudStorage.putFile()` / `ICloudStorage.getFile()` 操作。冲突检测复用现有 LWW merge。

**注意:** 此功能需要 Apple 开发者账号操作，无法纯代码完成，建议单独作为一个 milestone 规划。

---

## Design Documents

- [BDD Specifications](./bdd-specs.md) — 所有功能的 Gherkin 场景和测试策略
- [Architecture](./architecture.md) — 系统架构和组件细节
- [Best Practices](./best-practices.md) — 安全性、性能和代码质量指南

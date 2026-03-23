# Best Practices & Considerations

## 安全性

### 附件加密
- 附件 blob 永远不以明文写入磁盘。`AttachmentService.saveAttachment()` 在 `File.writeAsBytes()` 之前调用 `EncryptionService.encryptBytes()`。
- 附件 IV 嵌入在密文头部（由 `encryptBytes()` 生成），无需单独存储。
- 传输到云端时上传的是 **已加密** 字节（`loadEncryptedBytes()`），云服务商看不到明文。
- Web 平台 stub 抛 `UnsupportedError`——UI 层必须在 `kIsWeb` 时隐藏附件入口，不依赖异常路径。

### 密码修改
- **在 PRAGMA rekey 之前** 必须完成 verify blob 校验——绝不在没有验证当前密码的情况下触碰 DB 文件。
- `PRAGMA rekey` 后到 secure storage 更新之间是最危险的窗口期。用 DB 文件备份做保险，不要依赖内存状态。
- 字段重加密必须在 **同一个 DB 事务** 中完成，避免部分成功。
- 密码修改后立即调用 `EncryptionService.wipeKey()` 然后重新设置，确保内存中不残留旧 key。
- 修改密码不应要求用户重新登录（vault 保持 unlocked 状态），但需更新 `EncryptionService.masterKey`。

### iCloud Drive
- iCloud Drive ubiquity container 内的文件仍然是 AVV3 加密格式，Apple 服务器看不到明文。
- 不要在 ubiquity container 中存储任何未加密的 metadata（文件名不含敏感信息，`octarq_vault.enc` 本身不泄露内容）。

## 性能

### 附件同步
- 附件 blob 上传/下载是 best-effort，独立 try/catch，不阻断主 vault sync。
- 大文件（>10MB）考虑分块上传或在 push 前检查文件大小，WebDAV 和 Google Drive 均有文件大小限制。
- `getAllAttachments()` 每次 push 都调用——如果附件数量大，考虑维护一个「未同步」标记字段（`is_synced INTEGER`）避免全量检查。

### 密码修改
- 字段重加密是 O(n) 操作（n = asset_fields 行数）。对于大型 vault（>1000 条字段），考虑在后台 isolate 中执行并展示进度条。
- `PRAGMA rekey` 是同步 SQLCipher 操作，在主线程执行会短暂阻塞 UI——使用 `Future()` 将其推到事件循环之外，或在 compute() 中执行。

## 代码质量

### 附件 Provider
- 仿照 `assetRelationsProvider` 的 `FutureProvider.family` 模式——保持 provider 层一致性。
- 删除附件后调用 `ref.invalidate(attachmentsProvider(assetId))` 刷新列表，与 relations 的 `ref.invalidate(assetRelationsProvider(...))` 模式一致。

### 密码修改 Notifier
- 独立 `AsyncNotifier`，不修改 `AuthNotifier`——保持 `AuthNotifier` 职责单一（auth lifecycle）。
- 暴露详细的中间步骤状态（`ChangePasswordStep` enum）供 UI 展示进度，避免用户以为卡住了。

### 开源文件
- `CONTRIBUTING.md` 中的 Setup 章节必须与 `CLAUDE.md` 的命令保持同步——这两个文件是重复的，可以考虑 `CONTRIBUTING.md` 引用 `CLAUDE.md` 中的命令。
- Issue 模板使用 `.yml` 格式（GitHub Forms），不用 `.md` 格式，体验更好。
- `bug_report.yml` 必须包含 Flutter/Dart 版本字段——这是 Flutter 项目排查问题的关键。

## 向后兼容性

### 附件
- `getAttachmentsForAsset()` 在 schema v4 中已存在。老版本 DB（v1-v3）升级后 `asset_attachments` 表为空，附件功能正常但无历史数据，无需特殊处理。
- `attachmentManifest` 在 `VaultSnapshot` 中默认为 `const []`（已实现），旧设备收到含附件的 snapshot 时不会崩溃。

### 密码修改
- 修改密码后生成的 vault snapshot（AVV3）使用新 salt，旧设备用旧密码将无法解密——这是预期行为，用户需要在所有设备上输入新密码。
- Verify blob 会随密码修改更新，旧 verify blob 被覆盖。

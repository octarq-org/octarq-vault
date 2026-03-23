# Architecture Details

## 附件 UI + 云同步

### 新文件和修改点

```
lib/
├── providers/
│   ├── attachments_provider.dart    ← NEW
│   └── service_providers.dart       ← MODIFY: 添加 attachmentServiceProvider
├── views/
│   ├── asset_detail_screen.dart     ← MODIFY: 新增 Attachments 区块
│   └── asset_form_screen.dart       ← MODIFY: 新增文件选择器（non-web only）
└── providers/
    └── assets_provider.dart         ← MODIFY: push/pull 后添加 blob 同步
```

### attachments_provider.dart（新文件）

仿照 `lib/providers/relation_providers.dart:37-55` 的 `FutureProvider.family` 模式：

```dart
final attachmentsProvider =
    FutureProvider.family<List<AssetAttachment>, String>((ref, assetId) async {
  if (kIsWeb) return [];
  final dbSvc = ref.read(databaseServiceProvider);
  if (!dbSvc.isOpen) await dbSvc.ensureOpen(ref.read(encryptionServiceProvider).masterKey);
  return dbSvc.getAttachmentsForAsset(assetId);
});
```

`DatabaseService.getAttachmentsForAsset(assetId)` 已存在（database_service.dart:482）。

### service_providers.dart 修改

在文件末尾添加（需先 import attachment_service.dart 的条件导出）：

```dart
final attachmentServiceProvider = Provider<AttachmentService>(
  (ref) => AttachmentService(ref.read(encryptionServiceProvider)),
);
```

### asset_detail_screen.dart 插入点

**行 ~379** — 在 Linked Assets 的 `relationsAsync.when(...)` 块结束后，`const SizedBox(height: 40)` 之前插入 Attachments 区块。

UI 结构（仿 Linked Assets 模式）：
```
Row { _SectionTitle('Attachments'), IconButton(attach_file → file picker) }
SizedBox(height: 10)
if (kIsWeb) → 隐藏
else → ref.watch(attachmentsProvider(assetId)).when(
  loading: → CircularProgressIndicator
  error: → 错误提示
  data: (attachments) →
    attachments.isEmpty → 空状态卡片（仿 noLinkedAssets 样式）
    else → _DetailCard(children: attachments.map(_AttachmentRow))
)
```

`_AttachmentRow` 需要展示：图标（按 MIME 类型）、文件名、大小字符串、下载 IconButton、删除 IconButton。

### 同步编排插入点

**lib/providers/assets_provider.dart** 中的 push 方法（行 ~320 左右），在快照上传成功后：

```dart
// 附件 blob 上传（best-effort，失败不阻断整体 sync）
if (!kIsWeb) {
  final attachSvc = ref.read(attachmentServiceProvider);
  final allAtts = await db.getAllAttachments();
  for (final att in allAtts) {
    try {
      final encBytes = await attachSvc.loadEncryptedBytes(att);
      await backend.uploadAttachment(att, encBytes);
    } catch (e) {
      debugPrint('Attachment upload skipped: ${att.encFileName} — $e');
    }
  }
}
```

Pull 完成、merge 后（行 ~380 左右）：

```dart
if (!kIsWeb) {
  final attachSvc = ref.read(attachmentServiceProvider);
  for (final att in mergedSnapshot.attachmentManifest) {
    if (!await attachSvc.attachmentExists(att)) {
      try {
        final bytes = await backend.downloadAttachment(att);
        if (bytes != null) await attachSvc.saveEncryptedBytes(att, bytes);
      } catch (e) {
        debugPrint('Attachment download skipped: ${att.encFileName} — $e');
      }
    }
  }
}
```

**Best-effort 语义:** 每个 blob 操作独立 try/catch，失败只 log，不影响主 sync 结果。这符合 OctarqVault offline-first 设计——blob 在下次 sync 时重试。

---

## 密码修改

### 新文件

**lib/providers/change_password_notifier.dart**

```dart
enum ChangePasswordStep { idle, verifying, rekeying, reencrypting, saving, done }

class ChangePasswordNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> changePassword(String current, String newPwd) async {
    state = const AsyncLoading();
    // Step 1: Verify current password
    // Step 2: Derive new key
    // Step 3: DB backup + PRAGMA rekey
    // Step 4: Re-encrypt all asset_fields (DB transaction)
    // Step 5: Update secure storage
    // Step 6: Update EncryptionService in memory
    ...
  }
}
```

### DatabaseService 新增方法

需要在 `database_service.dart` 中新增：

```dart
// Re-encrypts all asset_fields under a new key.
// Must be called while DB is open under the NEW key (after PRAGMA rekey).
Future<void> reEncryptAllFields(
  EncryptionService oldEnc,
  EncryptionService newEnc,
) async { ... }
```

### PRAGMA rekey 调用

SQLCipher 通过 raw SQL 执行（`sqflite_sqlcipher ^3.4.0` 支持）：

```dart
final newHexKey = _bytesToHex(newKey);
await db.rawQuery("PRAGMA rekey = '$newHexKey'");
```

**回滚设计:** 在执行 `PRAGMA rekey` 之前，将 DB 文件路径记录，在出错时使用 `dart:io` File 操作恢复备份。`PRAGMA rekey` 本身是 SQLCipher 的原子操作，但 Step 4（字段重加密）是应用层操作，需要事务保护。

### UI 插入点

**lib/views/settings_screen.dart** — Security 区块，现有 Auto-lock picker 之后，新增：

```dart
ListTile(
  leading: const Icon(Icons.lock_reset_outlined, color: kTextMuted),
  title: Text(l10n.changeMasterPassword),
  trailing: const Icon(Icons.chevron_right, color: kTextMuted),
  onTap: () => _showChangePasswordDialog(context),
)
```

---

## iCloud Drive 主动同步

### 必要前提（非代码）

1. Apple Developer Portal → Identifiers → `org.octarq.vault` → 启用 iCloud 能力
2. 创建 iCloud Container: `iCloud.org.octarq.vault`
3. 更新 iOS/macOS Provisioning Profile

### 代码变更

**pubspec.yaml** 新增依赖：
```yaml
icloud_storage: ^2.x.x  # https://pub.dev/packages/icloud_storage
```

**ios/Runner/Runner.entitlements** 新增：
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array><string>iCloud.org.octarq.vault</string></array>
<key>com.apple.developer.icloud-services</key>
<array><string>CloudDocuments</string></array>
```

**macos/Runner/Release.entitlements** 同上。

**lib/services/icloud_sync_service_io.dart** 重写：
- 将 `_vaultFile()` 从 `getApplicationDocumentsDirectory()` 改为通过 `icloud_storage` 包解析 ubiquity container URL
- `backup()` → `ICloudStorage.upload()`
- `restore()` → `ICloudStorage.download()`

### 与现有架构的对接

iCloud Drive sync 使用与 WebDAV/Google Drive 相同的 `VaultSnapshot` + LWW merge 机制。`AssetsNotifier` 中的 `syncSettings.contains(SyncMethod.iCloud)` 已有分支，只需替换底层实现。

---

## CI 改进

**`.github/workflows/ci.yml`** 新增并行 job：

```yaml
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter test
```

这样能捕获 `sqflite_sqlcipher`、`local_auth`、`flutter_secure_storage` 在 macOS 平台上的潜在问题。

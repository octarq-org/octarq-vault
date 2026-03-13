// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'OctarqVault';

  @override
  String get settings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get language => '语言';

  @override
  String get localeSystem => '跟随系统';

  @override
  String get localeZh => '中文';

  @override
  String get localeEn => 'English';

  @override
  String get security => '安全';

  @override
  String get lockVault => '锁定保险库';

  @override
  String get biometricUnlock => '生物识别解锁';

  @override
  String get biometricUnlockSubtitle => '使用面容 ID / 指纹解锁';

  @override
  String get autoLockTimeout => '自动锁定超时';

  @override
  String lockAfterMinutes(int minutes) {
    return '后台 $minutes 分钟后自动锁定';
  }

  @override
  String get oneMinute => '1 分钟';

  @override
  String minutesPlural(int count) {
    return '$count 分钟';
  }

  @override
  String get expiration => '到期';

  @override
  String get sync => '同步';

  @override
  String get syncMethod => '同步方式';

  @override
  String get syncMethodNone => '无';

  @override
  String get syncMethodWebdav => 'WebDAV';

  @override
  String get syncMethodGoogleDrive => 'Google 云端硬盘';

  @override
  String get syncMethodLocalFile => '本地文件（浏览器）';

  @override
  String get webdavDriveLocalFile => 'WebDAV / 云端硬盘 / 本地文件';

  @override
  String get configureCredentialsAndLinkFiles => '配置凭据与关联文件';

  @override
  String get exportSyncSettings => '导出同步设置';

  @override
  String get exportSyncSettingsSubtitle => '将同步方式复制到剪贴板 (JSON)';

  @override
  String get importSyncSettings => '导入同步设置';

  @override
  String get importSyncSettingsSubtitle => '从剪贴板粘贴 JSON';

  @override
  String get dataManagement => '数据管理';

  @override
  String get manageCustomAssetTypes => '管理自定义资产类型';

  @override
  String get manageCustomAssetTypesSubtitle => '创建自定义资产模板';

  @override
  String get manageTags => '管理标签';

  @override
  String get manageTagsSubtitle => '查看并整理所有标签';

  @override
  String get importExport => '导入 / 导出';

  @override
  String get exportEncFile => '导出 .enc 文件';

  @override
  String get exportEncFileSubtitle => '加密备份（全平台）';

  @override
  String get importEncFile => '导入 .enc 文件';

  @override
  String get importEncFileSubtitle => '用备份替换保险库（需输入密码）';

  @override
  String get exportJsonToClipboard => '导出 JSON 到剪贴板';

  @override
  String get importJsonFromClipboard => '从剪贴板导入 JSON';

  @override
  String get about => '关于';

  @override
  String get website => '网站';

  @override
  String get websiteUrl => 'vault.octarq.org';

  @override
  String get helpAndDocs => '帮助与文档';

  @override
  String get docsUrl => 'vault.octarq.org/docs';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get remove => '移除';

  @override
  String get add => '添加';

  @override
  String get create => '创建';

  @override
  String get unlock => '解锁';

  @override
  String get connect => '连接';

  @override
  String get link => '链接';

  @override
  String get copy => '复制';

  @override
  String get archive => '归档';

  @override
  String get unarchive => '取消归档';

  @override
  String get masterPassword => '主密码';

  @override
  String get pleaseEnterMasterPassword => '请输入主密码';

  @override
  String get incorrectPassword => '密码错误';

  @override
  String get vaultLocked => '保险库已锁定';

  @override
  String get enterMasterPasswordToUnlock => '输入主密码以解锁。';

  @override
  String get useBiometrics => '使用生物识别';

  @override
  String get searchHint => '搜索资产、标签或字段…';

  @override
  String get newAsset => '新建资产';

  @override
  String get dashboard => '仪表盘';

  @override
  String get allAssets => '全部资产';

  @override
  String get categories => '分类';

  @override
  String get notifications => '通知';

  @override
  String get noUpcomingExpirations => '暂无即将到期项';

  @override
  String expiresOnDays(String date, int days) {
    return '$date 到期（剩余 $days 天）';
  }

  @override
  String get totalAssets => '资产总数';

  @override
  String get expiringWithin30Days => '30 天内到期';

  @override
  String get estMonthlyCost => '预估月费用';

  @override
  String get actionRequired => '需要处理';

  @override
  String get viewAll => '查看全部 →';

  @override
  String get recentlyAdded => '最近添加';

  @override
  String get expiringSoon => '即将到期';

  @override
  String get noAssetsYet => '暂无资产';

  @override
  String get addFirstAssetHint => '添加第一个数字资产以开始使用。';

  @override
  String get addAsset => '添加资产';

  @override
  String get asset => '资产';

  @override
  String get assetNotFound => '未找到该资产';

  @override
  String get assetType => '资产类型';

  @override
  String get assetName => '资产名称';

  @override
  String get details => '详情';

  @override
  String get fields => '字段';

  @override
  String get type => '类型';

  @override
  String get expirationDate => '到期日';

  @override
  String get added => '添加时间';

  @override
  String get editAsset => '编辑资产';

  @override
  String get duplicateAsset => '复制资产';

  @override
  String get deleteAsset => '删除资产';

  @override
  String get deleteAssetConfirmation => '确定要永久删除该资产吗？';

  @override
  String get hideSecrets => '隐藏敏感信息';

  @override
  String get revealSecrets => '显示敏感信息';

  @override
  String get errorDecrypting => '解密失败';

  @override
  String fieldCopied(String label) {
    return '已复制 $label';
  }

  @override
  String get noLinkedAssets => '无关联资产。';

  @override
  String get removeLinkConfirm => '移除链接？';

  @override
  String errorLoadingRelations(String error) {
    return '加载关系失败：$error';
  }

  @override
  String get linkAsset => '关联资产';

  @override
  String get targetAsset => '目标资产';

  @override
  String get relationType => '关系类型';

  @override
  String get relationHostedOn => '托管于';

  @override
  String get relationDependsOn => '依赖于';

  @override
  String get relationUses => '使用';

  @override
  String get relationManagedBy => '由…管理';

  @override
  String get relationRelatedTo => '相关';

  @override
  String get relationLinkedAccount => '关联账户';

  @override
  String get addReminder => '添加提醒';

  @override
  String get triggerType => '触发类型';

  @override
  String get beforeExpiration => '到期前';

  @override
  String get recurring => '重复';

  @override
  String get daysBefore => '提前天数';

  @override
  String daysCount(int count) {
    return '$count 天';
  }

  @override
  String get pleaseSelectType => '请选择类型';

  @override
  String get required => '必填';

  @override
  String get addTagHint => '添加标签…';

  @override
  String get noneTapToSet => '未设置，点击以设置';

  @override
  String get clearDate => '清除日期';

  @override
  String get reminders => '提醒';

  @override
  String get addReminderTooltip => '添加提醒';

  @override
  String get defaultReminderBeforeExpiry => '默认：到期前 7 天';

  @override
  String get setExpirationToEnableReminders => '设置到期日后可添加提醒';

  @override
  String get linkedAssets => '关联资产';

  @override
  String get addLink => '添加链接';

  @override
  String get noLinksAddAfterSave => '暂无链接。保存后可添加链接。';

  @override
  String get noOtherAssetsToLink => '没有其他可关联的资产。';

  @override
  String get linkToAsset => '关联到资产';

  @override
  String get noAssetsToLinkSaveFirst => '暂无资产可关联。请先保存本资产，再在详情页添加链接。';

  @override
  String get basicInfo => '基本信息';

  @override
  String get tags => '标签';

  @override
  String saveAssetFailed(String error) {
    return '保存资产失败：$error';
  }

  @override
  String errorGeneric(String error) {
    return '错误：$error';
  }

  @override
  String get manageAssetTypes => '管理资产类型';

  @override
  String get deleteCustomType => '删除自定义类型';

  @override
  String get deleteCustomTypeConfirmation => '确定删除？该类型的现有资产可能丢失模板映射。';

  @override
  String get newAssetType => '新建资产类型';

  @override
  String get assetTypeNameHint => '资产类型名称（如：加密货币钱包）';

  @override
  String get icon => '图标';

  @override
  String get fieldsConfiguration => '字段配置';

  @override
  String get addField => '添加字段';

  @override
  String get fieldLabelHint => '字段标签（如：私钥）';

  @override
  String get dataType => '数据类型';

  @override
  String get aesEncrypted => 'AES-256-GCM 加密';

  @override
  String get aesEncryptedSubtitle => '如密码、密钥等字段';

  @override
  String get requiredInput => '必填';

  @override
  String get newTag => '新标签';

  @override
  String get tagName => '标签名称';

  @override
  String get color => '颜色';

  @override
  String get deleteTag => '删除标签';

  @override
  String deleteTagConfirmation(String name) {
    return '从所有资产中移除「$name」？';
  }

  @override
  String get addTag => '添加标签';

  @override
  String get noTagsYet => '暂无标签';

  @override
  String get tagsCreatedWhenAdded => '将标签添加到资产时会自动创建。';

  @override
  String assetCount(int count) {
    return '$count 个资产';
  }

  @override
  String get expiringIn30Days => '30 天内到期';

  @override
  String get expired => '已到期';

  @override
  String get noMatchesFound => '未找到匹配项。';

  @override
  String selectedCount(int count) {
    return '已选 $count 项';
  }

  @override
  String itemsCount(int count) {
    return '$count 项';
  }

  @override
  String get hideArchived => '隐藏已归档';

  @override
  String get showArchived => '显示已归档';

  @override
  String get filterAll => '全部';

  @override
  String get filterExpiring30d => '30 天内到期';

  @override
  String get filterExpired => '已到期';

  @override
  String get sortByAdded => '按添加时间';

  @override
  String get sortByName => '按名称';

  @override
  String get sortByExpiry => '按到期日';

  @override
  String get archived => '已归档';

  @override
  String get exportedJsonCopiedToClipboard => '已导出 JSON 到剪贴板！';

  @override
  String get clipboardUnavailableWeb => '剪贴板不可用（浏览器可能需 HTTPS）。请尝试保存到文件。';

  @override
  String get clipboardUnavailable => '无法复制到剪贴板，请重试。';

  @override
  String get syncSettingsCopiedToClipboard => '同步设置已复制到剪贴板';

  @override
  String get syncSettingsApplied => '同步设置已应用';

  @override
  String get unlockBackup => '解锁备份';

  @override
  String get wrongPassword => '密码错误';

  @override
  String importedEncCount(int count) {
    return '已从 .enc 文件导入 $count 个资产';
  }

  @override
  String get clipboardEmpty => '剪贴板为空。';

  @override
  String invalidSyncSettingsJson(String error) {
    return '同步设置 JSON 无效：$error';
  }

  @override
  String cannotOpenUrl(String url) {
    return '无法打开：$url';
  }

  @override
  String get validationNoAssetsInJson => 'JSON 中无资产。';

  @override
  String importSuccessCount(int count) {
    return '已成功导入 $count 个资产！';
  }

  @override
  String importInvalid(String error) {
    return '导入无效：$error';
  }

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get invalidJsonOrFormat => 'JSON 或格式无效。';

  @override
  String get webdavBackup => 'WebDAV 备份';

  @override
  String get webdavConnected => '已连接 WebDAV';

  @override
  String get webdavConnectedSuccess => '已成功连接 WebDAV！';

  @override
  String webdavConnectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String get e2eeBackupSuccess => 'E2EE 备份成功！';

  @override
  String backupFailed(String error) {
    return '备份失败：$error';
  }

  @override
  String restoredAssetsE2ee(int count) {
    return '已恢复 $count 个资产 (E2EE)';
  }

  @override
  String restoreFailed(String error) {
    return '恢复失败：$error';
  }

  @override
  String get backupToWebdav => '备份到 WebDAV';

  @override
  String get restoreFromWebdav => '从 WebDAV 恢复';

  @override
  String get disconnectClearCredentials => '断开并清除凭据';

  @override
  String get webdavConfigureDescription =>
      '配置 WebDAV 服务器（如 Nextcloud、ownCloud、坚果云）以安全备份加密数据。';

  @override
  String get serverUrl => '服务器 URL';

  @override
  String get serverUrlHint => 'https://example.com/remote.php/webdav/';

  @override
  String get username => '用户名';

  @override
  String get passwordOrAppToken => '密码 / 应用令牌';

  @override
  String get e2eeWebSync => 'E2EE 网页同步';

  @override
  String get localDiskSyncE2ee => '本地磁盘同步（E2EE 加密）';

  @override
  String get localDiskSyncDescription => '在本地维护加密保险库文件，桌面端每次变更后会静默更新。';

  @override
  String get createNewEncryptedVaultFile => '创建新的加密保险库文件';

  @override
  String get linkExistingVaultFile => '链接已有保险库文件';

  @override
  String get importFallback => '导入备用';

  @override
  String get exportFallback => '导出备用';

  @override
  String get googleDriveSyncE2ee => 'Google 云端硬盘同步（E2EE 加密）';

  @override
  String get googleDriveSyncDescription => '自动同步到 Google 云端硬盘的隐藏应用数据文件夹，完全零知识。';

  @override
  String get authorizeSyncGoogleDrive => '授权并同步到 Google 云端硬盘';

  @override
  String get pullFromGoogleDrive => '从 Google 云端硬盘拉取（覆盖本地）';

  @override
  String restoredAssetsFromFile(int count) {
    return '已从文件恢复 $count 个资产';
  }

  @override
  String get browserNoFilePickUseFallback => '当前浏览器不支持直接选择文件，请使用下方导入/导出备用按钮。';

  @override
  String get pushedToGoogleDriveSuccess => '已安全推送到 Google 云端硬盘';

  @override
  String driveError(String error) {
    return '云端硬盘错误：$error';
  }

  @override
  String restoredAssetsFromDrive(int count) {
    return '已从云端硬盘恢复 $count 个资产';
  }

  @override
  String get noBackupFoundOnDrive => '云端硬盘上未找到备份。';

  @override
  String importError(String error) {
    return '导入错误：$error';
  }

  @override
  String get welcomeToOctarqVault => '欢迎使用 OctarqVault';

  @override
  String get setMasterPassword => '设置主密码';

  @override
  String get setupPasswordDescription => '此密码用于本地加密全部数据。忘记后无法恢复数据。';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get createVault => '创建保险库';

  @override
  String get orRestoreExistingVault => '或恢复已有保险库';

  @override
  String get restoreFromGoogleDrive => '从 Google 云端硬盘恢复';

  @override
  String get restoreFromLocalFile => '从本地文件恢复';

  @override
  String get passwordTooShort => '密码过短（至少 8 个字符）';

  @override
  String get passwordsDoNotMatch => '两次密码不一致';

  @override
  String createVaultFailed(String error) {
    return '创建保险库失败：$error';
  }

  @override
  String get unknownError => '未知错误';

  @override
  String get vaultFound => '发现保险库';

  @override
  String get vaultRestoredSuccess => '保险库已恢复！';

  @override
  String unlockFailed(String error) {
    return '解锁失败：$error';
  }

  @override
  String fallbackError(String error) {
    return '备用错误：$error';
  }

  @override
  String get notificationAssetExpiringTitle => '资产即将到期';

  @override
  String notificationAssetExpiringBody(String name, int days) {
    return '$name 将在 $days 天后到期。';
  }

  @override
  String get notificationChannelName => '资产到期';

  @override
  String get notificationChannelDescription => '即将到期资产的通知';
}

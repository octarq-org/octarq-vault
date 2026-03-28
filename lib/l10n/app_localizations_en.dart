// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OctarqVault';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get localeSystem => 'System';

  @override
  String get localeZh => '中文';

  @override
  String get localeEn => 'English';

  @override
  String get localeEs => 'Español';

  @override
  String get security => 'Security';

  @override
  String get lockVault => 'Lock Vault';

  @override
  String get changeMasterPassword => 'Change Master Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get changePasswordAction => 'Change Password';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get passwordTooWeak => 'Too weak';

  @override
  String get attachmentAdded => 'Attachment added';

  @override
  String get attachmentsTitle => 'Attachments';

  @override
  String get attachAction => 'Attach';

  @override
  String get attachmentPreview => 'Open / preview';

  @override
  String get biometricUnlock => 'Biometric Unlock';

  @override
  String get biometricUnlockSubtitle => 'Use Face ID / fingerprint to unlock';

  @override
  String get autoLockTimeout => 'Auto-Lock Timeout';

  @override
  String lockAfterMinutes(int minutes) {
    return 'Lock after $minutes min in background';
  }

  @override
  String get oneMinute => '1 minute';

  @override
  String minutesPlural(int count) {
    return '$count minutes';
  }

  @override
  String get expiration => 'Expiration';

  @override
  String get sync => 'Sync';

  @override
  String get syncMethod => 'Sync method';

  @override
  String get syncMethodNone => 'None';

  @override
  String get syncMethodWebdav => 'WebDAV';

  @override
  String get syncMethodGoogleDrive => 'Google Drive';

  @override
  String get syncMethodLocalFile => 'Local file (browser)';

  @override
  String get webdavDriveLocalFile => 'WebDAV / Drive / Local file';

  @override
  String get configureCredentialsAndLinkFiles =>
      'Configure credentials and link files';

  @override
  String get configureSyncMethodNone => 'Select a sync method above first';

  @override
  String configureSyncMethod(String method) {
    return 'Configure $method';
  }

  @override
  String get exportSyncSettings => 'Export sync settings';

  @override
  String get exportSyncSettingsSubtitle =>
      'Copy sync method to clipboard (JSON)';

  @override
  String get importSyncSettings => 'Import sync settings';

  @override
  String get importSyncSettingsSubtitle => 'Paste JSON from clipboard';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get manageCustomAssetTypes => 'Manage Custom Asset Types';

  @override
  String get manageCustomAssetTypesSubtitle => 'Create custom asset templates';

  @override
  String get manageTags => 'Manage Tags';

  @override
  String get manageTagsSubtitle => 'View and organize all tags';

  @override
  String get importExport => 'Import / Export';

  @override
  String get exportEncFile => 'Export .enc file';

  @override
  String get exportEncFileSubtitle => 'Encrypted backup (all platforms)';

  @override
  String get importEncFile => 'Import .enc file';

  @override
  String get importEncFileSubtitle =>
      'Replace vault with backup (enter password)';

  @override
  String get exportJsonToClipboard => 'Export JSON to Clipboard';

  @override
  String get importJsonFromClipboard => 'Import JSON (from clipboard)';

  @override
  String get about => 'About';

  @override
  String get website => 'Website';

  @override
  String get websiteUrl => 'vault.octarq.org';

  @override
  String get helpAndDocs => 'Help & Docs';

  @override
  String get docsUrl => 'vault.octarq.org/docs';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String get create => 'Create';

  @override
  String get unlock => 'Unlock';

  @override
  String get connect => 'Connect';

  @override
  String get link => 'Link';

  @override
  String get copy => 'Copy';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get masterPassword => 'Master Password';

  @override
  String get pleaseEnterMasterPassword => 'Please enter your master password';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get vaultLocked => 'Vault Locked';

  @override
  String get enterMasterPasswordToUnlock =>
      'Enter your Master Password to unlock it.';

  @override
  String get useBiometrics => 'Use Biometrics';

  @override
  String get usePasskey => 'Use Passkey';

  @override
  String get passkeyUnlock => 'Passkey Unlock (Web)';

  @override
  String get passkeyUnlockSubtitle =>
      'Use a browser passkey for local vault unlock';

  @override
  String get passkeyEnabled => 'Passkey unlock enabled';

  @override
  String get passkeyDisabled => 'Passkey unlock disabled';

  @override
  String get passkeySetupFailed => 'Failed to enable passkey unlock';

  @override
  String get passkeyAuthFailed => 'Passkey authentication failed';

  @override
  String get searchHint => 'Search assets, tags, or fields...';

  @override
  String get newAsset => 'New Asset';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get allAssets => 'All Assets';

  @override
  String get categories => 'CATEGORIES';

  @override
  String get notifications => 'Notifications';

  @override
  String get noUpcomingExpirations => 'No upcoming expirations';

  @override
  String expiresOnDays(String date, int days) {
    return 'Expires $date ($days days)';
  }

  @override
  String get totalAssets => 'Total Assets';

  @override
  String get expiringWithin30Days => 'Expiring < 30 Days';

  @override
  String get estMonthlyCost => 'Est. Monthly Cost';

  @override
  String get actionRequired => 'ACTION REQUIRED';

  @override
  String get viewAll => 'View all →';

  @override
  String searchViewAllResults(int count) {
    return 'View all $count results';
  }

  @override
  String get recentlyAdded => 'RECENTLY ADDED';

  @override
  String get expiringSoon => 'Expiring soon';

  @override
  String get noAssetsYet => 'No assets yet';

  @override
  String get addFirstAssetHint =>
      'Add your first digital asset to get started.';

  @override
  String get addAsset => 'Add Asset';

  @override
  String get asset => 'Asset';

  @override
  String get assetNotFound => 'Asset not found';

  @override
  String get assetType => 'Asset Type';

  @override
  String get assetName => 'Asset Name';

  @override
  String get notes => 'Notes';

  @override
  String get details => 'Details';

  @override
  String get fields => 'Fields';

  @override
  String get type => 'Type';

  @override
  String get expirationDate => 'Expiration Date';

  @override
  String get added => 'Added';

  @override
  String get editAsset => 'Edit asset';

  @override
  String get duplicateAsset => 'Duplicate asset';

  @override
  String get deleteAsset => 'Delete Asset';

  @override
  String get deleteAssetConfirmation =>
      'Are you sure you want to permanently delete this asset?';

  @override
  String get hideSecrets => 'Hide secrets';

  @override
  String get revealSecrets => 'Reveal secrets';

  @override
  String get errorDecrypting => 'Error decrypting';

  @override
  String fieldCopied(String label) {
    return '$label copied';
  }

  @override
  String get noLinkedAssets => 'No linked assets.';

  @override
  String get removeLinkConfirm => 'Remove Link?';

  @override
  String errorLoadingRelations(String error) {
    return 'Error loading relations: $error';
  }

  @override
  String get linkAsset => 'Link Asset';

  @override
  String get targetAsset => 'Target Asset';

  @override
  String get relationType => 'Relation Type';

  @override
  String get relationHostedOn => 'Hosted On';

  @override
  String get relationDependsOn => 'Depends On';

  @override
  String get relationUses => 'Uses';

  @override
  String get relationManagedBy => 'Managed By';

  @override
  String get relationRelatedTo => 'Related To';

  @override
  String get relationLinkedAccount => 'Linked Account';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get triggerType => 'Trigger Type';

  @override
  String get beforeExpiration => 'Before Expiration';

  @override
  String get recurring => 'Recurring';

  @override
  String get daysBefore => 'Days Before';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get pleaseSelectType => 'Please select a type';

  @override
  String get required => 'Required';

  @override
  String get addTagHint => 'Add tag...';

  @override
  String get noneTapToSet => 'None — tap to set';

  @override
  String get clearDate => 'Clear date';

  @override
  String get reminders => 'Reminders';

  @override
  String get addReminderTooltip => 'Add reminder';

  @override
  String get defaultReminderBeforeExpiry => 'Default: 7 days before expiry';

  @override
  String get setExpirationToEnableReminders =>
      'Set expiration to enable reminders';

  @override
  String get linkedAssets => 'Linked Assets';

  @override
  String get addLink => 'Add Link';

  @override
  String get noLinksAddAfterSave => 'No links. Add links to create after save.';

  @override
  String get noOtherAssetsToLink => 'No other assets to link.';

  @override
  String get linkToAsset => 'Link to Asset';

  @override
  String get noAssetsToLinkSaveFirst =>
      'No assets to link. Save this asset first, then add links on its detail page.';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get tags => 'Tags';

  @override
  String saveAssetFailed(String error) {
    return 'Failed to save asset: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get manageAssetTypes => 'Manage Asset Types';

  @override
  String get deleteCustomType => 'Delete Custom Type';

  @override
  String get deleteCustomTypeConfirmation =>
      'Are you sure? Existing assets of this type might lose their template mappings.';

  @override
  String assetTypeDeleteInUse(int count) {
    return 'Cannot delete: this type is used by $count assets.';
  }

  @override
  String get newAssetType => 'New Asset Type';

  @override
  String get assetTypeNameHint => 'Asset Type Name (e.g., Crypto Wallet)';

  @override
  String get icon => 'Icon';

  @override
  String get fieldsConfiguration => 'Fields Configuration';

  @override
  String get addField => 'Add Field';

  @override
  String get fieldLabelHint => 'Field Label (e.g., Private Key)';

  @override
  String get dataType => 'Data Type';

  @override
  String get aesEncrypted => 'AES-256-GCM Encrypted';

  @override
  String get aesEncryptedSubtitle => 'Fields like passwords, keys';

  @override
  String get requiredInput => 'Required Input';

  @override
  String get newTag => 'New Tag';

  @override
  String get tagName => 'Tag Name';

  @override
  String get color => 'Color';

  @override
  String get deleteTag => 'Delete Tag';

  @override
  String deleteTagConfirmation(String name) {
    return 'Remove \"$name\" from all assets?';
  }

  @override
  String get addTag => 'Add tag';

  @override
  String get noTagsYet => 'No tags yet';

  @override
  String get tagsCreatedWhenAdded =>
      'Tags are created when you add them to assets.';

  @override
  String assetCount(int count) {
    return '$count assets';
  }

  @override
  String get expiringIn30Days => 'Expiring in 30 days';

  @override
  String get expired => 'Expired';

  @override
  String get noMatchesFound => 'No matches found.';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get hideArchived => 'Hide Archived';

  @override
  String get showArchived => 'Show Archived';

  @override
  String get filterAll => 'All';

  @override
  String get filterExpiring30d => 'Expiring in 30d';

  @override
  String get filterExpired => 'Expired';

  @override
  String get sortByAdded => 'Sort by: Added';

  @override
  String get sortByName => 'Sort by: Name';

  @override
  String get sortByExpiry => 'Sort by: Expiry';

  @override
  String get archived => 'Archived';

  @override
  String get exportedJsonCopiedToClipboard =>
      'Exported JSON copied to clipboard!';

  @override
  String get clipboardUnavailableWeb =>
      'Clipboard unavailable (browser may require HTTPS). Try saving to a file instead.';

  @override
  String get clipboardUnavailable =>
      'Could not copy to clipboard. Please try again.';

  @override
  String get syncSettingsCopiedToClipboard =>
      'Sync settings copied to clipboard';

  @override
  String get syncSettingsApplied => 'Sync settings applied';

  @override
  String get unlockBackup => 'Unlock backup';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String importedEncCount(int count) {
    return 'Imported $count assets from .enc file';
  }

  @override
  String get clipboardEmpty => 'Clipboard is empty.';

  @override
  String invalidSyncSettingsJson(String error) {
    return 'Invalid sync settings JSON: $error';
  }

  @override
  String cannotOpenUrl(String url) {
    return 'Cannot open: $url';
  }

  @override
  String get validationNoAssetsInJson => 'No assets in JSON.';

  @override
  String importSuccessCount(int count) {
    return 'Successfully imported $count assets!';
  }

  @override
  String importInvalid(String error) {
    return 'Import invalid: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get invalidJsonOrFormat => 'Invalid JSON or format.';

  @override
  String get webdavBackup => 'WebDAV Backup';

  @override
  String get webdavConnected => 'WebDAV Connected';

  @override
  String get webdavConnectedSuccess => 'Connected to WebDAV successfully!';

  @override
  String webdavConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get e2eeBackupSuccess => 'E2EE backup successful!';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String restoredAssetsE2ee(int count) {
    return 'Restored $count assets (E2EE)';
  }

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get backupToWebdav => 'Backup to WebDAV';

  @override
  String get restoreFromWebdav => 'Restore from WebDAV';

  @override
  String get restoreFromIcloud => 'Restore from iCloud';

  @override
  String get disconnectClearCredentials => 'Disconnect & Clear Credentials';

  @override
  String get webdavConfigureDescription =>
      'Configure your WebDAV server (e.g., Nextcloud, ownCloud, Nutstore) to securely backup your encrypted database payload.';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'https://example.com/remote.php/webdav/';

  @override
  String get username => 'Username';

  @override
  String get usernameOptional => 'Username (optional)';

  @override
  String get passwordOrAppToken => 'Password / App Token';

  @override
  String get passwordOrAppTokenOptional => 'Password / App Token (optional)';

  @override
  String get e2eeWebSync => 'E2EE Web Sync';

  @override
  String get localDiskSyncE2ee => 'Local Disk Sync (E2EE Encrypted)';

  @override
  String get localDiskSyncDescription =>
      'Maintain a local encrypted vault file. This file will be silently updated on your desktop after every change.';

  @override
  String get createNewEncryptedVaultFile => 'Create New Encrypted Vault File';

  @override
  String get linkExistingVaultFile => 'Link Existing Vault File';

  @override
  String get importFallback => 'Import Fallback';

  @override
  String get exportFallback => 'Export Fallback';

  @override
  String get googleDriveSyncE2ee => 'Google Drive Sync (E2EE Encrypted)';

  @override
  String get googleDriveSyncDescription =>
      'Sync automatically to a hidden appDataFolder in your Google Drive. Completely zero-knowledge.';

  @override
  String get authorizeSyncGoogleDrive => 'Authorize & Sync with Google Drive';

  @override
  String get pullFromGoogleDrive => 'Pull from Google Drive (Overwrite Local)';

  @override
  String restoredAssetsFromFile(int count) {
    return 'Restored $count assets from file';
  }

  @override
  String get browserNoFilePickUseFallback =>
      'Your browser does not support picking files directly. Please use the Import/Export fallback buttons below.';

  @override
  String get pushedToGoogleDriveSuccess =>
      'Successfully securely pushed to Google Drive';

  @override
  String driveError(String error) {
    return 'Drive Error: $error';
  }

  @override
  String restoredAssetsFromDrive(int count) {
    return 'Restored $count assets from Drive';
  }

  @override
  String get noBackupFoundOnDrive => 'No backup found on Drive.';

  @override
  String importError(String error) {
    return 'Import Error: $error';
  }

  @override
  String get welcomeToOctarqVault => 'Welcome to OctarqVault';

  @override
  String get setMasterPassword => 'Set your Master Password';

  @override
  String get setupPasswordDescription =>
      'This password encrypts all your data locally. If you forget it, the data cannot be recovered.';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get createVault => 'Create Vault';

  @override
  String get orRestoreExistingVault => 'Or restore an existing vault';

  @override
  String get restoreFromGoogleDrive => 'Restore from Google Drive';

  @override
  String get restoreFromLocalFile => 'Restore from Local File';

  @override
  String get passwordTooShort => 'Password too short (12 chars min)';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String createVaultFailed(String error) {
    return 'Failed to create vault: $error';
  }

  @override
  String get unknownError => 'Unknown error';

  @override
  String get vaultFound => 'Vault Found';

  @override
  String get vaultRestoredSuccess => 'Vault restored successfully!';

  @override
  String unlockFailed(String error) {
    return 'Unlock failed: $error';
  }

  @override
  String fallbackError(String error) {
    return 'Fallback Error: $error';
  }

  @override
  String get notificationAssetExpiringTitle => 'Asset Expiring Soon';

  @override
  String notificationAssetExpiringBody(String name, int days) {
    return '$name is expiring in $days days.';
  }

  @override
  String get notificationChannelName => 'Asset Expirations';

  @override
  String get notificationChannelDescription =>
      'Notifications for expiring assets';

  @override
  String get webSecurityTitle => 'Web Security Notice';

  @override
  String get webSecurityBody =>
      'On the web, encryption keys are stored in the browser\'s localStorage and IndexedDB — not in a hardware-backed secure enclave like iOS Keychain or Android Keystore. For higher security, use the native app on your phone or desktop.';

  @override
  String get webSecurityLearnMore => 'Learn more';

  @override
  String get webdavCorsWarning =>
      'CORS notice: Most WebDAV servers block direct browser requests. Use a server with CORS headers enabled (e.g., Nextcloud with correct settings), or use a desktop/mobile app for WebDAV sync.';

  @override
  String driveSmartMergeSuccess(int local, int remote) {
    return 'Merged $local local + $remote remote assets (LWW)';
  }

  @override
  String get icloudBackup => 'iCloud Backup';

  @override
  String get icloudBackupSubtitle =>
      'Sync encrypted vault to iCloud Drive (iOS only)';

  @override
  String get icloudBackupSuccess => 'iCloud backup successful!';

  @override
  String icloudRestoreSuccess(int count) {
    return 'Restored $count assets from iCloud';
  }

  @override
  String get icloudNotAvailable => 'iCloud is not available on this device.';

  @override
  String get exportJsonSecurityTitle => 'Export plaintext JSON?';

  @override
  String get exportJsonSecurityBody =>
      'The export is unencrypted: field values will be readable as plain text. Anyone or any app that can read your clipboard could see this data. Encrypted backups (.enc) stay protected — use those when possible.';

  @override
  String get exportJsonContinueExport => 'Copy to clipboard';

  @override
  String get syncStatusTitle => 'Sync';

  @override
  String get syncStatusNotConfigured => 'Not set up';

  @override
  String get syncStatusNever => 'No sync yet';

  @override
  String get syncConflictsScreenTitle => 'Sync conflicts';

  @override
  String get syncConflictsEmpty => 'No pending conflicts.';

  @override
  String get syncConflictSameTime =>
      'This asset was edited on two devices with the same timestamp. Choose which version to keep.';

  @override
  String get syncConflictVersionThisDevice => 'This device';

  @override
  String get syncConflictVersionRemote => 'Remote device';

  @override
  String get keepThisDevice => 'Keep this device';

  @override
  String get keepRemoteDevice => 'Keep remote';

  @override
  String get syncConflictsDetectedSnack => 'Sync conflicts need your choice.';

  @override
  String get openSyncConflictsAction => 'Resolve';

  @override
  String driveMergeConflictsSnack(int count) {
    return 'Merged with $count conflict(s) to resolve.';
  }

  @override
  String get webdavWebGuideTitle => 'Web / WebDAV limitations';

  @override
  String get webdavWebGuideBody =>
      'Browsers cannot store WebDAV passwords in a secure enclave, so OctarqVault disables direct WebDAV on web. Cross-origin WebDAV requests are usually blocked by CORS unless your server sends Access-Control-Allow-* headers or you put a same-origin reverse proxy in front of WebDAV (e.g. nginx) that forwards PROPFIND/GET/PUT. Recommended on web: Google Drive sync or linked local file.';

  @override
  String get webdavProxyBaseUrlLabel => 'Proxy base URL (reference)';

  @override
  String get webdavProxyBaseUrlHint => 'https://your-domain.com/webdav-proxy';

  @override
  String get webdavProxySaveNote =>
      'Saved on this browser only. A future version may route sync through this URL if you run a compatible proxy.';

  @override
  String get webdavProxySaved => 'Reference URL saved.';

  @override
  String get attachmentsWillBeUploadedAfterSave =>
      'Attachments will upload after saving this asset.';

  @override
  String get noneOption => 'None';

  @override
  String get unmatchedLegacyDataTitle => 'Unmatched legacy data';

  @override
  String get unmatchedLegacyDataBody =>
      'These values use field keys that are not in the current type. They are shown read-only so nothing is guessed into the wrong place. They stay on the asset when you save unless you move them into a field below.';

  @override
  String get migrateOrphanToField => 'Move to field';

  @override
  String get migrateOrphanApply => 'Move';

  @override
  String get migrateOrphanNoTargets =>
      'No compatible target field. Use Copy and paste into a field manually.';

  @override
  String orphanDataMovedToField(String fieldName) {
    return 'Moved into “$fieldName”. Save to persist.';
  }

  @override
  String fieldEditorUnavailable(String key) {
    return 'This field cannot be edited (missing editor). Key: $key';
  }
}

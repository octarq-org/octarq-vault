import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OctarqVault'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @localeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get localeSystem;

  /// No description provided for @localeZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get localeZh;

  /// No description provided for @localeEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeEn;

  /// No description provided for @localeEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get localeEs;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @lockVault.
  ///
  /// In en, this message translates to:
  /// **'Lock Vault'**
  String get lockVault;

  /// No description provided for @changeMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Change Master Password'**
  String get changeMasterPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @changePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordAction;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Too weak'**
  String get passwordTooWeak;

  /// No description provided for @attachmentAdded.
  ///
  /// In en, this message translates to:
  /// **'Attachment added'**
  String get attachmentAdded;

  /// No description provided for @attachmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsTitle;

  /// No description provided for @attachAction.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attachAction;

  /// No description provided for @attachmentPreview.
  ///
  /// In en, this message translates to:
  /// **'Open / preview'**
  String get attachmentPreview;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get biometricUnlock;

  /// No description provided for @biometricUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID / fingerprint to unlock'**
  String get biometricUnlockSubtitle;

  /// No description provided for @autoLockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock Timeout'**
  String get autoLockTimeout;

  /// No description provided for @lockAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Lock after {minutes} min in background'**
  String lockAfterMinutes(int minutes);

  /// No description provided for @oneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get oneMinute;

  /// No description provided for @minutesPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String minutesPlural(int count);

  /// No description provided for @expiration.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get expiration;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncMethod.
  ///
  /// In en, this message translates to:
  /// **'Sync method'**
  String get syncMethod;

  /// No description provided for @syncMethodNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get syncMethodNone;

  /// No description provided for @syncMethodWebdav.
  ///
  /// In en, this message translates to:
  /// **'WebDAV'**
  String get syncMethodWebdav;

  /// No description provided for @syncMethodGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get syncMethodGoogleDrive;

  /// No description provided for @syncMethodLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Local file (browser)'**
  String get syncMethodLocalFile;

  /// No description provided for @webdavDriveLocalFile.
  ///
  /// In en, this message translates to:
  /// **'WebDAV / Drive / Local file'**
  String get webdavDriveLocalFile;

  /// No description provided for @configureCredentialsAndLinkFiles.
  ///
  /// In en, this message translates to:
  /// **'Configure credentials and link files'**
  String get configureCredentialsAndLinkFiles;

  /// No description provided for @configureSyncMethodNone.
  ///
  /// In en, this message translates to:
  /// **'Select a sync method above first'**
  String get configureSyncMethodNone;

  /// No description provided for @configureSyncMethod.
  ///
  /// In en, this message translates to:
  /// **'Configure {method}'**
  String configureSyncMethod(String method);

  /// No description provided for @exportSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Export sync settings'**
  String get exportSyncSettings;

  /// No description provided for @exportSyncSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy sync method to clipboard (JSON)'**
  String get exportSyncSettingsSubtitle;

  /// No description provided for @importSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Import sync settings'**
  String get importSyncSettings;

  /// No description provided for @importSyncSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste JSON from clipboard'**
  String get importSyncSettingsSubtitle;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @manageCustomAssetTypes.
  ///
  /// In en, this message translates to:
  /// **'Manage Custom Asset Types'**
  String get manageCustomAssetTypes;

  /// No description provided for @manageCustomAssetTypesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create custom asset templates'**
  String get manageCustomAssetTypesSubtitle;

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage Tags'**
  String get manageTags;

  /// No description provided for @manageTagsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and organize all tags'**
  String get manageTagsSubtitle;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get importExport;

  /// No description provided for @exportEncFile.
  ///
  /// In en, this message translates to:
  /// **'Export .enc file'**
  String get exportEncFile;

  /// No description provided for @exportEncFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup (all platforms)'**
  String get exportEncFileSubtitle;

  /// No description provided for @importEncFile.
  ///
  /// In en, this message translates to:
  /// **'Import .enc file'**
  String get importEncFile;

  /// No description provided for @importEncFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace vault with backup (enter password)'**
  String get importEncFileSubtitle;

  /// No description provided for @exportJsonToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Export JSON to Clipboard'**
  String get exportJsonToClipboard;

  /// No description provided for @importJsonFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Import JSON (from clipboard)'**
  String get importJsonFromClipboard;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @websiteUrl.
  ///
  /// In en, this message translates to:
  /// **'vault.octarq.org'**
  String get websiteUrl;

  /// No description provided for @helpAndDocs.
  ///
  /// In en, this message translates to:
  /// **'Help & Docs'**
  String get helpAndDocs;

  /// No description provided for @docsUrl.
  ///
  /// In en, this message translates to:
  /// **'vault.octarq.org/docs'**
  String get docsUrl;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @masterPassword.
  ///
  /// In en, this message translates to:
  /// **'Master Password'**
  String get masterPassword;

  /// No description provided for @pleaseEnterMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your master password'**
  String get pleaseEnterMasterPassword;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @vaultLocked.
  ///
  /// In en, this message translates to:
  /// **'Vault Locked'**
  String get vaultLocked;

  /// No description provided for @enterMasterPasswordToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter your Master Password to unlock it.'**
  String get enterMasterPasswordToUnlock;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometrics;

  /// No description provided for @usePasskey.
  ///
  /// In en, this message translates to:
  /// **'Use Passkey'**
  String get usePasskey;

  /// No description provided for @passkeyUnlock.
  ///
  /// In en, this message translates to:
  /// **'Passkey Unlock (Web)'**
  String get passkeyUnlock;

  /// No description provided for @passkeyUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a browser passkey for local vault unlock'**
  String get passkeyUnlockSubtitle;

  /// No description provided for @passkeyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Passkey unlock enabled'**
  String get passkeyEnabled;

  /// No description provided for @passkeyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Passkey unlock disabled'**
  String get passkeyDisabled;

  /// No description provided for @passkeySetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable passkey unlock'**
  String get passkeySetupFailed;

  /// No description provided for @passkeyAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Passkey authentication failed'**
  String get passkeyAuthFailed;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search assets, tags, or fields...'**
  String get searchHint;

  /// No description provided for @newAsset.
  ///
  /// In en, this message translates to:
  /// **'New Asset'**
  String get newAsset;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @allAssets.
  ///
  /// In en, this message translates to:
  /// **'All Assets'**
  String get allAssets;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get categories;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noUpcomingExpirations.
  ///
  /// In en, this message translates to:
  /// **'No upcoming expirations'**
  String get noUpcomingExpirations;

  /// No description provided for @expiresOnDays.
  ///
  /// In en, this message translates to:
  /// **'Expires {date} ({days} days)'**
  String expiresOnDays(String date, int days);

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get totalAssets;

  /// No description provided for @expiringWithin30Days.
  ///
  /// In en, this message translates to:
  /// **'Expiring < 30 Days'**
  String get expiringWithin30Days;

  /// No description provided for @estMonthlyCost.
  ///
  /// In en, this message translates to:
  /// **'Est. Monthly Cost'**
  String get estMonthlyCost;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'ACTION REQUIRED'**
  String get actionRequired;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all →'**
  String get viewAll;

  /// No description provided for @searchViewAllResults.
  ///
  /// In en, this message translates to:
  /// **'View all {count} results'**
  String searchViewAllResults(int count);

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'RECENTLY ADDED'**
  String get recentlyAdded;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringSoon;

  /// No description provided for @noAssetsYet.
  ///
  /// In en, this message translates to:
  /// **'No assets yet'**
  String get noAssetsYet;

  /// No description provided for @addFirstAssetHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first digital asset to get started.'**
  String get addFirstAssetHint;

  /// No description provided for @addAsset.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAsset;

  /// No description provided for @asset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get asset;

  /// No description provided for @assetNotFound.
  ///
  /// In en, this message translates to:
  /// **'Asset not found'**
  String get assetNotFound;

  /// No description provided for @assetType.
  ///
  /// In en, this message translates to:
  /// **'Asset Type'**
  String get assetType;

  /// No description provided for @assetName.
  ///
  /// In en, this message translates to:
  /// **'Asset Name'**
  String get assetName;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @expirationDate.
  ///
  /// In en, this message translates to:
  /// **'Expiration Date'**
  String get expirationDate;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @editAsset.
  ///
  /// In en, this message translates to:
  /// **'Edit asset'**
  String get editAsset;

  /// No description provided for @duplicateAsset.
  ///
  /// In en, this message translates to:
  /// **'Duplicate asset'**
  String get duplicateAsset;

  /// No description provided for @deleteAsset.
  ///
  /// In en, this message translates to:
  /// **'Delete Asset'**
  String get deleteAsset;

  /// No description provided for @deleteAssetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this asset?'**
  String get deleteAssetConfirmation;

  /// No description provided for @hideSecrets.
  ///
  /// In en, this message translates to:
  /// **'Hide secrets'**
  String get hideSecrets;

  /// No description provided for @revealSecrets.
  ///
  /// In en, this message translates to:
  /// **'Reveal secrets'**
  String get revealSecrets;

  /// No description provided for @errorDecrypting.
  ///
  /// In en, this message translates to:
  /// **'Error decrypting'**
  String get errorDecrypting;

  /// No description provided for @fieldCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String fieldCopied(String label);

  /// No description provided for @noLinkedAssets.
  ///
  /// In en, this message translates to:
  /// **'No linked assets.'**
  String get noLinkedAssets;

  /// No description provided for @removeLinkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove Link?'**
  String get removeLinkConfirm;

  /// No description provided for @errorLoadingRelations.
  ///
  /// In en, this message translates to:
  /// **'Error loading relations: {error}'**
  String errorLoadingRelations(String error);

  /// No description provided for @linkAsset.
  ///
  /// In en, this message translates to:
  /// **'Link Asset'**
  String get linkAsset;

  /// No description provided for @targetAsset.
  ///
  /// In en, this message translates to:
  /// **'Target Asset'**
  String get targetAsset;

  /// No description provided for @relationType.
  ///
  /// In en, this message translates to:
  /// **'Relation Type'**
  String get relationType;

  /// No description provided for @relationHostedOn.
  ///
  /// In en, this message translates to:
  /// **'Hosted On'**
  String get relationHostedOn;

  /// No description provided for @relationDependsOn.
  ///
  /// In en, this message translates to:
  /// **'Depends On'**
  String get relationDependsOn;

  /// No description provided for @relationUses.
  ///
  /// In en, this message translates to:
  /// **'Uses'**
  String get relationUses;

  /// No description provided for @relationManagedBy.
  ///
  /// In en, this message translates to:
  /// **'Managed By'**
  String get relationManagedBy;

  /// No description provided for @relationRelatedTo.
  ///
  /// In en, this message translates to:
  /// **'Related To'**
  String get relationRelatedTo;

  /// No description provided for @relationLinkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Linked Account'**
  String get relationLinkedAccount;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @triggerType.
  ///
  /// In en, this message translates to:
  /// **'Trigger Type'**
  String get triggerType;

  /// No description provided for @beforeExpiration.
  ///
  /// In en, this message translates to:
  /// **'Before Expiration'**
  String get beforeExpiration;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'Days Before'**
  String get daysBefore;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// No description provided for @pleaseSelectType.
  ///
  /// In en, this message translates to:
  /// **'Please select a type'**
  String get pleaseSelectType;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @addTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add tag...'**
  String get addTagHint;

  /// No description provided for @noneTapToSet.
  ///
  /// In en, this message translates to:
  /// **'None — tap to set'**
  String get noneTapToSet;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @addReminderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminderTooltip;

  /// No description provided for @defaultReminderBeforeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Default: 7 days before expiry'**
  String get defaultReminderBeforeExpiry;

  /// No description provided for @setExpirationToEnableReminders.
  ///
  /// In en, this message translates to:
  /// **'Set expiration to enable reminders'**
  String get setExpirationToEnableReminders;

  /// No description provided for @linkedAssets.
  ///
  /// In en, this message translates to:
  /// **'Linked Assets'**
  String get linkedAssets;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// No description provided for @noLinksAddAfterSave.
  ///
  /// In en, this message translates to:
  /// **'No links. Add links to create after save.'**
  String get noLinksAddAfterSave;

  /// No description provided for @noOtherAssetsToLink.
  ///
  /// In en, this message translates to:
  /// **'No other assets to link.'**
  String get noOtherAssetsToLink;

  /// No description provided for @linkToAsset.
  ///
  /// In en, this message translates to:
  /// **'Link to Asset'**
  String get linkToAsset;

  /// No description provided for @noAssetsToLinkSaveFirst.
  ///
  /// In en, this message translates to:
  /// **'No assets to link. Save this asset first, then add links on its detail page.'**
  String get noAssetsToLinkSaveFirst;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @saveAssetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save asset: {error}'**
  String saveAssetFailed(String error);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @manageAssetTypes.
  ///
  /// In en, this message translates to:
  /// **'Manage Asset Types'**
  String get manageAssetTypes;

  /// No description provided for @deleteCustomType.
  ///
  /// In en, this message translates to:
  /// **'Delete Custom Type'**
  String get deleteCustomType;

  /// No description provided for @deleteCustomTypeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? Existing assets of this type might lose their template mappings.'**
  String get deleteCustomTypeConfirmation;

  /// No description provided for @newAssetType.
  ///
  /// In en, this message translates to:
  /// **'New Asset Type'**
  String get newAssetType;

  /// No description provided for @assetTypeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Asset Type Name (e.g., Crypto Wallet)'**
  String get assetTypeNameHint;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @fieldsConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Fields Configuration'**
  String get fieldsConfiguration;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get addField;

  /// No description provided for @fieldLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Field Label (e.g., Private Key)'**
  String get fieldLabelHint;

  /// No description provided for @dataType.
  ///
  /// In en, this message translates to:
  /// **'Data Type'**
  String get dataType;

  /// No description provided for @aesEncrypted.
  ///
  /// In en, this message translates to:
  /// **'AES-256-GCM Encrypted'**
  String get aesEncrypted;

  /// No description provided for @aesEncryptedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fields like passwords, keys'**
  String get aesEncryptedSubtitle;

  /// No description provided for @requiredInput.
  ///
  /// In en, this message translates to:
  /// **'Required Input'**
  String get requiredInput;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'New Tag'**
  String get newTag;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag Name'**
  String get tagName;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @deleteTag.
  ///
  /// In en, this message translates to:
  /// **'Delete Tag'**
  String get deleteTag;

  /// No description provided for @deleteTagConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from all assets?'**
  String deleteTagConfirmation(String name);

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @noTagsYet.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get noTagsYet;

  /// No description provided for @tagsCreatedWhenAdded.
  ///
  /// In en, this message translates to:
  /// **'Tags are created when you add them to assets.'**
  String get tagsCreatedWhenAdded;

  /// No description provided for @assetCount.
  ///
  /// In en, this message translates to:
  /// **'{count} assets'**
  String assetCount(int count);

  /// No description provided for @expiringIn30Days.
  ///
  /// In en, this message translates to:
  /// **'Expiring in 30 days'**
  String get expiringIn30Days;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found.'**
  String get noMatchesFound;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @hideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide Archived'**
  String get hideArchived;

  /// No description provided for @showArchived.
  ///
  /// In en, this message translates to:
  /// **'Show Archived'**
  String get showArchived;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterExpiring30d.
  ///
  /// In en, this message translates to:
  /// **'Expiring in 30d'**
  String get filterExpiring30d;

  /// No description provided for @filterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get filterExpired;

  /// No description provided for @sortByAdded.
  ///
  /// In en, this message translates to:
  /// **'Sort by: Added'**
  String get sortByAdded;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by: Name'**
  String get sortByName;

  /// No description provided for @sortByExpiry.
  ///
  /// In en, this message translates to:
  /// **'Sort by: Expiry'**
  String get sortByExpiry;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @exportedJsonCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Exported JSON copied to clipboard!'**
  String get exportedJsonCopiedToClipboard;

  /// No description provided for @clipboardUnavailableWeb.
  ///
  /// In en, this message translates to:
  /// **'Clipboard unavailable (browser may require HTTPS). Try saving to a file instead.'**
  String get clipboardUnavailableWeb;

  /// No description provided for @clipboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not copy to clipboard. Please try again.'**
  String get clipboardUnavailable;

  /// No description provided for @syncSettingsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Sync settings copied to clipboard'**
  String get syncSettingsCopiedToClipboard;

  /// No description provided for @syncSettingsApplied.
  ///
  /// In en, this message translates to:
  /// **'Sync settings applied'**
  String get syncSettingsApplied;

  /// No description provided for @unlockBackup.
  ///
  /// In en, this message translates to:
  /// **'Unlock backup'**
  String get unlockBackup;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @importedEncCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} assets from .enc file'**
  String importedEncCount(int count);

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty.'**
  String get clipboardEmpty;

  /// No description provided for @invalidSyncSettingsJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid sync settings JSON: {error}'**
  String invalidSyncSettingsJson(String error);

  /// No description provided for @cannotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Cannot open: {url}'**
  String cannotOpenUrl(String url);

  /// No description provided for @validationNoAssetsInJson.
  ///
  /// In en, this message translates to:
  /// **'No assets in JSON.'**
  String get validationNoAssetsInJson;

  /// No description provided for @importSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} assets!'**
  String importSuccessCount(int count);

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'Import invalid: {error}'**
  String importInvalid(String error);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @invalidJsonOrFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON or format.'**
  String get invalidJsonOrFormat;

  /// No description provided for @webdavBackup.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Backup'**
  String get webdavBackup;

  /// No description provided for @webdavConnected.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Connected'**
  String get webdavConnected;

  /// No description provided for @webdavConnectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected to WebDAV successfully!'**
  String get webdavConnectedSuccess;

  /// No description provided for @webdavConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String webdavConnectionFailed(String error);

  /// No description provided for @e2eeBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'E2EE backup successful!'**
  String get e2eeBackupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @restoredAssetsE2ee.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} assets (E2EE)'**
  String restoredAssetsE2ee(int count);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @backupToWebdav.
  ///
  /// In en, this message translates to:
  /// **'Backup to WebDAV'**
  String get backupToWebdav;

  /// No description provided for @restoreFromWebdav.
  ///
  /// In en, this message translates to:
  /// **'Restore from WebDAV'**
  String get restoreFromWebdav;

  /// No description provided for @restoreFromIcloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from iCloud'**
  String get restoreFromIcloud;

  /// No description provided for @disconnectClearCredentials.
  ///
  /// In en, this message translates to:
  /// **'Disconnect & Clear Credentials'**
  String get disconnectClearCredentials;

  /// No description provided for @webdavConfigureDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure your WebDAV server (e.g., Nextcloud, ownCloud, Nutstore) to securely backup your encrypted database payload.'**
  String get webdavConfigureDescription;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/remote.php/webdav/'**
  String get serverUrlHint;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get usernameOptional;

  /// No description provided for @passwordOrAppToken.
  ///
  /// In en, this message translates to:
  /// **'Password / App Token'**
  String get passwordOrAppToken;

  /// No description provided for @passwordOrAppTokenOptional.
  ///
  /// In en, this message translates to:
  /// **'Password / App Token (optional)'**
  String get passwordOrAppTokenOptional;

  /// No description provided for @e2eeWebSync.
  ///
  /// In en, this message translates to:
  /// **'E2EE Web Sync'**
  String get e2eeWebSync;

  /// No description provided for @localDiskSyncE2ee.
  ///
  /// In en, this message translates to:
  /// **'Local Disk Sync (E2EE Encrypted)'**
  String get localDiskSyncE2ee;

  /// No description provided for @localDiskSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Maintain a local encrypted vault file. This file will be silently updated on your desktop after every change.'**
  String get localDiskSyncDescription;

  /// No description provided for @createNewEncryptedVaultFile.
  ///
  /// In en, this message translates to:
  /// **'Create New Encrypted Vault File'**
  String get createNewEncryptedVaultFile;

  /// No description provided for @linkExistingVaultFile.
  ///
  /// In en, this message translates to:
  /// **'Link Existing Vault File'**
  String get linkExistingVaultFile;

  /// No description provided for @importFallback.
  ///
  /// In en, this message translates to:
  /// **'Import Fallback'**
  String get importFallback;

  /// No description provided for @exportFallback.
  ///
  /// In en, this message translates to:
  /// **'Export Fallback'**
  String get exportFallback;

  /// No description provided for @googleDriveSyncE2ee.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync (E2EE Encrypted)'**
  String get googleDriveSyncE2ee;

  /// No description provided for @googleDriveSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync automatically to a hidden appDataFolder in your Google Drive. Completely zero-knowledge.'**
  String get googleDriveSyncDescription;

  /// No description provided for @authorizeSyncGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Authorize & Sync with Google Drive'**
  String get authorizeSyncGoogleDrive;

  /// No description provided for @pullFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Pull from Google Drive (Overwrite Local)'**
  String get pullFromGoogleDrive;

  /// No description provided for @restoredAssetsFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} assets from file'**
  String restoredAssetsFromFile(int count);

  /// No description provided for @browserNoFilePickUseFallback.
  ///
  /// In en, this message translates to:
  /// **'Your browser does not support picking files directly. Please use the Import/Export fallback buttons below.'**
  String get browserNoFilePickUseFallback;

  /// No description provided for @pushedToGoogleDriveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully securely pushed to Google Drive'**
  String get pushedToGoogleDriveSuccess;

  /// No description provided for @driveError.
  ///
  /// In en, this message translates to:
  /// **'Drive Error: {error}'**
  String driveError(String error);

  /// No description provided for @restoredAssetsFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} assets from Drive'**
  String restoredAssetsFromDrive(int count);

  /// No description provided for @noBackupFoundOnDrive.
  ///
  /// In en, this message translates to:
  /// **'No backup found on Drive.'**
  String get noBackupFoundOnDrive;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import Error: {error}'**
  String importError(String error);

  /// No description provided for @welcomeToOctarqVault.
  ///
  /// In en, this message translates to:
  /// **'Welcome to OctarqVault'**
  String get welcomeToOctarqVault;

  /// No description provided for @setMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Set your Master Password'**
  String get setMasterPassword;

  /// No description provided for @setupPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'This password encrypts all your data locally. If you forget it, the data cannot be recovered.'**
  String get setupPasswordDescription;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @createVault.
  ///
  /// In en, this message translates to:
  /// **'Create Vault'**
  String get createVault;

  /// No description provided for @orRestoreExistingVault.
  ///
  /// In en, this message translates to:
  /// **'Or restore an existing vault'**
  String get orRestoreExistingVault;

  /// No description provided for @restoreFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive'**
  String get restoreFromGoogleDrive;

  /// No description provided for @restoreFromLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from Local File'**
  String get restoreFromLocalFile;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short (12 chars min)'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @createVaultFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create vault: {error}'**
  String createVaultFailed(String error);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @vaultFound.
  ///
  /// In en, this message translates to:
  /// **'Vault Found'**
  String get vaultFound;

  /// No description provided for @vaultRestoredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vault restored successfully!'**
  String get vaultRestoredSuccess;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Unlock failed: {error}'**
  String unlockFailed(String error);

  /// No description provided for @fallbackError.
  ///
  /// In en, this message translates to:
  /// **'Fallback Error: {error}'**
  String fallbackError(String error);

  /// No description provided for @notificationAssetExpiringTitle.
  ///
  /// In en, this message translates to:
  /// **'Asset Expiring Soon'**
  String get notificationAssetExpiringTitle;

  /// No description provided for @notificationAssetExpiringBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is expiring in {days} days.'**
  String notificationAssetExpiringBody(String name, int days);

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Asset Expirations'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for expiring assets'**
  String get notificationChannelDescription;

  /// No description provided for @webSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Web Security Notice'**
  String get webSecurityTitle;

  /// No description provided for @webSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'On the web, encryption keys are stored in the browser\'s localStorage and IndexedDB — not in a hardware-backed secure enclave like iOS Keychain or Android Keystore. For higher security, use the native app on your phone or desktop.'**
  String get webSecurityBody;

  /// No description provided for @webSecurityLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get webSecurityLearnMore;

  /// No description provided for @webdavCorsWarning.
  ///
  /// In en, this message translates to:
  /// **'CORS notice: Most WebDAV servers block direct browser requests. Use a server with CORS headers enabled (e.g., Nextcloud with correct settings), or use a desktop/mobile app for WebDAV sync.'**
  String get webdavCorsWarning;

  /// No description provided for @driveSmartMergeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Merged {local} local + {remote} remote assets (LWW)'**
  String driveSmartMergeSuccess(int local, int remote);

  /// No description provided for @icloudBackup.
  ///
  /// In en, this message translates to:
  /// **'iCloud Backup'**
  String get icloudBackup;

  /// No description provided for @icloudBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync encrypted vault to iCloud Drive (iOS only)'**
  String get icloudBackupSubtitle;

  /// No description provided for @icloudBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'iCloud backup successful!'**
  String get icloudBackupSuccess;

  /// No description provided for @icloudRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} assets from iCloud'**
  String icloudRestoreSuccess(int count);

  /// No description provided for @icloudNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'iCloud is not available on this device.'**
  String get icloudNotAvailable;

  /// No description provided for @exportJsonSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Export plaintext JSON?'**
  String get exportJsonSecurityTitle;

  /// No description provided for @exportJsonSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'The export is unencrypted: field values will be readable as plain text. Anyone or any app that can read your clipboard could see this data. Encrypted backups (.enc) stay protected — use those when possible.'**
  String get exportJsonSecurityBody;

  /// No description provided for @exportJsonContinueExport.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get exportJsonContinueExport;

  /// No description provided for @syncStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncStatusTitle;

  /// No description provided for @syncStatusNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get syncStatusNotConfigured;

  /// No description provided for @syncStatusNever.
  ///
  /// In en, this message translates to:
  /// **'No sync yet'**
  String get syncStatusNever;

  /// No description provided for @syncConflictsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync conflicts'**
  String get syncConflictsScreenTitle;

  /// No description provided for @syncConflictsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending conflicts.'**
  String get syncConflictsEmpty;

  /// No description provided for @syncConflictSameTime.
  ///
  /// In en, this message translates to:
  /// **'This asset was edited on two devices with the same timestamp. Choose which version to keep.'**
  String get syncConflictSameTime;

  /// No description provided for @syncConflictVersionThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get syncConflictVersionThisDevice;

  /// No description provided for @syncConflictVersionRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote device'**
  String get syncConflictVersionRemote;

  /// No description provided for @keepThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Keep this device'**
  String get keepThisDevice;

  /// No description provided for @keepRemoteDevice.
  ///
  /// In en, this message translates to:
  /// **'Keep remote'**
  String get keepRemoteDevice;

  /// No description provided for @syncConflictsDetectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Sync conflicts need your choice.'**
  String get syncConflictsDetectedSnack;

  /// No description provided for @openSyncConflictsAction.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get openSyncConflictsAction;

  /// No description provided for @driveMergeConflictsSnack.
  ///
  /// In en, this message translates to:
  /// **'Merged with {count} conflict(s) to resolve.'**
  String driveMergeConflictsSnack(int count);

  /// No description provided for @webdavWebGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Web / WebDAV limitations'**
  String get webdavWebGuideTitle;

  /// No description provided for @webdavWebGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Browsers cannot store WebDAV passwords in a secure enclave, so OctarqVault disables direct WebDAV on web. Cross-origin WebDAV requests are usually blocked by CORS unless your server sends Access-Control-Allow-* headers or you put a same-origin reverse proxy in front of WebDAV (e.g. nginx) that forwards PROPFIND/GET/PUT. Recommended on web: Google Drive sync or linked local file.'**
  String get webdavWebGuideBody;

  /// No description provided for @webdavProxyBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Proxy base URL (reference)'**
  String get webdavProxyBaseUrlLabel;

  /// No description provided for @webdavProxyBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://your-domain.com/webdav-proxy'**
  String get webdavProxyBaseUrlHint;

  /// No description provided for @webdavProxySaveNote.
  ///
  /// In en, this message translates to:
  /// **'Saved on this browser only. A future version may route sync through this URL if you run a compatible proxy.'**
  String get webdavProxySaveNote;

  /// No description provided for @webdavProxySaved.
  ///
  /// In en, this message translates to:
  /// **'Reference URL saved.'**
  String get webdavProxySaved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

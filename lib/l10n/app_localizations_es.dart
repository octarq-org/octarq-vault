// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OctarqVault';

  @override
  String get settings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get localeSystem => 'Sistema';

  @override
  String get localeZh => '中文';

  @override
  String get localeEn => 'English';

  @override
  String get localeEs => 'Español';

  @override
  String get security => 'Seguridad';

  @override
  String get lockVault => 'Bloquear bóveda';

  @override
  String get biometricUnlock => 'Desbloqueo biométrico';

  @override
  String get biometricUnlockSubtitle =>
      'Usar Face ID / huella para desbloquear';

  @override
  String get autoLockTimeout => 'Tiempo de bloqueo automático';

  @override
  String lockAfterMinutes(int minutes) {
    return 'Bloquear tras $minutes min en segundo plano';
  }

  @override
  String get oneMinute => '1 minuto';

  @override
  String minutesPlural(int count) {
    return '$count minutos';
  }

  @override
  String get expiration => 'Vencimiento';

  @override
  String get sync => 'Sincronización';

  @override
  String get syncMethod => 'Método de sincronización';

  @override
  String get syncMethodNone => 'Ninguno';

  @override
  String get syncMethodWebdav => 'WebDAV';

  @override
  String get syncMethodGoogleDrive => 'Google Drive';

  @override
  String get syncMethodLocalFile => 'Archivo local (navegador)';

  @override
  String get webdavDriveLocalFile => 'WebDAV / Drive / Archivo local';

  @override
  String get configureCredentialsAndLinkFiles =>
      'Configurar credenciales y vincular archivos';

  @override
  String get configureSyncMethodNone =>
      'Seleccione primero un método de sincronización';

  @override
  String configureSyncMethod(String method) {
    return 'Configurar $method';
  }

  @override
  String get exportSyncSettings => 'Exportar configuración de sincronización';

  @override
  String get exportSyncSettingsSubtitle =>
      'Copiar método de sincronización al portapapeles (JSON)';

  @override
  String get importSyncSettings => 'Importar configuración de sincronización';

  @override
  String get importSyncSettingsSubtitle => 'Pegar JSON desde el portapapeles';

  @override
  String get dataManagement => 'Gestión de datos';

  @override
  String get manageCustomAssetTypes =>
      'Gestionar tipos de activos personalizados';

  @override
  String get manageCustomAssetTypesSubtitle =>
      'Crear plantillas de activos personalizadas';

  @override
  String get manageTags => 'Gestionar etiquetas';

  @override
  String get manageTagsSubtitle => 'Ver y organizar todas las etiquetas';

  @override
  String get importExport => 'Importar / Exportar';

  @override
  String get exportEncFile => 'Exportar archivo .enc';

  @override
  String get exportEncFileSubtitle =>
      'Copia de seguridad cifrada (todas las plataformas)';

  @override
  String get importEncFile => 'Importar archivo .enc';

  @override
  String get importEncFileSubtitle =>
      'Reemplazar bóveda con copia de seguridad (ingresar contraseña)';

  @override
  String get exportJsonToClipboard => 'Exportar JSON al portapapeles';

  @override
  String get importJsonFromClipboard => 'Importar JSON (desde portapapeles)';

  @override
  String get about => 'Acerca de';

  @override
  String get website => 'Sitio web';

  @override
  String get websiteUrl => 'vault.octarq.org';

  @override
  String get helpAndDocs => 'Ayuda y documentación';

  @override
  String get docsUrl => 'vault.octarq.org/docs';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'Aceptar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get remove => 'Quitar';

  @override
  String get add => 'Agregar';

  @override
  String get create => 'Crear';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get connect => 'Conectar';

  @override
  String get link => 'Vincular';

  @override
  String get copy => 'Copiar';

  @override
  String get archive => 'Archivar';

  @override
  String get unarchive => 'Desarchivar';

  @override
  String get masterPassword => 'Contraseña maestra';

  @override
  String get pleaseEnterMasterPassword =>
      'Por favor ingresa tu contraseña maestra';

  @override
  String get incorrectPassword => 'Contraseña incorrecta';

  @override
  String get vaultLocked => 'Bóveda bloqueada';

  @override
  String get enterMasterPasswordToUnlock =>
      'Ingresa tu contraseña maestra para desbloquear.';

  @override
  String get useBiometrics => 'Usar biometría';

  @override
  String get searchHint => 'Buscar activos, etiquetas o campos...';

  @override
  String get newAsset => 'Nuevo activo';

  @override
  String get dashboard => 'Panel';

  @override
  String get allAssets => 'Todos los activos';

  @override
  String get categories => 'CATEGORÍAS';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get noUpcomingExpirations => 'Sin vencimientos próximos';

  @override
  String expiresOnDays(String date, int days) {
    return 'Vence $date ($days días)';
  }

  @override
  String get totalAssets => 'Total de activos';

  @override
  String get expiringWithin30Days => 'Vence en < 30 días';

  @override
  String get estMonthlyCost => 'Costo mensual estimado';

  @override
  String get actionRequired => 'ACCIÓN REQUERIDA';

  @override
  String get viewAll => 'Ver todo →';

  @override
  String searchViewAllResults(int count) {
    return 'Ver los $count resultados';
  }

  @override
  String get recentlyAdded => 'AGREGADOS RECIENTEMENTE';

  @override
  String get expiringSoon => 'Por vencer';

  @override
  String get noAssetsYet => 'Sin activos aún';

  @override
  String get addFirstAssetHint =>
      'Agrega tu primer activo digital para comenzar.';

  @override
  String get addAsset => 'Agregar activo';

  @override
  String get asset => 'Activo';

  @override
  String get assetNotFound => 'Activo no encontrado';

  @override
  String get assetType => 'Tipo de activo';

  @override
  String get assetName => 'Nombre del activo';

  @override
  String get details => 'Detalles';

  @override
  String get fields => 'Campos';

  @override
  String get type => 'Tipo';

  @override
  String get expirationDate => 'Fecha de vencimiento';

  @override
  String get added => 'Agregado';

  @override
  String get editAsset => 'Editar activo';

  @override
  String get duplicateAsset => 'Duplicar activo';

  @override
  String get deleteAsset => 'Eliminar activo';

  @override
  String get deleteAssetConfirmation =>
      '¿Estás seguro de que deseas eliminar permanentemente este activo?';

  @override
  String get hideSecrets => 'Ocultar secretos';

  @override
  String get revealSecrets => 'Mostrar secretos';

  @override
  String get errorDecrypting => 'Error al descifrar';

  @override
  String fieldCopied(String label) {
    return '$label copiado';
  }

  @override
  String get noLinkedAssets => 'Sin activos vinculados.';

  @override
  String get removeLinkConfirm => '¿Eliminar vínculo?';

  @override
  String errorLoadingRelations(String error) {
    return 'Error al cargar relaciones: $error';
  }

  @override
  String get linkAsset => 'Vincular activo';

  @override
  String get targetAsset => 'Activo destino';

  @override
  String get relationType => 'Tipo de relación';

  @override
  String get relationHostedOn => 'Alojado en';

  @override
  String get relationDependsOn => 'Depende de';

  @override
  String get relationUses => 'Usa';

  @override
  String get relationManagedBy => 'Gestionado por';

  @override
  String get relationRelatedTo => 'Relacionado con';

  @override
  String get relationLinkedAccount => 'Cuenta vinculada';

  @override
  String get addReminder => 'Agregar recordatorio';

  @override
  String get triggerType => 'Tipo de activación';

  @override
  String get beforeExpiration => 'Antes del vencimiento';

  @override
  String get recurring => 'Recurrente';

  @override
  String get daysBefore => 'Días antes';

  @override
  String daysCount(int count) {
    return '$count días';
  }

  @override
  String get pleaseSelectType => 'Por favor selecciona un tipo';

  @override
  String get required => 'Obligatorio';

  @override
  String get addTagHint => 'Agregar etiqueta...';

  @override
  String get noneTapToSet => 'Ninguno — toca para establecer';

  @override
  String get clearDate => 'Borrar fecha';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get addReminderTooltip => 'Agregar recordatorio';

  @override
  String get defaultReminderBeforeExpiry =>
      'Predeterminado: 7 días antes del vencimiento';

  @override
  String get setExpirationToEnableReminders =>
      'Establece el vencimiento para habilitar recordatorios';

  @override
  String get linkedAssets => 'Activos vinculados';

  @override
  String get addLink => 'Agregar vínculo';

  @override
  String get noLinksAddAfterSave =>
      'Sin vínculos. Agrega vínculos después de guardar.';

  @override
  String get noOtherAssetsToLink => 'No hay otros activos para vincular.';

  @override
  String get linkToAsset => 'Vincular a activo';

  @override
  String get noAssetsToLinkSaveFirst =>
      'Sin activos para vincular. Guarda este activo primero, luego agrega vínculos en su página de detalles.';

  @override
  String get basicInfo => 'Información básica';

  @override
  String get tags => 'Etiquetas';

  @override
  String saveAssetFailed(String error) {
    return 'Error al guardar activo: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get manageAssetTypes => 'Gestionar tipos de activos';

  @override
  String get deleteCustomType => 'Eliminar tipo personalizado';

  @override
  String get deleteCustomTypeConfirmation =>
      '¿Estás seguro? Los activos existentes de este tipo podrían perder sus asignaciones de plantilla.';

  @override
  String get newAssetType => 'Nuevo tipo de activo';

  @override
  String get assetTypeNameHint =>
      'Nombre del tipo de activo (p. ej., Billetera cripto)';

  @override
  String get icon => 'Ícono';

  @override
  String get fieldsConfiguration => 'Configuración de campos';

  @override
  String get addField => 'Agregar campo';

  @override
  String get fieldLabelHint => 'Etiqueta del campo (p. ej., Clave privada)';

  @override
  String get dataType => 'Tipo de dato';

  @override
  String get aesEncrypted => 'Cifrado AES-256-GCM';

  @override
  String get aesEncryptedSubtitle => 'Campos como contraseñas, claves';

  @override
  String get requiredInput => 'Entrada obligatoria';

  @override
  String get newTag => 'Nueva etiqueta';

  @override
  String get tagName => 'Nombre de etiqueta';

  @override
  String get color => 'Color';

  @override
  String get deleteTag => 'Eliminar etiqueta';

  @override
  String deleteTagConfirmation(String name) {
    return '¿Quitar "$name" de todos los activos?';
  }

  @override
  String get addTag => 'Agregar etiqueta';

  @override
  String get noTagsYet => 'Sin etiquetas aún';

  @override
  String get tagsCreatedWhenAdded =>
      'Las etiquetas se crean cuando las agregas a los activos.';

  @override
  String assetCount(int count) {
    return '$count activos';
  }

  @override
  String get expiringIn30Days => 'Vence en 30 días';

  @override
  String get expired => 'Vencido';

  @override
  String get noMatchesFound => 'No se encontraron coincidencias.';

  @override
  String selectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String itemsCount(int count) {
    return '$count elementos';
  }

  @override
  String get hideArchived => 'Ocultar archivados';

  @override
  String get showArchived => 'Mostrar archivados';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterExpiring30d => 'Vence en 30d';

  @override
  String get filterExpired => 'Vencidos';

  @override
  String get sortByAdded => 'Ordenar por: Agregado';

  @override
  String get sortByName => 'Ordenar por: Nombre';

  @override
  String get sortByExpiry => 'Ordenar por: Vencimiento';

  @override
  String get archived => 'Archivado';

  @override
  String get exportedJsonCopiedToClipboard =>
      '¡JSON exportado al portapapeles!';

  @override
  String get clipboardUnavailableWeb =>
      'Portapapeles no disponible (el navegador puede requerir HTTPS). Intenta guardar en un archivo.';

  @override
  String get clipboardUnavailable =>
      'No se pudo copiar al portapapeles. Por favor intenta de nuevo.';

  @override
  String get syncSettingsCopiedToClipboard =>
      'Configuración de sincronización copiada al portapapeles';

  @override
  String get syncSettingsApplied => 'Configuración de sincronización aplicada';

  @override
  String get unlockBackup => 'Desbloquear copia de seguridad';

  @override
  String get wrongPassword => 'Contraseña incorrecta';

  @override
  String importedEncCount(int count) {
    return 'Se importaron $count activos desde el archivo .enc';
  }

  @override
  String get clipboardEmpty => 'El portapapeles está vacío.';

  @override
  String invalidSyncSettingsJson(String error) {
    return 'JSON de configuración de sincronización inválido: $error';
  }

  @override
  String cannotOpenUrl(String url) {
    return 'No se puede abrir: $url';
  }

  @override
  String get validationNoAssetsInJson => 'No hay activos en el JSON.';

  @override
  String importSuccessCount(int count) {
    return '¡Se importaron $count activos correctamente!';
  }

  @override
  String importInvalid(String error) {
    return 'Importación inválida: $error';
  }

  @override
  String importFailed(String error) {
    return 'Error en importación: $error';
  }

  @override
  String get invalidJsonOrFormat => 'JSON o formato inválido.';

  @override
  String get webdavBackup => 'Copia de seguridad WebDAV';

  @override
  String get webdavConnected => 'WebDAV conectado';

  @override
  String get webdavConnectedSuccess => '¡Conexión a WebDAV exitosa!';

  @override
  String webdavConnectionFailed(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String get e2eeBackupSuccess => '¡Copia de seguridad E2EE exitosa!';

  @override
  String backupFailed(String error) {
    return 'Error en copia de seguridad: $error';
  }

  @override
  String restoredAssetsE2ee(int count) {
    return 'Se restauraron $count activos (E2EE)';
  }

  @override
  String restoreFailed(String error) {
    return 'Error en restauración: $error';
  }

  @override
  String get backupToWebdav => 'Respaldar en WebDAV';

  @override
  String get restoreFromWebdav => 'Restaurar desde WebDAV';

  @override
  String get disconnectClearCredentials => 'Desconectar y borrar credenciales';

  @override
  String get webdavConfigureDescription =>
      'Configura tu servidor WebDAV (p. ej., Nextcloud, ownCloud, Nutstore) para respaldar de forma segura tu base de datos cifrada.';

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String get serverUrlHint => 'https://example.com/remote.php/webdav/';

  @override
  String get username => 'Usuario';

  @override
  String get passwordOrAppToken => 'Contraseña / Token de aplicación';

  @override
  String get e2eeWebSync => 'Sincronización web E2EE';

  @override
  String get localDiskSyncE2ee =>
      'Sincronización en disco local (cifrado E2EE)';

  @override
  String get localDiskSyncDescription =>
      'Mantén un archivo de bóveda cifrado localmente. Este archivo se actualizará silenciosamente en tu escritorio tras cada cambio.';

  @override
  String get createNewEncryptedVaultFile =>
      'Crear nuevo archivo de bóveda cifrado';

  @override
  String get linkExistingVaultFile => 'Vincular archivo de bóveda existente';

  @override
  String get importFallback => 'Importación alternativa';

  @override
  String get exportFallback => 'Exportación alternativa';

  @override
  String get googleDriveSyncE2ee =>
      'Sincronización con Google Drive (cifrado E2EE)';

  @override
  String get googleDriveSyncDescription =>
      'Sincroniza automáticamente a una carpeta appDataFolder oculta en tu Google Drive. Completamente de conocimiento cero.';

  @override
  String get authorizeSyncGoogleDrive =>
      'Autorizar y sincronizar con Google Drive';

  @override
  String get pullFromGoogleDrive =>
      'Obtener desde Google Drive (sobrescribir local)';

  @override
  String restoredAssetsFromFile(int count) {
    return 'Se restauraron $count activos desde el archivo';
  }

  @override
  String get browserNoFilePickUseFallback =>
      'Tu navegador no permite seleccionar archivos directamente. Por favor usa los botones de importación/exportación alternativos de abajo.';

  @override
  String get pushedToGoogleDriveSuccess =>
      'Enviado de forma segura a Google Drive';

  @override
  String driveError(String error) {
    return 'Error de Drive: $error';
  }

  @override
  String restoredAssetsFromDrive(int count) {
    return 'Se restauraron $count activos desde Drive';
  }

  @override
  String get noBackupFoundOnDrive =>
      'No se encontró copia de seguridad en Drive.';

  @override
  String importError(String error) {
    return 'Error de importación: $error';
  }

  @override
  String get welcomeToOctarqVault => 'Bienvenido a OctarqVault';

  @override
  String get setMasterPassword => 'Establece tu contraseña maestra';

  @override
  String get setupPasswordDescription =>
      'Esta contraseña cifra todos tus datos localmente. Si la olvidas, los datos no podrán recuperarse.';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get createVault => 'Crear bóveda';

  @override
  String get orRestoreExistingVault => 'O restaura una bóveda existente';

  @override
  String get restoreFromGoogleDrive => 'Restaurar desde Google Drive';

  @override
  String get restoreFromLocalFile => 'Restaurar desde archivo local';

  @override
  String get passwordTooShort => 'Contraseña muy corta (mínimo 12 caracteres)';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String createVaultFailed(String error) {
    return 'Error al crear bóveda: $error';
  }

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get vaultFound => 'Bóveda encontrada';

  @override
  String get vaultRestoredSuccess => '¡Bóveda restaurada correctamente!';

  @override
  String unlockFailed(String error) {
    return 'Error al desbloquear: $error';
  }

  @override
  String fallbackError(String error) {
    return 'Error alternativo: $error';
  }

  @override
  String get notificationAssetExpiringTitle => 'Activo por vencer';

  @override
  String notificationAssetExpiringBody(String name, int days) {
    return '$name vence en $days días.';
  }

  @override
  String get notificationChannelName => 'Vencimientos de activos';

  @override
  String get notificationChannelDescription =>
      'Notificaciones de activos por vencer';

  @override
  String get webSecurityTitle => 'Aviso de seguridad web';

  @override
  String get webSecurityBody =>
      'En la web, las claves de cifrado se almacenan en el localStorage e IndexedDB del navegador, no en un enclave seguro respaldado por hardware como iOS Keychain o Android Keystore. Para mayor seguridad, usa la aplicación nativa en tu teléfono o escritorio.';

  @override
  String get webSecurityLearnMore => 'Saber más';

  @override
  String get webdavCorsWarning =>
      'Aviso CORS: La mayoría de los servidores WebDAV bloquean las solicitudes directas del navegador. Usa un servidor con encabezados CORS habilitados (p. ej., Nextcloud con la configuración correcta), o usa la aplicación de escritorio/móvil para la sincronización WebDAV.';

  @override
  String driveSmartMergeSuccess(int local, int remote) {
    return 'Fusionados $local locales + $remote remotos (LWW)';
  }

  @override
  String get icloudBackup => 'Copia de seguridad iCloud';

  @override
  String get icloudBackupSubtitle =>
      'Sincronizar bóveda cifrada con iCloud Drive (solo iOS)';

  @override
  String get icloudBackupSuccess => '¡Copia de seguridad en iCloud exitosa!';

  @override
  String icloudRestoreSuccess(int count) {
    return 'Se restauraron $count activos desde iCloud';
  }

  @override
  String get icloudNotAvailable =>
      'iCloud no está disponible en este dispositivo.';
}

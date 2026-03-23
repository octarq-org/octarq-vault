/// Metadata for an encrypted attachment associated with an [Asset].
///
/// The actual ciphertext lives on disk at
/// `<ApplicationSupport>/octarq_attachments/<encFileName>`.
/// The file is encrypted with AES-256-GCM via [EncryptionService.encryptBytes].
class AssetAttachment {
  final String id;

  /// The owning asset's UUID.
  final String assetId;

  /// Original file name (e.g. `passport_scan.pdf`).
  final String name;

  /// MIME type (e.g. `application/pdf`, `image/jpeg`).
  final String mimeType;

  /// Original (plaintext) size in bytes.
  final int size;

  /// Encrypted file name on disk: `<uuid>.enc`.
  /// Only the filename, not a full path.
  final String encFileName;

  final int createdAt;
  final int updatedAt;

  const AssetAttachment({
    required this.id,
    required this.assetId,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.encFileName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'assetId': assetId,
    'name': name,
    'mimeType': mimeType,
    'size': size,
    'encFileName': encFileName,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AssetAttachment.fromJson(Map<String, dynamic> json) =>
      AssetAttachment(
        id: json['id'] as String,
        assetId: json['assetId'] as String,
        name: json['name'] as String,
        mimeType: json['mimeType'] as String,
        size: (json['size'] as num).toInt(),
        encFileName: json['encFileName'] as String,
        createdAt: (json['createdAt'] as num).toInt(),
        updatedAt: (json['updatedAt'] as num).toInt(),
      );

  AssetAttachment copyWith({
    String? id,
    String? assetId,
    String? name,
    String? mimeType,
    int? size,
    String? encFileName,
    int? createdAt,
    int? updatedAt,
  }) => AssetAttachment(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    name: name ?? this.name,
    mimeType: mimeType ?? this.mimeType,
    size: size ?? this.size,
    encFileName: encFileName ?? this.encFileName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assetId == other.assetId &&
          name == other.name &&
          mimeType == other.mimeType &&
          size == other.size &&
          encFileName == other.encFileName &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    name,
    mimeType,
    size,
    encFileName,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'AssetAttachment(id: $id, assetId: $assetId, name: $name, '
      'mimeType: $mimeType, size: $size)';
}

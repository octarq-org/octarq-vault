import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PickedLocalFile {
  final String name;
  final String mimeType;
  final Uint8List bytes;

  const PickedLocalFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });
}

class FilePickerService {
  static const Map<String, String> _mimeByExtension = {
    'txt': 'text/plain',
    'md': 'text/markdown',
    'json': 'application/json',
    'csv': 'text/csv',
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'zip': 'application/zip',
  };

  static String mimeForExtension(String? extension) {
    final ext = (extension ?? '').toLowerCase();
    return _mimeByExtension[ext] ?? 'application/octet-stream';
  }

  String _resolveMime(PlatformFile file) {
    return mimeForExtension(file.extension);
  }

  Future<PickedLocalFile?> pickSingleFile() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    final file = picked?.files.firstOrNull;
    if (file == null || file.bytes == null) return null;
    return PickedLocalFile(
      name: file.name,
      mimeType: _resolveMime(file),
      bytes: file.bytes!,
    );
  }
}

final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});

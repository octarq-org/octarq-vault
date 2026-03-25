import 'package:flutter_test/flutter_test.dart';
import 'package:octarq_vault/services/file_picker_service.dart';

void main() {
  group('FilePickerService.mimeForExtension', () {
    test('returns known mime for common extensions', () {
      expect(FilePickerService.mimeForExtension('txt'), 'text/plain');
      expect(FilePickerService.mimeForExtension('pdf'), 'application/pdf');
      expect(FilePickerService.mimeForExtension('png'), 'image/png');
    });

    test('is case-insensitive', () {
      expect(FilePickerService.mimeForExtension('JPG'), 'image/jpeg');
      expect(FilePickerService.mimeForExtension('Json'), 'application/json');
    });

    test('falls back to application/octet-stream for unknown', () {
      expect(
        FilePickerService.mimeForExtension('unknown_ext'),
        'application/octet-stream',
      );
      expect(
        FilePickerService.mimeForExtension(null),
        'application/octet-stream',
      );
    });
  });
}

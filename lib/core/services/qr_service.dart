import 'dart:convert';

class QRService {
  static const String _appSignature = "SMP-MUH-1-ABSENSI-SECURE";

  // Generate QR content string for a student
  String generateQRContent(String studentId, String qrCodeId) {
    final Map<String, String> data = {
      'app': _appSignature,
      'student_id': studentId,
      'qr_code_id': qrCodeId,
    };
    final jsonStr = jsonEncode(data);
    final bytes = utf8.encode(jsonStr);
    return base64Encode(bytes);
  }

  // Parse QR content string and return Map of data
  // Returns null if invalid signature
  Map<String, String>? parseQRContent(String qrContent) {
    try {
      final bytes = base64Decode(qrContent);
      final jsonStr = utf8.decode(bytes);
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);

      if (decoded['app'] == _appSignature) {
        return {
          'student_id': decoded['student_id']?.toString() ?? '',
          'qr_code_id': decoded['qr_code_id']?.toString() ?? '',
        };
      }
    } catch (e) {
      // Invalid format or signature
    }
    return null;
  }
}

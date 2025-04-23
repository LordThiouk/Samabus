import 'dart:convert';
import 'package:crypto/crypto.dart';

class QRGenerator {
  static Future<String> generateQRCode(String bookingId) async {
    // In a real app, this would generate a QR code image
    // For now, we'll just return a unique string that would be encoded in the QR
    
    // Add a timestamp and hash for security
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final dataToHash = '$bookingId:$timestamp';
    final hash = sha256.convert(utf8.encode(dataToHash)).toString().substring(0, 8);
    
    return '$bookingId:$timestamp:$hash';
  }
}

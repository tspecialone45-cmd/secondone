import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class AadhaarUtils {
  // 32-byte key for AES-256 (in production, should be securely derived or fetched from secure environment)
  static final _key = enc.Key.fromUtf8('MahilaBachatGatAppKeySecret2024!');
  static final _iv = enc.IV.fromUtf8('16BytesInitVec12');

  /// Extracts only the last 4 digits of a 12-digit Aadhaar number
  static String extractLast4(String aadhaarNumber) {
    final cleaned = aadhaarNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length >= 4) {
      return cleaned.substring(cleaned.length - 4);
    }
    return cleaned;
  }

  /// Encrypts the full Aadhaar number using AES-256
  static String encryptAadhaar(String fullAadhaar) {
    try {
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(fullAadhaar.trim(), iv: _iv);
      return encrypted.base64;
    } catch (e) {
      // Fallback secure SHA-256 hash if encryption fails
      return hashAadhaar(fullAadhaar);
    }
  }

  /// Decrypts the encrypted Aadhaar representation
  static String decryptAadhaar(String encryptedBase64) {
    try {
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: _iv);
      return decrypted;
    } catch (e) {
      return '****';
    }
  }

  /// Hashes Aadhaar with SHA-256 for non-reversible lookup
  static String hashAadhaar(String fullAadhaar) {
    final bytes = utf8.encode(fullAadhaar.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Formats last 4 digits as XXXX-XXXX-1234
  static String formatMasked(String last4) {
    return 'XXXX-XXXX-$last4';
  }
}

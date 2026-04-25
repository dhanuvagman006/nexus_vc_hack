import 'package:encrypt/encrypt.dart';

class CryptoService {
  // A static 32-character shared secret key for AES-256 encryption.
  // In a real production app, this should be securely fetched or derived.
  static const String _secretKeyString = 'my32lengthsupersecretnooneknows1';
  static final Key _key = Key.fromUtf8(_secretKeyString);
  static final IV _iv = IV.fromLength(16); // 16 bytes for AES

  /// Encrypts a plaintext JSON string and returns a Base64 encoded encrypted string.
  static String encryptJson(String plainText) {
    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return plainText; // Fallback, though ideally should throw
    }
  }

  /// Decrypts a Base64 encoded encrypted string back to plaintext JSON.
  static String decryptJson(String encryptedBase64) {
    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: _iv);
      return decrypted;
    } catch (e) {
      print('Decryption error: $e');
      return encryptedBase64; // Fallback
    }
  }
}

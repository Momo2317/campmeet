import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

class EncryptionService {
  late final enc.Key key;
  late final enc.IV iv;
  late final enc.Encrypter encrypter;

  EncryptionService() {
    // Generate a secure 32-byte AES key and a 16-byte IV for the session.
    // In a real E2EE implementation, this key would be derived via ECDH (Elliptic-curve Diffie–Hellman)
    // using the recipient's Public Key and our Private Key.
    key = enc.Key.fromSecureRandom(32);
    iv = enc.IV.fromSecureRandom(16);
    encrypter = enc.Encrypter(enc.AES(key));
  }

  /// Gibt eine simulierte 60-stellige Sicherheitsnummer basierend auf dem aktuellen Key zurück.
  String getSecurityCode(String remoteUserId) {
    // Im echten Szenario wäre dies z.B. SHA512(MyPubKey || RemotePubKey).
    final rawHash = key.base64 + remoteUserId;
    // Um einen langen Zahlen-Code zu generieren, wandeln wir Zeichen in Ziffern um
    final code =
        rawHash.codeUnits.map((u) => u.toString().padLeft(2, '0')).join('');
    // Nehmen die ersten 60 Zeichen und gruppieren sie in 5er Blöcke
    String trimmed = code.padRight(60, '0').substring(0, 60);
    return trimmed.replaceAllMapped(RegExp(r'.{5}'), (m) => '${m[0]} ').trim();
  }

  /// Verschlüsselt eine ausgehende Nachricht
  String encryptMessage(String plainText) {
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    debugPrint("🔒 E2EE -> Original: '$plainText'");
    debugPrint("🔒 E2EE -> Verschlüsselt: '${encrypted.base64}'");
    return encrypted.base64;
  }

  /// Entschlüsselt eine eingehende Nachricht
  String decryptMessage(String base64Encrypted) {
    try {
      final decrypted = encrypter.decrypt64(base64Encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      debugPrint('❌ E2EE Entschlüsselungs-Fehler: $e');
      return "Der Inhalt dieser Nachricht kann aufgrund von Verschlüsselungsproblemen nicht angezeigt werden.";
    }
  }
}

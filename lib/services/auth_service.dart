import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  static const _keyUrl = 'velocity_server_url';
  static const _keyClientId = 'velocity_cf_client_id';
  static const _keyClientSecret = 'velocity_cf_client_secret';

  static Future<bool> hasCredentials() async {
    final clientId = await _storage.read(key: _keyClientId);
    final secret = await _storage.read(key: _keyClientSecret);
    return clientId != null && secret != null && clientId.isNotEmpty && secret.isNotEmpty;
  }

  static Future<Map<String, String>> getHeaders() async {
    final clientId = await _storage.read(key: _keyClientId) ?? '';
    final secret = await _storage.read(key: _keyClientSecret) ?? '';
    return {
      'Content-Type': 'application/json',
      'CF-Access-Client-Id': clientId,
      'CF-Access-Client-Secret': secret,
    };
  }

  static Future<String> getBaseUrl() async {
    final stored = await _storage.read(key: _keyUrl);
    if (stored != null && stored.isNotEmpty) {
      return stored.endsWith('/') ? stored.substring(0, stored.length - 1) : stored;
    }
    return 'https://chat.sathwik.work';
  }

  static Future<bool> saveFromQrPayload(String rawPayload) async {
    try {
      final Map<String, dynamic> data = jsonDecode(rawPayload.trim());
      final url = (data['url'] as String?)?.trim() ?? 'https://chat.sathwik.work';
      final clientId = (data['client_id'] as String?)?.trim() ?? '';
      final secret = (data['client_secret'] as String?)?.trim() ?? '';

      if (clientId.isEmpty || secret.isEmpty) return false;

      final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

      await _storage.write(key: _keyUrl, value: cleanUrl);
      await _storage.write(key: _keyClientId, value: clientId);
      await _storage.write(key: _keyClientSecret, value: secret);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}

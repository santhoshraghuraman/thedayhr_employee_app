import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Must be overridden in [ProviderScope] at app startup with an initialized
/// [SharedPreferences] instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope.',
  );
});

/// Provides the shared [LocalStorageService] instance.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref.watch(sharedPreferencesProvider));
});

/// Safe wrapper over [SharedPreferences] that handles JSON parsing and storage
/// exceptions gracefully without crashing the application.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  /// Reads a raw string value, returning `null` if unavailable or on error.
  String? readString(String key) {
    try {
      return _prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  /// Writes a raw string value, returning `true` if saved successfully.
  Future<bool> writeString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (_) {
      return false;
    }
  }

  /// Removes a key from local storage, returning `true` on success.
  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (_) {
      return false;
    }
  }

  /// Decodes a JSON object from [key]. Returns `null` if missing or malformed.
  Map<String, dynamic>? readJsonMap(String key) {
    final raw = readString(key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Encodes [value] as JSON and saves it under [key].
  Future<bool> writeJsonMap(String key, Map<String, dynamic> value) async {
    try {
      final encoded = jsonEncode(value);
      return await writeString(key, encoded);
    } catch (_) {
      return false;
    }
  }

  /// Decodes a JSON list of maps from [key].
  ///
  /// Returns `null` if the key does not exist or the top-level JSON is corrupt.
  /// Individual malformed entries inside a valid list are skipped safely.
  List<Map<String, dynamic>>? readJsonList(String key) {
    final raw = readString(key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }
      final result = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          result.add(item);
        } else if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Encodes [items] as a JSON array and saves it under [key].
  Future<bool> writeJsonList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final encoded = jsonEncode(items);
      return await writeString(key, encoded);
    } catch (_) {
      return false;
    }
  }
}

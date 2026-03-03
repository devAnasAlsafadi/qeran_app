import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_service.dart';

class SharedPrefService implements StorageService {
  final SharedPreferences _prefs;
  SharedPrefService(this._prefs);

  @override
  Future<void> save<T>(String key, T value) async {
    if (value is String) await _prefs.setString(key, value);
    else if (value is int) await _prefs.setInt(key, value);
    else if (value is bool) await _prefs.setBool(key, value);
    else if (value is double) await _prefs.setDouble(key, value);
    else if (value is List<String>) await _prefs.setStringList(key, value);
    else throw ArgumentError('SharedPrefService: unsupported type ${T.toString()} for key "$key"');
  }

  @override
  Future<T?> get<T>(String key) async {
    if (T == String) return _prefs.getString(key) as T?;
    if (T == int) return _prefs.getInt(key) as T?;
    if (T == bool) return _prefs.getBool(key) as T?;
    if (T == double) return _prefs.getDouble(key) as T?;
    if (T == List<String>) return _prefs.getStringList(key) as T?;
    return _prefs.get(key) as T?;
  }

  @override
  Future<void> remove(String key) async => await _prefs.remove(key);

  @override
  Future<void> clear() async => await _prefs.clear();
}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/storage_service.dart';

class SecureStorageService implements StorageService {
  final FlutterSecureStorage _secure;
  SecureStorageService(this._secure);

  @override
  Future<void> save<T>(String key, T value) async {
    await _secure.write(key: key, value: value.toString());
  }

  @override
  Future<T?> get<T>(String key) async {
    final value = await _secure.read(key: key);
    if (value == null) return null;

    if (T == bool) return (value == 'true') as T;
    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    return value as T;
  }

  @override
  Future<void> remove(String key) async => await _secure.delete(key: key);

  @override
  Future<void> clear() async => await _secure.deleteAll();
}
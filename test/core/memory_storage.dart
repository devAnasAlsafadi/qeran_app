import 'package:qeran/core/services/storage_service.dart';

/// A [StorageService] kept in memory: what a test saved is what it reads.
class MemoryStorage implements StorageService {
  final Map<String, Object?> values = {};

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<void> save<T>(String key, T value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();
}

class PreferencesStorage {
  PreferencesStorage._();

  static final PreferencesStorage instance = PreferencesStorage._();

  final Map<String, Object?> _memory = <String, Object?>{};

  Future<String?> readString(String key) {
    final Object? value = _memory[key];
    return Future<String?>.value(value is String ? value : null);
  }

  Future<void> writeString(String key, String value) {
    _memory[key] = value;
    return Future<void>.value();
  }

  Future<void> remove(String key) {
    _memory.remove(key);
    return Future<void>.value();
  }

  Future<bool?> readBool(String key) {
    final Object? value = _memory[key];
    return Future<bool?>.value(value is bool ? value : null);
  }

  Future<void> writeBool(String key, bool value) {
    _memory[key] = value;
    return Future<void>.value();
  }

  Future<List<String>?> readStringList(String key) {
    final Object? value = _memory[key];
    if (value is List) {
      return Future<List<String>?>.value(value.whereType<String>().toList());
    }
    return Future<List<String>?>.value(null);
  }

  Future<void> writeStringList(String key, List<String> value) {
    _memory[key] = List<String>.from(value);
    return Future<void>.value();
  }
}

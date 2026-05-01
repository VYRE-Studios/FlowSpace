// lib/sync/version_vector.dart

class VersionVector {
  final Map<String, int> _versions = {};

  void increment(String clientId) {
    _versions[clientId] = (_versions[clientId] ?? 0) + 1;
  }

  void update(String clientId, int version) {
    final current = _versions[clientId] ?? 0;
    if (version > current) {
      _versions[clientId] = version;
    }
  }

  int get(String clientId) => _versions[clientId] ?? 0;

  Map<String, dynamic> toJson() => Map.from(_versions);

  static VersionVector fromJson(Map<String, dynamic> json) {
    final vv = VersionVector();
    json.forEach((k, v) {
      vv._versions[k] = v;
    });
    return vv;
  }
}

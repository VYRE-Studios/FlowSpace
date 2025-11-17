typedef ActivityResult = ({
  List<Map<String, dynamic>> events,
  bool fromCache,
  DateTime? cacheTimestamp,
});

class ActivityService {
  // Local-first mode: return empty activity for now
  static Future<ActivityResult> getEvents() async {
    return (
      events: <Map<String, dynamic>>[],
      fromCache: true,
      cacheTimestamp: DateTime.now(),
    );
  }
}

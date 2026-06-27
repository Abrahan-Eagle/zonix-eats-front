import 'dart:collection';

class RealtimeEventUtils {
  static const String defaultSchemaVersion = 'legacy';

  static String normalizeEventName(String eventName) {
    if (eventName.contains('EntityUpdated')) return 'EntityUpdated';
    if (eventName.contains('NotificationCreated')) return 'NotificationCreated';
    return eventName;
  }

  static String? extractEventId(Map<String, dynamic> data) {
    final raw = data['event_id'];
    if (raw == null) return null;
    final id = raw.toString().trim();
    return id.isEmpty ? null : id;
  }

  static DateTime? extractOccurredAt(Map<String, dynamic> data) {
    final raw = data['occurred_at'] ?? data['timestamp'] ?? data['created_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String extractSchemaVersion(Map<String, dynamic> data) {
    final raw = data['schema_version'];
    final value = raw?.toString().trim();
    return (value == null || value.isEmpty) ? defaultSchemaVersion : value;
  }

  static int? extractEntityId(Map<String, dynamic> data) {
    final raw = data['entity_id'];
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }
}

class RealtimeEventDeduper {
  RealtimeEventDeduper({
    this.ttl = const Duration(minutes: 10),
    this.maxEntries = 1500,
  });

  final Duration ttl;
  final int maxEntries;
  final LinkedHashMap<String, DateTime> _seenEventIds = LinkedHashMap<String, DateTime>();
  final Map<String, DateTime> _latestByEntityKey = {};
  String? _lastDropReason;

  String? consumeLastDropReason() {
    final value = _lastDropReason;
    _lastDropReason = null;
    return value;
  }

  bool shouldAccept({
    required String canonicalEventName,
    required Map<String, dynamic> data,
    required DateTime now,
  }) {
    _cleanup(now);
    _lastDropReason = null;
    final eventId = RealtimeEventUtils.extractEventId(data);
    if (eventId != null) {
      final seenAt = _seenEventIds[eventId];
      if (seenAt != null && now.difference(seenAt) <= ttl) {
        _lastDropReason = 'duplicate_event_id';
        return false;
      }
      _seenEventIds[eventId] = now;
      if (_seenEventIds.length > maxEntries) {
        _seenEventIds.remove(_seenEventIds.keys.first);
      }
    }

    final entityId = RealtimeEventUtils.extractEntityId(data);
    final occurredAt = RealtimeEventUtils.extractOccurredAt(data);
    if (entityId != null && occurredAt != null) {
      final key = '$canonicalEventName:$entityId';
      final latest = _latestByEntityKey[key];
      if (latest != null && occurredAt.isBefore(latest)) {
        _lastDropReason = 'out_of_order';
        return false;
      }
      _latestByEntityKey[key] = occurredAt;
    }

    return true;
  }

  void _cleanup(DateTime now) {
    _seenEventIds.removeWhere((_, seenAt) => now.difference(seenAt) > ttl);
    _latestByEntityKey.removeWhere((_, latestAt) => now.difference(latestAt) > ttl);
  }
}

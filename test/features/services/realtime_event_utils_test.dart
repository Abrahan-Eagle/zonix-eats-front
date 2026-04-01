import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/realtime_event_utils.dart';

void main() {
  group('RealtimeEventUtils', () {
    test('normaliza nombres con namespace', () {
      expect(
        RealtimeEventUtils.normalizeEventName(r'App\Events\OrderStatusChanged'),
        'OrderStatusChanged',
      );
      expect(
        RealtimeEventUtils.normalizeEventName('NotificationCreated'),
        'NotificationCreated',
      );
    });

    test('extrae event_id y occurred_at', () {
      final data = {
        'event_id': 'evt-123',
        'occurred_at': '2026-01-01T00:00:00Z',
      };
      expect(RealtimeEventUtils.extractEventId(data), 'evt-123');
      expect(RealtimeEventUtils.extractOccurredAt(data)?.toUtc().year, 2026);
      expect(RealtimeEventUtils.extractSchemaVersion(data), 'legacy');
    });
  });

  group('RealtimeEventDeduper', () {
    test('descarta duplicados por event_id', () {
      final deduper = RealtimeEventDeduper(ttl: const Duration(minutes: 5));
      final now = DateTime.parse('2026-01-01T00:00:00Z');
      final event = {
        'event_id': 'evt-dup',
        'order_id': 10,
        'occurred_at': '2026-01-01T00:00:00Z',
      };
      expect(
        deduper.shouldAccept(canonicalEventName: 'OrderStatusChanged', data: event, now: now),
        isTrue,
      );
      expect(
        deduper.shouldAccept(canonicalEventName: 'OrderStatusChanged', data: event, now: now.add(const Duration(seconds: 5))),
        isFalse,
      );
    });

    test('descarta evento fuera de orden para misma entidad', () {
      final deduper = RealtimeEventDeduper(ttl: const Duration(minutes: 5));
      final base = DateTime.parse('2026-01-01T00:00:00Z');
      final newEvent = {
        'event_id': 'evt-new',
        'order_id': 11,
        'occurred_at': '2026-01-01T00:01:00Z',
      };
      final oldEvent = {
        'event_id': 'evt-old',
        'order_id': 11,
        'occurred_at': '2026-01-01T00:00:30Z',
      };
      expect(
        deduper.shouldAccept(canonicalEventName: 'OrderStatusChanged', data: newEvent, now: base),
        isTrue,
      );
      expect(
        deduper.shouldAccept(canonicalEventName: 'OrderStatusChanged', data: oldEvent, now: base.add(const Duration(seconds: 1))),
        isFalse,
      );
    });
  });
}

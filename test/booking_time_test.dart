import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sweaton/utils/booking_time.dart';

void main() {
  group('formatStoredTime', () {
    test('uses a fixed 12-hour English format', () {
      expect(formatStoredTime(const TimeOfDay(hour: 14, minute: 0)), '2:00 PM');
      expect(formatStoredTime(const TimeOfDay(hour: 8, minute: 30)), '8:30 AM');
      expect(formatStoredTime(const TimeOfDay(hour: 0, minute: 0)), '12:00 AM');
      expect(
        formatStoredTime(const TimeOfDay(hour: 12, minute: 0)),
        '12:00 PM',
      );
    });

    test('round-trips through parseStoredTime', () {
      for (var hour = 0; hour < 24; hour++) {
        final time = TimeOfDay(hour: hour, minute: 15);
        expect(parseStoredTime(formatStoredTime(time)), time);
      }
    });
  });

  group('parseStoredTime', () {
    test('parses 12-hour times', () {
      expect(parseStoredTime('2:00 PM'), const TimeOfDay(hour: 14, minute: 0));
      expect(parseStoredTime('9:45 am'), const TimeOfDay(hour: 9, minute: 45));
    });

    test('handles 12 AM and 12 PM', () {
      expect(parseStoredTime('12:00 AM'), const TimeOfDay(hour: 0, minute: 0));
      expect(
        parseStoredTime('12:30 PM'),
        const TimeOfDay(hour: 12, minute: 30),
      );
    });

    test('parses narrow no-break space before AM/PM', () {
      expect(parseStoredTime('2:00 PM'), const TimeOfDay(hour: 14, minute: 0));
    });

    test('parses legacy 24-hour times', () {
      expect(parseStoredTime('14:00'), const TimeOfDay(hour: 14, minute: 0));
      expect(parseStoredTime('08:00'), const TimeOfDay(hour: 8, minute: 0));
    });

    test('returns null for unparseable input', () {
      expect(parseStoredTime(''), isNull);
      expect(parseStoredTime('garbage'), isNull);
      expect(parseStoredTime('25:00'), isNull);
      expect(parseStoredTime('10:75'), isNull);
    });
  });

  group('overlapsExistingBooking', () {
    final bookings = [
      {'startTime': '2:00 PM', 'durationHours': 2}, // 14:00-16:00
    ];

    test('detects overlap with an existing booking', () {
      expect(
        overlapsExistingBooking(
          bookings,
          const TimeOfDay(hour: 15, minute: 0),
          1,
        ),
        isTrue,
      );
      expect(
        overlapsExistingBooking(
          bookings,
          const TimeOfDay(hour: 13, minute: 0),
          2,
        ),
        isTrue,
      );
    });

    test('allows back-to-back bookings', () {
      expect(
        overlapsExistingBooking(
          bookings,
          const TimeOfDay(hour: 16, minute: 0),
          1,
        ),
        isFalse,
      );
      expect(
        overlapsExistingBooking(
          bookings,
          const TimeOfDay(hour: 12, minute: 0),
          2,
        ),
        isFalse,
      );
    });

    test('detects overlap with legacy 24-hour bookings', () {
      final legacy = [
        {'startTime': '14:00', 'durationHours': 1},
      ];
      expect(
        overlapsExistingBooking(
          legacy,
          const TimeOfDay(hour: 14, minute: 0),
          1,
        ),
        isTrue,
      );
      // Previously "14:00" was misread as midnight, so this would clash.
      expect(
        overlapsExistingBooking(legacy, const TimeOfDay(hour: 0, minute: 0), 1),
        isFalse,
      );
    });

    test('skips bookings with missing or unparseable start times', () {
      final bad = [
        {'durationHours': 2},
        {'startTime': '', 'durationHours': 2},
        {'startTime': 'garbage', 'durationHours': 2},
      ];
      expect(
        overlapsExistingBooking(bad, const TimeOfDay(hour: 0, minute: 0), 4),
        isFalse,
      );
    });

    test('defaults missing duration to 1 hour and accepts doubles', () {
      final noDuration = [
        {'startTime': '2:00 PM'},
      ];
      expect(
        overlapsExistingBooking(
          noDuration,
          const TimeOfDay(hour: 15, minute: 0),
          1,
        ),
        isFalse,
      );

      final doubleDuration = [
        {'startTime': '2:00 PM', 'durationHours': 2.0},
      ];
      expect(
        overlapsExistingBooking(
          doubleDuration,
          const TimeOfDay(hour: 15, minute: 0),
          1,
        ),
        isTrue,
      );
    });
  });
}

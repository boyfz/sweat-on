import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Booking start times are stored as fixed English 12-hour strings
// (e.g. "2:00 PM") so they parse the same way on every device,
// regardless of locale or the 24-hour clock setting.
final DateFormat _storedTimeFormat = DateFormat('h:mm a', 'en_US');

String formatStoredTime(TimeOfDay time) {
  return _storedTimeFormat.format(DateTime(2000, 1, 1, time.hour, time.minute));
}

// Accepts "2:00 PM" as well as "14:00", which bookings made on
// 24-hour devices were previously saved as. Returns null if unparseable.
TimeOfDay? parseStoredTime(String str) {
  final match = RegExp(
    r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?\s*$',
  ).firstMatch(str);
  if (match == null) return null;

  int hour = int.parse(match.group(1)!);
  final int minute = int.parse(match.group(2)!);
  final String? period = match.group(3)?.toUpperCase();
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  if (hour > 23 || minute > 59) return null;

  return TimeOfDay(hour: hour, minute: minute);
}

Future<List<Map<String, dynamic>>> fetchVenueBookings(
  String venueName,
  DateTime date,
) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('bookings')
          .where('venue', isEqualTo: venueName)
          .where('date', isEqualTo: date.toIso8601String())
          .get();

  return snapshot.docs.map((doc) => doc.data()).toList();
}

bool overlapsExistingBooking(
  List<Map<String, dynamic>> bookings,
  TimeOfDay start,
  int durationHours,
) {
  final candidateStart = start.hour * 60 + start.minute;
  final candidateEnd = candidateStart + durationHours * 60;

  return bookings.any((b) {
    final timeStr = b['startTime'];
    if (timeStr is! String) return false;

    final existing = parseStoredTime(timeStr);
    if (existing == null) return false;

    final existingStart = existing.hour * 60 + existing.minute;
    final existingEnd =
        existingStart + ((b['durationHours'] as num?)?.toInt() ?? 1) * 60;

    return candidateStart < existingEnd && existingStart < candidateEnd;
  });
}

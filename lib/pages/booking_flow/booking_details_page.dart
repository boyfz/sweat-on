import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_page.dart';

class BookingDetailsPage extends StatefulWidget {
  final String venueName;
  final String venueType;
  final String venueAddress;
  final double pricePerHour;

  BookingDetailsPage({
    required this.venueName,
    required this.venueType,
    required this.venueAddress,
    required this.pricePerHour,
  });

  @override
  _BookingDetailsPageState createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  DateTime? selectedDate;
  int? durationHours;
  TimeOfDay? selectedStartTime;
  List<TimeOfDay> filteredStartTimes = [];
  bool isLoadingStartTimes = false;

  // Operating hours 8 AM - 10 PM
  final List<TimeOfDay> allStartTimes = List.generate(
    15,
    (index) => TimeOfDay(hour: 8 + index, minute: 0),
  );

  // Durations in hours
  List<int> availableDurations = [1, 2, 3, 4];

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
        selectedStartTime = null;
        durationHours = null;
        filteredStartTimes = [];
      });
    }
  }

  Future<void> _selectDuration() async {
    if (selectedDate == null) {
      _showError("Please select a date first.");
      return;
    }

    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return ListView(
          children:
              availableDurations
                  .map(
                    (hours) => ListTile(
                      title: Text("$hours hour(s)"),
                      onTap: () => Navigator.pop(context, hours),
                    ),
                  )
                  .toList(),
        );
      },
    );

    if (selected != null) {
      setState(() {
        durationHours = selected;
        selectedStartTime = null;
        filteredStartTimes = [];
        isLoadingStartTimes = true;
      });
      await _loadAvailableStartTimes();
      setState(() => isLoadingStartTimes = false);
    }
  }

  Future<void> _loadAvailableStartTimes() async {
    if (selectedDate == null || durationHours == null) return;

    final dateStr = selectedDate!.toIso8601String();
    final snapshot =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('venue', isEqualTo: widget.venueName)
            .where('date', isEqualTo: dateStr)
            .get();

    final bookings = snapshot.docs.map((doc) => doc.data()).toList();

    List<TimeOfDay> available = [];

    for (var candidate in allStartTimes) {
      final candidateStart = candidate.hour * 60 + candidate.minute;
      final candidateEnd = candidateStart + durationHours! * 60;

      bool overlaps = bookings.any((b) {
        final timeStr = b['startTime'];
        if (timeStr == null || timeStr.isEmpty) return false;

        final existing = _parseTimeOfDay(timeStr);
        final existingStart = existing.hour * 60 + existing.minute;
        final existingEnd =
            existingStart + (b['durationHours'] as num).toInt() * 60;

        return candidateStart < existingEnd && existingStart < candidateEnd;
      });

      if (!overlaps) available.add(candidate);
    }

    setState(() => filteredStartTimes = available);
  }

  Future<void> _selectStartTime() async {
    if (durationHours == null) {
      _showError("Please select duration first.");
      return;
    }

    if (filteredStartTimes.isEmpty) {
      _showError("No available start times for selected date and duration.");
      return;
    }

    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      builder:
          (context) => ListView(
            children:
                filteredStartTimes
                    .map(
                      (time) => ListTile(
                        title: Text(time.format(context)),
                        onTap: () => Navigator.pop(context, time),
                      ),
                    )
                    .toList(),
          ),
    );

    if (selected != null) {
      setState(() => selectedStartTime = selected);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  TimeOfDay _parseTimeOfDay(String str) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)').firstMatch(str);
    if (match == null) return const TimeOfDay(hour: 0, minute: 0);
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!;
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (durationHours ?? 0) * widget.pricePerHour;
    final canProceed =
        selectedDate != null &&
        selectedStartTime != null &&
        durationHours != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Venue details card
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.venueName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Type: ${widget.venueType}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Address: ${widget.venueAddress}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Select Date
              const Text(
                "Select Available Date",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                title: Text(
                  selectedDate != null
                      ? "${selectedDate!.toLocal()}".split(' ')[0]
                      : "Tap to select date",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),

              const SizedBox(height: 24),

              // Select Duration
              const Text(
                "Select Duration (Hours)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                title: Text(
                  durationHours != null
                      ? "$durationHours hour(s)"
                      : "Tap to select duration",
                ),
                trailing: const Icon(Icons.timer),
                onTap: _selectDuration,
              ),

              const SizedBox(height: 24),

              // Select Start Time
              const Text(
                "Select Available Start Time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                title:
                    isLoadingStartTimes
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          selectedStartTime != null
                              ? selectedStartTime!.format(context)
                              : "Tap to select start time",
                        ),
                trailing:
                    isLoadingStartTimes ? null : const Icon(Icons.access_time),
                onTap: isLoadingStartTimes ? null : _selectStartTime,
              ),

              const SizedBox(height: 24),

              // Total Price
              if (durationHours != null)
                Text(
                  "Total Price: RM ${totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      canProceed
                          ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PaymentPage(
                                      venueName: widget.venueName,
                                      venueAddress: widget.venueAddress,
                                      date: selectedDate!,
                                      startTime: selectedStartTime!,
                                      durationHours: durationHours!,
                                      pricePerHour: widget.pricePerHour,
                                    ),
                              ),
                            );
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B39EF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Proceed to Payment",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

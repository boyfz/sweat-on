import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'booking_success_page.dart';
import 'mock_card_payment_page.dart';

class PaymentPage extends StatefulWidget {
  final String venueName;
  final String venueAddress;
  final DateTime date;
  final TimeOfDay startTime;
  final int durationHours;
  final double pricePerHour;

  const PaymentPage({
    super.key,
    required this.venueName,
    required this.venueAddress,
    required this.date,
    required this.startTime,
    required this.durationHours,
    required this.pricePerHour,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final Color primaryColor = const Color(0xFF4B39EF);
  bool _isProcessing = false;

  Future<void> _saveBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }

    final totalPrice = widget.pricePerHour * widget.durationHours;

    await FirebaseFirestore.instance.collection('bookings').add({
      'uid': user.uid,
      'email': user.email,
      'venue': widget.venueName,
      'venueAddress': widget.venueAddress,
      'date': widget.date.toIso8601String(),
      'startTime': widget.startTime.format(context),
      'durationHours': widget.durationHours,
      'pricePerHour': widget.pricePerHour,
      'totalPrice': totalPrice,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handlePayment() async {
    // Defensive check (you already passed required fields via constructor, but still safe)
    if (widget.venueName.isEmpty ||
        widget.venueAddress.isEmpty ||
        widget.durationHours <= 0 ||
        widget.pricePerHour <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking information is incomplete.')),
      );
      return;
    }

    final amount = widget.pricePerHour * widget.durationHours;

    final paymentSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MockCardPaymentPage(amount: amount)),
    );

    if (paymentSuccess == true) {
      setState(() => _isProcessing = true);

      try {
        await _saveBooking();

        if (mounted) {
          setState(() => _isProcessing = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BookingSuccessPage()),
          );
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Booking error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        "${widget.date.day}/${widget.date.month}/${widget.date.year}";
    final formattedStartTime = widget.startTime.format(context);
    final durationText = "${widget.durationHours} hour(s)";
    final totalCost = widget.pricePerHour * widget.durationHours;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Venue:', style: _labelStyle()),
            const SizedBox(height: 4),
            Text(widget.venueName, style: _valueStyle()),
            const SizedBox(height: 4),
            Text(widget.venueAddress, style: _valueStyle()),
            const SizedBox(height: 20),
            Text('Date:', style: _labelStyle()),
            const SizedBox(height: 4),
            Text(formattedDate, style: _valueStyle()),
            const SizedBox(height: 20),
            Text('Start Time:', style: _labelStyle()),
            const SizedBox(height: 4),
            Text(formattedStartTime, style: _valueStyle()),
            const SizedBox(height: 20),
            Text('Duration:', style: _labelStyle()),
            const SizedBox(height: 4),
            Text(durationText, style: _valueStyle()),
            const SizedBox(height: 20),
            Text('Total Price:', style: _labelStyle()),
            const SizedBox(height: 4),
            Text("RM ${totalCost.toStringAsFixed(2)}", style: _valueStyle()),
            const Spacer(),
            _isProcessing
                ? Center(
                  child: LoadingAnimationWidget.bouncingBall(
                    color: primaryColor,
                    size: 40,
                  ),
                )
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Confirm Booking'),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => const TextStyle(
    fontSize: 14,
    color: Colors.black54,
    fontWeight: FontWeight.w500,
  );

  TextStyle _valueStyle() => const TextStyle(
    fontSize: 18,
    color: Colors.black87,
    fontWeight: FontWeight.bold,
  );
}

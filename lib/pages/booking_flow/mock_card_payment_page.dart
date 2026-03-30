import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MockCardPaymentPage extends StatefulWidget {
  final double amount;

  const MockCardPaymentPage({super.key, required this.amount});

  @override
  State<MockCardPaymentPage> createState() => _MockCardPaymentPageState();
}

class _MockCardPaymentPageState extends State<MockCardPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  String nameOnCard = '';
  String cardNumber = '';
  String expiryDate = '';
  String cvv = '';
  bool isProcessing = false;

  void _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isProcessing = false);

    Navigator.pop(context, true); // returns true to indicate success
  }

  @override
  Widget build(BuildContext context) {
    final String amountText = widget.amount.toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Invoice'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child:
            isProcessing
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Pay Invoice',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card icons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(FontAwesomeIcons.ccVisa, size: 32),
                          SizedBox(width: 12),
                          Icon(FontAwesomeIcons.ccMastercard, size: 32),
                          SizedBox(width: 12),
                          Icon(FontAwesomeIcons.ccAmex, size: 32),
                          SizedBox(width: 12),
                          Icon(FontAwesomeIcons.ccDiscover, size: 32),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Amount display
                      Text('Payment amount', style: _labelStyle()),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        height: 50,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'RM $amountText',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        label: 'Name on card',
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter name on card' : null,
                        onSaved: (value) => nameOnCard = value!.trim(),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Card number',
                        hint: '1234 5678 9012 3456',
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter card number';
                          }
                          if (value.replaceAll(' ', '').length != 16) {
                            return 'Card number must be 16 digits';
                          }
                          return null;
                        },
                        onSaved: (value) => cardNumber = value!.trim(),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Expiry date',
                              hint: 'MM/YY',
                              maxLength: 5,
                              keyboardType: TextInputType.datetime,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter expiry';
                                }
                                if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                                  return 'Invalid format';
                                }
                                return null;
                              },
                              onSaved: (value) => expiryDate = value!.trim(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'Security code',
                              hint: '123',
                              maxLength: 3,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter CVV';
                                }
                                if (value.length != 3) {
                                  return 'CVV must be 3 digits';
                                }
                                return null;
                              },
                              onSaved: (value) => cvv = value!.trim(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _submitPayment,
                          icon: const Icon(Icons.lock_outline),
                          label: Text(
                            'Pay RM $amountText',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? hint,
    bool obscureText = false,
    int? maxLength,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      obscureText: obscureText,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  TextStyle _labelStyle() => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
}

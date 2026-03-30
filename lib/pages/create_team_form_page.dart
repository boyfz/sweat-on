import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'team_summary_page.dart';

class CreateTeamFormPage extends StatefulWidget {
  const CreateTeamFormPage({super.key});

  @override
  State<CreateTeamFormPage> createState() => _CreateTeamFormPageState();
}

class _CreateTeamFormPageState extends State<CreateTeamFormPage> {
  final Color primaryColor = const Color(0xFF4B39EF);

  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _venueAddressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venueLatController = TextEditingController();
  final TextEditingController _venueLngController = TextEditingController();

  String selectedSport = 'Football';
  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  int selectedDuration = 1;
  int selectedPlayersNeeded = 1;
  String? _userPhoneNumber;
  String? _userFullName;

  final List<String> sports = ['Football', 'Futsal'];
  final List<int> durations = [1, 2, 3, 4, 5, 6];

  Map<String, int> positions = {
    'Goalkeeper': 0,
    'Defender': 0,
    'Midfielder': 0,
    'Forward': 0,
  };

  String? _venueNameError;
  String? _venueAddressError;
  String? _venueLatError;
  String? _venueLngError;
  String? _descriptionError;
  String? _dateError;
  String? _timeError;
  String? _positionError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    updatePositionsBasedOnSport();
  }

  void updatePositionsBasedOnSport() {
    if (selectedSport == 'Futsal') {
      positions = {
        'Goalkeeper': 0,
        'Fixo': 0,
        'Pivot': 0,
        'Ala 1': 0,
        'Ala 2': 0,
      };
    } else {
      positions = {
        'Goalkeeper': 0,
        'Defender': 0,
        'Midfielder': 0,
        'Forward': 0,
      };
    }
    selectedPlayersNeeded = 1;
    setState(() {});
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _userPhoneNumber = data?['phone'];
          _userFullName = data?['fullName'];
        });
      }
    }
  }

  String get formattedDate =>
      selectedDate == null
          ? 'Select Date'
          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';

  String get formattedTime =>
      selectedStartTime == null
          ? 'Select Time'
          : selectedStartTime!.format(context);

  int get totalSelected => positions.values.fold(0, (a, b) => a + b);

  Future<void> pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => selectedStartTime = picked);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _showLoadingAndComplete() async {
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      _venueNameError =
          _venueNameController.text.trim().isEmpty
              ? 'Venue name is required.'
              : null;
      _venueAddressError =
          _venueAddressController.text.trim().isEmpty
              ? 'Venue address is required.'
              : null;
      _venueLatError =
          _venueLatController.text.trim().isEmpty
              ? 'Latitude is required.'
              : null;
      _venueLngError =
          _venueLngController.text.trim().isEmpty
              ? 'Longitude is required.'
              : null;
      _descriptionError =
          _descriptionController.text.trim().isEmpty
              ? 'Game description is required.'
              : null;
      _dateError = selectedDate == null ? 'Please select a date.' : null;
      _timeError =
          selectedStartTime == null ? 'Please select a start time.' : null;
      _positionError =
          totalSelected != selectedPlayersNeeded
              ? 'Total positions must match players needed ($selectedPlayersNeeded).'
              : null;
    });

    final hasError = [
      _venueNameError,
      _venueAddressError,
      _venueLatError,
      _venueLngError,
      _descriptionError,
      _dateError,
      _timeError,
      _positionError,
    ].any((e) => e != null);

    if (user?.uid == null ||
        _userPhoneNumber == null ||
        _userFullName == null) {
      showError('User data not found. Please re-login.');
      return;
    }

    if (hasError) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    await FirebaseFirestore.instance.collection('teams').add({
      'sport': selectedSport,
      'venueName': _venueNameController.text.trim(),
      'venueAddress': _venueAddressController.text.trim(),
      'latitude': double.tryParse(_venueLatController.text.trim()) ?? 0.0,
      'longitude': double.tryParse(_venueLngController.text.trim()) ?? 0.0,
      'phoneNumber': _userPhoneNumber ?? '',
      'createdBy': user!.uid,
      'createdByName': _userFullName ?? '',
      'description': _descriptionController.text.trim(),
      'date': Timestamp.fromDate(selectedDate!),
      'startTime': selectedStartTime!.format(context),
      'duration': selectedDuration,
      'positions': Map<String, int>.from(positions),
      'playersNeeded': selectedPlayersNeeded,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.of(context).pop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => TeamSummaryPage(
              sport: selectedSport,
              date: selectedDate!,
              time: selectedStartTime!,
              positions: Map<String, int>.from(positions),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTeamComplete = totalSelected == selectedPlayersNeeded;
    final playersOptions = List<int>.generate(
      selectedSport == 'Futsal' ? 5 : 15,
      (i) => i + 1,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Team'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown('Select Sport', sports, selectedSport, (val) {
              selectedSport = val!;
              updatePositionsBasedOnSport();
            }),
            const SizedBox(height: 24),
            _buildDropdown(
              'Players Needed',
              playersOptions,
              selectedPlayersNeeded,
              (val) {
                selectedPlayersNeeded = val!;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: pickDate,
                    child: _buildPickerBox('Date', formattedDate),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: pickStartTime,
                    child: _buildPickerBox('Start Time', formattedTime),
                  ),
                ),
              ],
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _dateError!,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            if (_timeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _timeError!,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            _buildDropdown('Duration', durations, selectedDuration, (val) {
              selectedDuration = val!;
            }),
            const SizedBox(height: 24),
            _buildTextField(
              'Venue Name',
              _venueNameController,
              _venueNameError,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Venue Address',
              _venueAddressController,
              _venueAddressError,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Latitude',
                    _venueLatController,
                    _venueLatError,
                    hint: 'e.g. 3.1390',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'Longitude',
                    _venueLngController,
                    _venueLngError,
                    hint: 'e.g. 101.6869',
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4.0, top: 4, bottom: 12),
              child: Text(
                'Get coordinates from Google Maps (Right-click > "What\'s here?")',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            _buildTextField(
              'Game Description / Notes',
              _descriptionController,
              _descriptionError,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Number of Players per Position',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...positions.keys.map(
              (key) => buildCounter(key, selectedPlayersNeeded),
            ),
            const SizedBox(height: 12),
            Text(
              'Total: $totalSelected / $selectedPlayersNeeded',
              style: TextStyle(
                color: isTeamComplete ? Colors.green : Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_positionError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _positionError!,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showLoadingAndComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Create Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    List<T> items,
    T value,
    void Function(T?)? onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      items:
          items
              .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
              .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPickerBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String? error, {
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint ?? 'Enter ${label.toLowerCase()}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            errorText: error,
          ),
        ),
      ],
    );
  }

  Widget buildCounter(String position, int playersNeeded) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(position, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  positions[position]! > 0
                      ? () => setState(
                        () => positions[position] = positions[position]! - 1,
                      )
                      : null,
            ),
            Text(
              '${positions[position]}',
              style: const TextStyle(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed:
                  totalSelected < playersNeeded
                      ? () => setState(
                        () => positions[position] = positions[position]! + 1,
                      )
                      : null,
            ),
          ],
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddVenueFormPage extends StatefulWidget {
  const AddVenueFormPage({super.key});

  @override
  State<AddVenueFormPage> createState() => _AddVenueFormPageState();
}

class _AddVenueFormPageState extends State<AddVenueFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  String _selectedType = 'Futsal';
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _venueTypes = ['Futsal', 'Football'];
  final Color primaryColor = const Color(0xFF4B39EF);

  final Map<String, bool> _facilities = {
    'Parking': false,
    'Toilet': false,
    'Changing Room': false,
  };

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'venue_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final uploadTask = await ref.putFile(imageFile);
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _imageFile == null ||
        _latController.text.isEmpty ||
        _lngController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final imageUrl = await _uploadImage(_imageFile!);
    if (!mounted) return;
    if (imageUrl == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image upload failed.')));
      return;
    }

    try {
      final latitude = double.parse(_latController.text);
      final longitude = double.parse(_lngController.text);

      await FirebaseFirestore.instance.collection('venues').add({
        'name': _venueNameController.text.trim(),
        'address': _addressController.text.trim(),
        'type': _selectedType,
        'pricePerHour': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': imageUrl,
        'location': GeoPoint(latitude, longitude),
        'facilities':
            _facilities.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList(),
        'openHour': 8,
        'closeHour': 22,
        'createdAt': Timestamp.now(),
        'isVisible': true,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venue added successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Add venue error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Icon _getFacilityIcon(String facility) {
    switch (facility) {
      case 'Parking':
        return const Icon(Icons.local_parking);
      case 'Toilet':
        return const Icon(Icons.wc);
      case 'Changing Room':
        return const Icon(Icons.door_front_door);
      default:
        return const Icon(Icons.check);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:
                            _imageFile != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, size: 40),
                                      SizedBox(height: 8),
                                      Text('Tap to select image'),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _venueNameController,
                      decoration: const InputDecoration(
                        labelText: 'Venue Name',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter address' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price per Hour (MYR)',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter price' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Venue Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _venueTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _latController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) => value!.isEmpty ? 'Enter latitude' : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 4),
                      child: Text(
                        'Get from Google Maps (Right-click > "What\'s here?")',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lngController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) => value!.isEmpty ? 'Enter longitude' : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 4),
                      child: Text(
                        'Get from Google Maps (Right-click > "What\'s here?")',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Select Facilities',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ..._facilities.keys.map(
                      (facility) => SwitchListTile(
                        title: Row(
                          children: [
                            _getFacilityIcon(facility),
                            const SizedBox(width: 12),
                            Text(facility),
                          ],
                        ),
                        value: _facilities[facility]!,
                        onChanged:
                            (val) =>
                                setState(() => _facilities[facility] = val),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Submit Venue",
                          style: TextStyle(
                            color: Colors.white, // white text
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

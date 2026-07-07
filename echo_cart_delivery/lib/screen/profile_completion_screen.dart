import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/driver_model.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../utils/colors.dart';
import 'app_main_screen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final DriverModel? initialDriver;
  final Map<String, dynamic>? initialProfile;
  final bool goToHomeOnSuccess;

  const ProfileCompletionScreen({
    super.key,
    this.initialDriver,
    this.initialProfile,
    this.goToHomeOnSuccess = true,
  });

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _authService = AuthService();
  final _driverService = DriverService();
  final _picker = ImagePicker();

  bool _loading = false;
  String? _profilePictureBase64;
  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    _loadExistingDriver();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _licenseCtrl.dispose();
    _vehicleCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDriver() async {
    if (widget.initialDriver != null) {
      _populateFromDriver(widget.initialDriver!);
      return;
    }

    if (widget.initialProfile != null) {
      _populateFromProfile(widget.initialProfile!);
      return;
    }

    final driver = await _driverService.getDriver();
    if (!mounted || driver == null) return;
    _populateFromDriver(driver);
  }

  void _populateFromDriver(DriverModel driver) {
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = driver.name;
      _addressCtrl.text = driver.address;
      _cityCtrl.text = driver.city;
      _licenseCtrl.text = driver.licenseNumber;
      _vehicleCtrl.text = driver.vehicleNumber;
      _aadhaarCtrl.text = '';
      _panCtrl.text = '';
      _bankCtrl.text = '';
    });
  }

  void _populateFromProfile(Map<String, dynamic> profile) {
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = profile['name']?.toString() ?? '';
      _addressCtrl.text = profile['address']?.toString() ?? '';
      _cityCtrl.text = profile['city']?.toString() ?? '';
      _licenseCtrl.text = profile['licenseNumber']?.toString() ?? '';
      _vehicleCtrl.text = profile['vehicleNumber']?.toString() ?? '';
      _aadhaarCtrl.text = profile['aadhaarNumber']?.toString() ?? '';
      _panCtrl.text = profile['panNumber']?.toString() ?? '';
      _bankCtrl.text = profile['bankAccountNumber']?.toString() ?? '';
    });
  }

  Future<void> _pickProfileImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    final bytes = await File(pickedFile.path).readAsBytes();
    setState(() {
      _profilePicturePath = pickedFile.path;
      _profilePictureBase64 = base64Encode(bytes);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final token = await _driverService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found. Please log in again.');
      }

      final payload = _authService.buildProfilePayload(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        aadhaarNumber: _aadhaarCtrl.text.trim(),
        panNumber: _panCtrl.text.trim(),
        licenseNumber: _licenseCtrl.text.trim(),
        vehicleNumber: _vehicleCtrl.text.trim(),
        bankAccountNumber: _bankCtrl.text.trim(),
        profilePicture: _profilePictureBase64 ?? '',
      );

      final response = await _authService.submitDeliveryProfile(
        token: token,
        profileData: payload,
      );

      final currentDriver = await _driverService.getDriver();
      final updatedDriver = DriverModel(
        id: currentDriver?.id ?? '',
        name: response['name']?.toString() ?? _nameCtrl.text.trim(),
        phone: currentDriver?.phone ?? '',
        email: currentDriver?.email ?? '',
        licenseNumber:
            response['licenseNumber']?.toString() ?? _licenseCtrl.text.trim(),
        vehicleNumber:
            response['vehicleNumber']?.toString() ?? _vehicleCtrl.text.trim(),
        vehicleType: currentDriver?.vehicleType ?? '',
        status: currentDriver?.status ?? 'active',
        profileImage:
            response['profilePictureUrl']?.toString() ??
            response['profilePicture']?.toString() ??
            currentDriver?.profileImage ??
            '',
        rating: currentDriver?.rating ?? 0.0,
        totalDeliveries: currentDriver?.totalDeliveries ?? 0,
        address: response['address']?.toString() ?? _addressCtrl.text.trim(),
        city: response['city']?.toString() ?? _cityCtrl.text.trim(),
        profileCompleted: response['profileCompleted'] == true,
        profilePictureUrl:
            response['profilePictureUrl']?.toString() ??
            response['profilePicture']?.toString() ??
            '',
      );

      await _driverService.saveDriver(updatedDriver);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
      if (widget.goToHomeOnSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppMainScreen()),
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.initialDriver != null || widget.initialProfile != null
              ? 'Edit your profile'
              : 'Complete your profile',
        ),
        backgroundColor: buttonMainColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: backgroundColor,
                      border: Border.all(color: buttonMainColor, width: 2),
                    ),
                    child: _profilePicturePath == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : ClipOval(
                            child: Image.file(
                              File(_profilePicturePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Tap to add profile photo')),
              const SizedBox(height: 20),
              _buildTextField(_nameCtrl, 'Full name', 'Name is required'),
              const SizedBox(height: 12),
              _buildTextField(_addressCtrl, 'Address', 'Address is required'),
              const SizedBox(height: 12),
              _buildTextField(_cityCtrl, 'City', 'City is required'),
              const SizedBox(height: 12),
              _buildTextField(
                _aadhaarCtrl,
                'Aadhaar number',
                'Aadhaar number is required',
              ),
              const SizedBox(height: 12),
              _buildTextField(_panCtrl, 'PAN number', 'PAN number is required'),
              const SizedBox(height: 12),
              _buildTextField(
                _licenseCtrl,
                'License number',
                'License number is required',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _vehicleCtrl,
                'Vehicle number',
                'Vehicle number is required',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _bankCtrl,
                'Bank account number',
                'Bank account number is required',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonMainColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    String validationMessage,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: declineOrder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? validationMessage : null,
    );
  }
}

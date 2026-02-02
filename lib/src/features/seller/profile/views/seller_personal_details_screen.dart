import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

class SellerPersonalDetailsScreen extends ConsumerStatefulWidget {
  const SellerPersonalDetailsScreen({super.key});

  static const routePath = '/seller/profile/personal-details';

  @override
  ConsumerState<SellerPersonalDetailsScreen> createState() =>
      _SellerPersonalDetailsScreenState();
}

class _SellerPersonalDetailsScreenState
    extends ConsumerState<SellerPersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _gender;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  void _populateFields(Seller seller) {
    _nameController.text = seller.name ?? '';
    _emailController.text = seller.email ?? '';
    _phoneController.text = seller.phone ?? '';
    _gender = seller.gender?.value.toLowerCase() ?? 'male';
    _isPopulated = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Profile Picture',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(context, ImageSource.camera);
                }),
                _buildUploadOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(context, ImageSource.gallery);
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() => _isUploading = true);
        final success = await ref
            .read(sellerProfileProvider.notifier)
            .updateProfilePicture(File(pickedFile.path));
        setState(() => _isUploading = false);

        if (mounted) {
          if (success) {
            SnackBarService.showSuccess(context, 'Profile picture updated');
          } else {
            SnackBarService.showError(
              context,
              'Failed to upload profile picture',
            );
          }
        }
      }
    }
  }

  Widget _buildUploadOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SellerColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: SellerColors.primaryLight),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: CommonColors.black),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(sellerProfileProvider.notifier)
        .updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          gender: _gender,
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        SnackBarService.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context);
      } else {
        SnackBarService.showError(context, 'Failed to update profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerAsync = ref.watch(sellerProfileProvider);

    // Robust Initialization: Populate fields if data is available and not already populated
    if (!_isPopulated && sellerAsync.hasValue && sellerAsync.value != null) {
      _populateFields(sellerAsync.value!);
    }

    ref.listen<AsyncValue<Seller?>>(sellerProfileProvider, (previous, next) {
      if (next.hasValue && next.value != null && !_isPopulated) {
        setState(() {
          _populateFields(next.value!);
        });
      }
    });

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personal Details',
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: sellerAsync.when(
        data: (seller) {
          if (seller == null) return const Center(child: Text('No data'));
          return _buildContent(seller);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(Seller seller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SellerColors.surface,
                      border: Border.all(color: CommonColors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : seller.avatar?.fileUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              seller.avatar!.fileUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person,
                                    size: 50,
                                    color: SellerColors.primaryLight,
                                  ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: SellerColors.primaryLight,
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SellerColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CommonColors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildLabel('Full Name'),
            const SizedBox(height: 8),
            _buildTextField(
              _nameController,
              'Enter your full name',
              Icons.person_outline,
            ),

            const SizedBox(height: 20),
            _buildLabel('Email Address'),
            const SizedBox(height: 8),
            _buildTextField(
              _emailController,
              'Enter your email',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),
            _buildLabel('Phone Number'),
            const SizedBox(height: 8),
            _buildTextField(
              _phoneController,
              'Enter your phone number',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              enabled: false, // Phone is usually not editable
            ),

            const SizedBox(height: 20),
            _buildLabel('Gender'),
            const SizedBox(height: 8),
            _buildGenderSelector(),

            const SizedBox(height: 48),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SellerColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CommonColors.black.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CommonColors.greyText,
        ),
        prefixIcon: Icon(icon, color: CommonColors.greyText, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SellerColors.primaryLight),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildGenderOption('male', 'Male', Icons.male),
          _buildGenderOption('female', 'Female', Icons.female),
          _buildGenderOption('other', 'Other', Icons.transgender),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? SellerColors.primaryLight.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? SellerColors.primaryLight
                    : CommonColors.greyText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? SellerColors.primaryLight
                      : CommonColors.greyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

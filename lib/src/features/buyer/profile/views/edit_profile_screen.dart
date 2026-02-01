import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/models/buyer_model.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  static const routePath = '/buyer/profile/edit';

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  String _gender = 'Other';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();

    // Call getProfile explicitly in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize if data is already available before fetching fresh data
      final buyer = ref.read(buyerProfileProvider).value;
      if (buyer != null) {
        _populateFields(buyer);
      }
      ref.read(buyerProfileProvider.notifier).getProfile();
    });
  }

  void _populateFields(Buyer buyer) {
    _firstNameController.text = buyer.firstName ?? '';
    _lastNameController.text = buyer.lastName ?? '';
    _emailController.text = buyer.email ?? '';
    _gender = buyer.gender?.value ?? 'Other';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          // Listen for updates to populate fields
          ref.listen<AsyncValue<Buyer?>>(buyerProfileProvider, (
            previous,
            next,
          ) {
            if (next.hasValue && next.value != null && !next.isLoading) {
              // Populate if controllers were empty or data has changed significantly
              if (_firstNameController.text.isEmpty &&
                  _lastNameController.text.isEmpty) {
                _populateFields(next.value!);
              }
            }
          });

          return ref
              .watch(buyerProfileProvider)
              .when(
                data: (buyer) {
                  if (buyer == null) {
                    return const Center(child: Text('Buyer data not found'));
                  }
                  return _buildBody(buyer);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: BuyerColors.primaryLight,
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(buyerProfileProvider.notifier)
                            .getProfile(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
        },
      ),
    );
  }

  Widget _buildBody(Buyer buyer) {
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
                      color: BuyerColors.surface,
                      border: Border.all(color: CommonColors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: BuyerColors.primaryLight,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BuyerColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: CommonColors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildLabel('First Name'),
            const SizedBox(height: 8),
            _buildTextField(_firstNameController, 'Enter first name'),

            const SizedBox(height: 20),
            _buildLabel('Last Name'),
            const SizedBox(height: 8),
            _buildTextField(_lastNameController, 'Enter last name'),

            const SizedBox(height: 20),
            _buildLabel('Email Address'),
            const SizedBox(height: 8),
            _buildTextField(
              _emailController,
              'Enter email address',
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),
            _buildLabel('Gender'),
            const SizedBox(height: 8),
            _buildGenderDropdown(),

            const SizedBox(height: 48),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          final success = await ref
                              .read(buyerProfileProvider.notifier)
                              .updateProfile(
                                firstName: _firstNameController.text,
                                lastName: _lastNameController.text,
                                email: _emailController.text,
                                gender: Gender.fromString(_gender),
                              );
                          setState(() => _isLoading = false);

                          if (success && mounted) {
                            SnackBarService.showSuccess(
                              context,
                              'Profile updated successfully',
                            );
                            Navigator.pop(context);
                          } else if (mounted) {
                            SnackBarService.showError(
                              context,
                              'Failed to update profile',
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuyerColors.primaryLight,
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
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Update Profile',
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
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: CommonColors.greyText,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: BorderSide(color: BuyerColors.primaryLight),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: CommonColors.greyText),
          style: GoogleFonts.inter(fontSize: 15, color: CommonColors.black),
          items: ['Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _gender = newValue!;
            });
          },
        ),
      ),
    );
  }
}

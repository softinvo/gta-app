import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_gradient_button.dart';
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile Photo',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a source to upload your photo',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _UploadOptionTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _UploadOptionTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
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
            SnackBarService.showSuccess(context, 'Profile photo updated');
          } else {
            SnackBarService.showError(context, 'Failed to upload photo');
          }
        }
      }
    }
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

    if (!_isPopulated && sellerAsync.hasValue && sellerAsync.value != null) {
      _populateFields(sellerAsync.value!);
    }

    ref.listen<AsyncValue<Seller?>>(sellerProfileProvider, (_, next) {
      if (next.hasValue && next.value != null && !_isPopulated) {
        setState(() => _populateFields(next.value!));
      }
    });

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: const SellerAppBar(
        title: 'Personal Details',
        showLogo: false,
        centerTitle: true,
      ),
      body: sellerAsync.when(
        data: (seller) {
          if (seller == null) return const Center(child: Text('No data'));
          return _buildContent(seller);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(Seller seller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────────────────
            Center(child: _buildAvatar(seller)),

            const SizedBox(height: 28),

            // ── Personal Info card ───────────────────────────────────
            _SectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline_rounded,
              children: [
                _FormField(
                  label: 'Full Name',
                  controller: _nameController,
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),
                _FormField(
                  label: 'Email Address',
                  controller: _emailController,
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _FormField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  hint: 'Phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: false,
                  trailingWidget: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 11, color: CommonColors.greyText),
                        const SizedBox(width: 3),
                        Text(
                          'Locked',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: CommonColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Gender card ──────────────────────────────────────────
            _SectionCard(
              title: 'Gender',
              icon: Icons.wc_rounded,
              children: [_buildGenderSelector()],
            ),

            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────────────
            SellerGradientButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onTap: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Seller seller) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadImage,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: SellerColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : seller.avatar?.fileUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: Image.network(
                      seller.avatar!.fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          _AvatarInitials(name: seller.name ?? 'S'),
                    ),
                  )
                : _AvatarInitials(name: seller.name ?? 'S'),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: SellerColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    const options = [
      ('male', 'Male', Icons.male_rounded),
      ('female', 'Female', Icons.female_rounded),
      ('other', 'Other', Icons.transgender_rounded),
    ];
    return Row(
      children: options.map((opt) {
        final isSelected = _gender == opt.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: opt.$1 != 'other' ? 10 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? SellerColors.primaryLight
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? SellerColors.primaryLight
                      : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: SellerColors.primaryLight.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    opt.$3,
                    size: 16,
                    color: isSelected ? Colors.white : CommonColors.greyText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    opt.$2,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : CommonColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SellerColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SellerColors.primaryLight.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: SellerColors.sectionIconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: SellerColors.primaryLight),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SellerColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            height: 1,
            color: SellerColors.cardDivider,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? trailingWidget;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SellerColors.textLabel,
                letterSpacing: 0.3,
              ),
            ),
            if (trailingWidget != null) trailingWidget!,
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? SellerColors.textPrimary : SellerColors.textLabel,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: SellerColors.accentLight,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: enabled
                      ? SellerColors.fieldIconBg
                      : SellerColors.fieldDisabledFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: enabled
                      ? SellerColors.primaryLight
                      : SellerColors.accentLight,
                ),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 52, minHeight: 48),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            filled: true,
            fillColor: enabled
                ? SellerColors.fieldFill
                : SellerColors.fieldDisabledFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: SellerColors.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: SellerColors.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: SellerColors.primaryLight, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: SellerColors.fieldDisabledBorder),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: CommonColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: CommonColors.error, width: 1.5),
            ),
          ),
          validator: validator ??
              (enabled
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    }
                  : null),
        ),
      ],
    );
  }
}

class _UploadOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: SellerColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SellerColors.surface),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: SellerColors.primaryLight),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SellerColors.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String name;
  const _AvatarInitials({required this.name});

  String _initials() {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials(),
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

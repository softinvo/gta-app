import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/models/address_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  static const routePath = '/buyer/profile/addresses/add';

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _localityController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _localityController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final address = Address(
      name: _nameController.text.trim(),
      phoneNumber: '+91${_phoneController.text.trim()}',
      address: _addressController.text.trim(),
      locality: _localityController.text.trim(),
      landmark: _landmarkController.text.trim(),
      pincode: _pincodeController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: 'India',
      isPrimary: _isPrimary,
      formattedAddress:
          '${_addressController.text.trim()}, ${_localityController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim()} - ${_pincodeController.text.trim()}',
      geolocation: GeoLocation(coordinates: [0, 0]),
    );

    final success = await ref
        .read(buyerAddressesProvider.notifier)
        .addAddress(address);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addressAddedSuccess)),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.addressAddFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          context.l10n.addressAddNewCta,
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(context.l10n.addressFullNameLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _nameController,
                context.l10n.addressReceiverNameHint,
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressPhoneLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _phoneController,
                'Enter 10-digit mobile number',
                keyboardType: TextInputType.phone,
                prefixIcon: _buildPhonePrefix(),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 116,
                  minHeight: 48,
                ),
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _phoneValidator,
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressFlatLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _addressController,
                context.l10n.addressDetailsHint,
                icon: Icons.home_outlined,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressLocalityLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _localityController,
                context.l10n.addressLocalityHint,
                icon: Icons.location_city_outlined,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressLandmarkLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _landmarkController,
                context.l10n.addressLandmarkHint,
                required: false,
                icon: Icons.place_outlined,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context.l10n.addressPincodeLabel),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _pincodeController,
                          'XXXXXX',
                          icon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: _pincodeValidator,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context.l10n.addressCityLabel),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _cityController,
                          context.l10n.addressCityHint,
                          icon: Icons.location_city_outlined,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressStateLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _stateController,
                context.l10n.addressStateHint,
                icon: Icons.map_outlined,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.l10n.addressSetPrimaryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: CommonColors.black,
                  ),
                ),
                value: _isPrimary,
                activeThumbColor: BuyerColors.primaryLight,
                onChanged: (val) {
                  setState(() => _isPrimary = val);
                },
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
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
                          context.l10n.addressSaveCta,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: CommonColors.black,
        ),
        prefixIcon:
            prefixIcon ??
            (icon == null
                ? null
                : Icon(icon, size: 20, color: BuyerColors.primaryLight)),
        prefixIconConstraints:
            prefixIconConstraints ??
            const BoxConstraints(minWidth: 52, minHeight: 48),
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
        counterText: '',
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
      validator: validator ?? (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return context.l10n.commonFieldRequired;
        }
        return null;
      },
    );
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return context.l10n.commonFieldRequired;
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  Widget _buildPhonePrefix() {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇮🇳', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '+91',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: CommonColors.borderColor),
        ],
      ),
    );
  }

  String? _pincodeValidator(String? value) {
    final pincode = value?.trim() ?? '';
    if (pincode.isEmpty) return context.l10n.commonFieldRequired;
    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      return 'Enter a valid 6-digit PIN code';
    }
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/models/address_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class EditAddressScreen extends ConsumerStatefulWidget {
  final Address address;

  const EditAddressScreen({super.key, required this.address});

  static const routePath = '/buyer/profile/addresses/edit';

  @override
  ConsumerState<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends ConsumerState<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _localityController;
  late TextEditingController _landmarkController;
  late TextEditingController _pincodeController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late bool _isPrimary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing address data
    _nameController = TextEditingController(text: widget.address.name);
    _phoneController = TextEditingController(text: widget.address.phoneNumber);
    _addressController = TextEditingController(text: widget.address.address);
    _localityController = TextEditingController(text: widget.address.locality);
    _landmarkController = TextEditingController(
      text: widget.address.landmark ?? '',
    );
    _pincodeController = TextEditingController(text: widget.address.pincode);
    _cityController = TextEditingController(text: widget.address.city ?? '');
    _stateController = TextEditingController(text: widget.address.state);
    _isPrimary = widget.address.isPrimary;
  }

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

  Future<void> _updateAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // For now, we'll need to delete the old address and create a new one
    // since there's no update endpoint yet
    final newAddress = Address(
      id: widget.address.id,
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      locality: _localityController.text,
      landmark: _landmarkController.text,
      pincode: _pincodeController.text,
      city: _cityController.text,
      state: _stateController.text,
      country: 'India',
      isPrimary: _isPrimary,
      formattedAddress:
          '${_addressController.text}, ${_localityController.text}, ${_cityController.text}, ${_stateController.text} - ${_pincodeController.text}',
      geolocation:
          widget.address.geolocation ?? GeoLocation(coordinates: [0, 0]),
    );

    // Delete old address and add new one
    final deleteSuccess = await ref
        .read(buyerAddressesProvider.notifier)
        .removeAddress(widget.address.id!);

    if (!deleteSuccess && mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.addressUpdateFailed),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final addSuccess = await ref
        .read(buyerAddressesProvider.notifier)
        .addAddress(newAddress);

    setState(() => _isLoading = false);

    if (addSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addressUpdatedSuccess)),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.addressUpdateFailed),
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
          context.l10n.addressEditTitle,
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
              _buildTextField(_nameController, context.l10n.addressReceiverNameHint),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressPhoneLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _phoneController,
                '+91 XXXXX XXXXX',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressFlatLabel),
              const SizedBox(height: 8),
              _buildTextField(_addressController, context.l10n.addressDetailsHint),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressLocalityLabel),
              const SizedBox(height: 8),
              _buildTextField(_localityController, context.l10n.addressLocalityHint),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressLandmarkLabel),
              const SizedBox(height: 8),
              _buildTextField(
                _landmarkController,
                context.l10n.addressLandmarkHint,
                required: false,
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
                          keyboardType: TextInputType.number,
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
                        _buildTextField(_cityController, context.l10n.addressCityHint),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildLabel(context.l10n.addressStateLabel),
              const SizedBox(height: 8),
              _buildTextField(_stateController, context.l10n.addressStateHint),

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
                activeColor: BuyerColors.primaryLight,
                onChanged: (val) {
                  setState(() => _isPrimary = val);
                },
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateAddress,
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
                          context.l10n.addressUpdateCta,
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
        if (required && (value == null || value.isEmpty)) {
          return context.l10n.commonFieldRequired;
        }
        return null;
      },
    );
  }
}

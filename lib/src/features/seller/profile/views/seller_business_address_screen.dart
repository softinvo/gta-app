import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/res/colors.dart';

class SellerBusinessAddressScreen extends ConsumerStatefulWidget {
  const SellerBusinessAddressScreen({super.key});

  static const routePath = '/seller/profile/business-address';

  @override
  ConsumerState<SellerBusinessAddressScreen> createState() =>
      _SellerBusinessAddressScreenState();
}

class _SellerBusinessAddressScreenState
    extends ConsumerState<SellerBusinessAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _localityController;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  bool _isLoading = false;
  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _localityController = TextEditingController();
    _landmarkController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pincodeController = TextEditingController();
  }

  void _populateFields(Seller seller) {
    _nameController.text = seller.businessName ?? '';
    _phoneController.text = seller.phone ?? '';
    if (seller.address != null) {
      _addressController.text = seller.address!.address;
      _localityController.text = seller.address!.locality;
      _landmarkController.text = seller.address!.landmark ?? '';
      _cityController.text = seller.address!.city ?? '';
      _stateController.text = seller.address!.state;
      _pincodeController.text = seller.address!.pincode;
    }
    _isPopulated = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _localityController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Business address updated successfully'),
          backgroundColor: CommonColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerAsync = ref.watch(sellerProfileProvider);

    // Robust Initialization
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
          'Business Address',
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
              // Map placeholder
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 48,
                      color: SellerColors.primaryLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to select location on map',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CommonColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Details Section
              Text(
                'Contact Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Business Name'),
              const SizedBox(height: 8),
              _buildTextField(
                _nameController,
                'Enter business name',
                Icons.store_outlined,
              ),

              const SizedBox(height: 16),
              _buildLabel('Phone Number'),
              const SizedBox(height: 8),
              _buildTextField(
                _phoneController,
                'Enter phone number',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Address Details Section
              Text(
                'Address Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Full Address'),
              const SizedBox(height: 8),
              _buildTextField(
                _addressController,
                'House no., Building, Street, Area',
                Icons.home_outlined,
                maxLines: 2,
              ),

              const SizedBox(height: 16),
              _buildLabel('Locality'),
              const SizedBox(height: 8),
              _buildTextField(
                _localityController,
                'Enter locality/area',
                Icons.location_city_outlined,
              ),

              const SizedBox(height: 16),
              _buildLabel('Landmark (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                _landmarkController,
                'Near landmark',
                Icons.place_outlined,
                isRequired: false,
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('City'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _cityController,
                          'City',
                          Icons.location_city,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Pincode'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _pincodeController,
                          'Pincode',
                          Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildLabel('State'),
              const SizedBox(height: 8),
              _buildTextField(
                _stateController,
                'Enter state',
                Icons.map_outlined,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
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
                          'Save Address',
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
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
          borderSide: BorderSide(color: SellerColors.primaryLight),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_gradient_button.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_map_picker_screen.dart';
import 'package:gta_app/src/models/address_model.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

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
  GeoLocation? _geolocation;

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
      _geolocation = seller.address!.geolocation;
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

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => SellerMapPickerScreen(
          initialLatitude: _geolocation?.latitude,
          initialLongitude: _geolocation?.longitude,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _geolocation = GeoLocation(
        coordinates: [result.longitude, result.latitude],
      );
      if (result.address.isNotEmpty) _addressController.text = result.address;
      if (result.locality.isNotEmpty) {
        _localityController.text = result.locality;
      }
      if (result.city != null && result.city!.isNotEmpty) {
        _cityController.text = result.city!;
      }
      if (result.state.isNotEmpty) _stateController.text = result.state;
      if (result.pincode.isNotEmpty) _pincodeController.text = result.pincode;
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final address = Address(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      locality: _localityController.text.trim(),
      landmark: _landmarkController.text.trim(),
      pincode: _pincodeController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: 'India',
      formattedAddress:
          '${_addressController.text.trim()}, ${_localityController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim()} - ${_pincodeController.text.trim()}',
      geolocation: _geolocation,
    );

    final success = await ref
        .read(sellerProfileProvider.notifier)
        .updateProfile(extraData: {'address': address.toJson()});

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      SnackBarService.showSuccess(context, 'Business address updated successfully');
      Navigator.pop(context);
    } else {
      SnackBarService.showError(context, 'Failed to update business address');
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
        title: 'Business Address',
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
            // ── Map preview ──────────────────────────────────────────
            _MapPreview(
              geolocation: _geolocation,
              onTap: _openMapPicker,
            ),

            const SizedBox(height: 20),

            // ── Contact Details ──────────────────────────────────────
            _SectionCard(
              title: 'Contact Details',
              icon: Icons.contacts_outlined,
              children: [
                _FormField(
                  label: 'Business Name',
                  controller: _nameController,
                  hint: 'Enter business name',
                  icon: Icons.store_outlined,
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

            // ── Address Details ──────────────────────────────────────
            _SectionCard(
              title: 'Address Details',
              icon: Icons.location_on_outlined,
              children: [
                _FormField(
                  label: 'Full Address',
                  controller: _addressController,
                  hint: 'House no., Building, Street, Area',
                  icon: Icons.home_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _FormField(
                  label: 'Locality',
                  controller: _localityController,
                  hint: 'Enter locality / area',
                  icon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 16),
                _FormField(
                  label: 'Landmark (Optional)',
                  controller: _landmarkController,
                  hint: 'Near landmark',
                  icon: Icons.place_outlined,
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FormField(
                        label: 'City',
                        controller: _cityController,
                        hint: 'City',
                        icon: Icons.location_city,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormField(
                        label: 'Pincode',
                        controller: _pincodeController,
                        hint: 'Pincode',
                        icon: Icons.pin_drop_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormField(
                  label: 'State',
                  controller: _stateController,
                  hint: 'Enter state',
                  icon: Icons.map_outlined,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────────────
            SellerGradientButton(
              label: 'Save Address',
              isLoading: _isLoading,
              onTap: _saveAddress,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Map Preview ─────────────────────────────────────────────────────────────
// Shows a live GoogleMap inline. When no location is pinned yet, it
// auto-centers on the device's current GPS position. When a location has been
// confirmed in the picker, it shows that spot with a marker.
// All touch is forwarded to [onTap] which opens the full-screen picker.

class _MapPreview extends StatefulWidget {
  final GeoLocation? geolocation;
  final VoidCallback onTap;

  const _MapPreview({required this.geolocation, required this.onTap});

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  static const LatLng _indiaCenter = LatLng(20.5937, 78.9629);

  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.geolocation == null) _fetchCurrentLocation();
  }

  @override
  void didUpdateWidget(_MapPreview old) {
    super.didUpdateWidget(old);
    final geo = widget.geolocation;
    if (geo != null && geo != old.geolocation) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(geo.latitude, geo.longitude), 15),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) { return; }

      // Last-known position is instant; fall back to a live fix with a
      // hard timeout so the spinner never hangs on emulators / slow GPS.
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 13));
    } catch (_) {
      // fall back to India center — no action needed
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = widget.geolocation != null;

    final LatLng target;
    final double zoom;
    if (hasPin) {
      target = LatLng(widget.geolocation!.latitude, widget.geolocation!.longitude);
      zoom = 15;
    } else if (_currentLocation != null) {
      target = _currentLocation!;
      zoom = 13;
    } else {
      target = _indiaCenter;
      zoom = 4.5;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            // Actual map — gestures disabled so it acts as a static preview
            IgnorePointer(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: target, zoom: zoom),
                onMapCreated: (c) => _mapController = c,
                markers: hasPin
                    ? {
                        Marker(
                          markerId: const MarkerId('business-location'),
                          position: LatLng(
                            widget.geolocation!.latitude,
                            widget.geolocation!.longitude,
                          ),
                        ),
                      }
                    : {},
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                liteModeEnabled: true,
              ),
            ),

            // Full-area tap overlay — opens the picker
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
              ),
            ),

            // Bottom gradient action bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      hasPin
                          ? 'Tap to update location'
                          : 'Tap to set location on map',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        hasPin ? 'Update' : 'Open Map',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Small spinner in corner while GPS is resolving (no pin yet)
            if (_isLoadingLocation && !hasPin)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
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
  final bool enabled;
  final bool isRequired;
  final int maxLines;
  final Widget? trailingWidget;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.isRequired = true,
    this.maxLines = 1,
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
          maxLines: maxLines,
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
              borderSide: const BorderSide(color: SellerColors.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SellerColors.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: SellerColors.primaryLight, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: SellerColors.fieldDisabledBorder),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CommonColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: CommonColors.error, width: 1.5),
            ),
          ),
          validator: isRequired && enabled
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}


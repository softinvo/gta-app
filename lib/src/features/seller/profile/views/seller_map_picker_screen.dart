import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gta_app/src/res/colors.dart';

/// Result returned when a location is confirmed on [SellerMapPickerScreen].
class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String locality;
  final String? city;
  final String state;
  final String pincode;
  final String formattedAddress;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.locality,
    this.city,
    required this.state,
    required this.pincode,
    required this.formattedAddress,
  });
}

/// Full-screen map picker for selecting the seller's business location.
/// Tap anywhere on the map (or drag the marker) to drop a pin, then confirm.
class SellerMapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const SellerMapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<SellerMapPickerScreen> createState() => _SellerMapPickerScreenState();
}

class _SellerMapPickerScreenState extends State<SellerMapPickerScreen> {
  static const LatLng _fallbackCenter = LatLng(20.5937, 78.9629); // India

  GoogleMapController? _mapController;
  LatLng? _pickedLatLng;
  Placemark? _placemark;
  bool _isResolvingAddress = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _pickedLatLng = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _resolveAddress(_pickedLatLng!);
    }
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() => _isResolvingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _placemark = placemarks.isNotEmpty ? placemarks.first : null;
        _isResolvingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placemark = null;
        _isResolvingAddress = false;
      });
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() => _pickedLatLng = position);
    _resolveAddress(position);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to use this'),
            ),
          );
        }
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _pickedLatLng = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      await _resolveAddress(latLng);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _confirm() {
    if (_pickedLatLng == null) return;
    final p = _placemark;
    final address = [
      p?.subThoroughfare,
      p?.thoroughfare,
    ].where((e) => e != null && e.isNotEmpty).join(' ');
    final formatted = [
      p?.street,
      p?.subLocality,
      p?.locality,
      p?.administrativeArea,
      p?.postalCode,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    Navigator.of(context).pop(
      PickedLocation(
        latitude: _pickedLatLng!.latitude,
        longitude: _pickedLatLng!.longitude,
        address: address.isNotEmpty ? address : (p?.street ?? ''),
        locality: p?.subLocality ?? '',
        city: p?.locality,
        state: p?.administrativeArea ?? '',
        pincode: p?.postalCode ?? '',
        formattedAddress: formatted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Set Business Location',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: CommonColors.black,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLatLng ?? _fallbackCenter,
              zoom: _pickedLatLng != null ? 16 : 4.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            markers: _pickedLatLng == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('picked-location'),
                      position: _pickedLatLng!,
                      draggable: true,
                      onDragEnd: _onMapTapped,
                    ),
                  },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton(
              heroTag: 'use-current-location',
              backgroundColor: Colors.white,
              foregroundColor: SellerColors.primaryLight,
              onPressed: _isLocating ? null : _useCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ConfirmPanel(
              hasPin: _pickedLatLng != null,
              isResolving: _isResolvingAddress,
              previewAddress: _isResolvingAddress
                  ? null
                  : (_placemark != null
                      ? [
                          _placemark!.street,
                          _placemark!.subLocality,
                          _placemark!.locality,
                          _placemark!.administrativeArea,
                          _placemark!.postalCode,
                        ].where((e) => e != null && e.isNotEmpty).join(', ')
                      : null),
              onConfirm: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmPanel extends StatelessWidget {
  final bool hasPin;
  final bool isResolving;
  final String? previewAddress;
  final VoidCallback onConfirm;

  const _ConfirmPanel({
    required this.hasPin,
    required this.isResolving,
    required this.previewAddress,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasPin)
            Text(
              'Tap anywhere on the map to drop a pin',
              style: GoogleFonts.inter(fontSize: 13, color: CommonColors.greyText),
            )
          else if (isResolving)
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Fetching address...',
                  style: GoogleFonts.inter(fontSize: 13, color: CommonColors.greyText),
                ),
              ],
            )
          else
            Text(
              previewAddress?.isNotEmpty == true
                  ? previewAddress!
                  : 'Pin dropped. Address not found — you can edit it manually.',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: hasPin && !isResolving ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: SellerColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'Confirm Location',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

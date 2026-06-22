import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/features/buyer/profile/views/add_address_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/edit_address_screen.dart';
import 'package:gta_app/src/models/address_model.dart';
import 'package:gta_app/src/res/colors.dart';

class ManageAddressesScreen extends ConsumerStatefulWidget {
  const ManageAddressesScreen({super.key});

  static const routePath = '/buyer/profile/addresses';

  @override
  ConsumerState<ManageAddressesScreen> createState() =>
      _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends ConsumerState<ManageAddressesScreen> {
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
          'Manage Addresses',
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ref
                .watch(buyerAddressesProvider)
                .when(
                  data: (addresses) => addresses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: CommonColors.greyText,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No addresses saved',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: CommonColors.greyText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first address to get started',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: CommonColors.greyText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: addresses.length,
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            return _buildAddressCard(address);
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: address.isPrimary
            ? Border.all(color: BuyerColors.primaryLight, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BuyerColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      address.name.toLowerCase() == 'home'
                          ? Icons.home
                          : Icons.work,
                      size: 18,
                      color: BuyerColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    address.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CommonColors.black,
                    ),
                  ),
                ],
              ),
              if (address.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: BuyerColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Primary',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${address.address}, ${address.locality}, ${address.pincode}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CommonColors.greyText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 14,
                color: CommonColors.greyText,
              ),
              const SizedBox(width: 6),
              Text(
                address.phoneNumber,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CommonColors.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!address.isPrimary) ...[
                  _buildCardOption(
                    Icons.check_circle_outline,
                    'Mark as Primary',
                    () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Mark as Primary'),
                          content: const Text(
                            'Do you want to set this as your primary address?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && mounted) {
                        final success = await ref
                            .read(buyerAddressesProvider.notifier)
                            .markAddressPrimary(address.id!);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address marked as primary'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to mark address as primary',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 24),
                ],
                _buildCardOption(Icons.edit_outlined, 'Edit', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditAddressScreen(address: address),
                    ),
                  );
                }),
                const SizedBox(width: 24),
                _buildCardOption(Icons.delete_outline, 'Delete', () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Address'),
                      content: const Text(
                        'Are you sure you want to delete this address?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    final success = await ref
                        .read(buyerAddressesProvider.notifier)
                        .removeAddress(address.id!);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete address'),
                        ),
                      );
                    }
                  }
                }, isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOption(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : BuyerColors.primaryLight;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => context.push(AddAddressScreen.routePath),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add New Address',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: BuyerColors.primaryLight,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

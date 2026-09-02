import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/buyer/profile/controller/profile_controller.dart';
import 'package:gta_app/src/features/buyer/profile/views/add_address_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/edit_address_screen.dart';
import 'package:gta_app/src/models/address_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

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
          context.l10n.profileManageAddressesTitle,
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
                                context.l10n.addressEmptyTitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: CommonColors.greyText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.addressEmptySubtitle,
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
                  error: (e, _) => Center(child: Text(context.l10n.commonErrorPrefix(e.toString()))),
                ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    final displayAddress = address.formattedAddress.trim().isNotEmpty
        ? address.formattedAddress.trim()
        : [
            address.address,
            address.locality,
            address.city,
            address.state,
            address.pincode,
            address.country,
          ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: address.isPrimary
            ? Border.all(color: BuyerColors.primaryLight, width: 1.5)
            : Border.all(color: CommonColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BuyerColors.surface,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      address.name.toLowerCase() == 'home'
                          ? Icons.home_outlined
                          : address.name.toLowerCase() == 'work' ||
                                address.name.toLowerCase() == 'office'
                          ? Icons.business_outlined
                          : Icons.location_on_outlined,
                      size: 19,
                      color: BuyerColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        address.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                      fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CommonColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (address.isPrimary) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: BuyerColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: BuyerColors.primaryLight.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    context.l10n.addressPrimaryBadge,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: BuyerColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: BuyerColors.primaryLight,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  displayAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: CommonColors.darkGrey,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (address.phoneNumber.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: BuyerColors.primaryLight,
                ),
                const SizedBox(width: 10),
                Text(
                  address.phoneNumber,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: CommonColors.darkGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: CommonColors.borderColor),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!address.isPrimary) ...[
                  _buildCardOption(
                    Icons.check_circle_outline,
                    context.l10n.addressMarkPrimaryTitle,
                    () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(context.l10n.addressMarkPrimaryTitle),
                          content: Text(
                            context.l10n.addressMarkPrimaryConfirm,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(context.l10n.commonCancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(context.l10n.commonConfirm),
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
                            SnackBar(
                              content: Text(context.l10n.addressMarkedPrimarySuccess),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.addressMarkPrimaryFailed,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                _buildCardOption(Icons.edit_outlined, context.l10n.commonEdit, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditAddressScreen(address: address),
                    ),
                  );
                }),
                const SizedBox(width: 10),
                _buildCardOption(Icons.delete_outline, context.l10n.commonDelete, () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.l10n.addressDeleteDialogTitle),
                      content: Text(
                        context.l10n.addressDeleteConfirm,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.l10n.commonCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            context.l10n.commonDelete,
                            style: const TextStyle(color: Colors.red),
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
                        SnackBar(
                          content: Text(context.l10n.addressDeleteFailed),
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
    final color = isDestructive ? CommonColors.error : BuyerColors.primaryLight;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
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
            context.l10n.addressAddNewCta,
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

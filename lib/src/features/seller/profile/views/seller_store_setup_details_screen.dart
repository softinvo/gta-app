import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/models/document_model.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/res/colors.dart';

/// Read-only view of the store setup shown once the seller is verified.
/// Details are locked after verification because editing the profile
/// resets the verification status to pending on the backend.
class SellerStoreSetupDetailsScreen extends ConsumerWidget {
  const SellerStoreSetupDetailsScreen({super.key});

  static const routePath = '/seller/profile/store-setup-details';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider);

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: const SellerAppBar(
        title: 'Store Setup',
        showLogo: false,
        centerTitle: true,
      ),
      body: sellerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (seller) {
          if (seller == null) {
            return const Center(child: Text('Profile not found'));
          }
          return _DetailsBody(seller: seller);
        },
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  final Seller seller;
  const _DetailsBody({required this.seller});

  @override
  Widget build(BuildContext context) {
    final dp = seller.designerProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VerifiedBanner(),
          const SizedBox(height: 16),
          _DetailsSectionCard(
            title: 'Business Information',
            icon: Icons.store_rounded,
            children: [
              _DetailRow(
                label: 'Business Name',
                value: seller.businessName ?? '-',
              ),
              _DetailRow(
                label: 'Business Type',
                value: seller.businessType?.displayName ?? '-',
              ),
              _DetailRow(
                label: 'Registration Date',
                value: _formatDate(seller.businessRegistrationDate),
                isLast: seller.businessType != BusinessType.designer,
              ),
            ],
          ),
          if (seller.isDesigner && dp != null) ...[
            const SizedBox(height: 16),
            _DetailsSectionCard(
              title: 'Designer Profile',
              icon: Icons.palette_outlined,
              children: [
                _DetailRow(
                  label: 'Availability',
                  value: _availabilityLabel(dp.availabilityStatus),
                ),
                _DetailRow(label: 'Professional Bio', value: dp.bio ?? '-'),
                _DetailRow(
                  label: 'Years of Experience',
                  value: dp.yearsOfExperience?.toString() ?? '-',
                ),
                _DetailRow(
                  label: 'Price Range',
                  value: _priceRangeLabel(dp.priceRange),
                ),
                if (dp.specializations.isNotEmpty)
                  _SpecializationChips(specializations: dp.specializations),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _DetailsSectionCard(
            title: 'Bank Details',
            icon: Icons.account_balance_rounded,
            children: [
              _DetailRow(
                label: 'Account Holder Name',
                value: seller.accountHolderName ?? '-',
              ),
              _DetailRow(
                label: 'Account Number',
                value: _maskAccountNumber(seller.bankAccountNumber),
              ),
              _DetailRow(label: 'IFSC Code', value: seller.ifscCode ?? '-'),
              _DetailRow(
                label: 'Payout Status',
                value: seller.bankVerificationLabel,
                isLast: true,
              ),
            ],
          ),
          if (seller.documents.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailsSectionCard(
              title: 'Documents',
              icon: Icons.description_rounded,
              children: [
                for (final doc in seller.documents) _DocumentTile(doc: doc),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _maskAccountNumber(String? number) {
    if (number == null || number.isEmpty) return '-';
    if (number.length <= 4) return number;
    return '•••• ${number.substring(number.length - 4)}';
  }

  static String _availabilityLabel(AvailabilityStatus? status) {
    switch (status) {
      case AvailabilityStatus.available:
        return 'Available';
      case AvailabilityStatus.busy:
        return 'Busy';
      case AvailabilityStatus.notTakingOrders:
        return 'Not Taking Orders';
      default:
        return '-';
    }
  }

  static String _priceRangeLabel(PriceRange? range) {
    if (range == null || (range.min == null && range.max == null)) return '-';
    final min = range.min?.toStringAsFixed(0) ?? '0';
    final max = range.max?.toStringAsFixed(0) ?? '-';
    return '₹$min - ₹$max';
  }
}

class _VerifiedBanner extends StatelessWidget {
  const _VerifiedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StatusColors.verifiedBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StatusColors.verifiedDot.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: StatusColors.verifiedDot,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Verified',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: StatusColors.verifiedText,
                  ),
                ),
                Text(
                  'Your store details are locked after verification. Contact support to make changes.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: StatusColors.verifiedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailsSectionCard({
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: SellerColors.primaryLight, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SellerColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CommonColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecializationChips extends StatelessWidget {
  final List<String> specializations;
  const _SpecializationChips({required this.specializations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specializations',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CommonColors.greyText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in specializations)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SellerColors.primaryLight,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final Document doc;
  const _DocumentTile({required this.doc});

  Color get _statusBg {
    switch (doc.status) {
      case DocumentStatus.approved:
        return StatusColors.verifiedBg;
      case DocumentStatus.rejected:
        return StatusColors.rejectedBg;
      case DocumentStatus.pending:
        return StatusColors.pendingBg;
    }
  }

  Color get _statusText {
    switch (doc.status) {
      case DocumentStatus.approved:
        return StatusColors.verifiedText;
      case DocumentStatus.rejected:
        return StatusColors.rejectedText;
      case DocumentStatus.pending:
        return StatusColors.pendingText;
    }
  }

  String get _statusLabel {
    switch (doc.status) {
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = doc.docImage?.fileUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SellerColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.docType,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    if (doc.docNumber != null && doc.docNumber!.isNotEmpty)
                      Text(
                        doc.docNumber!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CommonColors.greyText,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusText,
                  ),
                ),
              ),
            ],
          ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 140,
                  color: SellerColors.surface,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: CommonColors.greyText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/features/seller/complaint/controller/seller_complaint_controller.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:intl/intl.dart';

class SellerComplaintsListScreen extends ConsumerWidget {
  const SellerComplaintsListScreen({super.key});

  static const routePath = '/seller/profile/complaints';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(sellerComplaintsProvider);

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: AppBar(
        backgroundColor: CommonColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: CommonColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Complaints',
          style: GoogleFonts.poppins(
            color: CommonColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sellerComplaintsProvider.notifier).refresh(),
        child: complaintsAsync.when(
          data: (complaints) {
            if (complaints.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return _buildComplaintCard(context, complaint);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: SellerColors.primaryLight.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in_outlined,
                size: 80,
                color: SellerColors.primaryLight.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'All Clear!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You haven't raised any support requests yet. Our team is here to help if you encounter any issues.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CommonColors.greyText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SellerColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Get Help & Support',
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

  Widget _buildComplaintCard(BuildContext context, dynamic complaint) {
    // Note: 'dynamic' because I might need to adapt to the exact Model
    final statusColor = _getStatusColor(complaint.status);
    final formattedDate = DateFormat(
      'MMM dd, yyyy',
    ).format(complaint.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                complaint.subject,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                complaint.status.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              complaint.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${complaint.id.substring(complaint.id.length - 8).toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CommonColors.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CommonColors.greyText,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigation to details can be added later if screen exists
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE67E22);
      case 'open':
        return SellerColors.primaryLight;
      case 'resolved':
        return const Color(0xFF2ECC71);
      case 'closed':
        return CommonColors.greyText;
      default:
        return CommonColors.greyText;
    }
  }
}

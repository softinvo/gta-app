import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';

class SellerVerificationScreen extends ConsumerStatefulWidget {
  const SellerVerificationScreen({super.key});

  static const routePath = '/seller/profile/verification';

  @override
  ConsumerState<SellerVerificationScreen> createState() =>
      _SellerVerificationScreenState();
}

class _SellerVerificationScreenState
    extends ConsumerState<SellerVerificationScreen> {
  // Mock verification status - replace with actual provider data
  final String _verificationStatus =
      'pending'; // not_submitted, pending, approved, rejected
  final String? _rejectionReason = null;

  // Mock documents list
  final List<_DocumentItem> _documents = [
    _DocumentItem(
      docType: 'PAN Card',
      docNumber: 'ABCDE1234F',
      status: 'approved',
      icon: Icons.credit_card,
    ),
    _DocumentItem(
      docType: 'GST Certificate',
      docNumber: '29ABCDE1234F1Z5',
      status: 'pending',
      icon: Icons.receipt_long,
    ),
    _DocumentItem(
      docType: 'Business License',
      docNumber: null,
      status: 'not_submitted',
      icon: Icons.description,
    ),
    _DocumentItem(
      docType: 'Address Proof',
      docNumber: null,
      status: 'not_submitted',
      icon: Icons.location_on,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
          'Verification Status',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 24),

            // Progress Indicator
            _buildProgressSection(),
            const SizedBox(height: 24),

            // Documents Section
            Text(
              'Required Documents',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CommonColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload all required documents to get verified',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CommonColors.greyText,
              ),
            ),
            const SizedBox(height: 16),

            // Document List
            ...List.generate(_documents.length, (index) {
              return _buildDocumentCard(_documents[index]);
            }),

            // Rejection reason if rejected
            if (_verificationStatus == 'rejected' && _rejectionReason != null)
              _buildRejectionCard(),

            const SizedBox(height: 24),

            // Submit Button
            if (_verificationStatus != 'approved')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSubmit() ? _submitForVerification : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SellerColors.primaryLight,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _verificationStatus == 'pending'
                        ? 'Verification in Progress'
                        : 'Submit for Verification',
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

  bool _canSubmit() {
    // Check if all required documents are uploaded
    return _documents.every((doc) => doc.status != 'not_submitted') &&
        _verificationStatus != 'pending';
  }

  void _submitForVerification() {
    // TODO: Implement submission
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Documents submitted for verification'),
        backgroundColor: CommonColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (_verificationStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        statusText = 'Verification Pending';
        statusDescription =
            'Your documents are under review. This usually takes 24-48 hours.';
        break;
      case 'approved':
        statusColor = CommonColors.success;
        statusIcon = Icons.verified;
        statusText = 'Verified Seller';
        statusDescription = 'Congratulations! Your account is fully verified.';
        break;
      case 'rejected':
        statusColor = CommonColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Verification Rejected';
        statusDescription =
            'Please review the rejection reason and resubmit your documents.';
        break;
      default:
        statusColor = CommonColors.greyText;
        statusIcon = Icons.pending_actions;
        statusText = 'Not Verified';
        statusDescription =
            'Upload all required documents to start verification.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CommonColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CommonColors.greyText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final approvedCount = _documents
        .where((d) => d.status == 'approved')
        .length;
    final totalCount = _documents.length;
    final progress = approvedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Document Progress',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CommonColors.black,
                ),
              ),
              Text(
                '$approvedCount/$totalCount Verified',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SellerColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(SellerColors.primaryLight),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(_DocumentItem doc) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (doc.status) {
      case 'approved':
        statusColor = CommonColors.success;
        statusText = 'Verified';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_top;
        break;
      case 'rejected':
        statusColor = CommonColors.error;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = CommonColors.greyText;
        statusText = 'Not Uploaded';
        statusIcon = Icons.upload_file;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: doc.status == 'approved'
              ? CommonColors.success.withValues(alpha: 0.3)
              : doc.status == 'rejected'
              ? CommonColors.error.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Document Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SellerColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(doc.icon, size: 24, color: SellerColors.primaryLight),
          ),
          const SizedBox(width: 16),

          // Document Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.docType,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.black,
                  ),
                ),
                if (doc.docNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    doc.docNumber!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          // Upload Button if not submitted
          if (doc.status == 'not_submitted' || doc.status == 'rejected') ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _uploadDocument(doc.docType),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SellerColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.upload_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectionCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CommonColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CommonColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: CommonColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejection Reason',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CommonColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _rejectionReason ?? 'Documents could not be verified.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CommonColors.error.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _uploadDocument(String docType) {
    // TODO: Implement document upload
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
              'Upload $docType',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(context);
                }),
                _buildUploadOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(context);
                }),
                _buildUploadOption(Icons.description, 'Document', () {
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SellerColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: SellerColors.primaryLight),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: CommonColors.black),
          ),
        ],
      ),
    );
  }
}

class _DocumentItem {
  final String docType;
  final String? docNumber;
  final String status;
  final IconData icon;

  _DocumentItem({
    required this.docType,
    this.docNumber,
    required this.status,
    required this.icon,
  });
}

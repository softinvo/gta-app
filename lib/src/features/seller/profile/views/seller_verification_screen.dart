import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/features/seller/profile/controller/seller_profile_controller.dart';
import 'package:gta_app/src/models/attachment_model.dart';
import 'package:gta_app/src/models/document_model.dart';
import 'package:gta_app/src/models/seller_model.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/snackbar_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Metadata + per-doc form state
// ─────────────────────────────────────────────────────────────────────────────

class _DocMeta {
  final String type;
  final IconData icon;
  const _DocMeta(this.type, this.icon);
}

const _requiredDocs = [
  _DocMeta('PAN Card', Icons.credit_card_rounded),
  _DocMeta('GST Certificate', Icons.receipt_long_rounded),
  _DocMeta('Business License', Icons.description_rounded),
  _DocMeta('Address Proof', Icons.location_on_rounded),
];

class _DocFormState {
  final TextEditingController numberCtrl;
  Attachment? existingImage;
  Attachment? newAttachment;
  File? localFile;
  bool isUploading;

  _DocFormState({
    String initialNumber = '',
    this.existingImage,
    this.isUploading = false,
  }) : numberCtrl = TextEditingController(text: initialNumber);

  Attachment? get effectiveAttachment => newAttachment ?? existingImage;

  bool get isComplete =>
      numberCtrl.text.trim().isNotEmpty && effectiveAttachment != null;

  void dispose() => numberCtrl.dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SellerVerificationScreen extends ConsumerStatefulWidget {
  const SellerVerificationScreen({super.key});

  static const routePath = '/seller/profile/verification';

  @override
  ConsumerState<SellerVerificationScreen> createState() =>
      _SellerVerificationScreenState();
}

class _SellerVerificationScreenState
    extends ConsumerState<SellerVerificationScreen> {
  late final Map<String, _DocFormState> _docStates;
  bool _isPopulated = false;
  bool _isSubmitting = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _docStates = {
      for (final d in _requiredDocs) d.type: _DocFormState(),
    };
  }

  @override
  void dispose() {
    for (final s in _docStates.values) {
      s.dispose();
    }
    super.dispose();
  }

  void _populateFromSeller(Seller seller) {
    for (final doc in seller.documents) {
      final s = _docStates[doc.docType];
      if (s == null) continue;
      s.numberCtrl.text = doc.docNumber ?? '';
      s.existingImage = doc.docImage;
    }
    _isPopulated = true;
  }

  bool get _canSubmit => _docStates.values.every((s) => s.isComplete);

  Future<void> _pickAndUpload(String docType, ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null || !mounted) return;

    final localFile = File(xFile.path);
    setState(() {
      _docStates[docType]!.localFile = localFile;
      _docStates[docType]!.isUploading = true;
    });

    final result = await ref
        .read(sellerProfileProvider.notifier)
        .uploadDocFile(localFile);

    if (!mounted) return;

    result.fold(
      (error) {
        setState(() {
          _docStates[docType]!.localFile = null;
          _docStates[docType]!.isUploading = false;
        });
        SnackBarService.showError(context, error);
      },
      (attachment) {
        setState(() {
          _docStates[docType]!.newAttachment = attachment;
          _docStates[docType]!.isUploading = false;
        });
      },
    );
  }

  Future<void> _submit() async {
    final docs = _docStates.entries.map((e) {
      return {
        'docType': e.key,
        'docNumber': e.value.numberCtrl.text.trim(),
        'docImage': e.value.effectiveAttachment!.toJson(),
      };
    }).toList();

    setState(() => _isSubmitting = true);

    final error = await ref
        .read(sellerProfileProvider.notifier)
        .submitVerificationDocuments(docs);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      SnackBarService.showSuccess(context, 'Documents submitted for verification');
    } else {
      SnackBarService.showError(context, error);
    }
  }

  void _showPickerSheet(String docType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        docType: docType,
        onSource: (source) {
          Navigator.pop(context);
          _pickAndUpload(docType, source);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellerAsync = ref.watch(sellerProfileProvider);

    sellerAsync.whenData((seller) {
      if (seller != null && !_isPopulated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _populateFromSeller(seller));
        });
      }
    });

    final seller = sellerAsync.asData?.value;
    final status = seller?.verificationStatus ?? VerificationStatus.notSubmitted;

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: const SellerAppBar(
        title: 'Verification',
        showLogo: false,
        centerTitle: true,
      ),
      body: sellerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          switch (status) {
            case VerificationStatus.approved:
              return _ApprovedBody(seller: seller);
            case VerificationStatus.pending:
              return _PendingBody(seller: seller);
            default:
              return _FormBody(
                seller: seller,
                status: status,
                docStates: _docStates,
                isSubmitting: _isSubmitting,
                canSubmit: _canSubmit,
                onUploadTap: _showPickerSheet,
                onSubmit: _submit,
              );
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Approved body
// ─────────────────────────────────────────────────────────────────────────────

class _ApprovedBody extends StatelessWidget {
  final Seller? seller;
  const _ApprovedBody({this.seller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero verified card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF43A047).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Account Verified',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your business is verified on GTA Marketplace.\nYou can now sell and receive payouts.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Verified Documents',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ..._requiredDocs.map(
            (meta) => _SubmittedDocCard(
              meta: meta,
              doc: seller?.getDocument(meta.type),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending body
// ─────────────────────────────────────────────────────────────────────────────

class _PendingBody extends StatelessWidget {
  final Seller? seller;
  const _PendingBody({this.seller});

  @override
  Widget build(BuildContext context) {
    final approvedCount = _requiredDocs
        .where((m) => seller?.getDocument(m.type)?.status.value == 'approved')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCard(status: VerificationStatus.pending),
          const SizedBox(height: 16),
          _ProgressCard(approved: approvedCount, total: _requiredDocs.length),
          const SizedBox(height: 16),
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF57F17).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_clock_rounded,
                  color: Color(0xFFF57F17),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Documents are under review. You cannot make changes until admin completes the verification.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFF57F17),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Submitted Documents',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          ..._requiredDocs.map(
            (meta) => _SubmittedDocCard(
              meta: meta,
              doc: seller?.getDocument(meta.type),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form body (not_submitted + rejected)
// ─────────────────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  final Seller? seller;
  final VerificationStatus status;
  final Map<String, _DocFormState> docStates;
  final bool isSubmitting;
  final bool canSubmit;
  final void Function(String) onUploadTap;
  final VoidCallback onSubmit;

  const _FormBody({
    required this.seller,
    required this.status,
    required this.docStates,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onUploadTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCard(status: status),
          const SizedBox(height: 16),
          if (status == VerificationStatus.rejected &&
              seller?.rejectionReason != null) ...[
            _RejectionCard(reason: seller!.rejectionReason!),
            const SizedBox(height: 16),
          ],
          Text(
            status == VerificationStatus.rejected
                ? 'Update Documents'
                : 'Required Documents',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status == VerificationStatus.rejected
                ? 'Update and resubmit the documents that were rejected'
                : 'Upload a clear image of each document',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 12),
          ..._requiredDocs.map(
            (meta) => _DocumentFormCard(
              meta: meta,
              docState: docStates[meta.type]!,
              serverStatus: seller?.getDocument(meta.type)?.status.value,
              onUploadTap: () => onUploadTap(meta.type),
            ),
          ),
          const SizedBox(height: 8),
          _SubmitButton(
            canSubmit: canSubmit && !isSubmitting,
            isSubmitting: isSubmitting,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submitted doc card (read-only — used in pending + approved views)
// ─────────────────────────────────────────────────────────────────────────────

class _SubmittedDocCard extends StatelessWidget {
  final _DocMeta meta;
  final Document? doc;

  const _SubmittedDocCard({required this.meta, this.doc});

  @override
  Widget build(BuildContext context) {
    final String? docNumber = doc?.docNumber;
    final Attachment? docImage = doc?.docImage;
    final String? statusVal = doc?.status.value;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (statusVal) {
      case 'approved':
        statusColor = const Color(0xFF43A047);
        statusLabel = 'Verified';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFF57F17);
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        statusColor = CommonColors.error;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = CommonColors.greyText;
        statusLabel = 'Not Uploaded';
        statusIcon = Icons.upload_file_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusVal == 'approved'
              ? const Color(0xFF43A047).withValues(alpha: 0.2)
              : statusVal == 'rejected'
                  ? CommonColors.error.withValues(alpha: 0.2)
                  : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SellerColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, size: 20, color: SellerColors.primaryLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.type,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
                if (docNumber != null && docNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    docNumber,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CommonColors.greyText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (docImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                docImage.fileUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: SellerColors.surface,
                  child: Icon(
                    Icons.insert_drive_file_rounded,
                    color: SellerColors.primaryLight,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 3),
                Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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

// ─────────────────────────────────────────────────────────────────────────────
// Document form card (editable — used in form body)
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentFormCard extends StatelessWidget {
  final _DocMeta meta;
  final _DocFormState docState;
  final String? serverStatus;
  final VoidCallback onUploadTap;

  const _DocumentFormCard({
    required this.meta,
    required this.docState,
    required this.serverStatus,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (serverStatus) {
      case 'approved':
        statusColor = const Color(0xFF43A047);
        statusLabel = 'Verified';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFF57F17);
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        statusColor = CommonColors.error;
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = CommonColors.greyText;
        statusLabel = 'Not Uploaded';
        statusIcon = Icons.upload_file_rounded;
    }

    final hasPreview =
        docState.localFile != null || docState.effectiveAttachment != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: serverStatus == 'approved'
              ? const Color(0xFF43A047).withValues(alpha: 0.25)
              : serverStatus == 'rejected'
                  ? CommonColors.error.withValues(alpha: 0.25)
                  : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SellerColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  meta.icon,
                  size: 20,
                  color: SellerColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meta.type,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C1C1E),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 3),
                    Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: docState.numberCtrl,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF1C1C1E),
            ),
            decoration: InputDecoration(
              hintText: 'Document number',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: CommonColors.greyText,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: SellerColors.primaryLight,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasPreview) ...[
                _Thumbnail(
                  localFile: docState.localFile,
                  remoteUrl: docState.effectiveAttachment?.fileUrl,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _UploadButton(
                  hasExisting: hasPreview,
                  isUploading: docState.isUploading,
                  onTap: onUploadTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thumbnail
// ─────────────────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  final File? localFile;
  final String? remoteUrl;
  const _Thumbnail({this.localFile, this.remoteUrl});

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (localFile != null) {
      child = Image.file(
        localFile!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else if (remoteUrl != null) {
      child = Image.network(
        remoteUrl!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      child = _fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: child,
    );
  }

  Widget _fallback() {
    return Container(
      width: 64,
      height: 64,
      color: SellerColors.surface,
      child: Icon(
        Icons.insert_drive_file_rounded,
        color: SellerColors.primaryLight,
        size: 28,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload button
// ─────────────────────────────────────────────────────────────────────────────

class _UploadButton extends StatelessWidget {
  final bool hasExisting;
  final bool isUploading;
  final VoidCallback onTap;

  const _UploadButton({
    required this.hasExisting,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        hasExisting ? CommonColors.greyText : SellerColors.primaryLight;
    final bg = hasExisting
        ? Colors.grey.shade50
        : SellerColors.primaryLight.withValues(alpha: 0.08);
    final borderColor = hasExisting
        ? Colors.grey.shade200
        : SellerColors.primaryLight.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isUploading ? Colors.grey.shade50 : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUploading ? Colors.grey.shade200 : borderColor,
          ),
        ),
        child: isUploading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasExisting
                        ? Icons.refresh_rounded
                        : Icons.upload_rounded,
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasExisting ? 'Replace Image' : 'Upload Image',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image source picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final String docType;
  final void Function(ImageSource) onSource;

  const _PickerSheet({required this.docType, required this.onSource});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Upload $docType',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose image source',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _PickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => onSource(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => onSource(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: SellerColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: SellerColors.primaryLight),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit button
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitButton({
    required this.canSubmit,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canSubmit ? onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: SellerColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: CommonColors.greyText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'Submit for Verification',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status card
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final VerificationStatus status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    switch (status) {
      case VerificationStatus.pending:
        color = const Color(0xFFF57F17);
        icon = Icons.hourglass_top_rounded;
        title = 'Under Review';
        subtitle =
            'Your documents are being reviewed. This usually takes 24–48 hours.';
        break;
      case VerificationStatus.rejected:
        color = const Color(0xFFC62828);
        icon = Icons.cancel_rounded;
        title = 'Verification Rejected';
        subtitle =
            'Please review the reason below and re-upload the required documents.';
        break;
      default:
        color = CommonColors.greyText;
        icon = Icons.pending_actions_rounded;
        title = 'Not Verified';
        subtitle =
            'Upload all required documents to start the verification process.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress card
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final int approved;
  final int total;
  const _ProgressCard({required this.approved, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : approved / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1C1E),
                ),
              ),
              Text(
                '$approved / $total verified',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SellerColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor:
                  AlwaysStoppedAnimation<Color>(SellerColors.primaryLight),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rejection card
// ─────────────────────────────────────────────────────────────────────────────

class _RejectionCard extends StatelessWidget {
  final String reason;
  const _RejectionCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CommonColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CommonColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: CommonColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejection Reason',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CommonColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CommonColors.error.withValues(alpha: 0.85),
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
}

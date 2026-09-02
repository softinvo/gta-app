import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

class BuyerRateAppScreen extends StatefulWidget {
  const BuyerRateAppScreen({super.key});

  static const routePath = '/buyer/profile/rate-app';

  @override
  State<BuyerRateAppScreen> createState() => _BuyerRateAppScreenState();
}

class _BuyerRateAppScreenState extends State<BuyerRateAppScreen> {
  final _feedbackController = TextEditingController();
  int _rating = 0;
  bool _submitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _selectRating(int rating) {
    setState(() {
      _rating = rating;
      _submitted = false;
    });
  }

  void _submit() {
    if (_rating == 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: CommonColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.profileRateAppTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CommonColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _IntroCard(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BuyerColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    context.l10n.rateAppQuestion,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CommonColors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      final selected = value <= _rating;
                      return Semantics(
                        button: true,
                        selected: value == _rating,
                        label: '$value of 5 stars',
                        child: InkResponse(
                          onTap: () => _selectRating(value),
                          radius: 28,
                          child: AnimatedScale(
                            scale: value == _rating ? 1.12 : 1,
                            duration: const Duration(milliseconds: 160),
                            child: Icon(
                              selected
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 44,
                              color: selected
                                  ? const Color(0xFFF4B740)
                                  : const Color(0xFFD6D8DC),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _rating == 0
                          ? context.l10n.rateAppTapHint
                          : '$_rating / 5',
                      key: ValueKey(_rating),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _rating == 0
                            ? CommonColors.greyText
                            : BuyerColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BuyerColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.rateAppFeedbackLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CommonColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _feedbackController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 300,
                    onChanged: (_) {
                      if (_submitted) setState(() => _submitted = false);
                    },
                    decoration: InputDecoration(
                      hintText: context.l10n.rateAppFeedbackHint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: CommonColors.greyText,
                      ),
                      filled: true,
                      fillColor: BuyerColors.surfaceLight,
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: BuyerColors.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: BuyerColors.primaryLight,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _rating == 0 || _submitted ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: BuyerColors.primaryLight,
                  disabledBackgroundColor: _submitted
                      ? BuyerColors.surface
                      : const Color(0xFFD9DEDB),
                  disabledForegroundColor: _submitted
                      ? BuyerColors.primaryLight
                      : CommonColors.greyText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Row(
                    key: ValueKey(_submitted),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _submitted
                            ? Icons.check_circle_rounded
                            : Icons.send_rounded,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _submitted
                            ? context.l10n.rateAppThankYou
                            : context.l10n.rateAppSubmit,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BuyerColors.surfaceLight, Color(0xFFE1F2E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BuyerColors.primary, width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: BuyerColors.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: BuyerColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.rateAppHeading,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BuyerColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.rateAppDescription,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.4,
                    color: BuyerColors.textSecondary,
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

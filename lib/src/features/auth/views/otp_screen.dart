import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../res/colors.dart';
import '../../../commons/widgets/common_widgets.dart';
import '../../buyer/home/views/buyer_home_screen.dart';
import '../../seller/dashboard/views/seller_dashboard_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String userType;
  const OtpScreen({super.key, required this.phone, required this.userType});
  static const routePath = '/otp';

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 30;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) {
          _canResend = true;
        }
      });
      return _resendTimer > 0 && mounted;
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _verifyOTP() async {
    if (_otpController.text.length != 6) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      // Navigate based on user type
      if (widget.userType == 'buyer') {
        context.go(BuyerHomeScreen.routePath);
      } else {
        context.go(SellerDashboardScreen.routePath);
      }
    }
  }

  void _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    _startResendTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: AppColors.primaryBackgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = widget.userType == 'buyer';
    final accentColor = isBuyer
        ? const Color(0xFF4A90E2)
        : const Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBuyer
                            ? Icons.shopping_bag_outlined
                            : Icons.storefront_outlined,
                        size: 16,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isBuyer ? 'Buyer' : 'Seller',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Text(
                  'Verify Phone',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.greyTextColor,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a verification code to '),
                      TextSpan(
                        text: '+91 ${widget.phone}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // OTP Input
                Center(
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    autoFocus: true,
                    cursorColor: accentColor,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    animationDuration: const Duration(milliseconds: 200),
                    enableActiveFill: true,
                    textStyle: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 56,
                      fieldWidth: 48,
                      activeFillColor: accentColor.withValues(alpha: 0.1),
                      inactiveFillColor: AppColors.backgroudColor,
                      selectedFillColor: accentColor.withValues(alpha: 0.1),
                      activeColor: accentColor,
                      inactiveColor: Colors.grey.shade300,
                      selectedColor: accentColor,
                    ),
                    onCompleted: (value) => _verifyOTP(),
                    onChanged: (value) {},
                  ),
                ),

                const SizedBox(height: 32),

                // Resend section
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.greyTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _canResend ? _resendOTP : null,
                        child: Text(
                          _canResend
                              ? 'Resend OTP'
                              : 'Resend in ${_resendTimer}s',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _canResend
                                ? accentColor
                                : AppColors.greyTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Verify button
                PrimaryButton(
                  text: 'Verify & Continue',
                  onPressed: _otpController.text.length == 6
                      ? _verifyOTP
                      : null,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

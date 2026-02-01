import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/commons/widgets/phone_input_textfield.dart';
import 'package:gta_app/src/features/common_features/auth/views/widgets/continue_button.dart';
import 'package:gta_app/src/features/common_features/auth/views/widgets/google_sign_in_button.dart';
import 'package:gta_app/src/features/common_features/auth/views/widgets/user_type_toggle.dart';
import 'package:gta_app/src/res/assets.dart';
import 'package:gta_app/src/features/common_features/auth/controller/auth_controller.dart';
import '../../../../res/colors.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _userType = 'buyer';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text;
    final success = await ref
        .read(sendOtpStateProvider.notifier)
        .sendOTP(phone: phone, userType: _userType);

    if (success && mounted) {
      context.push(
        OtpScreen.routePath,
        extra: {'phone': phone, 'userType': _userType},
      );
    } else if (mounted) {
      final error = ref.read(sendOtpStateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isBuyer = _userType == 'buyer';
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: CommonColors.lightPrimaryColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// LOGO SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.55,
                          height: MediaQuery.of(context).size.width * 0.55,
                          child: Image.asset(
                            ImageAssets.logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: CommonColors.white.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    'GTA',
                                    style: GoogleFonts.poppins(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: CommonColors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// FORM SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          /// WELCOME
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isBuyer
                                      ? BuyerColors.surface
                                      : SellerColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.waving_hand,
                                  color: isBuyer
                                      ? BuyerColors.primaryLight
                                      : SellerColors.primaryLight,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Sign in to continue',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: CommonColors.greyText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          /// USER TYPE
                          UserTypeToggle(
                            selectedType: _userType,
                            onChanged: (type) {
                              HapticFeedback.lightImpact();
                              setState(() => _userType = type);
                            },
                          ),

                          const SizedBox(height: 20),

                          /// PHONE INPUT
                          Text(
                            'Phone Number',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: CommonColors.greyText,
                            ),
                          ),
                          const SizedBox(height: 8),

                          PhoneInputField(controller: _phoneController),

                          const SizedBox(height: 24),

                          /// CONTINUE BUTTON
                          Consumer(
                            builder: (context, ref, child) {
                              final sendOtpState = ref.watch(
                                sendOtpStateProvider,
                              );
                              return ContinueButton(
                                userType: _userType,
                                isLoading: sendOtpState.isLoading,
                                onPressed: _sendOTP,
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: CommonColors.greyText,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          GoogleSignInButton(onTap: () {}),
                          const SizedBox(height: 24),

                          Center(
                            child: Text(
                              'By continuing, you agree to our Terms & Privacy Policy',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: CommonColors.greyText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

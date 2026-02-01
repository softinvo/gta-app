import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/res/assets.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/features/common_features/auth/controller/auth_controller.dart';
import 'package:gta_app/src/features/buyer/home/views/buyer_home_screen.dart';
import 'package:gta_app/src/features/seller/dashboard/views/seller_dashboard_screen.dart';
import 'package:gta_app/src/features/common_features/auth/views/login_screen.dart';

class Splashscreen extends ConsumerStatefulWidget {
  const Splashscreen({super.key});
  static const routePath = '/splashscreen';

  @override
  ConsumerState<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends ConsumerState<Splashscreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Navigate after delay
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final isAuthenticated = await ref.read(isAuthenticatedProvider.future);

      if (isAuthenticated) {
        final userType = await ref.read(userTypeProvider.future);
        if (userType == 'buyer') {
          context.go(BuyerHomeScreen.routePath);
        } else {
          context.go(SellerDashboardScreen.routePath);
        }
      } else {
        context.go(LoginScreen.routePath);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background element
            Positioned(
              top: -width * 0.2,
              right: -width * 0.2,
              child: Container(
                width: width * 0.6,
                height: width * 0.6,
                decoration: BoxDecoration(
                  color: BuyerColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -width * 0.1,
              left: -width * 0.1,
              child: Container(
                width: width * 0.4,
                height: width * 0.4,
                decoration: BoxDecoration(
                  color: BuyerColors.primary.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            SizedBox(
                              width: width * 0.5,
                              height: width * 0.5,
                              child: Image.asset(
                                ImageAssets.logo,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.business,
                                    size: 80,
                                    color: BuyerColors.primary,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Tagline
                            Text(
                              'Your Textile Marketplace',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: BuyerColors.primary.withValues(
                                  alpha: 0.7,
                                ),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 80),

                            // Loading indicator
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  BuyerColors.primary.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

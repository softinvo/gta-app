import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gta_app/src/commons/views/splashscreen.dart';
import 'package:gta_app/src/features/auth/views/login_screen.dart';
import 'package:gta_app/src/features/auth/views/otp_screen.dart';
import 'package:gta_app/src/features/buyer/home/views/buyer_home_screen.dart';
import 'package:gta_app/src/features/seller/dashboard/views/seller_dashboard_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: Splashscreen.routePath,
  routes: [
    // Splash Screen
    GoRoute(
      path: Splashscreen.routePath,
      builder: (context, state) => const Splashscreen(),
    ),

    // Auth Routes
    GoRoute(
      path: LoginScreen.routePath,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: OtpScreen.routePath,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        // If no extra data, redirect to login
        if (extra == null || extra['phone'] == null) {
          return const LoginScreen();
        }
        return OtpScreen(
          phone: extra['phone'] as String,
          userType: extra['userType'] as String? ?? 'buyer',
        );
      },
    ),

    // Buyer Routes
    GoRoute(
      path: BuyerHomeScreen.routePath,
      builder: (context, state) => const BuyerHomeScreen(),
    ),

    // Seller Routes
    GoRoute(
      path: SellerDashboardScreen.routePath,
      builder: (context, state) => const SellerDashboardScreen(),
    ),
  ],
);

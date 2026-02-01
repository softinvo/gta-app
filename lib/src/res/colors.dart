import 'package:flutter/material.dart';

/// Common colors shared across all themes
class CommonColors {
  CommonColors._();

  // Neutrals
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color lightPrimaryColor = Color(0xFFE8F5E9);
  static const Color greyBackground = Color(0xFFF4F6F9);
  static const Color greyText = Color(0xFF7D7F88);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF424242);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Accent Colors
  static const Color starColor = Color(0xFFF1D01F);
}

/// Buyer Theme - Green Color Palette
/// Use this theme for all buyer-related screens and components
class BuyerColors {
  BuyerColors._();

  // Primary Colors
  static const Color primary = Color(0xFF014C2D);
  static const Color primaryLight = Color(0xFF47A374);
  static const Color primaryDark = Color(0xFF003D24);

  // Surface Colors
  static const Color surface = Color(0xFFEDF7EF);
  static const Color surfaceLight = Color(0xFFF5FBF6);
  static const Color background = Color(0xFFF4F6F9);

  // Accent Colors
  static const Color accent = Color(0xFF68A47E);
  static const Color accentLight = Color(0xFFA5D6A7);

  // Text Colors
  static const Color textPrimary = Color(0xFF1B5E20);
  static const Color textSecondary = Color(0xFF4E7D5B);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF47A374);
  static const Color buttonSecondary = Color(0xFFE8F5E9);
  static const Color buttonText = Colors.white;

  // Card Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE8F5E9);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF47A374), Color(0xFF014C2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Seller Theme - Blue/Indigo Color Palette
/// Use this theme for all seller-related screens and components
class SellerColors {
  SellerColors._();

  // Primary Colors
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3F51B5);
  static const Color primaryDark = Color(0xFF0D1642);

  // Surface Colors
  static const Color surface = Color(0xFFE8EAF6);
  static const Color surfaceLight = Color(0xFFF5F5FC);
  static const Color background = Color(0xFFF4F6F9);

  // Accent Colors
  static const Color accent = Color(0xFF5C6BC0);
  static const Color accentLight = Color(0xFF9FA8DA);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A237E);
  static const Color textSecondary = Color(0xFF5C6BC0);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF3F51B5);
  static const Color buttonSecondary = Color(0xFFE8EAF6);
  static const Color buttonText = Colors.white;

  // Card Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE8EAF6);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

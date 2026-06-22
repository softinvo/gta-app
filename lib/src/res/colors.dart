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
  static const Color primaryLight = Color(0xFF1A7A4F);
  static const Color primaryDark = Color(0xFF012B18);

  // Surface Colors
  static const Color surface = Color(0xFFEDF7EF);
  static const Color surfaceLight = Color(0xFFF5FBF6);
  static const Color background = Color(0xFFF5FBF6);

  // Accent Colors
  static const Color accent = Color(0xFF1A7A4F);
  static const Color accentLight = Color(0xFFA5D6A7);

  // Text Colors
  static const Color textPrimary = Color(0xFF1B5E20);
  static const Color textSecondary = Color(0xFF4E7D5B);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF1A7A4F);
  static const Color buttonSecondary = Color(0xFFE8F5E9);
  static const Color buttonText = Colors.white;

  // Card Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE8F5E9);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A7A4F), Color(0xFF014C2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Product Grid Card tokens ──────────────────────────────────────────
  static const Color gridCardBg = Color(0xFFFAFAF8);
  static const Color gridCardBorder = Color(0xFFEAE6E0);
  static const Color gridCardInfoBg = Color(0xFFF7F5F2);
  static const Color gridCardDivider = Color(0xFFEAE6E0);

  static const Color gridCardTextPrimary = Color(0xFF1E2A3A);
  static const Color gridCardTextMuted = Color(0xFF4A3F35);
  static const Color gridCardTextHint = Color(0xFF6B5E52);

  // Price / star accent – amber/gold
  static const Color gridCardAmber = Color(0xFFC9842A);
  static const Color gridCardAmberLight = Color(0xFFFDF3E7);
  static const Color gridCardAmberDark = Color(0xFFA06820);

  // Section badge pill colours (semi-opaque)
  static const Color gridBadgeNew = Color(0xEBC9842A);
  static const Color gridBadgeSale = Color(0xEBC94040);
  static const Color gridBadgeTop = Color(0xEB1E5C40);

  // Heart button
  static const Color gridHeartSaved = Color(0xFFFCEBEB);
  static const Color gridHeartRed = Color(0xFFC94040);
}

/// Verification / stock status color tokens
/// Dot = icon & border  |  Bg = badge fill  |  Text = label
class StatusColors {
  StatusColors._();

  // Pending (amber)
  static const Color pendingDot = Color(0xFFFFA726);
  static const Color pendingBg = Color(0xFFFFF8E1);
  static const Color pendingText = Color(0xFF7A4A00);

  // Verified / In-stock (green)
  static const Color verifiedDot = Color(0xFF4CAF50);
  static const Color verifiedBg = Color(0xFFE8F5E9);
  static const Color verifiedText = Color(0xFF1B5E20);

  // Rejected / Out-of-stock (red)
  static const Color rejectedDot = Color(0xFFE53935);
  static const Color rejectedBg = Color(0xFFFFEBEE);
  static const Color rejectedText = Color(0xFF7F1B1B);
}

/// Seller Theme - Blue/Indigo Color Palette
/// Use this theme for all seller-related screens and components
class SellerColors {
  SellerColors._();

  // Primary Colors
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3F51B5);
  static const Color primaryDark = Color(0xFF0D1642);

  // Surface & Background Colors
  static const Color surface = Color(0xFFE8EAF6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF0F2FB);

  // Accent Colors
  static const Color accent = Color(0xFF5C6BC0);
  static const Color accentLight = Color(0xFF9FA8DA);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A237E);
  static const Color textSecondary = Color(0xFF5C6BC0);
  static const Color textLabel = Color(0xFF5C6580);

  // Form / TextField Colors
  static const Color fieldBorder = Color(0xFFD8DCEF);
  static const Color fieldDisabledBorder = Color(0xFFECEEF8);
  static const Color fieldFill = Color(0xFFFFFFFF);
  static const Color fieldDisabledFill = Color(0xFFF7F8FD);
  static const Color fieldIconBg = Color(0xFFEEF0FB);

  // Card Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE8EAF6);
  static const Color cardDivider = Color(0xFFF0F2FA);
  static const Color sectionIconBg = Color(0xFFE5E8F8);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF3F51B5);
  static const Color buttonSecondary = Color(0xFFE8EAF6);
  static const Color buttonText = Colors.white;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF1A237E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';
import 'package:gta_app/src/res/colors.dart';

class QuoteUIHelpers {
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF1C40F);
      case 'submitted':
        return SellerColors.primaryLight;
      case 'in-progress':
      case 'negotiating':
      case 'negotiation':
        return const Color(0xFFE67E22);
      case 'agreed':
      case 'completed':
      case 'paid':
        return const Color(0xFF27AE60);
      case 'open':
        return SellerColors.primary;
      case 'accepted':
        return const Color(0xFF27AE60);
      case 'rejected':
      case 'cancelled':
        return CommonColors.error;
      default:
        return CommonColors.greyText;
    }
  }

  static Color parseColor(String colorCode) {
    try {
      if (colorCode.startsWith('#')) {
        return Color(int.parse(colorCode.replaceAll('#', '0xFF')));
      }
      if (colorCode.length == 6 &&
          RegExp(r'^[0-9a-fA-F]+$').hasMatch(colorCode)) {
        return Color(int.parse('0xFF$colorCode'));
      }
      return Colors.transparent;
    } catch (_) {
      return Colors.transparent;
    }
  }
}

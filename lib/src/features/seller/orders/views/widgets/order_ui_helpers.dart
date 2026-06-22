import 'package:flutter/material.dart';
import 'package:gta_app/src/res/colors.dart';

class OrderUIHelpers {
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF1C40F);
      case 'processing':
        return const Color(0xFFE67E22);
      case 'packed':
        return const Color(0xFF9B59B6);
      case 'shipped':
        return const Color(0xFF3498DB);
      case 'delivered':
        return const Color(0xFF27AE60);
      case 'cancelled':
        return CommonColors.error;
      default:
        return CommonColors.greyText;
    }
  }

  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Processing';
      case 'packed':
        return 'Packed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color getPaymentColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF27AE60);
      case 'pending':
        return const Color(0xFFE67E22);
      case 'failed':
        return CommonColors.error;
      case 'refunded':
        return const Color(0xFF8E44AD);
      case 'cancelled':
        return CommonColors.error;
      default:
        return CommonColors.greyText;
    }
  }

  static String getPaymentLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':     return 'Paid';
      case 'pending':  return 'Pending';
      case 'failed':   return 'Failed';
      case 'refunded': return 'Refunded';
      case 'cancelled': return 'Cancelled';
      default:         return status;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Icons.sync;
      case 'packed':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

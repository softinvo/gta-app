import 'package:flutter/material.dart';

/// "#RRGGBB" (uppercase) for a Color — the format gta_colors expects.
String hexOfColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

/// Parses any "#RRGGBB" into its exact Color, or null if `code` isn't one.
/// Use this (not `GtaColors.byHex`) when you need the real picked color —
/// `byHex` only matches the ~100 named colors and misses a custom pick.
Color? tryParseHex(String? code) {
  if (code == null || !code.startsWith('#') || code.length < 7) return null;
  try {
    return Color(int.parse(code.replaceFirst('#', '0xFF')));
  } catch (_) {
    return null;
  }
}

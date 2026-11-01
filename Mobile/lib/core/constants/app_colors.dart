import 'package:flutter/material.dart';

/// App color palette matching Pasig City's official blue theme.
///
/// Primary: Pasig Navy Blue (#004080)
/// Accent: Pasig Cyan/Sky Blue (#0284C7)
/// Soft Backgrounds: Ice/Sky Blue (#E0F2FE)
class AppColors {
  // Pasig City Brand Colors (Blue Theme)
  static const Color primaryNavy = Color(0xFF004080);
  static const Color primaryDark = Color(0xFF002855);
  static const Color primaryBlue = Color(0xFF0284C7);
  static const Color primaryLight = Color(0xFF38BDF8);

  // Pasig Accent & Soft Blue Palette
  static const Color accentBlue = Color(0xFF0284C7);
  static const Color softBlue = Color(0xFFE0F2FE);
  static const Color blueTint = Color(0xFFF0F9FF);

  // Mapped aliases for backwards-compatibility across existing screens
  static const Color accentPink = Color(0xFF0284C7); // Pasig Accent Blue
  static const Color softPink = Color(0xFFE0F2FE);   // Pasig Soft Sky Blue
  static const Color pinkTint = Color(0xFFF0F9FF);   // Pasig Light Tint

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFE0F2FE);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}

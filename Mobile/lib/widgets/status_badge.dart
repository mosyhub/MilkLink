import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    final lower = status.toLowerCase();

    if (lower == 'eligible' || lower == 'accepted' || lower == 'verified' || lower == 'active') {
      bg = AppColors.successBg;
      fg = AppColors.success;
    } else if (lower == 'pending' || lower == 'review') {
      bg = AppColors.warningBg;
      fg = AppColors.warning;
    } else if (lower == 'ineligible' || lower == 'deferred' || lower == 'rejected') {
      bg = AppColors.errorBg;
      fg = AppColors.error;
    } else {
      bg = AppColors.infoBg;
      fg = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}



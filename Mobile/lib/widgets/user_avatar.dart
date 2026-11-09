import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? initial;
  final double radius;
  final Color backgroundColor;
  final Color textColor;

  const UserAvatar({
    Key? key,
    this.avatarUrl,
    this.initial,
    this.radius = 20,
    this.backgroundColor = AppColors.softBlue,
    this.textColor = AppColors.primaryBlue,
  }) : super(key: key);

  ImageProvider? _resolveImageProvider(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    }

    if (clean.startsWith('data:image')) {
      try {
        final commaIdx = clean.indexOf(',');
        if (commaIdx != -1) {
          final bytes = base64Decode(clean.substring(commaIdx + 1));
          return MemoryImage(bytes);
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolveImageProvider(avatarUrl);
    final letter = (initial != null && initial!.trim().isNotEmpty)
        ? initial!.trim()[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageProvider,
      // Swallow network errors so the letter fallback is shown instead of a crash
      onBackgroundImageError: imageProvider is NetworkImage ? (_, __) {} : null,
      child: imageProvider == null
          ? Text(
              letter,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            )
          : null,
    );
  }
}
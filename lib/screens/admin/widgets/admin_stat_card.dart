import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Colors;
import 'package:saedny/core/theme/app_colors.dart';

class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? semanticsLabel;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? '$title: $value',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

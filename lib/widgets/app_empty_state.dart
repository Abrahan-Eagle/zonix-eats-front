import 'package:flutter/material.dart';
import 'package:zonix_glasses/features/utils/app_colors.dart';

/// Shared empty-state widget with icon, message and optional action buttons.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppColors.secondaryText(context)),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText(context),
                ),
              ),
            ],
            if (primaryActionLabel != null && onPrimaryAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onPrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentButton(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(primaryActionLabel!, style: const TextStyle(fontSize: 16, color: AppColors.white)),
                ),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!, style: TextStyle(color: AppColors.secondaryText(context))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

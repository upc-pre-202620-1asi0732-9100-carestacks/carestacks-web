import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'care_badge.dart';
import 'care_card.dart';
import 'care_icon_bubble.dart';

class CareNotificationTile extends StatelessWidget {
  const CareNotificationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.badge,
    this.actionLabel,
    this.onActionTap,
    this.iconBackgroundColor = AppColors.primaryLight,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String timeLabel;
  final CareBadge? badge;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Color iconBackgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return CareCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CareIconBubble(
                icon: icon,
                size: 38,
                iconSize: 19,
                backgroundColor: iconBackgroundColor,
                iconColor: iconColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(title, style: AppTextStyles.titleMedium),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                color: AppColors.textSecondary,
                size: 17,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onActionTap,
                  child: Text(
                    actionLabel!,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

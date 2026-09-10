import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CareBadge extends StatelessWidget {
  const CareBadge({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.primaryLight,
    this.foregroundColor = AppColors.primaryDark,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: padding,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../layout/care_breakpoints.dart';
import '../theme/app_colors.dart';
import 'care_card.dart';
import 'care_icon_bubble.dart';

/// Estado vacío o sin permisos. Un solo componente para las cinco pantallas.
class CareEmptyState extends StatelessWidget {
  const CareEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.action,
    this.dense = false,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Widget? action;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      variant: CareCardVariant.quiet,
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: dense ? 22 : 34),
      child: Column(
        children: [
          CareIconBubble(
            icon: icon,
            size: dense ? 42 : 52,
            iconSize: dense ? 20 : 25,
            backgroundColor: AppColors.surface,
            iconColor: AppColors.iconMuted,
          ),
          const SizedBox(height: 14),
          if (title != null) ...[
            Text(title!, style: layout.cardTitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
          ],
          Text(message, style: layout.bodyMuted, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../layout/care_breakpoints.dart';
import '../theme/app_colors.dart';
import 'care_card.dart';

/// Cifra suelta del tablero. Bloque silencioso, no compite con la tarjeta
/// principal de la pantalla.
class CareStatTile extends StatelessWidget {
  const CareStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      variant: CareCardVariant.quiet,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: layout.metricValue.copyWith(color: color)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.meta.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

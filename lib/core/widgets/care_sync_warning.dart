import 'package:flutter/material.dart';

import '../layout/care_breakpoints.dart';
import '../theme/app_colors.dart';

/// Aviso de sincronización. Naranja de estado, no una tarjeta más.
class CareSyncWarning extends StatelessWidget {
  const CareSyncWarning({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.orangeLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.orangeDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: layout.body.copyWith(color: AppColors.orangeDark),
            ),
          ),
        ],
      ),
    );
  }
}

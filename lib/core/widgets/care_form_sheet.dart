import 'package:flutter/material.dart';

import '../layout/care_breakpoints.dart';
import '../theme/app_colors.dart';

/// Formularios: hoja inferior en teléfono, diálogo centrado en escritorio.
Future<void> careShowForm(
  BuildContext context, {
  required Widget child,
  double maxWidth = 540,
}) {
  if (CareLayout.of(context).isCompact) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => child,
    );
  }

  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../layout/care_breakpoints.dart';
import '../theme/app_colors.dart';

/// Encabezado de bloque. Caja normal, no mayusculas: la jerarquia la da el
/// peso y el color, no el grito.
class CareSectionTitle extends StatelessWidget {
  const CareSectionTitle(this.text, {super.key, this.trailing, this.count});

  final String text;

  /// Accion opcional alineada a la derecha del titulo.
  final Widget? trailing;

  /// Contador discreto junto al titulo, cuando el numero aporta.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.sectionTitle,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Text(
                  count.toString(),
                  style: layout.meta.copyWith(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

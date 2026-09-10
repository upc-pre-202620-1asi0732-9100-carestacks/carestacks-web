import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fila de datos separada por hairline. La usan Documentos y Diario.
class CareDataRow extends StatelessWidget {
  const CareDataRow({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.backgroundSoft,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class CareHairline extends StatelessWidget {
  const CareHairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: const Divider(height: 1, thickness: 1, color: AppColors.border),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Niveles de jerarquia. Evita que todo el tablero sea la misma tarjeta
/// blanca con la misma sombra.
enum CareCardVariant {
  /// Pieza principal de una pantalla. Borde en primaryLight y sombra propia.
  hero,

  /// Contenedor de trabajo. Borde de 1px, sin sombra.
  standard,

  /// Bloque secundario embebido: relleno frio, sin borde ni sombra.
  quiet,

  /// Sin contenedor visible. Para filas de datos separadas por hairline.
  flat,
}

class CareCard extends StatelessWidget {
  const CareCard({
    super.key,
    required this.child,
    this.variant = CareCardVariant.standard,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.elevation,
    this.backgroundColor,
    this.borderColor,
    this.selected = false,
  });

  final Widget child;
  final CareCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;
  final double? elevation;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool selected;

  double get _radius =>
      borderRadius ??
      switch (variant) {
        CareCardVariant.hero => 20,
        CareCardVariant.standard => 14,
        CareCardVariant.quiet => 12,
        CareCardVariant.flat => 10,
      };

  Color get _background =>
      backgroundColor ??
      switch (variant) {
        CareCardVariant.hero => AppColors.surface,
        CareCardVariant.standard => AppColors.surface,
        CareCardVariant.quiet => AppColors.backgroundSoft,
        CareCardVariant.flat => Colors.transparent,
      };

  Color? get _border {
    if (borderColor != null) return borderColor;
    if (selected) return AppColors.primary;
    return switch (variant) {
      CareCardVariant.hero => AppColors.primaryLight,
      CareCardVariant.standard => AppColors.border,
      CareCardVariant.quiet => null,
      CareCardVariant.flat => null,
    };
  }

  List<BoxShadow> get _shadows {
    if (elevation != null) {
      return [
        BoxShadow(
          color: AppColors.primaryDark.withAlpha(12),
          blurRadius: elevation! * 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
    if (variant != CareCardVariant.hero) return const [];
    return [
      BoxShadow(
        color: AppColors.primaryDark.withAlpha(20),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: AppColors.primaryDark.withAlpha(10),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(_radius);
    final Color? border = _border;

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: _shadows),
      child: Material(
        color: _background,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          hoverColor: AppColors.primaryLight.withAlpha(70),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: border == null
                  ? null
                  : Border.all(color: border, width: selected ? 1.5 : 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

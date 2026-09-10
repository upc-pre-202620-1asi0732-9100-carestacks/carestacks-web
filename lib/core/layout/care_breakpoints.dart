import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Tres anchos de trabajo:
/// - compact  (< 768): telefono. Bottom nav y una sola columna.
/// - medium   (768 - 1279): tablet. Sidebar en modo riel de iconos, dos columnas.
/// - expanded (>= 1280): escritorio. Sidebar con etiquetas y panel de detalle.
enum CareLayoutSize { compact, medium, expanded }

class CareLayout {
  const CareLayout._(this.width, this.size);

  factory CareLayout.fromWidth(double width) {
    final CareLayoutSize size;
    if (width < compactMax) {
      size = CareLayoutSize.compact;
    } else if (width < expandedMin) {
      size = CareLayoutSize.medium;
    } else {
      size = CareLayoutSize.expanded;
    }
    return CareLayout._(width, size);
  }

  static CareLayout of(BuildContext context) =>
      CareLayout.fromWidth(MediaQuery.sizeOf(context).width);

  static const double compactMax = 768;
  static const double expandedMin = 1280;

  final double width;
  final CareLayoutSize size;

  bool get isCompact => size == CareLayoutSize.compact;
  bool get isDesktop => !isCompact;
  bool get isExpanded => size == CareLayoutSize.expanded;

  /// El sidebar muestra etiquetas solo cuando hay ancho de sobra.
  bool get sideNavShowsLabels => isExpanded;

  /// El panel de detalle de la derecha aparece a partir de 1280.
  bool get hasRail => isExpanded;

  double get sideNavWidth => sideNavShowsLabels ? 248 : 76;
  double get railWidth => 336;

  double get gutter => switch (size) {
    CareLayoutSize.compact => 20,
    CareLayoutSize.medium => 28,
    CareLayoutSize.expanded => 36,
  };

  /// Separacion entre columnas de una grilla.
  double get columnGap => isCompact ? 14 : 20;

  /// Separacion vertical entre bloques de una pagina.
  double get blockGap => isCompact ? 22 : 28;

  double get contentMaxWidth => hasRail ? 960 : 1080;

  /// Columnas disponibles para las grillas de tarjetas del contenido central.
  int get gridColumns => switch (size) {
    CareLayoutSize.compact => 1,
    CareLayoutSize.medium => 2,
    CareLayoutSize.expanded => 3,
  };

  // --- Escala tipografica -------------------------------------------------
  // Escritorio baja los titulares y sube el cuerpo respecto del telefono:
  // un tablero denso se lee mejor con titulos contenidos.

  TextStyle get pageTitle => isCompact
      ? AppTextStyles.headlineLarge
      : AppTextStyles.headlineLarge.copyWith(fontSize: 28, height: 36 / 28);

  TextStyle get pageSubtitle =>
      (isCompact
              ? AppTextStyles.bodyLarge
              : AppTextStyles.bodyLarge.copyWith(fontSize: 15, height: 24 / 15))
          .copyWith(color: AppColors.textSecondary);

  TextStyle get sectionTitle => AppTextStyles.labelMedium.copyWith(
    fontSize: isCompact ? 14 : 13,
    color: AppColors.textSecondary,
  );

  TextStyle get cardTitle => isCompact
      ? AppTextStyles.titleMedium
      : AppTextStyles.titleMedium.copyWith(fontSize: 17, height: 24 / 17);

  TextStyle get body => isCompact
      ? AppTextStyles.bodyLarge
      : AppTextStyles.bodyLarge.copyWith(fontSize: 15, height: 24 / 15);

  TextStyle get bodyMuted => body.copyWith(color: AppColors.textSecondary);

  TextStyle get meta => AppTextStyles.bodySmall.copyWith(
    color: AppColors.textMuted,
    fontWeight: FontWeight.w500,
  );

  TextStyle get metricValue => AppTextStyles.headlineLarge
      .copyWith(fontSize: isCompact ? 30 : 28, height: 1.1)
      .tabular;

  TextStyle get timeValue => AppTextStyles.labelMedium
      .copyWith(fontSize: isCompact ? 14 : 13, color: AppColors.textPrimary)
      .tabular;
}

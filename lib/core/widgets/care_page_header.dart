import 'package:flutter/material.dart';

import '../layout/care_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Cabecera fija del area de contenido en escritorio.
class CarePageHeader extends StatelessWidget {
  const CarePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.notificationCount = 0,
    this.onNotificationsPressed,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final int notificationCount;
  final VoidCallback? onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(layout.gutter, 20, layout.gutter, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.pageTitle,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: layout.pageSubtitle,
                  ),
                ],
              ],
            ),
          ),
          for (final action in actions) ...[const SizedBox(width: 12), action],
          if (onNotificationsPressed != null) ...[
            const SizedBox(width: 12),
            CareNotificationsButton(
              count: notificationCount,
              onPressed: onNotificationsPressed!,
            ),
          ],
        ],
      ),
    );
  }
}

class CareNotificationsButton extends StatelessWidget {
  const CareNotificationsButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notificaciones',
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 21,
                  color: AppColors.primaryDark,
                ),
                if (count > 0)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Boton de accion principal de una cabecera. Compacto, sin ancho completo:
/// el boton de 56px de alto es una decision de telefono.
class CareHeaderButton extends StatelessWidget {
  const CareHeaderButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = CareHeaderButtonTone.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CareHeaderButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final bool filled = tone == CareHeaderButtonTone.primary;

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            fontSize: 14,
            color: filled ? AppColors.surface : AppColors.primaryDark,
          ),
        ),
      ],
    );

    if (!filled) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.surface,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: child,
    );
  }
}

enum CareHeaderButtonTone { primary, neutral }

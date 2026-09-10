import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'care_page_header.dart';

/// Barra superior de telefono. En escritorio la reemplaza [CarePageHeader].
class CareTopBar extends StatelessWidget {
  const CareTopBar({
    super.key,
    this.title = 'CareConnect',
    this.onMenuPressed,
    this.onNotificationsPressed,
    this.showMenu = true,
    this.showNotifications = true,
    this.notificationCount = 0,
  });

  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationsPressed;
  final bool showMenu;
  final bool showNotifications;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (showMenu)
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Menú',
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu, size: 25),
                  color: AppColors.primaryDark,
                ),
              )
            else
              const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            if (showNotifications && onNotificationsPressed != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CareNotificationsButton(
                  count: notificationCount,
                  onPressed: onNotificationsPressed!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

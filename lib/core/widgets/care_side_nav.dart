import 'package:flutter/material.dart';

import '../layout/care_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'care_bottom_nav_bar.dart';

/// Navegacion lateral fija. Con etiquetas en escritorio, en riel de iconos
/// en tablet. El bottom nav solo sobrevive por debajo de 768px.
class CareSideNav extends StatelessWidget {
  const CareSideNav({
    super.key,
    required this.currentDestination,
    required this.onDestinationSelected,
    required this.showLabels,
    required this.userName,
    required this.userRole,
    required this.onLogout,
    this.badges = const {},
  });

  final CareNavDestination currentDestination;
  final ValueChanged<CareNavDestination> onDestinationSelected;
  final bool showLabels;
  final String userName;
  final String userRole;
  final VoidCallback onLogout;
  final Map<CareNavDestination, int> badges;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final double horizontal = showLabels ? 16 : 14;

    return Container(
      width: layout.sideNavWidth,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSoft,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 26),
              child: _Brand(showLabels: showLabels),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                children: [
                  for (final destination in CareNavDestination.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _NavItem(
                        destination: destination,
                        selected: destination == currentDestination,
                        showLabel: showLabels,
                        badge: badges[destination] ?? 0,
                        onTap: () => onDestinationSelected(destination),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 18),
              child: _UserFooter(
                name: userName,
                role: userRole,
                showLabels: showLabels,
                onLogout: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.showLabels});

  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.favorite_rounded,
        size: 19,
        color: AppColors.surface,
      ),
    );

    if (!showLabels) return Center(child: mark);

    return Row(
      children: [
        mark,
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CareConnect',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 16,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'Portal de cuidado',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.showLabel,
    required this.badge,
    required this.onTap,
  });

  final CareNavDestination destination;
  final bool selected;
  final bool showLabel;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected
        ? AppColors.primaryDark
        : AppColors.textSecondary;

    final Widget content = Row(
      mainAxisAlignment: showLabel
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        Icon(
          selected ? destination.selectedIcon : destination.icon,
          size: 20,
          color: selected ? AppColors.primary : AppColors.iconMuted,
        ),
        if (showLabel) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
          if (badge > 0) _NavBadge(count: badge),
        ],
      ],
    );

    final Widget item = Material(
      color: selected ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.primaryLight.withAlpha(110),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 12 : 8,
            vertical: 11,
          ),
          child: content,
        ),
      ),
    );

    final Widget withIndicator = Stack(
      children: [
        item,
        if (selected)
          Positioned(
            left: 0,
            top: 9,
            bottom: 9,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        // En riel no cabe el número: un punto basta para avisar.
        if (!showLabel && badge > 0)
          Positioned(
            right: 9,
            top: 7,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiary,
                border: Border.all(color: AppColors.backgroundSoft, width: 1.5),
              ),
            ),
          ),
      ],
    );

    if (showLabel) return withIndicator;
    return Tooltip(message: destination.label, child: withIndicator);
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 9 ? '9+' : count.toString(),
        style: AppTextStyles.bodySmall
            .copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral,
            )
            .tabular,
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({
    required this.name,
    required this.role,
    required this.showLabels,
    required this.onLogout,
  });

  final String name;
  final String role;
  final bool showLabels;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        _initials(name),
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark),
      ),
    );

    if (!showLabels) {
      return Column(
        children: [
          Tooltip(message: name, child: avatar),
          const SizedBox(height: 6),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            color: AppColors.iconMuted,
          ),
        ],
      );
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(fontSize: 13),
              ),
              Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: onLogout,
          icon: const Icon(Icons.logout, size: 18),
          color: AppColors.iconMuted,
        ),
      ],
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2);
  if (words.isEmpty) return 'CC';
  return words.map((word) => word[0].toUpperCase()).join();
}

import 'package:flutter/material.dart';

import '../layout/care_breakpoints.dart';
import '../theme/app_colors.dart';
import 'care_bottom_nav_bar.dart';
import 'care_page_header.dart';
import 'care_side_nav.dart';
import 'care_top_bar.dart';

/// Chrome comun de las pantallas del portal.
///
/// Escritorio: sidebar fijo + cabecera fija + contenido + panel de detalle.
/// Telefono: barra superior + contenido + bottom nav.
class CareAppShell extends StatelessWidget {
  const CareAppShell({
    super.key,
    required this.destination,
    required this.onDestinationSelected,
    required this.title,
    required this.content,
    required this.userName,
    required this.userRole,
    required this.onLogout,
    required this.onNotificationsPressed,
    this.subtitle,
    this.actions = const [],
    this.rail,
    this.notificationCount = 0,
    this.navBadges = const {},
    this.compactBottom,
  });

  final CareNavDestination destination;
  final ValueChanged<CareNavDestination> onDestinationSelected;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Columna central. Maneja su propio scroll.
  final Widget content;

  /// Panel de la derecha. Solo se monta a partir de 1280px; por debajo, cada
  /// pantalla reubica ese contenido dentro de la columna central.
  final Widget? rail;

  final String userName;
  final String userRole;
  final VoidCallback onLogout;
  final VoidCallback onNotificationsPressed;
  final int notificationCount;
  final Map<CareNavDestination, int> navBadges;

  /// Barra fija al pie en telefono, por ejemplo la accion principal.
  final Widget? compactBottom;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    if (layout.isCompact) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              color: AppColors.backgroundSoft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CareTopBar(
                title: title,
                showMenu: false,
                notificationCount: notificationCount,
                onNotificationsPressed: onNotificationsPressed,
              ),
            ),
            Expanded(child: content),
            if (compactBottom != null)
              SafeArea(top: false, child: compactBottom!),
          ],
        ),
        bottomNavigationBar: CareBottomNavBar(
          currentDestination: destination,
          onDestinationSelected: onDestinationSelected,
        ),
      );
    }

    final Widget? rail = layout.hasRail ? this.rail : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareSideNav(
            currentDestination: destination,
            onDestinationSelected: onDestinationSelected,
            showLabels: layout.sideNavShowsLabels,
            userName: userName,
            userRole: userRole,
            onLogout: onLogout,
            badges: navBadges,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CarePageHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                  notificationCount: notificationCount,
                  onNotificationsPressed: onNotificationsPressed,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: layout.contentMaxWidth,
                            ),
                            child: content,
                          ),
                        ),
                      ),
                      if (rail != null)
                        Container(
                          width: layout.railWidth,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: rail,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Columna scrolleable con el padding de pagina ya resuelto.
class CarePageBody extends StatelessWidget {
  const CarePageBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.padding,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    final Widget list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            layout.gutter,
            layout.isCompact ? 20 : 28,
            layout.gutter,
            36,
          ),
      children: children,
    );

    if (onRefresh == null || !layout.isCompact) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// Panel de detalle de la derecha.
class CareRailPanel extends StatelessWidget {
  const CareRailPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 36),
      children: children,
    );
  }
}

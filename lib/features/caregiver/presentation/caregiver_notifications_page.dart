import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../data/caregiver_models.dart';
import 'caregiver_panels.dart';

/// Abre las notificaciones sin sacar al cuidador de su pantalla: panel
/// lateral en escritorio, ruta completa en teléfono.
Future<void> showCaregiverNotifications(
  BuildContext context, {
  required CaregiverDashboardData dashboard,
  required Future<void> Function(String invitationId) onAcceptInvitation,
  required Future<void> Function(String invitationId) onRejectInvitation,
  required Future<void> Function(String notificationId) onMarkAsRead,
}) {
  final panel = CaregiverNotificationsPanel(
    dashboard: dashboard,
    onAcceptInvitation: onAcceptInvitation,
    onRejectInvitation: onRejectInvitation,
    onMarkAsRead: onMarkAsRead,
  );

  if (CareLayout.of(context).isCompact) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundSoft,
            foregroundColor: AppColors.primaryDark,
            elevation: 0,
            title: Text(
              'Notificaciones',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
          body: panel,
        ),
      ),
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notificaciones',
    barrierColor: AppColors.neutral.withAlpha(64),
    transitionDuration: const Duration(milliseconds: 190),
    pageBuilder: (_, _, _) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.background,
        child: SizedBox(
          width: 420,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notificaciones',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: AppColors.iconMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const CareHairline(),
                Expanded(child: panel),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class CaregiverNotificationsPanel extends StatefulWidget {
  const CaregiverNotificationsPanel({
    super.key,
    required this.dashboard,
    required this.onAcceptInvitation,
    required this.onRejectInvitation,
    required this.onMarkAsRead,
  });

  final CaregiverDashboardData dashboard;
  final Future<void> Function(String invitationId) onAcceptInvitation;
  final Future<void> Function(String invitationId) onRejectInvitation;
  final Future<void> Function(String notificationId) onMarkAsRead;

  @override
  State<CaregiverNotificationsPanel> createState() =>
      _CaregiverNotificationsPanelState();
}

class _CaregiverNotificationsPanelState
    extends State<CaregiverNotificationsPanel> {
  final Set<String> _busyInvitationIds = {};
  final Set<String> _readNotificationIds = {};

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final invitations = widget.dashboard.invitations
        .where((invitation) => invitation.isPending)
        .toList();
    final notifications = widget.dashboard.notifications;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        layout.isCompact ? layout.gutter : 22,
        20,
        layout.isCompact ? layout.gutter : 22,
        32,
      ),
      children: [
        if (invitations.isNotEmpty) ...[
          CareSectionTitle('Invitaciones', count: invitations.length),
          const SizedBox(height: 12),
          for (final invitation in invitations) ...[
            InvitationCard(
              invitation: invitation,
              compactActions: true,
              busy: _busyInvitationIds.contains(invitation.id),
              onAccept: () => _handleInvitation(invitation.id, accept: true),
              onReject: () => _handleInvitation(invitation.id, accept: false),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 14),
        ],
        CareSectionTitle('Avisos', count: notifications.length),
        const SizedBox(height: 6),
        if (notifications.isEmpty)
          const CareEmptyState(
            dense: true,
            icon: Icons.notifications_none,
            message: 'No hay notificaciones sincronizadas todavía.',
          )
        else
          for (int index = 0; index < notifications.length; index++) ...[
            if (index > 0) const CareHairline(),
            _NotificationRow(
              notification: notifications[index],
              read:
                  _readNotificationIds.contains(notifications[index].id) ||
                  notifications[index].readAt != null,
              onMarkAsRead: () => _markAsRead(notifications[index].id),
            ),
          ],
      ],
    );
  }

  Future<void> _handleInvitation(
    String invitationId, {
    required bool accept,
  }) async {
    setState(() => _busyInvitationIds.add(invitationId));
    try {
      if (accept) {
        await widget.onAcceptInvitation(invitationId);
      } else {
        await widget.onRejectInvitation(invitationId);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busyInvitationIds.remove(invitationId));
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await widget.onMarkAsRead(notificationId);
    if (mounted) setState(() => _readNotificationIds.add(notificationId));
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.read,
    required this.onMarkAsRead,
  });

  final CareNotification notification;
  final bool read;
  final VoidCallback onMarkAsRead;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CareIconBubble(
            icon: _notificationIcon(notification),
            size: 36,
            iconSize: 18,
            backgroundColor: _priorityBackground(notification.priority),
            iconColor: _priorityForeground(notification.priority),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: layout.body.copyWith(
                          fontSize: 14,
                          fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!read)
                      Container(
                        margin: const EdgeInsets.only(top: 6, left: 8),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.tertiary,
                        ),
                      ),
                  ],
                ),
                if (notification.message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: layout.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      CareDateFormatters.relative(
                        notification.sentAt ?? notification.createdAt,
                      ),
                      style: layout.meta,
                    ),
                    const Spacer(),
                    if (!read)
                      TextButton(
                        onPressed: onMarkAsRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Marcar leído',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      CareBadge(
                        label: 'Leído',
                        backgroundColor: AppColors.statusReadBackground,
                        foregroundColor: AppColors.statusReadText,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _notificationIcon(CareNotification notification) {
  return switch (notification.type) {
    'ALERT' => Icons.warning_amber_outlined,
    'REMINDER' => Icons.schedule,
    'INVITATION' => Icons.shield_outlined,
    _ => Icons.notifications_none,
  };
}

Color _priorityBackground(String priority) {
  return switch (priority) {
    'CRITICAL' => AppColors.redLight,
    'HIGH' => AppColors.orangeLight,
    'MEDIUM' => AppColors.primaryLight,
    _ => AppColors.backgroundSoft,
  };
}

Color _priorityForeground(String priority) {
  return switch (priority) {
    'CRITICAL' => AppColors.redDark,
    'HIGH' => AppColors.orangeDark,
    'MEDIUM' => AppColors.primaryDark,
    _ => AppColors.iconMuted,
  };
}

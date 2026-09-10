import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../data/caregiver_models.dart';
import 'caregiver_panels.dart';
import 'caregiver_ui_helpers.dart';

class CaregiverHomePage extends StatelessWidget {
  const CaregiverHomePage({
    super.key,
    required this.dashboard,
    required this.onNavigate,
    required this.onRefresh,
    required this.onAcceptInvitation,
    required this.onRejectInvitation,
    required this.onConfirmEvent,
    required this.onNotificationsPressed,
    required this.onLogout,
    this.errorMessage,
  });

  final CaregiverDashboardData dashboard;
  final ValueChanged<CareNavDestination> onNavigate;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String invitationId) onAcceptInvitation;
  final Future<void> Function(String invitationId) onRejectInvitation;
  final Future<void> Function(String eventId) onConfirmEvent;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onLogout;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final today = DateTime.now();
    final firstName = dashboard.user.fullName.split(' ').first;
    final patient = dashboard.activePatient;
    final invitations = dashboard.invitations
        .where((invitation) => invitation.isPending)
        .toList();
    final unread = dashboard.notifications
        .where((notification) => notification.readAt == null)
        .length;

    return CareAppShell(
      destination: CareNavDestination.home,
      onDestinationSelected: onNavigate,
      title: 'Hola, $firstName',
      subtitle: CareDateFormatters.longDate(today),
      userName: dashboard.user.fullName,
      userRole: 'Cuidador',
      onLogout: onLogout,
      onNotificationsPressed: onNotificationsPressed,
      notificationCount: unread + invitations.length,
      navBadges: invitations.isEmpty
          ? const {}
          : {CareNavDestination.home: invitations.length},
      content: CarePageBody(
        onRefresh: onRefresh,
        children: _mainSections(context, layout, patient, invitations, today),
      ),
      rail: layout.hasRail
          ? CareRailPanel(
              children: _railSections(context, patient, invitations),
            )
          : null,
    );
  }

  List<Widget> _mainSections(
    BuildContext context,
    CareLayout layout,
    LinkedPatient? patient,
    List<CaregiverInvitation> invitations,
    DateTime today,
  ) {
    final todayEvents = _eventsOn(today)
      ..sort((a, b) => (a.startAt ?? '').compareTo(b.startAt ?? ''));
    final nextEvent = _nextPendingEvent(dashboard.events);
    final latestNote = dashboard.diaryEntries.isEmpty
        ? null
        : dashboard.diaryEntries.first;
    final int columns = layout.gridColumns;
    final int wideSpan = columns >= 3 ? 2 : columns;

    return [
      if (layout.isCompact) ...[
        Text(CareDateFormatters.longDate(today), style: layout.meta),
        const SizedBox(height: 14),
      ],
      if (errorMessage != null) ...[
        CareSyncWarning(message: errorMessage!),
        SizedBox(height: layout.blockGap),
      ],
      if (patient == null)
        CareEmptyState(
          icon: Icons.group_add_outlined,
          title: 'Aún no tienes pacientes activos',
          message: invitations.isEmpty
              ? 'Cuando un paciente te invite a su cuidado, la invitación aparecerá aquí para aceptarla o rechazarla.'
              : 'Acepta una de las invitaciones pendientes para empezar a ver su agenda, documentos y diario.',
        )
      else
        _NextEventHero(
          patient: patient,
          event: nextEvent,
          onConfirm: nextEvent == null
              ? null
              : () => onConfirmEvent(nextEvent.id),
          onOpenAgenda: () => onNavigate(CareNavDestination.agenda),
        ),
      if (patient != null) ...[
        SizedBox(height: layout.blockGap),
        // Tres cifras siempre en una fila: son pequeñas y se comparan mejor
        // juntas que apiladas.
        CareGrid(
          columns: 3,
          spacing: layout.columnGap,
          runSpacing: layout.columnGap,
          items: [
            CareGridItem(
              child: CareStatTile(
                value: _countStatus('PENDING').toString(),
                label: 'Pendientes',
                color: AppColors.primaryDark,
                onTap: () => onNavigate(CareNavDestination.agenda),
              ),
            ),
            CareGridItem(
              child: CareStatTile(
                value: _countStatus('CONFIRMED').toString(),
                label: 'Confirmados',
                color: AppColors.greenDark,
                onTap: () => onNavigate(CareNavDestination.agenda),
              ),
            ),
            CareGridItem(
              child: CareStatTile(
                value: _countStatus('MISSED').toString(),
                label: 'Incumplidos',
                color: AppColors.redDark,
                onTap: () => onNavigate(CareNavDestination.agenda),
              ),
            ),
          ],
        ),
        SizedBox(height: layout.blockGap),
        CareGrid(
          columns: columns,
          spacing: layout.columnGap,
          runSpacing: layout.columnGap,
          items: [
            CareGridItem(
              span: wideSpan,
              child: _TodayScheduleCard(
                events: todayEvents,
                allowed: patient.allows('AGENDA'),
                onOpenAgenda: () => onNavigate(CareNavDestination.agenda),
                onConfirm: onConfirmEvent,
              ),
            ),
            CareGridItem(
              span: columns >= 3 ? 1 : columns,
              child: _LatestNoteCard(
                note: latestNote,
                patientName: patient.patientFullName,
                allowed: patient.allows('DIARY'),
                onOpenDiary: () => onNavigate(CareNavDestination.diary),
              ),
            ),
          ],
        ),
      ],
      SizedBox(height: layout.blockGap),
      const CareSectionTitle('Accesos rápidos'),
      const SizedBox(height: 12),
      CareGrid(
        columns: columns >= 3 ? 3 : columns,
        spacing: layout.columnGap,
        runSpacing: layout.columnGap,
        items: [
          CareGridItem(
            child: _QuickAction(
              icon: Icons.calendar_today_outlined,
              label: 'Agenda de salud',
              meta: '${dashboard.events.length} eventos registrados',
              background: AppColors.primaryLight,
              foreground: AppColors.primaryDark,
              onTap: () => onNavigate(CareNavDestination.agenda),
            ),
          ),
          CareGridItem(
            child: _QuickAction(
              icon: Icons.description_outlined,
              label: 'Documentos médicos',
              meta: '${dashboard.documentItems.length} archivos',
              background: AppColors.greenLight,
              foreground: AppColors.greenDark,
              onTap: () => onNavigate(CareNavDestination.documents),
            ),
          ),
          CareGridItem(
            child: _QuickAction(
              icon: Icons.edit_note_outlined,
              label: 'Diario de seguimiento',
              meta: '${dashboard.diaryEntries.length} notas',
              background: AppColors.orangeLight,
              foreground: AppColors.orangeDark,
              onTap: () => onNavigate(CareNavDestination.diary),
            ),
          ),
        ],
      ),
      if (!CareLayout.of(context).hasRail) ...[
        SizedBox(height: layout.blockGap),
        CareGrid(
          columns: columns,
          spacing: layout.columnGap,
          runSpacing: layout.columnGap,
          items: [
            if (patient != null)
              CareGridItem(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CareSectionTitle('Paciente a cargo'),
                    const SizedBox(height: 12),
                    ActivePatientPanel(
                      patient: patient,
                      patientCount: dashboard.patients.length,
                      onChangePatient: () =>
                          onNavigate(CareNavDestination.profile),
                    ),
                  ],
                ),
              ),
            if (invitations.isNotEmpty)
              CareGridItem(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CareSectionTitle('Invitaciones', count: invitations.length),
                    const SizedBox(height: 12),
                    for (final invitation in invitations.take(2)) ...[
                      InvitationCard(
                        invitation: invitation,
                        onAccept: () => onAcceptInvitation(invitation.id),
                        onReject: () => onRejectInvitation(invitation.id),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _railSections(
    BuildContext context,
    LinkedPatient? patient,
    List<CaregiverInvitation> invitations,
  ) {
    final recent = dashboard.notifications.take(5).toList();

    return [
      if (patient != null) ...[
        const CareSectionTitle('Paciente a cargo'),
        const SizedBox(height: 12),
        ActivePatientPanel(
          patient: patient,
          patientCount: dashboard.patients.length,
          onChangePatient: () => onNavigate(CareNavDestination.profile),
        ),
        const SizedBox(height: 28),
      ],
      if (invitations.isNotEmpty) ...[
        CareSectionTitle('Invitaciones', count: invitations.length),
        const SizedBox(height: 12),
        for (final invitation in invitations) ...[
          InvitationCard(
            invitation: invitation,
            compactActions: true,
            onAccept: () => onAcceptInvitation(invitation.id),
            onReject: () => onRejectInvitation(invitation.id),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
      ],
      CareSectionTitle(
        'Actividad reciente',
        trailing: recent.isEmpty
            ? null
            : _RailLink(label: 'Ver todo', onTap: onNotificationsPressed),
      ),
      const SizedBox(height: 6),
      if (recent.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Sin novedades por ahora.',
            style: CareLayout.of(context).meta,
          ),
        )
      else
        for (final notification in recent)
          _ActivityRow(notification: notification),
    ];
  }

  List<HealthEvent> _eventsOn(DateTime day) {
    return dashboard.events.where((event) {
      final date = CareDateFormatters.parse(event.startAt);
      return date != null &&
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
  }

  int _countStatus(String status) =>
      dashboard.events.where((event) => event.status == status).length;
}

HealthEvent? _nextPendingEvent(List<HealthEvent> events) {
  final pending = events.where((event) => event.status == 'PENDING').toList();
  pending.sort((a, b) => (a.startAt ?? '').compareTo(b.startAt ?? ''));
  return pending.isEmpty ? null : pending.first;
}

/// Pieza principal de Inicio: qué toca ahora y cómo resolverlo.
class _NextEventHero extends StatelessWidget {
  const _NextEventHero({
    required this.patient,
    required this.event,
    required this.onConfirm,
    required this.onOpenAgenda,
  });

  final LinkedPatient patient;
  final HealthEvent? event;
  final VoidCallback? onConfirm;
  final VoidCallback onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final event = this.event;

    if (event == null) {
      return CareCard(
        variant: CareCardVariant.hero,
        padding: EdgeInsets.all(layout.isCompact ? 20 : 24),
        child: Row(
          children: [
            const CareIconBubble(
              icon: Icons.check_circle_outline,
              size: 48,
              iconSize: 24,
              backgroundColor: AppColors.greenLight,
              iconColor: AppColors.greenDark,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Todo al día', style: layout.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    'No hay eventos pendientes para ${patient.patientFullName}.',
                    style: layout.bodyMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final start = CareDateFormatters.parse(event.startAt);
    final description = event.description.isEmpty
        ? eventTypeLabel(event.type)
        : event.description;

    return CareCard(
      variant: CareCardVariant.hero,
      padding: EdgeInsets.all(layout.isCompact ? 20 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CareIconBubble(
                icon: eventIcon(event.type),
                size: 52,
                iconSize: 25,
                backgroundColor: AppColors.primary,
                iconColor: AppColors.surface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          start == null
                              ? 'Hora pendiente'
                              : CareDateFormatters.time24(start),
                          style: AppTextStyles.headlineMedium
                              .copyWith(
                                fontSize: layout.isCompact ? 24 : 26,
                                color: AppColors.primaryDark,
                              )
                              .tabular,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CareBadge(
                              label: eventStatusLabel(event.status),
                              backgroundColor: eventStatusBackground(
                                event.status,
                              ),
                              foregroundColor: eventStatusForeground(
                                event.status,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: layout.cardTitle.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.patientFullName} · $description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: layout.bodyMuted,
                    ),
                  ],
                ),
              ),
              if (!layout.isCompact) ...[
                const SizedBox(width: 20),
                _HeroContext(event: event, start: start),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onConfirm != null && event.status == 'PENDING')
                CareHeaderButton(
                  label: 'Confirmar',
                  icon: Icons.check_rounded,
                  onPressed: onConfirm,
                ),
              CareHeaderButton(
                label: 'Ver en agenda',
                tone: CareHeaderButtonTone.neutral,
                onPressed: onOpenAgenda,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Contexto del evento del hero: a la derecha, en peso bajo, para que la
/// tarjeta no quede vacía en pantallas anchas.
class _HeroContext extends StatelessWidget {
  const _HeroContext({required this.event, required this.start});

  final HealthEvent event;
  final DateTime? start;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Próximo evento', style: layout.meta),
          const SizedBox(height: 4),
          Text(
            start == null ? 'Sin fecha' : CareDateFormatters.longDate(start!),
            textAlign: TextAlign.right,
            style: layout.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          CareBadge(
            label: eventTypeLabel(event.type),
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          ),
        ],
      ),
    );
  }
}

/// Plan del día completo, no un evento por vez.
class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({
    required this.events,
    required this.allowed,
    required this.onOpenAgenda,
    required this.onConfirm,
  });

  final List<HealthEvent> events;
  final bool allowed;
  final VoidCallback onOpenAgenda;
  final Future<void> Function(String eventId) onConfirm;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CareSectionTitle(
              'Hoy',
              count: allowed ? events.length : null,
              trailing: _RailLink(label: 'Ver semana', onTap: onOpenAgenda),
            ),
          ),
          const SizedBox(height: 8),
          if (!allowed)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
              child: Text(
                'Este paciente no compartió su agenda.',
                style: layout.bodyMuted,
              ),
            )
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
              child: Text(
                'Sin eventos programados para hoy.',
                style: layout.bodyMuted,
              ),
            )
          else
            for (int index = 0; index < events.length; index++) ...[
              if (index > 0) const CareHairline(indent: 62),
              _ScheduleRow(
                event: events[index],
                onConfirm: events[index].status == 'PENDING'
                    ? () => onConfirm(events[index].id)
                    : null,
              ),
            ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.event, required this.onConfirm});

  final HealthEvent event;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final start = CareDateFormatters.parse(event.startAt);
    final done = event.status == 'CONFIRMED';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              start == null ? '--:--' : CareDateFormatters.time24(start),
              style: layout.timeValue.copyWith(
                color: done ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: eventStatusForeground(event.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: done ? AppColors.textSecondary : null,
                  ),
                ),
                Text(eventTypeLabel(event.type), style: layout.meta),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onConfirm != null)
            IconButton(
              tooltip: 'Confirmar',
              onPressed: onConfirm,
              iconSize: 19,
              color: AppColors.greenDark,
              icon: const Icon(Icons.check_circle_outline),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: CareBadge(
                label: eventStatusLabel(event.status),
                backgroundColor: eventStatusBackground(event.status),
                foregroundColor: eventStatusForeground(event.status),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              ),
            ),
        ],
      ),
    );
  }
}

class _LatestNoteCard extends StatelessWidget {
  const _LatestNoteCard({
    required this.note,
    required this.patientName,
    required this.allowed,
    required this.onOpenDiary,
  });

  final DiaryEntry? note;
  final String patientName;
  final bool allowed;
  final VoidCallback onOpenDiary;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final note = this.note;

    return CareCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CareSectionTitle(
            'Última nota',
            trailing: _RailLink(label: 'Abrir diario', onTap: onOpenDiary),
          ),
          const SizedBox(height: 14),
          if (!allowed)
            Text(
              'Este paciente no compartió su diario.',
              style: layout.bodyMuted,
            )
          else if (note == null)
            Text(
              'Todavía no hay notas de seguimiento para $patientName.',
              style: layout.bodyMuted,
            )
          else ...[
            Text(
              CareDateFormatters.relative(note.entryDate),
              style: layout.meta.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: layout.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.meta,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String meta;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      variant: CareCardVariant.quiet,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          CareIconBubble(
            icon: icon,
            size: 40,
            iconSize: 20,
            backgroundColor: background,
            iconColor: foreground,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.notification});

  final CareNotification notification;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final unread = notification.readAt == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unread ? AppColors.tertiary : AppColors.disabled,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: layout.body.copyWith(
                    fontSize: 14,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CareDateFormatters.relative(
                    notification.sentAt ?? notification.createdAt,
                  ),
                  style: layout.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailLink extends StatelessWidget {
  const _RailLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.primary,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          fontSize: 13,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

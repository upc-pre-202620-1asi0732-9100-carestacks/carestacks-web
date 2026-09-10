import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../data/caregiver_models.dart';
import 'caregiver_ui_helpers.dart';

class CaregiverAgendaPage extends StatefulWidget {
  const CaregiverAgendaPage({
    super.key,
    required this.dashboard,
    required this.onConfirmEvent,
    required this.onSaveEvent,
    required this.onNotificationsPressed,
    required this.onRefresh,
    required this.onNavigate,
    required this.onLogout,
  });

  final CaregiverDashboardData dashboard;
  final Future<void> Function(String eventId) onConfirmEvent;
  final Future<void> Function(HealthEventDraft draft) onSaveEvent;
  final VoidCallback onNotificationsPressed;
  final Future<void> Function() onRefresh;
  final ValueChanged<CareNavDestination> onNavigate;
  final VoidCallback onLogout;

  @override
  State<CaregiverAgendaPage> createState() => _CaregiverAgendaPageState();
}

class _CaregiverAgendaPageState extends State<CaregiverAgendaPage> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _visibleMonth = DateTime(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final patient = widget.dashboard.activePatient;
    final allowed = patient != null && patient.allows('AGENDA');
    final events = [...widget.dashboard.events]
      ..sort((a, b) => (a.startAt ?? '').compareTo(b.startAt ?? ''));
    final selectedEvents = _eventsOn(events, _selectedDate);
    final unread = widget.dashboard.notifications
        .where((notification) => notification.readAt == null)
        .length;

    return CareAppShell(
      destination: CareNavDestination.agenda,
      onDestinationSelected: widget.onNavigate,
      title: 'Agenda',
      subtitle: patient == null
          ? 'Sin paciente activo'
          : '${patient.patientFullName} · ${CareDateFormatters.monthTitle(_visibleMonth)}',
      userName: widget.dashboard.user.fullName,
      userRole: 'Cuidador',
      onLogout: widget.onLogout,
      onNotificationsPressed: widget.onNotificationsPressed,
      notificationCount: unread,
      actions: [
        _WeekStepper(
          onPrevious: () => _shiftDays(-7),
          onToday: _goToToday,
          onNext: () => _shiftDays(7),
        ),
        if (allowed)
          CareHeaderButton(
            label: 'Nuevo evento',
            icon: Icons.add_rounded,
            onPressed: () => _showEventForm(context),
          ),
      ],
      compactBottom: allowed
          ? Padding(
              padding: EdgeInsets.fromLTRB(layout.gutter, 0, layout.gutter, 12),
              child: CarePrimaryButton(
                label: 'Agregar evento',
                icon: Icons.add_rounded,
                onPressed: () => _showEventForm(context),
              ),
            )
          : null,
      content: CarePageBody(
        onRefresh: widget.onRefresh,
        children: layout.isCompact
            ? _compactSections(layout, patient, events, selectedEvents)
            : _desktopSections(layout, patient, allowed, events),
      ),
      rail: layout.hasRail
          ? CareRailPanel(
              children: [
                _CalendarCard(
                  dense: true,
                  visibleMonth: _visibleMonth,
                  selectedDate: _selectedDate,
                  events: events,
                  onPreviousMonth: () => _changeMonth(-1),
                  onNextMonth: () => _changeMonth(1),
                  onDateSelected: _selectDate,
                ),
                const SizedBox(height: 26),
                CareSectionTitle(
                  _isToday(_selectedDate)
                      ? 'Hoy'
                      : CareDateFormatters.longDate(_selectedDate),
                  count: allowed ? selectedEvents.length : null,
                ),
                const SizedBox(height: 12),
                if (!allowed)
                  CareEmptyState(
                    dense: true,
                    icon: Icons.lock_outline,
                    message: patient == null
                        ? 'Acepta una invitación para ver la agenda.'
                        : 'Este paciente no compartió su agenda.',
                  )
                else if (selectedEvents.isEmpty)
                  CareEmptyState(
                    dense: true,
                    icon: Icons.event_available_outlined,
                    message: 'Sin eventos para este día.',
                  )
                else
                  for (final event in selectedEvents) ...[
                    _EventDetailCard(
                      event: event,
                      onEdit: () => _showEventForm(context, event: event),
                      onConfirm: event.status == 'PENDING'
                          ? () => widget.onConfirmEvent(event.id)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            )
          : null,
    );
  }

  // Escritorio: la semana entera a la vista, sin obligar a elegir un día
  // para saber qué viene.
  List<Widget> _desktopSections(
    CareLayout layout,
    LinkedPatient? patient,
    bool allowed,
    List<HealthEvent> events,
  ) {
    final weekStart = _weekStart(_selectedDate);
    final weekEvents = events.where((event) {
      final date = CareDateFormatters.parse(event.startAt);
      if (date == null) return false;
      final day = DateTime(date.year, date.month, date.day);
      return !day.isBefore(weekStart) &&
          day.isBefore(weekStart.add(const Duration(days: 7)));
    }).toList();

    return [
      if (!allowed)
        CareEmptyState(
          icon: patient == null ? Icons.group_add_outlined : Icons.lock_outline,
          title: patient == null
              ? 'Sin paciente activo'
              : 'Agenda no compartida',
          message: patient == null
              ? 'Acepta una invitación para gestionar la agenda de salud.'
              : 'Este paciente no habilitó el acceso a su agenda.',
        )
      else ...[
        _WeekHeadline(weekStart: weekStart, eventCount: weekEvents.length),
        const SizedBox(height: 14),
        _WeekGrid(
          weekStart: weekStart,
          selectedDate: _selectedDate,
          events: weekEvents,
          onDateSelected: _selectDate,
          onEventTap: (event) {
            final date = CareDateFormatters.parse(event.startAt);
            if (date != null) _selectDate(date);
            if (!CareLayout.of(context).hasRail) {
              _showEventForm(context, event: event);
            }
          },
        ),
        SizedBox(height: layout.blockGap),
        if (!layout.hasRail) ...[
          CareSectionTitle(
            _isToday(_selectedDate)
                ? 'Eventos de hoy'
                : 'Eventos del ${CareDateFormatters.longDate(_selectedDate)}',
            count: _eventsOn(events, _selectedDate).length,
          ),
          const SizedBox(height: 12),
          CareGrid(
            columns: layout.gridColumns,
            spacing: layout.columnGap,
            runSpacing: layout.columnGap,
            items: [
              for (final event in _eventsOn(events, _selectedDate))
                CareGridItem(
                  child: _EventDetailCard(
                    event: event,
                    onEdit: () => _showEventForm(context, event: event),
                    onConfirm: event.status == 'PENDING'
                        ? () => widget.onConfirmEvent(event.id)
                        : null,
                  ),
                ),
            ],
          ),
          if (_eventsOn(events, _selectedDate).isEmpty)
            CareEmptyState(
              dense: true,
              icon: Icons.event_available_outlined,
              message: 'Sin eventos para este día.',
            ),
        ],
      ],
    ];
  }

  // Teléfono: mes + día seleccionado, el patrón que ya conocía el usuario.
  List<Widget> _compactSections(
    CareLayout layout,
    LinkedPatient? patient,
    List<HealthEvent> events,
    List<HealthEvent> selectedEvents,
  ) {
    final allowed = patient != null && patient.allows('AGENDA');

    return [
      _CalendarCard(
        visibleMonth: _visibleMonth,
        selectedDate: _selectedDate,
        events: events,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        onDateSelected: _selectDate,
      ),
      SizedBox(height: layout.blockGap),
      CareSectionTitle(
        _isToday(_selectedDate)
            ? 'Eventos de hoy'
            : CareDateFormatters.longDate(_selectedDate),
        count: allowed ? selectedEvents.length : null,
      ),
      const SizedBox(height: 12),
      if (!allowed)
        CareEmptyState(
          icon: patient == null ? Icons.group_add_outlined : Icons.lock_outline,
          message: patient == null
              ? 'Acepta una invitación para revisar la agenda.'
              : 'Este paciente no compartió su agenda.',
        )
      else if (selectedEvents.isEmpty)
        const CareEmptyState(
          icon: Icons.event_available_outlined,
          message: 'No hay eventos programados para este día.',
        )
      else
        for (final event in selectedEvents) ...[
          _EventDetailCard(
            event: event,
            onEdit: () => _showEventForm(context, event: event),
            onConfirm: event.status == 'PENDING'
                ? () => widget.onConfirmEvent(event.id)
                : null,
          ),
          const SizedBox(height: 12),
        ],
    ];
  }

  List<HealthEvent> _eventsOn(List<HealthEvent> events, DateTime day) {
    return events
        .where(
          (event) => _sameDay(CareDateFormatters.parse(event.startAt), day),
        )
        .toList();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _visibleMonth = DateTime(date.year, date.month);
    });
  }

  void _goToToday() => _selectDate(DateTime.now());

  void _shiftDays(int days) =>
      _selectDate(_selectedDate.add(Duration(days: days)));

  void _showEventForm(BuildContext context, {HealthEvent? event}) {
    careShowForm(
      context,
      child: _EventFormSheet(event: event, onSave: widget.onSaveEvent),
    );
  }

  void _changeMonth(int delta) {
    final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final maxDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final selectedDay = _selectedDate.day > maxDay ? maxDay : _selectedDate.day;
    setState(() {
      _visibleMonth = nextMonth;
      _selectedDate = DateTime(nextMonth.year, nextMonth.month, selectedDay);
    });
  }
}

class _WeekHeadline extends StatelessWidget {
  const _WeekHeadline({required this.weekStart, required this.eventCount});

  final DateTime weekStart;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final sameMonth = weekStart.month == weekEnd.month;
    final range = sameMonth
        ? '${weekStart.day} al ${weekEnd.day} de ${CareDateFormatters.monthNames[weekStart.month - 1].toLowerCase()}'
        : '${CareDateFormatters.dayAndMonth(weekStart)} al ${CareDateFormatters.dayAndMonth(weekEnd)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(range, style: layout.cardTitle.copyWith(fontSize: 18)),
        ),
        Text(
          eventCount == 1 ? '1 evento' : '$eventCount eventos',
          style: layout.meta,
        ),
      ],
    );
  }
}

/// Siete columnas, una por día. Es la vista que un cuidador necesita para
/// planificar, no un evento por vez.
class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.weekStart,
    required this.selectedDate,
    required this.events,
    required this.onDateSelected,
    required this.onEventTap,
  });

  final DateTime weekStart;
  final DateTime selectedDate;
  final List<HealthEvent> events;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<HealthEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final days = [
      for (int index = 0; index < 7; index++)
        weekStart.add(Duration(days: index)),
    ];

    return CareCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int index = 0; index < days.length; index++) ...[
              if (index > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
              Expanded(
                child: _WeekDayColumn(
                  day: days[index],
                  selected: _sameDay(days[index], selectedDate),
                  events: events
                      .where(
                        (event) => _sameDay(
                          CareDateFormatters.parse(event.startAt),
                          days[index],
                        ),
                      )
                      .toList(),
                  onSelect: () => onDateSelected(days[index]),
                  onEventTap: onEventTap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.day,
    required this.selected,
    required this.events,
    required this.onSelect,
    required this.onEventTap,
  });

  final DateTime day;
  final bool selected;
  final List<HealthEvent> events;
  final VoidCallback onSelect;
  final ValueChanged<HealthEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final today = _isToday(day);
    final sorted = [...events]
      ..sort((a, b) => (a.startAt ?? '').compareTo(b.startAt ?? ''));

    return Container(
      color: selected ? AppColors.backgroundSoft : Colors.transparent,
      constraints: const BoxConstraints(minHeight: 210),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                children: [
                  Text(
                    CareDateFormatters.weekdayShortNames[day.weekday - 1],
                    style: layout.meta.copyWith(
                      color: today
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: today ? AppColors.primary : Colors.transparent,
                      border: selected && !today
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    child: Text(
                      day.day.toString(),
                      style: AppTextStyles.labelMedium
                          .copyWith(
                            fontSize: 14,
                            color: today
                                ? AppColors.surface
                                : AppColors.textPrimary,
                          )
                          .tabular,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 8, 7, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sorted.isEmpty)
                    const SizedBox.shrink()
                  else
                    for (final event in sorted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _EventChip(
                          event: event,
                          onTap: () => onEventTap(event),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.event, required this.onTap});

  final HealthEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = CareDateFormatters.parse(event.startAt);
    final accent = eventStatusForeground(event.status);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.primaryLight.withAlpha(90),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(7, 6, 6, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          start == null
                              ? '--:--'
                              : CareDateFormatters.time24(start),
                          style: AppTextStyles.bodySmall
                              .copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              )
                              .tabular,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

class _WeekStepper extends StatelessWidget {
  const _WeekStepper({
    required this.onPrevious,
    required this.onToday,
    required this.onNext,
  });

  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _StepperButton(
            icon: Icons.chevron_left,
            tooltip: 'Semana anterior',
            onPressed: onPrevious,
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.border,
          ),
          InkWell(
            onTap: onToday,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  'Hoy',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.border,
          ),
          _StepperButton(
            icon: Icons.chevron_right,
            tooltip: 'Semana siguiente',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          child: Icon(icon, size: 20, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.events,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
    this.dense = false,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<HealthEvent> events;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final dates = _calendarDates(visibleMonth);
    final eventDays = {
      for (final event in events)
        if (CareDateFormatters.parse(event.startAt) case final date?)
          _dateKey(date),
    };

    return CareCard(
      variant: dense ? CareCardVariant.quiet : CareCardVariant.standard,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 20,
        vertical: dense ? 14 : 20,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  CareDateFormatters.monthTitle(visibleMonth),
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: dense ? 14 : 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.chevron_left,
                tooltip: 'Mes anterior',
                onPressed: onPreviousMonth,
              ),
              _StepperButton(
                icon: Icons.chevron_right,
                tooltip: 'Mes siguiente',
                onPressed: onNextMonth,
              ),
            ],
          ),
          SizedBox(height: dense ? 8 : 12),
          _WeekDaysRow(dense: dense),
          SizedBox(height: dense ? 4 : 8),
          for (var row = 0; row < dates.length; row += 7)
            _CalendarDatesRow(
              dates: dates.sublist(row, row + 7),
              visibleMonth: visibleMonth,
              selectedDate: selectedDate,
              eventDays: eventDays,
              dense: dense,
              onDateSelected: onDateSelected,
            ),
        ],
      ),
    );
  }
}

class _WeekDaysRow extends StatelessWidget {
  const _WeekDaysRow({required this.dense});

  final bool dense;

  static const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in _days)
          Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: dense ? 11 : 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDatesRow extends StatelessWidget {
  const _CalendarDatesRow({
    required this.dates,
    required this.visibleMonth,
    required this.selectedDate,
    required this.eventDays,
    required this.dense,
    required this.onDateSelected,
  });

  final List<DateTime> dates;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final Set<String> eventDays;
  final bool dense;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final date in dates)
          Expanded(
            child: _CalendarDayButton(
              date: date,
              muted: date.month != visibleMonth.month,
              selected: _sameDay(date, selectedDate),
              hasEvent: eventDays.contains(_dateKey(date)),
              dense: dense,
              onTap: () => onDateSelected(date),
            ),
          ),
      ],
    );
  }
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.date,
    required this.muted,
    required this.selected,
    required this.hasEvent,
    required this.dense,
    required this.onTap,
  });

  final DateTime date;
  final bool muted;
  final bool selected;
  final bool hasEvent;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = _isToday(date);
    final Color textColor = selected
        ? AppColors.surface
        : muted
        ? AppColors.textMuted.withAlpha(150)
        : AppColors.textPrimary;
    final double size = dense ? 32 : 40;

    return SizedBox(
      height: size + 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(size),
        onTap: onTap,
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primary : Colors.transparent,
              border: today && !selected
                  ? Border.all(color: AppColors.primary)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date.day.toString(),
                  style: AppTextStyles.bodyMedium
                      .copyWith(
                        fontSize: dense ? 13 : 14,
                        color: textColor,
                        fontWeight: selected || today
                            ? FontWeight.w700
                            : FontWeight.w400,
                      )
                      .tabular,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEvent
                        ? selected
                              ? AppColors.surface
                              : AppColors.primary
                        : Colors.transparent,
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

class _EventDetailCard extends StatelessWidget {
  const _EventDetailCard({
    required this.event,
    required this.onConfirm,
    required this.onEdit,
  });

  final HealthEvent event;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CareIconBubble(
                icon: eventIcon(event.type),
                size: 38,
                iconSize: 19,
                backgroundColor: AppColors.primaryLight,
                iconColor: AppColors.primaryDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: layout.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      '${eventTypeLabel(event.type)} · ${CareDateFormatters.timeRange(event.startAt, event.endAt)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: layout.meta,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CareBadge(
                label: eventStatusLabel(event.status),
                backgroundColor: eventStatusBackground(event.status),
                foregroundColor: eventStatusForeground(event.status),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              ),
              Text(CareDateFormatters.date(event.startAt), style: layout.meta),
            ],
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description,
              style: layout.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onConfirm != null)
                CareHeaderButton(
                  label: 'Confirmar',
                  icon: Icons.check_rounded,
                  onPressed: onConfirm,
                ),
              if (onEdit != null)
                CareHeaderButton(
                  label: 'Editar',
                  tone: CareHeaderButtonTone.neutral,
                  onPressed: onEdit,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

DateTime _weekStart(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

List<DateTime> _calendarDates(DateTime visibleMonth) {
  final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
  final start = firstDay.subtract(Duration(days: firstDay.weekday - 1));
  return [
    for (var index = 0; index < 42; index++) start.add(Duration(days: index)),
  ];
}

bool _sameDay(DateTime? left, DateTime right) {
  return left != null &&
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

bool _isToday(DateTime date) => _sameDay(date, DateTime.now());

String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

class _EventFormSheet extends StatefulWidget {
  const _EventFormSheet({required this.event, required this.onSave});

  final HealthEvent? event;
  final Future<void> Function(HealthEventDraft draft) onSave;

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  static const _types = [
    'MEDICATION',
    'APPOINTMENT',
    'THERAPY',
    'CARE_ACTIVITY',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _type;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final start =
        CareDateFormatters.parse(event?.startAt) ??
        DateTime.now().add(const Duration(hours: 1));
    final end =
        CareDateFormatters.parse(event?.endAt) ??
        start.add(const Duration(hours: 1));

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _type = _types.contains(event?.type) ? event!.type : 'CARE_ACTIVITY';
    _date = DateTime(start.year, start.month, start.day);
    _startTime = TimeOfDay.fromDateTime(start);
    _endTime = TimeOfDay.fromDateTime(end);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.event != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, bottomInset + 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing ? 'Editar evento' : 'Nuevo evento',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 18),
              _SheetTextField(
                controller: _titleController,
                label: 'Nombre del evento',
                hintText: 'Ej. Revisión cardiológica',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo de evento'),
                items: [
                  for (final type in _types)
                    DropdownMenuItem(
                      value: type,
                      child: Text(eventTypeLabel(type)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 14),
              _PickerButton(
                icon: Icons.calendar_today_outlined,
                label: CareDateFormatters.date(_date.toIso8601String()),
                onPressed: _saving ? null : _pickDate,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.schedule,
                      label: _startTime.format(context),
                      onPressed: _saving ? null : () => _pickTime(start: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerButton(
                      icon: Icons.schedule_outlined,
                      label: _endTime.format(context),
                      onPressed: _saving ? null : () => _pickTime(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SheetTextField(
                controller: _descriptionController,
                label: 'Descripción',
                hintText: 'Detalles adicionales, dosis o notas importantes...',
                minLines: 3,
                maxLines: 5,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.redDark,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  CareHeaderButton(
                    label: _saving ? 'Guardando…' : 'Guardar evento',
                    icon: Icons.check_rounded,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final startAt = _combine(_date, _startTime);
    final endAt = _combine(_date, _endTime);

    if (title.isEmpty) {
      setState(() => _error = 'Ingresa el nombre del evento.');
      return;
    }
    if (!endAt.isAfter(startAt)) {
      setState(() => _error = 'La hora de fin debe ser posterior al inicio.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(
        HealthEventDraft(
          id: widget.event?.id,
          title: title,
          description: _descriptionController.text.trim(),
          type: _type,
          startAt: startAt,
          endAt: endAt,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = _errorMessage(error, 'No se pudo guardar.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hintText),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        alignment: Alignment.centerLeft,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18, color: AppColors.iconMuted),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

String _errorMessage(Object error, String fallback) {
  if (error is ApiException) return error.message;
  return fallback;
}

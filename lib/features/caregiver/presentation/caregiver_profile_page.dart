import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/caregiver_models.dart';
import 'caregiver_panels.dart';

class CaregiverProfilePage extends StatelessWidget {
  const CaregiverProfilePage({
    super.key,
    required this.dashboard,
    required this.onPatientSelected,
    required this.onLogout,
    required this.onNotificationsPressed,
    required this.onNavigate,
  });

  final CaregiverDashboardData dashboard;
  final Future<void> Function(String patientId) onPatientSelected;
  final VoidCallback onLogout;
  final VoidCallback onNotificationsPressed;
  final ValueChanged<CareNavDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final user = dashboard.user;
    final activePatient = dashboard.activePatient;
    final pendingInvitations = dashboard.invitations
        .where((invitation) => invitation.isPending)
        .length;
    final unread = dashboard.notifications
        .where((notification) => notification.readAt == null)
        .length;

    final summary = [
      CareStatTile(
        value: dashboard.patients.length.toString(),
        label: 'Pacientes vinculados',
        color: AppColors.primaryDark,
      ),
      CareStatTile(
        value: pendingInvitations.toString(),
        label: 'Invitaciones pendientes',
        color: AppColors.orangeDark,
      ),
      CareStatTile(
        value: dashboard.notifications.length.toString(),
        label: 'Avisos recibidos',
        color: AppColors.greenDark,
      ),
    ];

    return CareAppShell(
      destination: CareNavDestination.profile,
      onDestinationSelected: onNavigate,
      title: 'Perfil',
      subtitle: user.email,
      userName: user.fullName,
      userRole: 'Cuidador',
      onLogout: onLogout,
      onNotificationsPressed: onNotificationsPressed,
      notificationCount: unread,
      content: CarePageBody(
        children: [
          _IdentityCard(user: user),
          SizedBox(height: layout.blockGap),
          if (!layout.hasRail) ...[
            const CareSectionTitle('Resumen de cuidado'),
            const SizedBox(height: 12),
            CareGrid(
              columns: layout.isCompact ? 3 : 3,
              spacing: layout.columnGap,
              runSpacing: layout.columnGap,
              items: [for (final tile in summary) CareGridItem(child: tile)],
            ),
            SizedBox(height: layout.blockGap),
          ],
          CareSectionTitle(
            'Pacientes vinculados',
            count: dashboard.patients.length,
          ),
          const SizedBox(height: 12),
          if (dashboard.patients.isEmpty)
            const CareEmptyState(
              icon: Icons.group_add_outlined,
              title: 'Sin pacientes vinculados',
              message:
                  'Cuando aceptes una invitación, el paciente aparecerá aquí con los permisos que haya compartido.',
            )
          else
            CareGrid(
              columns: layout.isCompact ? 1 : 2,
              spacing: layout.columnGap,
              runSpacing: layout.columnGap,
              items: [
                for (final patient in dashboard.patients)
                  CareGridItem(
                    child: _PatientAccessCard(
                      patient: patient,
                      selected: activePatient?.patientId == patient.patientId,
                      onTap: () => onPatientSelected(patient.patientId),
                    ),
                  ),
              ],
            ),
          if (!layout.hasRail) ...[
            SizedBox(height: layout.blockGap),
            _SessionCard(onLogout: onLogout),
          ],
        ],
      ),
      rail: layout.hasRail
          ? CareRailPanel(
              children: [
                const CareSectionTitle('Resumen de cuidado'),
                const SizedBox(height: 12),
                for (final tile in summary) ...[
                  tile,
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                const CareSectionTitle('Sesión'),
                const SizedBox(height: 12),
                _SessionCard(onLogout: onLogout),
              ],
            )
          : null,
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      variant: CareCardVariant.hero,
      padding: EdgeInsets.all(layout.isCompact ? 20 : 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: layout.isCompact ? 30 : 34,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              careInitials(user.fullName),
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: layout.isCompact ? 22 : 24,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: layout.pageTitle.copyWith(
                    fontSize: layout.isCompact ? 22 : 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(user.email, style: layout.bodyMuted),
                const SizedBox(height: 12),
                CareBadge(
                  label: user.active
                      ? 'Cuidador verificado'
                      : 'Cuenta inactiva',
                  backgroundColor: user.active
                      ? AppColors.greenLight
                      : AppColors.redLight,
                  foregroundColor: user.active
                      ? AppColors.greenDark
                      : AppColors.redDark,
                ),
              ],
            ),
          ),
          if (!layout.isCompact) ...[
            const SizedBox(width: 24),
            _AccountFacts(user: user),
          ],
        ],
      ),
    );
  }
}

/// Datos de la cuenta a la derecha de la identidad: evita el vacío que deja
/// una tarjeta de perfil estirada a todo el ancho.
class _AccountFacts extends StatelessWidget {
  const _AccountFacts({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Fact(label: 'Rol', value: 'Cuidador'),
          const SizedBox(height: 10),
          _Fact(label: 'Estado', value: user.active ? 'Activa' : 'Inactiva'),
          const SizedBox(height: 10),
          _Fact(label: 'Identificador', value: user.id.isEmpty ? '—' : user.id),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: layout.meta),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: layout.body.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _PatientAccessCard extends StatelessWidget {
  const _PatientAccessCard({
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  final LinkedPatient patient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      onTap: onTap,
      selected: selected,
      backgroundColor: selected ? AppColors.backgroundSoft : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: selected
                    ? AppColors.greenLight
                    : AppColors.primaryLight,
                child: Text(
                  careInitials(patient.patientFullName),
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 13,
                    color: selected
                        ? AppColors.greenDark
                        : AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  patient.patientFullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.cardTitle,
                ),
              ),
              if (selected)
                const CareBadge(
                  label: 'Activo',
                  backgroundColor: AppColors.greenLight,
                  foregroundColor: AppColors.greenDark,
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                )
              else
                Text('Ver como activo', style: layout.meta),
            ],
          ),
          const SizedBox(height: 14),
          Text('Acceso compartido', style: layout.meta),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final view in patient.allowedViews)
                CareBadge(
                  label: careViewLabel(view),
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      variant: CareCardVariant.quiet,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CareIconBubble(
            icon: Icons.logout,
            size: 38,
            iconSize: 18,
            backgroundColor: AppColors.redLight,
            iconColor: AppColors.redDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cerrar sesión en este dispositivo',
              style: layout.body,
            ),
          ),
          const SizedBox(width: 10),
          CareHeaderButton(
            label: 'Salir',
            tone: CareHeaderButtonTone.neutral,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

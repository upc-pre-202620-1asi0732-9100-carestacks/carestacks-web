import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/caregiver_models.dart';

/// Ficha del paciente a cargo. Vive en el panel derecho en escritorio.
class ActivePatientPanel extends StatelessWidget {
  const ActivePatientPanel({
    super.key,
    required this.patient,
    required this.patientCount,
    required this.onChangePatient,
  });

  final LinkedPatient patient;
  final int patientCount;
  final VoidCallback onChangePatient;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.greenLight,
                child: Text(
                  careInitials(patient.patientFullName),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.greenDark,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.patientFullName,
                      maxLines: 2,
                      style: layout.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text('Paciente a cargo', style: layout.meta),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          if (patientCount > 1) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onChangePatient,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primary,
                ),
                child: Text(
                  'Cambiar paciente ($patientCount vinculados)',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Invitación pendiente con sus dos salidas. Se usa en Inicio y en el panel
/// de notificaciones.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.invitation,
    required this.onAccept,
    required this.onReject,
    this.busy = false,
    this.compactActions = false,
  });

  final CaregiverInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool busy;
  final bool compactActions;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      borderColor: AppColors.primaryLight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CareIconBubble(
                icon: Icons.shield_outlined,
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
                    Text(invitation.patientFullName, style: layout.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      'Quiere compartir su cuidado contigo',
                      style: layout.meta,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, compactActions ? 38 : 42),
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, compactActions ? 38 : 42),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: AppTextStyles.labelMedium.copyWith(fontSize: 14),
                  ),
                  child: Text(busy ? 'Guardando…' : 'Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String careInitials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2);
  if (words.isEmpty) return '—';
  return words.map((word) => word[0].toUpperCase()).join();
}

String careViewLabel(String value) {
  return switch (value) {
    'PROFILE' => 'Perfil',
    'AGENDA' => 'Agenda',
    'DOCUMENTS' => 'Documentos',
    'DIARY' => 'Diario',
    'NOTIFICATIONS' => 'Avisos',
    _ => value,
  };
}

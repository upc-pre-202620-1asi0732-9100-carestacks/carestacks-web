import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../data/caregiver_models.dart';
import '../data/caregiver_repository.dart';
import 'caregiver_agenda_page.dart';
import 'caregiver_diary_page.dart';
import 'caregiver_documents_page.dart';
import 'caregiver_home_page.dart';
import 'caregiver_notifications_page.dart';
import 'caregiver_profile_page.dart';

class CaregiverMainPage extends StatefulWidget {
  const CaregiverMainPage({
    super.key,
    required this.repository,
    required this.onLoggedOut,
  });

  final CaregiverRepository repository;
  final VoidCallback onLoggedOut;

  @override
  State<CaregiverMainPage> createState() => _CaregiverMainPageState();
}

class _CaregiverMainPageState extends State<CaregiverMainPage> {
  CareNavDestination _currentDestination = CareNavDestination.home;
  CaregiverDashboardData? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final dashboard = await widget.repository.loadDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo sincronizar la vista del cuidador.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPatient(String patientId) async {
    await widget.repository.selectPatient(patientId);
    await _loadDashboard(showSpinner: false);
  }

  Future<void> _acceptInvitation(String invitationId) async {
    await widget.repository.acceptInvitation(invitationId);
    await _loadDashboard(showSpinner: false);
    _showMessage('Invitación aceptada. El paciente ya está disponible.');
  }

  Future<void> _rejectInvitation(String invitationId) async {
    await widget.repository.rejectInvitation(invitationId);
    await _loadDashboard(showSpinner: false);
    _showMessage('Invitación rechazada.');
  }

  Future<void> _confirmEvent(String eventId) async {
    await widget.repository.confirmEvent(eventId);
    await _loadDashboard(showSpinner: false);
    _showMessage('Evento confirmado.');
  }

  Future<void> _saveAgendaEvent(HealthEventDraft draft) async {
    final patient = _dashboard?.activePatient;
    if (patient == null) {
      throw const ApiException('Selecciona un paciente antes de guardar.');
    }

    await widget.repository.saveAgendaEvent(patient: patient, draft: draft);
    await _loadDashboard(showSpinner: false);
    _showMessage(draft.id == null ? 'Evento creado.' : 'Evento actualizado.');
  }

  Future<void> _saveDiaryEntry(DiaryEntryDraft draft) async {
    final patient = _dashboard?.activePatient;
    if (patient == null) {
      throw const ApiException('Selecciona un paciente antes de guardar.');
    }

    await widget.repository.saveDiaryEntry(patient: patient, draft: draft);
    await _loadDashboard(showSpinner: false);
    _showMessage(draft.id == null ? 'Nota creada.' : 'Nota actualizada.');
  }

  Future<void> _addDocumentItem(DocumentItemDraft draft) async {
    final dashboard = _dashboard;
    final patient = dashboard?.activePatient;
    if (dashboard == null || patient == null) {
      throw const ApiException('Selecciona un paciente antes de guardar.');
    }

    await widget.repository.addDocumentItem(
      patient: patient,
      documents: dashboard.documents,
      draft: draft,
    );
    await _loadDashboard(showSpinner: false);
    _showMessage('Documento agregado.');
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    await widget.repository.markNotificationAsRead(notificationId);
    await _loadDashboard(showSpinner: false);
  }

  Future<void> _logout() async {
    await widget.repository.session.clear();
    widget.onLoggedOut();
  }

  void _openNotifications() {
    final dashboard = _dashboard;
    if (dashboard == null) return;
    showCaregiverNotifications(
      context,
      dashboard: dashboard,
      onAcceptInvitation: _acceptInvitation,
      onRejectInvitation: _rejectInvitation,
      onMarkAsRead: _markNotificationAsRead,
    );
  }

  void _navigate(CareNavDestination destination) {
    setState(() => _currentDestination = destination);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;

    if (_loading && dashboard == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (dashboard == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _ErrorState(
          error: _error,
          onRetry: _loadDashboard,
          onLogout: _logout,
        ),
      );
    }

    // Cada pantalla monta su propio chrome responsive: la navegación cambia
    // de sidebar a bottom nav según el ancho, no según la pantalla.
    return IndexedStack(
      index: _currentDestination.index,
      children: [
        CaregiverHomePage(
          dashboard: dashboard,
          errorMessage: _error,
          onNavigate: _navigate,
          onRefresh: () => _loadDashboard(showSpinner: false),
          onAcceptInvitation: _acceptInvitation,
          onRejectInvitation: _rejectInvitation,
          onConfirmEvent: _confirmEvent,
          onNotificationsPressed: _openNotifications,
          onLogout: _logout,
        ),
        CaregiverAgendaPage(
          dashboard: dashboard,
          onConfirmEvent: _confirmEvent,
          onSaveEvent: _saveAgendaEvent,
          onNotificationsPressed: _openNotifications,
          onRefresh: () => _loadDashboard(showSpinner: false),
          onNavigate: _navigate,
          onLogout: _logout,
        ),
        CaregiverDocumentsPage(
          dashboard: dashboard,
          onAddDocument: _addDocumentItem,
          onNotificationsPressed: _openNotifications,
          onRefresh: () => _loadDashboard(showSpinner: false),
          onNavigate: _navigate,
          onLogout: _logout,
        ),
        CaregiverDiaryPage(
          dashboard: dashboard,
          onSaveEntry: _saveDiaryEntry,
          onNotificationsPressed: _openNotifications,
          onRefresh: () => _loadDashboard(showSpinner: false),
          onNavigate: _navigate,
          onLogout: _logout,
        ),
        CaregiverProfilePage(
          dashboard: dashboard,
          onPatientSelected: _selectPatient,
          onLogout: _logout,
          onNotificationsPressed: _openNotifications,
          onNavigate: _navigate,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: EdgeInsets.all(layout.gutter),
            child: CareCard(
              variant: CareCardVariant.hero,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CareIconBubble(
                    icon: Icons.wifi_off,
                    size: 56,
                    iconSize: 26,
                    backgroundColor: AppColors.redLight,
                    iconColor: AppColors.redDark,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pudimos cargar tus datos',
                    style: layout.cardTitle.copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error ?? 'Revisa tu conexión o vuelve a iniciar sesión.',
                    style: layout.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CareHeaderButton(
                        label: 'Reintentar',
                        icon: Icons.refresh,
                        onPressed: onRetry,
                      ),
                      const SizedBox(width: 10),
                      CareHeaderButton(
                        label: 'Cerrar sesión',
                        tone: CareHeaderButtonTone.neutral,
                        onPressed: onLogout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

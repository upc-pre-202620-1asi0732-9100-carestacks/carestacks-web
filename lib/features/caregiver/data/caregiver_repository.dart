// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/care_connect_api_client.dart';
import '../../auth/data/session_manager.dart';
import 'caregiver_models.dart';

class CaregiverRepository {
  CaregiverRepository({
    required CareConnectApiClient apiClient,
    required SessionManager sessionManager,
    required SharedPreferences preferences,
  }) : _apiClient = apiClient,
       _sessionManager = sessionManager,
       _preferences = preferences;

  final CareConnectApiClient _apiClient;
  final SessionManager _sessionManager;
  final SharedPreferences _preferences;

  SessionManager get session => _sessionManager;

  Future<UserProfile> signInCaregiver({
    required String email,
    required String password,
  }) async {
    final login = await _apiClient.login(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = await _apiClient.getCurrentUser(login.token);
    if (user.role != 'CAREGIVER') {
      throw const ApiException(
        'Esta vista de Flutter está preparada para usuarios cuidadores.',
      );
    }
    await _sessionManager.saveSession(token: login.token, user: user);
    await _cacheObject('current_user', {
      'id': user.id,
      'email': user.email,
      'fullName': user.fullName,
      'role': user.role,
      'active': user.active,
    });
    return user;
  }

  Future<UserProfile> registerCaregiver({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _apiClient.registerCaregiver(
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      password: password,
    );
    return signInCaregiver(email: email, password: password);
  }

  Future<CaregiverDashboardData> loadDashboard() async {
    final token = _requiredToken();
    final user = await _loadCurrentUser(token);
    final patients = await _fetchListWithCache(
      key: 'caregiver_patients',
      fetch: () => _apiClient.getCaregiverPatients(token),
      toJson: (patient) => patient.toJson(),
      fromJson: LinkedPatient.fromJson,
    );

    final activePatient = await _resolveActivePatient(patients);
    final invitations = await _fetchListWithCache(
      key: 'caregiver_invitations',
      fetch: () => _apiClient.getCaregiverInvitations(token),
      toJson: (invitation) => invitation.toJson(),
      fromJson: CaregiverInvitation.fromJson,
    );
    final notifications = await _fetchListWithCache(
      key: 'caregiver_notifications_${user.id}',
      fetch: () => _apiClient.getNotifications(user.id),
      toJson: (notification) => notification.toJson(),
      fromJson: CareNotification.fromJson,
    );

    final events = activePatient == null || !activePatient.allows('AGENDA')
        ? <HealthEvent>[]
        : await _fetchListWithCache(
            key: 'agenda_${activePatient.patientId}',
            fetch: () => _apiClient.getAgendaEvents(activePatient.patientId),
            toJson: (event) => event.toJson(),
            fromJson: HealthEvent.fromJson,
          );
    final documents =
        activePatient == null || !activePatient.allows('DOCUMENTS')
        ? <MedicalDocument>[]
        : await _fetchListWithCache(
            key: 'documents_${activePatient.patientId}',
            fetch: () => _apiClient.getDocuments(activePatient.patientId),
            toJson: (document) => document.toJson(),
            fromJson: MedicalDocument.fromJson,
          );
    final diaryEntries = activePatient == null || !activePatient.allows('DIARY')
        ? <DiaryEntry>[]
        : await _fetchListWithCache(
            key: 'diary_${activePatient.patientId}',
            fetch: () => _apiClient.getDiaryEntries(activePatient.patientId),
            toJson: (entry) => entry.toJson(),
            fromJson: DiaryEntry.fromJson,
          );

    return CaregiverDashboardData(
      user: user,
      patients: patients,
      activePatient: activePatient,
      invitations: invitations,
      notifications: notifications,
      events: events,
      documents: documents,
      diaryEntries: diaryEntries,
    );
  }

  Future<void> selectPatient(String patientId) {
    return _sessionManager.saveActivePatientId(patientId);
  }

  Future<void> acceptInvitation(String invitationId) async {
    await _apiClient.acceptInvitation(_requiredToken(), invitationId);
  }

  Future<void> rejectInvitation(String invitationId) async {
    await _apiClient.rejectInvitation(_requiredToken(), invitationId);
  }

  Future<void> confirmEvent(String eventId) async {
    await _apiClient.confirmAgendaEvent(eventId);
  }

  Future<void> saveAgendaEvent({
    required LinkedPatient patient,
    required HealthEventDraft draft,
  }) async {
    if (!patient.allows('AGENDA')) {
      throw const ApiException('No tienes permiso para modificar la agenda.');
    }

    final eventId = draft.id;
    if (eventId == null || eventId.isEmpty) {
      await _apiClient.createAgendaEvent(
        patientId: patient.patientId,
        caregiverId: _sessionManager.userId,
        title: draft.title.trim(),
        description: draft.description.trim(),
        type: draft.type,
        startAt: draft.startAt,
        endAt: draft.endAt,
      );
      return;
    }

    await _apiClient.updateAgendaEvent(
      eventId: eventId,
      title: draft.title.trim(),
      description: draft.description.trim(),
      type: draft.type,
      startAt: draft.startAt,
      endAt: draft.endAt,
    );
  }

  Future<void> saveDiaryEntry({
    required LinkedPatient patient,
    required DiaryEntryDraft draft,
  }) async {
    if (!patient.allows('DIARY')) {
      throw const ApiException('No tienes permiso para modificar el diario.');
    }

    final entryId = draft.id;
    if (entryId == null || entryId.isEmpty) {
      await _apiClient.createDiaryEntry(
        patientId: patient.patientId,
        content: draft.content.trim(),
      );
      return;
    }

    await _apiClient.updateDiaryEntry(
      entryId: entryId,
      content: draft.content.trim(),
    );
  }

  Future<void> addDocumentItem({
    required LinkedPatient patient,
    required List<MedicalDocument> documents,
    required DocumentItemDraft draft,
  }) async {
    if (!patient.allows('DOCUMENTS')) {
      throw const ApiException('No tienes permiso para agregar documentos.');
    }

    var medicalDocumentId = documents.isEmpty ? '' : documents.first.id;
    if (medicalDocumentId.isEmpty) {
      final created = await _apiClient.createMedicalDocument(patient.patientId);
      medicalDocumentId = created.id;
    }

    await _apiClient.addDocumentItem(
      medicalDocumentId: medicalDocumentId,
      documentType: draft.documentType,
      title: draft.title.trim(),
      description: draft.description.trim(),
      fileUrl: draft.fileUrl.trim(),
      mimeType: draft.mimeType.trim(),
      fileSizeBytes: draft.fileSizeBytes,
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _apiClient.markNotificationAsRead(notificationId);
  }

  Future<UserProfile> _loadCurrentUser(String token) async {
    try {
      final user = await _apiClient.getCurrentUser(token);
      await _cacheObject('current_user', {
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'role': user.role,
        'active': user.active,
      });
      return user;
    } catch (_) {
      final cached = _readObject('current_user');
      if (cached != null) return UserProfile.fromJson(cached);
      return UserProfile(
        id: _sessionManager.userId ?? '',
        email: '',
        fullName: _sessionManager.userFullName ?? 'Cuidador',
        role: _sessionManager.userRole ?? 'CAREGIVER',
        active: true,
      );
    }
  }

  Future<LinkedPatient?> _resolveActivePatient(
    List<LinkedPatient> patients,
  ) async {
    if (patients.isEmpty) {
      await _sessionManager.clearActivePatientId();
      return null;
    }

    final activePatientId = _sessionManager.activePatientId;
    LinkedPatient active = patients.first;
    for (final patient in patients) {
      if (patient.patientId == activePatientId) {
        active = patient;
        break;
      }
    }
    await _sessionManager.saveActivePatientId(active.patientId);
    return active;
  }

  Future<List<T>> _fetchListWithCache<T>({
    required String key,
    required Future<List<T>> Function() fetch,
    required Map<String, dynamic> Function(T value) toJson,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    try {
      final remote = await fetch();
      await _cacheList(key, remote.map(toJson).toList());
      return remote;
    } catch (error) {
      final cached = _readList(key, fromJson);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<void> _cacheList(String key, List<Map<String, dynamic>> values) {
    return _preferences.setString('cache_$key', jsonEncode(values));
  }

  List<T> _readList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final rawValue = _preferences.getString('cache_$key');
    if (rawValue == null || rawValue.isEmpty) return const [];
    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  Future<void> _cacheObject(String key, Map<String, dynamic> value) {
    return _preferences.setString('cache_$key', jsonEncode(value));
  }

  Map<String, dynamic>? _readObject(String key) {
    final rawValue = _preferences.getString('cache_$key');
    if (rawValue == null || rawValue.isEmpty) return null;
    final decoded = jsonDecode(rawValue);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  String _requiredToken() {
    final token = _sessionManager.token;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'No hay una sesión activa. Iniciá sesión nuevamente.',
      );
    }
    return token;
  }
}

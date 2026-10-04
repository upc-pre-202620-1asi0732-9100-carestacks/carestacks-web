import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import '../../features/caregiver/data/caregiver_models.dart';

class CareConnectApiClient {
  CareConnectApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _requestMap(
      () => _httpClient.post(
        _uri('/api/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    return LoginResponse.fromJson(json);
  }

  Future<UserProfile> registerCaregiver({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final json = await _requestMap(
      () => _httpClient.post(
        _uri('/api/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': 'CAREGIVER',
        }),
      ),
    );
    return UserProfile.fromJson(json);
  }

  Future<UserProfile> getCurrentUser(String token) async {
    final json = await _requestMap(
      () => _httpClient.get(
        _uri('/api/auth/me'),
        headers: _headers(token: token),
      ),
    );
    return UserProfile.fromJson(json);
  }

  Future<List<LinkedPatient>> getCaregiverPatients(String token) async {
    try {
      final json = await _requestList(
        () => _httpClient.get(
          _uri('/api/consents/me/caregiver/patients'),
          headers: _headers(token: token),
        ),
      );
      return mapJsonList(json, LinkedPatient.fromJson);
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;

      try {
        final json = await _requestMap(
          () => _httpClient.get(
            _uri('/api/consents/me/caregiver'),
            headers: _headers(token: token),
          ),
        );
        return [LinkedPatient.fromJson(json)];
      } on ApiException catch (fallbackError) {
        // The legacy API returns 404 when no profile is shared, including
        // after revocation. Treat that response as an authoritative empty list.
        if (fallbackError.statusCode == 404) return const [];
        rethrow;
      }
    }
  }

  Future<List<CaregiverInvitation>> getCaregiverInvitations(
    String token, {
    bool pendingOnly = false,
  }) async {
    final path = pendingOnly
        ? '/api/invitations/me/caregiver/pending'
        : '/api/invitations/me/caregiver';
    try {
      final json = await _requestList(
        () => _httpClient.get(_uri(path), headers: _headers(token: token)),
      );
      return mapJsonList(json, CaregiverInvitation.fromJson);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<CaregiverInvitation> acceptInvitation(
    String token,
    String invitationId,
  ) async {
    final json = await _requestMap(
      () => _httpClient.patch(
        _uri('/api/invitations/$invitationId/accept'),
        headers: _headers(token: token),
      ),
    );
    return CaregiverInvitation.fromJson(json);
  }

  Future<CaregiverInvitation> rejectInvitation(
    String token,
    String invitationId,
  ) async {
    final json = await _requestMap(
      () => _httpClient.patch(
        _uri('/api/invitations/$invitationId/reject'),
        headers: _headers(token: token),
      ),
    );
    return CaregiverInvitation.fromJson(json);
  }

  Future<List<CareNotification>> getNotifications(String recipientId) async {
    final json = await _requestList(
      () => _httpClient.get(
        _uri('/api/notifications/recipient/$recipientId'),
        headers: _headers(),
      ),
    );
    return mapJsonList(json, CareNotification.fromJson);
  }

  Future<CareNotification> markNotificationAsRead(String notificationId) async {
    final json = await _requestMap(
      () => _httpClient.patch(
        _uri('/api/notifications/$notificationId/read'),
        headers: _headers(),
      ),
    );
    return CareNotification.fromJson(json);
  }

  Future<List<HealthEvent>> getAgendaEvents(String patientId) async {
    final json = await _requestList(
      () => _httpClient.get(
        _uri('/api/agenda/patient/$patientId'),
        headers: _headers(),
      ),
    );
    return mapJsonList(json, HealthEvent.fromJson);
  }

  Future<HealthEvent> createAgendaEvent({
    required String patientId,
    required String? caregiverId,
    required String title,
    required String description,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final body = {
      'patientId': patientId,
      if (caregiverId != null && caregiverId.isNotEmpty)
        'caregiverId': caregiverId,
      'title': title,
      'description': description,
      'type': type,
      'startAt': _formatDateTime(startAt),
      'endAt': _formatDateTime(endAt),
    };
    final json = await _requestMap(
      () => _httpClient.post(
        _uri('/api/agenda'),
        headers: _headers(),
        body: jsonEncode(body),
      ),
    );
    return HealthEvent.fromJson(json);
  }

  Future<HealthEvent> updateAgendaEvent({
    required String eventId,
    required String title,
    required String description,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final json = await _requestMap(
      () => _httpClient.put(
        _uri('/api/agenda/$eventId'),
        headers: _headers(),
        body: jsonEncode({
          'title': title,
          'description': description,
          'type': type,
          'startAt': _formatDateTime(startAt),
          'endAt': _formatDateTime(endAt),
        }),
      ),
    );
    return HealthEvent.fromJson(json);
  }

  Future<HealthEvent> confirmAgendaEvent(String eventId) async {
    final json = await _requestMap(
      () => _httpClient.patch(
        _uri('/api/agenda/$eventId/confirm'),
        headers: _headers(),
      ),
    );
    return HealthEvent.fromJson(json);
  }

  Future<List<MedicalDocument>> getDocuments(String patientId) async {
    final json = await _requestList(
      () => _httpClient.get(
        _uri('/api/documents/patient/$patientId'),
        headers: _headers(),
      ),
    );
    return mapJsonList(json, MedicalDocument.fromJson);
  }

  Future<MedicalDocument> createMedicalDocument(String patientId) async {
    final json = await _requestMap(
      () => _httpClient.post(
        _uri('/api/documents'),
        headers: _headers(),
        body: jsonEncode({'patientId': patientId}),
      ),
    );
    return MedicalDocument.fromJson(json);
  }

  Future<MedicalDocument> addDocumentItem({
    required String medicalDocumentId,
    required String documentType,
    required String title,
    required String description,
    required String fileUrl,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    final json = await _requestMap(
      () => _httpClient.post(
        _uri('/api/documents/$medicalDocumentId/items'),
        headers: _headers(),
        body: jsonEncode({
          'documentType': documentType,
          'title': title,
          'description': description,
          'fileUrl': fileUrl,
          'mimeType': mimeType,
          'fileSizeBytes': fileSizeBytes,
          'uploadedAt': _formatDateTime(DateTime.now()),
        }),
      ),
    );
    return MedicalDocument.fromJson(json);
  }

  Future<List<DiaryEntry>> getDiaryEntries(String patientId) async {
    final json = await _requestList(
      () => _httpClient.get(
        _uri('/api/diary/patient/$patientId'),
        headers: _headers(),
      ),
    );
    return mapJsonList(json, DiaryEntry.fromJson);
  }

  Future<DiaryEntry> createDiaryEntry({
    required String patientId,
    required String content,
  }) async {
    final json = await _requestMap(
      () => _httpClient.post(
        _uri('/api/diary'),
        headers: _headers(),
        body: jsonEncode({'patientId': patientId, 'content': content}),
      ),
    );
    return DiaryEntry.fromJson(json);
  }

  Future<DiaryEntry> updateDiaryEntry({
    required String entryId,
    required String content,
  }) async {
    final json = await _requestMap(
      () => _httpClient.put(
        _uri('/api/diary/$entryId'),
        headers: _headers(),
        body: jsonEncode({'content': content}),
      ),
    );
    return DiaryEntry.fromJson(json);
  }

  Future<Map<String, dynamic>> _requestMap(
    Future<http.Response> Function() request,
  ) async {
    final decoded = await _send(request);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Respuesta inesperada del servidor');
  }

  Future<List<dynamic>> _requestList(
    Future<http.Response> Function() request,
  ) async {
    final decoded = await _send(request);
    if (decoded is List<dynamic>) return decoded;
    throw const ApiException('Respuesta inesperada del servidor');
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    late final http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 25));
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        'No se pudo conectar con CareConnect. Verificá tu conexión.',
      );
    }

    // JSON and problem+json responses are UTF-8, even without a charset header.
    final body = response.bodyBytes.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body ?? <String, dynamic>{};
    }

    String message = 'Ocurrió un error al sincronizar con CareConnect';
    if (body is Map<String, dynamic>) {
      message =
          body['detail']?.toString() ?? body['message']?.toString() ?? message;
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    String four(int number) => number.toString().padLeft(4, '0');
    return '${four(value.year)}-${two(value.month)}-${two(value.day)}T${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}

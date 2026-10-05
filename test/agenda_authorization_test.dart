import 'dart:convert';

import 'package:carestacks/core/network/api_exception.dart';
import 'package:carestacks/core/network/care_connect_api_client.dart';
import 'package:carestacks/features/auth/data/session_manager.dart';
import 'package:carestacks/features/caregiver/data/caregiver_models.dart';
import 'package:carestacks/features/caregiver/data/caregiver_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const patient = LinkedPatient(
    consentId: 'consent-test',
    patientId: 'patient-test',
    patientFullName: 'Paciente',
    caregiverId: 'caregiver-test',
    caregiverFullName: 'Cuidador',
    allowedViews: ['AGENDA'],
  );
  final user = {
    'id': 'caregiver-test',
    'email': 'caregiver@example.test',
    'fullName': 'Cuidador',
    'role': 'CAREGIVER',
    'active': true,
  };
  final event = {
    'id': 'event-test',
    'patientId': 'patient-test',
    'title': 'Control',
    'description': '',
    'type': 'APPOINTMENT',
    'status': 'PENDING',
    'startAt': '2027-01-02T10:00:00',
    'endAt': '2027-01-02T11:00:00',
  };
  late SharedPreferences preferences;
  late SessionManager session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    session = SessionManager(preferences);
    await session.saveSession(
      token: 'issued-token',
      user: UserProfile.fromJson(user),
    );
  });

  CaregiverRepository repository(MockClient client) => CaregiverRepository(
    apiClient: CareConnectApiClient(httpClient: client),
    sessionManager: session,
    preferences: preferences,
  );

  http.Response dashboardResponse(http.Request request) {
    switch (request.url.path) {
      case '/api/auth/me':
        return http.Response(jsonEncode(user), 200);
      case '/api/consents/me/caregiver/patients':
        return http.Response(jsonEncode([patient.toJson()]), 200);
      default:
        return http.Response('[]', 200);
    }
  }

  test(
    'Agenda reads and mutations carry the issued caregiver session',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        if (request.url.path.startsWith('/api/agenda')) {
          requests.add(request);
          return http.Response(
            jsonEncode(request.method == 'GET' ? [event] : event),
            200,
          );
        }
        return dashboardResponse(request);
      });
      addTearDown(client.close);
      final repo = repository(client);
      expect((await repo.loadDashboard()).events.single.id, 'event-test');
      HealthEventDraft draft(String? id) => HealthEventDraft(
        id: id,
        title: 'Control',
        description: '',
        type: 'APPOINTMENT',
        startAt: DateTime(2027, 1, 2, 10),
        endAt: DateTime(2027, 1, 2, 11),
      );
      await repo.saveAgendaEvent(patient: patient, draft: draft(null));
      await repo.saveAgendaEvent(patient: patient, draft: draft('event-test'));
      await repo.confirmEvent('event-test');
      expect(requests.map((r) => r.method), ['GET', 'POST', 'PUT', 'PATCH']);
      for (final request in requests) {
        expect(request.headers['Authorization'], 'Bearer issued-token');
      }
    },
  );

  for (final status in [401, 403, 503]) {
    test(
      'Agenda cache handles HTTP $status without hiding access denial',
      () async {
        await preferences.setString(
          'cache_agenda_patient-test',
          jsonEncode([event]),
        );
        final client = MockClient((request) async {
          if (request.url.path.startsWith('/api/agenda')) {
            return http.Response(jsonEncode({'detail': 'Unavailable'}), status);
          }
          return dashboardResponse(request);
        });
        addTearDown(client.close);
        final repo = repository(client);
        if (status == 503) {
          expect((await repo.loadDashboard()).events.single.id, 'event-test');
          expect(preferences.containsKey('cache_agenda_patient-test'), isTrue);
        } else {
          await expectLater(
            repo.loadDashboard(),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', status),
            ),
          );
          expect(preferences.containsKey('cache_agenda_patient-test'), isFalse);
        }
      },
    );
  }
}

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
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  CaregiverRepository repository(MockClient client) => CaregiverRepository(
    apiClient: CareConnectApiClient(httpClient: client),
    sessionManager: SessionManager(preferences),
    preferences: preferences,
  );

  final user = {
    'id': 'caregiver-test',
    'email': 'caregiver@example.test',
    'fullName': 'Cuidador de prueba',
    'role': 'CAREGIVER',
    'active': true,
  };

  test(
    'BDD-01 registration normalizes email and establishes a caregiver session',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/api/auth/register':
            return http.Response(jsonEncode(user), 201);
          case '/api/auth/login':
            return http.Response(
              jsonEncode({'token': 'test-token', 'expiresIn': 1800}),
              200,
            );
          case '/api/auth/me':
            return http.Response(jsonEncode(user), 200);
          default:
            throw StateError('Unexpected request ${request.url.path}');
        }
      });
      addTearDown(client.close);
      final repo = repository(client);
      await repo.registerCaregiver(
        fullName: ' Cuidador de prueba ',
        email: ' CAREGIVER@EXAMPLE.TEST ',
        password: 'TestPass123',
      );
      expect(requests.map((request) => request.url.path), [
        '/api/auth/register',
        '/api/auth/login',
        '/api/auth/me',
      ]);
      expect(jsonDecode(requests[0].body)['email'], 'caregiver@example.test');
      expect(jsonDecode(requests[0].body)['role'], 'CAREGIVER');
      expect(requests[2].headers['Authorization'], 'Bearer test-token');
      expect(repo.session.hasCaregiverSession, isTrue);
      expect(repo.session.userId, 'caregiver-test');
    },
  );

  test(
    'BDD-02 a patient account cannot establish a caregiver session',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode(
            request.url.path == '/api/auth/login'
                ? {'token': 'patient-token'}
                : {...user, 'role': 'PATIENT'},
          ),
          200,
        ),
      );
      addTearDown(client.close);
      final repo = repository(client);
      await expectLater(
        repo.signInCaregiver(
          email: 'patient@example.test',
          password: 'TestPass123',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(repo.session.token, isNull);
      expect(repo.session.hasCaregiverSession, isFalse);
    },
  );

  const patient = LinkedPatient(
    consentId: 'consent-test',
    patientId: 'patient-test',
    patientFullName: 'Paciente de prueba',
    caregiverId: 'caregiver-test',
    caregiverFullName: 'Cuidador de prueba',
    allowedViews: ['DOCUMENTS'],
  );

  test('BDD-03 agenda creation without permission sends no request', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    final start = DateTime(2027, 1, 2, 10);
    await expectLater(
      repository(client).saveAgendaEvent(
        patient: patient,
        draft: HealthEventDraft(
          title: 'Control',
          description: '',
          type: 'APPOINTMENT',
          startAt: start,
          endAt: start.add(const Duration(hours: 1)),
        ),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(requests, 0);
  });

  test('BDD-04 diary creation without permission sends no request', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response('{}', 200);
    });
    addTearDown(client.close);
    await expectLater(
      repository(client).saveDiaryEntry(
        patient: patient,
        draft: const DiaryEntryDraft(content: 'Nota privada'),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(requests, 0);
  });

  test(
    'BDD-05 incorrect credentials preserve the unauthenticated state',
    () async {
      final client = MockClient(
        (request) async =>
            http.Response(jsonEncode({'detail': 'Invalid credentials'}), 401),
      );
      addTearDown(client.close);
      final repo = repository(client);
      await expectLater(
        repo.signInCaregiver(
          email: 'caregiver@example.test',
          password: 'WrongPass123',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      expect(repo.session.token, isNull);
    },
  );
}

// Runs against a disposable local API, never against production by default.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:carestacks/core/config/api_config.dart';
import 'package:carestacks/core/network/api_exception.dart';
import 'package:carestacks/core/network/care_connect_api_client.dart';
import 'package:carestacks/features/auth/data/session_manager.dart';
import 'package:carestacks/features/caregiver/data/caregiver_models.dart';
import 'package:carestacks/features/caregiver/data/caregiver_repository.dart';
import 'package:carestacks/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

const password = 'TestPass123';
const evidenceDir = String.fromEnvironment('TB1_EVIDENCE_DIR');
const viewportWidth = int.fromEnvironment(
  'TB1_VIEWPORT_WIDTH',
  defaultValue: 1440,
);

class Fixture {
  Fixture(
    this.raw,
    this.api,
    this.repository,
    this.preferences,
    this.patient,
    this.patientToken,
    this.caregiver,
    this.caregiverEmail,
  );

  final http.Client raw;
  final CareConnectApiClient api;
  final CaregiverRepository repository;
  final SharedPreferences preferences;
  final Map<String, dynamic> patient;
  final String patientToken;
  final UserProfile caregiver;
  final String caregiverEmail;
  String? consentId;

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final request = http.Request(
      method,
      Uri.parse('${ApiConfig.baseUrl}$path'),
    );
    request.headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    return http.Response.fromStream(await raw.send(request));
  }

  Future<void> grant([
    List<String> views = const ['AGENDA', 'DIARY', 'DOCUMENTS'],
  ]) async {
    final result = await request(
      'POST',
      '/api/consents',
      token: patientToken,
      body: {'caregiverId': caregiver.id, 'allowedViews': views},
    );
    expect(result.statusCode, 201, reason: result.body);
    consentId =
        (jsonDecode(result.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<void> revoke() async {
    final response = await request(
      'DELETE',
      '/api/consents/$consentId',
      token: patientToken,
    );
    expect(response.statusCode, 204, reason: response.body);
  }

  Future<LinkedPatient> linkedPatient() async {
    final dashboard = await repository.loadDashboard();
    expect(dashboard.activePatient?.patientId, patient['id']);
    return dashboard.activePatient!;
  }

  Future<String> event(LinkedPatient patient) async {
    final start = DateTime.now().add(const Duration(minutes: 30));
    await repository.saveAgendaEvent(
      patient: patient,
      draft: HealthEventDraft(
        title: 'Control TB1',
        description: 'Datos sintéticos',
        type: 'APPOINTMENT',
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
      ),
    );
    final events = await api.getAgendaEvents(patient.patientId);
    return events.singleWhere((event) => event.title == 'Control TB1').id;
  }
}

Future<Fixture> fixture() async {
  final uri = Uri.parse(ApiConfig.baseUrl);
  if (!['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host)) {
    throw StateError('System tests require a disposable local API.');
  }
  // This external-API test suite intentionally lives outside the default test directory.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  // Use real HTTP; flutter_test's default HTTP stub would return 400.
  final raw = IOClient(HttpClient());
  addTearDown(raw.close);
  final api = CareConnectApiClient(httpClient: raw);
  final repository = CaregiverRepository(
    apiClient: api,
    sessionManager: SessionManager(preferences),
    preferences: preferences,
  );
  final suffix = '${DateTime.now().microsecondsSinceEpoch}';
  final patientEmail = 'patient-$suffix@example.test';
  final caregiverEmail = 'caregiver-$suffix@example.test';
  final registration = await raw.post(
    Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': patientEmail,
      'password': password,
      'fullName': 'Paciente TB1',
      'role': 'PATIENT',
    }),
  );
  expect(registration.statusCode, 201, reason: registration.body);
  final patient = jsonDecode(registration.body) as Map<String, dynamic>;
  final patientLogin = await api.login(email: patientEmail, password: password);
  final caregiver = await repository.registerCaregiver(
    fullName: 'Cuidador TB1',
    email: caregiverEmail,
    password: password,
  );
  return Fixture(
    raw,
    api,
    repository,
    preferences,
    patient,
    patientLogin.token,
    caregiver,
    caregiverEmail,
  );
}

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 40));
    if (ready()) return;
  }
  fail('The UI did not reach the expected state within 6 seconds.');
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  if (evidenceDir.isEmpty) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ImageByteFormat.png);
    final directory = Directory(evidenceDir);
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final host = Uri.parse(ApiConfig.baseUrl).host;
    if (!['localhost', '127.0.0.1', '10.0.2.2'].contains(host)) {
      throw StateError('System tests require a disposable local API.');
    }
    const fontPath = String.fromEnvironment('TB1_TEST_FONT');
    const iconPath = String.fromEnvironment('TB1_ICON_FONT');
    // Widget tests normally use Ahem. Optional real fonts make evidence legible.
    if (fontPath.isNotEmpty) {
      final data = ByteData.sublistView(await File(fontPath).readAsBytes());
      // Inter is supplied by the browser in production; map it to this test font.
      for (final family in ['Inter', 'Segoe UI', 'Roboto', 'sans-serif']) {
        await (FontLoader(family)..addFont(Future.value(data))).load();
      }
    }
    if (iconPath.isNotEmpty) {
      final data = ByteData.sublistView(await File(iconPath).readAsBytes());
      await (FontLoader('MaterialIcons')..addFont(Future.value(data))).load();
    }
  });
  setUp(() => HttpOverrides.global = null);

  test(
    'SYS-01 Given registered users, When sharing and confirming, Then the event persists',
    () async {
      final f = await fixture();
      await f.grant();
      final patient = await f.linkedPatient();
      final eventId = await f.event(patient);
      await f.repository.confirmEvent(eventId);
      final events = await f.api.getAgendaEvents(patient.patientId);
      expect(
        events.singleWhere((event) => event.id == eventId).status,
        'CONFIRMED',
      );
      await f.repository.saveDiaryEntry(
        patient: patient,
        draft: const DiaryEntryDraft(content: 'Evolución TB1'),
      );
      expect(
        (await f.api.getDiaryEntries(patient.patientId)).single.content,
        'Evolución TB1',
      );
      await f.revoke();
      final access = await f.request(
        'GET',
        '/api/consents/me/caregiver/access?patientId=${patient.patientId}&view=AGENDA',
        token: f.repository.session.token,
      );
      expect(access.statusCode, 404);
    },
  );

  test(
    'SYS-02 Given an account, When the password is wrong, Then login is rejected',
    () async {
      final f = await fixture();
      await expectLater(
        f.api.login(email: f.caregiverEmail, password: 'WrongPass123'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    },
  );

  test(
    'SYS-03 Given a new caregiver, When loading home, Then an empty dashboard is shown',
    () async {
      final f = await fixture();
      final dashboard = await f.repository.loadDashboard();
      expect(dashboard.patients, isEmpty);
      expect(dashboard.activePatient, isNull);
    },
  );

  test(
    'SYS-04 Given cached patient data, When consent is revoked, Then home removes the patient',
    () async {
      final f = await fixture();
      await f.grant();
      await f.linkedPatient();
      await f.revoke();
      final dashboard = await f.repository.loadDashboard();
      expect(dashboard.patients, isEmpty);
      expect(dashboard.activePatient, isNull);
    },
  );

  test(
    'SYS-05 Given agenda-only consent, When diary is opened, Then its content is not downloaded',
    () async {
      final f = await fixture();
      await f.grant(['AGENDA']);
      final created = await f.request(
        'POST',
        '/api/diary',
        body: {'patientId': f.patient['id'], 'content': 'Nota privada TB1'},
        token: f.patientToken,
      );
      expect(created.statusCode, 201);
      final dashboard = await f.repository.loadDashboard();
      expect(dashboard.activePatient!.allows('DIARY'), isFalse);
      expect(dashboard.diaryEntries, isEmpty);
    },
  );

  test(
    'SYS-06 Given a revoked consent, When requesting agenda directly, Then the API denies access',
    () async {
      final f = await fixture();
      await f.grant();
      final patient = await f.linkedPatient();
      await f.event(patient);
      await f.revoke();
      final result = await f.request(
        'GET',
        '/api/agenda/patient/${patient.patientId}',
        token: f.repository.session.token,
      );
      expect(
        result.statusCode,
        anyOf(401, 403),
        reason: 'Revocation must protect the data endpoint.',
      );
    },
  );

  test(
    'SYS-07 Given no session, When requesting agenda, Then the API denies access',
    () async {
      final f = await fixture();
      await f.grant();
      final patient = await f.linkedPatient();
      await f.event(patient);
      final result = await f.request(
        'GET',
        '/api/agenda/patient/${patient.patientId}',
      );
      expect(
        result.statusCode,
        anyOf(401, 403),
        reason: 'Data requires authentication.',
      );
    },
  );

  testWidgets(
    'SYS-08 Given a linked caregiver, When logging in and tapping Confirmar, Then the UI and API update',
    (tester) async {
      tester.view.physicalSize = Size(viewportWidth.toDouble(), 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = (await tester.runAsync(() => fixture()))!;
      final eventId = (await tester.runAsync(() async {
        await f.grant();
        return f.event(await f.linkedPatient());
      }))!;
      await f.repository.session.clear();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: const MainApp()),
      );
      await waitFor(
        tester,
        () => find.byType(TextField).evaluate().length == 2,
      );
      await screenshot(tester, key, 'login');
      await tester.enterText(find.byType(TextField).at(0), f.caregiverEmail);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.tap(find.text('Ingresar'));
      await waitFor(
        tester,
        () => find.textContaining('TB1').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Agenda').first);
      await waitFor(
        tester,
        () => find.text('Control TB1').evaluate().isNotEmpty,
      );
      await screenshot(tester, key, 'agenda-pending');
      final confirm = find.textContaining('Confirmar');
      expect(confirm, findsWidgets);
      await tester.ensureVisible(confirm.first);
      await tester.pumpAndSettle();
      await screenshot(tester, key, 'agenda-pending');
      await tester.tap(confirm.hitTestable().first);
      await waitFor(
        tester,
        () => find.text('Evento confirmado.').evaluate().isNotEmpty,
      );
      final events = (await tester.runAsync(
        () => f.api.getAgendaEvents(f.patient['id'] as String),
      ))!;
      expect(
        events.singleWhere((event) => event.id == eventId).status,
        'CONFIRMED',
      );
      await screenshot(tester, key, 'agenda-confirmed');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets(
    'SYS-09 Given a new caregiver, When registering from the form, Then home shows no linked patient',
    (tester) async {
      tester.view.physicalSize = Size(viewportWidth.toDouble(), 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Local session storage is isolated; registration and login use the real API.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final email = 'ui-${DateTime.now().microsecondsSinceEpoch}@example.test';
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: const MainApp()),
      );
      await waitFor(
        tester,
        () => find.byType(TextField).evaluate().length == 2,
      );
      await tester.tap(find.textContaining('No tienes cuenta? Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(3));
      await tester.enterText(find.byType(TextField).at(0), 'Cuidador UI TB1');
      await tester.enterText(find.byType(TextField).at(1), email);
      await tester.enterText(find.byType(TextField).at(2), password);
      final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await screenshot(tester, key, 'registration');
      await tester.tap(submit.hitTestable());
      await waitFor(tester, () => find.text('Agenda').evaluate().isNotEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(SessionManager(preferences).hasCaregiverSession, isTrue);
      expect(SessionManager(preferences).activePatientId, isNull);
      expect(find.textContaining('pacientes activos'), findsWidgets);
      await screenshot(tester, key, 'home-no-patient');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 30));
    },
  );
}

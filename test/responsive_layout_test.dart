import 'package:carestacks/core/theme/theme.dart';
import 'package:carestacks/core/widgets/widgets.dart';
import 'package:carestacks/features/caregiver/data/caregiver_models.dart';
import 'package:carestacks/features/caregiver/presentation/caregiver_agenda_page.dart';
import 'package:carestacks/features/caregiver/presentation/caregiver_diary_page.dart';
import 'package:carestacks/features/caregiver/presentation/caregiver_documents_page.dart';
import 'package:carestacks/features/caregiver/presentation/caregiver_home_page.dart';
import 'package:carestacks/features/caregiver/presentation/caregiver_notifications_page.dart';
import 'package:carestacks/features/caregiver/presentation/caregiver_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _viewports = <String, Size>{
  'phone': Size(390, 844),
  'tablet': Size(1024, 768),
  'desktop': Size(1440, 900),
  'wide': Size(1920, 1080),
};

CaregiverDashboardData _dashboard() {
  final now = DateTime.now();
  String at(int hour) =>
      DateTime(now.year, now.month, now.day, hour).toIso8601String();

  return CaregiverDashboardData(
    user: const UserProfile(
      id: 'u1',
      email: 'percy@example.com',
      fullName: 'Percy Alonso Ramírez',
      role: 'CAREGIVER',
      active: true,
    ),
    patients: const [
      LinkedPatient(
        consentId: 'c1',
        patientId: 'p1',
        patientFullName: 'Rosa Méndez Quiroga',
        caregiverId: 'u1',
        caregiverFullName: 'Percy Alonso Ramírez',
        allowedViews: ['AGENDA', 'DOCUMENTS', 'DIARY', 'NOTIFICATIONS'],
      ),
      LinkedPatient(
        consentId: 'c2',
        patientId: 'p2',
        patientFullName: 'Luis Ferreyra',
        caregiverId: 'u1',
        caregiverFullName: 'Percy Alonso Ramírez',
        allowedViews: ['AGENDA'],
      ),
    ],
    activePatient: const LinkedPatient(
      consentId: 'c1',
      patientId: 'p1',
      patientFullName: 'Rosa Méndez Quiroga',
      caregiverId: 'u1',
      caregiverFullName: 'Percy Alonso Ramírez',
      allowedViews: ['AGENDA', 'DOCUMENTS', 'DIARY', 'NOTIFICATIONS'],
    ),
    invitations: [
      CaregiverInvitation(
        id: 'i1',
        patientId: 'p3',
        patientFullName: 'Amelia Torres del Castillo',
        patientEmail: 'amelia@example.com',
        caregiverId: 'u1',
        caregiverFullName: 'Percy Alonso Ramírez',
        allowedViews: const ['AGENDA', 'DIARY'],
        status: 'PENDING',
        createdAt: at(9),
      ),
    ],
    notifications: [
      CareNotification(
        id: 'n1',
        title: 'Recordatorio de medicación',
        message: 'Losartán 50 mg a las 09:30.',
        type: 'REMINDER',
        priority: 'HIGH',
        status: 'SENT',
        createdAt: at(8),
        sentAt: at(8),
      ),
      CareNotification(
        id: 'n2',
        title: 'Documento nuevo',
        message: 'Se agregó un informe de laboratorio.',
        type: 'INFO',
        priority: 'MEDIUM',
        status: 'READ',
        createdAt: at(7),
        sentAt: at(7),
        readAt: at(7),
      ),
    ],
    events: [
      HealthEvent(
        id: 'e1',
        patientId: 'p1',
        title: 'Losartán 50 mg',
        description: 'Con el desayuno, controlar presión antes de la toma.',
        type: 'MEDICATION',
        status: 'PENDING',
        startAt: at(9),
        endAt: at(10),
      ),
      HealthEvent(
        id: 'e2',
        patientId: 'p1',
        title: 'Kinesiología',
        description: 'Sesión de movilidad en el centro de rehabilitación.',
        type: 'THERAPY',
        status: 'CONFIRMED',
        startAt: at(13),
        endAt: at(14),
      ),
      HealthEvent(
        id: 'e3',
        patientId: 'p1',
        title: 'Control cardiológico',
        description: 'Consultorio 402, llevar electrocardiograma previo.',
        type: 'APPOINTMENT',
        status: 'MISSED',
        startAt: at(17),
        endAt: at(18),
      ),
    ],
    documents: [
      MedicalDocument(
        id: 'd1',
        patientId: 'p1',
        items: [
          DocumentItem(
            id: 'di1',
            documentType: 'LAB_RESULT',
            title: 'Hemograma completo agosto',
            description: 'Valores dentro de rango, hierro en el límite bajo.',
            fileUrl: 'https://example.com/hemograma.pdf',
            mimeType: 'application/pdf',
            fileSizeBytes: 240000,
            uploadedAt: at(6),
          ),
          DocumentItem(
            id: 'di2',
            documentType: 'IMAGING',
            title: 'Radiografía de tórax',
            description: 'Sin hallazgos agudos.',
            fileUrl: 'https://example.com/rx.png',
            mimeType: 'image/png',
            fileSizeBytes: 1800000,
            uploadedAt: at(5),
          ),
        ],
      ),
    ],
    diaryEntries: [
      DiaryEntry(
        id: 'de1',
        patientId: 'p1',
        content:
            'Durmió siete horas seguidas. Desayunó completo y caminó veinte minutos por el patio sin bastón.',
        entryDate: at(8),
      ),
      DiaryEntry(
        id: 'de2',
        patientId: 'p1',
        content: 'Tarde tranquila, algo de dolor en la rodilla izquierda.',
        entryDate: at(4),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
  await tester.pumpAndSettle();
}

void main() {
  final dashboard = _dashboard();
  Future<void> noop() async {}
  Future<void> withId(String _) async {}

  final pages = <String, Widget>{
    'home': CaregiverHomePage(
      dashboard: dashboard,
      onNavigate: (_) {},
      onRefresh: noop,
      onAcceptInvitation: withId,
      onRejectInvitation: withId,
      onConfirmEvent: withId,
      onNotificationsPressed: () {},
      onLogout: () {},
    ),
    'agenda': CaregiverAgendaPage(
      dashboard: dashboard,
      onConfirmEvent: withId,
      onSaveEvent: (_) async {},
      onNotificationsPressed: () {},
      onRefresh: noop,
      onNavigate: (_) {},
      onLogout: () {},
    ),
    'documents': CaregiverDocumentsPage(
      dashboard: dashboard,
      onAddDocument: (_) async {},
      onNotificationsPressed: () {},
      onRefresh: noop,
      onNavigate: (_) {},
      onLogout: () {},
    ),
    'diary': CaregiverDiaryPage(
      dashboard: dashboard,
      onSaveEntry: (_) async {},
      onNotificationsPressed: () {},
      onRefresh: noop,
      onNavigate: (_) {},
      onLogout: () {},
    ),
    'profile': CaregiverProfilePage(
      dashboard: dashboard,
      onPatientSelected: withId,
      onLogout: () {},
      onNotificationsPressed: () {},
      onNavigate: (_) {},
    ),
  };

  for (final entry in pages.entries) {
    for (final viewport in _viewports.entries) {
      testWidgets('${entry.key} renders at ${viewport.key}', (tester) async {
        await _pump(tester, viewport.value, entry.value);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('sidebar replaces bottom nav above 768px', (tester) async {
    await _pump(tester, const Size(1440, 900), pages['home']!);
    expect(find.byType(CareSideNav), findsOneWidget);
    expect(find.byType(CareBottomNavBar), findsNothing);
    expect(find.byType(CareRailPanel), findsOneWidget);
  });

  testWidgets('tablet collapses the sidebar and drops the rail', (
    tester,
  ) async {
    await _pump(tester, const Size(1024, 768), pages['home']!);
    expect(find.byType(CareSideNav), findsOneWidget);
    expect(find.byType(CareRailPanel), findsNothing);
    expect(find.text('Inicio'), findsNothing);
  });

  for (final viewport in _viewports.entries) {
    testWidgets('notifications panel renders at ${viewport.key}', (
      tester,
    ) async {
      await _pump(
        tester,
        viewport.value,
        Scaffold(
          body: CaregiverNotificationsPanel(
            dashboard: dashboard,
            onAcceptInvitation: withId,
            onRejectInvitation: withId,
            onMarkAsRead: withId,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('phone keeps the bottom nav', (tester) async {
    await _pump(tester, const Size(390, 844), pages['home']!);
    expect(find.byType(CareBottomNavBar), findsOneWidget);
    expect(find.byType(CareSideNav), findsNothing);
  });
}

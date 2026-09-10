import 'package:flutter/material.dart';

import 'core/theme/theme.dart';
import 'features/auth/presentation/auth_gate_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareConnect',
      theme: AppTheme.light,
      home: const CaregiverAuthGate(),
    );
  }
}

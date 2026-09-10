import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/care_connect_api_client.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../caregiver/data/caregiver_repository.dart';
import '../../caregiver/presentation/caregiver_main_page.dart';
import '../data/session_manager.dart';

class CaregiverAuthGate extends StatefulWidget {
  const CaregiverAuthGate({super.key});

  @override
  State<CaregiverAuthGate> createState() => _CaregiverAuthGateState();
}

class _CaregiverAuthGateState extends State<CaregiverAuthGate> {
  CaregiverRepository? _repository;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final preferences = await SharedPreferences.getInstance();
    final repository = CaregiverRepository(
      apiClient: CareConnectApiClient(),
      sessionManager: SessionManager(preferences),
      preferences: preferences,
    );
    if (!mounted) return;
    setState(() {
      _repository = repository;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    if (_loading || repository == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (repository.session.hasCaregiverSession) {
      return CaregiverMainPage(
        repository: repository,
        onLoggedOut: () => setState(() {}),
      );
    }

    return _CaregiverLoginPage(
      repository: repository,
      onAuthenticated: () => setState(() {}),
    );
  }
}

class _CaregiverLoginPage extends StatefulWidget {
  const _CaregiverLoginPage({
    required this.repository,
    required this.onAuthenticated,
  });

  final CaregiverRepository repository;
  final VoidCallback onAuthenticated;

  @override
  State<_CaregiverLoginPage> createState() => _CaregiverLoginPageState();
}

class _CaregiverLoginPageState extends State<_CaregiverLoginPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registerMode = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Ingresá tu correo y contraseña.');
      return;
    }
    if (_registerMode && _nameController.text.trim().isEmpty) {
      setState(() => _error = 'Ingresá tu nombre completo.');
      return;
    }
    if (_registerMode && password.length < 8) {
      setState(
        () => _error = 'La contraseña debe tener al menos 8 caracteres.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (_registerMode) {
        await widget.repository.registerCaregiver(
          fullName: _nameController.text,
          email: email,
          password: password,
        );
      } else {
        await widget.repository.signInCaregiver(
          email: email,
          password: password,
        );
      }
      widget.onAuthenticated();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'No se pudo iniciar sesión. Intentá nuevamente.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    final form = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: layout.gutter, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!layout.isDesktop) ...[
                const _BrandMark(),
                const SizedBox(height: 24),
              ],
              Text(
                _registerMode ? 'Crear cuenta' : 'Iniciar sesión',
                style: layout.pageTitle,
              ),
              const SizedBox(height: 6),
              Text(
                _registerMode
                    ? 'Registra tu cuenta de cuidador para recibir invitaciones de pacientes.'
                    : 'Entra con tu cuenta de cuidador para ver la agenda, los documentos y el diario del paciente.',
                style: layout.bodyMuted,
              ),
              const SizedBox(height: 24),
              CareCard(
                variant: CareCardVariant.hero,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_registerMode) ...[
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombres y apellidos',
                          hintText: 'Ej. Patricia López',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'nombre@ejemplo.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.redDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CarePrimaryButton(
                      label: _submitting
                          ? (_registerMode ? 'Creando cuenta…' : 'Ingresando…')
                          : (_registerMode ? 'Crear cuenta' : 'Ingresar'),
                      enabled: !_submitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _registerMode = !_registerMode),
                  child: Text(
                    _registerMode
                        ? '¿Ya tienes una cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Crear cuenta',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: layout.isDesktop
            ? Row(
                children: [
                  const Expanded(flex: 5, child: _AuthBrandPanel()),
                  Expanded(flex: 6, child: form),
                ],
              )
            : form,
      ),
    );
  }
}

/// Columna de marca del login. Solo en escritorio: en teléfono el formulario
/// necesita todo el ancho.
class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(onDark: true),
          const Spacer(),
          Text(
            'Todo el cuidado de tu paciente, en una sola vista.',
            style: AppTextStyles.headlineLarge.copyWith(
              fontSize: 32,
              height: 40 / 32,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: 28),
          const _BrandPoint(
            icon: Icons.calendar_today_outlined,
            label: 'Agenda de salud con la semana completa a la vista',
          ),
          const SizedBox(height: 14),
          const _BrandPoint(
            icon: Icons.description_outlined,
            label: 'Documentos médicos ordenados y buscables',
          ),
          const SizedBox(height: 14),
          const _BrandPoint(
            icon: Icons.edit_note_outlined,
            label: 'Diario de seguimiento compartido con la familia',
          ),
          const Spacer(),
          Text(
            'Acceso sujeto a los permisos que cada paciente comparte.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: onDark ? AppColors.surface : AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.favorite_rounded,
            size: 18,
            color: onDark ? AppColors.primaryDark : AppColors.surface,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'CareConnect',
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 17,
            color: onDark ? AppColors.surface : AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _BrandPoint extends StatelessWidget {
  const _BrandPoint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: 15,
              color: AppColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

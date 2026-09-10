import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../data/caregiver_models.dart';

class CaregiverDiaryPage extends StatefulWidget {
  const CaregiverDiaryPage({
    super.key,
    required this.dashboard,
    required this.onSaveEntry,
    required this.onNotificationsPressed,
    required this.onRefresh,
    required this.onNavigate,
    required this.onLogout,
  });

  final CaregiverDashboardData dashboard;
  final Future<void> Function(DiaryEntryDraft draft) onSaveEntry;
  final VoidCallback onNotificationsPressed;
  final Future<void> Function() onRefresh;
  final ValueChanged<CareNavDestination> onNavigate;
  final VoidCallback onLogout;

  @override
  State<CaregiverDiaryPage> createState() => _CaregiverDiaryPageState();
}

class _CaregiverDiaryPageState extends State<CaregiverDiaryPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _editingId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final patient = widget.dashboard.activePatient;
    final allowed = patient != null && patient.allows('DIARY');
    final entries = widget.dashboard.diaryEntries;
    final unread = widget.dashboard.notifications
        .where((notification) => notification.readAt == null)
        .length;
    final last = entries.isEmpty ? null : entries.first;

    return CareAppShell(
      destination: CareNavDestination.diary,
      onDestinationSelected: widget.onNavigate,
      title: 'Diario',
      subtitle: patient == null
          ? 'Sin paciente activo'
          : last == null
          ? '${patient.patientFullName} · sin notas todavía'
          : '${patient.patientFullName} · ${entries.length} notas, última ${CareDateFormatters.relative(last.entryDate)}',
      userName: widget.dashboard.user.fullName,
      userRole: 'Cuidador',
      onLogout: widget.onLogout,
      onNotificationsPressed: widget.onNotificationsPressed,
      notificationCount: unread,
      actions: [
        if (allowed)
          CareHeaderButton(
            label: 'Nueva nota',
            icon: Icons.add_rounded,
            onPressed: () => _startNewEntry(context),
          ),
      ],
      compactBottom: allowed
          ? Padding(
              padding: EdgeInsets.fromLTRB(layout.gutter, 0, layout.gutter, 12),
              child: CarePrimaryButton(
                label: 'Nueva nota',
                icon: Icons.add_rounded,
                onPressed: () => _startNewEntry(context),
              ),
            )
          : null,
      content: CarePageBody(
        onRefresh: widget.onRefresh,
        children: [
          if (!allowed)
            CareEmptyState(
              icon: patient == null
                  ? Icons.group_add_outlined
                  : Icons.lock_outline,
              title: patient == null
                  ? 'Sin paciente activo'
                  : 'Diario no compartido',
              message: patient == null
                  ? 'Acepta una invitación para leer y escribir el diario de seguimiento.'
                  : 'Este paciente no habilitó el acceso a su diario.',
            )
          else if (entries.isEmpty)
            CareEmptyState(
              icon: Icons.edit_note_outlined,
              title: 'El diario está vacío',
              message:
                  'Registra cómo pasó el día ${patient.patientFullName.split(' ').first}: ánimo, sueño, apetito o cualquier señal a seguir.',
            )
          else
            CareGrid(
              columns: layout.isExpanded ? 2 : layout.gridColumns,
              spacing: layout.columnGap,
              runSpacing: layout.columnGap,
              items: [
                for (final entry in entries)
                  CareGridItem(
                    child: _DiaryNoteCard(
                      entry: entry,
                      author: patient.patientFullName,
                      selected: entry.id == _editingId,
                      onEdit: () => _startEditing(context, entry),
                    ),
                  ),
              ],
            ),
        ],
      ),
      rail: layout.hasRail && allowed
          ? CareRailPanel(
              children: [
                _DiaryEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  editing: _editingId != null,
                  saving: _saving,
                  error: _error,
                  onCancel: _resetEditor,
                  onSave: _save,
                ),
              ],
            )
          : null,
    );
  }

  void _startNewEntry(BuildContext context) {
    if (CareLayout.of(context).hasRail) {
      setState(() {
        _editingId = null;
        _error = null;
        _controller.clear();
      });
      _focusNode.requestFocus();
      return;
    }
    careShowForm(
      context,
      child: _DiaryFormSheet(entry: null, onSave: widget.onSaveEntry),
    );
  }

  void _startEditing(BuildContext context, DiaryEntry entry) {
    if (CareLayout.of(context).hasRail) {
      setState(() {
        _editingId = entry.id;
        _error = null;
        _controller.text = entry.content;
      });
      _focusNode.requestFocus();
      return;
    }
    careShowForm(
      context,
      child: _DiaryFormSheet(entry: entry, onSave: widget.onSaveEntry),
    );
  }

  void _resetEditor() {
    setState(() {
      _editingId = null;
      _error = null;
      _controller.clear();
    });
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Escribe el contenido de la nota.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSaveEntry(
        DiaryEntryDraft(id: _editingId, content: content),
      );
      if (!mounted) return;
      _resetEditor();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(error, 'No se pudo guardar.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DiaryNoteCard extends StatelessWidget {
  const _DiaryNoteCard({
    required this.entry,
    required this.author,
    required this.selected,
    required this.onEdit,
  });

  final DiaryEntry entry;
  final String author;
  final bool selected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      selected: selected,
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 34,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CareDateFormatters.relative(entry.entryDate),
                      style: layout.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      CareDateFormatters.dateTime(entry.entryDate),
                      style: layout.meta,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar nota',
                onPressed: onEdit,
                iconSize: 18,
                color: AppColors.iconMuted,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              entry.content,
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
              style: layout.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor pegado al panel derecho: escribir no obliga a tapar la pantalla
/// con un modal en escritorio.
class _DiaryEditor extends StatelessWidget {
  const _DiaryEditor({
    required this.controller,
    required this.focusNode,
    required this.editing,
    required this.saving,
    required this.error,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editing;
  final bool saving;
  final String? error;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CareSectionTitle(editing ? 'Editar nota' : 'Nueva nota'),
        const SizedBox(height: 12),
        CareCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 9,
                maxLines: 16,
                style: layout.body,
                decoration: InputDecoration(
                  hintText:
                      'Ánimo, sueño, apetito, medicación, señales a seguir…',
                  hintStyle: layout.body.copyWith(color: AppColors.textMuted),
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: layout.meta.copyWith(color: AppColors.redDark),
                ),
              ],
              const SizedBox(height: 14),
              const CareHairline(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (editing) ...[
                    TextButton(
                      onPressed: saving ? null : onCancel,
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  CareHeaderButton(
                    label: saving ? 'Guardando…' : 'Guardar',
                    icon: Icons.check_rounded,
                    onPressed: saving ? null : () => onSave(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiaryFormSheet extends StatefulWidget {
  const _DiaryFormSheet({required this.entry, required this.onSave});

  final DiaryEntry? entry;
  final Future<void> Function(DiaryEntryDraft draft) onSave;

  @override
  State<_DiaryFormSheet> createState() => _DiaryFormSheetState();
}

class _DiaryFormSheetState extends State<_DiaryFormSheet> {
  late final TextEditingController _contentController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.entry != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, bottomInset + 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing ? 'Editar nota' : 'Nueva nota',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _contentController,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  hintText: 'Escribe una nota del cuidado diario…',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.redDark,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  CareHeaderButton(
                    label: _saving ? 'Guardando…' : 'Guardar nota',
                    icon: Icons.check_rounded,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Escribe el contenido de la nota.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(
        DiaryEntryDraft(id: widget.entry?.id, content: content),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = _errorMessage(error, 'No se pudo guardar.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String _errorMessage(Object error, String fallback) {
  if (error is ApiException) return error.message;
  return fallback;
}

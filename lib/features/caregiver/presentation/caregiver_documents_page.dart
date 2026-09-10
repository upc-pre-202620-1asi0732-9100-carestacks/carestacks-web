import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../data/caregiver_models.dart';
import 'caregiver_ui_helpers.dart';

class CaregiverDocumentsPage extends StatefulWidget {
  const CaregiverDocumentsPage({
    super.key,
    required this.dashboard,
    required this.onAddDocument,
    required this.onNotificationsPressed,
    required this.onRefresh,
    required this.onNavigate,
    required this.onLogout,
  });

  final CaregiverDashboardData dashboard;
  final Future<void> Function(DocumentItemDraft draft) onAddDocument;
  final VoidCallback onNotificationsPressed;
  final Future<void> Function() onRefresh;
  final ValueChanged<CareNavDestination> onNavigate;
  final VoidCallback onLogout;

  @override
  State<CaregiverDocumentsPage> createState() => _CaregiverDocumentsPageState();
}

class _CaregiverDocumentsPageState extends State<CaregiverDocumentsPage> {
  String _query = '';
  String? _typeFilter;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final patient = widget.dashboard.activePatient;
    final allowed = patient != null && patient.allows('DOCUMENTS');
    final all = widget.dashboard.documentItems;
    final documents = _filter(all);
    final selected = _selectedDocument(documents);
    final unread = widget.dashboard.notifications
        .where((notification) => notification.readAt == null)
        .length;

    return CareAppShell(
      destination: CareNavDestination.documents,
      onDestinationSelected: widget.onNavigate,
      title: 'Documentos',
      subtitle: patient == null
          ? 'Sin paciente activo'
          : '${patient.patientFullName} · ${all.length} archivos en el historial',
      userName: widget.dashboard.user.fullName,
      userRole: 'Cuidador',
      onLogout: widget.onLogout,
      onNotificationsPressed: widget.onNotificationsPressed,
      notificationCount: unread,
      actions: [
        if (!layout.isCompact)
          SizedBox(
            width: layout.isExpanded ? 260 : 200,
            child: _CompactSearchField(
              value: _query,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        if (allowed)
          CareHeaderButton(
            label: 'Subir documento',
            icon: Icons.upload_file_outlined,
            onPressed: () => _showDocumentForm(context),
          ),
      ],
      content: CarePageBody(
        onRefresh: widget.onRefresh,
        children: [
          if (layout.isCompact) ...[
            CareSearchField(
              hintText: 'Buscar documentos…',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
          ],
          if (!allowed)
            CareEmptyState(
              icon: patient == null
                  ? Icons.group_add_outlined
                  : Icons.lock_outline,
              title: patient == null
                  ? 'Sin paciente activo'
                  : 'Documentos no compartidos',
              message: patient == null
                  ? 'Acepta una invitación para ver el historial médico compartido.'
                  : 'Este paciente no habilitó el acceso a sus documentos.',
            )
          else ...[
            _TypeFilters(
              types: _availableTypes(all),
              selected: _typeFilter,
              counts: _countsByType(all),
              total: all.length,
              onSelected: (type) => setState(() => _typeFilter = type),
            ),
            const SizedBox(height: 18),
            if (documents.isEmpty)
              CareEmptyState(
                icon: Icons.folder_off_outlined,
                message: all.isEmpty
                    ? 'Todavía no hay documentos sincronizados para este paciente.'
                    : 'Ningún documento coincide con la búsqueda.',
              )
            else if (layout.isCompact)
              for (final item in documents) ...[
                CareDocumentTile(
                  icon: documentIcon(item.documentType),
                  title: item.title,
                  typeLabel: documentTypeLabel(item.documentType),
                  dateLabel: CareDateFormatters.date(item.uploadedAt),
                  onTap: () => _openDetails(context, item),
                  badgeBackgroundColor: toneBackground(
                    _toneFor(item.documentType),
                  ),
                  badgeTextColor: toneForeground(_toneFor(item.documentType)),
                ),
                const SizedBox(height: 12),
              ]
            else
              _DocumentTable(
                documents: documents,
                selectedId: selected?.id,
                onSelected: (item) {
                  setState(() => _selectedId = item.id);
                  if (!CareLayout.of(context).hasRail) {
                    _openDetails(context, item);
                  }
                },
              ),
          ],
        ],
      ),
      rail: layout.hasRail && allowed
          ? CareRailPanel(
              children: [
                if (selected == null)
                  CareEmptyState(
                    dense: true,
                    icon: Icons.touch_app_outlined,
                    message: documents.isEmpty
                        ? 'No hay documentos para revisar.'
                        : 'Elige un documento de la lista para ver su detalle.',
                  )
                else
                  _DocumentDetail(item: selected),
              ],
            )
          : null,
    );
  }

  List<DocumentItem> _filter(List<DocumentItem> source) {
    final query = _query.trim().toLowerCase();
    return source.where((item) {
      final matchesType =
          _typeFilter == null || item.documentType == _typeFilter;
      if (!matchesType) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          documentTypeLabel(item.documentType).toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  DocumentItem? _selectedDocument(List<DocumentItem> documents) {
    if (documents.isEmpty) return null;
    for (final item in documents) {
      if (item.id == _selectedId) return item;
    }
    return documents.first;
  }

  List<String> _availableTypes(List<DocumentItem> source) {
    final types = <String>{for (final item in source) item.documentType};
    return types.toList()..sort();
  }

  Map<String, int> _countsByType(List<DocumentItem> source) {
    final counts = <String, int>{};
    for (final item in source) {
      counts[item.documentType] = (counts[item.documentType] ?? 0) + 1;
    }
    return counts;
  }

  void _showDocumentForm(BuildContext context) {
    careShowForm(
      context,
      child: _DocumentFormSheet(onSave: widget.onAddDocument),
    );
  }

  void _openDetails(BuildContext context, DocumentItem item) {
    careShowForm(
      context,
      maxWidth: 480,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _DocumentDetail(item: item),
      ),
    );
  }
}

String _toneFor(String documentType) {
  return switch (documentType) {
    'IMAGING' => 'orange',
    'LAB_RESULT' => 'green',
    'PRESCRIPTION' => 'purple',
    _ => 'purple',
  };
}

class _TypeFilters extends StatelessWidget {
  const _TypeFilters({
    required this.types,
    required this.selected,
    required this.counts,
    required this.total,
    required this.onSelected,
  });

  final List<String> types;
  final String? selected;
  final Map<String, int> counts;
  final int total;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (types.length < 2) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Todos',
          count: total,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final type in types)
          _FilterChip(
            label: documentTypeLabel(type),
            count: counts[type] ?? 0,
            selected: selected == type,
            onTap: () => onSelected(type),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        hoverColor: AppColors.primaryLight.withAlpha(120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 13,
                  color: selected ? AppColors.surface : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: AppTextStyles.bodySmall
                    .copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primaryLight
                          : AppColors.textMuted,
                    )
                    .tabular,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filas separadas por hairline: en escritorio la lista es una tabla, no una
/// pila de tarjetas.
class _DocumentTable extends StatelessWidget {
  const _DocumentTable({
    required this.documents,
    required this.selectedId,
    required this.onSelected,
  });

  final List<DocumentItem> documents;
  final String? selectedId;
  final ValueChanged<DocumentItem> onSelected;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return CareCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('Documento', style: layout.meta)),
                Expanded(flex: 2, child: Text('Tipo', style: layout.meta)),
                Expanded(flex: 2, child: Text('Subido', style: layout.meta)),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Peso',
                    textAlign: TextAlign.right,
                    style: layout.meta,
                  ),
                ),
              ],
            ),
          ),
          const CareHairline(),
          for (int index = 0; index < documents.length; index++) ...[
            if (index > 0) const CareHairline(indent: 14),
            CareDataRow(
              selected: documents[index].id == selectedId,
              onTap: () => onSelected(documents[index]),
              child: _DocumentRow(item: documents[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.item});

  final DocumentItem item;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final tone = _toneFor(item.documentType);

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: [
              CareIconBubble(
                icon: documentIcon(item.documentType),
                shape: BoxShape.rectangle,
                size: 34,
                iconSize: 17,
                backgroundColor: toneBackground(tone),
                iconColor: toneForeground(tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: layout.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: CareBadge(
              label: documentTypeLabel(item.documentType),
              backgroundColor: toneBackground(tone),
              foregroundColor: toneForeground(tone),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            CareDateFormatters.date(item.uploadedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: layout.meta,
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            _formatBytes(item.fileSizeBytes),
            textAlign: TextAlign.right,
            maxLines: 1,
            style: layout.meta.tabular,
          ),
        ),
      ],
    );
  }
}

class _DocumentDetail extends StatelessWidget {
  const _DocumentDetail({required this.item});

  final DocumentItem item;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);
    final tone = _toneFor(item.documentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CareIconBubble(
          icon: documentIcon(item.documentType),
          shape: BoxShape.rectangle,
          size: 52,
          iconSize: 25,
          backgroundColor: toneBackground(tone),
          iconColor: toneForeground(tone),
        ),
        const SizedBox(height: 14),
        Text(item.title, style: layout.cardTitle.copyWith(fontSize: 19)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CareBadge(
              label: documentTypeLabel(item.documentType),
              backgroundColor: toneBackground(tone),
              foregroundColor: toneForeground(tone),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            ),
            Text(CareDateFormatters.date(item.uploadedAt), style: layout.meta),
          ],
        ),
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(item.description, style: layout.bodyMuted),
        ],
        const SizedBox(height: 20),
        CareCard(
          variant: CareCardVariant.quiet,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailLine(
                label: 'Formato',
                value: item.mimeType.isEmpty ? 'Desconocido' : item.mimeType,
              ),
              const SizedBox(height: 10),
              _DetailLine(
                label: 'Peso',
                value: _formatBytes(item.fileSizeBytes),
              ),
              const SizedBox(height: 10),
              _DetailLine(
                label: 'Enlace',
                value: item.fileUrl.isEmpty ? 'Sin URL' : item.fileUrl,
              ),
            ],
          ),
        ),
        if (item.fileUrl.isNotEmpty) ...[
          const SizedBox(height: 14),
          CareHeaderButton(
            label: 'Copiar enlace',
            icon: Icons.link_rounded,
            tone: CareHeaderButtonTone.neutral,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: item.fileUrl));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Enlace copiado.')));
            },
          ),
        ],
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = CareLayout.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 72, child: Text(label, style: layout.meta)),
        Expanded(
          child: SelectableText(
            value,
            style: layout.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _CompactSearchField extends StatelessWidget {
  const _CompactSearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Buscar documentos…',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 19,
            color: AppColors.iconMuted,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _DocumentFormSheet extends StatefulWidget {
  const _DocumentFormSheet({required this.onSave});

  final Future<void> Function(DocumentItemDraft draft) onSave;

  @override
  State<_DocumentFormSheet> createState() => _DocumentFormSheetState();
}

class _DocumentFormSheetState extends State<_DocumentFormSheet> {
  static const _documentTypes = [
    'PRESCRIPTION',
    'LAB_RESULT',
    'CLINICAL_REPORT',
    'IMAGING',
    'REFERRAL',
    'VACCINATION_RECORD',
    'INSURANCE_FORM',
    'OTHER',
  ];
  static const _mimeTypes = ['application/pdf', 'image/jpeg', 'image/png'];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fileUrlController = TextEditingController();
  final _fileSizeController = TextEditingController(text: '1024');
  String _documentType = 'OTHER';
  String _mimeType = 'application/pdf';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fileUrlController.dispose();
    _fileSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, bottomInset + 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agregar documento',
                style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 18),
              _SheetTextField(
                controller: _titleController,
                label: 'Nombre',
                hintText: 'Ej. Resultados cardiólogo',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _documentType,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: [
                        for (final type in _documentTypes)
                          DropdownMenuItem(
                            value: type,
                            child: Text(documentTypeLabel(type)),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(
                              () => _documentType = value ?? _documentType,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _mimeType,
                      decoration: const InputDecoration(labelText: 'Formato'),
                      items: [
                        for (final type in _mimeTypes)
                          DropdownMenuItem(value: type, child: Text(type)),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) =>
                                setState(() => _mimeType = value ?? _mimeType),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SheetTextField(
                controller: _fileUrlController,
                label: 'URL del archivo',
                hintText: 'https://…',
              ),
              const SizedBox(height: 14),
              _SheetTextField(
                controller: _fileSizeController,
                label: 'Tamaño en bytes',
                hintText: 'Ej. 204800',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _SheetTextField(
                controller: _descriptionController,
                label: 'Descripción',
                hintText: 'Detalle breve del documento',
                minLines: 2,
                maxLines: 4,
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
                    label: _saving ? 'Guardando…' : 'Guardar documento',
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
    final title = _titleController.text.trim();
    final fileUrl = _fileUrlController.text.trim();
    final fileSize = int.tryParse(_fileSizeController.text.trim()) ?? 0;

    if (title.isEmpty) {
      setState(() => _error = 'Ingresa el nombre del documento.');
      return;
    }
    if (Uri.tryParse(fileUrl)?.hasScheme != true) {
      setState(() => _error = 'Ingresa una URL válida del archivo.');
      return;
    }
    if (fileSize <= 0 || fileSize > 10 * 1024 * 1024) {
      setState(() => _error = 'El tamaño debe estar entre 1 byte y 10 MB.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(
        DocumentItemDraft(
          documentType: _documentType,
          title: title,
          description: _descriptionController.text.trim(),
          fileUrl: fileUrl,
          mimeType: _mimeType,
          fileSizeBytes: fileSize,
        ),
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

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hintText),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '—';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _errorMessage(Object error, String fallback) {
  if (error is ApiException) return error.message;
  return fallback;
}

class CareDateFormatters {
  const CareDateFormatters._();

  static const List<String> _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String date(String? rawValue) {
    final parsed = parse(rawValue);
    if (parsed == null) {
      return rawValue?.isNotEmpty == true ? rawValue! : 'Sin fecha';
    }
    return '${parsed.day.toString().padLeft(2, '0')} ${_months[parsed.month - 1]} ${parsed.year}';
  }

  static String dateTime(String? rawValue) {
    final parsed = parse(rawValue);
    if (parsed == null) {
      return rawValue?.isNotEmpty == true ? rawValue! : 'Sin fecha';
    }
    return '${date(rawValue)}, ${time(parsed)}';
  }

  static String timeRange(String? startRaw, String? endRaw) {
    final start = parse(startRaw);
    if (start == null) return 'Hora pendiente';
    final end = parse(endRaw);
    if (end == null) return time(start);
    return '${time(start)} - ${time(end)}';
  }

  static String time(DateTime value) {
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'p. m.' : 'a. m.';
    return '$hour12:$minute $suffix';
  }

  static const List<String> monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const List<String> weekdayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const List<String> weekdayShortNames = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  /// "Martes 10 de septiembre"
  static String longDate(DateTime value) {
    final weekday = weekdayNames[value.weekday - 1];
    final month = monthNames[value.month - 1].toLowerCase();
    return '$weekday ${value.day} de $month';
  }

  /// "Septiembre 2026"
  static String monthTitle(DateTime value) =>
      '${monthNames[value.month - 1]} ${value.year}';

  /// "10 sep"
  static String dayAndMonth(DateTime value) =>
      '${value.day} ${_months[value.month - 1]}';

  /// Reloj de 24 h para vistas densas: la agenda semanal alinea columnas.
  static String time24(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// "hace 2 h", "ayer", "12 sep"
  static String relative(String? rawValue) {
    final parsed = parse(rawValue);
    if (parsed == null) return 'Sin fecha';
    final difference = DateTime.now().difference(parsed);
    if (difference.inMinutes < 1) return 'recién';
    if (difference.inMinutes < 60) return 'hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'hace ${difference.inHours} h';
    if (difference.inDays == 1) return 'ayer';
    if (difference.inDays < 7) return 'hace ${difference.inDays} días';
    return dayAndMonth(parsed);
  }

  static DateTime? parse(String? rawValue) {
    if (rawValue == null || rawValue.isBlank) return null;
    return DateTime.tryParse(rawValue);
  }
}

extension _BlankString on String {
  bool get isBlank => trim().isEmpty;
}

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

IconData eventIcon(String type) {
  return switch (type) {
    'MEDICATION' => Icons.medical_services_outlined,
    'APPOINTMENT' => Icons.event_available_outlined,
    'THERAPY' => Icons.healing_outlined,
    _ => Icons.volunteer_activism_outlined,
  };
}

String eventTypeLabel(String type) {
  return switch (type) {
    'MEDICATION' => 'Medicación',
    'APPOINTMENT' => 'Cita médica',
    'THERAPY' => 'Terapia',
    _ => 'Actividad',
  };
}

String eventStatusLabel(String status) {
  return switch (status) {
    'CONFIRMED' => 'Completado',
    'MISSED' => 'Incumplido',
    'CANCELLED' => 'Cancelado',
    _ => 'Pendiente',
  };
}

Color eventStatusBackground(String status) {
  return switch (status) {
    'CONFIRMED' => AppColors.statusConfirmedBackground,
    'MISSED' => AppColors.statusMissedBackground,
    'CANCELLED' => AppColors.orangeLight,
    _ => AppColors.statusPendingBackground,
  };
}

Color eventStatusForeground(String status) {
  return switch (status) {
    'CONFIRMED' => AppColors.statusConfirmedText,
    'MISSED' => AppColors.statusMissedText,
    'CANCELLED' => AppColors.orangeDark,
    _ => AppColors.statusPendingText,
  };
}

IconData documentIcon(String type) {
  return switch (type) {
    'PRESCRIPTION' => Icons.medical_information_outlined,
    'IMAGING' => Icons.image_outlined,
    'LAB_RESULT' => Icons.science_outlined,
    'CLINICAL_REPORT' => Icons.description_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}

String documentTypeLabel(String type) {
  return switch (type) {
    'PRESCRIPTION' => 'Receta',
    'IMAGING' => 'Imagen',
    'LAB_RESULT' => 'Laboratorio',
    'CLINICAL_REPORT' => 'Informe',
    'VACCINATION_RECORD' => 'Vacuna',
    _ => 'Otro',
  };
}

Color toneBackground(String tone) {
  return switch (tone) {
    'green' => AppColors.greenLight,
    'orange' => AppColors.orangeLight,
    'red' => AppColors.redLight,
    _ => AppColors.primaryLight,
  };
}

Color toneForeground(String tone) {
  return switch (tone) {
    'green' => AppColors.greenDark,
    'orange' => AppColors.orangeDark,
    'red' => AppColors.redDark,
    _ => AppColors.primaryDark,
  };
}

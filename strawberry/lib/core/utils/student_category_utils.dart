import 'package:flutter/material.dart';

/// Central utility for handling student categories across the Strawberry ERP app.
/// Supports students enrolled in single or multiple categories (e.g. "Playgroup, Daycare").
class StudentCategoryUtils {
  /// Extract a clean list of trimmed, non-empty categories from:
  /// - A raw String (e.g. "Playgroup, Daycare")
  /// - A Map representing a student profile (reads `student_type` or `program`)
  /// - A List of dynamic items
  static List<String> getCategories(dynamic input) {
    if (input == null) return [];

    if (input is Map<String, dynamic>) {
      final raw = input['student_type'] ?? input['program'];
      return getCategories(raw);
    }

    if (input is List) {
      final set = <String>{};
      for (final item in input) {
        if (item != null) {
          final str = item.toString().trim();
          if (str.isNotEmpty) set.add(str);
        }
      }
      return set.toList();
    }

    if (input is String) {
      if (input.trim().isEmpty) return [];
      return input
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet() // Deduplicate
          .toList();
    }

    return [];
  }

  /// Check if a student (or raw category string) belongs to a specific category.
  /// Case-insensitive match. If [categoryToCheck] is 'All', returns true.
  static bool hasCategory(dynamic input, String? categoryToCheck) {
    if (categoryToCheck == null || categoryToCheck.trim().isEmpty) return true;
    final target = categoryToCheck.trim().toLowerCase();
    if (target == 'all') return true;

    final categories = getCategories(input);
    return categories.any((c) => c.trim().toLowerCase() == target);
  }

  /// Combine an iterable of categories into a clean comma-separated string for DB storage.
  /// E.g. ['Playgroup', 'Daycare'] -> "Playgroup, Daycare"
  static String joinCategories(Iterable<String> categories) {
    return categories
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .join(', ');
  }

  /// Returns a clean display string for UI text (e.g. "Playgroup, Daycare" or "General")
  static String formatCategories(dynamic input, {String emptyLabel = 'General'}) {
    final list = getCategories(input);
    if (list.isEmpty) return emptyLabel;
    return list.join(', ');
  }

  /// Returns a curated emoji for known categories.
  static String getCategoryEmoji(String category) {
    final lower = category.toLowerCase().trim();
    if (lower.contains('playgroup')) return '🍓';
    if (lower.contains('nursery')) return '🌱';
    if (lower.contains('lkg') || lower.contains('junior')) return '📚';
    if (lower.contains('ukg') || lower.contains('senior')) return '🎓';
    if (lower.contains('daycare') || lower.contains('creche')) return '☀️';
    if (lower.contains('tuition') || lower.contains('tution')) return '✏️';
    if (lower.contains('taekwondo') || lower.contains('activity')) return '🥋';
    if (lower.contains('dance')) return '💃';
    if (lower.contains('music')) return '🎵';
    if (lower.contains('drawing') || lower.contains('art')) return '🎨';
    return '🎒';
  }

  /// Returns a curated theme color for a category pill.
  static Color getCategoryColor(String category) {
    final lower = category.toLowerCase().trim();
    if (lower.contains('playgroup')) return const Color(0xFFE91E63);
    if (lower.contains('nursery')) return const Color(0xFF10B981);
    if (lower.contains('lkg') || lower.contains('junior')) return const Color(0xFF3B82F6);
    if (lower.contains('ukg') || lower.contains('senior')) return const Color(0xFF8B5CF6);
    if (lower.contains('daycare') || lower.contains('creche')) return const Color(0xFFF59E0B);
    if (lower.contains('tuition') || lower.contains('tution')) return const Color(0xFF06B6D4);
    if (lower.contains('taekwondo') || lower.contains('activity')) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }
}

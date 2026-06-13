import 'package:flutter/material.dart';

import '../cat_data.dart';

Color panelColor(BuildContext context) {
  return Theme.of(context).colorScheme.surface;
}

Color softSurfaceColor(BuildContext context) {
  return Theme.of(context).colorScheme.surfaceContainerHighest;
}

Color borderColor(BuildContext context) {
  return Theme.of(context).dividerColor;
}

Color mutedTextColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

Color sectionColor(CatSection? section) {
  switch (section) {
    case CatSection.varc:
      return const Color(0xFF4E6EAF);
    case CatSection.dilr:
      return const Color(0xFFE05D44);
    case CatSection.qa:
      return const Color(0xFF00796B);
    case null:
      return const Color(0xFFF2B84B);
  }
}

IconData sectionIcon(CatSection? section) {
  switch (section) {
    case CatSection.varc:
      return Icons.menu_book_outlined;
    case CatSection.dilr:
      return Icons.account_tree_outlined;
    case CatSection.qa:
      return Icons.calculate_outlined;
    case null:
      return Icons.rate_review_outlined;
  }
}

Color priorityColor(String priority) {
  switch (priority) {
    case 'Highest':
      return const Color(0xFFE05D44);
    case 'High':
      return const Color(0xFF00796B);
    case 'Medium':
      return const Color(0xFF4E6EAF);
    default:
      return const Color(0xFF7B6F54);
  }
}

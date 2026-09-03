import 'package:flutter/material.dart';

class CategoryIconHelper {
  static const List<IconData> availableIcons = [
    Icons.inventory_2,
    Icons.phone_android,
    Icons.restaurant,
    Icons.checkroom,
    Icons.business_center,
    Icons.local_pharmacy,
    Icons.directions_car,
    Icons.computer,
    Icons.construction,
    Icons.school,
    Icons.home,
    Icons.sports_soccer,
    Icons.category,
    Icons.shopping_bag,
    Icons.devices,
    Icons.style,
    Icons.local_offer,
    Icons.store,
    Icons.fastfood,
    Icons.liquor,
    Icons.fitness_center,
    Icons.build,
    Icons.auto_stories,
    Icons.medical_services,
    Icons.design_services,
    Icons.electric_bolt,
    Icons.spa,
    Icons.pets,
  ];

  /// Safe lookup of IconData from codePoint using constant static instances.
  /// Prevents Flutter release build tree-shaking failures.
  static IconData getIcon(int? codePoint) {
    if (codePoint == null) return Icons.category;
    for (final icon in availableIcons) {
      if (icon.codePoint == codePoint) {
        return icon;
      }
    }
    return Icons.category;
  }
}

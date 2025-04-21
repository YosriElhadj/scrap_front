// utils/string_utils.dart - Fixed for Flutter 3.27.3
// Centralized string utilities to avoid extension conflicts

class StringUtils {
  /// Capitalizes the first letter of a string
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  /// Formats a price value as currency
  static String formatPrice(double price, {bool showCents = false}) {
    if (showCents) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${price.toStringAsFixed(0)}';
    }
  }
  
  /// Formats area in square feet with appropriate units
  static String formatArea(double? area) {
    if (area == null) return 'Unknown';
    
    if (area >= 43560) {
      // Convert to acres for large areas
      final acres = area / 43560;
      return '${acres.toStringAsFixed(2)} acres';
    } else {
      return '${area.toStringAsFixed(0)} sq ft';
    }
  }
  
  /// Formats price per square foot
  static String formatPricePerSqFt(double? pricePerSqFt) {
    if (pricePerSqFt == null) return 'Unknown';
    return '\$${pricePerSqFt.toStringAsFixed(2)}/sq ft';
  }
}
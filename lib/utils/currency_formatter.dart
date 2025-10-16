/// Currency utility class for consistent peso formatting across the app
/// Ensures proper peso sign display on all devices and platforms
class CurrencyFormatter {
  // Use the peso sign (₱) as the primary symbol
  static const String _pesoSign = '₱';
  
  /// Formats amount as peso currency with proper symbol
  /// Example: formatPeso(150.0) returns "₱150"
  static String formatPeso(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return '$_pesoSign${amount.toStringAsFixed(2)}';
    } else {
      return '$_pesoSign${amount.toStringAsFixed(0)}';
    }
  }
  
  /// Formats amount with decimal places
  /// Example: formatPesoWithDecimals(150.50) returns "₱150.50"
  static String formatPesoWithDecimals(double amount) {
    return formatPeso(amount, showDecimals: true);
  }
  
  /// Formats amount for display in compact form
  /// Example: formatPesoCompact(150.0) returns "₱150"
  static String formatPesoCompact(double amount) {
    if (amount >= 1000) {
      return '$_pesoSign${(amount / 1000).toStringAsFixed(1)}k';
    }
    return formatPeso(amount);
  }
  
  /// Formats amount with negative prefix for discounts
  /// Example: formatDiscount(20.0) returns "-₱20"
  static String formatDiscount(double amount) {
    return '-${formatPeso(amount, showDecimals: true)}';
  }
  
  /// Formats price range
  /// Example: formatPriceRange(130.0, 150.0) returns "₱130 - ₱150"
  static String formatPriceRange(double minPrice, double maxPrice) {
    return '${formatPeso(minPrice)} - ${formatPeso(maxPrice)}';
  }
  
  /// Get the peso symbol for use in other contexts
  static String get pesoSymbol => _pesoSign;
  
  /// Check if peso symbol is supported (for fallback logic if needed)
  static bool get isPesoSymbolSupported {
    // In Flutter, the peso symbol should be supported on most platforms
    // This method is here for potential future fallback logic
    return true;
  }
}
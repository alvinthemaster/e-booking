class AppHelpers {
  /// Format van status for display
  static String formatVanStatus(String status) {
    switch (status.toLowerCase().trim()) {
      case 'active':
        return 'Ready';
      case 'inactive':
        return 'Inactive';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Unknown';
    }
  }

  /// Get status color
  static int getStatusColorValue(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'boarding':
        return 0xFF4CAF50; // Green
      case 'in_queue':
        return 0xFFFF9800; // Orange
      case 'in_transit':
        return 0xFF2196F3; // Blue
      case 'maintenance':
        return 0xFFF44336; // Red
      case 'inactive':
        return 0xFF9E9E9E; // Grey
      default:
        return 0xFF4CAF50; // Default green
    }
  }

  /// Validate plate number format
  static bool isValidPlateNumber(String plateNumber) {
    return plateNumber.isNotEmpty && plateNumber.length >= 3;
  }

  /// Validate phone number format
  static bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  /// Format capacity display
  static String formatCapacity(int capacity) {
    return '$capacity passenger${capacity == 1 ? '' : 's'}';
  }

  /// Format queue position
  static String formatQueuePosition(int position) {
    return '#$position';
  }
}
class Validators {
  /// CNIC format: XXXXX-XXXXXXX-X (13 digits with dashes)
  static String? cnic(String? value) {
    if (value == null || value.isEmpty) return 'CNIC is required';
    final regex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!regex.hasMatch(value)) return 'Format: XXXXX-XXXXXXX-X';
    return null;
  }

  /// Pakistani mobile: 03XX-XXXXXXX or 03XXXXXXXXX
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final digits = value.replaceAll('-', '').replaceAll(' ', '');
    final regex = RegExp(r'^03\d{9}$');
    if (!regex.hasMatch(digits)) return 'Format: 03XX-XXXXXXX';
    return null;
  }

  /// Required field — any non-empty string
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  /// Date must not be in the past (for expiry dates)
  static String? futureDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) return '$fieldName is required';
    if (value.isBefore(DateTime.now())) return '$fieldName must be a future date';
    return null;
  }

  /// Date must be in the past (for DOB, issue dates)
  static String? pastDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) return '$fieldName is required';
    if (value.isAfter(DateTime.now())) return '$fieldName cannot be a future date';
    return null;
  }

  /// Minimum age check (default 18)
  static String? minimumAge(DateTime? dob, {int minAge = 18}) {
    if (dob == null) return 'Date of birth is required';
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    if (age < minAge) return 'Worker must be at least $minAge years old';
    return null;
  }
}

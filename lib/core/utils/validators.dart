class Validators {
  /// CNIC — stored and entered WITHOUT dashes: 13 digits
  static String? cnic(String? value) {
    if (value == null || value.isEmpty) return 'CNIC is required';
    final clean = value.replaceAll('-', '').replaceAll(' ', '');
    if (clean.length != 13 || !RegExp(r'^\d{13}$').hasMatch(clean)) {
      return 'CNIC must be 13 digits';
    }
    return null;
  }

  /// Strip dashes from CNIC for storage
  static String cleanCnic(String value) =>
      value.replaceAll('-', '').replaceAll(' ', '').trim();

  /// Pakistani mobile — stored WITHOUT dashes: 11 digits starting 03
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final clean = value.replaceAll('-', '').replaceAll(' ', '');
    if (!RegExp(r'^03\d{9}$').hasMatch(clean)) {
      return 'Format: 03XXXXXXXXXX (11 digits, no dashes)';
    }
    return null;
  }

  /// Strip dashes from phone for storage
  static String cleanPhone(String value) =>
      value.replaceAll('-', '').replaceAll(' ', '').trim();

  /// House number: TYPE-NUMBER e.g. BQ-12, A-150, D+-5
  /// Type: letters/symbols only, Number: 1-200
  static String? houseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'House number is required';
    }
    final clean = value.trim().toUpperCase();
    if (!RegExp(r'^[A-Z+]{1,4}-\d{1,3}$').hasMatch(clean)) {
      return 'Format: TYPE-NUMBER (e.g. BQ-12, A-150)';
    }
    return null;
  }

  /// Employee number: XXX-00000 (3-char prefix + 5-digit zero-padded number)
  static String? employeeNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final clean = value.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}-\d{5}$').hasMatch(clean)) {
      return 'Format: FFL-00123 (prefix-5digits)';
    }
    return null;
  }

  /// Format employee number — pad number to 5 digits
  static String formatEmployeeNumber(String value) {
    final parts = value.trim().toUpperCase().split('-');
    if (parts.length != 2) return value.trim().toUpperCase();
    final prefix = parts[0];
    final number = parts[1].padLeft(5, '0');
    return '$prefix-$number';
  }

  /// Required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Date must be in the future (expiry dates)
  static String? futureDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) return '$fieldName is required';
    if (value.isBefore(DateTime.now())) {
      return '$fieldName must be a future date';
    }
    return null;
  }

  /// Date must be in the past (DOB, issue dates)
  static String? pastDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) return '$fieldName is required';
    if (value.isAfter(DateTime.now())) {
      return '$fieldName cannot be a future date';
    }
    return null;
  }

  /// Vehicle plate: ABC-1234 or AB-123
  static String? vehiclePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration number is required';
    }
    final clean = value.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2,4}-\d{3,4}$').hasMatch(clean)) {
      return 'Format: ABC-1234';
    }
    return null;
  }

  /// Vehicle registration number (free text for reg card doc number)
  static String? vehicleRegNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration number is required';
    }
    return null;
  }

  /// Minimum age check
  static String? minimumAge(DateTime? dob, {int minAge = 18}) {
    if (dob == null) return 'Date of birth is required';
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    if (age < minAge) return 'Must be at least $minAge years old';
    return null;
  }
}

class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'कृपया मोबाईल नंबर प्रविष्ट करा';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10) {
      return 'कृपया वैध १०-अंकी मोबाईल नंबर प्रविष्ट करा';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'कृपया $fieldName प्रविष्ट करा';
    }
    return null;
  }

  static String? validateAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'कृपया आधार क्रमांक प्रविष्ट करा';
    }
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length != 12 || !RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'कृपया वैध १२-अंकी आधार क्रमांक प्रविष्ट करा';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'कृपया रक्कम प्रविष्ट करा';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'कृपया वैध रक्कम प्रविष्ट करा';
    }
    return null;
  }

  static String? validateGroupCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'कृपया गट कोड प्रविष्ट करा';
    }
    if (value.trim().length != 6) {
      return 'गट कोड ६ अक्षरी असावा';
    }
    return null;
  }
}

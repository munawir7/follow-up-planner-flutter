class PhoneUtils {
  PhoneUtils._();
  static String normalize(String phoneNumber) {
    var normalized = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (normalized.length == 12 && normalized.startsWith('91')) {
      normalized = normalized.substring(2);
    }
    return normalized;
  }
}

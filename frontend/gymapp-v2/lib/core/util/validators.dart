class AppValidators {
  static String? validateHttpsUrl(String? value) {
    if (value == null || value.isEmpty) return null;

    // Check for https:// prefix
    if (!value.startsWith('https://')) {
      return 'URL "https://" ile başlamalıdır.';
    }

    // Simple URL regex
    final urlRegExp = RegExp(
      r'^https:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(\/\S*)?$',
      caseSensitive: false,
    );

    if (!urlRegExp.hasMatch(value)) {
      return 'Geçerli bir URL giriniz.';
    }

    return null;
  }
}

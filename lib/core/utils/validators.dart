/// Form alanları için ortak doğrulama kuralları. Negatif ve mantıksız
/// değerlerin girişini engellemek amacıyla kullanılır.
class Validators {
  Validators._();

  static String? required(String? value, {String message = 'Bu alan zorunludur'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// Sıfırdan büyük bir sayı bekler (miktar, birim fiyat gibi alanlar için).
  static String? positiveNumber(
    String? value, {
    String message = 'Sıfırdan büyük geçerli bir değer girin',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    final double? parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return message;
    return null;
  }

  /// Boş bırakılabilen ama girildiğinde 0-100 arası olması gereken yüzde alanı
  /// (iskonto gibi).
  static String? optionalPercentage(
    String? value, {
    String message = '0-100 arası bir değer girin',
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final double? parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0 || parsed > 100) return message;
    return null;
  }
}

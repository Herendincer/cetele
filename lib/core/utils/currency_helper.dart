import 'package:intl/intl.dart';

/// Kuruş bazlı (integer) para tutarlarını ve Türk Lirası biçimlendirmesini
/// yöneten yardımcı sınıf.
///
/// Tüm parasal değerler veritabanında ve hesaplamalarda "kuruş" (en küçük
/// para birimi) cinsinden tam sayı (int) olarak tutulmalıdır. Bu sayede
/// ondalık sayı yuvarlama hatalarının önüne geçilir.
class CurrencyHelper {
  CurrencyHelper._();

  static final NumberFormat _tryFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final NumberFormat _decimalFormat = NumberFormat.decimalPattern('tr_TR');

  /// Kuruş cinsinden [kurus] değerini "1.234,56 ₺" biçiminde döndürür.
  static String formatFromKurus(int kurus) {
    final double lira = kurus / 100;
    return _tryFormat.format(lira);
  }

  /// Lira (double) cinsinden [lira] değerini "1.234,56 ₺" biçiminde döndürür.
  static String formatFromLira(double lira) {
    return _tryFormat.format(lira);
  }

  /// Sembolsüz, sadece sayısal biçimlendirme (örn. formlarda gösterim için).
  static String formatDecimalFromKurus(int kurus) {
    final double lira = kurus / 100;
    return _decimalFormat.format(lira);
  }

  /// Lira cinsinden değeri kuruşa (int) çevirir. Yuvarlama hatalarını önlemek
  /// için değer 100 ile çarpılıp en yakın tam sayıya yuvarlanır.
  static int liraToKurus(double lira) {
    return (lira * 100).round();
  }

  /// Kuruş cinsinden değeri lira (double) olarak döndürür.
  static double kurusToLira(int kurus) {
    return kurus / 100;
  }

  /// Kullanıcının form alanına girdiği metni (örn. "1.234,56" veya "1234.56")
  /// kuruş cinsinden int değere çevirir. Geçersiz girişlerde null döner.
  static int? parseToKurus(String input) {
    if (input.trim().isEmpty) return null;
    // Türkçe biçimde binlik ayırıcı (.) ve ondalık ayırıcı (,) kullanımını
    // normalize et: önce binlik noktaları kaldır, sonra virgülü noktaya çevir.
    String normalized = input.trim();
    final bool hasComma = normalized.contains(',');
    if (hasComma) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }
    final double? value = double.tryParse(normalized);
    if (value == null) return null;
    return liraToKurus(value);
  }
}

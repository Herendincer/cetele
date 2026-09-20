/// Uygulama genelinde kullanılan sabitler.
class AppConstants {
  AppConstants._();

  static const String appName = 'Çetele';

  // Supabase - Bu değerleri kendi Supabase projenizin bilgileriyle değiştirin.
  // Güvenlik notu: Anon key herkese açık (public) bir anahtardır ve
  // Row Level Security (RLS) kuralları ile korunur, ancak yine de bu
  // değerleri ortam değişkenleri (--dart-define) ile yönetmeniz önerilir.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tsppigklksuslyklgcaj.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_AnXzE9LfpGmdOBpnYLfaAQ_UYgoJNZj',
  );

  // Tablo isimleri
  static const String tableProfiles = 'profiles';
  static const String tableContacts = 'contacts';
  static const String tableInvoices = 'invoices';
  static const String tableInvoiceItems = 'invoice_items';
  static const String tableTransactions = 'transactions';

  // RevenueCat - Google Play için genel (public) API anahtarı.
  // Bu değeri kendi RevenueCat projenizin Android public SDK key'i ile değiştirin.
  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
    defaultValue: 'test_yuurGNGXdDVHxpVdpmmRfCHNElm',
  );

  // RevenueCat entitlement/product tanımlayıcıları.
  static const String proEntitlementId = 'pro';
  static const String monthlyPackageId = r'$rc_monthly';

  // Yasal bağlantılar - paywall ekranında gösterilir.
  // Gerçek gizlilik politikası ve kullanım koşulları URL'leriniz ile değiştirin.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://cetele.app/privacy',
  );
  static const String termsOfUseUrl = String.fromEnvironment(
    'TERMS_OF_USE_URL',
    defaultValue: 'https://cetele.app/terms',
  );

  // Şirket bilgileri - PDF fatura çıktısında kullanılır.
  // Gerçek şirket bilgilerinizle güncelleyin.
  static const String companyName = 'Çetele Ön Muhasebe A.Ş.';
  static const String companyTaxOffice = 'Kadıköy Vergi Dairesi';
  static const String companyTaxNumber = '1234567890';
  static const String companyAddress = 'Bağdat Cd. No:1, Kadıköy / İstanbul';
  static const String companyPhone = '0216 000 00 00';
}

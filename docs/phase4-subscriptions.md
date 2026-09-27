# Faz 4 — Pro abonelik kurulumu

## Kodun beklediği tanımlar

| Tanım | Değer |
| --- | --- |
| Android paket adı | `com.hed.cetele.cetele` |
| RevenueCat entitlement | `pro` |
| RevenueCat offering | `default` |
| Offering içindeki aylık paket | `$rc_monthly` (Monthly) |
| Google Play abonelik ürün kimliği | `cetele_pro_monthly` |
| Google Play temel plan kimliği | `monthly` |
| RevenueCat Google ürünü | `cetele_pro_monthly:monthly` |
| RevenueCat müşteri kimliği | Kalıcı Supabase kullanıcısının UUID'si |

Kod `default` offering içindeki `$rc_monthly` paketini satın alır ve `pro`
aktif hakkını kontrol eder. Mağaza ürününü bu pakete yukarıdaki kimlikle bağlayın.
Fiyat kodda bulunmaz: gösterilen ve satın alınan paketin `priceString` alanı kullanılır.
Misafir hesabı RevenueCat'e müşteri olarak gönderilmez; satın alma/geri yükleme
öncesi Google girişi gerekir. Cari, hesap, hareket, PDF ve dashboard ücretsizdir.

## Google Play / RevenueCat manuel kurulumu

1. Play Console'da **Çetele** uygulamasını oluşturun/seçin. Paket adı yukarıdakiyle
   eşleşmeli. Gerekli geliştirici hesabı ve ödeme profili kurulumunu tamamlayın.
2. **Monetize with Play → Products → Subscriptions** bölümünde
   `cetele_pro_monthly` ürününü, görünen ad olarak **Çetele Pro Aylık** oluşturun.
   `monthly` temel planını ekleyin: otomatik yenilenen, bir aylık dönem.
   Ülkeleri ve fiyatları belirleyin, temel planı etkinleştirin.
   İlk aşamada deneme/indirim teklifi şart değildir.
3. RevenueCat projesinde **Apps → Google Play** uygulaması ekleyin. Paket adını
   `com.hed.cetele.cetele` olarak girin.
4. Google Cloud'da Google Play Android Developer API, Google Play Developer
   Reporting API ve Cloud Pub/Sub API'yi etkinleştirin. IAM & Admin → Service
   Accounts'ta RevenueCat için hizmet hesabı oluşturun. Pub/Sub Editor ve
   Monitoring Viewer rollerini verin; Keys bölümünden JSON anahtarı oluşturun.
5. Play Console → **Users and permissions** bölümünde bu hizmet hesabının
   e-postasını davet edin ve Çetele uygulamasına erişim verin. RevenueCat'in
   güncel rehberindeki izinleri seçin: uygulama bilgilerini/toplu raporları
   görüntüleme; finansal veriler, siparişler ve iptal anketlerini görüntüleme;
   siparişleri/abonelikleri yönetme; mağaza varlığını yönetme.
6. JSON anahtarını yalnızca RevenueCat → Apps → Google Play uygulaması →
   **Service Account Credentials JSON** alanına yükleyin. Repo'ya veya uygulamaya
   eklemeyin. Dashboard'daki credential doğrulamasının geçmesini bekleyin;
   yeni yetkilerin etkinleşmesi 36 saate kadar sürebilir.
7. RevenueCat **Product catalog → Products** bölümünde Play ürününü içe aktarın:
   abonelik `cetele_pro_monthly`, temel plan `monthly`. RevenueCat ürün eşlemesi
   `cetele_pro_monthly:monthly` olur.
8. **Entitlements** altında `pro` oluşturun ve bu ürünü bağlayın.
9. **Offerings** altında `default` oluşturun; **Monthly / $rc_monthly** paketini
   ekleyip aynı ürünü bağlayın. Bunu varsayılan/current offering olarak da seçin.
10. RevenueCat Android public SDK anahtarını çalıştırma/derleme sırasında
    `--dart-define=REVENUECAT_GOOGLE_API_KEY=<Android_public_SDK_key>` ile verin.
    Kaynak kodda fallback anahtar yoktur. REST secret key veya hizmet hesabı
    JSON'u bu değişkene verilmez. Eksik anahtarda uygulama açılır, satın alma
    seçeneği yüklenemez; sahte fiyat veya Pro hakkı üretilmez.
11. Play Console hesap ayarları → **License testing** bölümüne test Google
    hesabınızı ekleyin ve kaydedin. Phase 6'da aynı hesabı kapalı test listesinin
    üyesi yapın; test davetini kabul edin ve Play Store'a o hesapla giriş yapın.
    Sadece test kanalına eklemek lisans testçisi olmakla aynı şey değildir.

Kaynaklar: [Play ürünleri](https://www.revenuecat.com/docs/getting-started/entitlements/android-products),
[hizmet hesabı ve izinler](https://www.revenuecat.com/docs/service-credentials/creating-play-service-credentials),
[lisans testçileri](https://support.google.com/googleplay/android-developer/answer/6062777).

## Burada durulacak sınır

Bu faz gerçek bir Google Play satın alma işlemi çalıştırmaz. Projenin uçtan uca
Play test planı **Phase 6**'da release anahtarıyla imzalanmış AAB'nin kapalı test
kanalına yüklenmesi ve Play üzerinden kurulmasıdır; henüz yapılmadı. O aşamada
Play App Signing SHA-1 kaydını Phase 3 rehberine göre tamamlayın. Lisans testçisi
ödeme ekranında test ödeme yöntemlerini kullanmalı; gerçek kartla ödeme yapmamalı.

Teknik ayrım: Google, lisans testçilerine debug/sideload istisnası tanır ve internal
test kanalı da kullanılabilir. Dolayısıyla kapalı kanala release yükleme tüm
Google Play testleri için evrensel bir zorunluluk değildir; bu projenin seçilen
Phase 6 doğrulama yoludur. [Google'ın test kuralları](https://developer.android.com/google/play/billing/test).

## Şimdi kullanılabilecek mağazasız smoke test ortamı

İstenirse RevenueCat **Test Store** altında aynı aylık ürün için test ürünü
oluşturun; bunu `pro` ve `default / $rc_monthly` ile eşleyin. Yalnızca debug
derlemede Test Store public SDK anahtarını yukarıdaki dart-define değişkenine
verin. Bu ortam gerçek Play fiyatını, faturalandırmasını veya hizmet hesabı
bağlantısını doğrulamaz. Test Store anahtarını Play'e yüklenecek derlemelerde
kullanmayın; Flutter için Test Store debug derlemeleriyle sınırlıdır.
Android'de StoreKit kullanılmaz; bu fazdaki mağazasız karşılığı RevenueCat
Test Store ve otomatik testlerdeki SDK taklitleridir. Bu çalışma Test Store'da
da herhangi bir satın alma başlatmadı.
[RevenueCat Test Store rehberi](https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store).

## Gerçek satın alma olmadan manuel kontrol

- [ ] Anahtar vermeden uygulamayı aç; başlangıç çökmesin. Paywall yükleme hatası
  ve **Tekrar dene** gösterilsin; fiyat/satın alma düğmesi uydurulmasın.
- [ ] Misafir olarak Ayarlar → abonelik kartına dokun. Google hesabının gerekli
  olduğunu gör; satın alma veya geri yükleme işlemi başlatılamasın.
- [ ] Google hesap seçimini iptal et; misafir olarak kal. Tekrar dene ve giriş
  yap; oturum değişiminden sonra paywall otomatik açılsın.
- [ ] Var olan Google hesabıyla çakışma diyaloğunda **Vazgeç** seç; başka hesaba
  geçilmesin ve sonraki normal girişte istemeden paywall açılmasın.
- [ ] Test Store yalnızca fiyat gösterimi için yapılandırılmışsa aylık fiyatın
  dashboard'daki test ürününden geldiğini kontrol et. **Satın Al**'a basma.
- [ ] Mevcut bir test/pro hesabıyla Ayarlar'da **Pro** ve **Aboneliği Yönet**
  bağlantısını gör. Bağlantı Google Play abonelik yönetimini açsın.
- [ ] Dashboard'dan test hakkı değiştirildiğinde uygulamayı arka plana alıp geri
  dön; plan yenilensin. Hesap değiştirince önceki hesabın Pro durumu görünmesin.
- [ ] 320 dp genişlikte ve büyük yazıyla Google giriş açıklamasını, paywall'ı ve
  Ayarlar'ı kontrol et; düğmeler erişilebilir ve metinler taşmasız olsun.

## Fatura sayımı kurulumu ve davranışı

Önce `supabase/migrations/20260927120000_monthly_sales_invoice_count.sql`
dosyasını Supabase SQL Editor'da **siz çalıştırın**. Önceki migration'ların
uygulanmış olması gerekir. Bu çalışma SQL'i hiçbir veritabanında uygulamadı.
Yeni fonksiyon açılmadan ücretsiz satış oluşturma kontrolü hata gösterir;
eksik RPC veya bağlantı hatası sıfır kullanım olarak değerlendirilmez.

`count_monthly_sales_invoices()` parametresizdir ve bir sayı döndürür.
`SECURITY DEFINER`, boş `search_path`, sabit şema adları ve içeride `auth.uid()`
kontrolü kullanır. Oturumsuz çağrıya izin verilmez. Oturumlu misafirler de
Supabase'in authenticated rolü üzerinden yalnızca kendi kullanımını görür.
Satışlara ait `(user_id, issue_date)` kısmi indeksi sayımı destekler.

Son onaylanan sayım kuralı: faturanın **issue_date** alanı, sunucu saatine göre
**Europe/Istanbul** takviminde geçerli ayın ilk günü dahil, sonraki ayın ilk günü
hariç aralığında olmalıdır. `created_at` kullanılmaz. Alışlar sayılmaz; taslak,
onaylı, ödenmiş ve iptal edilmiş satışlar sayılır. Silinen veya tarihi başka aya
taşınan faturalar mevcut ayın sayımından çıkar; kalıcı kullanım günlüğü eklenmedi.

Ücretsiz kullanıcının sayısı 5 veya üzerindeyse satış oluşturma formu yerine
paywall açılır. Kayıtta tekrar sayılır; alış formunu açıp satışa geçmek de kontrol
edilir. Pro ve alış faturaları kotadan etkilenmez. Mevcut fatura işlemleri ve PDF
dışa aktarma sınır kontrolünden geçmez. Sayım fatura değişikliklerinde yenilenir;
Ayarlar'da elle, uygulamaya dönüşte ve açık ekranda ay değişince de yenilenebilir.

Sınır: bu faz sunucu sayımıyla uygulama akışını denetler; sayım ve oluşturma ayrı
isteklerdir. İki cihazın tam aynı anda kayıt yapması veya API'yi doğrudan çağırmak
için atomik veritabanı kota kilidi değildir. Böyle bir sunucu engeli, sunucuda
doğrulanan Pro hakkını da gerektirir; burada istemcinin gönderdiği bir Pro
bayrağına güvenen SQL eklenmedi.

- [ ] Migration'ı elle uygula; ücretsiz hesapta Ayarlar'da **0 / 5** kullanımını gör.
- [ ] Bu ay tarihli 5 satış faturası oluştur; her kayıttan sonra sayının arttığını gör.
- [ ] Altıncı satış için hem Faturalar düğmesini hem dashboard hızlı işlemini dene;
  **Bu ay ücretsiz fatura hakkınız doldu** paywall'ı açılsın, form açılmasın.
- [ ] Aynı ayda alış faturası oluştur; satış kullanımının değişmediğini gör.
  Alış formunda satış türünü seçince kota kontrolü yapılsın.
- [ ] Dört kullanımdayken satış formunu aç; başka cihazda beşinciyi oluştur.
  İlk cihazda Kaydet'e bas; yeniden sayım paywall'ı açsın ve kayıt yapılmasın.
- [ ] Farklı kullanıcıyla giriş yap; diğer kullanıcının sayısı görünmesin.
  Misafir beşe ulaştığında paywall Google girişi istesin.
- [ ] Önceki ay tarihli satışın bu ay sayılmadığını kontrol et; yalnızca kayıt
  oluşturma zamanı bu ay olması sayılması için yeterli değildir.
- [ ] Mevcut ay satışını sil; yenileme sonrası kullanımın azaldığını gör.
  Düzenleme tarihi değişikliği varsa başka aya taşımak da aynı etkiyi vermeli.
- [ ] Beş kullanımdayken mevcut faturaları aç, durumunu değiştir, PDF çıkar;
  bu işlemler engellenmesin. Cari, hesap ve hareket eklemek de sınırsız kalsın.
- [ ] Sayım sırasında ağ bağlantısını kes; hata gösterilsin, satış kaydı
  yapılmasın. Bağlantı gelince Ayarlar yenileme düğmesiyle tekrar dene.
- [ ] Ayrı test ortamında ay sınırlarını kontrol et: Türkiye saatine göre ayın
  ilk günündeki faturalar dahil, sonraki ayın ilk günündekiler hariç olmalı.
- [ ] Mevcut Pro test hesabıyla beş sınırının uygulanmadığını, Ayarlar'da kota
  yerine Pro planı ve yönetim bağlantısı gösterildiğini kontrol et.

# Faz 3 — Android kimlik doğrulama kurulumu ve testleri

## Google Cloud ve Supabase kurulumu (sırayla)

Bu proje için debug kurulumu kullanıcı tarafından tamamlandı. Aşağıdaki liste
aynı kurulumu yeniden yapabilmek ve Play dağıtımına hazırlanmak içindir.

1. Google Cloud Console'da projeyi seçin. Google Auth Platform → Branding:
   uygulama adı **Çetele**, destek e-postası ve geliştirici iletişim bilgilerini
   doldurun. Audience: **External**; test sırasında **Testing**, Test users
   listesine giriş yapacak Google hesaplarını ekleyin. Giriş kapsamları:
   `openid`, `email`, `profile`.
2. PowerShell'de projenin `android` klasöründe `./gradlew.bat signingReport`
   çalıştırın. Test sürümünü imzalayan sertifikanın **SHA1** değerini alın.
   Mevcut projede release de debug anahtarıyla imzalanıyor; bu işlem release
   imzalama yapılandırmasını değiştirmedi.
3. Google Auth Platform → Clients → Create client → **Android** seçin.
   Paket adı **com.hed.cetele.cetele**, SHA-1 bir önceki adımdaki değer olsun.
   Başka imzayla dağıtılan her sürüm için aynı paket adı ve ilgili SHA-1 ile
   ayrı Android istemcisi oluşturun.
4. Aynı projede Clients → Create client → **Web application** oluşturun.
   Authorized redirect URIs alanına şunu ekleyin:
   `https://tsppigklksuslyklgcaj.supabase.co/auth/v1/callback`.
   Client ID ve Client secret değerlerini alın. Native Android için JavaScript
   origin eklenmesi gerekmez.
5. Supabase → Authentication → Sign In / Providers → Google:
   **Enable Sign in with Google** açık olsun. **Client IDs** alanına önce Web
   Client ID, ardından Android Client ID değerlerini virgülle ayırarak yazın.
   **Client Secret (for OAuth)** alanına Web istemcisinin secret değerini girin.
   **Skip nonce checks** kapalı kalsın; kaydedin.
6. Supabase Authentication ayarlarında **Allow anonymous sign-ins** ve
   **Allow manual linking** açık olsun. Native token akışı için Supabase
   Redirect URLs listesine uygulama deep link'i eklenmez. SQL gerekmez.
7. Uygulamadaki `serverClientId`, aşağıdaki Web istemcisidir:
   `535679213005-gmgpu0kkt39q8i7qts0v8e9ketf8phav.apps.googleusercontent.com`.
   Client ID herkese açık bir tanımlayıcıdır. Client secret yalnızca Supabase
   dashboard'da tutulur. Firebase veya `google-services.json` gerekmez.
8. Play üzerinden testten önce Play Console → App integrity / App signing →
   **App signing key certificate → SHA-1** değerini alın ve bu imza için de
   Android OAuth istemcisini kaydedin; Supabase istemci listesine ekleyin.
   Upload sertifikası, cihazdaki Play sürümünü imzalayan sertifikayla aynı
   olmayabilir. Genel dağıtımdan önce Google Auth Platform yayın durumunu
   **In production** yapın ve konsolun istediği doğrulamaları tamamlayın.

Kaynaklar: [Google sertifika rehberi](https://developers.google.com/android/guides/client-auth),
[Flutter Android giriş paketi](https://pub.dev/packages/google_sign_in_android),
[Supabase Google kurulumu](https://supabase.com/docs/guides/auth/social-login/auth-google),
[native kimlik bağlama](https://supabase.com/docs/reference/dart/auth-linkidentitywithidtoken).

## Uygulama davranışı

- Oturumsuz açılışta giriş ekranı gösterilir. Anonim oturum yalnızca
  **Hesap oluşturmadan devam et** seçilirse açılır. Mevcut oturum korunur.
- Android Google SDK'dan alınan token'lar Supabase'e gönderilir. Tarayıcı
  OAuth akışı kullanılmaz. Servis sağlayıcı parametresi alır; Apple henüz
  uygulanmadı. Google native girişi bu fazda yalnızca Android'de desteklenir.
- Misafir hesap önce Google kimliğine bağlanır. Başarılı bağlama kullanıcı
  kimliğini değiştirmez; o kimliğe bağlı kayıtlar korunur.
- Yalnızca `identity_already_exists` hatasında mevcut hesaba geçiş onayı istenir.
  Vazgeçmek anonim oturumu korur. Onay verildiğinde mevcut hesaba giriş yapılır;
  anonim hesap verileri otomatik birleştirilmez.
- Her giriş, çıkış ve anonimden kalıcı hesaba geçişte Riverpod kapsamı yeniden
  oluşturulur. Cariler, hesaplar, hareketler, faturalar, dashboard, detay
  provider'ları ve abonelik önbelleği birlikte temizlenir. Açık rotalar da silinir.
- RevenueCat kimlik işlemleri sırayla tamamlanır. Sonra yeni kapsamda
  `subscriptionStatusProvider` yeniden okunur. Token yenilemek kapsamı sıfırlamaz.
- Kimliklendirme başarısızsa önceki RevenueCat müşterisinin Pro durumu gösterilmez.

## Türkçe manuel test listesi

Test kayıtları ve test Google hesapları kullanın. Veri silme/yeni kurulum
senaryolarında gerçek anonim verilerin bulunduğu uygulamayı silmeyin.

- [ ] Temiz kurulumda uygulamayı aç. **Google ile Giriş Yap** ve ikincil
  **Hesap oluşturmadan devam et** seçeneklerini gör; otomatik misafir açılmasın.
- [ ] Google düğmesine bas. Android hesap seçicisi açılsın; tarayıcı OAuth
  yönlendirmesi açılmasın. Seçimi iptal et; giriş ekranında kal.
- [ ] Test kullanıcısıyla Google girişi yap. Cari, hesap, hareket ve fatura ekle.
  Uygulamayı kapatıp aç; oturumun ve kayıtların korunduğunu kontrol et.
- [ ] Aynı Google hesabıyla farklı/yeni bir Android cihazdan giriş yap.
  Aynı kayıtların ve dashboard toplamlarının göründüğünü kontrol et.
- [ ] Ayrı test kurulumunda misafir olarak devam et. Cari, hesap, hareket ve
  fatura oluştur. Ayarlar'dan daha önce Çetele'de kullanılmamış bir Google
  hesabıyla giriş yap. Kayıtların kaldığını, Supabase Authentication → Users
  ekranında kullanıcı ID'sinin değişmediğini ve anonim durumunun kalktığını kontrol et.
- [ ] Bu yükseltilmiş Google hesabıyla ikinci cihazdan giriş yap;
  misafirken oluşturduğun kayıtları gör.
- [ ] Başka bir misafir test oturumunda daha önce kayıtlı bir Google hesabını
  seç. Mevcut hesaba geçiş ve verilerin birleştirilmeyeceği uyarısını gör.
  **Vazgeç** de; misafir oturumu ve verileri aynı kalsın.
- [ ] Aynı işlemi tekrarla, **Mevcut hesaba giriş yap** de. Yalnızca eski kalıcı
  hesabın kayıtlarını gör; misafir kayıtları bu hesaba taşınmasın.
- [ ] Ayarlar → **Çıkış Yap**. Giriş ekranına dön; geri tuşuyla önceki hesap
  ekranlarına ulaşama. Uygulamayı kapatıp aç; otomatik misafir oturumu açılmasın.
- [ ] Çıkıştan sonra farklı Google hesabıyla giriş yap. Cariler, hesaplar,
  hareketler, faturalar ve dashboard'da önceki hesabın verileri kısa süreliğine
  bile görünmesin. Aynı hesapla tekrar girişte doğru veriler geri gelsin.
- [ ] Pro ve ücretsiz test hesapları arasında geçiş yap. Abonelik kontrolü
  bitene kadar önceki hesabın Pro durumu görünmesin. RevenueCat müşteri ID'sinin
  etkin Supabase kullanıcı ID'siyle eşleştiğini kontrol et.
- [ ] İnterneti kapatıp giriş/misafir seçeneğini dene. Türkçe hata gösterilsin;
  başarısız bağlama otomatik olarak başka hesaba geçirmesin. Bağlantıyı açıp yeniden dene.
- [ ] İnternet yokken çıkış yap. Yerel oturum kapanmalı, önceki ekranlar silinmeli.
- [ ] 320 dp genişlikte ve büyük yazı boyutunda giriş ekranını, Ayarlar hesap
  kartını ve çakışma diyaloğunu kontrol et; düğmeler erişilebilir olsun.
- [ ] Play internal testing sürümünde aynı girişleri tekrarla; debug ve Play
  sertifikalarının ayrı kaydedilmiş olduğunu doğrula.

Gerçek Google hesap seçimi, dashboard ayarları, cihazlar arası eşitleme ve canlı
RevenueCat hakları otomatik sahte sunucu/SDK testlerinin yerine geçmez; cihazda
bu listeyle ayrıca doğrulanmalıdır.

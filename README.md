# 🏝️ Habit Island

Alışkanlıklarını tamamladıkça muz ve XP kazandığın, kazandıklarınla kendi adanı inşa ettiğin kişisel bir alışkanlık takip oyunu. Godot 4.7 ile yazıldı; hesap ve internet bağlantısı gerektirmez.

## Özellikler

- **Alışkanlıklar:** Alışkanlık ekle, sil ve her gün tamamla. Her tamamlama 5 muz ve 10 XP kazandırır, günlük seriler takip edilir.
- **Focus With Luffy:** Kamp ateşi başında Haki çalışan Hasır Şapkalı Luffy ile 15, 25, 45 veya 60 dakikalık oturumlar. STOP sayacı durdurup sıfırlar; ödül yalnızca biten oturuma verilir. Odaklanılan her dakika 1 muz ve 1 XP kazandırır. Kalan süre gerçek saatten hesaplandığı için telefon kilitlenip açıldığında sayaç geride kalmaz.
- **Today's Progress:** Bugün tamamlanan alışkanlıklar, odaklanılan dakikalar ve kazanılan muzlar; gün değişince sıfırlanır.
- **Günün Küçük Zaferi:** Gece yarısına kadar süren, değiştirilebilir mini görev. Tamamlanınca 20 muz ve 20 XP kazandırır.
- **CHECK-IN:** Günde bir kez 15 muz ve kutlama sesi.
- **Öncelikler:** Kırmızı, sarı ve beyaz noktaya dokunarak alışkanlığın önceliğini değiştir.
- **Ada İnşası:** Mağazadan palmiye, çadır, gemi gibi dekorları istediğin kadar al ve adanın üzerinde sürükleyerek yerleştir.
- **Ada Genişletme:** Adayı mağazadan 4. seviyeye kadar büyüt (🍌 200, 450, 800). Her seviye adayı %19 genişletir ve eşyalar için yeni alan açar.
- **Hasır Şapka Tayfası:** Luffy adada başlar; Zoro, Sanji, Chopper, Nami, Usopp, Robin, Franky, Brook ve Jinbe'yi mağazadan al. Her korsan benzersizdir, alınınca mağazada "Tayfada ✓" olarak kilitlenir; her biri adada sürüklenir, nefes alır, göz kırpar ve dokununca kendi korsan hareketini yapar.
- **İstatistikler ve Rozetler:** Seviye ilerlemesi, toplam odak süresi, en iyi seri ve 6 rozet.
- **Prosedürel Sesler:** Tüm ses efektleri çalışma anında kodla sentezlenir, ses dosyası kullanılmaz. Üst çubuktan kapatılabilir.
- **Yerel Kayıt:** İlerleme yalnızca cihazda `user://save_data.json` dosyasında tutulur, hiçbir yere gönderilmez.

## Mac'te anında çalıştırma

Godot 4.7 gerekir (`brew install --cask godot`).

**Terminalden** (720x1280 dikey pencere açılır):

```bash
./run_game.sh
```

**Godot editöründen:** Godot'yu aç, **Import** ile bu klasördeki `project.godot` dosyasını seç, ardından **F5** tuşuna bas.

Kayıt dosyası: `~/Library/Application Support/Godot/app_userdata/Habit Island/save_data.json`

## Dışa aktarmaya hazırlık

`export_presets.cfg` içinde **Android**, **macOS** ve **Web** ayarları hazırdır. Tüm platformlar için bir kez export şablonlarını kur:

**Editor → Manage Export Templates → Download and Install**

Çıktılar `build/` altına yazılır. Terminalden export almadan önce klasörleri oluştur:

```bash
mkdir -p build/android build/macos build/web
```

## Android APK alma

### Bir kez yapılacak kurulum

1. JDK 17 kur: `brew install --cask temurin@17`
2. [Android Studio](https://developer.android.com/studio) kur ve **SDK Manager** üzerinden *Android SDK Platform-Tools* ile *Android SDK Build-Tools* paketlerini yükle.
3. Godot'da **Editor → Editor Settings → Export → Android** altında yolları gir:
   - **Java SDK Path:** `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`
   - **Android SDK Path:** `~/Library/Android/sdk` klasörünün tam yolu

### Editörden

**Project → Export → Android → Export Project**, ardından `build/android/HabitIsland.apk` olarak kaydet.

### Terminalden

```bash
godot --headless --path . --export-debug "Android" build/android/HabitIsland.apk
```

Debug APK kişisel kullanım için yeterlidir. Release imzalı APK için bir anahtar oluştur ve anahtarı ortam değişkenleriyle ver, böylece parola proje dosyalarına yazılmaz. Anahtarı proje dışında sakla ve kaybetme: farklı bir anahtarla imzalanan sürüm, kurulu uygulamanın üzerine yüklenemez.

```bash
keytool -genkeypair -v -keystore ~/habit-island-release.keystore -alias habitisland -keyalg RSA -keysize 2048 -validity 10000

GODOT_ANDROID_KEYSTORE_RELEASE_PATH=~/habit-island-release.keystore \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=habitisland \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='anahtar-parolan' \
godot --headless --path . --export-release "Android" build/android/HabitIsland.apk
```

## Telefonda kullanma

### Android

**USB ile:** Telefonda *Geliştirici Seçenekleri → USB Hata Ayıklama*yı aç, sonra:

```bash
~/Library/Android/sdk/platform-tools/adb install -r build/android/HabitIsland.apk
```

**Dosya olarak:** APK'yı telefona gönder, dosyaya dokun ve istenirse *Bilinmeyen uygulamaları yükleme* iznini ver.

Uygulama dikey açılır ve tam ekran çalışır. Kurulumu kaldırmak kayıtları da siler. Uygulama ön plandayken ekran kapanmaz. Uygulama arka plana alınırsa süre işlemeye devam eder, ancak bitiş sesi ve ödül uygulamaya dönüldüğünde gelir; bildirim gönderilmez. Uygulama tamamen kapatılırsa (veya sistem kapatırsa) devam eden oturum kaybolur, çünkü sayaç kaydedilmez.

### Web (Ana Ekrana Ekle)

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

`build/web` klasörünü GitHub Pages, Netlify veya Cloudflare Pages gibi **HTTPS** sunan bir yere yükle. Ana ekrana ekleme ve çevrimdışı çalışma HTTPS gerektirir; yerel ağdaki `http://` adresinde çalışmaz.

Sayfayı telefonda aç, ardından:

- **Android Chrome:** Menü → *Ana ekrana ekle*
- **iPhone Safari:** Paylaş → *Ana Ekrana Ekle*

Web sürümünün kaydı tarayıcıda tutulur ve Android uygulamasıyla paylaşılmaz. Tarayıcı verilerini temizlemek kaydı siler.

## macOS uygulaması alma

```bash
godot --headless --path . --export-release "macOS" build/macos/HabitIsland.app
```

Uygulama ad-hoc imzalıdır. Kendi Mac'inde üretip çalıştırmak sorun olmaz; başka bir Mac'e kopyalanırsa Gatekeeper engelleyebilir.

## Testler

Testler kaydı ezmemek için geçici bir `HOME` ile çalışır:

```bash
HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase3_test.gd
HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase4_test.gd
HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase5_test.gd
HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase6_test.gd
HOME=$(mktemp -d) godot --headless --path . --script res://tests/phase7_test.gd
HOME=$(mktemp -d) godot --headless --path . --script res://tests/onepiece_test.gd
```

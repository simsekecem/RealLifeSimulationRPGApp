# Proje Sahne Analizi Raporu (Genişletilmiş)

Bu rapor, projedeki "Gym", "Market", "Library" ve "Resturant" sahnelerinin yapılarını, script mantıklarını ve en önemlisi **`Globals`** (genel veri yöneticisi) ve **`worker`** (arka plan sunucusu) ile olan bağlantılarını detaylı bir şekilde analiz etmektedir.

---

## Genel Veri Mimarisi: `Globals`, `Cache` ve `Worker`

Tüm sahneler, veri yönetimi için merkezi bir sisteme dayanır. Bu sistem üç ana bileşenden oluşur:

1.  **`Globals.gd` (Autoload/Singleton):** Projenin her yerinden erişilebilen merkezi script'tir. Oyunun tüm durumunu (`user`, `gym_log`, `library` vb.) `cache` adında bir sözlük (dictionary) içinde tutar.
2.  **Yerel Önbellek (`user_cache.json`):** `Globals.gd`, `cache` sözlüğünü periyodik olarak ve uygulama kapatılırken cihazın yerel hafızasındaki `user_cache.json` dosyasına kaydeder. Bu, internet bağlantısı olmadığında bile verilerin korunmasını sağlar.
3.  **Cloudflare Worker (Sunucu):** `Globals.gd`, kimlik doğrulaması yapılmış kullanıcılar için `cache` sözlüğünü `https://life-sim-worker.life-simulation.workers.dev` adresindeki sunucuya gönderir. Bu işlem, uygulama arka plana alındığında, kapatılırken veya bazen sahne geçişlerinde `HTTPRequest` aracılığıyla yapılır. Uygulama açıldığında ise verileri bu sunucudan geri yükler ve yerel `cache` ile birleştirir.
4.  **Firebase (Anlık Bildirim):** Firebase, ana veri depolama için **kullanılmaz**. Yalnızca cihazlara anlık bildirim (push notification) göndermek için gereken FCM (Firebase Cloud Messaging) token'ını almak amacıyla kullanılır. Bu token, `Globals.cache` içine kaydedilir ve `worker`'a gönderilen veri paketine dahil edilir.

---

## 1. GymScreen (Spor Salonu)

**Konum:** `scenes/GymScreen.tscn` ve `scripts/GymScreen.gd`

Bu sahne, oyuncunun günlük ve haftalık egzersiz programını takip etmesini ve düzenlemesini sağlar.

### `GymScreen.tscn` (Sahne Yapısı)
(Bu bölüm önceki raporla aynıdır)

### `GymScreen.gd` (Script Analizi)
(Bu bölüm önceki raporla aynıdır)

### `Globals` ve `Worker` Bağlantısı

-   **Veri Okuma:** `load_daily_list()` fonksiyonu, `Globals.cache["gym_log"]` dizisinden veri okur. Bu veri, uygulama açıldığında `worker`'dan senkronize edilmiş veya yerel `user_cache.json` dosyasından yüklenmiştir.
-   **Veri Yazma:** Kullanıcı "SAVE" butonuna bastığında `save_daily_data()` fonksiyonu çalışır. Bu fonksiyon, ekrandaki verileri toplayarak doğrudan `Globals.cache["gym_log"]` dizisini günceller.
-   **Senkronizasyon:** `save_daily_data()` fonksiyonu, `Globals.mark_dirty()` ve `Globals.save_cache()`'i çağırır.
    -   `save_cache()`: Değişiklikleri hemen yerel `user_cache.json` dosyasına yazar.
    -   `mark_dirty()`: `unsynced_changes` bayrağını `true` yapar ve `Globals`'ın bir sonraki uygun zamanda (örn. uygulama kapanırken) bu veriyi `worker`'a göndermesini tetikler.
-   **UI (Arayüz) Bağlantısı:** Sahnedeki "Geri" butonu, `UI` autoload'u üzerinden `UI.get_node("UIRoot").return_to_town()` fonksiyonunu çağırarak kasaba sahnesine geri döner.

---

## 2. Market

**Konum:** `scenes/market.tscn`, `scripts/market.gd`, `scripts/panel.gd`

Market sahnesi, oyuncunun farklı kategorilerdeki ürünleri görmesini sağlayan bir alışveriş arayüzüdür. Veri mantığı, `market.gd` tarafından yönetilen ve `panel.gd` script'ine sahip bir alt panel arasında bölünmüştür.

### `market.tscn` ve `market.gd` (Yapı ve Yönlendirme)
(Bu bölüm önceki raporla benzerdir)

### `panel.gd` (Asıl Veri Yöneticisi)
- **`load_category(cat_name)`:** Bu fonksiyon, `Globals.cache["market_items"]` dizisini okur. Sadece `cat_name` ile eşleşen kategoriye sahip ürünleri filtreleyerek ekranda listeler.
- **`save_items_to_cache()`:** Marketten çıkarken veya kategori değiştirirken çağrılır. Ekranda listelenen (ve kullanıcı tarafından değiştirilen) ürünleri ve diğer kategorilerdeki ürünleri birleştirerek `Globals.cache["market_items"]` dizisini günceller.

### `Globals` ve `Worker` Bağlantısı

-   **Veri Okuma:** `panel.gd` script'i, `load_category` içinde `Globals.cache["market_items"]` dizisinden veri okur.
-   **Veri Yazma:** `panel.gd` içindeki `save_items_to_cache` fonksiyonu, `Globals.cache["market_items"]` dizisini günceller ve `Globals.mark_dirty()` ile `Globals.save_cache()`'i çağırır.
-   **Senkronizasyon:** Gym sahnesinde olduğu gibi, `save_cache()` veriyi yerel dosyaya yazar, `mark_dirty()` ise `worker`'a gönderilmek üzere işaretler.
-   **UI Bağlantısı:** "Geri" butonu `UI.get_node("UIRoot").return_to_town()` ile kasaba sahnesine döner.

---

## 3. LibraryScreen (Kütüphane)

**Konum:** `scenes/LibraryScreen.tscn` ve `scripts/LibraryScreen.gd`

Bu sahne, oyuncunun kitap listesini ve haftalık ders çalışma programını yönetir.

### `LibraryScreen.tscn` (Sahne Yapısı)
(Bu bölüm önceki raporla aynıdır)

### `LibraryScreen.gd` (Script Analizi)
(Bu bölüm önceki raporla aynıdır)

### `Globals` ve `Worker` Bağlantısı

Bu sahne, iki farklı veri parçasını yönetir:

1.  **Kitap Listesi:**
    -   **Veri Okuma:** `load_books_to_ui()`, `Globals.cache["library"]` dizisinden veriyi okur.
    -   **Veri Yazma:** `_on_book_list_changed()`, metin kutularındaki değişiklikleri direkt olarak `Globals.cache["library"]` içine yazar ve `Globals.mark_dirty()`'i çağırır.
2.  **Çalışma Saatleri:**
    -   **Veri Okuma:** `get_study_data()`, `Globals.cache["study_log"]` dizisinden veri okur.
    -   **Veri Yazma:** `save_study_data()`, `Globals.cache["study_log"]` dizisini günceller ve `Globals.mark_dirty()`'i çağırır.

-   **Senkronizasyon:** Her iki veri türü için de yapılan değişiklikler, `Globals` aracılığıyla hem yerel `user_cache.json` dosyasına kaydedilir hem de sunucuya (`worker`) gönderilmek üzere işaretlenir.
-   **UI Bağlantısı:** "Geri" butonu, `UI` autoload'u üzerinden `UI.get_node("UIRoot").return_to_town()` fonksiyonunu çağırır.

---

## 4. Resturant (Restoran)

**Konum:** `scenes/resturant.tscn` ve `scripts/resturant.gd`

Bu sahne, oyuncunun haftalık yemek planını ve ilgili notları kaydetmesini sağlar.

### `resturant.tscn` (Sahne Yapısı)
(Bu bölüm önceki raporla aynıdır)

### `resturant.gd` (Script Analizi)
(Bu bölüm önceki raporla aynıdır)

### `Globals` ve `Worker` Bağlantısı

-   **Veri Okuma:** `_get_data_for_day()` fonksiyonu, seçilen günün verilerini `Globals.cache["restaurant"]` dizisinden okur.
-   **Veri Yazma:** Kullanıcı bir yemek veya not alanına yazı yazdığında tetiklenen `_on_meal_text_changed()` ve `_on_notes_changed()` fonksiyonları, `_save_data`'yı çağırır. `_save_data`, `Globals.cache["restaurant"]` dizisini günceller.
-   **Senkronizasyon:** `_save_data` fonksiyonu, `Globals.mark_dirty()`'i çağırarak yapılan değişiklikleri hem yerel dosyaya kaydeder hem de `worker`'a gönderilmek üzere işaretler.
-   **UI Bağlantısı:** "Geri" butonu, `UI.get_node("UIRoot").return_to_town()` fonksiyonunu çağırarak kasaba sahnesine geri döner.
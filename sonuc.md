### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scripts\Wardrobe.gd`

Bu Godot GDScript dosyası, oyuncunun gardırop arayüzünü yönetir. Temel işlevleri şunlardır:

*   **Gardırop Yönetimi:** Oyuncunun "outer" (dış giyim), "dress" (elbise), "upper" (üst giyim), "lower" (alt giyim) ve "shoes" (ayakkabı) gibi kategorilerdeki kıyafetlerini gösterir. Kullanıcı bu kıyafetler arasında gezinebilir.
*   **Resim Yükleme ve Gösterme:** Kıyafet resimlerini Supabase Storage'dan indirir ve arayüzde gösterir. Oyunun donmasını engellemek için resimleri arka planda asenkron olarak indiren bir kuyruk sistemi (`download_queue`) kullanır.
*   **Yeni Kıyafet Ekleme:** Kullanıcının cihazından bir resim dosyası seçmesine olanak tanır.
*   **Yapay Zeka Destekli Sınıflandırma:**
    *   Seçilen resim, bir Cloudflare Worker'a (`/api/classify_clothing_vit`) gönderilerek kıyafetin kategorisi (örneğin, "üst giyim") ve adı yapay zeka ile belirlenir.
    *   `detect_dominant_color` fonksiyonu ile resimdeki baskın rengi yerel olarak tespit eder.
    *   Yapay zekadan gelen isimle rengi birleştirerek "Mavi Tişört" gibi nihai bir isim oluşturur.
*   **Supabase Entegrasyonu:** Sınıflandırılan kıyafet resmini Supabase Storage'a yükler ve bilgilerini (`image_url`, kategori, isim vb.) `Globals` ismindeki global bir değişkende saklar.
*   **Otomatik Kombin Oluşturma:** "Sihirli Düğme" (`MagicButton`), kullanıcının gardırobundaki tüm kıyafetleri bir Cloudflare Worker'a (`/api/generate_outfit`) göndererek otomatik olarak bir kombin önerisi alır ve bunu bir popup ile gösterir.
*   **Veri ve Sahne Yönetimi:** Oyuncu verilerini ve resim dokularını yönetmek için `Globals` singleton'unu kullanır. Oyuncu "house.tscn" (ev sahnesi) sahnesine girdiğinde gardırop resimlerini otomatik olarak indirmeye başlar.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\WardrobeItemListPopup.tscn`

Bu bir Godot Sahne (`.tscn`) dosyasıdır ve gardırop içindeki eşyaları listelemek için kullanılan bir popup (açılır pencere) arayüzünü tanımlar.

*   **Ana Düğüm (Root Node):** Sahnenin ana düğümü bir `PopupPanel`'dir. Bu, sahnenin diğer arayüzlerin üzerinde bir diyalog penceresi olarak belireceği anlamına gelir.
*   **Betik (Script):):** `WardrobeItemListPopup.gd` adlı bir betik bu sahneye bağlanmıştır. Bu betik, popup'ın tüm mantığını ve davranışlarını kontrol eder.
*   **Tema (Theme):** `Wardrobe.tres` dosyasından bir tema alarak gardırop ekranıyla tutarlı bir görsel stil sağlar.
*   **Sahne Yapısı:** 
    *   `VBoxContainer`: Arayüz elemanlarını dikey olarak hizalar.
    *   `Label`: Pencerenin üst kısmında "Title" (Başlık) yazan bir etiket bulunur. Bu etiket, betik tarafından o anki kategoriye göre (örn: "Üst Giyim") dinamik olarak güncellenir.
    *   `ScrollContainer`: İçindeki eşya listesi ekrana sığmazsa kullanıcının listeyi kaydırmasına olanak tanır.
    *   `GridContainer`: Kıyafet eşyalarını 2 sütunlu bir grid (ızgara) yapısında göstermek için kullanılır. Kıyafet kartları (`ItemCard.tscn` olabilir) bu düğümün içine betik tarafından dinamik olarak eklenecektir.
    *   `CloseButton`: Pencereyi kapatmak için kullanılan "CLOSE" etiketli bir düğme.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scripts\WardrobeItemListPopup.gd`

Bu betik, `WardrobeItemListPopup.tscn` sahnesinin arkasındaki mantığı yönetir. Görevi, belirli bir giysi kategorisindeki (örneğin, tüm üst giyimler) eşyaları bir grid (ızgara) içinde listelemek ve kullanıcı etkileşimlerini yönetmektir.

*   **Sinyaller (Signals):** 
    *   `item_chosen`: Kullanıcı bir kıyafet seçtiğinde ana gardırop ekranına haber verir.
    *   `item_deleted`: Kullanıcı bir kıyafeti sildiğinde haber verir.
    *   `item_edited`: Kullanıcı bir kıyafetin bilgilerini güncellediğinde haber verir.
*   **Dinamik Arayüz Oluşturma:** 
    *   `open_category` fonksiyonu, bu betiğin ana işlevini yerine getirir. Çağrıldığında, `GridContainer` içindeki mevcut tüm eşya kartlarını temizler.
    *   Ardından, `Globals.cache["wardrobe"]` içindeki tüm kıyafetleri istenen kategoriye göre filtreler.
    *   Filtrelenmiş her bir kıyafet için `ItemCard.tscn` prefab'ından yeni bir kart oluşturur ve bunları grid'e ekler.
*   **Etkileşim Yönetimi:** 
    *   Her bir kıyafet kartından gelen sinyalleri dinler. Kullanıcı bir karta tıkladığında, silmek istediğinde veya düzenlemek istediğinde ilgili fonksiyonları tetikler.
*   **Diyalog Pencereleri:** 
    *   **Silme Onayı:** Bir eşyayı kalıcı olarak silmeden önce kullanıcıdan onay almak için bir `ConfirmationDialog` (Onay Diyaloğu) gösterir.
    *   **Düzenleme Penceresi:** Kod içerisinden dinamik olarak bir düzenleme penceresi oluşturur. Bu pencere, kullanıcının kıyafetin adını, kategorisini ve rengini değiştirmesine olanak tanıyan `LineEdit` (metin kutusu) ve `OptionButton` (seçenek düğmesi) elemanları içerir.
*   **Stil Yönetimi:** `apply_window_style` ve `apply_input_style` gibi fonksiyonlar aracılığıyla onay ve düzenleme pencerelerinin görsel stilini (renkler, fontlar, kenarlıklar vb.) kod üzerinden dinamik olarak ayarlar. Bu, oyunun genel estetiğiyle tutarlı bir görünüm sağlar.
*   **Modal Davranış:** `exclusive = true` ayarı sayesinde, bu popup açıkken arkadaki ana gardırop ekranıyla etkileşime girilmesini engeller, bu da daha kontrollü bir kullanıcı deneyimi sunar.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\prefabs\ItemCard.tscn`

Bu Godot Sahne dosyası, tek bir eşya kartını temsil eden, yeniden kullanılabilir bir "prefab" (şablon) tanımlar. Bu kartlar, `WardrobeItemListPopup` penceresinin içindeki grid'de her bir kıyafeti göstermek için kullanılır.

*   **Ana Düğüm:** Sahnenin temeli, arka plana sahip bir kutu görevi gören bir `Panel` düğümüdür.
*   **Betik (Script):** Kartın mantığı, `ItemCard.gd` betiği tarafından kontrol edilir. Bu betik, kartın resmini ve ismini ayarlamaktan ve düğme tıklamalarını yönetmekten sorumludur.
*   **Tema ve Stil:** 
    *   Ana `Wardrobe.tres` temasını kullanır.
    *   Panelin kendisine özel, yarı şeffaf bir arka plan rengi veren bir stil (`StyleBoxFlat`) ile özelleştirilmiştir.
*   **Sahne Yapısı:** 
    *   `VBoxContainer`: Kartın içindeki elemanları (resim, isim, düğmeler) dikey olarak sıralar.
    *   `TextureRect`: Kıyafetin resminin gösterileceği alandır.
    *   `Label`: Kıyafetin isminin yazılacağı etikettir. Varsayılan olarak "kıy" (muhtemelen "kıyafet"in kısaltması) yazar.
    *   `HBoxContainer`: Düzenle ve Sil düğmelerini yatay olarak yan yana dizer.
    *   `EditButton`: "EDIT" (Düzenle) yazan düğme. Tıklandığında, üst pencereye (`WardrobeItemListPopup`) bu eşyanın düzenlenmek istendiğini bildiren bir sinyal gönderir.
    *   `DeleteButton`: "DELETE" (Sil) yazan düğme. Tıklandığında, üst pencereye bu eşyanın silinme sürecini başlatması için bir sinyal gönderir.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\worker\src\index.js`

Bu JavaScript dosyası, projenin tüm arka uç (backend) mantığını içeren bir Cloudflare Worker betiğidir. Godot oyun istemcisi bu servis ile konuşarak veri kaydeder, veri çeker ve yapay zeka işlemlerini gerçekleştirir.

*   **Teknolojiler:** 
    *   **Sunucu:** Cloudflare Workers.
    *   **Veritabanı:** Cloudflare D1 (`env.DB`).
    *   **Yapay Zeka:** Google Gemini (`env.GEMINI_API_KEY`) ve Cloudflare AI (`env.AI`).
    *   **Kimlik Doğrulama & Depolama:** Supabase (Auth ve Storage).
    *   **Anlık Bildirim:** Firebase Cloud Messaging (FCM).

*   **Genel Yapı:** 
    *   Gelen isteğin URL'indeki yola (`/api/...`) göre ilgili işlemi yapan basit bir yönlendirici (router) içerir.
    *   Tüm cevaplara CORS başlıkları ekleyerek Godot istemcisinin farklı platformlardan (mobil, web) sorunsuzca erişimini sağlar.
    *   Belirli yolları korumak için bir kimlik doğrulama (authentication) kontrolü yapar. Gelen isteğin `Authorization` başlığındaki token'ı Supabase ile doğrular.

*   **Herkese Açık API Uç Noktaları (Auth Gerekmez):**
    *   `/api/login`: Kullanıcı girişi yapar.
    *   `/api/password-recover`: Şifre sıfırlama işlemi başlatır.
    *   `/api/daily_quests`: Google Gemini kullanarak oyun için 4 farklı kategoride (Spor, Kütüphane, Market, Restoran) günlük görevler üretir.
    *   `/api/classify_clothing_vit`: Gardırop için yüklenen bir resmin ne olduğunu (tişört, pantolon vb.) Cloudflare AI kullanarak anlar, kategorisini belirler (`upper`, `lower` vb.) ve kıyafet olmayan resimleri (örn: araba, kedi) eler.
    *   `/api/generate_outfit`: Kullanıcının gardırobundaki kıyafetleri ve "günlük" gibi bir stili Google Gemini'ye göndererek şık bir kombin oluşturmasını ister.
    *   `/api/ai_chat`, `/api/ai_diet`, `/api/ai_library`: Oyundaki farklı NPC'ler (Spor Hocası, Diyetisyen, Kütüphaneci) için yapay zeka sohbet servisleri. Oyuncunun verilerini (örn: spor geçmişi) ve sorusunu Gemini'ye göndererek kişiselleştirilmiş ve bağlama uygun cevaplar üretir.

*   **Korumalı API Uç Noktaları (Auth Gerekli):**
    *   `/api/load_all`: Giriş yapmış kullanıcının tüm verilerini (profil, gardırop, görevler, günlükler vb.) veritabanından tek seferde çeker.
    *   `/api/save_all`: Oyundan gelen tüm kullanıcı verilerini tek bir istekte alıp veritabanındaki ilgili tablolara kaydeder veya günceller. Bu, oyunun ana senkronizasyon mekanizmasıdır.
    *   `/api/delete_item`: Bir gardırop eşyasını hem veritabanından hem de Supabase Storage'dan kalıcı olarak siler.

*   **Zamanlanmış Görev (`scheduled`):** 
    *   Günün belirli bir saatinde otomatik olarak çalışır.
    *   Anlık bildirim izni vermiş tüm kullanıcılara, o gün tamamlamadıkları görevleri özetleyen kişiselleştirilmiş bir bildirim göndererek onları oyuna geri dönmeye teşvik eder.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\questmanager.gd`

Bu GDScript dosyası, oyundaki tüm görevleri yöneten merkezi bir sistemdir. Otomatik olarak yüklenen (autoload) bir `Node` olduğu için oyunun her yerinden erişilebilir.

*   **Görev Türleri:** 
    *   **Statik Görevler:** "Spor salonuna ilk kez gir" gibi tek seferlik, önceden tanımlanmış görevlerdir. Bu görevler `static_quest_definitions` dizisinde tanımlanır. Betik, oyuncunun görev listesinde eksik olan statik görevleri otomatik olarak ekler.
    *   **Günlük Görevler:** Her gün yenilenen görevlerdir. Betik, mevcut gün için yeni görevlerin alınıp alınmadığını kontrol eder. Eğer alınmamışsa, Cloudflare Worker'daki `/api/daily_quests` API'sini çağırarak yeni görevleri getirir.
*   **Ana Mantık:** 
    *   `check_and_init_quests`: Oyuncunun görev listesine eksik statik görevleri ekler.
    *   `check_daily_quests`: Yeni günlük görevlerin sunucudan çekilip çekilmeyeceğine karar verir.
    *   `_on_daily_received`: Sunucudan gelen günlük görevleri alır, mevcut görev listesiyle birleştirir ve `Globals` önbelleğini günceller.
*   **Görev Tetikleme Sistemi:** 
    *   `trigger_action(action_name)`: Oyunun farklı yerlerinden (örneğin, bir binaya girildiğinde) çağrılan çok önemli bir fonksiyondur.
    *   Çağrıldığında, tamamlanmamış görevler listesini kontrol eder. Eğer `action_name` ile eşleşen bir görev hedefi (`target_action`) bulursa, o görevi "tamamlandı" olarak işaretler.
    *   Oyuncuya `xp_reward` kadar tecrübe puanı (`XP`) verir ve ekranda bir bildirim gösterir.
*   **Arayüz Bildirimleri:** 
    *   **Bildirim Kuyruğu:** Birden fazla görevin aynı anda tamamlanması durumunda bildirim pencerelerinin üst üste binmesini engellemek için bir kuyruk (`notification_queue`) sistemi kullanır.
    *   `show_mission_popup`: "GÖREV TAMAMLANDI!" yazan, görevin açıklamasını ve kazanılan XP'yi gösteren bir pencere oluşturur ve canlandırır.
    *   `show_unlock_popup`: Yeni bir karakter açıldığında oyuncuyu bilgilendirmek için farklı bir temaya sahip özel bir pencere gösterir.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\GymScreen.tscn`

Bu Godot Sahne dosyası (`.tscn`), oyunun Spor Salonu (Gym) ekranının arayüzünü oluşturur. Bu arayüz, oyuncuların antrenmanlarını planlamasına, kaydetmesine ve görüntülemesine olanak tanır.

*   **Betik (Script):** Sahnenin tüm mantığı `GymScreen.gd` betiği tarafından yönetilir.
*   **Ana Yapı:** 
    *   `TabContainer`: Arayüzü "Daily" (Günlük) ve "Weekly" (Haftalık) olmak üzere iki ana sekmeye ayırır.
    *   **"Daily" Sekmesi:** 
        *   **Tarih Navigasyonu:** Kullanıcının farklı günleri görmesi için "TODAY" (Bugün) gibi düğmeler ve tarih seçimi için `OptionButton`'lar bulunur.
        *   **Liste Başlığı:** Egzersiz listesi için "Bitti", "İsim", "Set", "Tekrar" gibi statik başlıklar içerir.
        *   **Egzersiz Listesi:** Seçilen günün antrenman kayıtları bu alanda listelenir. `GymScreen.gd` betiği, her bir egzersiz için `DailyExerciseRow.tscn` şablonunu kullanarak dinamik olarak satırlar oluşturur ve bunları `ContentList` içine ekler.
        *   **Eylem Düğmeleri:** Yeni bir egzersiz satırı eklemek için "ADD" (Ekle) ve değişiklikleri kaydetmek için "SAVE" (Kaydet) düğmeleri mevcuttur.
    *   **"Weekly" Sekmesi:** 
        *   **Lejant (Legend):** Egzersizlerin durumunu (örn: Yeşil = Tamamlandı, Kırmızı = Geçmiş & Tamamlanmadı) açıklayan renk kodlu bir gösterge paneli bulunur.
        *   **Haftanın Günleri:** Pazartesiden pazara kadar her gün için bir satır ayrılmıştır.
        *   **Yatay Egzersiz Görünümü:** Her günün karşısında, o günün egzersizlerini `WeeklyExerciseRow.tscn` şablonuyla yatay olarak gösteren kaydırılabilir bir alan vardır. Bu, haftalık plana hızlı bir bakış sağlar.
*   **NPC Etkileşimi:** 
    *   Ekranda bir spor hocası karakterini temsil eden bir `TextureButton` (resimli düğme) bulunur.
    *   Karakterin yanında "Yardım lazım mı?" yazan bir konuşma balonu yer alır.
    *   Bu karaktere tıklandığında, `_on_texture_button_pressed` metodu tetiklenir. Bu metodun, oyuncunun yapay zeka spor hocasıyla sohbet edebileceği `ChatPopup` sahnesini açması muhtemeldir.
*   **Diğer Elemanlar:** 
    *   Arka plan resmi, geri dönme düğmesi ve dekoratif bir spor salonu tabelası gibi çeşitli görsel elemanlar içerir.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scripts\globals.gd`

Bu GDScript dosyası, oyunun "beyni" olarak kabul edilebilir. Godot'ta "Singleton" (Autoload) olarak ayarlanmıştır, bu da oyunun her yerinden `Globals` adıyla tek bir örneğine erişilebildiği anlamına gelir. Oyunun tüm genel durumunu ve veri yönetimini üstlenir.

*   **Temel Bileşenler:** 
    *   **`cache` Sözlüğü:** Oyunun anlık durumunu tutan devasa bir sözlüktür. Oyuncu profili (`isim`, `seviye`, `XP`), tüm aktivite kayıtları (`gym_log`, `study_log`), eşya listeleri (`kütüphane`, `market`, `gardırop`) ve görevler gibi oyunla ilgili her şey bu sözlük içinde saklanır.
    *   **Sinyaller (Signals):** 
        *   `data_updated`: `cache` içindeki veriler değiştiğinde yayınlanır. Arayüz elemanları bu sinyali dinleyerek kendilerini otomatik olarak günceller.
        *   `sync_finished`: Sunucu ile ilk veri senkronizasyonu tamamlandığında yayınlanır. Bu, yükleme ekranının ne zaman kapanacağını belirler.
    *   **Anlık Bildirim (FCM) Entegrasyonu:** 
        *   Mobil platformlarda (Android/iOS) Firebase servisini başlatır.
        *   Cihaz için özel bir anlık bildirim "token"ı alır ve bunu `cache` içine kaydeder.
        *   Bu token'ı sunucuya göndererek, zamanlanmış görevin doğru cihaza bildirim atmasını sağlar.
    *   **Veri Kaydı ve Senkronizasyon:** 
        *   **Yerel Kayıt:** `save_cache()` ve `load_cache()` fonksiyonları, `cache` sözlüğünü cihazda bir JSON dosyasına (`user_cache.json`) yazıp okur. Bu, internet olmasa bile verilerin korunmasını sağlar.
        *   **Sunucu Senkronizasyonu:** Oyun alta alındığında, kapatıldığında veya sahne değiştirildiğinde `cache` içeriğini otomatik olarak Cloudflare Worker'daki `/api/save_all` adresine gönderir. Bu sayede veri kaybı riski en aza indirilir.
        *   **İlk Yükleme:** Oyun başlangıcında `load_from_server()` fonksiyonu ile sunucudaki en güncel veriyi çeker.
    *   **Veri Birleştirme (`merge_list`):** Çevrimdışı yapılan değişikliklerle sunucudan gelen verileri akıllıca birleştiren kritik bir fonksiyondur. Farklı veri türleri için özel kurallar içerir ve çift kayıt oluşmasını engeller.
    *   **Çoklu Kullanıcı Güvenliği (`prepare_for_user`):** Aynı cihazda farklı bir kullanıcı giriş yaparsa, önceki kullanıcının verilerini görmemesi için yerel `cache`'i tamamen sıfırlayan bir güvenlik mekanizmasıdır.
*   **Oyun Mantığı:** 
    *   **Sahne Yönetimi:** `change_scene_with_loading` fonksiyonu, verileri kaydedip bir yükleme ekranı göstererek sahneler arası güvenli geçişi sağlar.
    *   **Seviye ve XP Sistemi:** `add_xp` fonksiyonu, tecrübe puanı ekler, seviye atlanıp atlanmadığını kontrol eder ve bir sonraki seviye için gereken XP'yi hesaplar.
    *   **Seviye Atlama Ödülleri:** Seviye 2'ye ulaşıldığında, oyuncuya yeni bir karakterin kilidini açtığını bildiren özel bir pencere göstermek için `QuestManager`'ı tetikler.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scripts\GymScreen.gd`

Bu GDScript dosyası, `GymScreen.tscn` sahnesinin tüm mantığını ve etkileşimlerini yönetir. Spor salonu ekranının beyni olarak çalışır.

*   **Amaç:** Oyuncunun günlük ve haftalık antrenman programını görüntülemesini, yeni egzersizler eklemesini, var olanları silmesini ve tüm bu değişiklikleri kaydetmesini sağlar.
*   **Durum Yönetimi:** 
    *   `selected_date_dict`: Kullanıcının "Günlük" sekmesinde o an hangi tarihi incelediğini takip eder.
    *   `pending_deletes`: Kullanıcının sildiği ama henüz veritabanından kalıcı olarak kaldırılmamış egzersizleri geçici olarak tutar.
*   **"Daily" (Günlük) Sekmesi Mantığı:** 
    *   **Tarih Kontrolü:** `go_to_today` (bugüne git) gibi fonksiyonlar ve tarih seçimi menüleri ile kullanıcıya günler arasında gezinme imkanı sunar.
    *   `load_daily_list`: Ekranın en önemli fonksiyonlarından biridir. `Globals.cache["gym_log"]` içindeki tüm antrenman kayıtlarını okur, seçili tarihe ait olanları filtreler ve her bir kayıt için `DailyExerciseRow` (Günlük Egzersiz Satırı) şablonundan bir kopya oluşturarak listeyi dinamik olarak doldurur.
    *   **Veri Temizliği:** `_clean_duplicates` adlı bir yardımcı fonksiyon ile veritabanında yanlışlıkla oluşmuş birebir aynı kayıtları bularak temizler ve veri bütünlüğünü sağlar.
    *   `add_empty_row`: Kullanıcının yeni bir egzersiz ekleyebilmesi için listeye boş bir satır ekler.
    *   `save_daily_data`: "SAVE" düğmesine basıldığında çalışır. Ekrandaki tüm satırları okur, silinmesi istenenleri işler ve `Globals.cache["gym_log"]` listesini bu yeni verilerle tamamen günceller. Son olarak, bu değişikliğin sunucuya kaydedilmesi için `Globals`'ı "kirli" olarak işaretler.
    *   **Görev Tetikleme:** Kaydetme işlemi bittikten sonra `QuestManager`'a "gym_action" adlı bir eylemin gerçekleştiğini bildirerek ilgili görevin tamamlanmasını sağlar.
*   **"Weekly" (Haftalık) Sekmesi Mantığı:** 
    *   `refresh_weekly_view`: Bu sekme açıldığında çalışır. Mevcut haftanın başlangıcını (Pazartesi) hesaplar. Haftanın her günü için `gym_log`'u filtreler ve o güne ait egzersizleri `WeeklyExerciseRow` şablonunu kullanarak yatay bir liste halinde gösterir. Egzersizlerin tamamlanıp tamamlanmadığına veya geçmiş bir güne ait olup olmadığına göre renklerini ayarlar.
*   **Yapay Zeka Sohbeti:** 
    *   `_on_texture_button_pressed`: Sahnedeki NPC (oyuncu olmayan karakter) resmine tıklandığında tetiklenir. `ChatPopup` penceresini görünür hale getirerek oyuncunun yapay zeka antrenör ile sohbet etmesini başlatır.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\GymScreen.tres`

Bu bir Godot Tema Kaynak (`.tres`) dosyasıdır. `GymScreen.tscn` sahnesinde kullanılan arayüz (UI) elemanlarının görsel stilini tanımlar.

*   **Amaç:** Spor Salonu ekranındaki `Button` (Düğme), `TabContainer` (Sekme Konteyneri), `LineEdit` (Metin Kutusu), `Label` (Etiket) gibi tüm kontrol düğümlerinin tutarlı bir görünüme sahip olmasını sağlamak.
*   **Bağımlılıklar:** 
    *   Arayüzdeki tüm metinler için `res://assets/fonts/PressStart2P-Regular.ttf` adlı pixel-art font dosyasını kullanır.
    *   `CheckBox` (Onay Kutusu) elemanının "seçili" ve "seçili değil" durumları için `check.png` ve `uncheck.png` resimlerini kullanır.
*   **Stil Detayları:** 
    *   Dosyanın büyük bir kısmı, arayüz elemanlarının arka planını, kenarlıklarını ve köşe yuvarlaklıklarını tanımlayan `StyleBoxFlat` kaynaklarından oluşur.
    *   **Renk Paleti:** Spor salonu ekranına özgü, ağırlıklı olarak pembe, leylak ve eflatun tonlarından oluşan bir renk paleti kullanır. Bu, ekranın oyunun diğer bölümlerinden görsel olarak ayrışmasını sağlar.
    *   **Düğme Stilleri:** Düğmelerin "normal", "fareyle üzerine gelindiğinde" (`hover`) ve "basıldığında" (`pressed`) durumları için farklı arka plan renkleri ve görünümler tanımlar.
    *   **Sekme Stilleri:** `TabContainer` içindeki seçili sekmenin, seçili olmayan sekmelerin ve üzerine gelinen sekmelerin nasıl görüneceğini belirler.
    *   **Diğer Kontroller:** `ScrollBar` (Kaydırma Çubuğu), `LineEdit` (Metin Giriş Kutusu) gibi diğer tüm arayüz elemanları için de benzer şekilde detaylı stil tanımlamaları içerir.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scripts\resturant.gd`

Bu GDScript dosyası, oyunun Restoran (Yemek Günlüğü) ekranının mantığını yönetir. Dosya adındaki "resturant" bir yazım hatasıdır, "restaurant" olmalıdır.

*   **Amaç:** Oyuncunun haftanın günlerine tıklayarak o güne özel kahvaltı, öğle yemeği, akşam yemeği ve atıştırmalıklarını kaydetmesini ve o güne özel notlar almasını sağlamak.
*   **Arayüz Yönetimi:** 
    *   **Gün Butonları:** Ekranda haftanın 7 günü için birer buton bulunur. Bir güne tıklandığında, o güne ait yemek giriş alanları ve not defteri görünür hale gelir.
    *   **Dinamik Tarih Hesaplama:** `get_date_string_for_day` fonksiyonu, betiğin en önemli mantığını içerir. Kullanıcı "Çarşamba" butonuna tıkladığında, bu fonksiyon o anki sistem tarihine göre içinde bulunulan haftanın Çarşamba gününün gerçek tarihini (örn: "2025-12-24") hesaplar. Bu, ekranın her zaman mevcut haftanın planını göstermesini sağlar.
    *   **Veri Gösterimi:** Bir gün seçildiğinde, o güne ait veriler `Globals.cache`'ten çekilir ve ilgili metin kutuları (`TextEdit`) bu verilerle doldurulur.
*   **Veri Yönetimi:** 
    *   **Veri Yapısı:** Tüm yemek kayıtları, `Globals.cache["restaurant"]` adlı bir listede tutulur. Listenin her bir elemanı, `tarih`, `kahvaltı`, `öğle_yemeği` gibi alanlar içeren birer sözlüktür.
    *   `_get_data_for_day`: Belirli bir tarihe ait yemek kaydını `Globals.cache` içinden bulup getirir.
    *   `_save_data`: Merkezi kayıt fonksiyonudur. Kullanıcı bir yemek veya not alanına bir şey yazdığında tetiklenir.
        1.  `Globals.cache` içinde o güne ait bir kayıt olup olmadığını kontrol eder.
        2.  Kayıt varsa, sadece ilgili alanı (örn: `kahvaltı` alanını) günceller.
        3.  Kayıt yoksa, o tarih için yeni bir sözlük oluşturur, değiştirilen alanı doldurur ve bunu ana listeye ekler.
        4.  Son olarak, `Globals.mark_dirty()`'yi çağırarak verilerin sunucuya kaydedilmesi gerektiğini bildirir.
*   **Görev Sistemi Entegrasyonu:** 
    *   Kullanıcı bir alana herhangi bir veri girip kaydettiğinde, `QuestManager`'ı tetikleyerek "eat_action" (yemek yeme eylemi) ve "first_restaurant" (restorana ilk giriş) gibi görevlerin tamamlanmasını sağlar.
*   **Sahne Akışı:** 
    *   "Geri" düğmesi, yapılan son değişiklikleri kaydeder ve `UI` singleton'u aracılığıyla ana kasaba ekranına geri döner.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scripts\market.gd`

Bu GDScript dosyası, oyunun Market ekranının ana kontrolcüsü olarak görev yapar. Kullanıcının farklı ürün kategorileri arasında gezinmesini ve bu kategorilerdeki listeleri yönetmesini sağlar.

*   **Amaç:** Market arayüzünü yönetmek, kategori geçişlerini kontrol etmek ve veri kaydetme/yükleme işlemlerini tetiklemek.
*   **Arayüz Kontrolü:** 
    *   Ekranda bulunan "Groceries" (Bakkaliye), "Home Goods" (Ev Eşyaları), "Clothing" (Giyim) gibi farklı kategorilere ait düğmeleri yönetir.
    *   Bu kategorilerdeki ürünlerin listelendiği bir `Panel`'in görünürlüğünü ve içeriğini kontrol eder.
*   **İşlevsellik:** 
    *   `_switch_category`: Bir kategori düğmesine basıldığında tetiklenir.
        1.  Önce, eğer başka bir kategori açıksa, o kategoriye ait verileri (`panel.save_items_to_cache()` aracılığıyla) kaydeder.
        2.  Ardından, markette bir eylem yapıldığını bildirmek için `QuestManager`'ı tetikler (`market_add`, `first_market` görevleri için).
        3.  `Panel`'i görünür hale getirir ve `panel.load_category` fonksiyonunu çağırarak yeni seçilen kategoriye ait ürünleri listeler.
    *   `_on_back_button_pressed`: "Geri" düğmesine basıldığında çalışır.
        1.  Açık olan kategorideki değişiklikleri kaydeder.
        2.  Verilerin sunucuyla senkronize edilmesi için `Globals.mark_dirty()` ile veriyi "kirli" olarak işaretler.
        3.  `QuestManager`'ı tekrar tetikler.
        4.  Son olarak, `UI` singleton'u aracılığıyla oyuncuyu kasaba ekranına döndürür.
    *   `_on_global_data_updated`: Oyunun genel veritabanı (`Globals.cache`) güncellendiğinde, market listesinin de güncel kalması için mevcut kategoriyi yeniden yükler.
*   **Bağımlılıklar:** 
    *   `Panel`: Ürün listelerini göstermekten ve yönetmekten sorumlu olan alt düğüm.
    *   `Globals`: Oyunun genel verilerini tutan, veri güncellemelerini bildiren ve sunucu senkronizasyonunu yöneten singleton.
    *   `QuestManager`: Oyuncunun eylemlerini görevlerin ilerlemesiyle ilişkilendiren singleton.
    *   `UI`: Sahneler arası geçiş gibi genel arayüz işlemlerini yürüten singleton.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scripts\LibraryScreen.gd`

Bu GDScript dosyası, Kütüphane ekranının tüm işlevselliğini yönetir. Ekran, oyuncunun kitaplarını ve ders çalışma programını yönetmesi için iki ana panele ayrılmıştır.

*   **Amaç:** Oyuncunun okuduğu kitapları ve çalışma saatlerini kaydetmesini sağlamak, bu verileri `Globals` üzerinden yönetmek ve görev ilerlemesini tetiklemek.

*   **Sol Panel: Kitap Listesi Yönetimi (`reading`, `completed`, `wishlist`)**
    *   **Arayüz:** "Okuduklarım", "Bitirdiklerim" ve "Okuma Listem" için üç ayrı metin kutusu (`TextEdit`) bulunur.
    *   **Veri Yükleme (`load_books_to_ui`):** `Globals.cache["library"]` içindeki kitap listesini okur ve her kitabın `status` (durum) alanına göre ilgili metin kutusuna yazar. Veritabanındaki olası çift kayıtların arayüzde tekil görünmesini sağlayan bir filtreleme mekanizması içerir.
    *   **Çakışma Korumalı Kayıt (`_on_book_list_changed`):** 
        *   Herhangi bir metin kutusu değiştiğinde, tüm kutulardaki verileri baştan analiz eder.
        *   `_parse_text_edit_to_list` fonksiyonu, bir kitabın aynı anda sadece **tek bir kategoride** (örn: hem "okuduklarım" hem de "bitirdiklerim" listesinde) yer alabilmesini garantiler. Eğer bir kitap birden fazla listeye yazılırsa, öncelik sırasına göre ilk listedeki kaydı geçerli sayılır.
        *   Bu yeni ve temiz listeyi `Globals.cache["library"]` üzerine yazar ve veriyi senkronizasyon için "kirli" olarak işaretler.
    *   **Görev Entegrasyonu:** Kitap listesi her güncellendiğinde, `QuestManager`'a `study_action` ve `first_library` eylemlerini göndererek ilgili görevlerin tamamlanmasını sağlar.

*   **Sağ Panel: Çalışma Saatleri Yönetimi**
    *   **Arayüz:** Haftanın günleri için butonlar ve seçilen güne ait saatlik çalışma planını gösteren bir liste içerir.
    *   **Veri Yükleme (`load_hours_for_day`):** Bir gün seçildiğinde, o güne ait saatlik satırlar (`StudyHoursRow.tscn` şablonu kullanılarak) dinamik olarak oluşturulur. `Globals.cache["study_log"]` içinden o saate ait ders konusu verisi çekilerek ilgili satıra yazılır.
    *   **Veri Kaydetme (`save_study_data`):** Kullanıcı bir saat dilimine ders konusu yazdığında, bu bilgi anında `Globals.cache["study_log"]` listesine kaydedilir veya güncellenir.
    *   **Görev Entegrasyonu:** Bir ders konusu yazıldığında, görevlerin tamamlanması için `QuestManager` tetiklenir.

*   **Genel Fonksiyonlar:** 
    *   `_on_back_button_pressed`: Geri düğmesine basıldığında mevcut değişiklikleri kaydeder ve kasaba ekranına döner.
    *   `_on_texture_button_pressed`: Muhtemelen Kütüphaneci NPC ile sohbet penceresini (`ChatPopup_L`) açar.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\UserInterface\MissionsWindow.gd`

Bu GDScript dosyası, oyuncunun tüm görevlerini görüntülediği "Görevler Penceresi" arayüzünü yönetir.

*   **Amaç:** Oyuncunun görev listesini `Globals`'dan çekerek, sıralı ve anlaşılır bir şekilde ekranda listelemek.
*   **Dinamik Liste Oluşturma:** 
    *   Her bir görev için `res://scenes/prefabs/MissionRow.tscn` şablonunu kullanarak yeni bir satır oluşturur.
    *   `refresh_mission_list` fonksiyonu, `Globals.cache["quests"]` içindeki tüm görevleri alır.
*   **Akıllı Sıralama:** 
    *   Görevleri listelemeden önce onları "günlük" (`daily`) ve "diğer" (hikaye) olarak ikiye ayırır.
    *   Son listede **önce günlük görevleri**, sonra diğer görevleri göstererek oyuncunun öncelikli görevleri daha kolay görmesini sağlar.
*   **Görsel Durum Yönetimi:** 
    *   `load_missions` fonksiyonu, her bir görev satırını `quest` verisine göre doldurur:
        *   Görevin adı, detayı ve XP ödülü ilgili etiketlere yazılır.
        *   Görevin türüne göre `[DAILY]` veya `[STORY]` gibi bir ön ek eklenir.
        *   Görevin `is_completed` (tamamlandı mı) durumuna göre:
            *   Satır sonundaki "tik" ikonu (`CheckBox`) işaretli veya boş olarak ayarlanır. Bu ikonun kullanıcı tarafından değiştirilmesi engellenmiştir (`MOUSE_FILTER_IGNORE`).
            *   Tamamlanmış görevlerin yazı rengi, oyuncuya görsel geri bildirim vermek için yeşil yapılır.
*   **Veri Güncelliği ve Senkronizasyon:** 
    *   `_ready` fonksiyonunda, `Globals.data_updated` sinyaline bağlanır. Bu sayede, oyunun herhangi bir yerinde bir görev tamamlandığında veya yeni görevler eklendiğinde bu liste kendini **otomatik olarak yeniler**.
    *   Ayrıca, başlangıçta `QuestManager`'ın statik görevleri yüklemesi için `0.1` saniyelik kısa bir bekleme yapar ve ardından listeyi ilk kez doldurur.
*   **Pencere Kontrolü:** 
    *   `hide_missions_window` fonksiyonu, "Kapat" düğmesine basıldığında pencereyi gizler.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\UserInterface\MissionsWindow.tscn`

Bu Godot Sahne (`.tscn`) dosyası, oyunun "Görevler Penceresi" adlı arayüzünün görsel yapısını ve düzenini tanımlar.

*   **Ana Düğüm:** Sahnenin en üst seviye düğümü, arayüz elemanları için yaygın olarak kullanılan bir `Control` düğümüdür ve "MissionsWindow" olarak adlandırılmıştır.
*   **Betik Entegrasyonu:** Bu sahneye `MissionsWindow.gd` betiği eklenmiştir. Bu, pencerenin mantıksal davranışlarının bu betik tarafından kontrol edildiği anlamına gelir.
*   **Tema:** Arayüzdeki düğmeler, etiketler vb. gibi tüm kontrol elemanlarına tutarlı bir görünüm sağlamak için `res://scenes/UserInterface/maintheme.tres` temasını kullanır.
*   **Düzen ve Bileşenler:** 
    *   **Arka Plan (`NinePatchRect`):** "Background" adında bir `NinePatchRect` düğümü, pencerenin ölçeklenebilir arka planını oluşturur. `res://assets/ui/GUI/missions.png` dosyasındaki dokuyu kullanır ve ekran boyutuna duyarlı olacak şekilde merkeze sabitlenmiştir.
    *   **Kapat Düğmesi (`TextureButton`):** Arka plan panelinin içinde "CloseButton" adında bir `TextureButton` bulunur. Bu düğme, `missions.png` dokusunun belirli bir bölgesini (bir `AtlasTexture` olarak tanımlanmıştır) kullanarak pencereyi kapatma işlevini yerine getirir.
    *   **Kaydırma Konteyneri (`ScrollContainer`):** Görev listesi uzun olduğunda içeriğin kaydırılabilmesini sağlamak için bir `ScrollContainer` kullanılır. Bu da merkeze hizalıdır.
    *   **Görev Listesi Paneli (`VBoxContainer`):** `ScrollContainer`'ın içinde "MissionsPanel" adında bir `VBoxContainer` bulunur. `MissionsWindow.gd` betiği tarafından dinamik olarak oluşturulacak bireysel görev satırları (muhtemelen `MissionRow.tscn`'den türetilmiş), bu konteyner içine dikey olarak eklenir. Satırlar arasında 10 birimlik bir boşluk (`separation`) vardır.
*   **Kaynaklar:** 
    *   `missions.png`: Çeşitli arayüz elementlerini (arka plan, kapat düğmesi ikonu gibi) içeren bir doku atlası.
    *   `maintheme.tres`: Arayüz kontrol elemanlarının stilini tanımlayan tema kaynağı.
    *   `MissionsWindow.gd`: Sahnenin işlevselliğini sağlayan betik dosyası.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\UserInterface\UI.tscn`

Bu Godot Sahne (`.tscn`) dosyası, oyunun ana kullanıcı arayüzü (UI) kökünü tanımlar. Oyun dünyasının üzerinde görünen tüm diğer UI elemanları için bir kapsayıcı görevi görür. Genellikle "Autoload" (Singleton) olarak yapılandırılmış olup, oyun boyunca sürekli erişilebilir durumdadır.

*   **Ana Düğüm:** Sahnenin ana düğümü "UIRoot" adında bir `Control` düğümüdür.
*   **Betik Entegrasyonu:** Bu sahneye `UI.gd` betiği eklenmiştir. Çeşitli UI elemanlarını yöneten mantık bu betik içinde bulunur.
*   **Tema:** Oyunun tüm kullanıcı arayüzünde tutarlı bir görünüm sağlamak için `res://scenes/UserInterface/maintheme.tres` temasını kullanır.
*   **Düzen ve Bileşenler:** 
    *   **Yükleme Ekranı (`LoadingScreen.tscn`):** Sahne geçişleri veya veri yüklemeleri sırasında oyuncuya bilgi vermek ve bekletmek için bir `LoadingScreen` örneği bulunur. Kendi betiği (`LoadingScreen.gd`) ile davranışları yönetilir.
    *   **Ayarlar Penceresi (`SettingsWindow.tscn`):** Oyun ayarlarını görüntülemek ve değiştirmek için kullanılan `SettingsWindow` sahnesinin bir örneğidir.
    *   **Görevler Penceresi (`MissionsWindow.tscn`):** Oyuncunun aktif görevlerini ve tamamlanmış görevlerini gösteren `MissionsWindow` sahnesinin bir örneğidir.
    *   **Sohbet Pop-up'ları (`ChatPopup_R.tscn`, `ChatPopup_L.tscn`):** Genellikle NPC diyalogları veya oyuncuya özel mesajlar için kullanılan, sağa ve sola hizalı iki adet sohbet penceresi örneği içerir.
    *   **Avatar Penceresi (`AvatarWindow.tscn`):** Oyuncunun avatarını özelleştirmek veya görüntülemek için bir `AvatarWindow` örneği bulunur.
    *   **Çıktı Paneli (`Output`):** Genel oyun mesajlarını veya bildirimleri görüntülemek için içinde bir `Label` bulunan bir `Panel` düğümüdür.
    *   **Ana Kontrol Paneli (`MainControls`):** Oyuncunun temel navigasyon düğmelerini içeren bir `Control` düğümüdür.
        *   `MoneyLabel`, `XPLabel`, `TimeLabel`: Oyuncunun parasını, deneyim puanlarını ve oyun içi zamanı gösterir.
        *   `DailyMissionButton`: Görevler penceresini açmak için bir düğme.
        *   `SettingsButton`: Ayarlar penceresini açmak için bir düğme.
    *   **Gardırop Eşya Listesi Pop-up'ı (`WardrobeItemListPopup.tscn`):** Gardırop sistemi içindeki eşyaları listelemek için özel bir açılır penceredir.
    *   **Kombin Sonuç Pop-up'ı (`OutfitResultPopup.tscn`):** Otomatik kombin oluşturma sonuçlarını göstermek için bir açılır pencere.
    *   **Bildirim (`Notification`):** Geçici oyun içi bildirimleri göstermek için bir `Control` düğümü.
*   **Betik İşlevi:** `UI.gd` betiği, bu pencereleri gösterme/gizleme, aralarında veri aktarımı ve sinyalleri bağlama gibi işlemleri yöneterek genel kullanıcı arayüzü akışını sağlar.
### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\UserInterface\AvatarWindow.gd`

Bu GDScript dosyası, oyuncunun avatar özelleştirme penceresini yönetir.

*   **Ana İşlevler:** 
    *   **Arayüz Yönetimi:** Karakter istatistiklerini gösteren bir ana ekran ve değişiklik yapmak için bir düzenleme ekranı olmak üzere iki ana görünümü kontrol eder.
    *   **Veri Gösterimi:** Oyuncunun adını, seviyesini, XP'sini, doğum gününü ve karakter görünümünü `Globals` singleton'undan alıp gösterir.
    *   **XP ve Seviye Hesaplaması:** Oyuncunun seviyesini ve bir sonraki seviye için gereken XP'yi doğru bir şekilde hesaplayıp gösterir ve bir XP ilerleme çubuğunu günceller.
    *   **Karakter Seçimi:** 
        *   Oyuncunun mevcut karakterler arasında geçiş yapmasına olanak tanır (`char_1.tres`, `char_2.tres`, vb.).
        *   **Seviye Kilidi:** Karakterlerin oyuncunun seviyesine göre kilitli olduğu kritik bir özellik içerir. Örneğin, 2. karakteri seçebilmek için oyuncunun en az 2. seviyede olması gerekir. Kilitli bir karakter seçildiğinde görsel bir geri bildirim (kırmızı bir parlama) verir.
    *   **Veri Kalıcılığı:** 
        *   Düzenleme penceresindeki "Kaydet" düğmesine tıklandığında, oyuncunun adını ve doğum gününü `Globals.cache`'e kaydeder.
        *   Avatar penceresi kapatıldığında, seçilen `character_id`'yi `Globals.cache`'e kaydeder.
        *   Değişikliklerin sunucu ile senkronize edilmesi ve yerel olarak kaydedilmesi için `Globals.mark_dirty()` ve `Globals.save_cache()` fonksiyonlarını kullanır.
    *   **Görev Entegrasyonu:** Oyuncu adını ilk kez değiştirdiğinde (`first_name`) veya doğum gününü ayarladığında (`first_birthday`) `QuestManager` aracılığıyla ilgili görevleri tetikler.
    *   **Dinamik Arayüz Güncellemeleri:** `Globals.data_updated` sinyaline bağlanır. Bu sayede, oyunun başka bir yerinde veri (XP veya seviye gibi) değiştiğinde, avatar penceresinin arayüzü otomatik olarak ve anında güncellenir.
    *   **Tarih Seçiciler:** Kullanıcının doğum tarihini (gün, ay, yıl) seçmesi için açılır menüler sunar.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\market.tres`

Bu bir Godot Tema kaynak dosyasıdır (`.tres`) ve Market (Pazar) sahnesinin kullanıcı arayüzü (UI) elemanlarının görsel stilini tanımlar.

*   **Türü:** `Theme`
*   **Amacı:** Market sahnesindeki UI kontrolleri için tutarlı bir görünüm ve his sağlamak.
*   **Font:** Projedeki diğer UI temalarıyla tutarlı olarak "Press Start 2P" piksel sanat fontunu (`res://assets/fonts/PressStart2P-Regular.ttf`) kullanır.
*   **Renk Paleti:** Tema, mavi ve mor tonlarının hakimiyetindedir:
    *   Normal düğmeler açık, grimsi mavi bir arka plana sahiptir (`#B5CDEB`).
    *   Üzerine gelinen/odaklanılan düğmeler orta tonda bir mavi rengi paylaşır (`#94ADe3`).
    *   Basılan düğmeler daha koyu bir mavidir (`#77B1D4`).
    *   Font rengi koyu, doygunluğu azaltılmış bir mavidir (`#496580`).
    *   Kaydırma çubuğu elemanları çok koyu ve orta tonlarda maviler kullanır.
*   **Stil:**
    *   **Düğmeler (`Button`):** Tüm düğme durumları (normal, üzerine gelindiğinde, basıldığında, odaklanıldığında) `StyleBoxFlat` ile, yani düz renkli panellerle şekillendirilmiştir. Önemli bir özellik, tüm köşelerdeki 15 piksellik `corner_radius` (köşe yuvarlaklığı) olup, düğmelere belirgin, yuvarlak bir görünüm kazandırır.
    *   **Onay Kutuları (`CheckBox`):** Ayrıca düz renklerle şekillendirilmiştir.
    *   **Kaydırma Çubukları (`HScrollBar`, `VScrollBar`):** Hem yatay hem de dikey kaydırma çubuklarının "tutamacı" (tıklanıp sürüklenen kısım), yine 15 piksellik yuvarlak köşelere sahip olan koyu ve orta mavi `StyleBoxFlat` kaynakları ile şekillendirilmiştir.

Özetle, bu dosya, mavi/mor bir renk şemasına ve UI elemanları için belirgin şekilde yuvarlak köşelere sahip, uyumlu bir "Market" teması oluşturur.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\assets\characters\resources\char_1.tres`

Bu bir Godot `SpriteFrames` kaynak dosyasıdır. "1. karakter" olarak adlandırılan bir oyun karakteri için animasyonları tanımlar.

*   **Türü:** `SpriteFrames`
*   **Amacı:** Bir karakter spriti için tüm animasyon dizilimlerini depolayarak bir `AnimatedSprite2D` düğümünde kolayca yönetilmesini ve kullanılmasını sağlamak.
*   **Bağımlılık:** `res://assets/characters/character_5_frame64x64.png` konumundaki tek bir doku atlasına (bir spritesheet) dayanır. `character_5` dosya adı, kaynak adı olan `char_1` ile çelişkili görünmektedir; bu durum bir isimlendirme tutarsızlığına veya birden fazla karakter kaynağının aynı temel spritesheet'i paylaştığına işaret edebilir.
*   **Yapısı:** 
    *   **`ext_resource`**: Ana resim dosyasının yolunu tanımlar.
    *   **`sub_resource` (`AtlasTexture`)**: 18 adet `AtlasTexture` alt kaynağı bulunmaktadır. Her biri, ana doku atlası içinde belirli bir dikdörtgen bölgeyi (tek bir 64x64 kare) tanımlar. Bu, bireysel karelerin spritesheet'ten "kesilip" çıkarılma yöntemidir.
    *   **`resource` (`animations`)**: Dosyanın çekirdeğidir. Animasyon tanımlarını içeren bir dizidir.
*   **Tanımlanan Animasyonlar:** 
    *   **Boşta Kalma Animasyonları:** `idle_down`, `idle_left`, `idle_right`, `idle_up`. Her biri tek karelik bir animasyondur, yani karakter boştayken sabittir.
    *   **Yürüme Animasyonları:** `walk_down`, `walk_left`, `walk_right`, `walk_up`. Her biri üç kareden oluşarak basit bir yürüme döngüsü oluşturur.
*   **Animasyon Özellikleri:** Tüm animasyonlar `loop = true` (döngü açık) olarak ayarlanmış ve saniyede 5.0 kare hızına (`speed`) sahiptir.

Özetle, bu dosya, bir spritesheet'ten kareleri ayırarak ve onları isimlendirilmiş animasyon dizilimleri halinde düzenleyerek ilk oyuncu karakteri için sekiz yönlü (dört yönde boşta durma ve yürüme) animasyon setini tanımlar.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\Wardrobe.tres`

Bu, `Wardrobe` (Gardırop) sahnesi ve onunla ilişkili açılır pencereler (popup) için özel olarak tasarlanmış bir Godot `Theme` (Tema) kaynak dosyasıdır.

*   **Türü:** `Theme`
*   **Amacı:** Gardırop kullanıcı arayüzü elemanlarına benzersiz ve tutarlı bir görünüm kazandırmak.
*   **Fontlar:** İki farklı font ailesi kullanır:
    *   `PressStart2P-Regular.ttf`: `Button` ve `Label` gibi standart UI elemanları için kullanılan ana piksel-art fontu.
    *   `CherrySwash-Bold.ttf` ve `CherrySwash-Regular.ttf`: Sadece `RichTextLabel` kontrolü için kullanılan daha dekoratif, el yazısı benzeri fontlar. Bu, oyunun diğer bölümlerinden farklı olarak, gardırop içinde daha süslü metinlerin gösterilmesine olanak tanır.
*   **Renk Paleti:** Tema, ahşap, deri veya rahat bir dolap hissi uyandıran sıcak, altın-kahverengi ve sarı bir palet etrafında şekillendirilmiştir.
    *   **Kenarlıklar:** Hakim renk, koyu, pirinç benzeri bir sarı/altın rengidir (örneğin, `#c48605`, `#a06c03`). Çoğu eleman, özellikle düğmeler, arka plan rengi olmadan (`bg_color` şeffaf) bu altın rengini kenarlık olarak kullanır.
    *   **Kaydırma Çubukları ve Açılır Pencereler:** Kaydırma çubuğu tutamaçları ve açılır pencere panelleri, koyu kahverengi/bronz (`#553801`) ve aynı altın-sarı tonlarının bir karışımını kullanır.
    *   **Font Renkleri:** Düğme font renkleri de bu altın-sarı aralığındadır ve üzerine gelme veya basılma durumlarında parlaklıkları hafifçe değişir.
*   **Stil:**
    *   **Düğmeler (`Button`):** Stil, öncelikli olarak 2 piksel genişliğinde, harmanlanmış altın rengi bir kenarlık ve 7 piksellik bir köşe yuvarlaklığı ile tanımlanır, bu da onlara daha yumuşak, çerçeveli bir görünüm kazandırır. Arka planın şeffaf olması, kenarlığı en belirgin özellik haline getirir.
    *   **Açılır Pencereler (`PopupPanel`, `Window`):** Bunlar, koyu kahverengi, yarı şeffaf bir arka plana, kalın, harmanlanmış altın rengi bir kenarlığa ve daha büyük bir köşe yuvarlaklığına (15 piksel) sahiptir, bu da onlara sağlam, "çerçevelenmiş" bir görünüm verir.
    *   **Kaydırma Çubukları (`HScrollBar`, `VScrollBar`):** Tutamaçlar, 20 piksellik büyük bir köşe yuvarlaklığına sahip düz altın-sarı renktedir ve bu da onlara yuvarlak bir pastil görünümü kazandırır. Ayrıca hafif bir gölge efektine sahiptirler.
    *   **`RichTextLabel`:** Diğer UI elemanlarından farklı olarak, çeşitli metin stilleri (normal, kalın, italik) için `CherrySwash` font ailesini kullanacak şekilde özel olarak yapılandırılmıştır.

Özetle, bu dosya, çerçeveli, altın-sarı ve kahverengi renk şeması, yuvarlak köşeler ve zengin metinler için özel bir dekoratif font kullanımıyla karakterize edilen benzersiz bir "Gardırop" teması oluşturur. Bu, gardıroba oyunun diğer UI temalarına kıyasla daha sıcak, biraz rustik ve daha premium bir his verir.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\project.godot`

Bu, tüm uygulama için temel ayarları tanımlayan ana Godot proje yapılandırma dosyasıdır (`project.godot`).

*   **`config_version=5`**: Bu projenin Godot 4 için olduğunu belirtir.
*   **`[application]` bölümü:**
    *   `config/name`: Uygulamanın adını "RealLifeSimulationRPGApp" olarak ayarlar.
    *   `run/main_scene`: Oyunun giriş noktasını, benzersiz kimliği (`uid://by5fgbvxh4h1j`) ile belirtilen bir sahne dosyası olarak tanımlar. Bu, oyun başlatıldığında yüklenen ilk sahnedir.
    *   `config/features`: Projenin Godot 4.5 ve geniş donanım desteği sağlayan "GL Uyumluluğu" (GL Compatibility) render motorunu kullandığını bildirir.
    *   `config/icon`: Uygulamanın ikonuna bir UID aracılığıyla işaret eder.
*   **`[autoload]` bölümü:** Bu, projenin mimarisini anlamak için en kritik bölümlerden biridir. Oyun başlangıcında yüklenen ve oyunun her yerinden erişilebilen global "Singleton"ları tanımlar.
    *   `Globals`: `*res://scripts/globals.gd` konumundaki global bir betik. Daha önce görüldüğü gibi, bu, tüm oyuncu verilerini ve oyun durumunu yöneten oyunun "beyni"dir.
    *   `UI`: Ana kullanıcı arayüzü sahnesi olan `*res://scenes/UserInterface/UI.tscn` de bir singleton'dur. Bu, herhangi bir betiğin pencereler ve HUD bileşenleri gibi UI elemanlarına kolayca erişip kontrol etmesini sağlar.
    *   `MusicController`: `*res://scenes/Autoloads/music_controller.tscn` konumundaki bir sahne, arka plan müziğini ve muhtemelen ses efektlerini küresel olarak yönetmekten sorumludur.
    *   `QuestManager`: `*res://questmanager.gd` betiği de bir autoload'dur, bu da tüm görevle ilgili mantığı yöneten merkezi sistem rolünü doğrular.
*   **`[display]` bölümü:**
    *   `window/size/viewport_width` ve `height`: Oyunun temel çözünürlüğünü 1280x720 olarak ayarlar.
    *   `window/stretch/mode="canvas_items"` ve `aspect="keep_width"`: Bu ayarlar, oyunun farklı ekran boyutlarında nasıl ölçekleneceğini tanımlar. Genişliği sabit tutarak orijinal en-boy oranını korurken UI elemanlarını ölçekler; bu, çeşitli çözünürlükleri desteklemesi gereken 2D oyunlar için yaygın bir kurulumdur.
*   **`[editor_plugins]` bölümü:**
    *   `enabled=PackedStringArray("res://addons/godotx_firebase/plugin.cfg")`: `godotx_firebase` eklentisini açıkça etkinleştirir, projenin kimlik doğrulama, mesajlaşma vb. özellikler için Firebase ile entegrasyonunu onaylar.
*   **`[input_devices]` bölümü:**
    *   `pointing/emulate_touch_from_mouse=true`: Fare tıklamalarının dokunma olayları olarak kabul edilmesini sağlar, bu da mobil öncelikli kullanıcı arayüzlerini bir masaüstü bilgisayarda test etmek için gereklidir.
*   **`[rendering]` bölümü:**
    *   `textures/canvas_textures/default_texture_filter=0`: Varsayılan doku filtrelemesini "En Yakın Komşu" (Nearest Neighbor) olarak ayarlar. Bu, piksel sanatı oyunlarında piksellerin bulanıklık olmadan keskin ve net görünmesini sağlamak için kasıtlı bir seçimdir.
    *   `renderer/rendering_method="gl_compatibility"`: Hem masaüstü hem de mobil için Uyumluluk render motorunun kullanıldığını yeniden onaylar, bu da oyunun daha eski ve daha az güçlü donanımlarda çalışmasını sağlar.
    *   `textures/vram_compression/import_etc2_astc=true`: Mobil cihazlar için verimli bir doku sıkıştırma formatını etkinleştirir, bu da mobil hedefli bir oyun için iyi bir optimizasyondur.

**Özet:**

Bu dosya, projenin üst düzey bir planını sunar. 720p temel çözünürlüğe sahip, mobil öncelikli, 2D bir piksel sanatı oyunu kurar. Mimari, durum, UI, ses ve oyun mantığını yönetmek için dört ana singleton'a (`Globals`, `UI`, `MusicController`, `QuestManager`) büyük ölçüde dayanır. Ayrıca Firebase ve GL Uyumluluk render motorunun kullanıldığını doğrular.
### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\prefabs\note_pop_up.gd`

Bu GDScript dosyası, takvimdeki belirli bir tarih için not almayı sağlayan bir açılır pencereyi yönetir.

*   **Arayüz Yönetimi:** Bir `PopupPanel`, bir başlık, not içeriği için bir `TextEdit` ve bir çıkış düğmesi içerir.
*   **Tarih İşleme:**
    *   `open_for_date` fonksiyonu, bir tarih nesnesi alarak çalışır. Tarihi veritabanı için "YYYY-AA-GG" formatına çevirir ve açılır pencerenin başlığını kullanıcı dostu "GG.AA.YYYY" formatında ayarlar.
    *   O tarihe ait mevcut bir notu `Globals.cache`'ten yükler.
*   **Veri Kalıcılığı:**
    *   `_save_note_to_cache`: Notu kaydeder. `Globals.cache["calendar_notes"]` listesinde ilgili tarih girişini bulur ve "note" değerini günceller. O tarihe ait bir giriş yoksa, yeni bir tane oluşturur. Boş notları da kaydedebilir. Kaydetme işlemi, çıkış düğmesine basıldığında gerçekleşir. Metin değiştikçe anında kaydetme seçeneği de yorum satırı olarak mevcuttur.
    *   `_get_note_from_cache`: Belirli bir tarihe ait notu `Globals.cache`'ten alır.
*   **Görev Entegrasyonu:** Açılır pencere açıldığında, muhtemelen bir eğitim görevini tamamlamak için `QuestManager`'daki `first_calendar` eylemini tetikler.
*   **Kullanıcı Deneyimi:**
    *   `exclusive` (özel) olarak ayarlanarak arkasındaki arayüzle etkileşimi engeller.
    *   Açıldıktan sonra bir kare bekler ve ardından kullanıcının hemen yazmaya başlamasına olanak tanımak için `TextEdit`'e otomatik olarak odaklanır.
*   **`Globals` Bağımlılığı:** Veri depolama (`Globals.cache`), veri temizleme (`Globals.safe_str`, `Globals.ensure_list`) ve sunucu senkronizasyonu için veriyi "kirli" olarak işaretleme (`Globals.mark_dirty`) gibi işlemler için `Globals` singleton'una büyük ölçüde bağımlıdır.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\Wardrobe.tscn`

Bu Godot Sahne dosyası (`.tscn`), "Gardırop" ekranının görsel düzenini ve yapısını tanımlar.

*   **Kök Düğüm:** Sahnenin ana düğümü, tüm ekranı kaplayan "Wardrobe" adında bir `Control` düğümüdür. Bu düğüme `Wardrobe.gd` betiği bağlanmıştır ve arayüz `Wardrobe.tres` temasını kullanır.
*   **Arka Plan:** `NinePatchRect` düğümü, `wardrobe.png` resmini kullanarak sahne için ölçeklenebilir bir arka plan oluşturur.
*   **Kıyafet Yuvaları:** Ana düzen, iki dikey kutu (`VBoxContainer`) içeren bir yatay kutu (`HBoxContainer`) ile organize edilmiştir. Bu kaplar, farklı kıyafet kategorileri için yuvalar içerir:
    *   `SlotOuter` (Dış Giyim)
    *   `SlotDress` (Elbise)
    *   `SlotUpper` (Üst Giyim)
    *   `SlotLower` (Alt Giyim)
    *   `SlotShoes` (Ayakkabı)
*   **Yuva Yapısı:** Her bir yuva, şeffaf bir arka plana sahip bir `Panel`'dir. Her panelin içinde, yatay olarak üç öğeyi düzenleyen bir `HBoxContainer` bulunur:
    *   "<" etiketli bir "Geri" `Button`'u.
    *   Kıyafetin resminin gösterileceği bir `TextureRect`.
    *   ">" etiketli bir "İleri" `Button`'u.
Bu yapı, oyuncunun her kategorideki eşyalar arasında gezinmesine olanak tanır.
*   **Eylem Düğmeleri:**
    *   `AddClothesButton`: "ADD CLOTHES" (Kıyafet Ekle) etiketli bir düğme.
    *   `MagicButton`: "TODAY'S OUTFIT" (Günün Kombini) etiketli, muhtemelen otomatik kombinasyon oluşturmayı tetikleyen bir düğme.
    *   `CloseButton`: Gardırop ekranından çıkmak için kullanılan "<-" etiketli bir düğme.
*   **Betik ve Tema:** Sahne, `TextureRect`'leri dolduracak ve tüm düğme tıklamalarını yönetecek olan `Wardrobe.gd` betiğiyle sıkı bir şekilde bağlantılıdır. Görsel görünüm, `Wardrobe.tres` tema dosyası tarafından tanımlanır.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\scenes\UserInterface\SettingsWindow.gd`

Bu GDScript dosyası, oyunun ayarlar penceresini yönetir.

*   **Arayüz Yönetimi:** Ayarlar penceresini temsil eden bir `Control` düğümünü kontrol eder. Bir `close_button` ve bir `volume_slider` içerir.
*   **Ses Kontrolü:**
    *   `_ready()`: Pencere hazır olduğunda, kayıtlı ses seviyesini `Globals.cache["preferences"]["music_volume"]`'dan yükler. Kayıtlı değer yoksa, varsayılan olarak 50 kullanır. Ardından kaydırıcının konumunu ayarlar ve sesi "Müzik" ses yoluna uygular.
    *   `_on_volume_slider_value_changed(value)`: Bu işlev, kullanıcı kaydırıcıyı hareket ettirdiğinde çağrılır. Yeni ses seviyesini `_apply_volume` aracılığıyla "Müzik" ses yoluna uygular ve `Globals.cache`'teki `music_volume`'u günceller.
    *   `_apply_volume(value)`: Doğrusal kaydırıcı değerini (0-100) desibele dönüştüren ve "Müzik" ses yolunun ses seviyesini ayarlayan yardımcı bir işlev.
*   **Veri Kalıcılığı:**
    *   Ses ayarı `Globals.cache`'te saklanır.
    *   `hide_settings_window()`: Pencere kapatıldığında, ayarları yerel `user_cache.json` dosyasına kaydetmek için `Globals.save_cache()`'i çağırır.
*   **Görev Entegrasyonu:** Ses seviyesi ilk kez değiştirildiğinde, `QuestManager`'daki `first_music` eylemini tetikler.
*   **Pencere Yönetimi:** `hide_settings_window` işlevi, pencereyi gizlemek için `close_button`'ın `pressed` sinyaline bağlıdır.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\questmanager.gd.uid`

Bu dosya, Godot'un `questmanager.gd` betiğini dahili olarak referans göstermek için kullandığı benzersiz bir kimlik (`uid://blha282not461`) içerir. Bu, dosya taşınsa veya yeniden adlandırılsa bile motorun onu bulabilmesini sağlar. Bu bir kod dosyası değildir ve herhangi bir mantık içermez.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\addons\calendar_library\calendar_locale.gd`

Bu GDScript dosyası, takvim eklentisi için yerelleştirilmiş hafta günü ve ay adlarını depolayan bir `CalendarLocale` kaynağı tanımlar.

*   **Kaynak:** `.tres` dosyası olarak oluşturulup kaydedilebilen bir `Resource`.
*   **Sınıf Adı:** `CalendarLocale` adında global bir sınıf olarak tanımlanmıştır.
*   **Tarih Formatı:** Yerel ayar için standart tarih formatını (örneğin, "Yıl-Ay-Gün", "Gün-Ay-Yıl") tanımlamak için dışa aktarılmış bir `date_format` numaralandırması ve tarih formatı için ayırıcıyı tanımlayan dışa aktarılmış bir `divider_symbol` değişkeni içerir.
*   **Yerelleştirme:** Tüm hafta günleri ve ayların tam adları, kısaltmaları ve kısa adları için dışa aktarılmış değişkenler sağlar:
    *   `monday`, `tuesday`, ...
    *   `abbr_monday`, `abbr_tuesday`, ...
    *   `short_monday`, `short_tuesday`, ...
    *   `january`, `february`, ...
    *   `abbr_january`, `abbr_february`, ...
    *   `short_january`, `short_february`, ...
*   **Kullanım:** Bu kaynak, takvimi doğru yerelleştirilmiş adlarla görüntülemek için bir `Calendar` nesnesine atanabilir. Varsayılan değerler İngilizce'dir. `demo` klasöründeki `calendar_locale_CN.tres` ve `calendar_locale_DE.tres` dosyaları gibi farklı diller için farklı `.tres` dosyaları oluşturulabilir.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\addons\calendar_library\calendar_locale.gd.uid`

Bu dosya, Godot'un `calendar_locale.gd` betiğini dahili olarak referans göstermek için kullandığı benzersiz bir kimlik (`uid://coa0a2gxpj6n5`) içerir. Bu, dosya taşınsa veya yeniden adlandırılsa bile motorun onu bulabilmesini sağlar. Bu bir kod dosyası değildir ve herhangi bir mantık içermez.

### `C:\Users\Hp\Desktop\RealLifeSimulationRPGApp\addons\calendar_library\calendar.gd`

Bu GDScript dosyası, Godot için kapsamlı bir `Takvim` kütüphanesi tanımlar. Bu, referans sayılarak yönetilen bir `RefCounted` sınıfıdır.

*   **Temel İşlevsellik:** Kütüphane, yıllık, aylık ve haftalık genel bakışlar için takvim verileri oluşturma işlevleri sunar. Godot'un `Time` singleton kurallarına uyar.
*   **Yerelleştirme:** Hafta içi günleri ve aylar için yerelleştirilmiş adlar sağlamak üzere `CalendarLocale` kaynağını kullanır. Başlatmada varsayılan bir İngilizce yerel ayarı oluşturulur.
*   **Tarih Biçimlendirme:**
    *   POSIX benzeri yer tutucular (ör. `%Y`, `%m`, `%d`, `%A`) kullanarak bir tarih dizesini biçimlendirebilen bir `get_date_formatted` işlevi sağlar.
    *   Ayrıca, atanmış `CalendarLocale`'deki ayarlara göre bir tarihi biçimlendirmek için `get_date_locale_format` işlevine sahiptir.
*   **Takvim Oluşturma:**
    *   `get_calendar_year`, `get_calendar_month`, `get_calendar_week`: Bu işlevler, bir yılı, ayı veya haftayı temsil eden `Tarih` nesnelerinden oluşan diziler döndürür. Bitişik günleri dahil etme ve tutarlı bir kullanıcı arayüzü sunumu için sabit sayıda hafta zorlama seçeneklerine sahiptirler.
*   **Tarih Hesaplama:**
    *   `is_leap_year`, `get_leap_days`, `get_days_in_month`, `get_days_in_year`, `get_day_of_year`: Tarihle ilgili hesaplamalar için bir dizi işlev.
    *   `get_weekday`: Belirli bir tarihin haftanın hangi günü olduğunu belirlemek için Zeller Uyum algoritmasını kullanır.
    *   `get_week_number`: Belirli bir tarihin hafta numarasını, iki farklı sistemi (`WEEK_NUMBER_FOUR_DAY` ve `WEEK_NUMBER_TRADITIONAL`) destekleyerek hesaplar.
*   **İç Sınıf `Date`:**
    *   `yıl`, `ay` ve `gün`ü saklamak için iç içe geçmiş bir `Tarih` sınıfı tanımlanmıştır.
    *   Doğrulama (`is_valid`), karşılaştırma (`is_before`, `is_after`, `is_equal`) ve düzenleme (`add_days`, `subtract_months`, vb.) için yöntemler içerir.
    *   Ayrıca, temiz bir dize gösterimi (ör. "2023-12-01") sağlamak için bir `_to_string` yöntemine sahiptir.
    *   Geçerli tarihi bir `Tarih` nesnesi olarak almak için statik bir `today()` işlevi sağlanmıştır.

Bu kütüphane, oyun içindeki tüm takvimle ilgili mantığı işlemek için güçlü ve bağımsız bir araçtır.
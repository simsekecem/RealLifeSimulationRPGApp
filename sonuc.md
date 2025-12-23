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
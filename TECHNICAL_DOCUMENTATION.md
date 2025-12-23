
# Teknik Dökümantasyon: RealLifeSimulationRPGApp

## 1. Giriş ve Felsefe

Bu döküman, `RealLifeSimulationRPGApp` projesinin teknik mimarisini, veri akışını ve temel bileşenlerini derinlemesine açıklamaktadır. Projenin temel felsefesi, **merkezi bir veri yönetimi** ve **kesintisiz bir oyun deneyimi** sunmaktır. Bu hedeflere ulaşmak için oyun, hem çevrimiçi (online) hem de çevrimdışı (offline) modları destekleyen hibrit bir yapı kullanır.

Mimarinin kalbinde, Godot'un "AutoLoad" özelliği ile bir singleton olarak yapılandırılmış `Globals.gd` betiği yer alır. Bu betik, oyunun "tek doğruluk kaynağı" (Single Source of Truth) olarak görev yapar ve tüm oyuncu verilerini, oyun durumunu ve genel konfigürasyonu yönetir. Bu merkeziyetçi yaklaşım, veri tutarlılığını sağlamayı, hata ayıklamayı kolaylaştırmayı ve projenin farklı modülleri arasındaki karmaşıklığı azaltmayı hedefler.

---

## 2. Temel Mimari ve Veri Akışı

Oyunun veri akışı, üç ana katman arasında gerçekleşir: **Yerel Depolama (JSON)**, **Oyun İçi Bellek (`Globals.cache`)**, ve **Uzak Sunucu (Cloudflare Worker)**.

```
+--------------------------+      +---------------------------+      +-------------------------+
|   Uzak Sunucu            |      |   Oyun İçi Bellek         |      |   Yerel Depolama        |
| (Cloudflare Worker)      |<---->| (Globals.gd -> cache)     |<---->| (user://cache.json)     |
+--------------------------+      +---------------------------+      +-------------------------+
           ^                                                                     ^
           | (HTTP İstekleri)                                                    | (Dosya I/O)
           |                                                                     |
+--------------------------------------------------------------------------------+
|                                  Oyun Motoru (Godot)                           |
+--------------------------------------------------------------------------------+
```

### 2.1. Kimlik Doğrulama ve İlk Veri Yükleme Akışı

1.  **Başlangıç:** Oyun, giriş ekranını içeren `scenes/auth_screen.tscn` ile başlar.
2.  **Kullanıcı Girişi:** `scripts/Login.gd` betiği, kullanıcının girdiği e-posta ve şifreyi alır.
3.  **API İsteği:** `_on_login_pressed` fonksiyonu tetiklendiğinde, `scripts/AuthBase.gd` içinde tanımlanan genel `send_request` fonksiyonu aracılığıyla Cloudflare Worker'a (`WORKER_URL`) bir POST isteği gönderilir.
4.  **Token Alımı:** Sunucudan başarılı bir yanıt (`200 OK`) dönerse, yanıtın body'sinden gelen kimlik doğrulama `token`'ı ve kullanıcı ID'si `Globals` singleton'ına kaydedilir (`Globals.set("user_id", ...)`).
5.  **Güvenli Sahne Geçişi:** `Login.gd`, doğrudan ana oyun sahnesine geçmek yerine `Globals.change_scene_with_loading("res://scenes/MainGame.tscn")` fonksiyonunu çağırır.
6.  **Yükleme Ekranı Devreye Girer:** Bu fonksiyon, önce `scenes/UserInterface/LoadingScreen.tscn` sahnesini yükler.
7.  **Eş Zamanlı Operasyonlar:** `LoadingScreen.gd` betiği `_ready` fonksiyonunda iki kritik işlemi başlatır:
    *   **Sunucu Senkronizasyonu:** `Globals.load_from_server()` çağrılır. Bu fonksiyon, sunucudan kullanıcının tüm verilerini (karakter, envanter, görevler vb.) çeker ve `Globals.cache` sözlüğüne doldurur. İşlem bittiğinde `Globals.is_initial_sync_done` `true` olarak ayarlanır.
    *   **Sahne Yüklemesi:** `ResourceLoader.load_threaded_request(...)` ile `MainGame.tscn` sahnesi arka planda yüklenmeye başlar.
8.  **Kapı Bekçisi (`Gatekeeper`) Lojíği:** `LoadingScreen.gd` içindeki `_process` fonksiyonu, her karede şu iki koşulun da sağlanıp sağlanmadığını kontrol eder:
    *   Sahne yüklemesi tamamlandı mı?
    *   `Globals.is_initial_sync_done` `true` mu?
9.  **Oyuna Giriş:** Her iki koşul da sağlandığında, yükleme ekranı `get_tree().change_scene_to_packed(...)` ile hafızadaki hazır sahneye geçer. Bu mekanizma, oyunun asla eksik veya eski veriyle başlamamasını garanti eder.

### 2.2. Oyun Sırasında Veri Yönetimi

*   **Veri Değişikliği:** Oyuncu bir eşya aldığında, bir görevi tamamladığında veya karakterinin bir özelliğini geliştirdiğinde, ilgili değişiklik doğrudan `Globals.cache` sözlüğü üzerinde yapılır. Örneğin: `Globals.cache.character.strength += 1`.
*   **Yerel Kayıt:** Belirli aralıklarla veya önemli olaylardan sonra (örn: sahne değişikliği), `Globals.save_cache()` fonksiyonu çağrılarak `cache` sözlüğünün güncel hali `user://cache.json` dosyasına yazılır. Bu, oyuncu internetini kaybederse veya oyunu kapatıp açarsa ilerlemesinin kaybolmamasını sağlar.
*   **Arka Plan Senkronizasyonu:** `Globals.send_to_server_background()` fonksiyonu, `cache`'in tamamını veya sadece değişen kısımlarını sunucuya göndererek verileri günceller. Bu sayede oyuncu farklı bir cihazdan giriş yaptığında kaldığı yerden devam edebilir.

---

## 3. Anahtar Betikler ve Sorumlulukları

### `scripts/globals.gd` (Singleton)
Projenin merkezi sinir sistemidir.
*   **`var cache = {}`**: Oyuncu verilerinin tamamını tutan sözlük. Hipotetik bir yapısı şöyledir:
    ```gdscript
    {
      "user_id": "...",
      "token": "...",
      "character": {
        "name": "Gemini",
        "level": 5,
        "strength": 12,
        "intelligence": 18,
        "outfit": { "shirt": "item_101", "pants": "item_203" }
      },
      "inventory": ["item_001", "item_004", "item_501"],
      "quests": {
        "main_quest_1": "completed",
        "side_quest_3": "in_progress"
      }
    }
    ```
*   **`func save_cache()` / `func load_cache()`**: `cache`'i JSON formatında yerel dosyaya yazar/okur. `load_cache` oyun başlangıcında çağrılarak çevrimdışı ilerlemeyi yükler.
*   **`func load_from_server()`**: Sunucudan gelen veri ile yerel `cache`'i akıllıca birleştirir. Örneğin, sunucuda olup yerelde olmayan bir eşyayı ekler.
*   **`func change_scene_with_loading(path)`**: Yukarıda açıklanan güvenli sahne geçiş mekanizmasını başlatır.

### `scripts/AuthBase.gd`
Yeniden kullanılabilir API iletişim katmanıdır.
*   **`const WORKER_URL = "..."`**: Tüm API isteklerinin gönderileceği merkezi sunucu adresi.
*   **`func send_request(endpoint, body)`**: `HTTPRequest` nodunu kullanarak belirtilen endpoint'e (`/login`, `/signup` vb.) bir JSON isteği gönderir. Sinyaller (`request_completed`) aracılığıyla sonucu çağıran betiğe (örn: `Login.gd`) bildirir. Bu yapı, kod tekrarını önler.

### `scripts/LoadingScreen.gd`
Veri tutarlılığının garantisidir.
*   `_process` içindeki kontrol mantığı, bu betiği projenin en önemli koruyucu mekanizmalarından biri yapar. Asenkron işlemlerin karmaşıklığını yönetir ve oyuncunun asla bir "yükleniyor..." ekranında takılıp kalmamasını veya eski verilerle oynamaya başlamamasını sağlar.

### `scripts/MainGame.gd`
Ana oyun dünyasının orkestra şefidir.
*   Bu betik, `MainGame.tscn` sahnesinin kök noduna bağlıdır. Bu sahne, `TownContainer` ve `HomeContainer` gibi boş `Node`'lar içerir. `MainGame.gd`'nin görevi, oyuncunun konumuna göre bu container'ların içine `town.tscn`, `house.tscn`, `market.tscn` gibi alt-sahneleri dinamik olarak yüklemek (`add_child`) ve gereksiz olanları kaldırmaktır (`remove_child`). Bu, tüm oyun dünyasını tek seferde belleğe yüklemek yerine sadece görünür olan alanı yükleyerek performansı artırır.

### `scripts/Interactable.gd` ve Türevleri
Dünya ile etkileşim altyapısıdır.
*   `Interactable.gd`, muhtemelen `_on_body_entered` gibi sinyalleri dinleyen ve oyuncu yaklaştığında bir "Etkileşime Gir" ipucu gösteren temel bir sınıftır.
*   `Door.gd`, `npc_interactable.gd` gibi betikler bu sınıftan miras alır.
*   Bir kapı (`Door.gd`) ile etkileşime girildiğinde, `Globals.change_scene_with_loading` çağrılarak başka bir mekana (örn: `house.tscn`) geçiş yapılır.
*   Bir NPC (`npc_interactable.gd`) ile etkileşime girildiğinde, `Globals.cache.quests` içindeki verilere göre bir diyalog penceresi (`chat_popup.tscn`) açılır.

---

## 4. Sonuç ve Öneriler

`RealLifeSimulationRPGApp`, sağlam, ölçeklenebilir ve veri odaklı bir mimari üzerine kurulmuştur. Merkezi `Globals.gd` yapısı ve güvenli yükleme ekranı mekanizması, projenin en güçlü yönleridir.

**Gelecekteki Geliştiriciler İçin Notlar:**
*   Yeni bir özellik eklerken, verisini mutlaka `Globals.cache`'e eklemeyi ve sunucu senkronizasyonunu düşünün.
*   Yeni bir mekan eklerken, bunu `MainGame.tscn`'e bir alt-sahne olarak yüklemeyi tercih edin.
*   Tüm sahne geçişlerini `Globals.change_scene_with_loading` üzerinden yaparak veri tutarlılığını koruyun.
*   Sunucu ile iletişim gerektiren yeni bir özellik için `AuthBase.gd`'yi genişletin veya kullanın.

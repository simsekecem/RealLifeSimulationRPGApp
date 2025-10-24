export default {
    async fetch(request, env) {
        const url = new URL(request.url);
        const path = url.pathname;
        const method = request.method;

        // Pages uygulamanızın CORS için kabul edilen URL'si
        const ALLOWED_ORIGIN = "https://life-sim.pages.dev"; 
        // Kullanıcının e-postadan tıklayınca yönlendirileceği adres
        const REDIRECT_URL = "https://life-sim.pages.dev/reset-password"; 
        
        // Tüm yanıtlara CORS başlıklarını ekleyen yardımcı fonksiyon
        const addCorsHeaders = (response) => {
            response.headers.set("Access-Control-Allow-Origin", ALLOWED_ORIGIN);
            response.headers.set("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS");
            response.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
            response.headers.set("Access-Control-Max-Age", "86400"); // 24 saat
            return response;
        };
        
        // ====================================================================
        // 1. HERKESE AÇIK ENDPOINT'LER ve CORS PRE-FLIGHT (ÖN KONTROL)
        // ====================================================================

        // CORS Pre-flight (OPTIONS) İsteğini Yönet
        // Hem şifre güncelleme hem de mail gönderme endpoint'leri için OPTIONS kontrolü
        if ((path === "/api/update-password" || path === "/api/password-recover") && method === "OPTIONS") {
             return addCorsHeaders(new Response(null, { status: 204 }));
        }
        
        /**
         * YENİ ENDPOINT: Şifre Sıfırlama Mailini Gönderme
         * POST /api/password-recover
         * Body: { "email": "kullanici@mail.com" }
         */
        if (path === "/api/password-recover" && method === "POST") {
            try {
                const { email } = await request.json();

                if (!email) {
                    const response = new Response(JSON.stringify({ error: "Email adresi gereklidir." }), {
                        status: 400, headers: { "Content-Type": "application/json" }
                    });
                    return addCorsHeaders(response);
                }

                // Supabase /auth/v1/recover endpoint'ine isteği gönder
                const recoverRes = await fetch(`${env.SUPABASE_URL}/auth/v1/recover`, {
                    method: "POST",
                    headers: {
                        "apikey": env.SUPABASE_ANON_KEY,
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        email: email,
                        // BURASI EN ÖNEMLİ KISIM: Kullanıcıyı doğru Pages sayfasına yönlendirir
                        redirect_to: REDIRECT_URL 
                    })
                });

                if (recoverRes.ok || recoverRes.status === 200) {
                    // Supabase, mail başarıyla gönderilse bile (güvenlik nedeniyle)
                    // her zaman 200 döner ve kullanıcı mailde yazanı görmez,
                    // sadece "mail gönderildi" mesajı gösteririz.
                    const response = new Response(JSON.stringify({ message: "Şifre sıfırlama maili gönderildi. Lütfen e-posta kutunuzu kontrol edin." }), {
                        status: 200, headers: { "Content-Type": "application/json" }
                    });
                    return addCorsHeaders(response);
                } else {
                    const errorData = await recoverRes.json();
                    const response = new Response(JSON.stringify({ error: errorData.msg || "Supabase hatası: Mail gönderilemedi." }), {
                        status: recoverRes.status, headers: { "Content-Type": "application/json" }
                    });
                    return addCorsHeaders(response);
                }

            } catch (e) {
                const response = new Response(JSON.stringify({ error: "Sunucu hatası: İşlem sırasında bir sorun oluştu." }), {
                    status: 500, headers: { "Content-Type": "application/json" }
                });
                return addCorsHeaders(response);
            }
        }
        
        /**
         * ENDPOINT: Yeni Şifreyi Güncelleme (Mevcut, çalışanı korundu)
         * POST /api/update-password
         */
        if (path === "/api/update-password" && method === "POST") {
             // ... BU KISIM ESKİ KODUNUZLA AYNI KALACAK ...
             try {
                const { access_token, new_password } = await request.json();

                if (!access_token || !new_password) {
                    const response = new Response(JSON.stringify({ error: "Token ve yeni şifre gerekli" }), {
                        status: 400,
                        headers: { "Content-Type": "application/json" }
                    });
                    return addCorsHeaders(response);
                }

                // Supabase'e şifreyi güncelleme komutu gönder
                const updateRes = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
                    method: "PUT",
                    headers: {
                        "Authorization": `Bearer ${access_token}`,
                        "apikey": env.SUPABASE_ANON_KEY,
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        password: new_password
                    })
                });

                if (!updateRes.ok) {
                    const errorText = await updateRes.text();
                    let errorMessage = "Şifre güncellenirken bir hata oluştu.";
                    try {
                        const errorData = JSON.parse(errorText);
                        errorMessage = errorData.msg || errorData.error_description || errorMessage;
                    } catch (e) {
                        errorMessage = errorText;
                    }

                    const response = new Response(JSON.stringify({ error: errorMessage }), {
                        status: updateRes.status,
                        headers: { "Content-Type": "application/json" }
                    });
                    return addCorsHeaders(response);
                }

                // Başarılı Yanıt
                const response = new Response(JSON.stringify({ message: "Şifreniz başarıyla güncellendi." }), {
                    status: 200, headers: { "Content-Type": "application/json" }
                });
                return addCorsHeaders(response);

            } catch (e) {
                // JSON ayrıştırma veya fetch hatası
                const response = new Response(JSON.stringify({ error: "Sunucu hatası: İşlem sırasında bir sorun oluştu." }), {
                    status: 500,
                    headers: { "Content-Type": "application/json" }
                });
                return addCorsHeaders(response);
            }
        }

        // ====================================================================
        // 2. KİMLİK DOĞRULAMASI GEREKEN (PRIVATE) ENDPOINT'LER (Mevcut Kodunuz)
        // ====================================================================

        const authHeader = request.headers.get("Authorization");
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            const response = new Response(JSON.stringify({ error: "Unauthorized" }), { 
                status: 401, 
                headers: { "Content-Type": "application/json" } 
            });
            return addCorsHeaders(response);
        }
        const token = authHeader.substring(7);

        // Supabase'den token'ı doğrula ve kullanıcı ID'sini al
        const userRes = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
            headers: {
                "Authorization": `Bearer ${token}`,
                "apikey": env.SUPABASE_ANON_KEY
            }
        });

        if (!userRes.ok) {
            const response = new Response(JSON.stringify({ error: "Invalid token" }), { 
                status: 401, 
                headers: { "Content-Type": "application/json" } 
            });
            return addCorsHeaders(response);
        }

        const user = await userRes.json();
        const userId = user.id;

        // --- Mevcut /prefs Mantığı ---

        if (path === "/prefs/get" && method === "GET") {
            const { results } = await env.DB.prepare(
                "SELECT prefs FROM preferences WHERE user_id = ?"
            ).bind(userId).all();
            const response = new Response(results[0]?.prefs || "{}", { headers: { "Content-Type": "application/json" } });
            return addCorsHeaders(response);
        }

        if (path === "/prefs/set" && method === "POST") {
            const body = await request.json();
            await env.DB.prepare(`
                INSERT INTO preferences (user_id, prefs)
                VALUES (?, ?)
                ON CONFLICT(user_id) DO UPDATE SET prefs = excluded.prefs
            `).bind(userId, JSON.stringify(body)).run();
            const response = new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } });
            return addCorsHeaders(response);
        }
        
        // Eşleşen başka hiçbir endpoint yoksa
        const response = new Response(JSON.stringify({ error: "Not found" }), { status: 404, headers: { "Content-Type": "application/json" } });
        return addCorsHeaders(response);
    }
};
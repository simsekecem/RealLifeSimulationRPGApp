export default {
    async fetch(request, env) {
        const url = new URL(request.url);
        const path = url.pathname;
        const method = request.method;

        // Pages uygulamanızın CORS için kabul edilen URL'si
        const ALLOWED_ORIGIN = "https://life-sim.pages.dev"; 
        
        // Şifre Sıfırlama için varsayılan URL (Artık kullanılmıyor ama durabilir)
        const REDIRECT_URL_RESET = "https://life-sim.pages.dev/reset-password";
        // 🔥 YENİ: Kayıt Onayı sonrası yönlendirme URL'si
        const REDIRECT_URL_SIGNUP = "https://life-sim.pages.dev/signup-confirmed"; 
        
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
        // OPTIONS kontrolüne /api/signup endpoint'i de eklendi
        if ((path === "/api/update-password" || path === "/api/password-recover" || path === "/api/signup") && method === "OPTIONS") {
             return addCorsHeaders(new Response(null, { status: 204 }));
        }
        
        /**
         * YENİ ENDPOINT: Kullanıcı Kaydı (Sign-up)
         * POST /api/signup
         */
        if (path === "/api/signup" && method === "POST") {
            try {
                const { email, password } = await request.json();

                if (!email || !password) {
                    const response = new Response(JSON.stringify({ error: "Email ve şifre gereklidir." }), {
                        status: 400, headers: { "Content-Type": "application/json" }
                    });
                    return addCorsHeaders(response);
                }

                // Supabase /auth/v1/signup endpoint'ine isteği gönder
                const signupRes = await fetch(`${env.SUPABASE_URL}/auth/v1/signup`, {
                    method: "POST",
                    headers: {
                        "apikey": env.SUPABASE_ANON_KEY,
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        email: email,
                        password: password,
                        // Kayıt onay linki tıklandığında buraya yönlendirilir.
                        email_redirect_to: REDIRECT_URL_SIGNUP 
                    })
                });

                if (signupRes.ok || signupRes.status === 200) {
                    const response = new Response(JSON.stringify({ message: "Kayıt başarılı! Onay maili gönderildi. Lütfen e-posta kutunuzu kontrol edin." }), {
                        status: 200, headers: { "Content-Type": "application/json" }
                    });
                    return addCorsHeaders(response);
                } else {
                    const errorData = await signupRes.json();
                    const response = new Response(JSON.stringify({ error: errorData.msg || "Kayıt hatası." }), {
                        status: signupRes.status, headers: { "Content-Type": "application/json" }
                    });
                    return addCorsHeaders(response);
                }

            } catch (e) {
                const response = new Response(JSON.stringify({ error: "Sunucu hatası: Kayıt sırasında bir sorun oluştu." }), {
                    status: 500, headers: { "Content-Type": "application/json" }
                });
                return addCorsHeaders(response);
            }
        }
        
        /**
         * ENDPOINT: Şifre Sıfırlama Mailini Gönderme
         * POST /api/password-recover
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
                        // Şifre sıfırlama için artık redirect_to kullanılmıyor.
                    })
                });

                if (recoverRes.ok || recoverRes.status === 200) {
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
         * ENDPOINT: Yeni Şifreyi Güncelleme
         * POST /api/update-password
         */
        if (path === "/api/update-password" && method === "POST") {
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
                 const response = new Response(JSON.stringify({ error: "Sunucu hatası: İşlem sırasında bir sorun oluştu." }), {
                     status: 500,
                     headers: { "Content-Type": "application/json" }
                 });
                 return addCorsHeaders(response);
             }
        }

        // ====================================================================
        // 2. KİMLİK DOĞRULAMASI GEREKEN (PRIVATE) ENDPOINT'LER
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

        // --- Preferences (Tercihler) Mantığı --- 🔥 GERİ EKLENDİ!

        if (path === "/prefs/get" && method === "GET") {
            const { results } = await env.DB.prepare(
                "SELECT prefs FROM preferences WHERE user_id = ?"
            ).bind(userId).all();
            const response = new Response(results[0]?.prefs || "{}", { headers: { "Content-Type": "application/json" } });
            return addCorsHeaders(response);
        }

        if (path === "/prefs/set" && method === "POST") {
            const body = await request.json();
            // JSON verisini stringify yapıp veritabanına kaydet
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
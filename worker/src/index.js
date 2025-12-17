export default {
    async fetch(request, env) {
        const url = new URL(request.url);
        const path = url.pathname;
        const method = request.method;

        // Mobil APK + itch.io + browser hepsinde çalışsın diye wildcard yerine dinamik origin
        const origin = request.headers.get("Origin") || "*";

        const addCors = (response) => {
            response.headers.set("Access-Control-Allow-Origin", origin);
            response.headers.set("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS");
            response.headers.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
            response.headers.set("Access-Control-Allow-Credentials", "true");
            return response;
        };

        // Preflight
        if (method === "OPTIONS") {
            return addCors(new Response(null, { status: 204 }));
        }

        // =====================================================
        // PUBLIC ENDPOINTS
        // =====================================================

        // ---------- SIGNUP ----------
        if (path === "/api/signup" && method === "POST") {
            const body = await request.json();
            const res = await fetch(`${env.SUPABASE_URL}/auth/v1/signup`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "apikey": env.SUPABASE_ANON_KEY,
                },
                body: JSON.stringify({
                    email: body.email,
                    password: body.password,
                    email_redirect_to: "https://web.life-simulation.workers.dev/signup-confirmed",
                }),
            });

            return addCors(new Response(await res.text(), { status: res.status }));
        }
        // ---------- LOGIN ----------
        if (path === "/api/login" && method === "POST") {
            const body = await request.json();
            const res = await fetch(`${env.SUPABASE_URL}/auth/v1/token?grant_type=password`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "apikey": env.SUPABASE_ANON_KEY,
                },
                body: JSON.stringify({
                    email: body.email,
                    password: body.password,
                }),
            });
            return addCors(new Response(await res.text(), { status: res.status }));
        }


        // ---------- PASSWORD RECOVER ----------
        if (path === "/api/password-recover" && method === "POST") {
            const body = await request.json();
            const res = await fetch(`${env.SUPABASE_URL}/auth/v1/recover`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "apikey": env.SUPABASE_ANON_KEY,
                },
                body: JSON.stringify({ email: body.email }),
            });

            return addCors(new Response(await res.text(), { status: res.status }));
        }

        // ---------- UPDATE PASSWORD ----------
        if (path === "/api/update-password" && method === "POST") {
            const body = await request.json();
            const res = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
                method: "PUT",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${body.access_token}`,
                    "apikey": env.SUPABASE_ANON_KEY,
                },
                body: JSON.stringify({ password: body.new_password }),
            });

            return addCors(new Response(await res.text(), { status: res.status }));
        }

        // ---------- AI CHAT (GYM COACH) ----------
       // ---------- AI CHAT (GYM COACH) ----------
        if (path === "/api/ai_chat" && method === "POST") {
            try {
                const body = await request.json();
                const userMessage = body.message;
                const userContext = body.context || "Veri yok.";
                const userName = body.user_name || "Sporcu";

                // Gemini'ye Gönderilecek İngilizce System Prompt
                const systemPrompt = `
                    You are a personal trainer, a professional, friendly, and data-driven personal trainer.
                    
                    USER PROFILE:
                    Name: ${userName}
                    
                    TRAINING HISTORY (JSON Context):
                    ${JSON.stringify(userContext)}
                    
                    INSTRUCTIONS:
                    1. Analyze the user's training history provided in the JSON context to answer their question.
                    2. BE DATA-DRIVEN: Compare past lifts with current ones. Mention specific numbers (e.g., "You increased your Bench Press weight by 10kg since last week!").
                    3. If the history shows a gap in training, be encouraging and motivate them to get back on track.
                    4. If the data is empty or irrelevant to the question, provide expert general fitness advice.
                    5. TONE: Energetic, supportive, concise (short paragraphs), and use emojis.
                    
                    ⚠️ LANGUAGE CONSTRAINT (CRITICAL):
                    Detect the language of the "${userMessage}". YOU MUST RESPOND IN THE EXACT SAME LANGUAGE as the user's message.
                    (e.g., If the user asks in Turkish, reply in Turkish. If English, reply in English).

                    USER QUESTION: "${userMessage}"
                `;

                const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${env.GEMINI_API_KEY}`;
                
                const response = await fetch(geminiUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        contents: [{ parts: [{ text: systemPrompt }] }]
                    })
                });

                const data = await response.json();
                
                // 👇 DEBUG: Varsayılan mesaj yerine hatayı görelim
                let replyText = "Couldn't understand. Please ask again.";

                // EĞER GEMINI HATA DÖNDÜRDÜYSE ONU YAZDIR
                if (data.error) {
                    replyText = "ERROR: " + data.error.message;
                } 
                // EĞER BAŞARILIYSA CEVABI AL
                else if (data.candidates && data.candidates.length > 0) {
                    replyText = data.candidates[0].content.parts[0].text;
                }

                return addCors(new Response(JSON.stringify({ reply: replyText }), { status: 200 }));

            } catch (err) {
                // Kod patlarsa hatayı görelim
                return addCors(new Response(JSON.stringify({ reply: "SERVER ERROR: " + err.message }), { status: 200 }));
            }
        }

        // =====================================================
        // AUTH CHECK (Protected Routes)
        // =====================================================

        const authHeader = request.headers.get("Authorization");
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
            return addCors(new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 }));
        }

        const token = authHeader.slice(7);

        // Validate token
        const userRes = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
            headers: {
                "Authorization": `Bearer ${token}`,
                "apikey": env.SUPABASE_ANON_KEY
            }
        });

        if (!userRes.ok) {
            return addCors(new Response(JSON.stringify({ error: "Invalid token" }), { status: 401 }));
        }

        const user = await userRes.json();
        const userId = user.id;

        // =====================================================
        // LOAD ALL DATA
        // =====================================================
        if (path === "/api/load_all" && method === "GET") {

            const result = {
                user: await env.DB.prepare(`SELECT name, birthdate, level, experience, character_id FROM users WHERE user_id=?`)
                    .bind(userId).first(),

                // Preferences satırını buradan kaldırdık. 
                // Artık cihazlar arası ses senkronizasyonu yok.

                library: await env.DB.prepare(`SELECT title, status FROM library_books WHERE user_id=?`)
                    .bind(userId).all(),

                study_log: await env.DB.prepare(`SELECT date, start_time, end_time, subject FROM study_log WHERE user_id=?`)
                    .bind(userId).all(),

                gym_log: await env.DB.prepare(`SELECT id, date, exercise_name, sets, reps, duration, rest, weight, region, completed 
                                  FROM gym_log WHERE user_id=?`)
                    .bind(userId).all(),

                market_items: await env.DB.prepare(`SELECT id, category, item_name, planned, bought, date
                                                      FROM market_items WHERE user_id=?`)
                    .bind(userId).all(),

                restaurant: await env.DB.prepare(`SELECT date, breakfast, lunch, dinner, snacks, notes
                                                    FROM restaurant_log WHERE user_id=?`)
                    .bind(userId).all(),

                calendar_notes: await env.DB.prepare(`SELECT date, note FROM calendar_notes WHERE user_id=?`)
                    .bind(userId).all()
            };

            return addCors(new Response(JSON.stringify(result), { status: 200 }));
        }

        // =====================================================
        // SAVE ALL (TYPE SAFE & CRASH PROOF VERSION)
        // =====================================================
        if (path === "/api/save_all" && method === "POST") {
            try {
                const body = await request.json();

                async function insertOrUpdate(insertQ, insertParams, updateQ, updateParams) {
                    try {
                        await env.DB.prepare(insertQ).bind(...insertParams).run();
                    } catch (e) {
                        await env.DB.prepare(updateQ).bind(...updateParams).run();
                    }
                }

                const safeList = (data) => Array.isArray(data) ? data : [];

                // 1. USER
                // 1. USER (Level, XP ve Karakter ID Eklendi)
                // 1. USER (İsim Varsayılanı DB Tarafından Kontrol Ediliyor)
                const userBox = body.user || {}; 
                const userName = userBox.name || ""; 
                const userBirth = userBox.birthdate || "";
                const userLevel = userBox.level || 1;
                const userExp = userBox.experience || 0;
                const charId = userBox.character_id || 1;

                // 👇 YENİ: İsim boşsa DB'ye "Çaylak" olarak yazılmasını garantile
                const finalUserName = userName === "" ? "Rookie" : userName;

                await insertOrUpdate(
                    // INSERT: İlk kayıt yapılırken finalUserName kullanılır
                    `INSERT INTO users (user_id, name, birthdate, level, experience, character_id) VALUES (?, ?, ?, ?, ?, ?)`,
                    [userId, finalUserName, userBirth, userLevel, userExp, charId],
                    // UPDATE: Zaten kayıtlıysa güncel isim kullanılır
                    `UPDATE users SET name=?, birthdate=?, level=?, experience=?, character_id=? WHERE user_id=?`,
                    [finalUserName, userBirth, userLevel, userExp, charId, userId]
                );

                // 2. PREFERENCES (KALDIRILDI)
                // Artık sunucuya kaydedilmiyor.

                // 3. LIBRARY
                if (body.library !== undefined) {
                    const library = safeList(body.library);
                    
                    // A) Önce eski listeyi tamamen temizle (En temiz senkronizasyon)
                    await env.DB.prepare(`DELETE FROM library_books WHERE user_id=?`).bind(userId).run();

                    // B) Listeyi olduğu gibi (boşluklar dahil) kaydet
                    for (const b of library) {
                        // 👇 DEĞİŞİKLİK: 'if' kontrolünü kaldırdık. 
                        // Başlık boş olsa bile ('') veritabanına kaydediyoruz.
                         await env.DB.prepare(`INSERT INTO library_books (user_id, title, status) VALUES (?, ?, ?)`)
                            .bind(userId, b.title || "", b.status).run();
                    }
                }

                // 4. STUDY LOG
                const study_log = safeList(body.study_log);
                for (const s of study_log) {
                    await insertOrUpdate(
                        `INSERT INTO study_log (user_id, date, start_time, end_time, subject) VALUES (?, ?, ?, ?, ?)`,
                        [userId, s.date, s.start_time, s.end_time, s.subject],
                        `UPDATE study_log SET subject=? WHERE user_id=? AND date=? AND start_time=? AND end_time=?`,
                        [s.subject, userId, s.date, s.start_time, s.end_time]
                    );
                }

                // 5. GYM LOG
                // 5. GYM LOG (GÜNCELLENDİ: CRASH-PROOF & ID DESTEKLİ)
                const gym_log = safeList(body.gym_log);
                for (const g of gym_log) {
                    
                    // ---------------------------------------------------------
                    // 1. ADIM: SİLME KONTROLÜ (İsim Boşsa + ID Varsa -> SİL)
                    // ---------------------------------------------------------
                    if (g.id && (!g.exercise_name || g.exercise_name.trim() === "")) {
                        await env.DB.prepare(`DELETE FROM gym_log WHERE id=? AND user_id=?`)
                            .bind(g.id, userId).run();
                        continue;
                    }

                    // ---------------------------------------------------------
                    // 2. ADIM: KAYDETME / GÜNCELLEME
                    // ---------------------------------------------------------
                    
                    // A) GÜNCELLEME (ID VARSA)
                    if (g.id) {
                        try {
                            // Var olan ID'yi güncellemeye çalış
                            await env.DB.prepare(`
                                UPDATE gym_log 
                                SET date=?, exercise_name=?, sets=?, reps=?, duration=?, rest=?, weight=?, region=?, completed=? 
                                WHERE id=? AND user_id=?
                            `).bind(g.date, g.exercise_name, g.sets, g.reps, g.duration, g.rest, g.weight, g.region, g.completed, g.id, userId).run();
                        } catch (e) {
                            // HATA: Eğer ismini değiştirdin ve o tarihte o isimde zaten başka kayıt varsa (Çakışma)
                            // Eskisini sil (Merge mantığı: yenisi kalsın, eskisi gitsin)
                            await env.DB.prepare(`DELETE FROM gym_log WHERE id=?`).bind(g.id).run();
                        }
                    }
                    
                    // B) EKLEME (ID YOKSA)
                    else {
                        // İsimsiz yeni kayıtları engelle
                        if (!g.exercise_name || g.exercise_name.trim() === "") continue;

                        try {
                            // Yeni eklemeyi dene
                            await env.DB.prepare(`
                                INSERT INTO gym_log (user_id, date, exercise_name, sets, reps, duration, rest, weight, region, completed) 
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                            `).bind(userId, g.date, g.exercise_name, g.sets, g.reps, g.duration, g.rest, g.weight, g.region, g.completed).run();
                        } catch (e) {
                            // HATA: Eğer "Zaten var" derse, var olan kaydı güncelle
                            // (Örneğin kullanıcı aynı gün tekrar 'Push Up' eklemiş ama ID'si yok)
                            await env.DB.prepare(`
                                UPDATE gym_log 
                                SET sets=?, reps=?, duration=?, rest=?, weight=?, region=?, completed=? 
                                WHERE user_id=? AND date=? AND exercise_name=?
                            `).bind(g.sets, g.reps, g.duration, g.rest, g.weight, g.region, g.completed, userId, g.date, g.exercise_name).run();
                        }
                    }
                }

                // 6. MARKET ITEMS
                const market_items = safeList(body.market_items);
                for (const m of market_items) {
                    
                    // ---------------------------------------------------------
                    // 1. ADIM: İSİM KONTROLÜ (BOŞSA YOK ET!)
                    // ---------------------------------------------------------
                    // Eğer isim yoksa veya boşluksa...
                    if (!m.item_name || m.item_name.trim() === "") {
                        // ...ve bu eski bir kayıtsa (ID'si varsa)
                        if (m.id) {
                            // Veritabanından silip atıyoruz.
                            await env.DB.prepare(`DELETE FROM market_items WHERE id=? AND user_id=?`)
                                .bind(m.id, userId).run();
                        }
                        // İster yeni olsun ister eski, işlem burada biter.
                        // Aşağıdaki koda inip "boş isimle kaydetmeye" çalışmasına izin vermiyoruz!
                        continue; 
                    }

                    // ---------------------------------------------------------
                    // 2. ADIM: DOLU İSİMLERİ KAYDET
                    // ---------------------------------------------------------
                    
                    // A) GÜNCELLEME (ID VARSA)
                    if (m.id) {
                        try {
                            await env.DB.prepare(`
                                UPDATE market_items 
                                SET category=?, item_name=?, planned=?, bought=?, date=? 
                                WHERE id=? AND user_id=?
                            `).bind(m.category, m.item_name, m.planned, m.bought, m.date, m.id, userId).run();
                        } catch (e) {
                            // Eğer isim değiştirdin ve o isimde başka ürün varsa (Çakışma),
                            // Eskisini sil ki çakışma olmasın.
                            await env.DB.prepare(`DELETE FROM market_items WHERE id=?`).bind(m.id).run();
                        }
                    } 
                    
                    // B) EKLEME (ID YOKSA)
                    else {
                        try {
                            await env.DB.prepare(`
                                INSERT INTO market_items (user_id, category, item_name, planned, bought, date) 
                                VALUES (?, ?, ?, ?, ?, ?)
                            `).bind(userId, m.category, m.item_name, m.planned, m.bought, m.date).run();
                        } catch (e) {
                            // Zaten varsa özelliklerini güncelle
                            await env.DB.prepare(`
                                UPDATE market_items 
                                SET planned=?, bought=?, date=? 
                                WHERE user_id=? AND category=? AND item_name=?
                            `).bind(m.planned, m.bought, m.date, userId, m.category, m.item_name).run();
                        }
                    }
                }

                // 7. RESTAURANT LOG
                const restaurant = safeList(body.restaurant);
                for (const r of restaurant) {
                    await insertOrUpdate(
                        `INSERT INTO restaurant_log (user_id, date, breakfast, lunch, dinner, snacks, notes) VALUES (?, ?, ?, ?, ?, ?, ?)`,
                        [userId, r.date, r.breakfast, r.lunch, r.dinner, r.snacks, r.notes],
                        `UPDATE restaurant_log SET breakfast=?, lunch=?, dinner=?, snacks=?, notes=? WHERE user_id=? AND date=?`,
                        [r.breakfast, r.lunch, r.dinner, r.snacks, r.notes, userId, r.date]
                    );
                }

                // 8. CALENDAR NOTES
                // 8. CALENDAR NOTES (GÜNCELLENDİ: Boş Notları Korur & Çift Kaydı Önler)
                const calendar_notes = safeList(body.calendar_notes);
                for (const c of calendar_notes) {
                    // Not içeriği undefined ise boş string yap ama null yapma
                    const noteContent = (c.note === undefined || c.note === null) ? "" : c.note;

                    // 1. Önce var olan tarihi güncellemeyi dene
                    const updateRes = await env.DB.prepare(`UPDATE calendar_notes SET note=? WHERE user_id=? AND date=?`)
                        .bind(noteContent, userId, c.date).run();
                    
                    // 2. Eğer güncellenecek satır yoksa (yani o tarih ilk kez geliyorsa) yeni ekle
                    if (updateRes.meta.changes === 0) {
                         await env.DB.prepare(`INSERT INTO calendar_notes (user_id, date, note) VALUES (?, ?, ?)`)
                            .bind(userId, c.date, noteContent).run();
                    }
                }

                return addCors(new Response(JSON.stringify({ ok: true }), { status: 200 }));

            } catch (err) {
                return addCors(new Response(JSON.stringify({ error: err.message, stack: err.stack }), { status: 500 }));
            }
        }

        // Not found
        return addCors(new Response(JSON.stringify({ error: "Not Found" }), { status: 404 }));
    }
};
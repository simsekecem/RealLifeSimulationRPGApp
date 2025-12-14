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
                    email_redirect_to: "https://life-sim.pages.dev/signup-confirmed",
                }),
            });

            return addCors(new Response(await res.text(), { status: res.status }));
        }
        // ---------- LOGIN ----------
        if (path === "/api/login" && method === "POST") {
            const body = await request.json();
            
            // Supabase'e giriş isteği atıyoruz (Email + Şifre ile)
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

            // Supabase'den gelen cevabı (Token'ı) Godot'ya iletiyoruz
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
                user: await env.DB.prepare(`SELECT name, birthdate FROM users WHERE user_id=?`)
                    .bind(userId).first(),

                preferences: await env.DB.prepare(`SELECT music_volume FROM user_preferences WHERE user_id=?`)
                    .bind(userId).first(),

                library: await env.DB.prepare(`SELECT title, status FROM library_books WHERE user_id=?`)
                    .bind(userId).all(),

                study_log: await env.DB.prepare(`SELECT date, start_time, end_time, subject FROM study_log WHERE user_id=?`)
                    .bind(userId).all(),

                gym_log: await env.DB.prepare(`SELECT date, exercise_name, sets, reps, duration, rest, weight, region, completed 
                                                  FROM gym_log WHERE user_id=?`)
                    .bind(userId).all(),

                market_items: await env.DB.prepare(`SELECT category, item_name, planned, bought, date
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

                // --- HELPER: Gelen veri kesinlikle Array olsun ---
                // Eğer "null" gelirse veya yanlışlıkla "{}" (Object) gelirse boş dizi [] yap.
                const safeList = (data) => Array.isArray(data) ? data : [];

                // 1. USER
                const userBox = body.user || {}; 
                const userName = userBox.name || ""; 
                const userBirth = userBox.birthdate || "";

                await insertOrUpdate(
                    `INSERT INTO users (user_id, name, birthdate) VALUES (?, ?, ?)`,
                    [userId, userName, userBirth],
                    `UPDATE users SET name=?, birthdate=? WHERE user_id=?`,
                    [userName, userBirth, userId]
                );

                // 2. PREFERENCES
                const prefsBox = body.preferences || {};
                await insertOrUpdate(
                    `INSERT INTO user_preferences (user_id, music_volume) VALUES (?, ?)`,
                    [userId, prefsBox.music_volume || 50],
                    `UPDATE user_preferences SET music_volume=? WHERE user_id=?`,
                    [prefsBox.music_volume || 50, userId]
                );

                // 3. LIBRARY (HATA BURADAYDI -> DÜZELTİLDİ)
                const library = safeList(body.library);
                for (const b of library) {
                    await insertOrUpdate(
                        `INSERT INTO library_books (user_id, title, status) VALUES (?, ?, ?)`,
                        [userId, b.title, b.status],
                        `UPDATE library_books SET status=? WHERE user_id=? AND title=?`,
                        [b.status, userId, b.title]
                    );
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
                const gym_log = safeList(body.gym_log);
                for (const g of gym_log) {
                    await insertOrUpdate(
                        `INSERT INTO gym_log (user_id, date, exercise_name, sets, reps, duration, rest, weight, region, completed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                        [userId, g.date, g.exercise_name, g.sets, g.reps, g.duration, g.rest, g.weight, g.region, g.completed],
                        `UPDATE gym_log SET sets=?, reps=?, duration=?, rest=?, weight=?, region=?, completed=? WHERE user_id=? AND date=? AND exercise_name=?`,
                        [g.sets, g.reps, g.duration, g.rest, g.weight, g.region, g.completed, userId, g.date, g.exercise_name]
                    );
                }

                // 6. MARKET ITEMS
                const market_items = safeList(body.market_items);
                for (const m of market_items) {
                    await insertOrUpdate(
                        `INSERT INTO market_items (user_id, category, item_name, planned, bought, date) VALUES (?, ?, ?, ?, ?, ?)`,
                        [userId, m.category, m.item_name, m.planned, m.bought, m.date],
                        `UPDATE market_items SET planned=?, bought=?, date=? WHERE user_id=? AND category=? AND item_name=?`,
                        [m.planned, m.bought, m.date, userId, m.category, m.item_name]
                    );
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
                const calendar_notes = safeList(body.calendar_notes);
                for (const c of calendar_notes) {
                    await insertOrUpdate(
                        `INSERT INTO calendar_notes (user_id, date, note) VALUES (?, ?, ?)`,
                        [userId, c.date, c.note],
                        `UPDATE calendar_notes SET note=? WHERE user_id=? AND date=?`,
                        [c.note, userId, c.date]
                    );
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

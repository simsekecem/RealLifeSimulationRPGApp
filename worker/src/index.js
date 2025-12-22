export default {
    async fetch(request, env) {
        const toInt = (v) => Number.isFinite(Number(v)) ? Number(v) : 0;
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
// ---------- GÜNLÜK GÖREV ÜRET (GEMINI AI) ----------
		if (path === "/api/daily_quests" && method === "POST") {
			try {
				const prompt = `
					Generate 4 daily tasks for a life sim game in JSON format.
					NPCs/Locations: Gym, Library, Market, Restaurant.
					Language: English.
					Format: Return ONLY a JSON array like this:
					[
						{"category": "gym", "text": "Do 2 sets of bench press", "target": "gym_action"},
						{"category": "library", "text": "Study between 10-12 AM", "target": "study_action"},
						{"category": "market", "text": "Add detergent to list", "target": "market_add"},
						{"category": "restaurant", "text": "Eat eggs for breakfast", "target": "eat_action"}
					]
				`;

				const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${env.GEMINI_API_KEY}`;
				
				const response = await fetch(geminiUrl, {
					method: "POST",
					headers: { "Content-Type": "application/json" },
					body: JSON.stringify({
						contents: [{ parts: [{ text: prompt }] }]
					})
				});

				const data = await response.json();
				let generatedText = data.candidates[0].content.parts[0].text;
				generatedText = generatedText.replace(/```json/g, "").replace(/```/g, "").trim();
				
				const quests = JSON.parse(generatedText);

				const finalQuests = quests.map((q, index) => ({
					id: `daily_${Date.now()}_${index}`,
					type: "daily",
					category: q.category,
					description: q.text,
					target_action: q.target,
					xp_reward: 50,
					is_completed: false
				}));

				return addCors(new Response(JSON.stringify(finalQuests), {
					headers: { "Content-Type": "application/json" }
				}));
			} catch (err) {
				return addCors(new Response(JSON.stringify({ error: err.message }), { status: 500 }));
			}
		}
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
                // ---------- AI CHAT (DIETITIAN - GYM STYLE) ----------
        if (path === "/api/ai_diet" && method === "POST") {
            try {
                const body = await request.json();
                const userMessage = body.message; // Kullanıcının sorusu
                const userContext = body.context; // Godot'tan gelen Globals.cache listesi
                const userName = body.user_name || "Gurme";

                const systemPrompt = `
                    You are a professional nutritionist in a life simulation game.
                    
                    USER PROFILE:
                    Name: ${userName}
                    
                    MEAL DATA FROM GAME (Context):
                    ${JSON.stringify(userContext)}
                    
                    INSTRUCTIONS:
                    1. Use the provided "Meal Data" to analyze the user's habits.
                    2. If the user asks about their diet, reference their specific logs.
                    3. Be supportive, knowledgeable, and professional. 
                    4. Use food emojis (🥗, 🥑, 🍎).
                    
                    ⚠️ LANGUAGE CONSTRAINT:
                    Respond in the SAME LANGUAGE as the user's message: "${userMessage}".
                `;

                const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${env.GEMINI_API_KEY}`;
                
                const response = await fetch(geminiUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        contents: [{ parts: [{ text: systemPrompt + `\n\nUSER: ${userMessage}` }] }]
                    })
                });

                const data = await response.json();
                const replyText = data.candidates?.[0]?.content?.parts?.[0]?.text || "Couldn't understand. Please ask again.";

                return addCors(new Response(JSON.stringify({ reply: replyText }), { status: 200 }));

            } catch (err) {
                return addCors(new Response(JSON.stringify({ reply: "Error: " + err.message }), { status: 200 }));
            }
        }
                // ---------- AI CHAT (LIBRARIAN & STUDY COACH) ----------
        if (path === "/api/ai_library" && method === "POST") {
            try {
                const body = await request.json();
                const userMessage = body.message;
                const libraryContext = body.context; // Kitap listesi (Still Reading, Completed vb.)
                const studySchedule = body.study_schedule; // Yeni: Haftalık ders saatleri verisi
                const userName = body.user_name || "Kitap Kurdu";

                const systemPrompt = `
                    You are a wise Librarian and an expert Study Coach in a life simulation game.
                    
                    USER PROFILE:
                    Name: ${userName}
                    
                    USER'S LIBRARY (Books):
                    ${JSON.stringify(libraryContext)}
                    
                    WEEKLY STUDY SCHEDULE (Lessons & Hours):
                    ${JSON.stringify(studySchedule)}
                    
                    INSTRUCTIONS:
                    1. BOOK ADVISOR: Analyze the books. Encourage finishing 'Reading' books and suggest new ones based on 'Completed' titles.
                    2. STUDY COACH (CRITICAL): Analyze the study schedule. 
                    - If they are missing study sessions or have very few hours, motivate them firmly but kindly.
                    - Mention specific hours (e.g., "I see you have a gap between 10:00-12:00, why not study then?").
                    - Act as a mentor who wants them to reach their academic goals.
                    3. TONE: Sophisticated, intellectual, encouraging, and slightly disciplined (like a mentor).
                    4. EMOJIS: 📖, 📚, ✍️, 🎓, ⏳, 💡.
                    
                    ⚠️ LANGUAGE CONSTRAINT:
                    Respond in the SAME LANGUAGE as the user's message: "${userMessage}".
                `;

                const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${env.GEMINI_API_KEY}`;
                
                const response = await fetch(geminiUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        contents: [{ parts: [{ text: systemPrompt + `\n\nUSER QUESTION: ${userMessage}` }] }]
                    })
                });

                const data = await response.json();
                const replyText = data.candidates?.[0]?.content?.parts?.[0]?.text || "Couldn't understand. Please ask again.";

                return addCors(new Response(JSON.stringify({ reply: replyText }), { status: 200 }));

            } catch (err) {
                return addCors(new Response(JSON.stringify({ reply: "Error: " + err.message }), { status: 200 }));
            }
        }

        // ---------- AI OUTFIT GENERATOR (GEMINI) ----------
        if (path === "/api/generate_outfit" && method === "POST") {
            try {
                const body = await request.json();
                const wardrobe = body.wardrobe || [];
                const context = body.context || "daily casual"; // Kullanıcıdan "Düğün", "Spor" vb. de alabiliriz ilerde

                if (wardrobe.length < 2) {
                    return addCors(new Response(JSON.stringify({ error: "Not enough items" }), { status: 400 }));
                }

                // Gemini için sadeleştirilmiş liste (Sadece isim, renk ve ID gönderiyoruz, resim URL'ine gerek yok)
                const simplifiedList = wardrobe.map(item => ({
                    id: item.id,
                    name: item.item_name,
                    category: item.category,
                    color: item.color
                }));

                const systemPrompt = `
                    You are a world-class fashion stylist.
                    
                    TASK: Create a stylish outfit from the provided list of clothes for a "${context}" occasion.
                    
                    RULES:
                    1. Select 1 Top + 1 Bottom (OR 1 Dress) + 1 Shoes + (Optional) Outerwear.
                    2. Return ONLY valid JSON. No markdown, no extra text.
                    3. JSON Format:
                    {
                        "selected_ids": [12, 45, 99],
                        "explanation": "I chose the white shirt to contrast with..."
                    }
                    4. "explanation" should be short, friendly, and use emojis. Language: English.
                    
                    WARDROBE LIST:
                    ${JSON.stringify(simplifiedList)}
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
                let rawText = data.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
                
                // Gemini bazen ```json ... ``` içinde döndürür, temizleyelim
                rawText = rawText.replace(/```json/g, "").replace(/```/g, "").trim();
                
                const result = JSON.parse(rawText);

                return addCors(new Response(JSON.stringify(result), { status: 200 }));

            } catch (err) {
                return addCors(new Response(JSON.stringify({ error: err.message }), { status: 500 }));
            }
        }



// ---------- CLOTHING CLASSIFICATION (ViT MODEL - DOĞRU ROUTER URL) ----------
if (path === "/api/classify_clothing_vit" && method === "POST") {
	try {
		const { image } = await request.json();
		if (!image || typeof image !== "string") {
			return addCors(new Response(JSON.stringify({
				is_valid: false,
				reason: "Missing image"
			}), { status: 200 }));
		}

		const imageBase64 = image.startsWith("data:")
			? image.split(",")[1]
			: image;

		const binary = atob(imageBase64);
		const bytes = new Uint8Array(binary.length);
		for (let i = 0; i < binary.length; i++) {
			bytes[i] = binary.charCodeAt(i);
		}

		const aiResponse = await env.AI.run("@cf/microsoft/resnet-50", {
			image: [...bytes]
		});

		if (!Array.isArray(aiResponse) || aiResponse.length === 0) {
			return addCors(new Response(JSON.stringify({
				is_valid: false,
				reason: "No predictions"
			}), { status: 200 }));
		}

		const top = aiResponse[0];
		const label = top.label.toLowerCase();
		const confidence = Number(top.score.toFixed(4));

		// ❌ Çok düşük confidence direkt elensin
		if (confidence < 0.45) {
			return addCors(new Response(JSON.stringify({
				is_valid: false,
				reason: "Low confidence",
				confidence
			}), { status: 200 }));
		}

		/* --------------------------------------------------
		   👕 KIYAFET ANAHTAR KELİMELERİ (GENİŞLETİLDİ)
		-------------------------------------------------- */
		const clothingKeywords = [
			// upper
			"shirt", "t-shirt", "tshirt", "top", "blouse",
			"sweater", "hoodie", "sweatshirt", "suit",

			// lower
			"jean", "pants", "trousers", "shorts",
			"skirt", "legging",

			// dress
			"dress", "gown",

			// outer
			"jacket", "coat", "blazer", "parka",
			"overcoat", "windbreaker",

			// shoes
			"shoe", "sneaker", "boot", "sandal",
			"heel", "slipper"
		];

		const isClothing = clothingKeywords.some(k => label.includes(k));

		if (!isClothing) {
			return addCors(new Response(JSON.stringify({
				is_valid: false,
				reason: "Not a clothing item",
				item_name: top.label,
				confidence
			}), { status: 200 }));
		}

		/* --------------------------------------------------
		   📦 CATEGORY MAP (SENİN SİSTEMİN)
		   outer | dress | upper | lower | shoes
		-------------------------------------------------- */
		let category = "upper";

		if (
			label.includes("jacket") ||
			label.includes("coat") ||
			label.includes("blazer") ||
			label.includes("parka") ||
			label.includes("overcoat") ||
			label.includes("windbreaker")
		) category = "outer";

		else if (label.includes("dress") || label.includes("gown"))
			category = "dress";

		else if (
			label.includes("pants") ||
			label.includes("jean") ||
			label.includes("trousers") ||
			label.includes("shorts") ||
			label.includes("skirt") ||
			label.includes("legging")
		) category = "lower";

		else if (
			label.includes("shoe") ||
			label.includes("sneaker") ||
			label.includes("boot") ||
			label.includes("sandal") ||
			label.includes("heel") ||
			label.includes("slipper")
		) category = "shoes";

		return addCors(new Response(JSON.stringify({
			is_valid: true,
			item_name: top.label,   // örn: "running shoe", "jacket"
			category,               // outer / dress / upper / lower / shoes
			confidence,
			raw_predictions: aiResponse.slice(0, 5)
		}), { status: 200 }));

	} catch (err) {
		console.error("AI ERROR:", err);
		return addCors(new Response(JSON.stringify({
			is_valid: false,
			error: "AI_ERROR",
			message: err.message
		}), { status: 500 }));
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

        if (path === "/api/delete_item" && method === "POST") {
            try {
                const body = await request.json();
                const imageUrl = body.image_url;
                
                if (!imageUrl) return addCors(new Response(JSON.stringify({ error: "No image URL" }), { status: 400 }));

                // 1. D1'den Sil (GÜVENLİK GÜNCELLEMESİ: Sadece user_id eşleşirse sil!)
                const result = await env.DB.prepare("DELETE FROM wardrobe WHERE user_id=? AND image_url=?")
                    .bind(userId, imageUrl).run();

                // Eğer veritabanından bir şey silinmediyse, demek ki o resim bu kullanıcının değil!
                if (result.meta.changes === 0) {
                     // Supabase'e gitmeye gerek yok, çünkü yetkisi yok.
                     return addCors(new Response(JSON.stringify({ success: true, note: "Item not found or not yours" }), { status: 200 }));
                }

                // 2. Supabase'den Sil
                const fileName = imageUrl.split("/wardrobe/").pop(); 
                if (fileName) {
                    await fetch(`${env.SUPABASE_URL}/storage/v1/object/wardrobe/${fileName}`, {
                        method: "DELETE",
                        headers: { 
                            "Authorization": `Bearer ${env.SUPABASE_ANON_KEY}`, 
                            "apikey": env.SUPABASE_ANON_KEY 
                        }
                    });
                }

                return addCors(new Response(JSON.stringify({ success: true }), { status: 200 }));
            } catch (err) {
                return addCors(new Response(JSON.stringify({ error: err.message }), { status: 500 }));
            }
        }

        // =====================================================
        // LOAD ALL DATA
        // =====================================================
        if (path === "/api/load_all" && method === "GET") {

            const result = {
                user: await env.DB.prepare(`SELECT name, birthdate, level, experience, character_id FROM users WHERE user_id=?`)
                    .bind(userId).first(),

                wardrobe: await env.DB.prepare(`SELECT id, category, item_name, color, image_url, is_favorite FROM wardrobe WHERE user_id=?`).bind(userId).all(),

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
                const fcmToken = userBox.fcm_token || null;

                // 👇 YENİ: İsim boşsa DB'ye "Çaylak" olarak yazılmasını garantile
                const finalUserName = userName === "" ? "Rookie" : userName;

                await insertOrUpdate(
                    `INSERT INTO users (user_id, name, birthdate, level, experience, character_id, fcm_token) VALUES (?, ?, ?, ?, ?, ?, ?)`,
                    [userId, finalUserName, userBirth, userLevel, userExp, charId, fcmToken],
                    // UPDATE: fcm_token sütununu güncelliyoruz
                    `UPDATE users SET name=?, birthdate=?, level=?, experience=?, character_id=?, fcm_token=? WHERE user_id=?`,
                    [finalUserName, userBirth, userLevel, userExp, charId, fcmToken, userId]
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
                // =====================================================
                // 5. GYM LOG (TAM EŞLEŞME KONTROLLÜ & COMPLETED HARİÇ)
                        // =====================================================
                const gym_log = safeList(body.gym_log);

                for (const g of gym_log) {
                    
                    // ---------------------------------------------------------
                    // 1. ADIM: SİLME KONTROLÜ
                    // ---------------------------------------------------------
                    // Eğer ID varsa ama isim silindiyse veya boşsa, veritabanından yok et.
                    if (g.id && (!g.exercise_name || g.exercise_name.trim() === "")) {
                        await env.DB.prepare(`DELETE FROM gym_log WHERE id=? AND user_id=?`)
                            .bind(g.id, userId).run();
                        continue;
                    }

                    // İsimsiz yeni kayıtların eklenmesini engelle
                    if (!g.exercise_name || g.exercise_name.trim() === "") continue;

                    // ---------------------------------------------------------
                    // 2. ADIM: UPSERT (EKLE VEYA GÜNCELLE)
                    // ---------------------------------------------------------
                    // NOT: Bu sorgunun çalışması için D1 konsolunda şu indeksi oluşturmuş olmalısın:
                    // CREATE UNIQUE INDEX idx_gym_workout_details ON gym_log(user_id, date, exercise_name, sets, reps, weight, duration, rest, region);
                    
                    try {
                        await env.DB.prepare(`
                        INSERT INTO gym_log (
                            user_id, date, exercise_name, sets, reps, 
                            weight, duration, rest, region, completed
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ON CONFLICT(user_id, date, exercise_name, sets, reps, weight, duration, rest, region) 
                        DO UPDATE SET 
                            completed = excluded.completed
                    `).bind(
                        userId,
                        g.date,
                        g.exercise_name,
                        toInt(g.sets),
                        toInt(g.reps),
                        toInt(g.weight),
                        toInt(g.duration),
                        toInt(g.rest),
                        g.region || "",
                        g.completed ? 1 : 0
                    ).run();

                    } catch (e) {
                        console.error("Gym Log Sync Error:", e.message);
                        // Tekil bir hata tüm döngüyü bozmasın diye burada loglayıp devam ediyoruz.
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
                    // Eğer r.notes veya r.breakfast gelmezse (null/undefined ise) || "" sayesinde hata almaz, boş kaydeder.
                    const params = [
                        userId, 
                        r.date, 
                        r.breakfast || "", 
                        r.lunch || "", 
                        r.dinner || "", 
                        r.snacks || "", 
                        r.notes || ""
                    ];
                    
                    const updateParams = [
                        r.breakfast || "", 
                        r.lunch || "", 
                        r.dinner || "", 
                        r.snacks || "", 
                        r.notes || "", 
                        userId, 
                        r.date
                    ];

                    await insertOrUpdate(
                        `INSERT INTO restaurant_log (user_id, date, breakfast, lunch, dinner, snacks, notes) VALUES (?, ?, ?, ?, ?, ?, ?)`,
                        params,
                        `UPDATE restaurant_log SET breakfast=?, lunch=?, dinner=?, snacks=?, notes=? WHERE user_id=? AND date=?`,
                        updateParams
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

                const wardrobe = safeList(body.wardrobe);
                for (const w of wardrobe) {
                    if (w.id && (!w.image_url || w.image_url === "")) {
                        await env.DB.prepare(`DELETE FROM wardrobe WHERE id=? AND user_id=?`).bind(w.id, userId).run();
                        continue;
                    }
                    if (!w.image_url || w.image_url === "") continue;

                    try {
                        // CONFIDENCE EKLENDİ 🚀
                        await env.DB.prepare(`
                            INSERT INTO wardrobe (user_id, category, item_name, color, image_url, is_favorite, confidence) 
                            VALUES (?, ?, ?, ?, ?, ?, ?)
                            ON CONFLICT(user_id, image_url) 
                            DO UPDATE SET item_name=excluded.item_name, color=excluded.color, is_favorite=excluded.is_favorite, confidence=excluded.confidence
                        `).bind(
                            userId, 
                            w.category, 
                            w.item_name || "Unnamed", 
                            w.color || "Unknown", 
                            w.image_url, 
                            w.is_favorite ? 1 : 0,
                            w.confidence || 0 // Confidence değeri burada bağlanıyor
                        ).run();
                    } catch (e) {
                        console.error("Wardrobe Save Error:", e.message);
                    }
                }

                return addCors(new Response(JSON.stringify({ ok: true }), { status: 200 }));

            } catch (err) {
                return addCors(new Response(JSON.stringify({ error: err.message, stack: err.stack }), { status: 500 }));
            }
        }
        // ---------- HUGGING FACE (KORUMALI VERSİYON) ----------
    

            // Not found
            return addCors(new Response(JSON.stringify({ error: "Not Found" }), { status: 404 }));
        },

// Worker kodunun en altındaki scheduled fonksiyonunu bununla değiştir:

    async scheduled(event, env, ctx) {
        const today = new Date().toISOString().split('T')[0];
        console.log(`🕒 Global Notification Sync Started: ${today}`);

        try {
            // 1. Auth Hazırlığı
            const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
            const accessToken = await getGoogleAccessToken(serviceAccount);

            // 2. FCM Token'ı olan kullanıcıları çek
            const { results: users } = await env.DB.prepare(
                "SELECT user_id, fcm_token, name FROM users WHERE fcm_token IS NOT NULL AND fcm_token != ''"
            ).all();

            for (const user of users) {
                let summaryParts = [];

                // --- VERİ KONTROLLERİ (BOŞ SATIR FİLTRELİ) ---
                
                // A) GYM (Egzersiz adı boş değilse say)
                const gym = await env.DB.prepare(`
                    SELECT id FROM gym_log 
                    WHERE user_id=? AND date=? AND completed=0 
                    AND exercise_name IS NOT NULL AND exercise_name != ''
                `).bind(user.user_id, today).all();
                
                if (gym.results.length > 0) summaryParts.push(`🏋️ ${gym.results.length} exercises left!`);

                // B) MARKET (Ürün adı boş değilse say)
                const mkt = await env.DB.prepare(`
                    SELECT id FROM market_items 
                    WHERE user_id=? AND date=? AND bought=0 
                    AND item_name IS NOT NULL AND item_name != ''
                `).bind(user.user_id, today).all();
                
                if (mkt.results.length > 0) summaryParts.push(`🛒 ${mkt.results.length} items to buy.`);

                // C) STUDY (Konu adı boş değilse say)
                const study = await env.DB.prepare(`
                    SELECT subject FROM study_log 
                    WHERE user_id=? AND date=? 
                    AND subject IS NOT NULL AND subject != ''
                `).bind(user.user_id, today).all();
                
                if (study.results.length > 0) summaryParts.push(`📚 ${study.results.length} study sessions planned.`);

                // D) LIBRARY (Okunuyor durumu ve Kitap adı boş değilse)
                const book = await env.DB.prepare(`
                    SELECT title FROM library_books 
                    WHERE user_id=? AND status='Reading' 
                    AND title IS NOT NULL AND title != ''
                `).bind(user.user_id).first();
                
                if (book) summaryParts.push(`📖 Reading: "${book.title}"`);

                // E) NOTES (Not içeriği boş değilse)
                const note = await env.DB.prepare(`
                    SELECT note FROM calendar_notes 
                    WHERE user_id=? AND date=? 
                    AND note IS NOT NULL AND note != ''
                `).bind(user.user_id, today).first();
                
                if (note && note.note.trim() !== "") summaryParts.push(`📝 Note: "${note.note.substring(0, 15)}..."`);

                // F) RESTAURANT (Yemek planı notları veya öğünleri boş değilse)
                // Burası biraz daha detaylı çünkü 4-5 tane alan var.
                // Eğer herhangi biri doluysa "Plan Var" sayıyoruz.
                const meal = await env.DB.prepare(`
                    SELECT id FROM restaurant_log 
                    WHERE user_id=? AND date=? 
                    AND (
                        (breakfast IS NOT NULL AND breakfast != '') OR
                        (lunch IS NOT NULL AND lunch != '') OR
                        (dinner IS NOT NULL AND dinner != '') OR
                        (snacks IS NOT NULL AND snacks != '')
                    )
                `).bind(user.user_id, today).first();
                
                if (meal) summaryParts.push(`🍽️ Meal plan is ready.`);

                // --- BİLDİRİM METNİ ---
                let title = "";
                let body = "";

                if (summaryParts.length > 0) {
                    // DURUM 1: Yapılacak işler var
                    title = `Don't stop now, ${user.name || 'Champ'}! 🚀`;
                    body = "Unfinished goals for today:\n" + summaryParts.join("\n") + "\n\nLog in now to complete them!";
                } else {
                    // DURUM 2: Her şey bitti veya plan yok
                    // Boş bildirim atmamak için burayı 'return' ile geçebilirsin istersen.
                    // Ama kullanıcıyı oyuna çekmek için motivasyon atmak daha iyidir:
                    title = `Your life is waiting! ✨`;
                    body = `Hey ${user.name || 'Rookie'}, your character needs you. Log in now to plan your next move!`;
                }

                // 3. GÖNDERİM
                const fcmUrl = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
                
                const payload = {
                    "message": {
                        "token": user.fcm_token,
                        "notification": {
                            "title": title,
                            "body": body
                        },
                        "android": {
                            "priority": "high"
                        }
                    }
                };

                await fetch(fcmUrl, {
                    method: "POST",
                    headers: {
                        "Authorization": `Bearer ${accessToken}`,
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(payload)
                });
            }
        } catch (e) {
            console.error("FCM Scheduled Error:", e.message);
        }
    }
    
};

async function getGoogleAccessToken(serviceAccount) {
  // 1. JWT Header ve Payload hazırla
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;

  const payload = btoa(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: exp,
    iat: iat
  }));

  const unsignedToken = `${header}.${payload}`;

  // 2. Özel anahtarı (Private Key) temizle ve import et
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = serviceAccount.private_key
    .replace(/\\n/g, "\n")
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s+/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  // 3. Token'ı imzala
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const signedToken = `${unsignedToken}.${btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")}`;

  // 4. Google'dan gerçek Access Token'ı iste
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedToken
    })
  });

  const data = await response.json();
  return data.access_token;
}
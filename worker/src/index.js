export default {
    async fetch(request, env) {
        const toInt = (v) => Number.isFinite(Number(v)) ? Number(v) : 0;
        const url = new URL(request.url);
        const path = url.pathname;
        const method = request.method;

        // Dynamic origin instead of wildcard to support APK, itch.io, and browser environments
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
// ---------- DAILY QUEST GENERATOR (GEMINI AI) ----------
if (path === "/api/daily_quests" && method === "POST") {
    try {
        // ── API KEY ROTATION ─────────────────────────────────────────
        const apiKeys = [
            env.GEMINI_API_KEY,
            env.GEMINI_KEY_1,
            env.GEMINI_KEY_2,
            env.GEMINI_KEY_3,
            env.GEMINI_KEY_4,
            env.GEMINI_KEY_5,
            env.GEMINI_KEY_6
        ].filter(key => key && key.trim() !== ""); // filter out empty/undefined keys

        if (apiKeys.length === 0) {
            throw new Error("No valid Gemini API key found!");
        }

        // Round-robin key selection per request
        const keyIndex = Date.now() % apiKeys.length;
        const selectedKey = apiKeys[keyIndex];

        // ── PROMPT ───────────────────────────────────────────────────
        const prompt = `
            You are a quest generator for a Life Simulation Game. 
            Generate exactly 4 daily quests (one for each category: Gym, Library, Market, Restaurant).
            
            STRICT GAME LOGIC CONSTRAINTS:

            1. MARKET (Category: "market"):
               - Valid Sub-Categories: "Groceries", "Home Goods", "Clothing", "Personal Care", "Household Essentials".
               - Task Format: "Add [Item Name] to [Sub-Category] list".
               - Example: "Add Apple to Groceries list".
               - Target Action: "market_add"

            2. RESTAURANT (Category: "restaurant"):
               - Valid Meals: "Breakfast", "Lunch", "Dinner", "Snacks".
               - Task Format: "Eat [Food Name] for [Meal]".
               - Example: "Eat Toast for Breakfast".
               - Target Action: "eat_action"

            3. GYM (Category: "gym"):
               - Valid Regions: "Chest", "Back", "Legs", "Arms", "Shoulders", "Abs", "Cardio", "Full Body", "Stretching".
               - Task Format Options:
                 a) "Do [Sets] sets of [Exercise Name]"
                 b) "Do [Region/Exercise] for [Duration] mins"
                 c) "Train [Region] region"
               - Example: "Do Cardio for 20 mins" or "Train Back region".
               - Target Action: "gym_action"

            4. LIBRARY (Category: "library"):
               - Valid Time Slots: 1-hour intervals between 09:00 and 24:00 (e.g., "09:00-10:00", "15:00-16:00").
               - Task Format: "Study [Subject] between [Time Slot]".
               - Example: "Study Coding between 10:00-11:00".
               - Target Action: "study_action"

            OUTPUT FORMAT:
            Return ONLY a raw JSON array. Do not use Markdown (no \`\`\`json).
            [
                {"category": "gym", "text": "...", "target": "gym_action"},
                {"category": "library", "text": "...", "target": "study_action"},
                {"category": "market", "text": "...", "target": "market_add"},
                {"category": "restaurant", "text": "...", "target": "eat_action"}
            ]
        `;

        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${selectedKey}`;

        const response = await fetch(geminiUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }]
            })
        });

        if (!response.ok) {
            throw new Error(`Gemini API error: ${response.status} - ${await response.text().catch(() => "no details")}`);
        }

        const data = await response.json();
        
        let generatedText = data.candidates?.[0]?.content?.parts?.[0]?.text || "[]";
        generatedText = generatedText.replace(/```json/g, "").replace(/```/g, "").trim();

        let quests = [];
        try {
            quests = JSON.parse(generatedText);
        } catch (e) {
            console.error("JSON parse error, using fallback", e);
            quests = [
                {"category": "gym", "text": "Run for 15 mins", "target": "gym_action"},
                {"category": "market", "text": "Add Milk to Groceries list", "target": "market_add"},
                {"category": "restaurant", "text": "Eat Salad for Lunch", "target": "eat_action"},
                {"category": "library", "text": "Study History between 12:00-13:00", "target": "study_action"}
            ];
        }

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
        console.error("Daily quests endpoint error:", err);
        
        const status = err.message.includes("429") ? 429 : 500;
        const message = err.message.includes("429") 
            ? "Rate limit exceeded, please try again later" 
            : err.message;

        return addCors(new Response(JSON.stringify({ error: message }), { 
            status,
            headers: { "Content-Type": "application/json" }
        }));
    }
}
    // ---------- SIGNUP ----------
if (path === "/api/signup" && method === "POST") {
    try {
        const body = await request.json();
        
        // 1. Supabase Auth Signup API call (create user)
        const res = await fetch(`${env.SUPABASE_URL}/auth/v1/signup`, {
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

        const data = await res.json();

        // Error handling
        if (!res.ok) {
            let errorCode = "signup_failed";
            if (data.msg && data.msg.includes("valid email")) errorCode = "email_address_invalid";
            if (data.msg && data.msg.includes("6 characters")) errorCode = "weak_password";
            
            return addCors(new Response(JSON.stringify({ 
                error_code: errorCode, 
                msg: data.msg 
            }), { status: res.status }));
        }

        // Initialize D1 database user profile upon successful auth signup
        const newUserId = data.id || (data.user ? data.user.id : null);

        if (newUserId) {
            try {
                // Insert default user row into D1
                await env.DB.prepare(
                    `INSERT INTO users (user_id, name, birthdate, level, experience, character_id) 
                     VALUES (?, ?, ?, ?, ?, ?)`
                ).bind(
                    newUserId,      // User ID
                    "Rookie",       // Default Name
                    "2000-01-01",   // Default Birthdate
                    1,              // Level 1
                    0,              // XP 0
                    1               // Character 1
                ).run();
                
                console.log(`✅ DB profile created for user: ${newUserId}`);
            } catch (dbErr) {
                // Log silently if profile already exists
                console.error("DB profile creation error (Signup):", dbErr);
            }
        }

        return addCors(new Response(JSON.stringify(data), { status: 200 }));

    } catch (err) {
        return addCors(new Response(JSON.stringify({ error: err.message }), { status: 500 }));
    }
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
        if (path === "/api/ai_chat" && method === "POST") {
    try {
        // ── API KEY ROTATION ───────────────────────────────────────────
        const apiKeys = [
            env.GEMINI_API_KEY,
            env.GEMINI_KEY_1,
            env.GEMINI_KEY_2,
            env.GEMINI_KEY_3,
            env.GEMINI_KEY_4,
            env.GEMINI_KEY_5,
            env.GEMINI_KEY_6
        ].filter(key => key && typeof key === "string" && key.trim() !== "");

        if (apiKeys.length === 0) {
            throw new Error("No valid Gemini API key found");
        }

        // Simple round-robin key rotation
        const keyIndex = Date.now() % apiKeys.length;
        const selectedKey = apiKeys[keyIndex];

        const body = await request.json();
        const userMessage = body.message;
        const userContext = body.context || "No data.";
        const userName = body.user_name || "Athlete";

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

        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${selectedKey}`;
        
        const response = await fetch(geminiUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                contents: [{ parts: [{ text: systemPrompt }] }]
            })
        });

        const data = await response.json();
        
        let replyText = "Couldn't understand. Please ask again.";

        if (data.error) {
            replyText = "ERROR: " + data.error.message;
        } 
        else if (data.candidates && data.candidates.length > 0) {
            replyText = data.candidates[0].content.parts[0].text;
        }

        return addCors(new Response(JSON.stringify({ reply: replyText }), { status: 200 }));

    } catch (err) {
        return addCors(new Response(JSON.stringify({ reply: "SERVER ERROR: " + err.message }), { status: 200 }));
    }
}
        // ---------- AI CHAT (DIETITIAN) ----------
        if (path === "/api/ai_diet" && method === "POST") {
    try {
        // ── API KEY ROTATION ───────────────────────────────────────────
        const apiKeys = [
            env.GEMINI_API_KEY,
            env.GEMINI_KEY_1,
            env.GEMINI_KEY_2,
            env.GEMINI_KEY_3,
            env.GEMINI_KEY_4,
            env.GEMINI_KEY_5,
            env.GEMINI_KEY_6
        ].filter(key => key && typeof key === "string" && key.trim() !== "");

        if (apiKeys.length === 0) {
            throw new Error("No valid Gemini API key found");
        }

        // Simple round-robin key rotation
        const keyIndex = Date.now() % apiKeys.length;
        const selectedKey = apiKeys[keyIndex];

        const body = await request.json();
        const userMessage = body.message; // User prompt
        const userContext = body.context; // Meal cache list from client
        const userName = body.user_name || "Gourmet";

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

        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${selectedKey}`;
        
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
        // ── API KEY ROTATION ───────────────────────────────────────────
        const apiKeys = [
            env.GEMINI_API_KEY,
            env.GEMINI_KEY_1,
            env.GEMINI_KEY_2,
            env.GEMINI_KEY_3,
            env.GEMINI_KEY_4,
            env.GEMINI_KEY_5,
            env.GEMINI_KEY_6

        ].filter(key => key && typeof key === "string" && key.trim() !== "");

        if (apiKeys.length === 0) {
            throw new Error("No valid Gemini API key found");
        }

        // Simple round-robin key rotation
        const keyIndex = Date.now() % apiKeys.length;
        const selectedKey = apiKeys[keyIndex];

        const body = await request.json();
        const userMessage = body.message;
        const libraryContext = body.context; // Book list (Reading, Completed, etc.)
        const studySchedule = body.study_schedule; // Weekly study hours schedule
        const userName = body.user_name || "Bookworm";

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

        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${selectedKey}`;
        
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
        // ── API KEY ROTATION ───────────────────────────────────────────
        const apiKeys = [
            env.GEMINI_API_KEY,
            env.GEMINI_KEY_1,
            env.GEMINI_KEY_2,
            env.GEMINI_KEY_3,
            env.GEMINI_KEY_4,
            env.GEMINI_KEY_5,
            env.GEMINI_KEY_6
        ].filter(key => key && typeof key === "string" && key.trim() !== "");

        if (apiKeys.length === 0) {
            throw new Error("No valid Gemini API key found");
        }

        // Simple round-robin key rotation
        const keyIndex = Date.now() % apiKeys.length;
        const selectedKey = apiKeys[keyIndex];

        const body = await request.json();
        const wardrobe = body.wardrobe || [];
        const context = body.context || "daily casual";

        if (wardrobe.length < 2) {
            return addCors(new Response(JSON.stringify({ error: "Not enough items" }), { status: 400 }));
        }

        // Simplified list for Gemini (name, category, color, and ID)
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

        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${selectedKey}`;
        
        const response = await fetch(geminiUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                contents: [{ parts: [{ text: systemPrompt }] }]
            })
        });

        const data = await response.json();
        let rawText = data.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
        
        // Clean markdown json fences if present
        rawText = rawText.replace(/```json/g, "").replace(/```/g, "").trim();
        
        const result = JSON.parse(rawText);

        return addCors(new Response(JSON.stringify(result), { status: 200 }));

    } catch (err) {
        return addCors(new Response(JSON.stringify({ error: err.message }), { status: 500 }));
    }
}



// ---------- CLOTHING CLASSIFICATION ----------
if (path === "/api/classify_clothing_vit" && method === "POST") {
	try {
		const { image } = await request.json();

		if (!image || typeof image !== "string") {
			return addCors(new Response(JSON.stringify({
				is_valid: false,
				reason: "Missing image"
			}), { status: 200 }));
		}

		// --------------------------------------------------
		// 🖼️ Base64 → Uint8Array
		// --------------------------------------------------
		const imageBase64 = image.startsWith("data:")
			? image.split(",")[1]
			: image;

		const binary = atob(imageBase64);
		const bytes = new Uint8Array(binary.length);
		for (let i = 0; i < binary.length; i++) {
			bytes[i] = binary.charCodeAt(i);
		}

		// --------------------------------------------------
		// 🤖 AI CALL (ResNet-50)
		// --------------------------------------------------
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
		const confidence = Number(top.score.toFixed(4));

		const label = top.label
			.toLowerCase()
			.replace(/[-_]/g, " ")
			.replace(/\s+/g, " ");

		// --------------------------------------------------
		// ❌ LOW CONFIDENCE
		// --------------------------------------------------
		if (confidence < 0.45) {
			return addCors(new Response(JSON.stringify({
				is_valid: false,
				reason: "Low confidence",
				item_name: top.label,
				confidence
			}), { status: 200 }));
		}

		// --------------------------------------------------
		// 🚫 NON-CLOTHING BLACKLIST
		// --------------------------------------------------
		const nonClothingKeywords = [
			// Humans / animals
			"person", "man", "woman", "child", "baby",
			"dog", "cat", "animal",

			// Food
			"food", "pizza", "burger", "sandwich",
			"fruit", "apple", "banana",
			"drink", "coffee", "tea", "beer",

			// Household / furniture
			"chair", "sofa", "table", "desk",
			"bed", "pillow", "blanket", "lamp",
			"mirror", "clock", "vase", "curtain",

			// Vehicles
			"car", "bus", "truck", "motorcycle",
			"bicycle", "train", "airplane",

			// Electronics
			"phone", "smartphone", "laptop",
			"computer", "keyboard", "mouse",
			"monitor", "tv", "camera",

			// Places / nature
			"building", "house", "room",
			"tree", "forest", "mountain",
			"beach", "river", "sea", "sky",

			// Accessories (intentionally excluded)
			"bag", "backpack", "handbag",
			"watch", "glasses", "sunglasses"
		];

		const isClearlyNotClothing = nonClothingKeywords.some(k =>
			label.includes(k)
		);

		if (isClearlyNotClothing) {
			return addCors(new Response(JSON.stringify({
				is_valid: false,
				reason: "Not clothing (blacklist)",
				item_name: top.label,
				confidence
			}), { status: 200 }));
		}

		// --------------------------------------------------
		// 📦 CATEGORY MAP
		// outer | dress | upper | lower | shoes
		// --------------------------------------------------
		let category = "upper";

		// 🧥 OUTER (fix suit collisions)
		if (
			label.includes("jacket") &&
			!label.includes("dinner jacket") &&
			!label.includes("suit")
		) {
			category = "outer";
		}
		else if (
			label.includes("coat") ||
			label.includes("parka") ||
			label.includes("overcoat") ||
			label.includes("trench") ||
			label.includes("windbreaker") ||
			label.includes("raincoat") ||
			label.includes("poncho") ||
			label.includes("cape") ||
			label.includes("anorak") ||
			label.includes("puffer") ||
			label.includes("fleece") ||
			label.includes("shearling") ||
			label.includes("blazer")
		) {
			category = "outer";
		}

		// 👗 DRESS / ONE-PIECE
		else if (
			label.includes("dress") ||
			label.includes("gown") ||
			label.includes("jumpsuit") ||
			label.includes("romper") ||
			label.includes("playsuit") ||
			label.includes("boiler suit") ||
			label.includes("overalls") ||
			label.includes("dungarees")
		) {
			category = "dress";
		}

		// 👔 SUIT → UPPER
		else if (
			label.includes("suit") ||
			label.includes("tuxedo") ||
			label.includes("tailcoat") ||
			label.includes("morning suit")
		) {
			category = "upper";
		}

		// 👖 LOWER
		else if (
			label.includes("pants") ||
			label.includes("trousers") ||
			label.includes("jean") ||
			label.includes("denim") ||
			label.includes("shorts") ||
			label.includes("bermuda") ||
			label.includes("legging") ||
			label.includes("jogger") ||
			label.includes("sweatpants") ||
			label.includes("track pants") ||
			label.includes("skirt") ||
			label.includes("culottes") ||
			label.includes("palazzo") ||
			label.includes("harem")
		) {
			category = "lower";
		}

		// 👟 SHOES
		else if (
			label.includes("shoe") ||
			label.includes("sneaker") ||
			label.includes("trainer") ||
			label.includes("boot") ||
			label.includes("sandal") ||
			label.includes("heel") ||
			label.includes("flat") ||
			label.includes("loafer") ||
			label.includes("oxford") ||
			label.includes("derby") ||
			label.includes("mule") ||
			label.includes("clog") ||
			label.includes("espadrille") ||
			label.includes("slipper") ||
			label.includes("flip flop") ||
			label.includes("slide")
		) {
			category = "shoes";
		}

		// --------------------------------------------------
		// ✅ RESPONSE
		// --------------------------------------------------
		return addCors(new Response(JSON.stringify({
			is_valid: true,
			item_name: top.label,
			category,
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

                // 1. Delete from D1 (Security check: only delete matching user_id)
                const result = await env.DB.prepare("DELETE FROM wardrobe WHERE user_id=? AND image_url=?")
                    .bind(userId, imageUrl).run();

                // If no record was deleted, image does not belong to this user
                if (result.meta.changes === 0) {
                     return addCors(new Response(JSON.stringify({ success: true, note: "Item not found or not yours" }), { status: 200 }));
                }

                // 2. Delete from Supabase Storage
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

                library: await env.DB.prepare(`SELECT id, title, status FROM library_books WHERE user_id=?`)
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
                    .bind(userId).all(),

                quests: await env.DB.prepare(`SELECT id, type, description, target_action, xp_reward, is_completed FROM quests WHERE user_id=?`).bind(userId).all()
            };

            // Boolean conversion for client (1 -> true)
            if (result.quests && result.quests.results) {
                result.quests = result.quests.results.map(q => ({ ...q, is_completed: q.is_completed === 1 }));
            }

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

                // 1. USER (Name, Level, XP, Character ID, FCM Token)
                const userBox = body.user || {}; 
                const rawName = userBox.name || "";
                const userName = (!rawName || rawName.trim() === "") ? "Rookie" : rawName;
                const userBirth = userBox.birthdate || "";
                const userLevel = userBox.level || 1;
                const userExp = userBox.experience || 0;
                const charId = userBox.character_id || 1;
                const fcmToken = userBox.hasOwnProperty("fcm_token")
                    ? userBox.fcm_token
                    : undefined;

                await insertOrUpdate(
                    `INSERT INTO users (user_id, name, birthdate, level, experience, character_id, fcm_token) VALUES (?, ?, ?, ?, ?, ?, ?)`,
                    [userId, userName, userBirth, userLevel, userExp, charId, fcmToken],
                    `UPDATE users SET name=?, birthdate=?, level=?, experience=?, character_id=?, fcm_token = COALESCE(NULLIF(?, ''), fcm_token) WHERE user_id=?`,
                    [userName, userBirth, userLevel, userExp, charId, fcmToken ?? null, userId]
                );

                // 2. LIBRARY (ID-based safe synchronization)
                if (body.library !== undefined) {
                    const library = safeList(body.library);

                    // A) Remove deleted records
                    const validIds = library
                        .filter(b => b.id !== undefined && b.id !== null && b.id !== 0)
                        .map(b => b.id);

                    if (validIds.length > 0) {
                        const placeholders = validIds.map(() => '?').join(',');
                        await env.DB.prepare(`
                            DELETE FROM library_books 
                            WHERE user_id = ? 
                            AND id NOT IN (${placeholders})
                        `).bind(userId, ...validIds).run();
                    } else {
                        await env.DB.prepare(`DELETE FROM library_books WHERE user_id=?`).bind(userId).run();
                    }

                    // B) Add or update items
                    for (const b of library) {
                        if (!b.title || b.title.trim() === "") continue;

                        if (b.id) {
                            await env.DB.prepare(`
                                UPDATE library_books 
                                SET title = ?, status = ? 
                                WHERE id = ? AND user_id = ?
                            `).bind(b.title, b.status, b.id, userId).run();
                        } else {
                            await env.DB.prepare(`
                                INSERT INTO library_books (user_id, title, status) 
                                VALUES (?, ?, ?)
                            `).bind(userId, b.title, b.status).run();
                        }
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

                // 3. GYM LOG
                const gym_log = safeList(body.gym_log);

                for (const g of gym_log) {
                    // 1. DELETE: If ID exists but exercise_name is empty, delete from DB
                    if (g.id && (!g.exercise_name || g.exercise_name.trim() === "")) {
                        await env.DB.prepare(`DELETE FROM gym_log WHERE id=? AND user_id=?`)
                            .bind(g.id, userId).run();
                        continue;
                    }

                    // Skip empty new records
                    if (!g.exercise_name || g.exercise_name.trim() === "") continue;

                    // 2. UPSERT (INSERT OR UPDATE)
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
                    }
                }

                // 4. MARKET ITEMS
                const market_items = safeList(body.market_items);
                for (const m of market_items) {
                    // 1. Check item name (delete if empty and has existing ID)
                    if (!m.item_name || m.item_name.trim() === "") {
                        if (m.id) {
                            await env.DB.prepare(`DELETE FROM market_items WHERE id=? AND user_id=?`)
                                .bind(m.id, userId).run();
                        }
                        continue; 
                    }

                    // 2. Save valid items
                    // A) UPDATE (if ID exists)
                    if (m.id) {
                        try {
                            await env.DB.prepare(`
                                UPDATE market_items 
                                SET category=?, item_name=?, planned=?, bought=?, date=? 
                                WHERE id=? AND user_id=?
                            `).bind(m.category, m.item_name, m.planned, m.bought, m.date, m.id, userId).run();
                        } catch (e) {
                            await env.DB.prepare(`DELETE FROM market_items WHERE id=?`).bind(m.id).run();
                        }
                    } 
                    // B) INSERT (if no ID)
                    else {
                        try {
                            await env.DB.prepare(`
                                INSERT INTO market_items (user_id, category, item_name, planned, bought, date) 
                                VALUES (?, ?, ?, ?, ?, ?)
                            `).bind(userId, m.category, m.item_name, m.planned, m.bought, m.date).run();
                        } catch (e) {
                            await env.DB.prepare(`
                                UPDATE market_items 
                                SET planned=?, bought=?, date=? 
                                WHERE user_id=? AND category=? AND item_name=?
                            `).bind(m.planned, m.bought, m.date, userId, m.category, m.item_name).run();
                        }
                    }
                }

                // 5. RESTAURANT LOG
                const restaurant = safeList(body.restaurant);
                for (const r of restaurant) {
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

                // 6. CALENDAR NOTES
                const calendar_notes = safeList(body.calendar_notes);
                for (const c of calendar_notes) {
                    const noteContent = (c.note === undefined || c.note === null) ? "" : c.note;

                    // 1. Try updating existing date note
                    const updateRes = await env.DB.prepare(`UPDATE calendar_notes SET note=? WHERE user_id=? AND date=?`)
                        .bind(noteContent, userId, c.date).run();
                    
                    // 2. Insert new record if date does not exist yet
                    if (updateRes.meta.changes === 0) {
                         await env.DB.prepare(`INSERT INTO calendar_notes (user_id, date, note) VALUES (?, ?, ?)`)
                            .bind(userId, c.date, noteContent).run();
                    }
                }

                // 7. QUESTS
                const quests = safeList(body.quests);
                for (const q of quests) {
                    if (!q.id) continue;

                    try {
                        await env.DB.prepare(`
                            INSERT INTO quests (user_id, id, type, description, target_action, xp_reward, is_completed)
                            VALUES (?, ?, ?, ?, ?, ?, ?)
                            ON CONFLICT(user_id, id) 
                            DO UPDATE SET 
                                is_completed = excluded.is_completed,
                                type = excluded.type
                        `).bind(
                            userId,
                            q.id,
                            q.type,
                            q.description || "",
                            q.target_action || "",
                            q.xp_reward || 0,
                            q.is_completed ? 1 : 0
                        ).run();
                    } catch (e) {
                        console.error("Quest Save Error:", e.message);
                    }
                }

                // 8. WARDROBE
                const wardrobe = safeList(body.wardrobe);
                for (const w of wardrobe) {
                    if (w.id && (!w.image_url || w.image_url === "")) {
                        await env.DB.prepare(`DELETE FROM wardrobe WHERE id=? AND user_id=?`).bind(w.id, userId).run();
                        continue;
                    }
                    if (!w.image_url || w.image_url === "") continue;

                    try {
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
                            w.confidence || 0
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
        // ---------- HUGGING FACE (PROTECTED ENDPOINT) ----------
    

            // Not found
            return addCors(new Response(JSON.stringify({ error: "Not Found" }), { status: 404 }));
        },

    async scheduled(event, env, ctx) {
        const today = new Date().toISOString().split('T')[0];
        console.log(`🕒 Global Notification Sync Started: ${today}`);

        // =================================================================
        // 1. SUPABASE PING (Anti-Pause / Keepalive)
        // =================================================================
        try {
            // Health check to Supabase Auth to keep database active and prevent sleep mode
            const sbPing = await fetch(`${env.SUPABASE_URL}/auth/v1/health`, {
                method: "GET",
                headers: {
                    "apikey": env.SUPABASE_ANON_KEY
                }
            });
            console.log(`💓 Supabase Ping Status: ${sbPing.status}`);
        } catch (e) {
            console.error("Supabase Ping Error:", e.message);
        }

        // =================================================================
        // 2. FIREBASE PUSH NOTIFICATIONS
        // =================================================================
        try {
            // A. Authentication
            const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
            const accessToken = await getGoogleAccessToken(serviceAccount);

            // B. Fetch users with FCM tokens
            const { results: users } = await env.DB.prepare(
                "SELECT user_id, fcm_token, name FROM users WHERE fcm_token IS NOT NULL AND fcm_token != ''"
            ).all();

            for (const user of users) {
                let summaryParts = [];

                // --- DATA CHECKS (FILTER EMPTY ENTRIES) ---
                
                // Gym
                const gym = await env.DB.prepare(`
                    SELECT id FROM gym_log 
                    WHERE user_id=? AND date=? AND completed=0 
                    AND exercise_name IS NOT NULL AND exercise_name != ''
                `).bind(user.user_id, today).all();
                
                if (gym.results.length > 0) summaryParts.push(`🏋️ ${gym.results.length} exercises left!`);

                // Market
                const mkt = await env.DB.prepare(`
                    SELECT id FROM market_items 
                    WHERE user_id=? AND date=? AND bought=0 
                    AND item_name IS NOT NULL AND item_name != ''
                `).bind(user.user_id, today).all();
                
                if (mkt.results.length > 0) summaryParts.push(`🛒 ${mkt.results.length} items to buy.`);

                // Study
                const study = await env.DB.prepare(`
                    SELECT subject FROM study_log 
                    WHERE user_id=? AND date=? 
                    AND subject IS NOT NULL AND subject != ''
                `).bind(user.user_id, today).all();
                
                if (study.results.length > 0) summaryParts.push(`📚 ${study.results.length} study sessions planned.`);

                // Library
                const book = await env.DB.prepare(`
                    SELECT title FROM library_books 
                    WHERE user_id=? AND status='Reading' 
                    AND title IS NOT NULL AND title != ''
                `).bind(user.user_id).first();
                
                if (book) summaryParts.push(`📖 Reading: "${book.title}"`);

                // Notes
                const note = await env.DB.prepare(`
                    SELECT note FROM calendar_notes 
                    WHERE user_id=? AND date=? 
                    AND note IS NOT NULL AND note != ''
                `).bind(user.user_id, today).first();
                
                if (note && note.note.trim() !== "") summaryParts.push(`📝 Note: "${note.note.substring(0, 15)}..."`);

                // Restaurant
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

                // --- NOTIFICATION TEXT ---
                let title = "";
                let body = "";

                if (summaryParts.length > 0) {
                    // Case 1: Pending tasks
                    title = `Don't stop now, ${user.name || 'Champ'}! 🚀`;
                    body = "Unfinished goals for today:\n" + summaryParts.join("\n") + "\n\nLog in now to complete them!";
                } else {
                    // Case 2: All done or no plans
                    title = `Your life is waiting! ✨`;
                    body = `Hey ${user.name || 'Rookie'}, your character needs you. Log in now to plan your next move!`;
                }

                // C. Dispatch
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
  // 1. Prepare JWT Header and Payload
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

  // 2. Clean and import private key
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

  // 3. Sign token
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const signedToken = `${unsignedToken}.${btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")}`;

  // 4. Request Access Token from Google OAuth2
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
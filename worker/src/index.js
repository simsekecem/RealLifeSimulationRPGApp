export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // --- AUTH CHECK ---
    const authHeader = request.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }
    const token = authHeader.substring(7);

    const userRes = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
      headers: {
        "Authorization": `Bearer ${token}`,
        "apikey": env.SUPABASE_ANON_KEY
      }
    });

    if (!userRes.ok) {
      return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401 });
    }

    const user = await userRes.json();
    const userId = user.id;

    // --- PREFERENCES ENDPOINTS ---
    if (path === "/prefs/get" && method === "GET") {
      const { results } = await env.DB.prepare(
        "SELECT prefs FROM preferences WHERE user_id = ?"
      ).bind(userId).all();
      return new Response(results[0]?.prefs || "{}", { headers: { "Content-Type": "application/json" } });
    }

    if (path === "/prefs/set" && method === "POST") {
      const body = await request.json();
      await env.DB.prepare(`
        INSERT INTO preferences (user_id, prefs)
        VALUES (?, ?)
        ON CONFLICT(user_id) DO UPDATE SET prefs = excluded.prefs
      `).bind(userId, JSON.stringify(body)).run();
      return new Response(JSON.stringify({ ok: true }));
    }

    // --- RESET PASSWORD ENDPOINT ---
    if (path === "/reset-password" && method === "POST") {
      const body = await request.json();
      const { access_token, new_password } = body;

      if (!access_token || !new_password) {
        return new Response(JSON.stringify({ error: "Missing parameters" }), { status: 400 });
      }

      // Supabase Admin Key ile şifre güncelle
      const supabaseRes = await fetch(`${env.SUPABASE_URL}/auth/v1/admin/users`, {
        method: "PUT",
        headers: {
          "apikey": env.SUPABASE_SERVICE_ROLE_KEY,
          "Authorization": `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          password: new_password,
          id_token: access_token
        })
      });

      const data = await supabaseRes.json();
      return new Response(JSON.stringify(data), { status: supabaseRes.status, headers: { "Content-Type": "application/json" } });
    }

    // --- NOT FOUND ---
    return new Response("Not found", { status: 404 });
  }
};

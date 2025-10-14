export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

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

    return new Response("Not found", { status: 404 });
  }
};

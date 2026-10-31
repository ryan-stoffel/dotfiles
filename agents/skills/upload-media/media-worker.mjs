export default {
  async fetch(request, env) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed", {
        status: 405,
        headers: { Allow: "GET, HEAD" },
      });
    }

    const key = new URL(request.url).pathname.slice(1);
    if (!key) return new Response("Not found", { status: 404 });

    const object = request.method === "HEAD"
      ? await env.MEDIA.head(key)
      : await env.MEDIA.get(key);
    if (!object) return new Response("Not found", { status: 404 });

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set("ETag", object.httpEtag);
    headers.set("Content-Length", String(object.size));
    headers.set("X-Content-Type-Options", "nosniff");
    return new Response(request.method === "HEAD" ? null : object.body, { headers });
  },
};

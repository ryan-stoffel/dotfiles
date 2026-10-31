export default { fetch() { return new Response("Private media. Authentication required.\n", { status: 401, headers: { "Cache-Control": "no-store", "Content-Type": "text/plain" } }); } };

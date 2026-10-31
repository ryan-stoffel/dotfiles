import assert from "node:assert/strict";
import test from "node:test";
import worker from "./media-worker.mjs";

function bucket() {
  const calls = [];
  const object = () => ({
    size: 3,
    httpEtag: '"image-etag"',
    body: new Response("png").body,
    writeHttpMetadata(headers) {
      headers.set("Content-Type", "image/png");
      headers.set("Cache-Control", "public,max-age=31536000,immutable");
    },
  });
  return {
    calls,
    async get(key) { calls.push(["get", key]); return key === "missing" ? null : object(); },
    async head(key) { calls.push(["head", key]); return key === "missing" ? null : object(); },
  };
}

test("serves the stored bytes and image metadata", async () => {
  const MEDIA = bucket();
  const result = await worker.fetch(new Request("https://files.example/test.png"), { MEDIA });
  assert.equal(result.status, 200);
  assert.equal(await result.text(), "png");
  assert.equal(result.headers.get("Content-Type"), "image/png");
  assert.equal(result.headers.get("Content-Length"), "3");
  assert.equal(result.headers.get("ETag"), '"image-etag"');
  assert.equal(result.headers.get("X-Content-Type-Options"), "nosniff");
  assert.deepEqual(MEDIA.calls, [["get", "test.png"]]);
});

test("HEAD checks metadata without downloading the object", async () => {
  const MEDIA = bucket();
  const result = await worker.fetch(new Request("https://files.example/test.png", { method: "HEAD" }), { MEDIA });
  assert.equal(result.status, 200);
  assert.equal(result.body, null);
  assert.equal(result.headers.get("Content-Type"), "image/png");
  assert.deepEqual(MEDIA.calls, [["head", "test.png"]]);
});

test("does not expose a bucket listing or accept writes", async () => {
  const MEDIA = bucket();
  const root = await worker.fetch(new Request("https://files.example/"), { MEDIA });
  assert.equal(root.status, 404);
  for (const method of ["POST", "PUT", "DELETE"]) {
    const result = await worker.fetch(new Request("https://files.example/test.png", { method }), { MEDIA });
    assert.equal(result.status, 405);
    assert.equal(result.headers.get("Allow"), "GET, HEAD");
  }
  assert.deepEqual(MEDIA.calls, []);
});

test("missing files return 404", async () => {
  const result = await worker.fetch(new Request("https://files.example/missing"), { MEDIA: bucket() });
  assert.equal(result.status, 404);
});

# Private R2 setup

Ryan's `pr-media` bucket must remain private. Keep both custom-domain access and
`r2.dev` access disabled. Existing Gists and their files remain unchanged.

Each upload machine needs Node.js/npm and a Cloudflare login:

```bash
npx --yes wrangler@4.156.0 login
```

Enable R2 in the Cloudflare dashboard and use Standard storage. R2 requires
billing setup; usage beyond the account's free allowance is billed. See
[R2 pricing](https://developers.cloudflare.com/r2/pricing/).

The local `~/.config/pr-media/r2.env` contains no credentials:

```bash
CLOUDFLARE_ACCOUNT_ID='<account ID from wrangler whoami>'
R2_BUCKET='pr-media'
R2_PUBLIC_URL=''
```

Wrangler stores its login separately. The empty public URL intentionally stops
`upload.sh` before any upload. `PR_MEDIA_CONFIG` can select another configuration
file. An authenticated sharing workflow is required before private media can be
shared with PR reviewers. Public access must stay disabled during that setup.

The `pr-media-private` Worker denies requests to `pr-media.parallax.codes/*`,
including previously cached synthetic test files. The domain is disconnected
from R2. Retain this guard until those cached URLs are purged or otherwise
inaccessible. See [R2 access controls](https://developers.cloudflare.com/r2/buckets/public-buckets/#access-control).
Its source is `private-guard.js`, with deployment settings in `wrangler.private.json`.

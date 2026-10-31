# R2 media setup

Media is served publicly at `https://files.stoffel-thomas-ryan.workers.dev`.
The `files` Worker serves GET/HEAD requests from the `pr-media` R2 bucket,
without a directory listing or public uploads. Direct R2 custom-domain and
`r2.dev` access remain disabled.

Each upload machine needs Node.js/npm and a Cloudflare login:

```bash
npx --yes wrangler@4.156.0 login
```

Its `~/.config/pr-media/r2.env` contains no credentials:

```bash
CLOUDFLARE_ACCOUNT_ID='<account ID from wrangler whoami>'
R2_BUCKET='pr-media'
R2_PUBLIC_URL='https://files.stoffel-thomas-ryan.workers.dev'
```

Wrangler stores its login separately. `PR_MEDIA_CONFIG` can select another
configuration file. Verify setup by uploading a non-sensitive screenshot and
opening the returned URL.

To deploy the read-only host after changing `media-worker.mjs`:

```bash
. ~/.config/pr-media/r2.env
export CLOUDFLARE_ACCOUNT_ID
npx --yes wrangler@4.156.0 deploy --config ~/.dotfiles/agents/skills/upload-media/wrangler.json
```

The account shares R2's free allowance and Workers' free request allowance.
Excess R2 usage is billed. See [R2 pricing](https://developers.cloudflare.com/r2/pricing/)
and [Workers limits](https://developers.cloudflare.com/workers/platform/limits/).

Existing Gists remain unchanged. `pr-media.parallax.codes` is disconnected from
R2. Its `pr-media-private` Worker blocks old cached URLs; retain that guard until
they are purged or otherwise inaccessible. Its source and deployment settings
are `private-guard.js` and `wrangler.private.json`.

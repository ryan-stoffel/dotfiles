# R2 setup

Each machine needs Node.js/npm and a Cloudflare login:

```bash
npx --yes wrangler@4.156.0 login
```

Enable R2 in the Cloudflare dashboard, then create a Standard storage bucket
named `pr-media`. R2 requires billing setup. Its free allowance is shared across
the account; usage beyond it is billed. See [R2 pricing](https://developers.cloudflare.com/r2/pricing/).

Connect a dedicated custom domain to the bucket and wait for it to become active.
Use a hostname with no existing service. The `r2.dev` development endpoint is
rate limited and is not intended for production use. See
[public buckets](https://developers.cloudflare.com/r2/buckets/public-buckets/).

Create `~/.config/pr-media/r2.env` on each upload machine:

```bash
CLOUDFLARE_ACCOUNT_ID='<account ID from wrangler whoami>'
R2_BUCKET='pr-media'
R2_PUBLIC_URL='https://<public bucket hostname>'
```

These are shell assignments, without spaces around `=`. The file contains no
credentials. Wrangler stores its login separately. `PR_MEDIA_CONFIG` can select
another configuration file.

Run `upload.sh` with a non-sensitive screenshot, then open the returned URL and
check its contents. Update the live skill only after that upload succeeds.
Leave existing Gists and their files intact.

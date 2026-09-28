# Secrets

This repo is **public**, so no real credentials or PII are committed in plaintext. Two things are redacted from `config.yml` / `docker-compose.yml`:

1. **Camera RTSP credentials** — the login every camera uses.
2. **LPR license plate numbers** — real plates tied to named vehicles.

There are two independent mechanisms here: env-var templating (what actually runs the deployment) and an encrypted backup (so the real values aren't lost if this repo is the only copy left).

## How redaction works at runtime

`docker-compose.yml` reads three variables from a local `.env` file (never committed — see `.gitignore`):

```
FRIGATE_RTSP_USER=admin
FRIGATE_RTSP_PASSWORD=<password for Frigate's own restreamed RTSP/go2rtc output>
FRIGATE_CAMERA_RTSP_PASSWORD=<the actual camera password>
```

These get passed into the container as environment variables, and Frigate substitutes them into `config.yml` wherever it sees `{FRIGATE_RTSP_USER}` / `{FRIGATE_CAMERA_RTSP_PASSWORD}` — this is a built-in Frigate feature, restricted to variables prefixed `FRIGATE_`. Example from `config.yml`:

```yaml
inputs:
  - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_CAMERA_RTSP_PASSWORD}@192.168.1.189:554/onvif1
```

Set up `.env` with:

```bash
cp .env.example .env
# edit .env with real values
```

**LPR plates are different** — Frigate has no env-var templating for `lpr.known_plates`, so `config.yml` just carries placeholders:

```yaml
lpr:
  known_plates:
    Vehicle1:
      - AAA0000
```

To run LPR for real, edit the deployed `/FRIGATE_DATA/config/config.yaml` directly with the real plate values (see `secrets.env.enc` below for where those are backed up). This file is **not** the same as the repo's `config.yml` — it's the live copy on the server, and it's fine for it to diverge here since it's not committed anywhere.

## Encrypted backup (`secrets.env.enc`)

An AES-256 encrypted file containing the real values above (both the RTSP credentials and the LPR plates), so they're recoverable even if the server disk is lost — without ever putting them in git as plaintext.

**The passphrase is not stored anywhere in this repo or its history.** Keep it in a password manager. If it's lost, the backup is unrecoverable — that's the intended tradeoff.

To restore the real values (e.g., rebuilding the server from scratch):

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -in secrets.env.enc -out secrets.env
```

This produces `secrets.env` with all the real values in one place:

```
FRIGATE_RTSP_USER=...
FRIGATE_RTSP_PASSWORD=...
FRIGATE_CAMERA_RTSP_PASSWORD=...
LPR_PLATE_<VEHICLE>=...
```

From there:
- Copy the three `FRIGATE_*` lines into `.env` (used by `docker-compose.yml`).
- Manually paste the `LPR_PLATE_*` values into the live `/FRIGATE_DATA/config/config.yaml`'s `lpr.known_plates` section (there's no automated step for this — Frigate doesn't support templating there).

`secrets.env` itself is gitignored — never commit it. Only the `.enc` form is safe to commit.

## Rotating a credential

If you ever change the camera password or add/remove a plate:

1. Update `.env` and/or the live `config.yaml` on the server with the new value.
2. Update your local `secrets.env` to match.
3. Re-encrypt and commit the new backup:
   ```bash
   openssl enc -aes-256-cbc -pbkdf2 -salt -in secrets.env -out secrets.env.enc
   git add secrets.env.enc
   git commit -m "Rotate camera RTSP password"
   ```

## Why this matters here specifically

This repo's git history once had a plaintext RTSP password committed for over a year before it was caught and scrubbed (via `git filter-branch` + a forced push, after which the underlying credential should be treated as burned regardless of the history rewrite — scrubbing history doesn't undo any exposure that already happened, e.g. from scrapers or cached forks). The lesson: **check `git diff` for anything that looks like a credential before committing**, not just before making a repo public.

# Operations

Day-2 tasks: upgrading, rolling back, disk safety, and camera troubleshooting.

## Why the OS disk stays safe now

For two years, this deployment periodically filled its root disk to 100% ([Issue #1](https://github.com/vcasadei/Frigate-Configuration/issues/1)), taking down the whole system, including a `/dev/loop0`-based workaround that didn't actually fix it. The real cause: Frigate stages recording segments in `/tmp/cache` before finalizing them, and `docker-compose.yml` never mounted that path as `tmpfs`. It was silently accumulating on the container's writable layer — which lives on the **OS** disk, not the separate media partition — and eventually reached tens of GB.

The fix, now in `docker-compose.yml`:

```yaml
tmpfs:
  - /tmp/cache:size=1g
```

This caps that cache at 1GB **in RAM**. It cannot spill onto the OS disk regardless of camera load — this class of bug is structurally closed, not just patched around.

**Sanity check anytime:**

```bash
df -h /                              # should stay well under 100%, growing only when you pull a new image
docker exec frigate df -h /tmp/cache # should stay near/under the 1g cap
```

If `/` is ever climbing again, check `sudo du -x -h --max-depth=2 /var/lib` first — `/var/lib/containerd` growing unusually large again would point to a similar caching bug elsewhere, not a resurgence of this one.

## Upgrading Frigate

1. **Tag the current known-good state** before touching anything:
   ```bash
   git tag -a frigate-<current-version>-working -m "known-good state before upgrading"
   git push origin frigate-<current-version>-working
   ```
2. **Back up config + database** on the server:
   ```bash
   sudo cp /FRIGATE_DATA/config/config.yaml /FRIGATE_DATA/config/frigate.db /FRIGATE_DATA/config/pre-upgrade-backup/
   ```
3. **Check the release notes** on the [Frigate releases page](https://github.com/blakeblackshear/frigate/releases) for breaking config changes between your version and the target.
4. Bump the tag in `docker-compose.yml`, then:
   ```bash
   docker compose pull   # can be slow — run detached if it keeps timing out:
                          # nohup docker pull ghcr.io/blakeblackshear/frigate:<tag> > /tmp/pull.log 2>&1 &
   docker compose up -d
   docker compose logs -f frigate
   ```
5. **Watch the startup log** for the config migration step:
   ```
   Checking if frigate config needs migration...
   Migrating frigate config from X to Y...
   Finished frigate config migration...
   ```
   Frigate's built-in migrator handles schema changes (e.g. the 0.17→0.18 zones/masks format change) automatically. If it fails, the release notes will say so explicitly and link manual migration steps.
6. **Verify** the migrated config (`sudo cat /FRIGATE_DATA/config/config.yaml`) still has all cameras, zones, and `review.alerts.required_zones` intact — diff against your backup if unsure.
7. **Sync this repo** — update `config.yml`, `docker-compose.yml`, and the `version:` line to match the verified live config, then commit and push. Tag the new state too (e.g. `v0.18`).

### Rolling back

Every upgrade should leave behind a tag from step 1. To roll back:

```bash
git checkout frigate-<old-version>-working -- docker-compose.yml config.yml
# copy config.yml back to /FRIGATE_DATA/config/config.yaml on the server
# restore /FRIGATE_DATA/config/frigate.db from the pre-upgrade backup if the DB was migrated
docker compose up -d
```

Current tags: `frigate-0.17.0-working`, `v0.18`.

## Camera troubleshooting

If a camera starts crash-looping in `docker logs frigate`:

```
ffmpeg.<Camera>.detect  ERROR  : Connection to tcp://<ip>:554 ... failed: No route to host
watchdog.<Camera>       ERROR  : Ffmpeg process crashed unexpectedly for <Camera>.
```

1. **Check it's actually a network problem, not Frigate:**
   ```bash
   ping -c 3 <camera-ip>
   ```
   `Destination Host Unreachable` means the camera (or its switch/PoE port) is physically offline — not a Frigate or config issue. Frigate's watchdog retries indefinitely and will reconnect automatically once the camera's back; no action needed on the server.

2. **If the camera is confirmed dead** (won't come back), disable it to stop the log noise:
   ```bash
   docker compose stop frigate   # avoid a race: Frigate periodically rewrites config.yaml itself
   sudo sed -i '/^  <Camera>:$/,/enabled:/ s/enabled: true/enabled: false/' /FRIGATE_DATA/config/config.yaml
   docker compose up -d
   ```
   Stopping the container first matters — editing the file while Frigate is running can lose your edit to its own periodic rewrite. Mirror the same change (`enabled: false`) in this repo's `config.yml` and commit.

3. **When the camera is replaced**, flip `enabled: true` back on both the live config and in this repo — the IP/credentials are usually still valid if the replacement takes the same network slot.

### Current known camera state

| Camera | Status |
|---|---|
| PortaArea, Entrada, Garagem, Galinheiro, AtrasCasa, Portao, Quintal | Healthy |
| Cana | Disabled — hardware failure (unreachable at the network level even after power-cycling) |

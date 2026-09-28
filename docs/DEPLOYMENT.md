# Deployment

Full guide for deploying this configuration on a fresh box. If you're rebuilding the existing server, most of this is already done — see [OPERATIONS.md](OPERATIONS.md) instead.

## 1. Hardware prerequisites

- An x86 board with a free M.2/PCIe slot for a **Google Coral PCIe TPU** (this repo assumes `device: pci` in the detector config — a USB Coral or no accelerator needs a different `detectors:` block in `config.yml`).
- Enough storage for **two separate concerns**: the OS/config disk, and recordings. Do not put both on the same partition — see [why](#why-two-partitions) below.
- IP cameras reachable over RTSP/ONVIF on the same LAN.

## 2. OS install and partitioning

Debian 12 (Bookworm) is required — Debian 13 ships kernel 6.12, which the Coral PCIe driver doesn't support yet ([reference](https://www.coral.ai/docs/m2/get-started/#2a-on-linux)).

Full step-by-step install notes with screenshots are in [Issue #2](https://github.com/vcasadei/Frigate-Configuration/issues/2). Summary of the partition scheme:

| Partition | Size | Mount | Purpose |
|---|---|---|---|
| EFI | 512MB | `/boot/efi` | boot |
| Root | ~60GB | `/` | OS, Docker, Frigate config/db |
| Swap | 2-4GB | swap | |
| Media | remaining space | `/frigate/media` | Frigate recordings — **its own partition** |

### Why two partitions

Recordings can fill a disk. Keeping them on a dedicated partition means a full media disk can't take down the OS or Docker — Frigate just fails to write new recordings until space is freed, instead of the whole box grinding to a halt. This deployment learned this the hard way over two years (see [Issue #1](https://github.com/vcasadei/Frigate-Configuration/issues/1)) — and even with two partitions, a *different* bug (Frigate's cache silently defaulting onto the OS partition rather than RAM) still managed to fill the root disk in 2026. That's now fixed with a `tmpfs` mount; see [OPERATIONS.md](OPERATIONS.md#why-the-os-disk-stays-safe-now).

Install Docker + Docker Compose after the OS is up (standard [Docker install docs](https://docs.docker.com/engine/install/debian/)).

## 3. Coral PCIe driver

Follow [Coral's official Linux setup](https://www.coral.ai/docs/m2/get-started/#2a-on-linux) to install the PCIe driver and confirm the accelerator shows up as `/dev/apex_0`:

```bash
ls -la /dev/apex_0
```

## 4. Clone the repo and set up host directories

```bash
git clone https://github.com/vcasadei/Frigate-Configuration.git
cd Frigate-Configuration
sudo mkdir -p /FRIGATE_DATA/config /frigate/media
```

`docker-compose.yml` bind-mounts these two host paths into the container as `/config` and `/media`. They must exist before `docker compose up` — Docker won't create them with the right ownership automatically for a bind mount, and Frigate needs `/config` to already be there to write its database and config.

## 5. Set up secrets

See **[SECRETS.md](SECRETS.md)** for the full explanation. Short version:

```bash
cp .env.example .env
# edit .env with your camera username/password
```

`docker compose` auto-loads `.env` from the current directory and substitutes `${FRIGATE_RTSP_USER}` etc. into `docker-compose.yml`'s `environment:` block, which Frigate then substitutes into `config.yml`'s `{FRIGATE_RTSP_USER}` placeholders at startup.

## 6. Put the config in place

```bash
sudo cp config.yml /FRIGATE_DATA/config/config.yaml
```

Frigate reads `config.yaml` (or `config.yml`) from `/config` inside the container — cloning the repo alone doesn't put it there, this copy step is required.

**Edit the camera IPs and names** in `/FRIGATE_DATA/config/config.yaml` to match your own cameras — the ones checked into this repo (`192.168.1.x`) are this deployment's actual LAN and won't mean anything on a different network. If you're setting up a genuinely new deployment (not rebuilding this one), also strip the `lpr.known_plates` section unless you want that feature.

## 7. First boot

```bash
docker compose up -d
docker compose logs -f frigate
```

Watch for all cameras reaching `Capture process started for <camera>` and no `ffmpeg` connection errors. Then open `http://<server-ip>` — you should see live feeds for every enabled camera.

If a camera fails to connect, check RTSP credentials and that the camera's ONVIF path (`/onvif1` in this config) matches your camera model — see [OPERATIONS.md](OPERATIONS.md#camera-troubleshooting) for the full troubleshooting flow.

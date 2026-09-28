
# Frigate Configuration on Radxa X2L (Debian 12 + Coral PCIe)

This is the live configuration for a home security NVR: **8 IP cameras**, motion + zone-based alerting, and license-plate recognition (LPR), running on [Frigate](https://frigate.video/) in Docker on a **Radxa X2L** board (Debian 12, Google Coral PCIe TPU). It's been in production for 2+ years.

The setup includes:

-   Minimal Debian 12 install with a dedicated partition for recordings
-   Coral PCIe TPU for object detection
-   8 cameras with per-camera zones, motion masks, and license-plate recognition
-   A `tmpfs` mount that keeps Frigate's recording cache in RAM instead of the OS disk (see [Operations](docs/OPERATIONS.md#why-the-os-disk-stays-safe-now) — this is the fix for a disk-fill bug that recurred for two years, see [Issue #1](https://github.com/vcasadei/Frigate-Configuration/issues/1))
-   Temperature monitoring script for the Coral TPU

## 📂 Repository Contents

| File | Purpose |
|---|---|
| `docker-compose.yml` | Runs Frigate with Coral TPU passthrough and the tmpfs cache fix |
| `config.yml` | Frigate configuration — cameras, zones, detectors, recording, LPR (secrets redacted, see below) |
| `.env.example` | Template for the credentials `docker-compose.yml` injects into `config.yml` |
| `secrets.env.enc` | Encrypted backup of the real credentials + LPR plate numbers |
| `coralTemp.sh` | Monitors Coral PCIe TPU temperature in real time |
| `docs/DEPLOYMENT.md` | Full deployment guide — prerequisites, partitioning, first-time setup |
| `docs/SECRETS.md` | How credentials are redacted, stored, restored, and rotated |
| `docs/OPERATIONS.md` | Upgrades, rollback, disk safety, camera troubleshooting |

## 🚀 Quick Start

See **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** for the full guide (host directories, hardware prerequisites, secrets, first boot). Short version once prerequisites are met:

```bash
git clone https://github.com/vcasadei/Frigate-Configuration.git
cd Frigate-Configuration
cp .env.example .env   # fill in real credentials — see docs/SECRETS.md
sudo mkdir -p /FRIGATE_DATA/config /frigate/media
sudo cp config.yml /FRIGATE_DATA/config/config.yaml
docker compose up -d
```

Access the UI at `http://<your-server-ip>`.

## 🧩 Hardware & Software

-   **Board:** Radxa X2L
-   **OS:** Debian 12 (Bookworm, kernel 6.1 LTS) — see [Issue #2](https://github.com/vcasadei/Frigate-Configuration/issues/2) for the full install/partitioning walkthrough
-   **Accelerator:** Google Coral PCIe TPU
-   **Frigate:** v0.18.0 (Docker container)

## 📖 More docs

-   **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** — prerequisites, partitioning, first-time setup
-   **[docs/SECRETS.md](docs/SECRETS.md)** — credential redaction, encrypted backup, rotation
-   **[docs/OPERATIONS.md](docs/OPERATIONS.md)** — upgrades, rollback, disk safety, camera issues
-   **[Issue #1](https://github.com/vcasadei/Frigate-Configuration/issues/1)** — history of the disk-fill incident and root cause
-   **[Issue #2](https://github.com/vcasadei/Frigate-Configuration/issues/2)** — Debian install and disk partitioning notes

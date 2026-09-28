
# Frigate Configuration on Radxa X2L (Debian 12 + Coral PCIe)

This repository contains my configuration files and scripts for running Frigate NVR on a **Radxa X2L board** with **Debian 12** and a **Google Coral PCIe TPU**.

The setup includes:

-   Minimal Debian 12 installation
    
-   Coral PCIe driver installation and verification
    
-   Docker + Docker Compose setup
    
-   Frigate configuration with multiple cameras, zones, and motion‑based recording
    
-   Temperature monitoring script for the Coral TPU
    

## 📂 Repository Contents

-   **README.md** → Project overview and documentation
    
-   **config.yml** → Frigate configuration (cameras, zones, detectors, recording, LPR settings)
    
-   **coralTemp.sh** → Bash script to monitor Coral PCIe TPU temperature in real time
    
-   **docker-compose.yml** → Docker Compose file to run Frigate with Coral TPU support
    
-   **.env.example** → Template for the camera/RTSP credentials that `docker-compose.yml` injects into `config.yml`; real secrets live only in a local, gitignored `.env`
    
-   **secrets.env.enc** → Encrypted backup of the real credentials + LPR plate numbers (see [Secrets backup](#-secrets-backup) below)

## 🚀 Quick Start

1.  Clone the repo:
    ```bash
    git clone https://github.com/vcasadei/Frigate-Configuration.git
    cd Frigate-Configuration
    ```

2.  Set up credentials:
    ```bash
    cp .env.example .env
    # edit .env with real camera credentials
    ```

3.  Start Frigate:
    
    ```bash
    docker compose up -d
    ```
    
4.  Access the Frigate UI at:
    
    ```
    http://<your-ip>
    ```
    

## 🧩 Hardware & Software

-   **Board:** Radxa X2L
    
-   **OS:** Debian 12 (Bookworm, kernel 6.1 LTS)
    
-   **Accelerator:** Google Coral PCIe TPU
    
-   **Frigate:** v0.17.0 (Docker container)

-   `/tmp/cache` is mounted as a 1GB `tmpfs` so Frigate's recording-segment buffer stays in RAM instead of silently filling the OS disk.
    

## 🔐 Secrets Backup

`secrets.env.enc` is an AES-256 encrypted backup of the real RTSP credentials and LPR license plate values (the ones redacted from `config.yml`/`.env.example`). It's safe to keep in this public repo since it's ciphertext, but the passphrase is not stored anywhere in git — keep it in a password manager.

To restore the real values:

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -in secrets.env.enc -out secrets.env
```

To update the backup after rotating a credential:

```bash
openssl enc -aes-256-cbc -pbkdf2 -salt -in secrets.env -out secrets.env.enc
```

## 📖 Documentation

Detailed installation notes are available in Issue #2. This covers:

-   Debian installation and partitioning
    
-   Post‑install setup (`sudo`, SSH, utilities)
    
-   Coral PCIe driver installation
    
-   Docker + Frigate setup
    
-   Frigate configuration with zones and motion masks
  
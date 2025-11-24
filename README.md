
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
    
-   **config.json** → Frigate configuration (cameras, zones, detectors, recording settings)
    
-   **coralTemp.sh** → Bash script to monitor Coral PCIe TPU temperature in real time
    
-   **docker-compose.yml** → Docker Compose file to run Frigate with Coral TPU support
    

## 🚀 Quick Start

1.  Clone the repo:
    ```bash
    git clone https://github.com/vcasadei/Frigate-Configuration.git
    cd Frigate-Configuration
    ```

    
2.  Start Frigate:
    
    ```bash
    docker compose up -d
    ```
    
3.  Access the Frigate UI at:
    
    ```
    http://<your-ip>
    ```
    

## 🧩 Hardware & Software

-   **Board:** Radxa X2L
    
-   **OS:** Debian 12 (Bookworm, kernel 6.1 LTS)
    
-   **Accelerator:** Google Coral PCIe TPU
    
-   **Frigate:** v0.15‑1 (Docker container)
    

## 📖 Documentation

Detailed installation notes are available in Issue #2. This covers:

-   Debian installation and partitioning
    
-   Post‑install setup (`sudo`, SSH, utilities)
    
-   Coral PCIe driver installation
    
-   Docker + Frigate setup
    
-   Frigate configuration with zones and motion masks
  
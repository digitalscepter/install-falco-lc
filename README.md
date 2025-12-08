# Falco‑LC Collector Bootstrap Installer

This repository provides the lightweight bootstrap installer used to prepare a clean Linux VM for a Falco‑LC collector deployment. The installer focuses solely on machine readiness and initial configuration, handing off the actual application stack to the main Falco‑LC configuration system.

Falco‑LC collectors are designed to run a small, self‑contained telemetry stack for log and flow ingestion, metrics collection, and visualization. The bootstrap script in this repository does *not* contain or manage those services directly — it simply ensures the host is ready for the full deployment process.

---

## Quick Install

Run on a fresh Debian/Ubuntu VM:

```
curl -sSL https://raw.githubusercontent.com/digitalscepter/falco-lc-installer/refs/heads/main/install.sh | sudo bash
```

Requirements:

- A user with `sudo` privileges  
- A supported Debian‑based Linux distribution  
- Network access sufficient for package installation and repository cloning  

---

## What the Bootstrap Script Does

The installer performs only the minimal steps required to ready a VM for Falco‑LC:

1. Detects the operating system and validates basic prerequisites  
2. Installs essential system packages  
3. Prepares a Python virtual environment for automation tools  
4. Installs the automation runtime used by the main deployment process  
5. Clones or updates the Falco‑LC deployment repository  
6. Runs the initial local deployment to configure the VM for use as a collector  

All operational components — containers, services, dashboards, retention settings, and integrations — are defined and managed in the primary Falco‑LC configuration repository, not here.

---

## After Deployment

Once the deployment process completes, the VM will function as a Falco‑LC collector. The specifics of:

- what services run,  
- how logs and metrics are ingested,  
- where data is stored, and  
- how visualization tools are exposed  

are intentionally *not* documented in this repository. Those details live in the main Falco‑LC project.

This installer’s purpose is strictly:

> **Prepare a VM → hand off to the full Falco‑LC configuration layer.**

---

## Updating an Existing Collector

The bootstrap installer is normally not rerun after initial provisioning.

To update an existing collector:

1. Log into the VM  
2. Navigate to the deployment directory created by the installer  
3. Pull updates from the main Falco‑LC configuration repository  
4. Re-run the deployment command included in that repository  

This ensures the collector receives new configurations and service updates without modifying the bootstrap environment.

---

## Troubleshooting

Common issues encountered during bootstrap installation include:

- Missing `sudo` privileges  
- Network connectivity or DNS failures  
- Unsupported or heavily customized OS images  
- Inability to clone the deployment repository  

If a failure occurs, review:

- Installer console output  
- Basic network and package‑management functionality  
- Access to any referenced repositories  

---

## Scope of This Repository

This repository intentionally contains only:

- `install.sh` — the bootstrap script  
- Minimal documentation or helper content  

It does *not* contain:

- Docker definitions  
- Service or pipeline configuration  
- Monitoring or dashboard assets  
- Long‑term application logic  

Those are all maintained in the Falco‑LC deployment/configuration repository.

---

## Contributing

Contributions are welcome where they improve:

- Installer reliability  
- OS compatibility  
- Error handling and diagnostics  
- Documentation clarity  

Changes to the Falco‑LC application stack itself should be made in the main configuration repository, not here.

---

## License

See the `LICENSE` file for terms of use.

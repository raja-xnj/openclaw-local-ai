# OpenClaw + Ollama: Air-Gapped Local AI Agent on Windows

> **Zero data egress. Rootless containers. Local model inference. Built for regulated environments.**

A fully reproducible setup for running [OpenClaw](https://github.com/openclaw) with [Ollama](https://ollama.com) inside a rootless [Podman](https://podman.io) container on Windows via WSL2 — with no cloud API dependencies.

Built and documented by [Raja Das](https://www.linkedin.com/in/rajadas/) | [The Bridge Report](https://thebridge.report)

📖 **Full build story on Medium →** *(add your link here)*

---

## Why This Matters

Most enterprise AI deployments route data through cloud APIs. For many use cases, that's acceptable. For **clinical data, proprietary formulations, regulated supply chain decisions, and M&A intelligence** — it is not.

This stack gives you:

- ✅ Local model inference (no data leaves the device)
- ✅ Rootless container isolation (Podman, no root daemon)
- ✅ Auditable network boundaries
- ✅ Reproducible on any Windows machine with WSL2

---

## Stack

| Component | Role |
|-----------|------|
| **WSL2 + Ubuntu** | Linux runtime on Windows |
| **Podman** | Rootless container runtime |
| **OpenClaw** | AI agent framework |
| **Ollama** | Local LLM server |
| **llama3.2:1b** | Default model (CPU-friendly) |

---

## Prerequisites

- Windows 10/11 with WSL2 enabled
- 8GB RAM minimum (16GB recommended for larger models)
- ~5GB disk space for model + container image

---

## Setup Guide

### Step 1: Install WSL2 + Ubuntu

```powershell
# In PowerShell (Admin)
wsl --update
wsl --install -d Ubuntu
```

> **Common error:** `Invalid distribution name: 'Ubuntu-24.04'`  
> **Fix:** Use `Ubuntu` not `Ubuntu-24.04` as the distribution name.

After install, if you hit sudo issues:

```bash
# Drop into root shell via WSL
wsl -u root

# Add your user to sudoers
usermod -aG sudo raja    # replace 'raja' with your username
wsl --shutdown
```

---

### Step 2: Fix Podman Runtime Directory

Add to `~/.bashrc` for persistent fix:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
```

Apply immediately:

```bash
source ~/.bashrc
```

---

### Step 3: Install Podman

```bash
sudo apt update && sudo apt install -y podman
```

---

### Step 4: Install Ollama

```bash
# Install dependency first
sudo apt install -y zstd

# Run official installer
curl -fsSL https://ollama.com/install.sh | sh

# Pull the model
ollama pull llama3.2:1b
```

> Using `llama3.2:1b` for CPU performance. Switch to `llama3.2:3b` if running on GPU or higher-spec hardware (expect 20-30s response times on CPU).

---

### Step 5: Build and Start OpenClaw

```bash
# Clone OpenClaw
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Build container (clean build recommended)
podman build --no-cache -t openclaw .

# Start container
podman run -d --name openclaw -p 3000:3000 openclaw
```

---

### Step 6: Configure OpenClaw → Ollama Connection

The key networking challenge: a process *inside* a container cannot reach `localhost` the same way processes outside can. Use `host.docker.internal` as the bridge:

```bash
oc config set models.providers.ollama.baseUrl "http://host.docker.internal:11434"
oc config set models.providers.ollama.api "openai-completions"

# Alternative if host.docker.internal doesn't resolve:
# oc config set models.providers.ollama.baseUrl "http://172.17.0.1:11434"
```

---

### Step 7: Set Model and Disable Heartbeat Noise

```bash
# Set primary model
oc config set agents.defaults.model.primary "ollama/llama3.2:1b"

# Disable heartbeat (stops HEARTBEAT.md flooding agent context)
oc config set agents.defaults.heartbeat.every "0m"

# Disable device auth for local-only deployment
# (add to your openclaw config)
# dangerouslyDisableDeviceAuth: true

# Restart to apply
podman restart openclaw
```

---

## Scripts

### `scripts/start.sh`

```bash
#!/bin/bash
OLLAMA_HOST=0.0.0.0 OLLAMA_NUM_THREADS=6 ollama serve &
podman start openclaw
echo "✓ OpenClaw + Ollama started"
```

### `scripts/stop.sh`

```bash
#!/bin/bash
pkill -9 ollama
podman stop -t 0 openclaw
echo "✓ OpenClaw + Ollama stopped"
```

Make executable:

```bash
chmod +x scripts/start.sh scripts/stop.sh
```

---

## Final Working State

```
WSL2 + Ubuntu
└── Ollama (host)
    └── llama3.2:1b
└── Podman (rootless)
    └── OpenClaw container
        └── → http://host.docker.internal:11434
```

| Setting | Value |
|---------|-------|
| Model | `ollama/llama3.2:1b` |
| Ollama URL | `http://host.docker.internal:11434` |
| API format | `openai-completions` |
| Heartbeat | Disabled |
| Sandbox mode | Off (container isolation retained) |
| Data egress | None |

---

## Model Selection Guide

| Model | Parameters | CPU Latency | Use Case |
|-------|-----------|-------------|----------|
| llama3.2:1b | 1B | ~3-8s | Interactive agent use, CPU-only |
| llama3.2:3b | 3B | ~20-30s | Better reasoning, GPU recommended |
| llama3.1:8b | 8B | GPU required | Production-grade reasoning |

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Invalid distribution name` | WSL not updated | `wsl --update` first |
| `not in sudoers file` | User not added to sudo group | `wsl -u root`, then `usermod -aG sudo <user>` |
| `XDG_RUNTIME_DIR` errors | Runtime dir not set | Add env vars to `~/.bashrc` |
| `ollama: command not found` | Missing `zstd` dep | `sudo apt install -y zstd` first |
| Pairing loop on dashboard | Device auth blocking | Set `dangerouslyDisableDeviceAuth: true` + `rm -rf ~/.openclaw/devices` |
| Container can't reach Ollama | localhost scope issue | Use `host.docker.internal:11434` not `localhost:11434` |
| UI timeout on responses | Model too large for CPU | Switch to `llama3.2:1b` |
| HEARTBEAT.md flooding context | Heartbeat enabled | `oc config set agents.defaults.heartbeat.every "0m"` |

---

## Related Writing

- 📄 [Full build story on Medium](#) *(add link)*
- 📰 [The Bridge Report](https://thebridge.report) — AI deployment strategy for regulated industries
- 🔗 [LinkedIn](https://www.linkedin.com/in/rajadas/)

---

## License

MIT — use freely, attribution appreciated.

---

*Built in April 2026 as a practitioner research project. Architecture validated on Windows 11, WSL2, Ubuntu 24.04 LTS.*

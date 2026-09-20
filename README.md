# Samu Recon

OSINT framework
Collects public info about IP, domains, emails, Roblox, Discord, Instagram and more.

> For educational and authorized use only.

---


## Installation

```bash
git clone <https://github.com/Scmuu/Sam-Recon>
cd Sam-Recon

chmod +x requirements.sh recon.sh
./requirements.sh

source .venv/bin/activate
./recon.sh
```

## Quick start

```bash
cd Sam-Recon
source .venv/bin/activate
./recon.sh
```

## Update


```bash
git pull

source .venv/bin/activate
python -m pip install -r requirements.txt
```

### (Optional) Discord webhook

1. Create a webhook in your Discord channel.
2. Copy the webhook URL.
3. (Optional) Create `config/config.sh` and set:

```bash
DISCORD_WEBHOOK_URL="[https://discord.com/api/webhooks/](https://discord.com/api/webhooks/)..."
```

The tool works without this file too.

---

## APIs used

Mostly public and free
---

## Legal & ethical notice

Use only on targets you have explicit permission for, or for educational purposes (CTF, personal labs, etc.).  
Do not use for stalking, harassment, doxxing or any illegal activity

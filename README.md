# Ghost Blog & Newsletter Platform

A Docker-based Ghost setup with **Caddy for automatic HTTPS** - production ready.

## 🚀 VPS Deployment

### Prerequisites

- VPS with Docker and Docker Compose installed
- Domain pointed to your VPS IP (A record)
- Ports 80 and 443 open

### Deploy

```bash
# 1. Clone repo
git clone <your-repo-url> ghost-blog
cd ghost-blog

# 2. Configure
cp .env.example .env
nano .env  # Set your domain and email settings

# 3. Start
chmod +x scripts/*.sh
./scripts/manage.sh start
```

Your blog will be live at **https://yourdomain.com** with automatic SSL!

---

## ⚙️ Configuration

Edit `.env` with your values:

```env
DOMAIN=yourdomain.com
GHOST_URL=https://yourdomain.com
ACME_EMAIL=admin@yourdomain.com
NODE_ENV=production
```

### Newsletter/SMTP (Optional)

```env
MAIL_TRANSPORT=SMTP
MAIL_FROM=noreply@yourdomain.com
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=your-user
SMTP_PASS=your-password
```

---

## 🛠️ Management Commands

```bash
./scripts/manage.sh start        # Start Ghost + Caddy
./scripts/manage.sh stop         # Stop containers
./scripts/manage.sh restart      # Restart containers
./scripts/manage.sh status       # Show status
./scripts/manage.sh logs         # Ghost logs
./scripts/manage.sh logs-caddy   # Caddy logs
./scripts/manage.sh backup       # Create backup
./scripts/manage.sh restore <file>  # Restore backup
./scripts/manage.sh update       # Update containers
./scripts/manage.sh health       # Health check
./scripts/manage.sh info         # Show info
```

---

## 📁 Project Structure

```
├── docker-compose.yml   # Ghost + Caddy config
├── Caddyfile           # Caddy reverse proxy
├── .env.example        # Config template
├── scripts/manage.sh   # Management script
├── content/            # Themes & images
└── backups/            # Backup files
```

---

## � SSL Notes

Caddy handles SSL automatically:
- Obtains Let's Encrypt certificates
- Auto-renews before expiry
- Redirects HTTP → HTTPS

Just ensure DNS is pointed to your VPS before starting.

---

## 📚 Resources

- [Ghost Docs](https://ghost.org/docs/)
- [Caddy Docs](https://caddyserver.com/docs/)

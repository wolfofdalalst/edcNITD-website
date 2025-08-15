# AWS EC2 Docker Deployment (Django + Gunicorn + Nginx)

This repo has Docker/Nginx configs to run the Django site behind Gunicorn and Nginx. Staticfiles, media and `db.sqlite3` are mounted from the repo directories so you can copy them in from your previous instance.

## Prereqs
- Ubuntu 22.04 EC2 with security group allowing 22, 80, 443
- Docker and Docker Compose v2 installed
- Optional: a domain if you want HTTPS via Let's Encrypt; otherwise you can test via server IP on port 80

## One-time server setup
```bash
sudo apt update && sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
```

## Deploy steps
```bash
# Clone
cd ~
git clone https://YOUR_REPO_URL.git edcNITD-website
cd edcNITD-website

# Checkout deployment branch
git checkout aws

# Put your data in place (from backups)
# - Copy website/staticfiles/*  website/media/*  website/db.sqlite3

# Build images
docker compose build

# Collect static (one-shot)
docker compose run --rm web python website/manage.py collectstatic --noinput

# Start services
docker compose up -d

# Check logs
docker compose logs -f --tail=200
```

Now browse `http://YOUR_SERVER_IP/`.

## HTTPS (optional, requires domain)
1) Update `nginx/default-ssl.conf` to replace `YOUR_DOMAIN` with your domain
2) Create DH params (once):
```bash
openssl dhparam -out nginx/ssl-dhparams.pem 2048
```
3) Create Certbot webroot dir and temporary HTTP config:
```bash
mkdir -p nginx/certs /var/www/certbot
sudo chown -R $USER:$USER nginx
```
4) Stop nginx service if any host service is running (not docker):
```bash
sudo systemctl stop nginx || true
```
5) Request certificate (webroot):
```bash
docker run --rm -it \
  -v $(pwd)/nginx/certs:/etc/letsencrypt \
  -v /var/www/certbot:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d YOUR_DOMAIN --email you@example.com --agree-tos --no-eff-email
```
6) Switch Nginx config to SSL inside `docker-compose.yml` by mapping `nginx/default-ssl.conf` instead of `default.conf` (or overwrite the file). Then restart:
```bash
docker compose restart nginx
```
7) Auto-renew cron (host):
```bash
(crontab -l 2>/dev/null; echo "0 3 * * * docker run --rm -v $(pwd)/nginx/certs:/etc/letsencrypt -v /var/www/certbot:/var/www/certbot certbot/certbot renew && docker compose reload nginx") | crontab -
```

## Notes
- Env vars: set `EMAIL` and `EMAIL_PASSWORD` in `docker-compose.yml` if needed for SMTP.
- If using a different DB later, change `DATABASES` in `website/website/settings.py` and remove the sqlite bind mount.
- To update:
```bash
git pull
docker compose build --no-cache
docker compose up -d
```

# Certbot: Obtaining and Renewing Certificates

This guide explains how to obtain and renew TLS certificates for Nginx using Certbot.

## Install Certbot

- Debian/Ubuntu:
  - `sudo apt-get update && sudo apt-get install -y certbot python3-certbot-nginx`
- RHEL/CentOS (via EPEL or snap):
  - `sudo yum install -y certbot` (or use `snap install --classic certbot`)

## Per-Subdomain Certificate (HTTP-01)

```bash
sudo certbot --nginx -d api.example.com
```

- Certbot edits Nginx config and reloads automatically
- Verify: `curl -I https://api.example.com`

## Wildcard Certificate (DNS-01)

```bash
sudo certbot certonly --manual --preferred-challenges dns \
  -d "*.example.com" -d example.com
```

- Follow prompts to create a TXT record at `_acme-challenge.example.com`
- After issuance, install paths will be under `/etc/letsencrypt/live/example.com/`

## Use Certificates in Nginx

```nginx
ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
```

## Automatic Renewal

- Check timer: `systemctl list-timers | grep certbot`
- Dry-run test: `sudo certbot renew --dry-run`
- Post-renew hook to reload Nginx:
  - `/etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh`

```bash
#!/usr/bin/env bash
sudo nginx -t && sudo systemctl reload nginx
```

## Troubleshooting

- Port 80 must be open for HTTP-01
- DNS propagation delays affect DNS-01 issuance
- Use `--nginx` plugin for automatic config where possible
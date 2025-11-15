# DevOpss

A lightweight, batteries-included template to bootstrap a modern DevOps toolchain on any green-field project.

## Quick Start

- Prepare a secure VPS (Ubuntu/Debian recommended)
- Deploy your app behind Nginx with TLS and sane defaults
- Copy, paste, and edit the provided configs; reload services and verify

## Why This Template

- Security-first defaults: TLS, strict headers, rate limiting, and basic auth
- Copy-paste deploys: minimal edits for domain, paths, and upstream ports
- Production-friendly: systemd, Nginx, Certbot, and predictable logging

## Secure VPS Bootstrap

1) System hardening

```bash
sudo apt update && sudo apt upgrade -y
sudo adduser appuser && sudo usermod -aG sudo appuser
sudo apt install -y nginx certbot python3-certbot-nginx fail2ban
sudo ufw allow OpenSSH && sudo ufw allow "Nginx Full" && sudo ufw enable
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl reload ssh
```

2) App process (example: Django via Gunicorn)

```bash
# create app directory owned by non-root
sudo mkdir -p /var/www/django && sudo chown -R appuser:www-data /var/www/django
# create systemd socket/service (adjust paths)
sudo tee /etc/systemd/system/gunicorn.socket >/dev/null <<'EOF'
[Unit]
Description=gunicorn socket
[Socket]
ListenStream=/run/gunicorn.sock
[Install]
WantedBy=sockets.target
EOF

sudo tee /etc/systemd/system/gunicorn.service >/dev/null <<'EOF'
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=appuser
Group=www-data
WorkingDirectory=/var/www/django
ExecStart=/var/www/django/venv/bin/gunicorn --workers 4 --bind unix:/run/gunicorn.sock project.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now gunicorn.socket
```

3) Nginx reverse proxy with TLS and security

```nginx
# /etc/nginx/sites-available/django.conf
server {
    listen 80;
    server_name example.com .example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com .example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    access_log /var/log/nginx/django_access.log;
    error_log  /var/log/nginx/django_error.log warn;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy no-referrer-when-downgrade;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()";
    add_header X-XSS-Protection "1; mode=block";
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data:; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self';";

    client_max_body_size 100M;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    location /static { alias /var/www/django/static; expires 7d; add_header Cache-Control "public, max-age=604800"; }
    location /media  { alias /var/www/django/media;  expires 1d; }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable and reload:

```bash
sudo ln -s /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled/django.conf
sudo nginx -t && sudo systemctl reload nginx
```

4) TLS certificates

```bash
sudo certbot --nginx -d example.com -d www.example.com
sudo certbot renew --dry-run
```

5) Optional: protect sensitive paths with Basic Auth

```bash
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd_admin admin
# then wrap your admin/API location with:
# location ^~ /admin { auth_basic "Admin"; auth_basic_user_file /etc/nginx/.htpasswd_admin; include proxy_params; proxy_pass http://unix:/run/gunicorn.sock; }
sudo nginx -t && sudo systemctl reload nginx
```

## Security Checklist

- Non-root user for app processes; restrict ownership and permissions
- SSH key auth only; disable passwords; rotate keys regularly
- Firewall `ufw` permit only `22`, `80`, `443`; close everything else
- TLS enforced; HSTS and OCSP stapling where supported
- Strict headers and minimal exposure; deny frames; limit referrers
- Basic Auth for admin/API; optionally pair with IP allowlists
- Rate limit and connection limit to deter abuse
- Fail2ban monitoring Nginx logs; ban on repeated failures
- Log to `/var/log/nginx/*`; add logrotate; watch for anomalies
- Backups for configs and certificates stored securely

## Repository Map

- `docs/nginx/django.conf`: hardened Nginx template with headers, limits, upstreams
- `docs/nginx/TLS.md`: TLS settings, HSTS, OCSP
- `docs/nginx/CERTBOT.md`: certificate issuance and renewal
- `docs/nginx/SECURITY.md`: security hardening tips and examples
- `docs/nginx/SUBDOMAINS.md`: wildcard and per-subdomain patterns
- `docs/nginx/TROUBLESHOOTING.md`: quick diagnostics
- `docs/vps/django_nginx.md`: end-to-end VPS setup for Django + Gunicorn
- `src/nginx/django_services.conf`: multi-upstream example and HTTPS redirect

## Verification

- Config test and reload: `sudo nginx -t && sudo systemctl reload nginx`
- Health check: `curl -I https://example.com/` and `curl -I https://example.com/healthz`
- Admin/API auth: `curl -I -u user:pass https://example.com/admin/`

## References

- Security headers block: `docs/nginx/django.conf:41` and surrounding lines
- Upstream header forwarding: `docs/nginx/django.conf:120`
- Subdomain server examples: `docs/nginx/SUBDOMAINS.md:42`


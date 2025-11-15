# Nginx Subdomain Setup

This guide explains how to serve multiple subdomains on a single server using Nginx, including SSL/TLS, HTTP→HTTPS redirection, and per-subdomain customization.

## Prerequisites

- DNS records pointing subdomains to your server IP (A/AAAA)
- Open ports `80` (HTTP) and `443` (HTTPS)
- Valid SSL certificates for each subdomain or a wildcard certificate
- Nginx installed and enabled

## Approaches

- Individual subdomain certificates (HTTP-01): easiest with `certbot --nginx -d sub.example.com`
- Wildcard certificate (DNS-01): requires DNS provider plugin (e.g., Cloudflare/Route53)

## Obtain Certificates

- Per subdomain:
  - `sudo certbot --nginx -d sub.example.com`
- Wildcard (example using manual DNS challenge):
  - `sudo certbot certonly --manual --preferred-challenges dns -d "*.example.com" -d example.com`
  - Create the TXT record as instructed, then proceed

> Replace `example.com` with your domain.

## Nginx Configuration Patterns

### 1) Redirect HTTP to HTTPS for all subdomains

```nginx
server {
    listen 80;
    server_name example.com .example.com;
    return 301 https://$host$request_uri;
}
```

### 2) Wildcard subdomains served by one HTTPS block

```nginx
server {
    listen 443 ssl http2;
    server_name example.com .example.com;

    ssl_certificate /etc/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;

    # Upstream defined elsewhere (see django.conf)
    location / {
        include proxy_params;
        proxy_pass http://django_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Optional: protect admin globally
    location ^~ /admin {
        auth_basic "Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd_admin;
        include proxy_params;
        proxy_pass http://django_backend;
    }
}
```

### 3) Dedicated server block per subdomain

```nginx
server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /etc/ssl/certs/api.example.com.crt;
    ssl_certificate_key /etc/ssl/private/api.example.com.key;

    location / {
        include proxy_params;
        proxy_pass http://django_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Optional: basic auth for API
    location ^~ /api {
        auth_basic "API Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd_api;
        include proxy_params;
        proxy_pass http://django_backend;
    }
}
```

## Upstream Definition

Place in a common file (e.g., `django.conf`) and reference from server blocks:

```nginx
upstream django_backend {
    server 127.0.0.1:8000 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8001 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:9000 backup;
    keepalive 64;
}
```

## Enable Sites

- Save the configuration under `/etc/nginx/sites-available/<name>.conf`
- Symlink to sites-enabled:
  - `sudo ln -s /etc/nginx/sites-available/<name>.conf /etc/nginx/sites-enabled/<name>.conf`
- Test and reload:
  - `sudo nginx -t && sudo systemctl reload nginx`

## Verification

- DNS resolution:
  - `dig +short sub.example.com`
- HTTP→HTTPS redirect:
  - `curl -I http://sub.example.com`
- HTTPS app response:
  - `curl -I https://sub.example.com/`
- Auth prompts where enabled:
  - `curl -I -u user:pass https://sub.example.com/admin/`

## Tips

- Use `server_name .example.com;` to match all subdomains; add a separate block for `example.com` (apex) if needed
- Keep `proxy_set_header Host $host;` to let the Django app detect the requested subdomain
- For per-subdomain behavior, add dedicated server blocks or route in the app based on `Host`
- Automate certificate renewals with `certbot renew` via a systemd timer or cron
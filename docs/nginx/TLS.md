# TLS/SSL Configuration for Nginx

This guide covers production TLS settings, certificate installation, wildcard certs, renewal, and security enhancements like HSTS and OCSP stapling.

## Certificates

- Single domain: `/etc/ssl/certs/example.com.crt` and `/etc/ssl/private/example.com.key`
- Chain file (if required): `/etc/ssl/certs/example.com.chain.crt`
- Wildcard: obtain `*.example.com` via DNS-01 (see `CERTBOT.md`)

## Nginx TLS Block

```nginx
server {
    listen 443 ssl http2;
    server_name example.com .example.com;

    ssl_certificate /etc/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';

    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/certs/example.com.chain.crt;

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}
```

## Renewal

- Certbot handles renewal automatically via systemd timer:
  - `sudo systemctl list-timers | grep certbot`
- Manual renew (test):
  - `sudo certbot renew --dry-run`

## Tips

- Use HTTP→HTTPS redirect server to force TLS
- Keep private keys readable only by root: `chmod 600 /etc/ssl/private/*.key`
- Monitor expiry: `openssl x509 -enddate -noout -in /etc/ssl/certs/example.com.crt`
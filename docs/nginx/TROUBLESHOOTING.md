# Troubleshooting Nginx + Django

Common issues and quick diagnostics.

## 502 Bad Gatewayq

- Gunicorn/ASGI not running or listening on expected ports
- Test upstream locally:
  - `curl -I http://127.0.0.1:8000/`
- Check Nginx error log:
  - `sudo tail -n 100 /var/log/nginx/django_error.log`

## 403 Forbidden

- Basic Auth enabled but credentials missing/invalid
- IP restrictions block your client
- Hidden files blocked (`location ~ /\.`)

## SSL Issues

- Mismatched certificate/key paths; verify files exist and readable by Nginx
- OCSP stapling requires chain/trusted cert; disable temporarily if failing

## Rate Limiting

- `limit_req`/`limit_conn` throttling; increase `burst` or per-location settings

## Config Test and Reload

- `sudo nginx -t && sudo systemctl reload nginx`

## SELinux/AppArmor

- Ensure Nginx allowed to read `/etc/nginx/.htpasswd_*` and `/etc/ssl/*`
- Adjust policies or contexts if enforced

## Health Checks

- Verify `/healthz`: `curl -I https://sub.example.com/healthz`
- Reduce `proxy_read_timeout` on health to fail fast

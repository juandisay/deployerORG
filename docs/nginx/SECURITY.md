# Security Hardening for Nginx

This guide summarizes common security measures for Nginx serving Django.

## Headers

```nginx
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options DENY;
add_header Referrer-Policy no-referrer-when-downgrade;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()";
add_header X-XSS-Protection "1; mode=block";
add_header Content-Security-Policy "default-src 'self'; img-src 'self' data:; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self';";
```

## Bot Protection

```nginx
map $http_user_agent $bad_bot {
    default 0;
    ~*(curl|wget|python-requests|scrapy) 1;
}

server {
    if ($bad_bot) { return 403; }
}
```

## Basic Auth

- Admin: `auth_basic_user_file /etc/nginx/.htpasswd_admin`
- API: `auth_basic_user_file /etc/nginx/.htpasswd_api`
- See `README.md` for password file creation

## IP Allow/Deny

```nginx
location ^~ /admin {
    allow 127.0.0.1;
    allow 192.168.0.0/16;
    deny all;
}
```

## Fail2ban Integration (Example)

- Install `fail2ban`
- Add jail monitoring `nginx-http-auth` and `nginx-botsearch`
- Point fail2ban to `/var/log/nginx/*` logs

## File Permissions

- `/etc/nginx/*.conf`: root-writable
- `/etc/nginx/.htpasswd_*`: `root` owner, `www-data` group, `chmod 640`
- Certificates: `*.key` files `chmod 600`, readable only by root
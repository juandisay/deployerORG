# Logging and Rotation

Configure access and error logging and rotate logs to avoid disk growth.

## Logging

```nginx
http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log  /var/log/nginx/error.log warn;
}
```

Per-server overrides:

```nginx
server {
    access_log /var/log/nginx/django_access.log main;
    error_log  /var/log/nginx/django_error.log warn;
}
```

## Logrotate

Create `/etc/logrotate.d/nginx`:

```text
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -s /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

## Tips

- Use separate files for API or admin blocks to analyze traffic patterns
- Adjust `error_log` level to `info` temporarily when debugging upstreams
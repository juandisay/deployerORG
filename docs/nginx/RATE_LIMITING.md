# Rate Limiting and Connection Limits

Use Nginx `limit_req` and `limit_conn` to mitigate abuse and control traffic per client IP.

## Define Zones (http context)

```nginx
limit_req_zone  $binary_remote_addr zone=req_limit_per_ip:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
```

## Apply to Locations

```nginx
location ^~ /api {
    limit_req zone=req_limit_per_ip burst=50 nodelay;
    limit_conn conn_limit_per_ip 50;
    include proxy_params;
    proxy_pass http://django_backend;
}

location ^~ /admin {
    limit_req zone=req_limit_per_ip burst=20 nodelay;
    limit_conn conn_limit_per_ip 20;
    include proxy_params;
    proxy_pass http://django_backend;
}
```

## Tips

- Use higher `burst` for endpoints that return small responses
- Log overload with `error_log` at `warn` level to audit throttling
- Consider per-method rates by using `map $request_uri` or `geo`
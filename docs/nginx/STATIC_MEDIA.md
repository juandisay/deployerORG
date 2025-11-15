# Static and Media Handling

Best practices for serving Django static and media files via Nginx.

## Paths

- Static: `/var/www/django/static`
- Media: `/var/www/django/media`

## Nginx Locations

```nginx
location /static {
    alias /var/www/django/static;
    expires 7d;
    add_header Cache-Control "public, max-age=604800";
}

location /media {
    alias /var/www/django/media;
    expires 1d;
    add_header Cache-Control "public, max-age=86400";
}
```

## Compression

```nginx
gzip on;
gzip_comp_level 5;
gzip_min_length 256;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

## Collectstatic

- Run collectstatic before deployment:
  - `DJANGO_ENV=production python manage.py collectstatic --no-input`
- Ensure correct ownership and permissions on `/var/www/django/*`
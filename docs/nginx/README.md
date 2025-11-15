# Nginx Basic Authentication Setup

This guide explains how to set up HTTP Basic Authentication for protecting Django endpoints behind Nginx. It covers generating credential files, installing them securely on the server, wiring them into the configuration, reloading Nginx, and verifying access.

## Prerequisites

- Nginx configuration references password files:
  - Admin: `auth_basic_user_file /etc/nginx/.htpasswd_admin`
  - API: `auth_basic_user_file /etc/nginx/.htpasswd_api`
- Access to the server with `sudo` privileges
- Tools to create password hashes:
  - Debian/Ubuntu: `sudo apt-get update && sudo apt-get install -y apache2-utils`
  - RHEL/CentOS: `sudo yum install -y httpd-tools`
  - macOS (for local generation): `brew install httpd` or use the script below

## Option A: Generate Locally (Recommended)

Use the provided script to generate a secure password file without needing `htpasswd`:

```bash
bash gibran-backend/deployment/nginx/generate_htpasswd_admin.sh admin
```

This will create `.htpasswd_admin` in your working directory. You can pass a custom output path as the second argument:

```bash
bash gibran-backend/deployment/nginx/generate_htpasswd_admin.sh admin gibran-backend/deployment/nginx/.htpasswd_admin
```

Copy the file to the server and install it for Nginx:

```bash
scp gibran-backend/deployment/nginx/.htpasswd_admin <ssh_user>@<host>:/tmp/.htpasswd_admin
ssh <ssh_user>@<host> \
  'sudo mv /tmp/.htpasswd_admin /etc/nginx/.htpasswd_admin \
   && sudo chown root:www-data /etc/nginx/.htpasswd_admin \
   && sudo chmod 640 /etc/nginx/.htpasswd_admin'
```

Repeat for the API file if needed:

```bash
bash gibran-backend/deployment/nginx/generate_htpasswd_admin.sh api gibran-backend/deployment/nginx/.htpasswd_api
scp gibran-backend/deployment/nginx/.htpasswd_api <ssh_user>@<host>:/tmp/.htpasswd_api
ssh <ssh_user>@<host> \
  'sudo mv /tmp/.htpasswd_api /etc/nginx/.htpasswd_api \
   && sudo chown root:www-data /etc/nginx/.htpasswd_api \
   && sudo chmod 640 /etc/nginx/.htpasswd_api'
```

> Replace `www-data` with your Nginx group if different (e.g. `nginx`).

## Option B: Generate Directly on the Server

Create or update the admin password file:

```bash
sudo htpasswd -c /etc/nginx/.htpasswd_admin <admin_user>    # create new file
sudo htpasswd    /etc/nginx/.htpasswd_admin <admin_user>    # add/modify user
```

Create or update the API password file:

```bash
sudo htpasswd -c /etc/nginx/.htpasswd_api <api_user>
sudo htpasswd    /etc/nginx/.htpasswd_api <api_user>
```

Secure the files:

```bash
sudo chown root:www-data /etc/nginx/.htpasswd_admin /etc/nginx/.htpasswd_api
sudo chmod 640 /etc/nginx/.htpasswd_admin /etc/nginx/.htpasswd_api
```

## Wire Into Nginx and Reload

Ensure your Nginx config uses the files:

```nginx
location ^~ /admin {
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd_admin;
    # ... proxy settings
}

location ^~ /api {
    auth_basic "API Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd_api;
    # ... proxy settings
}
```

Test config and reload:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

## Verify

Check protected endpoints:

```bash
curl -I -u <admin_user>:<password> https://your-sub.example.com/admin/
curl -I -u <api_user>:<password>   https://your-sub.example.com/api/
```

Expect `401 Unauthorized` without credentials and `200 OK` with valid credentials.

## User Management

- Change password: `sudo htpasswd /etc/nginx/.htpasswd_admin <admin_user>`
- Remove a user: edit the file and delete the line, then reload Nginx.

## Security Tips

- Do not commit `.htpasswd_*` files to the repository; keep them only on the server under `/etc/nginx/`.
- Use strong, random passwords; rotate regularly.
- Combine with IP allowlists where appropriate for sensitive paths.
- Ensure only Nginx group can read the files (`chmod 640`).

## Troubleshooting

- 401 for correct credentials: verify `auth_basic_user_file` path and permissions; ensure Nginx can read the file.
- No prompt: confirm the `location` blocks match requested paths and are not overridden.
- Hash issues: regenerate credentials using `htpasswd` or the provided script and reload Nginx.
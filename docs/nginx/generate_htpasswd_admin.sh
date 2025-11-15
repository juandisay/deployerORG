#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Default variables
USERNAME="${1:-admin}"
OUTPUT_FILE="${2:-.htpasswd_admin}"

## generate_salt: produce a random alphanumeric salt for APR1 hashing
generate_salt() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 8
}

## prompt_password: securely prompt for a password and confirmation
prompt_password() {
  local pass1 pass2
  read -r -s -p "Enter password for user '${USERNAME}': " pass1
  echo
  read -r -s -p "Confirm password: " pass2
  echo
  if [ "$pass1" != "$pass2" ]; then
    echo "Passwords do not match" >&2
    exit 1
  fi
  echo "$pass1"
}

PASSWORD="$(prompt_password)"
SALT="$(generate_salt)"

# Generate APR1 (Apache MD5) hash using openssl
HASH="$(openssl passwd -apr1 -salt "$SALT" "$PASSWORD")"

echo "${USERNAME}:${HASH}" >"${OUTPUT_FILE}"
chmod 600 "${OUTPUT_FILE}"

echo "Written ${OUTPUT_FILE}. Use: auth_basic_user_file /etc/nginx/.htpasswd_admin;"
echo "To install on server: sudo mv ${OUTPUT_FILE} /etc/nginx/.htpasswd_admin && sudo chmod 640 /etc/nginx/.htpasswd_admin"
#!/usr/bin/env bash
# Starts a local WordPress on http://localhost:8080 with the JWT plugin,
# the register endpoint and a demo user. Safe to run again.
set -euo pipefail
cd "$(dirname "$0")"

SITE_URL="${SITE_URL:-http://localhost:8080}"

docker compose up -d
until curl -fs -o /dev/null "$SITE_URL/wp-admin/install.php"; do sleep 2; done

wp() { docker compose run --rm -T cli wp "$@"; }

if ! wp core is-installed >/dev/null 2>&1; then
  wp core install --url="$SITE_URL" --title="JWT Auth Demo" \
    --admin_user=admin --admin_password=admin --admin_email=admin@example.com --skip-email
fi
wp plugin install jwt-authentication-for-wp-rest-api --activate
wp plugin activate jwt-auth-register
wp option update users_can_register 1
wp rewrite structure '/%postname%/'
wp user get demo >/dev/null 2>&1 || \
  wp user create demo demo@example.com --user_pass=demo1234 --display_name="Demo User" --role=subscriber

echo "WordPress ready at $SITE_URL (admin/admin, demo/demo1234)"

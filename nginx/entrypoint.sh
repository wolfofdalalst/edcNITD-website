#!/bin/sh
set -e

DOMAIN=${SERVER_NAME:-edcnitd.co.in}
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
TEMPLATES_DIR="/etc/nginx/templates"
CONF_DIR="/etc/nginx/conf.d"

if [ -f "${CERT_DIR}/fullchain.pem" ] && [ -f "${CERT_DIR}/privkey.pem" ]; then
  cp "${TEMPLATES_DIR}/default_ssl_redirect.conf" "${CONF_DIR}/default.conf"
  cp "${TEMPLATES_DIR}/ssl.conf" "${CONF_DIR}/ssl.conf"
else
  cp "${TEMPLATES_DIR}/default_plain.conf" "${CONF_DIR}/default.conf"
  rm -f "${CONF_DIR}/ssl.conf" || true
fi

exec nginx -g 'daemon off;'



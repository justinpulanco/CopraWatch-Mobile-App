#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run this one-time technician installer with sudo." >&2
  exit 1
fi

backend_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
run_user="${SUDO_USER:-}"
unit_template="$backend_dir/coprawatch.service"
python_bin="$backend_dir/.venv/bin/python"

if [[ -z "$run_user" || "$run_user" == "root" ]]; then
  echo "Run sudo from the Raspberry Pi account that will own CopraWatch files." >&2
  exit 1
fi
if [[ ! -x "$python_bin" ]]; then
  echo "Missing backend virtual environment: $python_bin" >&2
  echo "Provision the Pi dependencies and .venv before installing the service." >&2
  exit 1
fi
if [[ ! -f "$unit_template" ]]; then
  echo "Missing service template: $unit_template" >&2
  exit 1
fi

"$python_bin" -c 'import flask, picamera2, RPi.GPIO' || {
  echo "The backend environment is missing Flask, Picamera2, or RPi.GPIO." >&2
  exit 1
}

install -d -m 0750 -o "$run_user" -g "$run_user" /etc/coprawatch
if [[ ! -f /etc/coprawatch/coprawatch.env ]]; then
  api_key="$("$python_bin" -c 'import secrets; print(secrets.token_urlsafe(32))')"
  umask 077
  printf 'COPRAWATCH_API_KEY=%s\n' "$api_key" > /etc/coprawatch/coprawatch.env
  chown root:"$run_user" /etc/coprawatch/coprawatch.env
  chmod 0640 /etc/coprawatch/coprawatch.env
  echo "Generated an API key in /etc/coprawatch/coprawatch.env. Enter the same key in app Settings."
else
  echo "Keeping existing /etc/coprawatch/coprawatch.env and API key."
fi

sed \
  -e "s|@RUN_USER@|$run_user|g" \
  -e "s|@BACKEND_DIR@|$backend_dir|g" \
  "$unit_template" > /etc/systemd/system/coprawatch.service
chmod 0644 /etc/systemd/system/coprawatch.service

systemctl daemon-reload
systemctl enable --now coprawatch.service
systemctl --no-pager --full status coprawatch.service

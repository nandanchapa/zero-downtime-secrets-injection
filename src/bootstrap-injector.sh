#!/bin/bash
# 1. Fetch live secret payload from PAM via backend script
export APP_DB_USER="application_app"
export APP_DB_PASSWORD=$(python3 /usr/local/bin/vault_client.py \
  --endpoint "pam.company.com" \
  --api-key "REDACTED_API_KEY" \
  --system "TARGET_DATABASE_CLUSTER" \
  --account "application_app" | tr -d '"')
export APP_DB_HOST="127.0.0.1:5432"

# 2. Source baseline machine global environments if present
if [ -f /etc/sysconfig/app-server ]; then
    source /etc/sysconfig/app-server
fi

# 3. Replace current process space cleanly with the target server binary
# Environment Variable Precedence allows these exported variables to override flat configuration files natively.
exec /usr/share/application/bin/app-server \
  --config=/etc/application/app.ini \
  --pidfile=/run/application/sandbox.pid \
  --packaging=rpm \
  cfg:server.http_port=3001 \
  cfg:default.paths.logs=/var/log/application/sandbox.log

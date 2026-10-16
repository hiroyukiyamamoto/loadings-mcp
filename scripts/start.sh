#!/usr/bin/env bash
set -euo pipefail
public_port="${PORT:-8080}"
[[ "$public_port" =~ ^[0-9]{1,5}$ ]] && (( public_port > 0 && public_port < 65536 && public_port != 8081 )) || { echo 'Invalid PORT'; exit 1; }
mkdir -p /tmp/loadings-nginx/{body,proxy,fastcgi,uwsgi,scgi}
cat > /tmp/loadings-nginx/nginx.conf <<EOF
worker_processes 1;
pid /tmp/loadings-nginx/nginx.pid;
error_log /dev/stderr warn;
events { worker_connections 64; }
http {
  access_log off;
  client_body_temp_path /tmp/loadings-nginx/body;
  proxy_temp_path /tmp/loadings-nginx/proxy;
  fastcgi_temp_path /tmp/loadings-nginx/fastcgi;
  uwsgi_temp_path /tmp/loadings-nginx/uwsgi;
  scgi_temp_path /tmp/loadings-nginx/scgi;
  client_max_body_size 2m;
  client_body_timeout 5s;
  client_header_timeout 5s;
  keepalive_timeout 5s;
  limit_req_zone \$server_name zone=global:1m rate=60r/m;
  limit_req_status 429;
  server {
    listen 0.0.0.0:${public_port};
    server_name _;
    location = /mcp {
      limit_req zone=global burst=10 nodelay;
      proxy_pass http://127.0.0.1:8081;
      proxy_http_version 1.1;
      proxy_set_header Connection "";
      proxy_buffering off;
      proxy_request_buffering on;
      proxy_connect_timeout 1s;
      proxy_send_timeout 5s;
      proxy_read_timeout 25s;
    }
    location / { return 404; }
  }
}
EOF
nginx -t -c /tmp/loadings-nginx/nginx.conf
PORT=8081 Rscript --vanilla R/server.R &
r_pid=$!
proxy_pid=""
cleanup() { kill "$r_pid" ${proxy_pid:+"$proxy_pid"} 2>/dev/null || true; wait "$r_pid" ${proxy_pid:+"$proxy_pid"} 2>/dev/null || true; }
trap cleanup EXIT
trap 'exit 0' TERM INT
ready=false
for i in {1..100}; do
  kill -0 "$r_pid" 2>/dev/null || exit 1
  if ( : < /dev/tcp/127.0.0.1/8081 ) 2>/dev/null; then ready=true; break; fi
  sleep 0.1
done
"$ready" || { echo 'R transport failed to start'; exit 1; }
nginx -c /tmp/loadings-nginx/nginx.conf -g 'daemon off;' &
proxy_pid=$!
# Fail the container if either process exits, allowing Cloud Run to replace it.
wait -n "$r_pid" "$proxy_pid"
exit 1

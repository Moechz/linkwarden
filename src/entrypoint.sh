#!/bin/sh
# TOS wrapper: Linkwarden needs NEXTAUTH_SECRET, but hard-coding a secret in the
# compose file is forbidden. Generate it on first start and keep it on the
# persistent storage volume, then run the upstream entrypoint unchanged.
set -u
set -e
mkdir -p /data/storage
F=/data/storage/nextauth_secret
if [ ! -s "$F" ]; then
  head -c 32 /dev/urandom | base64 | tr -d '\n' > "$F"
fi
export NEXTAUTH_SECRET="$(cat "$F")"
exec docker-entrypoint.sh sh -c 'export PATH=/data/node_modules/.bin:$PATH && prisma migrate deploy --schema=/data/packages/prisma/schema.prisma && exec concurrently -k -n web,worker "cd /data/apps/web && exec next start" "cd /data/apps/worker && exec tsx worker.ts"'

#!/bin/sh
set -e

# Logging helper
log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1"
}

log "INFO: Initializing container entrypoint..."

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

log "INFO: Target node user UID: $PUID, GID: $PGID"

# Adjust the node user's UID/GID if they differ from the runtime request
# and fix volume ownership only when a remap is needed
changed=0

# Check if we are running as root to perform usermod/groupmod
if [ "$(id -u)" -eq 0 ]; then
  if [ "$(id -u node)" -ne "$PUID" ]; then
      log "INFO: Updating node UID to $PUID"
      usermod -o -u "$PUID" node
      changed=1
  fi

  if [ "$(id -g node)" -ne "$PGID" ]; then
      log "INFO: Updating node GID to $PGID"
      groupmod -o -g "$PGID" node
      usermod -g "$PGID" node
      changed=1
  fi

  if [ "$changed" = "1" ]; then
      log "INFO: Permissions changed, updating /paperclip ownership..."
      chown -R node:node /paperclip
  fi
  
  log "INFO: Switching to node user and executing: $@"
  exec gosu node "$@"
else
  log "WARNING: Not running as root. Skipping UID/GID remapping and continuing as $(id -u -n)."
  # Note: In environments like DO App Platform, the container may run as a non-root user.
  # If we're already not root, just exec directly.
  exec "$@"
fi

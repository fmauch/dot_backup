#!/bin/bash
set -e

# Default values to be overwritten in config file
BACKUP_UUID=""
BACKUP_MOUNT=""
BACKUP_REPO=""
## Use one of the following in your config file or make sure it is available in the sourced env.
## Otherwise restic will ask for the password on stdin, which is not suitable for an automatic
## backup.
# export RESTIC_PASSWORD_COMMAND=""
# export RESTIC_PASSWORD_FILE=""

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/restic"
CONFIG_FILE="$CONFIG_HOME/restic_wrapper_config.sh"
EXCLUDE_FILE="$CONFIG_HOME/restic_excludes.txt"
INCLUDE_FILE="$CONFIG_HOME/restic_includes.txt"

#DRY_RUN="--dry-run"
DRY_RUN=""

if [ -e $CONFIG_FILE ]; then
  source $CONFIG_FILE
fi

log() {
  echo "$*"
}

err() {
  printf "ERROR: %s\n" "$*" >&2
}


validate_non_empty() {
  if [ -z "$1" ]; then
    err "$2 is empty which is not allowed"
    exit 1
  fi
}

# Validate correct config
validate_non_empty $BACKUP_UUID "BACKUP_UUID"
validate_non_empty $BACKUP_MOUNT "BACKUP_MOUNT"
validate_non_empty $BACKUP_REPO "BACKUP_REPO"



notify_from_file() {
  notify-send -a "restic backup" -t 6000 "$1" "$(cat $2)"
}

# Check for backup device present
volume="/dev/disk/by-uuid/$BACKUP_UUID"
if [ ! -e $volume ]; then
  err "No disk with UUID '$BACKUP_UUID" found. Exiting.
  exit 0 # We do not want the systemd job to fail
fi

if [ ! -e $BACKUP_MOUNT ]; then
  mkdir -p $BACKUP_MOUNT
fi

# TODO: Mount
if mountpoint -q $BACKUP_MOUNT ; then
  echo "Mountpoint already mounted"
else
  mount $volume $BACKUP_MOUNT
fi

# Perform backup
restic -r "$BACKUP_REPO" \
  --verbose backup \
  --files-from "$INCLUDE_FILE" \
  --exclude-file "$EXCLUDE_FILE"  \
  $DRY_RUN | tee /tmp/backup.output
notify_from_file "Backup created" /tmp/backup.output

# Forget old snapshots
restic -r "$BACKUP_REPO" \
  --verbose forget \
  --keep-hourly 6 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12 \
  --keep-yearly 5 \
  --prune \
  $DRY_RUN | tee /tmp/backup_forget.output

notify_from_file "Backup cleaned" /tmp/backup_forget.output

restic -r "$BACKUP_REPO" check

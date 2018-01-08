#!/bin/sh
set -eo pipefail

_set_config() {
  export BORG_CACHE_DIR='/borg/cache'
  export BORG_CONFIG_DIR='/borg/config'
  export BORG_KEYS_DIR='/borg/config/keys'
  if [ -f "$SSHFS_IDENTITY_FILE" ]; then
    export BORG_RSH="ssh -i $SSHFS_IDENTITY_FILE -o StrictHostKeyChecking=no"
  else
    export BORG_RSH="ssh -i /borg/config/keys/id_rsa -o StrictHostKeyChecking=no"
  fi

  if [ -n "${BORG_SHOWRC}" ] && [ "${BORG_SHOWRC}" = "1" ] ; then
    SHOWRC_CMD="--show-rc"
  else
    SHOWRC_CMD=""
  fi
}

_gensshkey() {
  if [ "$1" = 'gen-ssh-key' ]; then
    if [ -n "${SSHFS_IDENTITY_FILE:-}" ]; then
      if [ -f "$SSHFS_IDENTITY_FILE" ]; then
        echo >&2 'error: File for SSHFS_IDENTITY_FILE already exists'
        exit 1
      else
        ssh-keygen -t rsa -b 2048 -N '' -f "$SSHFS_IDENTITY_FILE"
        cat "${SSHFS_IDENTITY_FILE}.pub"
        exit 0
      fi
    else
      ssh-keygen -t rsa -b 2048 -N '' -f "/borg/config/keys/id_rsa"
    fi
  fi
}

_init() {
  _set_config
  
  if [ -n "${BORG_PASSPHRASE}" ] || [ -n "${BORG_PASSCOMMAND}" ]; then
    INIT_ENCRYPTION="--encryption=repokey"
  else
    INIT_ENCRYPTION="--encryption=none"
    echo >&1 ' warning: Not using encryption. If you want to encrypt files, set $BORG_PASSPHRASE variable.'
  fi

  exec borg "$@" $SHOWRC_CMD $INIT_ENCRYPTION
}

_create() {
  _set_config
  if [ -n "${BORG_COMPRESSION}" ]; then
    COMPRESSION_CMD="--compression=${BORG_COMPRESSION}"
  else
    COMPRESSION_CMD=""
  fi

  if [ ! -n "${BORG_BACKUP_DIR}" ]; then
    echo >&2 ' error: Variable $BORG_BACKUP_DIR is required. '
    exit 1
  fi

  DEFAULT_ARCHIVE="${HOSTNAME}_$(date +%Y-%m-%d)"
  ARCHIVE="${ARCHIVE:-$DEFAULT_ARCHIVE}"

  exec borg "$@" --stats $SHOWRC_CMD $COMPRESSION_CMD ::"${ARCHIVE}" ${BORG_BACKUP_DIR}

  if [ -n "${BORG_PRUNE}" ]; then
    if [ -n "${PRUNE_PREFIX}" ]; then
      PRUNE_PREFIX="--prefix=${PRUNE_PREFIX}"
    else
      PRUNE_PREFIX=""
    fi

    exec borg prune --stats $SHOWRC_CMD ${PRUNE_PREFIX} --keep-daily=$KEEP_DAILY --keep-weekly=$KEEP_WEEKLY --keep-monthly=$KEEP_MONTHLY --keep-yearly=$KEEP_YEARLY
  fi
}

_prune() {
  _set_config

  if [ -n "${PRUNE_PREFIX}" ]; then
    PRUNE_PREFIX="--prefix=${PRUNE_PREFIX}"
  else
    PRUNE_PREFIX=""
  fi

  exec borg "$@" --stats $SHOWRC_CMD ${PRUNE_PREFIX} --keep-daily=${KEEP_DAILY} --keep-weekly=${KEEP_WEEKLY} --keep-monthly=${KEEP_MONTHLY} --keep-yearly=${KEEP_YEARLY}
}

_param() {
  _set_config

  exec borg "$@"
}

export BORG_REPO

case "$1" in
  gen-ssh-key) _gensshkey "$@" ;;
  init) _init "$@" ;;
  create) _create "$@" ;;
  prune) _prune "$@" ;;
  list|rename|diff|delete|info|check|mount|unmount|upgrade|recreate|break-lock|with-lock) _param "$@" ;;
  *) exec "$@" ;;
esac

exit 0

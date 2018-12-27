#!/bin/sh
set -e

echo "Starting container ..."

RESTIC_CMD=restic

if [ -n "${ROOT_CERT}" ]; then
	RESTIC_CMD="${RESTIC_CMD} --cert ${ROOT_CERT}"
fi

# handle ssh config and keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ ! -z "$SSH_CONFIG" ] ; then
  echo "$SSH_CONFIG" > ~/.ssh/config
  chmod 600 ~/.ssh/config
  unset SSH_CONFIG
fi
if [ ! -z "$SSH_CONFIG_PATH" && ! -a ~/.ssh/config ]; then
  cp "$SSH_CONFIG_PATH" ~/.ssh/config
  chmod 600 ~/.ssh/config
  unset SSH_CONFIG_PATH
fi
if [ ! -z "$SSH_PRIVATE_RSA_KEY" ]; then
  echo "$SSH_PRIVATE_RSA_KEY" > ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  unset SSH_PRIVATE_RSA_KEY
fi
if [ ! -z "$SSH_PRIVATE_RSA_KEY_PATH" && ! -a ~/.ssh/id_rsa ]; then
  cp "$SSH_PRIVATE_RSA_KEY_PATH" ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  unset SSH_PRIVATE_RSA_KEY_PATH
fi
if [ -n "${NFS_TARGET}" ]; then
    echo "Mounting NFS based on NFS_TARGET: ${NFS_TARGET}"
    mount -o nolock -v ${NFS_TARGET} /mnt/restic
fi

if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
    echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
    restic init | true
fi

if [ -n "${BACKUP_CRON}" ]; then
	echo "Setup backup cron job with cron expression BACKUP_CRON: '${BACKUP_CRON}'"
	echo "${BACKUP_CRON} /bin/backup >> /var/log/cron.log 2>&1" > /var/spool/cron/crontabs/root

	# Make sure the file exists before we start tail
	touch /var/log/cron.log

	# start the cron deamon
	crond

	echo "Container started."

	tail -fn0 /var/log/cron.log
else
	echo "Starting immediate non-scheduled backup..."
	/bin/backup >> /var/log/backup-immediate.log 2>&1

	echo "Container started."

	tail -fn0 /var/log/backup-immediate.log
fi

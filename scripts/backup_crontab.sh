#!/usr/bin/env bash
BACKUP_DIRECTORY="${HOME}/Backup/cron"

if [ ! -e "${BACKUP_DIRECTORY}" ]; then
	mkdir -p ${BACKUP_DIRECTORY}
fi

crontab -l > ${BACKUP_DIRECTORY}/$(date '+%Y%m%d').txt
find ${HOME}/crontab_backup -mtime +7 -name '*.txt' -exec rm -rf {} \;

rsync -av --delete ${BACKUP_DIRECTORY} uglyboy.cn:/srv/Base/Data/Remote

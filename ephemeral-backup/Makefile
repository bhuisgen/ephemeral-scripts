all: install

.PHONY: backup install start stop uninstall

install:
	stat /etc/systemd/system/ephemeral-disk.service > /dev/null 2>&1 || (echo "ephemeral-disk.service not found" ; exit 1)
	stat ephemeral-backup > /dev/null 2>&1 || (echo "ephemeral-backup file not found" ; exit 1)
	stat backup > /dev/null 2>&1 || (echo "backup file not found" ; exit 1)
	stat ephemeral-backup.sh > /dev/null 2>&1 || (echo "ephemeral-backup.sh file not found" ; exit 1)
	stat ephemeral-backup.timer > /dev/null 2>&1 || (echo "ephemeral-backup.timer file not found" ; exit 1)
	cp ephemeral-backup.sh /etc/ephemeral-scripts/
	chmod 750 /etc/ephemeral-scripts/ephemeral-backup.sh
	cp backup /etc/ephemeral-scripts/
	chmod 640 /etc/ephemeral-scripts/backup
	cp ephemeral-backup.service /etc/systemd/system/
	cp ephemeral-backup.timer /etc/systemd/system/
	cp ephemeral-backup /etc/default/
	systemctl daemon-reload

uninstall:
	rm -f /etc/ephemeral-scripts/ephemeral-backup.sh
	rm -f /etc/ephemeral-scripts/backup
	rm -f /etc/systemd/system/ephemeral-backup.timer
	rm -f /etc/systemd/system/ephemeral-backup.service
	rm -f /etc/default/ephemeral-disk
	systemctl daemon-reload

enable:
	systemctl enable ephemeral-backup.timer

disable:
	systemctl disable ephemeral-backup.timer

start:
	systemctl start ephemeral-backup.timer

stop:
	systemctl stop ephemeral-backup.timer

backup:
	systemctl start ephemeral-backup.service

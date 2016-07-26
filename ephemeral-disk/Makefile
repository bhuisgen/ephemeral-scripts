all: install

.PHONY: disable enable install start stop uninstall

install:
	stat ephemeral-disk > /dev/null 2>&1 || (echo "ephemeral-disk file not found" ; exit 1)
	stat ephemeral-units.service > /dev/null 2>&1 || (echo "ephemeral-units.service file not found" ; exit 1)
	mkdir -p /etc/ephemeral-scripts/
	cp ephemeral-disk_start /etc/ephemeral-scripts/
	chmod 750 /etc/ephemeral-scripts/ephemeral-disk_start
	cp ephemeral-disk_stop /etc/ephemeral-scripts/
	chmod 750 /etc/ephemeral-scripts/ephemeral-disk_stop
	cp ephemeral-disk.service /etc/systemd/system/
	cp ephemeral-data.mount /etc/systemd/system/
	cp ephemeral-units.service /etc/systemd/system/
	cp ephemeral-disk /etc/default/
	systemctl daemon-reload

uninstall:
	rm -f /etc/ephemeral-scripts/ephemeral-disk_start
	rm -f /etc/ephemeral-scripts/ephemeral-disk_stop
	rmdir /etc/ephemeral-scripts/
	rm -f /etc/systemd/system/ephemeral-disk.service
	rm -f /etc/systemd/system/ephemeral-data.mount
	rm -f /etc/systemd/system/ephemeral-units.service
	rm -f /etc/default/ephemeral-disk
	systemctl daemon-reload

enable:
	systemctl enable ephemeral-disk.service
	systemctl enable ephemeral-data.mount
	systemctl enable ephemeral-units.service

disable:
	systemctl disable ephemeral-units.service
	systemctl disable ephemeral-data.mount
	systemctl disable ephemeral-disk.service

start:
	systemctl start ephemeral-disk.service
	systemctl start ephemeral-data.mount
	systemctl start ephemeral-units.service

stop:
	systemctl stop ephemeral-units.service
	systemctl stop ephemeral-data.mount
	systemctl stop ephemeral-disk.service

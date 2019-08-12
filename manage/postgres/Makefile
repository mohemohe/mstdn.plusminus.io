.PHONY: build clean install uninstall

build:
	$(eval CURRENT_USER := $(shell whoami))
	$(eval CURRENT_DIR := $(shell pwd))
	cp -f template.postgres_backup.service postgres_backup.service
	sed -i "s|###CURRENT_DIR###|$(CURRENT_DIR)|g" postgres_backup.service
	sed -i "s|###CURRENT_USER###|$(CURRENT_USER)|g" postgres_backup.service

clean:
	rm postgres_backup.service || true

install:
	cp postgres_backup.service /etc/systemd/system/
	cp postgres_backup.timer /etc/systemd/system/
	systemctl daemon-reload
	systemctl enable --now postgres_backup.timer

uninstall:
	systemctl disable --now postgres_backup.timer
	rm /etc/systemd/system/postgres_backup.service
	rm /etc/systemd/system/postgres_backup.timer
	systemctl daemon-reload


# borg-backup-docker-lvm-systemd
Systemd scripts for backing up lvm-volumes in docker with borg

It depends on the borg-backup docker-container from https://github.com/pschiffe/docker-borg

## Usage
1. Use `./install` to link the systemd-service and timer
2. To set up a new backup **service**, use the `systemctl start borg-backup@**service**.timer` syntax
3. Set up the timer with `systemctl edit borg-backup@**service**.timer` and use this style:
```bash
[Timer]
  OnCalendar=*-*-* 01:00:00
```
4. Set up the **service** with `systemctl edit borg-backup@**service**.service` ,for example, to backup volume **test_data** and **test_db**:
```BASH
[Service]
Environment="LVM_VOLUMES=**test_data** **test_db**"
```
5. If wanted, you can overwrite the `BORG_CHECK`Environment variable for prune and repo-check
```BASH
[Service]
Environment="[...]"
Environment="BORG_CHECK=true"
```

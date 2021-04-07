# BTRFS Recovery Procedures

Credits: Richard Brown

The below are the steps I would recommend for ANY btrfs issue, smart people reading dmesg or syslog can probably figure out which of these steps they'd need to skip to in order to fix their particular problem.

# Safe part

1. Boot to a suitable alternative system, such as a different installation, a live DVD, or an installation DVD. The installation DVD for the version of Linux you are running is usually the best choice as it will certainly use the same kernel/btrfs version.
2. Go to a suitable console and make sure you do the below as root
3. Try to mount your partition to /mnt, just to confirm it's really broken (eg. "mount /dev/sda1 /mnt")
4. If it mounts - are you sure it's broken? If Yes - run `btrfs scrub start /mnt` to scrub the system, and `btrfs scrub status /mnt` to monitor it.
5. If it doesn't mount, try to scrub the device just in case it works (eg. `btrfs scrub start /dev/sda1` and `btrfs scrub status /dev/sda1` to monitor). Try mounting, if yes, you're fixed.
6. If scrubbing is not an option, or it does not resolve the issue, then try `mount -o usebackuproot` instead (eg. `mount -o usebackuproot /dev/sda1 /mnt`).

# Interlude

All of the above steps are considered safe and should make no destructive changes to disk, and have fixed every filesystem issue I've had on btrfs in the last 5 years. Full disk issues need a different approach.

If the above doesn't fix things for you, you can continue with the below steps. In case the situation is serious enough to justify a bug report, please write one!

# Treading on Thin Ice

7. Run `btrfs check <device>` (eg. `btrfs check /dev/sda1`).  This isn't going to help, but save the log somewhere, it will be useful for the bug report.
8. Seriously consider running `btrfs restore <device> <somewhere to copy data>` (eg. `btrfs restore /dev/sda1 /mnt/usbdrive`). This won't fix anything but it will scan the filesystem and recover everything it can to the mounted device. This especially useful if your btrfs issues are actually caused by failing hardware and not btrfs fault.
9. Run `btrfs rescue super-recover <device>` (eg. `btrfs rescue super-recover /dev/sda1`). Then try to mount the device normally. If it works, stop here.
10. Run `btrfs rescue zero-log <device>` (eg. `btrfs rescue zero-log /dev/sda1`). Then try to mount the device normally. If it works, stop here.
11. Run `btrfs rescue chunk-recover <device>` (eg. `btrfs rescue chunk-recover /dev/sda1`). This will take a LONG while. Then try to mount the device normally. If it works, stop here.
12. Don't just consider it this time, don't be an idiot, run `btrfs restore <device> <somewhere to copy data>` (eg. `btrfs restore /dev/sda1 /mnt/usbdrive`).
13. Seriously, don't be an idiot, use btrfs restore.

# Danger Zone

The above tools had a small chance of making unwelcome changes, but now you're in the seriously suicidal territory, do not do the following unless you're prepared to accept the consequences of your choice.

14. Now, ONLY NOW, try btrfsck aka `btrfs check --repair <device>` (eg. `btrfs check --repair /dev/sda1`)


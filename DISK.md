# Disk Recovery Procedures

# Prerequisites

```
dnf install smartmontools hdparm sysstat testdisk
```

# Phase 0 - Analyze disk

Connect drive on SATA/SCSI directly (do not use USB adapters).

```
smartctl -a /dev/sdX
```

# Phase 1 - Recover gross data as fast as possible

We disable standby, acoustics and APM. Then we enable fast error recovery (7 sec; only Enterprise and NAS drives support this).

```
hdparm -S 0 -M 254 -B 255 /dev/sdy
smartctl -l scterc,70,70 /dev/sdx
fdisk -xu /dev/sdx > part_sdx.log
ddrescue -f -n /dev/sdx /dev/sdy rescue_sdx.map
```

# Phase 2 - Recover bad sectors if possible

We disable fast error recovery to try to read as much of the data as possible.

```
smartctl -l scterc,0,0 /dev/sdx
ddrescue -f -d r3 -W /dev/sdx /dev/sdy rescue_sdx.map
```

We leave it try some more.

```
ddrescue -f -d r100 -W /dev/sdx /dev/sdy rescue_sdx.map
```

If data is important, then manually test with -i.


# Phase 3 - Sanitize

1. Check capability for sanitize `hdparm --sanitize-status /dev/sdx && hdparm -I /dev/sdX`
2. If disk supports it (Enterprise), then `hdparm --sanitize-crypto-scramble /dev/sdX`. Go to step 9.
3. Otherwise, if SSD, then `hdparm --sanitize-block-erase /dev/sdX`
4. Otherwise, if HDD, then `hdparm --sanitize-overwrite --sanitize-overwrite-passes 1 hex:DEADBEEF /dev/sdX`
5. If santize is not supported at all, then unlock the drive (if frozen only; suspend computer or enable Hotplug in BIOS and remove ATA cable).
6. Enter high security mode `hdparm --user-master u --security-set-pass YOURPASS /dev/sdX`
7. If drive supports it, use enhanced security erase `hdparm --user-master u --security-erase-enhanced YOURPASS /dev/sdX`
8. Otherwise, use normal security erase `hdparm --user-master u --security-erase YOURPASS /dev/sdX`
9. For HDD, `cryptsetup -c aes-xts-plain64 open /dev/sdX --type plain -d /dev/urandom --sector-size=4096 to_be_wiped`. Otherwise go to 12.
10. Run wipe `dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress bs=1M conv=sync,noerror oflag=direct`.
11. Finish up `cryptsetup close to_be_wiped`.
12. For SSD, `blkdiscard /dev/sdX`.

# Phase 4 - Confirm if any deterioration or improvement.

```
smartctl -a /dev/sdX
```

Pending sector count increase/decrease.
Relocated sector count increase/decrease.
Offline irrecoverable errors increase/decrease.

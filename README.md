# DDEasy
Easily backup and restore linux system

## Installation
```bash
git clone https://github.com/410-dev/DDEasy.git
```

## Usage
After cloning the git, use `cd DDEasy` to enter the cloned git directory. Then you can execute ddeasy.sh file to start action.
To configure the program, you may use any text editor to edit config.env which is copied from config.env.default when first launch.
To safely edit config file before first execution, you just need to copy the config.env.default to config.env to the same directory, then edit that file.

Possible execution commands:
```bash
./ddeasy.sh # Interactive mode
./ddeasy.sh <source> <destination> <file name> --backup --nointeraction # Backup mode, no interaction
./ddeasy.sh <source> <destination> --restore --nointeraction # Restore mode, no interaction
./ddeasy.sh <source> <destination> <file name> --backup --noconfirm  # Interactive backup mode, no confirmation
./ddeasy.sh <source> <destination> --restore --noconfirm # Interactive restore mode, no confirmation
```
### Arguments: 
Source: the full path to source device or backup file. Ex) /dev/sda    or     /home/user/backups/my-backup.img.gz

Destination: the full path to backup directory or device Ex) /home/user/backups    or     /dev/sda

File name: this will be the file name of the backup.


### Flags
--noconfirm: This will not prompt confirmation message.

--nointeraction: This will not ask any prompt during the process. This overrides --noconfirm option.

--backup: Execute backup script

--restore: Execute restore script


In interactive mode, if the source is not specified both in command line and config.env, it will automatically detect the boot drive.



Note: It is recommended to edit config.env file instead of passing values to command line arguments. 




## Description
This is a simple backup utility for linux that uses dd and gzip to create backup file, and uses dd and gunzip to restore backup.

## Notes
1. It is highly recommended to use block size of 512 instead of 64k when restoring.
2. It is not possible to restore the image to smaller disk than the original disk. For example, disk with size of 128GB cannot be restored with image from 256GB disk.

## Configurations
Edit the config.env file. The defaults are contained in config.env.default.
The script will automatically copy the default file to create config.env if it does not exist.

The editable (default) configurations are:
```bash
NOINTERACTION=0    # 0: Interactive mode, 1: No interaction mode
ACTION=            # "backup" or "restore"
SOURCE=            # Source device or file. Useful when periodically backing up automatically.
TARGET=            # Target directory or device. Useful when periodically backing up automatically.
NAMING=BACKUP-$(date +%Y-%m-%d_%H-%M) # Naming of the backup file
NOCONFIRM=0        # 0: Show confirmation in interactive mode, 1: No confirmation in interactive mode
BS=64k             # Block size when executing dd command.
PROGRESS=1         # 0: Do not show progress, 1: Show progress
```

## Error codes
E.Mx: Error in main script (ddeasy.sh)
```
E.M01: Failed copying config.env.default to config.env. Check permission or create config.env.default manually.

E.M02: Not enough permission for no interaction mode. Run script as root.

E.M03: Action is not set to "backup" or "restore" for no interaction mode. Use --backup or --restore flag to set action.

E.M04: Action is not set to "backup" or "restore" in interactive mode. Use --backup or --restore flag to set action, or type "backup" or "restore" when question is prompted.

E.M05: Module not found. Check if module exists in modules/ directory, or check if action is set correctly to "backup" or "restore".

E.M06: Failed loading config.env. Check permission or create config.env manually from config.env.default.
```

E.Bx: Error in backup script (modules/backup.sh)
```
E.B01: Failed loading config.env. Check permission or create config.env manually from config.env.default.

E.B02: The result of lsblk is empty. This means there are no recognizable partitions. Check if device exists.

E.B03: The specified source device is not in the list of partitions. Check if device exists or correctly specified.

E.B04: Source device is not specified while trying to run in no interaction mode. Either specify the source device in config.env or put as the first argument from command line.

E.B05: Destination path is not specified while trying to run in no interaction mode. Either specify the destination path in config.env or put as the second argument from command line.

E.B06: Naming scheme (which will be the file name in the destination directory) is not specified while trying to run in no interaction mode. Either specify the naming scheme in config.env or put as the third argument from command line.

E.B07: Source device is not specified in interactive mode. Either specify the source device in config.env or type it when prompted.

E.B08: Destination path is not specified in interactive mode. Either specify the destination path in config.env or type it when prompted.

E.B09: Naming scheme (which will be the file name in the destination directory) is not specified in interactive mode. Either specify the naming scheme in config.env or type it when prompted.

E.B10: Destination path should not be in the same device of source device. This is to prevent overwriting the source device. Use another device such as external USB thumbdrive or external hard disk.

E.B11: Destination path is not a directory. The backup file is a archive image file, so it should be a contained in a directory.

E.B12: Backup failed due to dd command error. Check if source device is mounted or if there is enough space in the destination device.
```

E.Rx: Error in restore script (modules/restore.sh)
```
E.R01: Failed loading config.env. Check permission or create config.env manually from config.env.default.

E.R02: The result of lsblk is empty. This means there are no recognizable partitions. Check if device exists.

E.R03: Source file is not specified while trying to run in no interaction mode. Either specify the source file in config.env or put as the first argument from command line.

E.R04: Unable to locate the specified backup file while trying to run in no interaction mode. Check if the given path is an existing img.gz file and not a directory.

E.R05: Destination device is not specified while trying to run in no interaction mode. Either specify the destination device in config.env or put as the second argument from command line.

E.R06: Source file is not specified in interactive mode. Either specify the source file in config.env or type it when prompted.

E.R07: Target device is not specified in interactive mode. Either specify the target device in config.env or type it when prompted.

E.R08: Unable to locate the specified backup file regardless of mode (But highly likely to be during interactive mode). Check if the given path is an existing img.gz file and not a directory.

E.R09: Given backup file is located, but it is not a img.gz file. Check if the given path is an existing img.gz file and not a directory.

E.R10: Target device does not exist. Check if device exists.

E.R11: Target device is the same device used for boot. This is to prevent overwriting the boot device. Restoring requires to boot into a live usb and restore from there. Otherwise, restore to another device.

E.R12: Source file is in the same device as target device. This is to prevent overwriting the source device. Use another device such as external USB thumbdrive or external hard disk.

E.R13: Restore failed due to dd command error. Check if source device is mounted or if there is enough space in the destination device.
```

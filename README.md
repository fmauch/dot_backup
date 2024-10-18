# Backups using restic

This is my backup solution using [restic](https://restic.net/).

## Why restic?
For my backups I have the following requirements:

* encrypted backups
* fast backup
* some amount of data deduplication
* easy restore from backup

Restic provides incremental snapshots that are encrypted by default and for restoring one can
either use a `restore` command or mount a snapshot as if it was just an external drive.

## So what does this package add for abstraction
I do my backups on an external hard drive. Since most machines I work on (and want to make backups
of) are Laptops that aren't always connected to the backup drive, I want my backup script to check
for the required hard drive and only proceed if it is actually attached.

The backup script also handles inclusion and exclusion of backup paths through a config file. Also,
the restic repository definition and access is handled through that.

## Requirements
In order to use this package, you will need the following dependencies:

* restic
* notify-send (notifications aren't optional at the moment)

If you want to setup restic to backup files outside of your home directory (or backup files that
your user doesn't have the permissions to read), setup your (backup) user to read all files. See
https://restic.readthedocs.io/en/stable/080_examples.html#full-backup-without-root for details.

## Installation

This is best installed using [gnu stow](https://www.gnu.org/software/stow/). Clone this package
into a first level subdirectory of your Home folder, e.g. `~/dotfiles` and run stow in it:

```bash
mkdir -p ~/dotfiles
cd ~/dotfiles
git clone https://github.com/fmauch/dot_backup.git
stow dot_backup
```

## Configuration
Configuration is handled through `~/.config/restic/restic_wrapper_config.sh`. It should contain the
following items:

```bash
BACKUP_UUID="" # get yours through blkid
BACKUP_MOUNT="" # Mount point where the backup device should be mounted to
BACKUP_REPO="" # restic repo root. Should be a path under the backup mount


## Use one of the following in your config file or make sure it is available in the sourced env.
## Otherwise restic will ask for the password on stdin, which is not suitable for an automatic
## backup.
# export RESTIC_PASSWORD_COMMAND=""
# export RESTIC_PASSWORD_FILE=""
```

Path inclusion and exclusion is handled through the two files

* `~/.config/restic/restic_includes.txt`
* `~/.config/restic/restic_excludes.txt`

See the restic documentation about this.

## Usage
The backup script can be used directly or through cron / systemd timers.

## Systemd timers

This repo already contains two systemd units to be added for the user

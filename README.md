# Rclone Google Drive Backup Script

A bash script that automates backups to Google Drive using rclone, optimized for large database backup files.

## Features

- **Incremental backups**: Only uploads files matching `database_*` prefix
- **Age filtering**: Only uploads files newer than 3 days
- **Remote cleanup**: Automatically removes files older than 3 days from Google Drive
- **Performance optimized**: Parallel transfers, large chunks for big files
- **Per-execution logging**: Creates a new log file for each backup run
- **Cron-friendly**: Designed to run automatically via cron

## Requirements

- Linux (tested on CentOS 7)
- [rclone](https://rclone.org/) configured with Google Drive remote
- Bash 4.2+

## Installation

1. **Install rclone**:
   ```bash
   curl https://rclone.org/install.sh | sudo bash
   ```

2. **Configure rclone**:
   ```bash
   rclone config
   ```
   - Create a Google Drive remote (e.g., `gdrive`)
   - Follow the authentication flow

   **Important:** For large backups (>7GB), it's highly recommended to create your own Google Drive client ID instead of using the default one. This helps avoid rate limits:
   [Making your own client ID](https://rclone.org/drive/#making-your-own-client-id)

3. **Edit the script**:
   ```bash
   nano rclone-backup.sh
   ```
   
   Update these variables for your setup:
   ```bash
   remote_name='gdrive'                 # Your rclone remote name
   backup_base='backups/db'             # Google Drive destination folder
   source_dir='/opt/backup'             # Local folder to backup
   log_dir='/opt/backup/log'            # Where to store log files
   file_prefix='database_'              # Only files starting with this
   keep_days=3                          # Keep last N days
   ```

4. **Make executable**:
   ```bash
   chmod +x rclone-backup.sh
   ```

## Usage

### Manual run
```bash
./rclone-backup.sh
```

### Cron setup
```bash
# Edit crontab
crontab -e

# Run daily at 2 AM
0 2 * * * /path/to/rclone-backup.sh
```

## Performance Tuning

The script includes these optimizations for large files (7GB+):

- `--transfers 8` - 8 parallel file transfers (default: 4)
- `--checkers 16` - 16 parallel file checkers (default: 8)
- `--drive-chunk-size 128M` - 128MB upload chunks for Google Drive (default: 8M)
- `--fast-list` - Faster directory listing (uses more RAM)
- `--no-check-dest` - Skip destination existence checks
- `--no-traverse` - Don't scan destination tree

Adjust these in the script if needed:
```bash
transfers=8      # Increase for faster internet
checkers=16      # Increase for more CPU cores
drive_chunk_size='128M'  # Reduce if low on memory
```

## Log Files

Each execution creates a unique log file:
```
/opt/backup/log/rclone_backup_2026-02-08_14-30-00.log
```

Old log files are automatically cleaned up by your existing backup script's `find` command.

## Style Guide

This script follows the [YSAP Bash Style Guide](https://style.ysap.sh):
- Uses `#!/usr/bin/env bash`
- Tabs for indentation
- `[[ ... ]]` for conditionals
- `local` variables in functions
- Proper quoting
- No `set -e`, no `eval`

## License

MIT License - See bash_style.md for original style guide license.

## Troubleshooting

**Script not uploading files?**
- Check `file_prefix` matches your backup files (default: `database_`)
- Verify `source_dir` path is correct
- Check file ages with `find /path -mtime -3`

**Permission denied?**
```bash
chmod +x rclone-backup.sh
```

**rclone not found?**
```bash
which rclone
# If empty, install rclone first
```

**Remote not found?**
```bash
rclone listremotes
# Should show your configured remote
```

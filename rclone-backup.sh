#!/usr/bin/env bash
#
# rclone backup script for Google Drive - cron-friendly
# Backs up a specific folder to backups/ on Google Drive
#

# Configuration - modify these for your setup
remote_name='gdrive'
backup_base='backups/db'
source_dir='/opt/backup'
log_dir='/opt/backup/log'

# Generate timestamp for this backup run
timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
backup_dest="${remote_name}:${backup_base}"
keep_days=3
file_prefix='database_'

# Performance settings for large files
transfers=8
checkers=16
drive_chunk_size='128M'

# Create unique log file for this run
current_log="${log_dir}/rclone_backup_${timestamp}.log"

# Logging function - writes to console and current log file
log() {
	local msg
	msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
	echo "$msg"
	echo "$msg" >> "$current_log" 2>/dev/null
}

# Check if rclone is installed
check_rclone() {
	if ! command -v rclone &>/dev/null; then
		log 'ERROR: rclone is not installed'
		exit 1
	fi
}

# Validate remote exists
validate_remote() {
	if ! rclone listremotes 2>/dev/null | grep -q "^${remote_name}:"; then
		log "ERROR: Remote '${remote_name}' not found"
		exit 1
	fi
}

# Validate source directory
validate_source() {
	if [[ ! -d $source_dir ]]; then
		log "ERROR: Source directory not found: ${source_dir}"
		exit 1
	fi
}

# Perform backup
run_backup() {
	local start_time end_time duration
	start_time=$(date +%s)

	log "Starting backup of '${source_dir}' to '${backup_dest}'"
	log "Timestamp: ${timestamp}"

	# Run rclone with copy (only files newer than keep_days and matching prefix)
	# Performance flags for large files:
	# --transfers: number of parallel file transfers (default 4)
	# --checkers: number of parallel checks (default 8)
	# --drive-chunk-size: upload chunk size for Google Drive
	# --fast-list: faster listing for many files (uses more memory)
	log "Starting rclone copy..."
	rclone copy "$source_dir" "$backup_dest" \
		--max-age "${keep_days}d" \
		--include "${file_prefix}*" \
		--transfers "$transfers" \
		--checkers "$checkers" \
		--drive-chunk-size "$drive_chunk_size" \
		--fast-list \
		--stats 30s \
		--log-level INFO \
		2>&1 | tee -a "$current_log"

	if ((PIPESTATUS[0] == 0)); then
		end_time=$(date +%s)
		duration=$((end_time - start_time))
		log "Backup completed successfully in ${duration}s"
		return 0
	else
		log "ERROR: Backup failed"
		return 1
	fi
}

# Cleanup old backups on remote (keep last N days)
cleanup_remote() {
	log "Cleaning up backups older than ${keep_days} days on remote..."
	rclone delete "$backup_dest" --min-age "${keep_days}d" --drive-use-trash=false 2>/dev/null || {
		log "WARNING: Cleanup completed with some errors"
	}
}

# Main
main() {
	check_rclone
	validate_remote
	validate_source
	run_backup
	cleanup_remote
}

main "$@"

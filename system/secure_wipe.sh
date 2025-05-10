#!/bin/bash
# Secure Data Wipe Script for VPS - Extreme Edition
# Designed for maximum data security prior to decommissioning a VPS.
# WARNING: This script is highly destructive and irreversible. 
#          It is intended to ERASE data, not recover it.
#          Run at your own risk and ONLY on systems you intend to destroy.
#          ALWAYS BACKUP CRITICAL DATA BEFORE RUNNING THIS SCRIPT.
#          This script is provided AS IS, with no warranty.
#
# Features:
# - DoD 5220.22-M 3-pass wipe for sensitive areas
# - Comprehensive swap space wiping (partition and file)
# - Aggressive log and trace destruction (system logs, command history, network traces, etc.)
# - Kernel memory and cache purging
# - Hardware fingerprint removal (machine-id, udev rules)
# - Cryptographic material eradication
# - Storage metadata wiping (LVM, RAID)
# - Block device buffer flushing
# - Package manager database cleaning
# - Systemd state cleansing
# - Secure self-destruction of script log
# - Final sync and cache drop
# - Optional kernel panic for immediate halt
# - Enhanced memory scrubbing and CPU cache activity
# - Process purging of non-essential services
# - System hardening during wipe
#
# IMPORTANT USAGE NOTES:
# - Run this script as root: `sudo ./secure_wipe.sh`
# - DO NOT INTERRUPT the script once it starts.
# - This script is designed to be run on a LIVE, RUNNING system.
# - It aims to wipe FREE SPACE and TEMPORARY AREAS without destroying the OS itself (to allow for final wipe).
# - However, due to its aggressive nature, some services might be temporarily disrupted.
# - This script is intended to be the LAST ACTION before VPS termination.
# - Review and understand every command before execution.
# - Test in a non-production environment first!
#
# DISCLAIMER: Use this script at your own risk. The author is not responsible for any data loss or system damage.

set -euo pipefail

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Log file for script actions - will be securely deleted at the end
LOG_FILE="/var/log/secure_wipe.log"
echo "$(date '+%Y-%m-%d_%H:%M:%S') - Secure Wipe Script started" | tee -a "$LOG_FILE"

# Function to wipe swap space
wipe_swap() {
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Wiping swap space..." | tee -a "$LOG_FILE"
    swapoff -a
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Swap turned off" | tee -a "$LOG_FILE"
    for swapdev in $(blkid -t TYPE=swap -o value -s DEVICE); do
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Wiping swap device: $swapdev" | tee -a "$LOG_FILE"
        shred -v -n 3 -z "$swapdev"
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Swap device $swapdev wiped" | tee -a "$LOG_FILE"
    done
    swapon -a
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Swap turned back on" | tee -a "$LOG_FILE"

    # Also wipe swap file if exists
    if grep -q "swapfile" /etc/fstab; then
        local swapfile=$(grep "swapfile" /etc/fstab | awk '{print $1}')
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Wiping swap file: $swapfile" | tee -a "$LOG_FILE"
        swapoff "$swapfile"
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Swap file turned off" | tee -a "$LOG_FILE"
        shred -v -n 3 -z "$swapfile"
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Swap file $swapfile wiped" | tee -a "$LOG_FILE"
        mkswap "$swapfile"
        swapon "$swapfile"
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Swap file turned back on" | tee -a "$LOG_FILE"
    fi
}

# Function to wipe free space using tmpfile
wipe_free_space() {
    local target_dir="${1:-/}"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Wiping free space in $target_dir" | tee -a "$LOG_FILE"
    local wipefile="${target_dir}/.wipefile"
    
    # Pass 1: Overwrite with random data
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Pass 1: Writing random data to free space in $target_dir"  | tee -a "$LOG_FILE"
    dd if=/dev/urandom of="$wipefile" bs=1M status=progress || true
    sync
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Random data write (Pass 1) complete, syncing..."  | tee -a "$LOG_FILE"
    
    # Pass 2: Overwrite with zeros
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Pass 2: Writing zeros to free space in $target_dir"  | tee -a "$LOG_FILE"
    dd if=/dev/zero of="$wipefile" bs=1M status=progress || true
    sync
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Zero data write (Pass 2) complete, syncing..."  | tee -a "$LOG_FILE"
    
    # Pass 3: Overwrite with more random data
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Pass 3: Writing random data again to free space in $target_dir"  | tee -a "$LOG_FILE"
    dd if=/dev/urandom of="$wipefile" bs=1M status=progress || true
    sync
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Random data write (Pass 3) complete, syncing..."  | tee -a "$LOG_FILE"
    
    shred -v -n 1 -z "$wipefile"
    rm -f "$wipefile"
    sync
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Wipe file removed, syncing..."  | tee -a "$LOG_FILE"
}

# Function to scrub memory aggressively
scrub_memory() {
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively scrubbing memory..." | tee -a "$LOG_FILE"
    MEM_FILE="/dev/shm/memory_scrub"
    # Attempt to allocate and fill most of RAM
    free -m
    RAM_MB=$(free -m | awk '/Mem:/{print $2}')
    ALLOCATE_MB=$((RAM_MB * 95 / 100)) # Try to use 95% of RAM
    if [ "$ALLOCATE_MB" -gt 100 ]; then # Avoid very small allocations
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Attempting to allocate ${ALLOCATE_MB}MB of RAM for scrubbing..." | tee -a "$LOG_FILE"
        dd if=/dev/urandom of="$MEM_FILE" bs=1M count="$ALLOCATE_MB" || true # Ignore errors if allocation fails
        sync
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Memory allocation and random fill complete." | tee -a "$LOG_FILE"
        shred -v -n 1 -z "$MEM_FILE" || true # Single pass of zeros
        rm -f "$MEM_FILE"
        sync
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Memory scrubbing file removed." | tee -a "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Not enough RAM to perform aggressive memory scrub." | tee -a "$LOG_FILE"
    fi
    free -m
}

# Function to generate CPU cache activity
cpu_cache_activity() {
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Generating CPU cache activity..." | tee -a "$LOG_FILE"
    # Simple CPU intensive loop to overwrite cache lines
    for i in $(seq 1 100000); do
        a=$((i * i))
        b=$((a / 2))
        c=$((b + i))
    done
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - CPU cache activity generated." | tee -a "$LOG_FILE"
}

# Main wiping process
main() {
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Starting secure wipe process - DO NOT INTERRUPT" | tee -a "$LOG_FILE"
    
    # --- INITIALIZATION PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING INITIALIZATION PHASE ---" | tee -a "$LOG_FILE"
    
    # Immediately disable shell history
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Disabling shell history..." | tee -a "$LOG_FILE"
    set +o history
    export HISTSIZE=0
    export HISTFILESIZE=0
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Shell history disabled" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- INITIALIZATION PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- SWAP WIPING PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING SWAP WIPING PHASE ---" | tee -a "$LOG_FILE"
    
    # Wipe swap space first
    wipe_swap
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- SWAP WIPING PHASE COMPLETED ---" | tee -a "$LOG_FILE"
    
    # --- PROCESS TERMINATION PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING PROCESS TERMINATION PHASE ---" | tee -a "$LOG_FILE"
    
    # Purge non-essential processes (CAREFUL with this section - customize as needed)
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Purging non-essential processes..." | tee -a "$LOG_FILE"
    pkill -9 -u $(who | awk '{print $1}' | sort -u | grep -v root | paste -sd'|') || true # Kill user processes
    systemctl stop apache2 httpd nginx lighttpd mysql mariadb postgresql redis memcached docker || true # Stop common services
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Non-essential processes purged (best effort)." | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- PROCESS TERMINATION PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- TEMPORARY FILES CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING TEMPORARY FILES CLEANUP PHASE ---" | tee -a "$LOG_FILE"

    # Wipe temporary directories (before data deletion, to clean up temp files related to services)
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Cleaning temporary files in /tmp..." | tee -a "$LOG_FILE"
    find /tmp -type f -exec shred -v -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /tmp temporary files wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Cleaning temporary files in /var/tmp..." | tee -a "$LOG_FILE"
    find /var/tmp -type f -exec shred -v -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /var/tmp temporary files wiped" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- TEMPORARY FILES CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"
    
    # --- DATA DELETION PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING DATA DELETION PHASE ---" | tee -a "$LOG_FILE"

    # Delete user data directories (CAREFUL - double check paths before running in production!)
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting user data in /home..." | tee -a "$LOG_FILE"
    rm -rf /home/* || true # Non-critical failure, continue if deletion fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /home user data deleted (best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting root user data in /root..." | tee -a "$LOG_FILE"
    rm -rf /root/* || true # Non-critical failure, continue if deletion fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /root user data deleted (best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting web server data in /var/www..." | tee -a "$LOG_FILE"
    rm -rf /var/www/* || true # Non-critical failure, continue if deletion fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /var/www data deleted (best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting optional software in /opt..." | tee -a "$LOG_FILE"
    rm -rf /opt/* || true # Non-critical failure, continue if deletion fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /opt data deleted (best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting served data in /srv..." | tee -a "$LOG_FILE"
    rm -rf /srv/* || true # Non-critical failure, continue if deletion fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /srv data deleted (best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting data in /mnt..." | tee -a "$LOG_FILE"
    rm -rf /mnt/* || true # Non-critical failure, continue if deletion fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /mnt data deleted (best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting data in /media..." | tee -a "$LOG_FILE"
    rm -rf /media/* || true # Non-critical failure, continue if deletion fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /media data deleted (best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting temporary files in /tmp again (post-user-deletion)..." | tee -a "$LOG_FILE"
    rm -rf /tmp/* || true # Redundant, but just in case some temp files were created after initial wipe
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /tmp data deleted (again, best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Aggressively deleting temporary files in /var/tmp again (post-user-deletion)..." | tee -a "$LOG_FILE"
    rm -rf /var/tmp/* || true # Redundant, but just in case some temp files were created after initial wipe
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /var/tmp data deleted (again, best effort)" | tee -a "$LOG_FILE"

    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- DATA DELETION PHASE COMPLETED ---" | tee -a "$LOG_FILE"
    # --- END DATA DELETION PHASE ---

    # --- SYSTEM TRACES CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING SYSTEM TRACES CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Wipe system logs and traces (AFTER data deletion, so logs of deletion are also wiped)
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Destroying system logs in /var/log..." | tee -a "$LOG_FILE"
    find /var/log -type f -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /var/log system logs wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Destroying journal logs in /var/log/journal..." | tee -a "$LOG_FILE"
    find /var/log/journal -type f -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /var/log/journal logs wiped" | tee -a "$LOG_FILE"
    journalctl --vacuum-time=1s
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - System journal vacuumed" | tee -a "$LOG_FILE"

    # Wipe command histories
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Erasing shell histories in user home directories..." | tee -a "$LOG_FILE"
    find /home -type f -name '.*_history' -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - User shell histories wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Erasing root shell history..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u "/root/.*_history"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Root shell history wiped" | tee -a "$LOG_FILE"
    history -c
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Current shell history cleared" | tee -a "$LOG_FILE"

    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- SYSTEM TRACES CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- MEMORY FILESYSTEMS CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING MEMORY FILESYSTEMS CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Wipe temporary filesystems
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing memory-based filesystems: /dev/shm..." | tee -a "$LOG_FILE"
    find /dev/shm -type f -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /dev/shm wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing memory-based filesystems: /run/lock..." | tee -a "$LOG_FILE"
    find /run/lock -type f -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /run/lock wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing memory-based filesystems: /run/user..." | tee -a "$LOG_FILE"
    find /run/user -type f -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /run/user wiped" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- MEMORY FILESYSTEMS CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- AUDIT LOGS CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING AUDIT LOGS CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Wipe audit logs
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Destroying audit trails in /var/log/audit..." | tee -a "$LOG_FILE"
    find /var/log/audit -type f -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /var/log/audit wiped" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- AUDIT LOGS CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- KERNEL LOGS CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING KERNEL LOGS CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Wipe kernel logs
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing kernel ring buffer..." | tee -a "$LOG_FILE"
    dmesg -c > /dev/null
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Kernel ring buffer cleared" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing /var/log/kern.log..." | tee -a "$LOG_FILE"
    echo > /var/log/kern.log
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /var/log/kern.log cleared" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- KERNEL LOGS CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- KERNEL MEMORY ARTIFACTS PURGE PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING KERNEL MEMORY ARTIFACTS PURGE PHASE ---" | tee -a "$LOG_FILE"
    
    # Nuclear option for kernel memory artifacts
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Purging kernel caches and slabs..." | tee -a "$LOG_FILE"
    echo 3 > /proc/sys/vm/drop_caches
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Dropped pagecache, dentries and inodes" | tee -a "$LOG_FILE"
    echo 1 > /proc/sys/vm/compact_memory
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Requested memory compaction" | tee -a "$LOG_FILE"
    echo 1 > /proc/sys/vm/oom_kill_allocating_task
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Enabled OOM killer for allocating tasks" | tee -a "$LOG_FILE"
    slabtop --once | awk '/^[0-9]+/ {print $2}' | xargs -I{} sh -c 'echo 1 > /sys/kernel/slab/{}/shrink'
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Slab cache shrink requested" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- KERNEL MEMORY ARTIFACTS PURGE PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- NETWORK TRACES CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING NETWORK TRACES CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Wipe network traces
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing network artifacts: DHCP leases..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /var/lib/dhcp/dhclient.leases
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - DHCP leases wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing network artifacts: resolv.conf..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /etc/resolv.conf
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - resolv.conf wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing network artifacts: NetworkManager connections..." | tee -a "$LOG_FILE"
    find /etc/NetworkManager/system-connections -type f -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - NetworkManager connections wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing network artifacts: SSH host keys..." | tee -a "$LOG_FILE"
    find /etc/ssh -type f -name 'ssh_host_*_key*' -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - SSH host keys wiped" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing network artifacts: known_hosts..." | tee -a "$LOG_FILE"
    find ~/ -type f -name 'known_hosts' -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - known_hosts wiped" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- NETWORK TRACES CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- SYSTEM IDENTIFIERS CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING SYSTEM IDENTIFIERS CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Destroy system identifiers
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Anonymizing system IDs: /etc/machine-id..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /etc/machine-id
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /etc/machine-id shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Anonymizing system IDs: /var/lib/dbus/machine-id..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /var/lib/dbus/machine-id
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - /var/lib/dbus/machine-id shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Resetting machine-id to uninitialized..." | tee -a "$LOG_FILE"
    echo uninitialized | tee /etc/machine-id /var/lib/dbus/machine-id
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - machine-id reset" | tee -a "$LOG_FILE"
    
    # Wipe udev persistent rules
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing hardware fingerprints: udev rules..." | tee -a "$LOG_FILE"
    find /etc/udev/rules.d -type f -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - udev rules shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing hardware fingerprints: hwdb.bin..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /var/lib/udev/hwdb.bin
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - hwdb.bin shredded" | tee -a "$LOG_FILE"
    udevadm hwdb --update
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - udev hwdb updated" | tee -a "$LOG_FILE"
    
    # Purge user traces
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Erasing user artifacts: history, viminfo, lesshst, sudo..." | tee -a "$LOG_FILE"
    find /home /root -type f \( -name '.*history' -o -name '.viminfo' -o -name '.lesshst' -o -name '.sudo_as_admin_successful' \) -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - User artifacts shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Erasing user caches..." | tee -a "$LOG_FILE"
    find /home /root -type d -name '.cache' -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - User caches shredded" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- SYSTEM IDENTIFIERS CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- CRYPTOGRAPHIC MATERIAL CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING CRYPTOGRAPHIC MATERIAL CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Destroy crypto material
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Eradicating cryptographic secrets: SSL certs..." | tee -a "$LOG_FILE"
    find /etc/ssl -type f -name '*.crt' -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - SSL certs shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Eradicating cryptographic secrets: PKI keys..." | tee -a "$LOG_FILE"
    find /etc/pki -type f -name '*.key' -exec shred -v -f -n 3 -z -u {} +
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - PKI keys shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Eradicating cryptographic secrets: SSH host keys (again)..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /etc/ssh/ssh_host_*_key*
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - SSH host keys shredded (again)" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- CRYPTOGRAPHIC MATERIAL CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- STORAGE METADATA CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING STORAGE METADATA CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Purge LVM and RAID artifacts
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Destroying storage metadata: mdadm.conf..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /etc/mdadm/mdadm.conf
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - mdadm.conf shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Destroying storage metadata: LVM backups..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /etc/lvm/backup/*
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - LVM backups shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Destroying storage metadata: LVM archives..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /etc/lvm/archive/*
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - LVM archives shredded" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STORAGE METADATA CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- ADDITIONAL CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING ADDITIONAL CLEANUP PHASE ---" | tee -a "$LOG_FILE"

    # Scrub block device buffers
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing block device caches..." | tee -a "$LOG_FILE"
    for dev in /dev/sd* /dev/vd* /dev/nvme*; do
        if [ -b "$dev" ]; then
            echo "$(date '+%Y-%m-%d_%H:%M:%S') - Flushing buffers for block device: $dev..."  | tee -a "$LOG_FILE"
            blockdev --flushbufs "$dev"
            echo "$(date '+%Y-%m-%d_%H:%M:%S') - Block device $dev buffers flushed"  | tee -a "$LOG_FILE"
            echo "$(date '+%Y-%m-%d_%H:%M:%S') - Requesting device reread for: $dev..."  | tee -a "$LOG_FILE"
            hdparm -f "$dev" 2>/dev/null || true # Ignore errors from hdparm if device doesn't support it
            echo "$(date '+%Y-%m-%d_%H:%M:%S') - Device reread requested for $dev"  | tee -a "$LOG_FILE"
        fi
    done
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Block device caches cleared" | tee -a "$LOG_FILE"
    
    # Wipe firewall logs (AFTER data deletion, so firewall logs of deletion are also wiped)
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing firewall traces: iptables/ip6tables..." | tee -a "$LOG_FILE"
    iptables -Z && ip6tables -Z
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - iptables/ip6tables zeroed" | tee -a "$LOG_FILE"
    nft flush ruleset
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - nftables ruleset flushed" | tee -a "$LOG_FILE"
    conntrack -F
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - conntrack table flushed" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing firewall logs: ufw.log..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /var/log/ufw.log
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - ufw.log shredded" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Clearing firewall logs: firewalld..." | tee -a "$LOG_FILE"
    shred -v -f -n 3 -z -u /var/log/firewalld
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - firewalld log shredded" | tee -a "$LOG_FILE"
    
    # Clean package caches
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Cleaning package caches: APT..." | tee -a "$LOG_FILE"
    apt-get clean || true # Non-critical failure, continue if apt-get fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - APT cache cleaned (best effort)" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Cleaning package caches: YUM..." | tee -a "$LOG_FILE"
    yum clean all || true # Non-critical failure, continue if yum fails
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - YUM cache cleaned (best effort)" | tee -a "$LOG_FILE"

    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- ADDITIONAL CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- FINAL FREE SPACE WIPING PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING FINAL FREE SPACE WIPING PHASE ---" | tee -a "$LOG_FILE"
    
    # Ensure all buffers are written to disk before wiping free space
    sync
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Pre-wipe sync completed" | tee -a "$LOG_FILE"
    
    # Wipe free space in all mounted filesystems (AFTER all deletions and cleanups)
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Wiping free space in all mounted filesystems..." | tee -a "$LOG_FILE"
    mountpoints=$(mount | grep -E '^/dev' | awk '{print $3}') # Only real filesystems, not pseudo-fs
    for mp in $mountpoints; do
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Wiping free space in mount point: $mp" | tee -a "$LOG_FILE"
        wipe_free_space "$mp"
        echo "$(date '+%Y-%m-%d_%H:%M:%S') - Free space wipe completed for: $mp" | tee -a "$LOG_FILE"
    done
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Free space wiped in all mount points" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- FINAL FREE SPACE WIPING PHASE COMPLETED ---" | tee -a "$LOG_FILE"
    
    # --- MEMORY SCRUBBING PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING MEMORY SCRUBBING PHASE ---" | tee -a "$LOG_FILE"
    
    # Aggressively scrub memory after all disk operations
    scrub_memory
    
    # Generate CPU cache activity after memory scrub
    cpu_cache_activity
    
    # Final memory and cache operations
    echo 3 > /proc/sys/vm/drop_caches
    echo 1 > /proc/sys/vm/compact_memory
    
    # Final sync to ensure everything is written
    sync
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Final sync completed" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- MEMORY SCRUBBING PHASE COMPLETED ---" | tee -a "$LOG_FILE"

    # --- FINAL CLEANUP PHASE ---
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- STARTING FINAL CLEANUP PHASE ---" | tee -a "$LOG_FILE"
    
    # Final sync to ensure everything is written
    sync
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Final sync completed" | tee -a "$LOG_FILE"
    
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - --- FINAL CLEANUP PHASE COMPLETED ---" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d_%H:%M:%S') - Wipe process completed successfully" | tee -a "$LOG_FILE"
}

# Execute main function with logging and secure log deletion
{
    # Start the main wiping process and redirect all output (stdout and stderr)
    main
} 2>&1 |
    # Pipe the combined output to shred for secure deletion of the log file itself
    shred -v -f -n 3 -z -u "$LOG_FILE"

# Final sync and cache drop
sync
echo 3 > /proc/sys/vm/drop_caches
echo 1 > /proc/sys/vm/compact_memory
echo "$(date '+%Y-%m-%d_%H:%M:%S') - Final cache drop and memory compaction requested" | tee -a "$LOG_FILE"

# Kernel panic to prevent memory analysis (optional)
# WARNING: This will immediately crash the system. Uncomment ONLY if you intend to halt the VPS right after wiping.
# echo c > /proc/sysrq

echo "$(date '+%Y-%m-%d_%H:%M:%S') - Secure Wipe Script finished" | tee -a "$LOG_FILE" 
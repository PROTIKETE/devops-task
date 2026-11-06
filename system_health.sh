#!/usr/bin/env bash

# System Health Monitoring Script

set -euo pipefail

LOG_FILE="health_log.txt"
DISK_THRESHOLD=80

# CPU Usage
get_cpu_usage() {
    local u1 n1 s1 i1 w1 q1 sq1 st1
    local u2 n2 s2 i2 w2 q2 sq2 st2

    read -r _ u1 n1 s1 i1 w1 q1 sq1 st1 _ < /proc/stat
    sleep 1
    read -r _ u2 n2 s2 i2 w2 q2 sq2 st2 _ < /proc/stat

    local idle=$(( (i2 + w2) - (i1 + w1) ))

    local total=$(( \
        (u2+n2+s2+i2+w2+q2+sq2+st2) - \
        (u1+n1+s1+i1+w1+q1+sq1+st1) \
    ))

    if (( total <= 0 )); then
        echo 0
        return
    fi

    echo $(( 100 * (total - idle) / total ))
}

# Memory Usage
get_mem_usage() {
    free | awk '/^Mem:/ { printf "%.0f", ($2 - $7) / $2 * 100 }'
}

# Disk Usage
get_disk_usage() {
    df -P / | awk 'NR==2 { gsub("%", "", $5); print $5 }'
}

timestamp=$(date '+%Y-%m-%d %H:%M:%S')

cpu=$(get_cpu_usage)
mem=$(get_mem_usage)
disk=$(get_disk_usage)

entry="[$timestamp] CPU: ${cpu}% | Memory: ${mem}% | Disk: ${disk}%"

echo "$entry"
echo "$entry" >> "$LOG_FILE"

if [ "$disk" -gt "$DISK_THRESHOLD" ]; then
    warning="[$timestamp] [WARNING] Disk space high! (${disk}% used)"
    echo "$warning"
    echo "$warning" >> "$LOG_FILE"
fi

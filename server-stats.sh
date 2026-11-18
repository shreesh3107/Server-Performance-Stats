#!/usr/bin/env bash
#
# server-stats.sh
#
# Analyses basic server performance stats on any Linux server:
#   - Total CPU usage
#   - Total memory usage (free vs used, including percentage)
#   - Total disk usage (free vs used, including percentage)
#   - Top 5 processes by CPU usage
#   - Top 5 processes by memory usage
#   - Stretch: OS version, uptime, load average, logged in users,
#              failed login attempts
#
# Usage:
#   ./server-stats.sh
#
# Works on most Linux distributions out of the box (relies on
# /proc, free, df and ps, which are available on virtually every
# Linux system without extra dependencies).

set -u

echo "########################################"
echo "        Server Performance Stats"
echo "        $(date)"
echo "########################################"

# ---------------------------------------------------------------------------
# Total CPU usage
# ---------------------------------------------------------------------------
# Sample /proc/stat twice (1 second apart) to compute CPU usage over that
# interval. This is more accurate than a single snapshot. awk handles both
# the math and the formatting in one step.

echo
echo "== Total CPU Usage =="
if [ -r /proc/stat ]; then
    cpu1=$(grep '^cpu ' /proc/stat)
    sleep 1
    cpu2=$(grep '^cpu ' /proc/stat)
    awk -v c1="$cpu1" -v c2="$cpu2" 'BEGIN {
        split(c1, a); split(c2, b)
        idle1 = a[5] + a[6]; idle2 = b[5] + b[6]
        total1 = a[2]+a[3]+a[4]+a[5]+a[6]+a[7]+a[8]+a[9]
        total2 = b[2]+b[3]+b[4]+b[5]+b[6]+b[7]+b[8]+b[9]
        total_diff = total2 - total1
        idle_diff = idle2 - idle1
        if (total_diff > 0)
            printf "Total CPU Usage: %.2f%%\n", (total_diff - idle_diff) * 100 / total_diff
        else
            print "Unable to compute CPU usage."
    }'
else
    echo "CPU stats unavailable (/proc/stat not readable)."
fi

# ---------------------------------------------------------------------------
# Total memory usage
# ---------------------------------------------------------------------------

echo
echo "== Memory Usage =="
if command -v free >/dev/null 2>&1; then
    free -m | awk '/^Mem:/ {
        printf "Total:     %d MB\n", $2
        printf "Used:      %d MB (%.2f%%)\n", $3, $3 * 100 / $2
        printf "Free:      %d MB (%.2f%%)\n", $4, $4 * 100 / $2
        printf "Available: %d MB\n", $7
    }'
else
    echo "Memory stats unavailable ('free' command not found)."
fi

# ---------------------------------------------------------------------------
# Total disk usage
# ---------------------------------------------------------------------------
# Aggregate across all real filesystems (exclude pseudo/virtual ones).

echo
echo "== Disk Usage =="
if command -v df >/dev/null 2>&1; then
    df -BM --total -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | awk '
        /^total/ {
            gsub("M", "", $2); gsub("M", "", $3); gsub("M", "", $4); gsub("%", "", $5)
            printf "Total: %s MB\n", $2
            printf "Used:  %s MB (%s%%)\n", $3, $5
            printf "Free:  %s MB (%d%%)\n", $4, 100 - $5
            found = 1
        }
        END { if (!found) print "Unable to compute aggregate disk usage." }
    '
else
    echo "Disk stats unavailable ('df' command not found)."
fi

# ---------------------------------------------------------------------------
# Top 5 processes by CPU usage
# ---------------------------------------------------------------------------
# head -n 6 keeps ps's own header row plus the top 5 entries, so columns
# stay aligned exactly as ps formats them natively.

echo
echo "== Top 5 Processes by CPU Usage =="
if command -v ps >/dev/null 2>&1; then
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
else
    echo "Process stats unavailable ('ps' command not found)."
fi

# ---------------------------------------------------------------------------
# Top 5 processes by memory usage
# ---------------------------------------------------------------------------

echo
echo "== Top 5 Processes by Memory Usage =="
if command -v ps >/dev/null 2>&1; then
    ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 6
else
    echo "Process stats unavailable ('ps' command not found)."
fi

# ---------------------------------------------------------------------------
# Stretch goals
# ---------------------------------------------------------------------------

echo
echo "== OS Version =="
if [ -r /etc/os-release ]; then
    (. /etc/os-release && echo "${PRETTY_NAME:-Unknown}")
elif command -v uname >/dev/null 2>&1; then
    uname -srm
else
    echo "Unknown"
fi

echo
echo "== Uptime =="
if command -v uptime >/dev/null 2>&1; then
    uptime -p 2>/dev/null || uptime
elif [ -r /proc/uptime ]; then
    awk '{ printf "Up %.0f minutes\n", $1 / 60 }' /proc/uptime
else
    echo "Unknown"
fi

echo
echo "== Load Average (1m, 5m, 15m) =="
if [ -r /proc/loadavg ]; then
    awk '{ printf "%s, %s, %s\n", $1, $2, $3 }' /proc/loadavg
elif command -v uptime >/dev/null 2>&1; then
    uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ *//'
else
    echo "Unknown"
fi

echo
echo "== Logged In Users =="
if command -v who >/dev/null 2>&1; then
    printf "Count: %s\n" "$(who | wc -l)"
    who 2>/dev/null
else
    echo "Unknown ('who' command not found)."
fi

echo
echo "== Failed Login Attempts =="
if command -v lastb >/dev/null 2>&1 && [ -r /var/log/btmp ]; then
    printf "Count: %s\n" "$(lastb | grep -vc '^btmp begins')"
else
    echo "Unavailable (requires 'lastb' and read access to /var/log/btmp, try sudo)."
fi

echo

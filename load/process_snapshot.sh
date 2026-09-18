#!/bin/sh
# Read-only Linux process counters. The collector shell and its direct children
# are excluded; no environment variables or command-line secrets are recorded.
set -eu
read -r uptime_seconds unused < /proc/uptime
printf 'uptime\t%s\n' "$uptime_seconds"
for process_stat in /proc/[0-9]*/stat; do
  [ -r "$process_stat" ] || continue
  awk -v collector="$$" '
    {
      pid = $1
      name = $0
      sub(/^[^(]*\(/, "", name)
      sub(/\) .*/, "", name)
      fields = $0
      sub(/^.*\) /, "", fields)
      split(fields, f, " ")
      if (pid == collector || f[2] == collector) next
      gsub(/[\t\r\n]/, " ", name)
      # After removing pid/comm: utime=12, stime=13, threads=18,
      # starttime=20, vsize=21, resident pages=22.
      printf "%s\t%s\t%.0f\t%s\t%s\t%s\t%s\n", pid, f[20], f[12]+f[13], f[22], f[21], f[18], name
    }
  ' "$process_stat" 2>/dev/null || true # Processes can exit between reads.
done

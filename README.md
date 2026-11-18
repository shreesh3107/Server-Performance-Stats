# Server-Performance-Stats

A Bash script that reports basic server performance statistics on Linux systems.

## Features

- Total CPU usage
- Memory usage (total, used, free, and available)
- Aggregate disk usage
- Top five processes by CPU usage
- Top five processes by memory usage
- OS version, uptime, load average, and logged-in users
- Failed login attempt count, when available

## Project URL

https://github.com/shreesh3107/Server-Performance-Stats
https://github.com/shreesh3107/Server-Performance-Stats/blob/main/server-stats.sh

## Requirements

- Linux
- Bash
- Standard Linux utilities: `free`, `df`, `ps`, `uptime`, `who`, and `awk`

## Run the project

Clone the repository:

```bash
git clone https://github.com/shreesh3107/Server-Performance-Stats.git
cd Server-Performance-Stats
```

Make the script executable:

```bash
chmod +x server-stats.sh
```

Run it:

```bash
./server-stats.sh
```

You can also run it directly with Bash:

```bash
bash server-stats.sh
```

Reading `/var/log/btmp` for failed login attempts may require `sudo` or the appropriate permissions.

#!/bin/bash
# =============================================================================
# Script: system-info.sh
# Description: Displays detailed system information (basic system, CPU, memory,
#              disk, cache, NUMA, and optionally network data) after ensuring
#              required packages are installed.
#
# Usage: ./system-info.sh [--network] [--memory]
#   --detail   Include network information in the report.
#
# Requirements: lsb_release, lscpu, free, lsblk, nvme (optional), numactl (optional),
#               ip, top, ps, and iostat (optional).
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Global flag to control network info output
DETAILED=false

usage() {
	echo "Usage: $0 [--network]"
	echo "  --detail    Include detailed network and memory information in the report."
	echo "  -h, --help  Show this help message."
	exit 0
}

info() { echo -e "\e[1;34m$1\e[0m"; }

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	--detail)
		DETAILED=true
		shift
		;;
	-h | --help)
		usage
		;;
	*)
		echo "Unknown argument: $1"
		usage
		;;
	esac
done

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

install_package() {
	local pkg="$1"
	if command_exists apt-get; then
		echo "Installing $pkg using apt-get..."
		sudo apt-get update && sudo apt-get install -y "$pkg"
	elif command_exists yum; then
		echo "Installing $pkg using yum..."
		sudo yum install -y "$pkg"
	elif command_exists dnf; then
		echo "Installing $pkg using dnf..."
		sudo dnf install -y "$pkg"
	else
		echo "No supported package manager found. Please install $pkg manually."
	fi
}

install_dependencies() {
	# Ensure the script is run with root privileges or that sudo is available.
	if ! command_exists sudo && [ "$EUID" -ne 0 ]; then
		echo "This script requires root privileges or sudo installed to install packages."
		exit 1
	fi

	# Define dependencies: key = command, value = package name.
	declare -A dependencies=(
		[lsb_release]="lsb-release"
		[lscpu]="util-linux"
		[free]="procps"
		[lsblk]="util-linux"
		[nvme]="nvme-cli"
		[numactl]="numactl"
		[ip]="iproute2"
		[top]="procps"
		[ps]="procps"
		[iostat]="sysstat"
		[dmidecode]="dmidecode"
		[numastat]="numastat"
	)

	# echo "Checking and Installing Dependencies"
	for cmd in "${!dependencies[@]}"; do
		if ! command_exists "$cmd"; then
			install_package "${dependencies[$cmd]}"
		fi
	done
	echo "Dependency Check Complete"
	echo
}

# Important commands for basic system info:
#   hostname, shows the system hostname
#   lsb_release, shows the OS version
#   uname, shows the kernel version
#   uptime -p, shows the system uptime in a human-readable format
print_basic_info() {
	info "========== Basic System Information =========="
	echo "Hostname: $(hostname)"
	if command_exists lsb_release; then
		echo "OS: $(lsb_release -d | cut -f2)"
	else
		echo "OS: Information not available (lsb_release not found)"
	fi
	echo "Kernel: $(uname -r)"
	echo "Architecture: $(uname -m)"
	echo "Uptime: $(uptime -p)"
	echo
}

# Important commands for CPU info:
#   lscpu, shows CPU architecture and details
#  /proc/cpuinfo, shows detailed CPU information
print_cpu_info() {
	info "========== CPU Information =========="
	if command_exists lscpu; then
		CPU_INFO=$(lscpu)
		echo "CPU Model: $(echo "$CPU_INFO" | grep 'Model name:' | awk -F: '{print $2}' | sed 's/^ *//')"
		echo "CPU vCores: $(echo "$CPU_INFO" | grep '^CPU(s):' | awk -F: '{print $2}' | sed 's/^ *//')"
		echo "CPU Sockets: $(echo "$CPU_INFO" | grep '^Socket(s):' | awk -F: '{print $2}' | sed 's/^ *//')"
		echo "CPU Cores/Socket: $(echo "$CPU_INFO" | grep '^Core(s) per socket:' | awk -F: '{print $2}' | sed 's/^ *//')"
		echo "CPU Threads/Core: $(echo "$CPU_INFO" | grep 'Thread(s) per core:' | awk -F: '{print $2}' | sed 's/^ *//')"
		echo "CPU Frequency: $(echo "$CPU_INFO" | grep 'MHz' | awk -F: '{print $2}' | sed 's/^ *//') MHz"
		info "CPU Cache:"
		echo "$CPU_INFO" | grep -i 'cache'
	else
		echo "lscpu command not found."
	fi
	echo
}

# Important commands for memory info:
# 	free -h, shows total, used, and free memory
# 	numactl --hardware, shows NUMA memory allocation
# 	numastat -m, shows per-NUMA-node memory usage
# 	dmidecode --type memory, shows detailed memory information
print_memory_info() {
	info "========== Memory Information =========="

	# Total System Memory
	if command_exists free; then
		echo "Total Memory:"
		free -h | awk '/Mem:/ {print "  " $2 " total, " $3 " used, " $4 " free"}'
		echo
	fi

	# NUMA Memory Layout
	if command_exists numactl; then
		echo "NUMA Memory Allocation:"
		numactl --hardware | awk '/node [0-9]+ size:/ {print "  " $0}'
		echo
	fi

	# Expanded details if --detailed flag is set
	if [ "$DETAILED" = true ]; then

		if command_exists numastat; then
			numastat -m
		else
			echo "lscpu command not found. Skipping memory manufacturer info."
		fi

		if command_exists dmidecode; then
			echo "Per-DIMM Memory Details:"
			sudo dmidecode --type memory | awk '
				BEGIN { skip = 0 }
				/Memory Device/ { skip = 0; header_printed = 0 }
				/Size: No Module Installed|Volatile Size: None/ { skip = 1 }
				skip == 0 && /Error Correction Type:|Size:|Type:|Speed:/ {
				if (!header_printed) { 
					printf "\n--------------------------------------\n"; 
					header_printed = 1 
				}
				sub(/^[ \t]+/, "  "); print
				}
			'
			echo

			# ECC Check
			echo "Checking ECC Support:"
			ECC_TYPE=$(sudo dmidecode -t 16 | grep "Error Correction Type:" | awk -F: '{print $2}' | xargs)
			if [[ "$ECC_TYPE" != "None" ]]; then
				echo "  ECC is enabled: $ECC_TYPE"
			else
				echo "  ECC is NOT enabled."
			fi
		else
			echo "dmidecode command not found. Skipping detailed memory info."
		fi
	fi

	echo
}

# Important commands for disk info:
#   lsblk - shows block device details (name, size, type, mountpoint, etc.)
#   cat /sys/block/*/queue/rotational - determines if device is rotational (HDD) or not (SSD/NVMe)
#   nvme list - lists NVMe drives and detailed controller/device info (requires nvme-cli)
#   df -h - shows mounted filesystem usage (useful for space, not disk type)
print_disk_info() {
	info "========== Disk Information =========="
	echo "Disk Details: (ROTA: 1 indicates rotational HDD, 0 indicates SSD/NVME)"
	if command_exists lsblk; then
		# tran means transport type, which can be:
		# sas - Serial Attached SCSI
		# sata - Serial ATA
		# nvme - Non-Volatile Memory Express
		lsblk -o NAME,SIZE,TYPE,ROTA,MOUNTPOINT,FSTYPE,TRAN
	else
		echo "lsblk command not found."
	fi

	if [ "$DETAILED" = false ]; then
		return
	fi

	# print model and vendor and serial number
	echo
	for disk in $(lsblk -dno NAME); do
		if [ -b "/dev/$disk" ]; then
			echo "Disk: /dev/$disk"
			echo "  Model: $(cat /sys/block/$disk/device/model 2>/dev/null || echo "N/A")"
			echo "  Vendor: $(cat /sys/block/$disk/device/vendor 2>/dev/null || echo "N/A")"
			echo "  Serial: $(cat /sys/block/$disk/device/serial 2>/dev/null || echo "N/A")"
		fi
	done

	if command_exists nvme; then
	    echo
		nvme list
	else
		echo "nvme command not found. Install nvme-cli to use this feature."
	fi
	echo
}

# Important commands for cache info:
#   cat /proc/meminfo - system-wide memory stats, including page cache
#   grep -i 'cached:' /proc/meminfo - shows current size of page cache
#   cat /proc/sys/vm/drop_caches - shows interface to manually drop cache (needs sudo, not used here)
#   cat /proc/sys/vm/swappiness - shows kernel's tendency to swap
#   cat /proc/sys/vm/dirty_{ratio,background_ratio} - shows thresholds for dirty page flushing
print_cache_info() {
	info "========== File System Cache =========="
	echo "Page Cache Info:"
	if [ -r /proc/meminfo ]; then
		grep -i 'cached:' /proc/meminfo
	else
		echo "/proc/meminfo not accessible."
	fi
	echo
}

# Important commands for NUMA info:
#   numactl --hardware - shows NUMA nodes, memory per node, CPU affinity per node
#   numastat -m - shows memory usage per NUMA node
#   numastat -c - shows cache miss locality breakdown
print_numa_info() {
	info "========== NUMA Information =========="
	if command_exists numactl; then
		numactl --hardware
	else
		echo "numactl command not found. Install numactl to use this feature."
	fi
	echo
}

# Important commands for network info:
#   hostname -I - shows assigned IP addresses
#   ip -brief link - shows summary of active network interfaces
#   ifconfig - deprecated; use ip instead (may need net-tools)
#   ethtool - shows NIC-specific settings (requires sudo)
#   ss, netstat - shows active sockets (ss is modern replacement for netstat)
#   ping, traceroute, mtr - latency/path testing tools
#   tcpdump, wireshark - packet capture and deep inspection (need sudo)
#   iperf - network bandwidth tester (useful with a server on the other end)
#   nload, iftop, nethogs, bmon - bandwidth visualization tools (optional extras)
print_network_info() {
	if [ "$DETAILED" = true ]; then
		info "========== Network Information =========="
		echo "IP Addresses:"
		if command_exists hostname; then
			hostname -I
		else
			echo "hostname command not found."
		fi
		echo
		echo "Active Network Interfaces:"
		if command_exists ip; then
			ip -brief link
		else
			echo "ip command not found."
		fi
		echo
	fi
}

# Important commands for running processes:
#   top -b -n1 - shows real-time top processes in batch mode (CPU-focused)
#   ps aux --sort=-%mem - shows memory-heavy processes, --sort=(-%mem or -%cpu)
#   htop, btop, glances, nmon - interactive process viewers (not used here, but worth exploring)
#   pmap <pid> - shows memory map of a process
#   lsof - lists open files and processes, 
#   lsof -u <username> - shows files opened by a user, 
#   lsof -p <PID> - shows files opened by a process
#   ps -p <PID> -o pid,ppid,cmd      # find by PID
#   ps -u <username> -o pid,ppid,cmd  # find by user
#   pgrep <name>                    # find by name
#   lsof -i :<port>                 # find process using a port
#   ss -ltnp | grep :<port>         # alternative to lsof for sockets
print_top_processes() {
	if [ "$DETAILED" = false ]; then
		return
	fi
	info "========== Top Processes by CPU Usage =========="
	if command_exists top; then
		top -b -n1 | head -15
	else
		echo "top command not found."
	fi
	echo
}

# Important commands for I/O statistics:
#   iostat -x - shows extended device-level I/O stats (requires sysstat)
#   vmstat, dstat - show system I/O, memory, CPU stats (optional)
#   iotop - shows I/O by process 
#   perf, blktrace - advanced I/O profiling (not used here, useful for deeper analysis)
#   sar - collects and reports system activity (requires sysstat)
#   pidstat - shows CPU and I/O stats per process (requires sysstat)
print_io_stats() {
	if [ "$DETAILED" = false ]; then
		return
	fi
	info "========== I/O Statistics =========="
	if command_exists iostat; then
		iostat -x 1 1 2>/dev/null || echo "iostat did not produce output."
	else
		echo "iostat command not found. Install sysstat to use this feature."
	fi
	echo
}

main() {
	install_dependencies
	print_basic_info
	print_cpu_info
	print_memory_info
	print_disk_info
	print_cache_info
	print_numa_info
	print_network_info
	print_top_processes
	print_io_stats
	echo "========== End of Report =========="
}

main
exit 0

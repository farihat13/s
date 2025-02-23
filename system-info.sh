#!/bin/bash
# =============================================================================
# Script: system-info.sh
# Description: Displays detailed system information (basic system, CPU, memory,
#              disk, cache, NUMA, and optionally network data) after ensuring
#              required packages are installed.
#
# Usage: ./system-info.sh [--network]
#   --network   Include network information in the report.
#
# Requirements: lsb_release, lscpu, free, lsblk, nvme (optional), numactl (optional),
#               ip, top, ps, and iostat (optional).
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Global flag to control network info output
INCLUDE_NETWORK=false

# -----------------------------------------------------------------------------
# Function: usage
# Description: Displays usage information.
# -----------------------------------------------------------------------------
usage() {
  echo "Usage: $0 [--network]"
  echo "  --network   Include network information in the report."
  exit 1
}

# -----------------------------------------------------------------------------
# Parse command line arguments
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --network)
      INCLUDE_NETWORK=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      ;;
  esac
done

# -----------------------------------------------------------------------------
# Function: command_exists
# Description: Checks if a command exists on the system.
# -----------------------------------------------------------------------------
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Function: install_package
# Description: Installs a package using the available package manager.
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Function: install_dependencies
# Description: Checks and installs any missing required packages.
# -----------------------------------------------------------------------------
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
  )

  echo "========== Checking and Installing Dependencies =========="
  for cmd in "${!dependencies[@]}"; do
    if ! command_exists "$cmd"; then
      echo "Command '$cmd' not found. Attempting to install package '${dependencies[$cmd]}'..."
      install_package "${dependencies[$cmd]}"
    else
      echo "Command '$cmd' found."
    fi
  done
  echo "========== Dependency Check Complete =========="
  echo
}

# -----------------------------------------------------------------------------
# Function: print_basic_info
# Description: Prints basic system information.
# -----------------------------------------------------------------------------
print_basic_info() {
  echo "========== Basic System Information =========="
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

# -----------------------------------------------------------------------------
# Function: print_cpu_info
# Description: Prints CPU-related information.
# -----------------------------------------------------------------------------
print_cpu_info() {
  echo "========== CPU Information =========="
  if command_exists lscpu; then
    CPU_INFO=$(lscpu)
    echo "CPU Model: $(echo "$CPU_INFO" | grep 'Model name:' | awk -F: '{print $2}' | sed 's/^ *//')"
    echo "CPU vCores: $(echo "$CPU_INFO" | grep '^CPU(s):' | awk -F: '{print $2}' | sed 's/^ *//')"
    echo "CPU Sockets: $(echo "$CPU_INFO" | grep '^Socket(s):' | awk -F: '{print $2}' | sed 's/^ *//')"
    echo "CPU Cores/Socket: $(echo "$CPU_INFO" | grep '^Core(s) per socket:' | awk -F: '{print $2}' | sed 's/^ *//')"
    echo "CPU Threads/Core: $(echo "$CPU_INFO" | grep 'Thread(s) per core:' | awk -F: '{print $2}' | sed 's/^ *//')"
    echo "CPU Frequency: $(echo "$CPU_INFO" | grep 'MHz' | awk -F: '{print $2}' | sed 's/^ *//') MHz"
    echo "CPU Cache:"
    echo "$CPU_INFO" | grep -i 'cache'
  else
    echo "lscpu command not found."
  fi
  echo
}

# -----------------------------------------------------------------------------
# Function: print_memory_info
# Description: Prints memory usage details.
# -----------------------------------------------------------------------------
print_memory_info() {
  echo "========== Memory Information =========="
  if command_exists free; then
    free -h
  else
    echo "free command not found."
  fi
  echo
}

# -----------------------------------------------------------------------------
# Function: print_disk_info
# Description: Prints disk details using lsblk and (optionally) nvme.
# -----------------------------------------------------------------------------
print_disk_info() {
  echo "========== Disk Information =========="
  # Disk usage (df -h) is commented out by default.
  # echo "Disk Usage:"
  # df -h
  echo "Disk Details: (ROTA: 1 indicates rotational HDD, 0 indicates SSD/NVME)"
  if command_exists lsblk; then
    lsblk -o NAME,SIZE,TYPE,ROTA,MOUNTPOINT,FSTYPE
  else
    echo "lsblk command not found."
  fi
  echo
  if command_exists nvme; then
    nvme list
  else
    echo "nvme command not found. Install nvme-cli to use this feature."
  fi
  echo
}

# -----------------------------------------------------------------------------
# Function: print_cache_info
# Description: Displays file system page cache information.
# -----------------------------------------------------------------------------
print_cache_info() {
  echo "========== File System Cache =========="
  echo "Page Cache Info:"
  if [ -r /proc/meminfo ]; then
    grep -i 'cached:' /proc/meminfo
  else
    echo "/proc/meminfo not accessible."
  fi
  echo
}

# -----------------------------------------------------------------------------
# Function: print_numa_info
# Description: Displays NUMA hardware information.
# -----------------------------------------------------------------------------
print_numa_info() {
  echo "========== NUMA Information =========="
  if command_exists numactl; then
    numactl --hardware
  else
    echo "numactl command not found. Install numactl to use this feature."
  fi
  echo
}

# -----------------------------------------------------------------------------
# Function: print_network_info
# Description: Prints network information if the --network flag is provided.
# -----------------------------------------------------------------------------
print_network_info() {
  if [ "$INCLUDE_NETWORK" = true ]; then
    echo "========== Network Information =========="
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

# -----------------------------------------------------------------------------
# Function: print_top_processes
# Description: Shows the top processes by CPU and memory usage.
# -----------------------------------------------------------------------------
print_top_processes() {
  echo "========== Top Processes by CPU Usage =========="
  if command_exists top; then
    top -b -n1 | head -15
  else
    echo "top command not found."
  fi
  echo
  echo "========== Top Processes by Memory Usage =========="
  if command_exists ps; then
    ps aux --sort=-%mem | head -10
  else
    echo "ps command not found."
  fi
  echo
}

# -----------------------------------------------------------------------------
# Function: print_io_stats
# Description: Displays I/O statistics.
# -----------------------------------------------------------------------------
print_io_stats() {
  echo "========== I/O Statistics =========="
  if command_exists iostat; then
    iostat -x 1 1 2>/dev/null || echo "iostat did not produce output."
  else
    echo "iostat command not found. Install sysstat to use this feature."
  fi
  echo
}

# -----------------------------------------------------------------------------
# Main function: Installs dependencies and calls all other functions in order.
# -----------------------------------------------------------------------------
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

#!/bin/bash
# =============================================================================
# Script: numa-mbw.sh
# Description: NUMA-aware memory bandwidth benchmarking using `mbw`
#
# Usage: ./numa-mbw.sh <size_in_mib>
#   Example: ./numa-mbw.sh 1000
#
# Features:
#   - Detects NUMA nodes
#   - Runs `mbw` on different NUMA nodes
#   - Compares NUMA-local vs. NUMA-remote memory performance
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# Check if numactl and mbw are installed
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists numactl || ! command_exists mbw; then
  echo "Error: This script requires 'numactl' and 'mbw'."
  echo "Install them using: sudo apt-get install numactl mbw"
  exit 1
fi

# Default memory test size in MiB (if not provided)
MEM_SIZE="${1:-1000}"

# Get NUMA node count
NUMA_NODES=$(numactl --hardware | grep "available:" | awk '{print $2}')

echo "========== NUMA Configuration =========="
numactl --hardware
echo

if [[ "$NUMA_NODES" -eq 1 ]]; then
  echo "⚠️  Only one NUMA node detected. Running standard memory test."
  mbw "$MEM_SIZE"
  exit 0
fi

echo "========== NUMA-Aware Memory Benchmarking =========="
echo "Testing memory bandwidth with $MEM_SIZE MiB across NUMA nodes..."
echo

# Run `mbw` on each NUMA node
for NODE in $(seq 0 $((NUMA_NODES - 1))); do
  echo "Running on NUMA Node $NODE (Local Memory Access)"
  numactl --membind="$NODE" --cpunodebind="$NODE" mbw "$MEM_SIZE"
  echo
done

# Test NUMA-remote memory access (binding CPU to one node and memory to another)
if [[ "$NUMA_NODES" -ge 2 ]]; then
  echo "========== Cross-NUMA Memory Access Test =========="
  echo "Forcing memory on NUMA Node 0 and CPU on NUMA Node 1"
  numactl --membind=0 --cpunodebind=1 mbw "$MEM_SIZE"
  echo

  echo "Forcing memory on NUMA Node 1 and CPU on NUMA Node 0"
  numactl --membind=1 --cpunodebind=0 mbw "$MEM_SIZE"
  echo
fi

echo "NUMA-aware benchmarking complete!"

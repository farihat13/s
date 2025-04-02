#!/bin/bash

# === System Monitoring and Resource Inspection ===
#   htop          # Interactive process viewer
#   numactl       # NUMA policy and affinity control
#   lsof          # List open files
#   strace        # Trace system calls
#   dstat         # Real-time resource usage
#   iotop         # I/O usage by processes
#   iftop         # Network usage per interface
#   iperf3        # Network throughput tester

# === Performance & Profiling ===
#   linux-tools-common          # perf, etc.
#   linux-tools-$(uname -r)     # Version-specific perf
#   sysstat                     # Includes sar, iostat
#   hwloc                       # Hardware topology
#   cpufrequtils                # CPU frequency control
#   ethtool                     # Ethernet interface config
#   irqbalance                  # Distribute IRQs

# === Development ===
#   build-essential             # GCC, make, etc.
#   clang                       # LLVM Clang compiler
#   llvm                        # LLVM backend
#   gdb                         # Debugger
#   valgrind                    # Memory error detector

#   # === Tracing & Observability ===
#   bpfcc-tools                 # BCC tools (execsnoop, etc.)
#   bpftrace                    # High-level BPF tracing

# === Misc ===
#   net-tools                   # ifconfig, netstat, etc.
#   tcpdump                     # Packet capture
#   dmidecode                   # BIOS/hardware info
#   time                        # Run time/memory stats
#   stress-ng                   # Load testing
#   procps                      # Includes watch, top, etc.
sudo apt update && sudo apt install -y \
  htop numactl lsof strace dstat iotop iftop iperf3 \
  linux-tools-common linux-tools-$(uname -r) \
  sysstat hwloc cpufrequtils ethtool irqbalance \
  build-essential clang llvm gdb valgrind \
  bpfcc-tools bpftrace \
  net-tools tcpdump dmidecode \
  time stress-ng procps

#!/bin/bash

# System monitoring script
# Author: ap
# date : $(date)


# log file 
LOG_FILE="system_monitoring.log"

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=90
DISK_THRESHOLD=10

# detect OS
OS=$(uname)
if [[ "$OS" == "Linux" ]]; then 
    if [[ -f /etc/redhat-release ]] ; then 
        DISTRO="RedHat"
    elif [[ -f /etc/debian_version ]] ; then 
        DISTRO="Debian"
    else
        DISTRO="Other-linux"
    fi

elif [[ "$OS" == "Darwin" ]]; then
    DISTRO="Mac"
else
    DISTRO="Unknown"
    echo "Unknown OS : $OS" | tee -a $LOG_FILE
    exit 1
fi


# Function to check CPU usage
check_cpu_usage() {
    if [[ "$DISTRO" == "macOS" ]]; then
        CPU_USAGE=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
    else
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    fi
    CPU_USAGE=$(printf "%.0f" $CPU_USAGE)
    echo "CPU Usage: $CPU_USAGE%"
    if (( CPU_USAGE > CPU_THRESHOLD )); then
        echo "[ALERT] CPU usage exceeded $CPU_THRESHOLD%" | tee -a $LOG_FILE
    fi
}

# Function to check memory usage
check_memory_usage() {
    if [[ "$DISTRO" == "macOS" ]]; then
        MEMORY_FREE=$(vm_stat | grep "free" | awk '{print $3}' | sed 's/\.//')
        MEMORY_ACTIVE=$(vm_stat | grep "active" | awk '{print $3}' | sed 's/\.//')
        MEMORY_INACTIVE=$(vm_stat | grep "inactive" | awk '{print $3}' | sed 's/\.//')
        MEMORY_WIRED=$(vm_stat | grep "wired" | awk '{print $4}' | sed 's/\.//')
        MEMORY_TOTAL=$(( MEMORY_FREE + MEMORY_ACTIVE + MEMORY_INACTIVE + MEMORY_WIRED ))
        MEMORY_USED=$(( MEMORY_ACTIVE + MEMORY_WIRED ))
        MEMORY_USAGE=$(( MEMORY_USED * 100 / MEMORY_TOTAL ))
    else
        MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    fi
    MEMORY_USAGE=$(printf "%.0f" $MEMORY_USAGE)
    echo "Memory Usage: $MEMORY_USAGE%"
    if (( MEMORY_USAGE > MEMORY_THRESHOLD )); then
        echo "[ALERT] Memory usage exceeded $MEMORY_THRESHOLD%" | tee -a $LOG_FILE
    fi
}



# Function to check disk usage
check_disk_usage() {
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    echo "Disk Usage: $DISK_USAGE%"
    if (( DISK_USAGE > (100 - DISK_THRESHOLD) )); then
        echo "[ALERT] Disk space below $DISK_THRESHOLD% free" | tee -a $LOG_FILE
    fi
}
    

# Main monitoring loop
echo "Starting System Monitoring on $DISTRO... (Press Ctrl+C to stop)"
echo "Logging to $LOG_FILE"
echo "-----------------------" >> $LOG_FILE
echo "Monitoring started at $(date) on $DISTRO" >> $LOG_FILE
echo "-----------------------" >> $LOG_FILE

while true; do
    echo "---------------------------------"
    echo "$(date)"
    check_cpu_usage
    check_memory_usage
    check_disk_usage
    echo "---------------------------------" >> $LOG_FILE
    sleep 5
done
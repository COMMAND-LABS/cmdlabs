#!/bin/bash

# Script to kill all processes running on Kalygo microservice ports
# Usage: ./dev-kill-ports.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ports used by Kalygo microservices
PORTS=(4000 4100 9000 7100 3000 8080 8081)
SERVICE_NAMES=(
    "kalygo3-ai-api"
    "kalygo3-completion-api"
    "kalygo3-embeddings-api"
    "kalygo3-reranker-api"
    "kalygo3-ui"
    "kalygo3-qna-ingest-cloud-function"
    "kalygo3-txt-ingest-cloud-function"
)

echo -e "${BLUE}Checking and killing processes on Kalygo microservice ports...${NC}\n"

KILLED_COUNT=0

# Function to check if a process is a system process
is_system_process() {
    local pid=$1
    local comm=$(ps -p $pid -o comm= 2>/dev/null || echo "")
    local path=$(ps -p $pid -o command= 2>/dev/null || echo "")
    
    # Check for specific system process names
    if [[ "$comm" == "ControlCenter" ]] || \
       [[ "$comm" == "kernel_task" ]] || \
       [[ "$comm" == "launchd" ]] || \
       [[ "$comm" == "WindowServer" ]] || \
       [[ "$comm" == "Dock" ]] || \
       [[ "$comm" == "Finder" ]] || \
       [[ "$comm" == "SystemUIServer" ]]; then
        return 0  # It's a system process
    fi
    
    # Check if it's in system directories
    if [[ "$path" == /System/* ]] || \
       [[ "$path" == /Library/* ]] || \
       [[ "$path" == /usr/sbin/* ]] || \
       [[ "$path" == /sbin/* ]]; then
        return 0  # It's a system process
    fi
    
    # Check if owned by root (on macOS, system processes are often root)
    local owner=$(ps -p $pid -o user= 2>/dev/null || echo "")
    if [[ "$owner" == "root" ]] && [[ "$comm" != "" ]]; then
        # Additional check: if it's a known system binary
        if [[ "$path" == /* ]] && [[ ! "$path" == /Users/* ]] && [[ ! "$path" == /tmp/* ]]; then
            return 0  # Likely a system process
        fi
    fi
    
    return 1  # Not a system process
}

# Function to kill process on a specific port
kill_port() {
    local port=$1
    local service_name=$2
    
    # Check if port is in use
    if lsof -ti:$port > /dev/null 2>&1; then
        # Get process info before killing
        local pids=$(lsof -ti:$port)
        local pid_list=($pids)
        local process_info=$(lsof -i:$port 2>/dev/null | tail -n +2 | head -1 || echo "unknown")
        local comm=$(ps -p $pids -o comm= 2>/dev/null | head -1 || echo "unknown")
        local full_path=$(ps -p $pids -o command= 2>/dev/null | head -1 || echo "unknown")
        
        echo -e "${YELLOW}Port ${port} (${service_name}) is in use${NC}"
        echo -e "  PID(s): ${pids}"
        echo -e "  Process: ${comm}"
        echo -e "  Path: ${full_path}"
        
        # Check if it's a system process
        local skip_kill=false
        for pid in "${pid_list[@]}"; do
            if is_system_process "$pid"; then
                echo -e "  ${RED}⚠ WARNING: This appears to be a system process. Skipping kill to avoid system instability.${NC}"
                echo -e "  ${YELLOW}You may need to manually change the port for ${service_name} or stop the system service.${NC}"
                skip_kill=true
                break
            fi
        done
        
        if [ "$skip_kill" = false ]; then
            # Try graceful kill first
            if kill -TERM $pids 2>/dev/null; then
                sleep 1
                # Force kill if still running
                if lsof -ti:$port > /dev/null 2>&1; then
                    kill -9 $pids 2>/dev/null && echo -e "  ${RED}Force killed (SIGKILL)${NC}" || echo -e "  ${RED}Failed to kill process${NC}"
                else
                    echo -e "  ${GREEN}Terminated gracefully${NC}"
                    KILLED_COUNT=$((KILLED_COUNT + 1))
                fi
            else
                # If TERM fails, try KILL
                if kill -9 $pids 2>/dev/null; then
                    echo -e "  ${RED}Force killed (SIGKILL)${NC}"
                    KILLED_COUNT=$((KILLED_COUNT + 1))
                else
                    echo -e "  ${RED}Failed to kill process (may require sudo)${NC}"
                fi
            fi
        fi
        echo ""
    else
        echo -e "${GREEN}Port ${port} (${service_name}) is free${NC}"
    fi
}

# Kill processes on each port
for i in "${!PORTS[@]}"; do
    kill_port "${PORTS[$i]}" "${SERVICE_NAMES[$i]}"
done

echo -e "${BLUE}Summary:${NC}"
if [ $KILLED_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All ports are free - no processes were killed${NC}"
else
    echo -e "${YELLOW}✓ Killed processes on ${KILLED_COUNT} port(s)${NC}"
fi

echo -e "\n${BLUE}Verifying all ports are now free...${NC}"
ALL_FREE=true
SYSTEM_PORTS=()
for i in "${!PORTS[@]}"; do
    if lsof -ti:"${PORTS[$i]}" > /dev/null 2>&1; then
        local pids=$(lsof -ti:"${PORTS[$i]}")
        local is_system=false
        for pid in $pids; do
            if is_system_process "$pid"; then
                is_system=true
                break
            fi
        done
        
        if [ "$is_system" = true ]; then
            echo -e "${YELLOW}⚠ Port ${PORTS[$i]} (${SERVICE_NAMES[$i]}) is still in use by a system process${NC}"
            SYSTEM_PORTS+=("${PORTS[$i]}")
        else
            echo -e "${RED}✗ Port ${PORTS[$i]} (${SERVICE_NAMES[$i]}) is still in use${NC}"
        fi
        ALL_FREE=false
    fi
done

if [ "$ALL_FREE" = true ]; then
    echo -e "${GREEN}✓ All ports are now free!${NC}"
elif [ ${#SYSTEM_PORTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠ Some ports are still in use by system processes: ${SYSTEM_PORTS[*]}${NC}"
    echo -e "${YELLOW}   Consider using different ports for those services or stopping the system services.${NC}"
else
    echo -e "${YELLOW}⚠ Some ports may still be in use. You may need to run this script again or manually check.${NC}"
fi


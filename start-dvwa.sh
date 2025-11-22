#!/usr/bin/env bash

# DVWA Docker Startup Script
# This script automates the deployment of DVWA (Damn Vulnerable Web Application) using Docker
# It detects the Linux distribution, installs Docker if needed, and starts the DVWA container

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/dvwa-docker.log"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to log messages
log_message() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        log_message "Detected distribution: $DISTRO"
    else
        print_message "$RED" "Cannot detect Linux distribution"
        exit 1
    fi
}

# Function to check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        log_message "Docker is already installed"
        docker --version | tee -a "$LOG_FILE"
        return 0
    else
        log_message "Docker is not installed"
        return 1
    fi
}

# Function to install Docker on Debian/Ubuntu
install_docker_debian() {
    log_message "Installing Docker on Debian/Ubuntu..."
    sudo apt-get update | tee -a "$LOG_FILE"
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release | tee -a "$LOG_FILE"
    
    # Add Docker's official GPG key (using official Docker installation method)
    # This is the standard method from https://docs.docker.com/engine/install/
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update | tee -a "$LOG_FILE"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin | tee -a "$LOG_FILE"
    
    log_message "Docker installed successfully"
}

# Function to install Docker on RHEL/CentOS/Fedora
install_docker_rhel() {
    log_message "Installing Docker on RHEL/CentOS/Fedora..."
    
    # Detect package manager (dnf is preferred, fallback to yum)
    if command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
    else
        PKG_MGR="yum"
    fi
    
    sudo "$PKG_MGR" install -y yum-utils | tee -a "$LOG_FILE"
    sudo "$PKG_MGR" config-manager --add-repo "https://download.docker.com/linux/$DISTRO/docker-ce.repo" 2>&1 | tee -a "$LOG_FILE" || \
        sudo yum-config-manager --add-repo "https://download.docker.com/linux/$DISTRO/docker-ce.repo" | tee -a "$LOG_FILE"
    sudo "$PKG_MGR" install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin | tee -a "$LOG_FILE"
    
    log_message "Docker installed successfully"
}

# Function to install Docker on Arch Linux
install_docker_arch() {
    log_message "Installing Docker on Arch Linux..."
    sudo pacman -Sy --noconfirm docker | tee -a "$LOG_FILE"
    
    log_message "Docker installed successfully"
}

# Function to install Docker based on distribution
install_docker() {
    case $DISTRO in
        ubuntu|debian)
            install_docker_debian
            ;;
        rhel|centos|fedora)
            install_docker_rhel
            ;;
        arch|manjaro)
            install_docker_arch
            ;;
        *)
            print_message "$RED" "Unsupported distribution: $DISTRO"
            print_message "$YELLOW" "Please install Docker manually from: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
}

# Function to start Docker service
start_docker_service() {
    log_message "Checking Docker service status..."
    
    if ! sudo systemctl is-active --quiet docker; then
        log_message "Starting Docker service..."
        sudo systemctl start docker | tee -a "$LOG_FILE"
        sudo systemctl enable docker | tee -a "$LOG_FILE"
        log_message "Docker service started"
    else
        log_message "Docker service is already running"
    fi
}

# Function to check if user is in docker group
check_docker_group() {
    if ! groups | grep -q docker; then
        log_message "Adding current user to docker group..."
        sudo usermod -aG docker "$USER"
        print_message "$YELLOW" "User added to docker group. You may need to log out and back in for this to take effect."
        print_message "$YELLOW" "For now, commands will run with sudo."
        USE_SUDO="yes"
    else
        USE_SUDO="no"
    fi
}

# Function to run docker commands with or without sudo
run_docker() {
    if [ "$USE_SUDO" = "yes" ]; then
        sudo docker "$@"
    else
        docker "$@"
    fi
}

# Function to stop existing DVWA containers
stop_existing_containers() {
    log_message "Checking for existing DVWA containers..."
    
    # Check if any container is using port 80 and stop all of them
    if run_docker ps --format '{{.Ports}}' | grep -q ':80->'; then
        print_message "$YELLOW" "Port 80 is already in use. Stopping existing containers..."
        # Get all container IDs using port 80
        CONTAINER_IDS=$(run_docker ps --format '{{.ID}} {{.Ports}}' | grep ':80->' | awk '{print $1}')
        if [ -n "$CONTAINER_IDS" ]; then
            # Stop each container
            while IFS= read -r CONTAINER_ID; do
                run_docker stop "$CONTAINER_ID" | tee -a "$LOG_FILE"
                log_message "Stopped container: $CONTAINER_ID"
            done <<< "$CONTAINER_IDS"
        fi
    fi
}

# Function to pull DVWA image
pull_dvwa_image() {
    log_message "Pulling DVWA Docker image..."
    run_docker pull vulnerables/web-dvwa | tee -a "$LOG_FILE"
    log_message "DVWA image pulled successfully"
}

# Function to run DVWA container
run_dvwa_container() {
    log_message "Starting DVWA container..."
    print_message "$GREEN" "Starting DVWA on http://localhost:80"
    print_message "$GREEN" "Logs are being saved to: $LOG_FILE"
    print_message "$YELLOW" "Press Ctrl+C to stop the container"
    
    # Run the container and redirect output to log file and console
    run_docker run --rm -it -p 80:80 vulnerables/web-dvwa 2>&1 | tee -a "$LOG_FILE"
}

# Main script execution
main() {
    print_message "$GREEN" "=== DVWA Docker Startup Script ==="
    log_message "Script started"
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_message "$YELLOW" "Warning: Running as root. This is not recommended."
    fi
    
    # Detect distribution
    detect_distro
    
    # Check and install Docker if needed
    if ! check_docker; then
        print_message "$YELLOW" "Docker not found. Installing..."
        install_docker
    fi
    
    # Start Docker service
    start_docker_service
    
    # Check docker group membership
    check_docker_group
    
    # Stop any existing containers on port 80
    stop_existing_containers
    
    # Pull DVWA image
    pull_dvwa_image
    
    # Run DVWA container
    run_dvwa_container
    
    log_message "Script completed"
}

# Run main function
main

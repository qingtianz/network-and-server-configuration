#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
USERNAME="newuser"                 # Specify the new user's username
USER_HOME="/home/$USERNAME"       # Specify the new user's home directory
ALLOWED_NETWORK="192.168.0.0/24"   # Define the allowed outgoing network
LOCALHOST="127.0.0.1"              # Localhost IP

# Function to check if the script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This script must be run as root. Use sudo."
        exit 1
    fi
}

# Function to create a new user
create_user() {
    if id "$USERNAME" &>/dev/null; then
        echo "User '$USERNAME' already exists. Skipping user creation."
    else
        echo "Creating user '$USERNAME' with home directory '$USER_HOME'..."
        sudo adduser --home "$USER_HOME" --gecos "" "$USERNAME"
        echo "User '$USERNAME' created successfully."
    fi
}

# Function to retrieve the UID of the new user
get_user_uid() {
    USER_UID=$(id -u "$USERNAME")
    echo "User '$USERNAME' has UID: $USER_UID"
}

# Function to backup existing iptables rules
backup_iptables() {
    BACKUP_FILE="/root/iptables-backup-$(date +%F).conf"
    echo "Backing up current iptables rules to '$BACKUP_FILE'..."
    sudo iptables-save > "$BACKUP_FILE"
    echo "Backup completed."
}

# Function to configure iptables for the new user
configure_iptables() {
    echo "Configuring iptables rules for user '$USERNAME' (UID: $USER_UID)..."

    # Allow outgoing traffic to the allowed network
    sudo iptables -A OUTPUT -m owner --uid-owner "$USER_UID" -d "$ALLOWED_NETWORK" -j ACCEPT
    echo "Allowed outgoing traffic for UID $USER_UID to $ALLOWED_NETWORK."

    # Allow outgoing traffic to localhost
    sudo iptables -A OUTPUT -m owner --uid-owner "$USER_UID" -d "$LOCALHOST" -j ACCEPT
    echo "Allowed outgoing traffic for UID $USER_UID to $LOCALHOST."

    # Drop all other outgoing traffic for the new user
    sudo iptables -A OUTPUT -m owner --uid-owner "$USER_UID" -j DROP
    echo "Dropped all other outgoing traffic for UID $USER_UID."
}

# Function to install and configure iptables-persistent for rule persistence
setup_persistence() {
    echo "Installing iptables-persistent to ensure rules persist across reboots..."
    
    # Install iptables-persistent if not already installed
    if ! dpkg -l | grep -q iptables-persistent; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
        echo "iptables-persistent installed successfully."
    else
        echo "iptables-persistent is already installed. Skipping installation."
    fi

    # Save current iptables rules
    echo "Saving current iptables rules..."
    sudo netfilter-persistent save
    echo "iptables rules saved successfully."
}

# Function to display completion message
completion_message() {
    echo "------------------------------------------------------------"
    echo "User '$USERNAME' has been created and outgoing internet access"
    echo "has been restricted successfully."
    echo "Incoming traffic is managed separately via UFW."
    echo "------------------------------------------------------------"
}

# Main Execution Flow
main() {
    check_root
    create_user
    get_user_uid
    backup_iptables
    configure_iptables
    setup_persistence
    completion_message
}

# Invoke the main function
main

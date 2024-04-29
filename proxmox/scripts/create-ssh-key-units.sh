#!/bin/bash

# Generate SSH host keys if missing
generate_ssh_keys() {
    if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
        echo "Generating SSH host keys..."
        ssh-keygen -A
    fi
}

# Create generate-ssh-keys.service unit file
create_service_unit() {
    echo "Creating generate-ssh-keys.service unit file..."
    cat <<EOF > /etc/systemd/system/generate-ssh-keys.service
[Unit]
Description=Generate SSH host keys if missing
ConditionPathExists=!/etc/ssh/ssh_host_rsa_key

[Service]
Type=oneshot
ExecStart=/usr/bin/ssh-keygen -A
EOF
}

# Configure SSH service dependency on key generation
configure_ssh_dependency() {
    echo "Configuring SSH service dependency on key generation..."
    mkdir -p /etc/systemd/system/ssh.service.d
    cat <<EOF > /etc/systemd/system/ssh.service.d/dependency.conf
[Unit]
Requires=generate-ssh-keys.service
After=generate-ssh-keys.service
EOF
}

# Enable and start key generation service
enable_start_service() {
    echo "Enabling and starting key generation service..."
    systemctl enable generate-ssh-keys.service
    systemctl start generate-ssh-keys.service
}

# Reload systemd daemon
reload_systemd() {
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
}

# Main function
main() {
    generate_ssh_keys
    create_service_unit
    configure_ssh_dependency
    enable_start_service
    reload_systemd
    echo "Setup completed."
}

# Execute main function
main

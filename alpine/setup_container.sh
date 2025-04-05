#!/bin/bash

apk add \
    bash \
    bash-completion \
    coreutils \
    curl \
    gcompat \
    git \
    libstdc++ \
    openssh-server \
    python3 \
    py3-pip \
    sudo \
    util-linux  \
    zsh \
    zsh-autosuggestions \
    zsh-completions \
    zsh-syntax-highlighting \
    zsh-vcs \
    apk-tools-zsh-completion \
    curl-zsh-completion \
    git-zsh-completion \
    openrc-zsh-completion 

echo "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/local.conf
sysctl -p /etc/sysctl.d/local.conf

sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config
rc-update add sshd
rc-service sshd restart

passwd -d root

# Create user 'anvil' if it doesn't exist
if ! id "anvil" >/dev/null 2>&1; then
    adduser -s $(which zsh) -D anvil
    passwd anvil
    echo "User 'anvil' created."
else
    echo "User 'anvil' already exists."
fi

echo "anvil ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/anvil
chmod 440 /etc/sudoers.d/anvil

# Set up SSH directory
sudo -u anvil mkdir -p /home/anvil/.ssh
sudo -u anvil chmod 700 /home/anvil/.ssh

# Prompt for GitHub username
read -p "Enter GitHub username: " GITHUB_USER

# Download GitHub SSH keys
if wget -qO- "https://github.com/$GITHUB_USER.keys" > /home/anvil/.ssh/authorized_keys; then
    echo "SSH keys imported for GitHub user: $GITHUB_USER"
else
    echo "Failed to retrieve SSH keys for user: $GITHUB_USER"
    exit 1
fi

# Set correct permissions
chown -R anvil:anvil /home/anvil/.ssh
chmod 600 /home/anvil/.ssh/authorized_keys

echo "Setup complete. User 'anvil' can now SSH using GitHub keys."

#!/bin/bash

# curl -s https://raw.githubusercontent.com/traefikturkey/onvoy/main/proxmox/scripts/add_github_ssh_keys.sh | bash -s <your_github_username>

if [ "$#" -ne 1 ]; then
    echo "Please provide a github username."
    exit 1
fi

keys=$(wget -qO- https://github.com/$1.keys)
echo "$keys" | while read -r key
do
    if [ -f "~/.ssh/authorized_keys" ] && ! grep "$key" "~/.ssh/authorized_keys" &> /dev/null
    then
        echo "$key" >> "~/.ssh/authorized_keys"
    fi
done

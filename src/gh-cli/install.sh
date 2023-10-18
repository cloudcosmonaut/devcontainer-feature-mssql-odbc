#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ -z "${_REMOTE_USER}" ]; then
    echo -e 'Feature script must be executed by a tool that implements the dev container specification. See https://containers.dev/ for more information.'
    exit 1
fi

install_apt() {
    export ACCEPT_EULA=Y
    apt update
    apt install -y \
        apt-transport-https \
        curl \
        gnupg

    curl -Ssf https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor | tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    apt update
    apt install gh -y
}

set -euo pipefail

. /etc/os-release

case "${ID}" in
    debian) install_apt ;;
    ubuntu) install_apt ;;

    *)
        echo "Unsupported platform, please create a PR at https://github.com/cloudcosmonaut/devcontainer-features"
        exit 1
    ;;
esac

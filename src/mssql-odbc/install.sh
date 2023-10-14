#!/bin/bash

INSTALL_VERSION=${VERSION:-18}
INSTALLTOOLS=${INSTALLTOOLS:-false}

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

    if [ "${INSTALLTOOLS}" = true ]; then
        if [ "${INSTALL_VERSION}" = "17" ]; then
            apt install -y mssql-tools
        else
            apt install -y mssql-tools${INSTALL_VERSION}
        fi
    else
        apt install -y msodbcsql${INSTALL_VERSION}
    fi

    # Add symlink for tools location for v18, so the path from the configuration is still valid
    if [ "${INSTALLTOOLS}" = true ] && [ "${INSTALL_VERSION}" = "18" ]; then
        ln -s /opt/mssql-tools${INSTALL_VERSION} /opt/mssql-tools
    fi
}

install_debian() {
    export DEBIAN_FRONTEND=noninteractive
    export ACCEPT_EULA=Y
    apt update -y
    apt install -y \
        apt-transport-https \
        curl \
        gnupg \
        lsb-release

    if [[ "12" == "$VERSION_ID" ]];
    then
        # explicitly set version to 11, as MS does not provide a 12 version
        apt update && apt install -y gpg
        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

        curl -Ssf https://packages.microsoft.com/config/debian/11/prod.list | tee /etc/apt/sources.list.d/mssql-release.list

    else
        curl -Ssf https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc

        curl -Ssf https://packages.microsoft.com/config/debian/$VERSION_ID/prod.list | tee /etc/apt/sources.list.d/mssql-release.list

    fi

    install_apt
}

install_ubuntu() {
    apt update -y
    apt install -y \
        apt-transport-https \
        curl \
        gnupg \
        lsb-release

    if ! [[ "18.04 20.04 22.04 23.04" == *"$(lsb_release -rs)"* ]];
    then
        echo "Ubuntu $(lsb_release -rs) is not currently supported.";
        exit;
    fi

    curl -Ssf https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc

    curl -Ssf https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | tee /etc/apt/sources.list.d/mssql-release.list

    install_apt
}

set -euo pipefail

. /etc/os-release

case "${ID}" in
    debian) install_debian ;;
    ubuntu) install_ubuntu ;;

    *)
        echo "Unsupported platform, please create a PR at https://github.com/cloudcosmonaut/devcontainer-features"
        exit 1
    ;;
esac

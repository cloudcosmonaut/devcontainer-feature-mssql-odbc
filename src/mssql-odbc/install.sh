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

install_alpine_17() {
    curl -sSfO https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.5.1-1_amd64.apk

    curl -sSfO https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.5.1-1_amd64.sig

    curl https://packages.microsoft.com/keys/microsoft.asc  | gpg --import -
    gpg --verify msodbcsql17_17.10.5.1-1_amd64.sig msodbcsql17_17.10.5.1-1_amd64.apk

    apk add --allow-untrusted msodbcsql17_17.10.5.1-1_amd64.apk

    if [["${INSTALLTOOLS}" == "true" ]] ; then
        curl -sSfO https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.apk

        curl -sSfO https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.sig

        gpg --verify mssql-tools_17.10.1.1-1_amd64.sig mssql-tools_17.10.1.1-1_amd64.apk

        apk add --allow-untrusted mssql-tools_17.10.1.1-1_amd64.apk
    fi
}

install_alpine_18() {
    case $(uname -m) in
        x86_64) architecture="amd64" ;;
        arm64) architecture="arm64" ;;
        *)
            echo "Alpine architecture $(uname -m) is not currently supported."
            exit
        ;;
    esac

    curl -sSfO https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_$architecture.apk

    curl -sSfO https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_$architecture.sig

    curl https://packages.microsoft.com/keys/microsoft.asc  | gpg --import -
    gpg --verify msodbcsql18_18.3.2.1-1_$architecture.sig msodbcsql18_18.3.2.1-1_$architecture.apk

    sudo apk add --allow-untrusted msodbcsql18_18.3.2.1-1_$architecture.apk

    if [["${INSTALLTOOLS}" == "true" ]] ; then
        curl -sSfO https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_18.3.1.1-1_$architecture.apk

        curl -sSfO https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_18.3.1.1-1_$architecture.sig

        gpg --verify mssql-tools18_18.3.1.1-1_$architecture.sig mssql-tools18_18.3.1.1-1_$architecture.apk

        sudo apk add --allow-untrusted mssql-tools18_18.3.1.1-1_$architecture.apk
    fi
}

install_alpine() {
    apk add curl gnupg

    case ${INSTALL_VERSION} in
        17) install_alpine_17 ;;
        18) install_alpine_18 ;;
        *)
            echo "Unsupported version, please create a PR or an issue."
            exit 1
        ;;
    esac
}

set -euo pipefail

. /etc/os-release

case "${ID}" in
    debian) install_debian ;;
    ubuntu) install_ubuntu ;;
    alpine) install_alpine ;;

    *)
        echo "Unsupported platform, please create a PR at https://github.com/cloudcosmonaut/devcontainer-features"
        exit 1
    ;;
esac

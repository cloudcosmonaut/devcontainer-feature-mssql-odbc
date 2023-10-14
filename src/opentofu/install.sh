#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ -z "${_REMOTE_USER}" ]; then
    echo -e 'Feature script must be executed by a tool that implements the dev container specification. See https://containers.dev/ for more information.'
    exit 1
fi

install_package() {
    case "$(uname -m)" in
        x86_64) ARCH=amd64 ;;

        *)
            echo "Unsupported architecture, please create a PR at https://github.com/cloudcosmonaut/devcontainer-features"
            exit 1
        ;;
    esac

    latest=$(curl https://github.com/opentofu/opentofu/releases/latest -H 'accept: application/json' -LfsS | jq '.tag_name' -r)

    curl -fsSL "https://github.com/opentofu/opentofu/releases/download/${latest}/tofu_${latest:1}_${ARCH}.deb" --output tofu_${latest:1}_${ARCH}.deb

    dpkg -i tofu_${latest:1}_${ARCH}.deb

}

set -euo pipefail

. /etc/os-release

install_package

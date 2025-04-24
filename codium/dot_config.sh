#!/usr/bin/env bash

MANUAL_SETUP='no'

app_name='codium'
config_path="${HOME}/.config/VSCodium/User"
check_command='codium --version'
main_config_subpath='user-config/'

additional_setup() {
    set -e

    log_info "Adding extensions"
    local extensions_dir="${HOME}/.vscode-oss/extensions"
    if [ -d "$extensions_dir" ]; then
        log_warning "Found existing VSCodium extensions, backing up to ${extensions_dir}.bak"
        mv "$extensions_dir" "${extensions_dir}.bak"
    fi

    mkdir -p "${HOME}/.vscode-oss"
    ln -s "${REPO_PATH}/codium/extensions/" "$extensions_dir"

    log_info "Extensions installed"

    set +e
}

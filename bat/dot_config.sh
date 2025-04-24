#!/usr/bin/env bash

MANUAL_SETUP='no'

app_name='bat'
config_path="${HOME}/.config/bat"
check_command='bat --version'
main_config_subpath=''

additional_setup() {
    set -e

    log_warning "Removing bat cache"

    rm -rf "${HOME}/.cache/bat"

    mkdir -p "$(bat --config-dir)/themes"
    wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
    bat cache --build

    set +e
}

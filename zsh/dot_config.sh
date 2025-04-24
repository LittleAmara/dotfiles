#!/usr/bin/env bash

MANUAL_SETUP='yes'

app_name='zsh'
config_path="${HOME}/.zshrc"
check_command='zsh --version'
main_config_subpath=''

additional_setup() {
    set -e

    log_info "Manual installation"

    local zshrc_path="${HOME}/.zshrc"
    if [ -f "$zshrc_path" ]; then
        log_info "Found zshrc, backing up to ${zshrc_path}.bak"
        mv "${zshrc_path}" "${zshrc_path}.bak"
    fi
    ln -s "${REPO_PATH}/zsh/zshrc" "$zshrc_path"

    local p10k_path="${HOME}/.p10k.zsh"
    if [ -f "$p10k_path" ]; then
        log_info "Found p10k.zsh, backing up to ${p10k_path}.bak"
        mv "${p10k_path}" "${p10k_path}.bak"
    fi
    ln -s "${REPO_PATH}/zsh/p10k.zsh" "$p10k_path"

    log_info "Installing oh my zsh"

    KEEP_ZSHRC='yes' ZSH="${HOME}/.config/zsh/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    log_info "Installing oh my zsh plugins"

    git clone --depth=1 "https://github.com/zsh-users/zsh-autosuggestions" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" || true
    git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" || true

    log_info "Zsh configuration files installed"

    set +e
}

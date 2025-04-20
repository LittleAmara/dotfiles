#!/usr/bin/env bash

usage() {
    cat << EOF
This little script is there to help you install the configurations that are located in this repository.

Usage: install.sh [-i|--input-file INPUT_FILE] [--apps APPS] [-a|--all] [-f|--force] [-h|--help]

    -i|--input-file INPUT_FILE           INPUT_FILE must be file containing an app name on each line.
    --apps APPS                          Specify a list of apps to configure. Must be a space separeted string.
    --force                              Do not check for existing configuration and overwrite if any. Useful when configuring a system from scratch.
    -h|--help                            Show this help message.

Example: install.sh --apps 'i3 tmux' --force
EOF
    exit "$1"
}

# Color variables
readonly BLACK='\033[0;30m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly RESET='\033[0m'
readonly REPO_PATH="$(dirname "$(realpath "$0")")"

CONFIGURATION_VARIABLES='app_name config_path check_command'

LOG_PREFIX='INITIALIZATION'

_log() {
    case $1 in
        -*)
            local echo_option="$1"
            shift
            echo "$echo_option" "[${LOG_PREFIX}] $*"
            ;;
        *)
            echo "[${LOG_PREFIX}]" $*
            ;;
    esac
}

log_info() {
    _log -e "$1"
}


log_success() {
    _log -e "${GREEN}$1${RESET}"
}

log_warning() {
    _log -e "${YELLOW}$1${RESET}" >&2
}

log_fail() {
    _log -e "${RED}$1${RESET}" >&2
}

init() {
    _log -n "Installing config... "
}

success() {
    _log -e "${GREEN}Configuration installed successfully${RESET}"
}

fail() {
    local message="$1"
    log_fail 'Failed to install configuration'
    _log "Reason: $message" >&2
    exit
}

is_dot_config_valid() {
    local status=0
    for variable in $CONFIGURATION_VARIABLES; do
        # Ugly hack to evaluate a variable which name is stored inside another variable in a POSIX fashion
        if eval "test -z \"\$$variable\"" ; then
            log_fail "$variable must be defined in the dot_config file"
            status=1
        fi
    done
    return $status
}

is_app_installed() {
    local app_name="$1"
    local command="$2"

    if ! $command > /dev/null 2>&1; then
        log_warning "Skipping because $app_name is not installed or not in \$PATH"
        return 1
    fi

    log_info "Application is installed"
    log_info "$app_name -> $(which "$app_name" 2>/dev/null)"
}

check_existing_config() {
    local app_name="$1"
    local config_path="$2"

    if [ -d "$config_path" ]; then
        if [ -n "$FORCE_OVERWRITE" ]; then
            local tmp_dir="$(mktemp -d)"
            log_warning "Moving current $app_name configuration to $tmp_dir"
            [ -L "$config_path" ] && log_warning "Was a symlink pointing to $(realpath $config_path)"
            # echo mv "$config_path" "$tmp_dir"
            mv "$config_path" "$tmp_dir"
        else
            log_warning "Configuration files were found at $config_path and --force was not specified. Please make a backup first or use --force to overwrite the current configuration."
            return 1
        fi
    fi
}

install_config() {
    local dst="$1"
    local src="$2"

    ln -s "$src" "$dst"
}

configure_app() {
    local app="$1"
    LOG_PREFIX="$app"

    if ! [ -d "${REPO_PATH}/${app}" ]; then
        log_warning 'Skipping because this repository does not contain a configuration for this app...'
        return
    fi

    log_info 'Installing config...'

    local config_script="${REPO_PATH}/${app}/dot_config.sh"
    [ -f "$config_script" ] || fail "$app does not contain the required instructions for installing its configuration. See README for more information."

    unset -v $CONFIGURATION_VARIABLES
    log_info "Reading $config_script..."
    . "$config_script"

    is_dot_config_valid && log_success "dot_config is valid" || return 1
    is_app_installed "$app" "$check_command"
    check_existing_config "$app" "$config_path" || return
    set -e
    install_config "$config_path" "${REPO_PATH}/${app}/${main_config_subpath}"
    set +e

    local check_additional_setup="$(type 'additional_setup' 2>&1)"

    case "$check_additional_setup" in
        *function*) additional_setup && unset additional_setup;;
        *) log_info 'No additional setup were found in dot_config file';;
    esac

    success
}

[ "$#" -eq 0 ] && usage 1

CONFIGURE_ALL=
APPS=
INPUT_FILE=
FORCE_OVERWIRTE=
while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            usage
            ;;
        --all)
            CONFIGURE_ALL=true
            ;;
        --apps)
            [ -n "$2" ] && APPS="$2" || log_fail 'You must specify a space separated list of apps when using  --apps'
            ALL=
            shift
            ;;
        -i|--input-file)
            [ -n "$2" ] && INPUT_FILE="$2" || log_fail 'You must specify an input_file when using -i|--input-file'
            shift
            ;;
        -f|--force)
            FORCE_OVERWRITE=true
            ;;
        *)
            usage 1
            ;;
    esac

    shift
done

readonly CONFIGURE_ALL APPS INPUT_FILE FORCE_OVERWRITE

[ -n "$CONFIGURE_ALL" ] && [ -n "$APPS" ] && log_fail 'You must chose between the arguments --all and --apps' && exit 1

CURRENT_APP=

if [ -n "$APPS" ]; then
    for app in $APPS; do
        CURRENT_APP="$app"
        configure_app "$app"
        echo
    done
    exit 0
fi

if [ -n "$CONFIGURE_ALL" ]; then
    for app in *; do
        CURRENT_APP="$app"
        [ -d "$app" ] || continue
        configure_app "$app"
        echo
    done
    exit 0
fi

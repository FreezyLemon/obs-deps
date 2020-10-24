#!/usr/bin/env bash

set -eE

PRODUCT_NAME="OBS Pre-Built Dependencies"
BASE_DIR="$(git rev-parse --show-toplevel)"

COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_BLUE=$(tput setaf 4)
COLOR_ORANGE=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

{environment}

hr() {{
     echo -e "${{COLOR_BLUE}}[${{PRODUCT_NAME}}] ${{1}}${{COLOR_RESET}}"
}}

step() {{
    echo -e "${{COLOR_GREEN}}  + ${{1}}${{COLOR_RESET}}"
}}

info() {{
    echo -e "${{COLOR_ORANGE}}  + ${{1}}${{COLOR_RESET}}"
}}

error() {{
     echo -e "${{COLOR_RED}}  + ${{1}}${{COLOR_RESET}}"
}}

exists() {{
    command -v "${{1}}" >/dev/null 2>&1
}}

ensure_dir() {{
    [[ -n ${{1}} ]] && /bin/mkdir -p ${{1}} && builtin cd ${{1}}
}}

cleanup() {{
    restore_brews
}}

mkdir() {{
    /bin/mkdir -p $*
}}

trap cleanup EXIT

caught_error() {{
    error "ERROR during build step: ${{1}}"
    cleanup ${workspace}
    exit 1
}}

restore_brews() {{
    if [ -d /usr/local/opt/xz ]; then
      brew link xz
    fi

    if [ -d /usr/local/opt/zstd ]; then
      brew link zstd
    fi

    if [ -d /usr/local/opt/libtiff ]; then
      brew link libtiff
    fi

    if [ -d /usr/local/opt/webp ]; then
      brew link webp
    fi
}}

{build_steps}

obs-deps-build-main() {{
    ensure_dir {workspace}

{call_build_steps}

    restore_brews

    hr "All Done"
}}

obs-deps-build-main $*
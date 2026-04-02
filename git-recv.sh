#!/usr/bin/env bash
# git-recv.sh — Extract archive on closed-network server
#
# Usage:
#   git-recv.sh <archive.tar.gz>                Extract here
#   git-recv.sh <archive.tar.gz> /target/path   Extract to path
#   git-recv.sh --watch /incoming/dir           Auto-extract new archives
#   git-recv.sh --list /dir                     List archives in dir

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "  ${GREEN}OK${NC}  $*"; }
info() { echo -e "  ${YELLOW}..${NC}  $*"; }
fail() { echo -e "  ${RED}!!${NC}  $*"; }

extract() {
    local archive="$1"
    local target="${2:-.}"

    if [[ ! -f "${archive}" ]]; then
        fail "Not found: ${archive}"
        return 1
    fi

    local fname size
    fname=$(basename "${archive}")
    size=$(du -h "${archive}" | cut -f1)

    echo ""
    echo -e "  ${BOLD}${fname}${NC} (${size})"

    mkdir -p "${target}"
    tar xzf "${archive}" -C "${target}"
    if [[ $? -ne 0 ]]; then
        fail "Extraction failed"
        return 1
    fi

    local extracted
    extracted=$(tar tzf "${archive}" | head -1 | cut -d/ -f1)
    local extracted_path="${target}/${extracted}"
    ok "Extracted: ${extracted_path}"

    # Fix Windows CRLF line endings in text files
    info "Fixing line endings..."
    find "${extracted_path}" -type f \( -name "*.sh" -o -name "*.c" -o -name "*.h" -o -name "*.conf" -o -name "*.json" -o -name "*.py" -o -name "*.spec" -o -name "Makefile" -o -name "*.mk" \) -exec sed -i 's/\r$//' {} +
    find "${extracted_path}" -type f -name "*.sh" -exec chmod +x {} +
    ok "Line endings fixed"

    # Auto-build prompt
    if [[ -f "${target}/${extracted}/Makefile" ]]; then
        echo ""
        read -p "  Build now? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "${target}/${extracted}" && make
        fi
    fi
}

watch_dir() {
    local dir="$1"
    info "Watching ${dir} for *.tar.gz ..."
    info "Ctrl+C to stop"

    local seen=""
    while true; do
        for f in "${dir}"/*.tar.gz; do
            [[ -f "${f}" ]] || continue
            echo "${seen}" | grep -qF "${f}" && continue
            echo ""
            info "New: $(basename "${f}")"
            extract "${f}" "${dir}"
            seen="${seen}|${f}"
        done
        sleep 3
    done
}

list_archives() {
    local dir="${1:-.}"
    echo ""
    echo "  Archives in ${dir}:"
    echo ""
    ls -lhtr "${dir}"/*.tar.gz 2>/dev/null | awk '{printf "  %-50s %s\n", $NF, $5}'
    echo ""
}

case "${1:-}" in
    --watch|-w)  watch_dir "${2:-.}" ;;
    --list|-l)   list_archives "${2:-.}" ;;
    --help|-h|"")
        echo ""
        echo "  git-recv — Extract archives from git-sync"
        echo ""
        echo "  git-recv.sh <file.tar.gz> [target_dir]"
        echo "  git-recv.sh --watch <dir>"
        echo "  git-recv.sh --list [dir]"
        echo ""
        ;;
    *)  extract "$1" "${2:-.}" ;;
esac

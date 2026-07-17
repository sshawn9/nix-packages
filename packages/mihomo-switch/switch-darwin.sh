#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./switch-common.sh
source "$SCRIPT_DIR/switch-common.sh"

platform_restart_service() {
  /bin/launchctl kickstart -k system/mihomo
}

mihomo_switch_main "$@"

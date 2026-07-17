#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./switch-common.sh
source "$SCRIPT_DIR/switch-common.sh"

platform_restart_service() {
  systemctl restart mihomo.service
}

mihomo_switch_main "$@"

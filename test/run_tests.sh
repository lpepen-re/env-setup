#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/lib/bats-core/bin/bats" "$SCRIPT_DIR"/*.bats "$@"

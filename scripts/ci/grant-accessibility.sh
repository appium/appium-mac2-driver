#!/usr/bin/env bash
# Seeds a path-based kTCCServiceAccessibility grant into the system TCC.db.
#
# Only works on runners where System Integrity Protection is disabled (GitHub-hosted
# macOS images have shipped this way since macos-13: actions/runner-images#8162) — SIP
# is what normally makes the system TCC.db unwritable even as root.
#
# Uses client_type=1 (path-based identity) with no csreq, so the grant is not tied to a
# specific code signature/CDHash. This sidesteps the "ad-hoc rebuild loses the grant"
# problem that applies to persistent dev machines, and is safe for CI because each run
# re-seeds fresh against whatever binary that run just built.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <absolute-path-to-binary>" >&2
  exit 1
fi

target_path="$1"
tcc_db="/Library/Application Support/com.apple.TCC/TCC.db"

if [[ ! -f "$target_path" ]]; then
  echo "::warning::grant-accessibility.sh: no file at '$target_path', skipping grant" >&2
  exit 0
fi

sudo sqlite3 "$tcc_db" <<SQL
INSERT OR REPLACE INTO access
  (service, client, client_type, auth_value, auth_reason, auth_version,
   indirect_object_identifier, flags, last_modified)
VALUES
  ('kTCCServiceAccessibility', '${target_path}', 1, 2, 3, 1,
   'UNUSED', 0, CAST(strftime('%s', 'now') AS INTEGER));
SQL

sudo launchctl kickstart -k system/com.apple.tccd 2>/dev/null || sudo pkill -HUP tccd || true

echo "Granted kTCCServiceAccessibility to $target_path"

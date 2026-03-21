#!/usr/bin/env bash
# Remove local encrypted attachment blobs (does not touch SQLCipher DB or keychain).
# macOS / Linux: Application Support layout from path_provider.
set -euo pipefail

support_root="${OCTARQ_APP_SUPPORT:-$HOME/Library/Application Support/org.octarq.vault}"
att_dir="$support_root/octarq_attachments"

if [[ ! -d "$support_root" ]]; then
  echo "Nothing at $support_root (skip)."
  exit 0
fi

if [[ -d "$att_dir" ]]; then
  n=$(find "$att_dir" -maxdepth 1 -name '*.enc' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$n" != "0" ]]; then
    find "$att_dir" -maxdepth 1 -name '*.enc' -type f -print -delete
    echo "Deleted $n file(s) under $att_dir"
  else
    echo "No *.enc in $att_dir"
  fi
else
  echo "No $att_dir"
fi

# Sandboxed macOS: Documents + optional iCloud snapshot copies
if [[ "$(uname)" == "Darwin" ]]; then
  doc="$HOME/Library/Containers/org.octarq.vault/Data/Documents"
  if [[ -d "$doc" ]]; then
    for f in "$doc/octarq_vault.enc" "$doc/asset_vault.enc"; do
      [[ -f "$f" ]] && rm -v "$f"
    done
    if [[ -d "$doc/octarq_attachments" ]]; then
      find "$doc/octarq_attachments" -maxdepth 1 -name '*.enc' -type f -print -delete || true
    fi
  fi
fi

echo "Done. Export/backup .enc files you chose yourself are not removed. Google Drive / WebDAV: delete in the cloud UI if needed."

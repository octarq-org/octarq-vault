#!/usr/bin/env bash
# 打 tag、推送、创建 GitHub Release
# 用法: ./scripts/release.sh  或  ./scripts/release.sh 1.2.1

set -e
cd "$(dirname "$0")/.."

if [[ -n "$1" ]]; then
  V="$1"
else
  V=$(grep '^version:' pubspec.yaml | sed 's/version: *\([0-9.]*\).*/\1/')
fi
TAG="v${V}"

echo "→ Tag: $TAG"
git tag "$TAG"
git push origin "$TAG"

echo "→ Release: $TAG"
gh release create "$TAG" --title "$TAG" --generate-notes

echo "Done: $TAG"

#!/bin/bash
set -euo pipefail

echo "Running case-insensitive matcher & git mv for referenced assets..."
echo

moved=0
skipped=0
nomatch=0
multi=0

while IFS= read -r relpath || [ -n "$relpath" ]; do
  # normalize (remove leading / if present)
  relpath="${relpath#/}"
  dest="./${relpath}"

  # skip if destination already exists
  if [ -f "$dest" ]; then
    echo "OK exists: $dest"
    continue
  fi

  base="$(basename "$relpath")"
  # find candidate files under ./assets matching basename case-insensitively
  # limit to regular files only
  IFS=$'\n' read -r -d '' -a candidates < <(find ./assets -type f -iname "$base" -print0 2>/dev/null && printf '\0')

  if [ "${#candidates[@]}" -eq 0 ]; then
    echo "No match for: $relpath"
    nomatch=$((nomatch+1))
    continue
  elif [ "${#candidates[@]}" -gt 1 ]; then
    echo "Multiple matches for: $relpath"
    for c in "${candidates[@]}"; do
      echo "  candidate: $c"
    done
    echo "Skipping $relpath (manual review needed)"
    multi=$((multi+1))
    skipped=$((skipped+1))
    continue
  fi

  cand="${candidates[0]}"
  # create dest dir
  mkdir -p "$(dirname "$dest")"
  echo "git mv \"$cand\" \"$dest\""
  git mv "$cand" "$dest"
  moved=$((moved+1))

done < /tmp/referenced-assets.txt

echo
echo "Summary: moved=$moved, no-match=$nomatch, multi=$multi, skipped=$skipped"
echo "Run 'git status --porcelain' to review changes, then 'git diff --name-only --cached' before committing."


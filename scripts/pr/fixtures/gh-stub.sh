#!/bin/bash
# Stands in for gh in the ready-to-merge tests: answers from files in $FIX_DIR, so a test
# chooses what GitHub "said". A missing file makes that call fail, like gh failing.
case "$*" in
  *"api graphql"*)       f=threads.json ;;
  *"pr view --json url"*) f=url.json ;;
  *mergeStateStatus*)    f=extra.json ;;
  *"pr view"*)           f=fetch.json ;;
  *) exit 1 ;;
esac
[ -f "$FIX_DIR/$f" ] || exit 1
cat "$FIX_DIR/$f"

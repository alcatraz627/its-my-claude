#!/bin/bash
# Sets how Finder arranges icons in every folder that has no view settings of its own.
# Usage: grid-default.sh <name|kind|dateModified|grid|none>
#   name = sorted grid, like Windows Explorer. none = the macOS default free placement.
# Folders you already arranged by hand keep their own setting (stored in their .DS_Store);
# use the "Grid - Sort by ..." quick action on those.
mode="${1:?usage: grid-default.sh <name|kind|dateModified|grid|none>}"
plist="$HOME/Library/Preferences/com.apple.finder.plist"
for key in StandardViewSettings FK_StandardViewSettings; do
  /usr/libexec/PlistBuddy -c "Set :$key:IconViewSettings:arrangeBy $mode" "$plist" 2>/dev/null
done
# Finder caches its prefs, so it must restart to read the new default.
killall Finder
echo "Finder icon default arrangement: $mode"

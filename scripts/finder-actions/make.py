#!/usr/bin/env python3
"""Installs the owner's Finder right-click Quick Actions into ~/Library/Services.

Each action is a shell command run with the selected files as arguments. The
bundle format is cloned from template.wflow, a working Automator Quick Action,
so no Automator UI is needed. Re-running rewrites every action in place.

Usage: python3 make.py            install or refresh all actions
       python3 make.py --remove   move them to the Trash
"""
import copy
import plistlib
import subprocess
import sys
import uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
SERVICES = Path.home() / "Library" / "Services"
PREFIX = "Finder "

# Picks the folder an action works on: a selected folder itself, or the
# folder that holds the selected file.
TARGET_DIR = 'if [ -d "$1" ]; then d="$1"; else d=$(dirname "$1"); fi'
NOTIFY = "osascript -e 'display notification \"%s\" with title \"Finder\"'"
GRID = f'{TARGET_DIR}; osascript "{HERE}/grid.applescript" "$d" %s'
ACT = f'/bin/bash "{HERE}/actions.sh" %s "$@"'

# Icons are AppKit's built-in template images, the same set Automator's own
# image picker offers, so Finder can always draw them.
ACTIONS = [
    {
        "name": "Copy Path",
        "icon": "NSTouchBarDocumentsTemplate",
        "cmd": 'printf "%s" "$(printf "%s\\n" "$@")" | pbcopy; '
        + NOTIFY % "Path copied",
    },
    {
        "name": "Copy Folder Path",
        "icon": "NSTouchBarFolderTemplate",
        "cmd": f'{TARGET_DIR}; printf "%s" "$d" | pbcopy; ' + NOTIFY % "Folder path copied",
    },
    {"name": "Sort as Grid by Name", "icon": "NSTouchBarIconViewTemplate", "cmd": GRID % "name"},
    {"name": "Sort as Grid by Kind", "icon": "NSTouchBarTagIconTemplate", "cmd": GRID % "kind"},
    {"name": "Sort as Grid by Date", "icon": "NSTouchBarHistoryTemplate", "cmd": GRID % "modified"},
    {"name": "Snap to Grid", "icon": "NSTouchBarExitFullScreenTemplate", "cmd": GRID % "grid"},
    {
        "name": "New Text File Here",
        "icon": "NSTouchBarComposeTemplate",
        "cmd": f'{TARGET_DIR}; f="$d/untitled.txt"; n=2; '
        'while [ -e "$f" ]; do f="$d/untitled $n.txt"; n=$((n+1)); done; '
        ': > "$f"; open -R "$f"',
    },
    {"name": "Copy Contents", "icon": "NSTouchBarTextBoxTemplate", "cmd": ACT % "contents"},
    {"name": "Copy Repo Path", "icon": "NSTouchBarBookmarksTemplate", "cmd": ACT % "repo-path"},
    {"name": "Open on GitHub", "icon": "NSTouchBarOpenInBrowserTemplate", "cmd": ACT % "github"},
    {"name": "Copy SHA-256", "icon": "NSTouchBarGetInfoTemplate", "cmd": ACT % "sha"},
    {"name": "Make Executable", "icon": "NSTouchBarGoForwardTemplate", "cmd": ACT % "exec"},
    {"name": "Reset Folder View", "icon": "NSTouchBarRefreshTemplate", "cmd": ACT % "reset-view"},
    {"name": "Send with Taildrop", "icon": "NSTouchBarShareTemplate", "cmd": ACT % "taildrop"},
    {"name": "Send with csync", "icon": "NSTouchBarSkipAheadTemplate", "cmd": ACT % "csync"},
    {"name": "Open in Zed", "icon": "NSTouchBarTextListTemplate", "cmd": 'open -a Zed "$@"'},
    {
        "name": "Open in VS Code",
        "icon": "NSTouchBarTextListTemplate",
        "cmd": 'open -a "Visual Studio Code" "$@"',
    },
]


def info_plist(label, icon):
    return {
        "NSServices": [
            {
                "NSBackgroundColorName": "background",
                "NSIconName": icon,
                "NSMenuItem": {"default": label},
                "NSMessage": "runWorkflowAsService",
                "NSRequiredContext": {"NSApplicationIdentifier": "com.apple.finder"},
                "NSSendFileTypes": ["public.item"],
            }
        ]
    }


def document(template, cmd, icon):
    doc = copy.deepcopy(template)
    doc["workflowMetaData"]["systemImageName"] = icon
    action = doc["actions"][0]["action"]
    action["ActionParameters"]["COMMAND_STRING"] = cmd
    action["ActionParameters"]["shell"] = "/bin/zsh"
    action["ActionParameters"]["inputMethod"] = 1  # selected files arrive as "$@"
    for key in ("InputUUID", "OutputUUID", "UUID"):
        action[key] = str(uuid.uuid4()).upper()
    meta = doc["workflowMetaData"]
    meta["inputTypeIdentifier"] = "com.apple.Automator.fileSystemObject"
    meta["serviceInputTypeIdentifier"] = "com.apple.Automator.fileSystemObject"
    return doc


def bundle(a):
    return SERVICES / f"{PREFIX}{a['name']}.workflow"


def refresh_services():
    subprocess.run(["/System/Library/CoreServices/pbs", "-flush"], check=False)
    subprocess.run(["/System/Library/CoreServices/pbs", "-update"], check=False)


def main():
    if "--remove" in sys.argv:
        found = [str(bundle(a)) for a in ACTIONS if bundle(a).exists()]
        if found:
            subprocess.run(["trash", *found], check=True)
        refresh_services()
        print(f"removed {len(found)} actions")
        return
    template = plistlib.loads((HERE / "template.wflow").read_bytes())
    for a in ACTIONS:
        contents = bundle(a) / "Contents"
        contents.mkdir(parents=True, exist_ok=True)
        (contents / "Info.plist").write_bytes(plistlib.dumps(info_plist(a["name"], a["icon"])))
        (contents / "document.wflow").write_bytes(
            plistlib.dumps(document(template, a["cmd"], a["icon"]))
        )
        print(f"installed {bundle(a).name}")
    refresh_services()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Reads disk/volume facts from diskutil for ntfsutil.sh.

Talks to `diskutil` via its -plist output (never scrapes the column-aligned
text table, which shifts between macOS versions) and prints JSON on stdout.
Read-only: this file never mounts, unmounts, or writes anything.
"""
import json
import plistlib
import subprocess
import sys


def diskutil_plist(subcommand, *args):
    # -plist must come right after the subcommand, before the identifier,
    # or diskutil errors out.
    out = subprocess.run(
        ["diskutil", subcommand, "-plist", *args], capture_output=True, check=True
    ).stdout
    return plistlib.loads(out)


def is_ntfs(info):
    name = (info.get("FilesystemName") or "").lower()
    fstype = (info.get("FilesystemType") or "").lower()
    return "ntfs" in name or fstype == "ntfs"


def all_identifiers():
    top = diskutil_plist("list")
    ids = []
    for disk in top.get("AllDisksAndPartitions", []):
        if "DeviceIdentifier" in disk:
            ids.append(disk["DeviceIdentifier"])
        for part in disk.get("Partitions", []):
            ids.append(part["DeviceIdentifier"])
        for apfs_vol in disk.get("APFSVolumes", []):
            ids.append(apfs_vol["DeviceIdentifier"])
    return ids


def info_for(identifier):
    try:
        info = diskutil_plist("info", identifier)
    except subprocess.CalledProcessError:
        return None
    return {
        "identifier": info.get("DeviceIdentifier", identifier),
        "volume_name": info.get("VolumeName") or "",
        "size_bytes": info.get("TotalSize") or info.get("Size") or 0,
        "filesystem_name": info.get("FilesystemName") or "",
        "filesystem_type": info.get("FilesystemType") or "",
        "is_ntfs": is_ntfs(info),
        "internal": bool(info.get("Internal", False)),
        "removable_media": bool(info.get("RemovableMedia", False)),
        "ejectable": bool(info.get("Ejectable", False)),
        "writable_media": bool(info.get("WritableMedia", True)),
        "mount_point": info.get("MountPoint") or "",
        "mounted": bool(info.get("MountPoint")),
        "device_node": info.get("DeviceNode") or f"/dev/{identifier}",
        "whole_disk": bool(info.get("WholeDisk", False)),
        "bus_protocol": info.get("BusProtocol") or "",
    }


def cmd_list_ntfs():
    try:
        ids = all_identifiers()
    except subprocess.CalledProcessError as e:
        print(f"disklib: diskutil list failed: {e}", file=sys.stderr)
        sys.exit(1)
    results = []
    for ident in ids:
        info = info_for(ident)
        if info and info["is_ntfs"]:
            results.append(info)
    print(json.dumps(results))


def cmd_info(identifier):
    info = info_for(identifier)
    print(json.dumps(info))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: disklib.py list-ntfs | info <identifier>", file=sys.stderr)
        sys.exit(2)
    if sys.argv[1] == "list-ntfs":
        cmd_list_ntfs()
    elif sys.argv[1] == "info" and len(sys.argv) == 3:
        cmd_info(sys.argv[2])
    else:
        print("usage: disklib.py list-ntfs | info <identifier>", file=sys.stderr)
        sys.exit(2)

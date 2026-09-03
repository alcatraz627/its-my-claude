# ntfsutil

Mount external NTFS drives read-write on macOS. Apple's own NTFS driver is
read-only. This wraps a self-built `ntfs-3g` running on FUSE-T (already
installed on this machine) to get write access.

## Usage

```
ntfsutil scan   [--json]
ntfsutil status [<identifier>] [--json]
ntfsutil mount   <identifier> [mountpoint] [--ro|--rw] [-f]
ntfsutil unmount <identifier|mountpoint> [-f]
```

Run `ntfsutil -h` for the full reference (examples, safety model).

## Why root is needed for mount and unmount

`ntfs-3g` refuses to mount a real block device as a non-root user when built
against external FUSE. That check lives in its own source
(`src/ntfs-3g.c`: `if (getuid() && ctx->blkdev)`), not something this wrapper
added. `mount` therefore runs the driver via `sudo` and will prompt for your
password. `unmount` falls back to `sudo diskutil umount` if a plain unmount
is refused.

## Layout

- `ntfsutil.sh`: the CLI (entry point)
- `disklib.py`: reads disk facts from `diskutil -plist`, prints JSON
- `vendor/bin/`, `vendor/lib/`: the built `ntfs-3g` binaries plus
  `libntfs-3g.90.dylib`, relinked with `install_name_tool` and re-signed with
  `codesign -s -` to point at this permanent location instead of the
  ephemeral build tree
- `state/mounts.json`: tracks mounts this tool made, so `status` and
  `unmount` can find them later. macOS's `mount` output does not expose the
  original device for a FUSE-T mount.

## Rebuilding the vendor binaries

Source: https://github.com/tuxera/ntfs-3g, built from a full clone, not the
Homebrew formula. That formula now requires Linux on this tap.

```bash
git clone --depth 1 https://github.com/tuxera/ntfs-3g.git
cd ntfs-3g && ./autogen.sh

# ntfs-3g's configure hardcodes the pkg-config module name "fuse". FUSE-T
# registers as "fuse-t" instead, so alias it:
mkdir -p /tmp/pkgconfig-alias
cat > /tmp/pkgconfig-alias/fuse.pc <<'EOF'
prefix=/usr/local
exec_prefix=${prefix}
libdir=${prefix}/lib
includedir=${prefix}/include/fuse
Name: fuse
Version: 2.9.9
Libs: -L${libdir} -Wl,-rpath,${libdir} -lfuse-t
Cflags: -I${includedir}
EOF

PKG_CONFIG_PATH=/tmp/pkgconfig-alias:/usr/local/lib/pkgconfig \
  ./configure --prefix=/usr/local --disable-ldconfig --without-uuid

make -j"$(sysctl -n hw.ncpu)"

# macOS's Clang hard-errors without this flag. Linux's glibc defaults it on,
# so ntfs-3g's configure never learned to detect it on Darwin:
cd src && make CFLAGS="-DHAVE_CONFIG_H -g -O2 -Wall -D_FILE_OFFSET_BITS=64"
```

Then copy the real binaries, not the libtool wrapper shell scripts (those
hardcode the build-tree path and must never be moved), into `vendor/`. Relink
and re-sign so they stop pointing at the ephemeral build directory:

```bash
VENDOR=~/.claude/scripts/ntfsutil/vendor
cp src/.libs/{ntfs-3g,lowntfs-3g} "$VENDOR/bin/"
cp ntfsprogs/.libs/{mkntfs,ntfsfix,ntfsresize,ntfsclone,ntfsinfo,ntfscat,ntfslabel} "$VENDOR/bin/"
cp libntfs-3g/.libs/libntfs-3g.90.dylib "$VENDOR/lib/"

install_name_tool -id "$VENDOR/lib/libntfs-3g.90.dylib" "$VENDOR/lib/libntfs-3g.90.dylib"
codesign -s - -f "$VENDOR/lib/libntfs-3g.90.dylib"
for b in "$VENDOR"/bin/*; do
  install_name_tool -change /usr/local/lib/libntfs-3g.90.dylib "$VENDOR/lib/libntfs-3g.90.dylib" "$b"
  codesign -s - -f "$b"
done
```

Apple Silicon requires the `codesign` step after `install_name_tool` touches a
binary. Without it, dyld refuses to load the binary as an invalid signature.

## Known gap

This was tested against loopback disk images (`hdiutil attach`) and against
one internal-disk, missing-binary, and nonexistent-identifier refusal path.
The `sudo` mount and unmount of a real physical drive was not exercised
end-to-end. The sandbox this was built in has no interactive TTY for a sudo
password prompt. That path is grounded in reading ntfs-3g's own
privilege-check source, not in a run-and-observed test. Watch the first real
run.

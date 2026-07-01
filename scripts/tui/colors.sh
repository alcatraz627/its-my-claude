#!/usr/bin/env bash
# colors.sh — the one TTY-gated ANSI palette for std::claude::tui shell tools.
#
# Source it, call `tui_colors_init`, then use the exported vars. Every var is the
# empty string when output is not a real terminal (or NO_COLOR is set), so call
# sites never branch — `printf '%sX%s' "$C" "$R"` is correct in a pipe and in a
# terminal alike.
#
# Exports BOTH naming dialects the existing tools already use, so adoption is one
# `source` line, not a callsite rename:
#   short  : B Y C D R G Rd RED MAG BLU   (zap/zconvert/memhog use B Y C D R [+G Rd])
#   long   : BLD YEL CYN DIM RST GRN       (download/zcmd use BLD/YEL/CYN/DIM/RST/GRN)
# RED/MAG/BLU are shared across dialects. `Rd` is zap's red alias; `R` is reset.
#
# Gate is BOTH fds: a tool whose `--help` pipes to a pager, or whose stderr is
# redirected to a log, must not emit raw escapes into either stream. `-t 1` alone
# leaks ANSI into a redirected stderr; this gate closes that (the latent bug five
# of six callers carried).
#
# Pure sourced library: prints nothing, returns 0, idempotent (re-init recomputes).

# tui_colors_init — set (or blank) the palette vars per the both-fd TTY gate. Call once after sourcing.
tui_colors_init() {
  if [ -t 1 ] && [ -t 2 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    B=$'\033[1m';  Y=$'\033[1;33m'; C=$'\033[36m'; D=$'\033[2m'; R=$'\033[0m'
    G=$'\033[32m'; RED=$'\033[31m'; MAG=$'\033[35m'; BLU=$'\033[34m'
  else
    B=''; Y=''; C=''; D=''; R=''; G=''; RED=''; MAG=''; BLU=''
  fi
  Rd="$RED"                                   # zap's red alias (R is reset, not red)
  BLD="$B"; YEL="$Y"; CYN="$C"; DIM="$D"; RST="$R"; GRN="$G"   # long-form dialect
  export B Y C D R G Rd RED MAG BLU BLD YEL CYN DIM RST GRN
}

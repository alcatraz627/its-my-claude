#!/usr/bin/env python3
"""Shrinks the i-dream session briefing to a character budget.

The briefing is a few paragraphs of project context and do/avoid lists that
every session reads once. This keeps the title, the first sentence of what the
project is about, and the bold lead of each do/avoid bullet, in the order the
daemon ranked them (newest first), and drops the rest until it fits. The full
brief stays with the daemon; only what enters the model's context shrinks.

Usage: brief-cap.py BUDGET < briefing.txt > capped.txt
Text with no recognised sections is flattened and cut at the budget.
"""
import re
import sys


def split_sections(text):
    out, cur = {}, None
    for line in text.splitlines():
        m = re.match(r"^##\s+(.*)", line)
        if m:
            cur = m.group(1).strip().lower()
            out[cur] = []
        elif cur is not None:
            out[cur].append(line)
    return out


def lead_sentence(lines, limit=170):
    s = " ".join(l.strip() for l in lines if l.strip())
    m = re.match(r"(.+?[.!?])(\s|$)", s)
    s = m.group(1) if m else s
    return s if len(s) <= limit else s[: limit - 1].rsplit(" ", 1)[0] + "…"


def bullet_leads(lines):
    res = []
    for l in lines:
        m = re.match(r"^\s*[-*]\s+\*\*(.+?)\*\*", l)
        if m:
            res.append(m.group(1).strip().rstrip(":"))
        elif re.match(r"^\s*[-*]\s+\S", l):
            res.append(re.sub(r"^\s*[-*]\s+", "", l).strip()[:90])
    return res


def compose(title, about, do, avoid, nd, na):
    parts = [title]
    if about:
        parts.append(about)
    if do and nd:
        parts.append("Do: " + "; ".join(do[:nd]))
    if avoid and na:
        parts.append("Avoid: " + "; ".join(avoid[:na]))
    return "\n".join(parts)


def main():
    budget = int(sys.argv[1]) if len(sys.argv) > 1 else 700
    raw = sys.stdin.read()
    text = re.sub(r"<!--.*?-->", "", raw, flags=re.S).strip()
    if not text:
        return
    sec = split_sections(text)
    pick = lambda *names: next((v for k, v in sec.items() if any(n in k for n in names)), [])
    about = lead_sentence(pick("about"))
    do = bullet_leads(pick("to do", "keep doing"))
    avoid = bullet_leads(pick("avoid"))
    if not (about or do or avoid):
        flat = re.sub(r"\s+", " ", re.sub(r"[#*_`]", "", text)).strip()
        print(flat if len(flat) <= budget else flat[: budget - 1].rsplit(" ", 1)[0] + "…")
        return
    title = "# i-dream briefing"
    nd, na = len(do), len(avoid)
    out = compose(title, about, do, avoid, nd, na)
    while len(out) > budget and (nd or na):
        if nd >= na and nd:
            nd -= 1
        else:
            na -= 1
        out = compose(title, about, do, avoid, nd, na)
    if len(out) > budget:
        out = out[: budget - 1].rsplit(" ", 1)[0] + "…"
    print(out)


if __name__ == "__main__":
    main()

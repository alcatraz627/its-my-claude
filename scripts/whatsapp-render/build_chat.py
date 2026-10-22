"""Turn a WhatsApp iOS export folder into a single chat.html that reads like WhatsApp.

Writes chat.html into the export folder so photos, videos and stickers load from
the files beside it. Your side is guessed as the name not in the folder title.

Usage: python3 -I build_chat.py <export-folder> [me-name] [--template FILE]
"""
import datetime, json, os, re, subprocess, sys

args = sys.argv[1:]
template = os.path.join(os.path.dirname(os.path.abspath(__file__)), "chat_template.html")
if "--template" in args:
    k = args.index("--template")
    template = args[k + 1]
    del args[k:k + 2]
if not args or args[0] in ("-h", "--help"):
    print(__doc__.strip())
    sys.exit(0 if args else 1)
folder = args[0]
me = args[1] if len(args) > 1 else None

raw = open(os.path.join(folder, "_chat.txt"), encoding="utf-8").read()
head = re.compile(
    r"^‎?\[(\d\d)/(\d\d)/(\d\d), (\d{1,2}):(\d\d):\d\d[\s ]?([AP]M)\] ([^:\n]+): ",
    re.M,
)
attach_re = re.compile(r"‎?<attached: ([^>]+)>")
omit_re = re.compile(r"^‎?(image|video|audio|sticker|GIF|document|video note|Contact card) omitted$")
call_re = re.compile(r"^‎?(Missed )?(Voice|Video) call(?:, ‎?(.*))?$")
deleted = {"This message was deleted", "You deleted this message"}

names, days, msgs = [], [], []
starts = list(head.finditer(raw))
# Some exports repeat an earlier stretch of history; when time jumps backwards,
# skip until we pass the newest message already kept.
high, skipping, skipped = None, False, 0
for i, m in enumerate(starts):
    dd, mm, yy, hh, mi, ap, who = m.groups()
    sec = raw[m.start():m.end()].split(":")[2][:2]
    h24 = int(hh) % 12 + (12 if ap == "PM" else 0)
    stamp = datetime.datetime(2000 + int(yy), int(mm), int(dd), h24, int(mi), int(sec))
    if high and stamp < high:
        skipping = True
    if skipping and stamp <= high:
        skipped += 1
        continue
    skipping, high = False, stamp
    end = starts[i + 1].start() if i + 1 < len(starts) else len(raw)
    body = raw[m.end():end].rstrip("\n").strip()
    if who not in names:
        names.append(who)
    day = stamp.date().isoformat()
    if not days or days[-1] != day:
        days.append(day)

    edited = 0
    if body.endswith("<This message was edited>"):
        edited, body = 1, body[: -len("<This message was edited>")].rstrip()

    kind, file = 0, ""
    a = attach_re.search(body)
    if a:
        kind, file = 1, a.group(1)
        body = attach_re.sub("", body).strip()
    else:
        # iOS puts the caption first and "image omitted" last on the same line
        om = re.search(r"‎?(image|video|audio|sticker|GIF|document|video note|Contact card) omitted$", body)
        if om:
            kind, file = 2, om.group(1)
            body = body[: om.start()].strip()
        else:
            c = call_re.match(body)
            if c:
                kind = 3
                body = ("Missed " if c.group(1) else "") + c.group(2).lower() + " call" + (
                    " · " + c.group(3).replace("‎", "") if c.group(3) else "")
            elif body.replace("‎", "") in deleted:
                kind, body = 4, body.replace("‎", "")
    body = body.replace("‎", "")
    msgs.append([len(days) - 1, f"{int(hh)}:{mi} {ap}", names.index(who), body, kind, file, edited])

if me is None:
    # the exporter's own side is the one that isn't in the folder name
    tag = os.path.basename(folder.rstrip("/"))
    me = next((n for n in names if n not in tag), names[-1])

# Image sizes let the page reserve space before each photo loads, so the chat doesn't jump.
dims = {}
images = sorted({m[5] for m in msgs if m[4] == 1 and m[5].lower().endswith((".jpg", ".jpeg", ".png", ".webp", ".gif"))})
if images:
    out_sips = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", *images],
                              cwd=folder, capture_output=True, text=True).stdout
    for blk in re.split(r"\n(?=\S)", out_sips):
        w = re.search(r"pixelWidth: (\d+)", blk)
        h = re.search(r"pixelHeight: (\d+)", blk)
        if w and h:
            dims[os.path.basename(blk.split("\n", 1)[0].strip())] = [int(w.group(1)), int(h.group(1))]

data = {"names": names, "dims": dims, "me": names.index(me), "days": days, "msgs": msgs, "title": os.path.basename(folder.rstrip("/"))}
blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
html = open(template, encoding="utf-8").read().replace("/*__DATA__*/", blob)
out = os.path.join(folder, "chat.html")
open(out, "w", encoding="utf-8").write(html)
missing = sorted({m[5] for m in msgs if m[4] == 1 and not os.path.exists(os.path.join(folder, m[5]))})
print(out, len(msgs), "messages", len(days), "days", "skipped dupes", skipped, "names", names, "me", me)
print("attached files missing on disk:", len(missing), missing[:5])
print("image sizes found:", len(dims), "of", len(images))

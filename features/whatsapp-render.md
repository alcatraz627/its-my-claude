---
brief: Render a WhatsApp chat export as a WhatsApp-style HTML reader (bubbles, grouping, day pills, date rail, inline media, search, saved position) and serve it to a phone over the tailnet
triggers:
  - topic:whatsapp
  - phrase:"whatsapp chat"
  - phrase:"_chat.txt"
  - tool:build_chat.py
related:
  - dev-servers
tier: 3
category: features
updated: 2026-10-21
stale_after_days: 180
---

# WhatsApp chat reader

Turns a WhatsApp export (`_chat.txt` plus media files) into one `chat.html` that reads like
the app: your messages on the right, theirs on the left, runs from the same person grouped,
a date pill per day, and photos, videos, voice notes and stickers playing inline. A date rail
on the left (a drawer on phones) shows every day with a bar for how busy it was, follows
your scroll, and jumps on tap. The page remembers the exact message and pixel you were on.

Built 2026-10-21 for the "yonzan" export. Planned to grow; see the proposal filed the same day.

## Use it

```
python3 -I ~/.claude/scripts/whatsapp-render/build_chat.py "<export folder>" [my-name]
```

It writes `chat.html` into the export folder, since media loads by relative path. Open it
directly, or serve the folder (below). Extract the zip first; `._*` files from an exFAT
drive are ignored.

## What the parser knows (iOS export format)

- Header `[dd/mm/yy, h:mm:ss AM] Name: text`, sometimes led by U+200E, with a narrow
  no-break space before AM/PM. Lines without a header continue the previous message.
- `<attached: NNNNNNNN-PHOTO-….jpg>` is a real file; `image omitted` (and video, audio,
  sticker, GIF, document, video note, Contact card) means WhatsApp left it out, shown as a
  placeholder. A caption can sit before either one on the same line.
- Calls (`Voice call, 33 sec`, `Missed video call`), deleted messages and the
  `<This message was edited>` suffix each get their own look.
- **Exports can repeat history.** The yonzan export held three overlapping copies (93,059
  lines, 63,422 unique). The parser drops any stretch where time jumps backwards until it
  passes the newest message already kept.
- Replies are not in the export, so quoted replies cannot be rebuilt.
- Image sizes come from `sips` at build time, so photos reserve their space and never shove
  the chat while loading.

## Serving it to a phone

Live instance: pm2 `yonzan-chat` runs caddy with
`~/.config/caddy/yonzan-chat.Caddyfile` (copy in this folder), port 5119 (tier 2 claim),
root `~/Documents/WhatsApp Chat - yonzan`. Phone URL `http://100.65.206.85:5119/`.

Lessons that cost a round each:

- The Mac App Store Tailscale cannot serve a folder ("Path serving is not supported on
  macOS due to sandbox restrictions"), so `tailscale serve` must proxy to a local server.
- Use a server with Range support (caddy). Phone browsers need it to play video.
- The owner's phone (Chrome Android) failed on tailnet HTTPS. Plain HTTP to the tailnet IP
  is what worked; Tailscale already encrypts the hop. `tailscale serve --http` only answers
  the hostname, so the IP route is caddy binding `100.65.206.85` itself.
- Never put the reader on an origin another app used. Data Forge had installed a service
  worker at the root of `https://…ts.net`, which hijacked `/yonzan` on soft reloads. A
  self-unregistering `/sw.js` (`_sw-kill.js` here) fixed the laptop; a `Clear-Site-Data`
  header made the phone load nothing and was removed. A fresh origin was the real fix.
- Send `Cache-Control: no-cache` on the HTML and turn on gzip (3.4 MB to 939 KB).

## Files

`~/.claude/scripts/whatsapp-render/`: `build_chat.py` (parser and builder),
`chat_template.html` (the page; data is injected at `/*__DATA__*/`),
`yonzan-chat.Caddyfile` and `_sw-kill.js` (serving examples).

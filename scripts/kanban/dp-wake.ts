// Tells the session that raised a decision page that the owner has answered it.
//
// The page server used to send a plain `inform` message, and the ipc wake watcher
// (claude-ipc plugin/scripts/watch-inbox.sh) only wakes an idle session for
// query, request or response mail. An inform waits for the next turn, so an
// answered page sat unread until the owner typed. This sends a `request` (no
// reply wanted, so nothing is chased), falls back to the project mailbox when the
// alias cannot be reached, and records what happened in <page>/.notify.json so a
// failed handoff is never silent.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export interface SendResult { code: number; out: string; err: string }
export type Sender = (argv: string[]) => Promise<SendResult>;

// requested: a wake-capable message went to a live session. queued: it went out
// but nobody live holds the mailbox, so it waits for a successor. undelivered:
// nothing could be sent. no-origin: the page names nobody to tell.
export type WakeState = "requested" | "queued" | "undelivered" | "no-origin";
export interface WakeResult { state: WakeState; via: string[]; reason: string }

const SEND_TIMEOUT_MS = 10_000;

export const ipcSender: Sender = async (argv) => {
  const proc = Bun.spawn(["claude-ipc", ...argv], { stdout: "pipe", stderr: "pipe" });
  const timer = setTimeout(() => proc.kill(), SEND_TIMEOUT_MS);
  try {
    const [out, err, code] = await Promise.all([
      new Response(proc.stdout).text(), new Response(proc.stderr).text(), proc.exited]);
    return { code, out: out.trim(), err: err.trim() };
  } catch (e: any) {
    return { code: 1, out: "", err: String(e?.message ?? e) };
  } finally { clearTimeout(timer); }
};

export async function wakeOrigin(opts: {
  slug: string; dir: string; reachState?: string; send?: Sender; now?: () => string;
}): Promise<WakeResult> {
  const send = opts.send ?? ipcSender;
  const now = opts.now ?? (() => new Date().toISOString());
  let origin = "", project = "";
  try {
    const cfg = JSON.parse(fs.readFileSync(path.join(opts.dir, "config.json"), "utf8"));
    origin = String(cfg?.origin?.session ?? "");
    project = String(cfg?.origin?.project ?? "");
    // The CLI gets this as a bare argument, so no shell expands the tilde for us.
    if (project.startsWith("~/")) project = path.join(os.homedir(), project.slice(2));
  } catch { /* an unreadable config reads as no origin, and is recorded below */ }

  const body = `decision page ${opts.slug} answered. Read it: bash ~/.claude/scripts/decision-page/decision-page.sh answer ${opts.slug}`;
  const common = ["--from", "dp-server", "--kind", "request", "--no-reply-expected"];
  const via: string[] = [];
  const reasons: string[] = [];

  let aliasOk = false;
  if (origin) {
    const r = await send(["send", "--to", origin, ...common, body]);
    if (r.code === 0) { aliasOk = true; via.push(`alias:${origin}`); }
    else reasons.push(`alias ${origin}: ${r.err || r.out || `exit ${r.code}`}`);
  }
  const live = opts.reachState === "hot";
  // A project mailbox waits for ANY session in that tree, so it is the net under
  // an alias that never registered, has gone cold, or could not be reached.
  if (project && !(aliasOk && live)) {
    const r = await send(["send", "--to-project", project, ...common, body]);
    if (r.code === 0) via.push(`project:${project}`);
    else reasons.push(`project ${project}: ${r.err || r.out || `exit ${r.code}`}`);
  }

  let result: WakeResult;
  if (!origin && !project) result = { state: "no-origin", via, reason: "the page config names no origin session or project" };
  else if (via.length === 0) result = { state: "undelivered", via, reason: reasons.join("; ") };
  else if (aliasOk && live) result = { state: "requested", via, reason: "" };
  else result = { state: "queued", via, reason: reasons.join("; ") || `origin is ${opts.reachState ?? "unknown"}, so the message waits for a session to return` };

  try {
    const tmp = path.join(opts.dir, ".notify.json.tmp");
    fs.writeFileSync(tmp, JSON.stringify({ ...result, at: now() }, null, 1), "utf8");
    fs.renameSync(tmp, path.join(opts.dir, ".notify.json"));
  } catch { /* the page's answer is saved either way */ }
  return result;
}

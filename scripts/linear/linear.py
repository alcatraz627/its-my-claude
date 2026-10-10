#!/usr/bin/env python3
"""Work with Linear from the terminal: read issues, projects, cycles and points, make changes, and publish docs.

Reads run straight away and never change Linear. Every change first prints exactly what it
will send, with names resolved to what Linear knows ("In Review", "cycle 97", "Aakarsh");
add --yes to send it. The skill's field guide explains how each part of Linear behaves:
~/.claude/skills/linear/references/field-guide.md

Auth: LINEAR_API_KEY (for example exported in ~/.zshenv), or the keychain service linear-api.
The team defaults to the workspace's only team; set LINEAR_TEAM or --team when there are several.

  linear.py whoami                                  key owner, workspace, team, rate limits
  linear.py issue show VER-986 [--comments]         one issue in full
  linear.py issues --cycle current --mine           filtered list (state, label, project, milestone, cycle, assignee)
  linear.py search "system of record" [--docs|--projects]
  linear.py projects | project show "V6" | milestones "V6"
  linear.py cycle [current|next|previous|N]         progress and points
  linear.py points --cycle current | --project "V6" [--milestone "V6: SoR"]
  linear.py labels | states | users | templates | views | view run "Next Sprint Board"
  linear.py comments VER-986 | docs list VER-986 | doc pull <id> [-o f.md] | doc history <id>
  linear.py query '{ viewer { name } }'             any read-only GraphQL
  linear.py snapshot -o versable.md                 this workspace's states, labels, cycles, projects

  linear.py issue create --title "..." [--body-file f.md] [--state] [--label ...] [--estimate 3] [--cycle next] [--parent VER-1] [--yes]
  linear.py issue update VER-1 [--state "In Review"] [--add-label x] [--estimate 5] [--milestone "..."] [--yes]
  linear.py comment add VER-1 --body "..." [--parent <commentId>] | comment edit <id> | comment resolve <id>
  linear.py link VER-1 <url> [--title] | relate VER-1 blocks VER-2
  linear.py milestone create "V6" "Name" [--target 2026-10-31] | milestone update "V6" "Name" [--target ...]
  linear.py project update "V6" [--status Planned] [--lead me] [--target ...] | project post "V6" --health atRisk --body-file f.md
  linear.py label create "Name" | initiative create "Name" | initiative update "Name" [--status ...]
  linear.py doc archive <id> | docs publish linear.json [--dry-run] [--force] [--yes]
"""
import argparse
import datetime as dt
import hashlib
import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from client import Client, LinearError, Resolver, emit, pick, short_date, table  # noqa: E402

PRIORITY = {"none": 0, "urgent": 1, "high": 2, "medium": 3, "normal": 3, "low": 4}
ISSUE_F = ("id identifier title url priority priorityLabel estimate dueDate updatedAt "
           "state { name type } assignee { name } labels { nodes { name } } project { name } "
           "projectMilestone { name } cycle { number } parent { identifier }")



def issue_row(i):
    return [i["identifier"], (i.get("state") or {}).get("name"), i.get("estimate"), (i.get("assignee") or {}).get("name"),
            (i.get("cycle") or {}).get("number"), (i.get("projectMilestone") or {}).get("name"), i["title"]]


def print_issues(nodes):
    table([issue_row(i) for i in nodes], ["id", "state", "pts", "assignee", "cycle", "milestone", "title"])


def body_arg(a, text_attr="body", file_attr="body_file"):
    if getattr(a, file_attr, None):
        return pathlib.Path(getattr(a, file_attr)).read_text()
    return getattr(a, text_attr, None)


def date_arg(s):
    if s is None:
        return None
    try:
        dt.date.fromisoformat(s)
    except ValueError:
        raise LinearError(f"dates are YYYY-MM-DD, not {s!r}")
    return s


def plan_or_send(ctx, summary, mutation, variables, result_path=None):
    """Show what a change will do; send it only with --yes. Returns the mutation's result when sent."""
    if ctx.json and not ctx.yes:
        print(json.dumps({"would": summary, "sent": False, "variables": variables}, indent=1))
        return None
    if not ctx.yes:
        print("Would:")
        for line in summary:
            print(f"  {line}")
        print("Nothing sent. Re-run with --yes to send.")
        return None
    data = ctx.c.write(mutation, variables)
    out = data
    for k in (result_path or "").split("."):
        if k:
            out = out[k]
    if ctx.json:
        print(json.dumps({"did": summary, "sent": True, "result": out}, indent=1, default=str))
    else:
        print("Done:")
        for line in summary:
            print(f"  {line}")
        if isinstance(out, dict) and out.get("url"):
            print(f"  {out['url']}")
    return out


def resolve_issue_fields(ctx, a, summary, for_update=False):
    """Turn the shared issue flags into an input dict, recording each resolved value in the summary."""
    r, inp = ctx.r, {}
    if getattr(a, "title", None):
        inp["title"] = a.title; summary.append(f"title: {a.title}")
    body = body_arg(a, "description", "body_file")
    if body is not None:
        inp["description"] = body; summary.append(f"description: {len(body)} characters")
    if getattr(a, "state", None):
        s = r.state(a.state); inp["stateId"] = s["id"]; summary.append(f"state: {s['name']}")
    if getattr(a, "assignee", None):
        if a.assignee.lower() in ("none", "nobody"):
            inp["assigneeId"] = None; summary.append("assignee: none")
        else:
            u = r.user(a.assignee); inp["assigneeId"] = u["id"]; summary.append(f"assignee: {u['name']}")
    if getattr(a, "estimate", None) is not None:
        inp["estimate"] = r.estimate(a.estimate); summary.append(f"estimate: {inp['estimate']}")
    if getattr(a, "priority", None):
        p = a.priority.lower()
        if p not in PRIORITY:
            raise LinearError(f"priority is one of {', '.join(PRIORITY)}")
        inp["priority"] = PRIORITY[p]; summary.append(f"priority: {p}")
    if getattr(a, "due", None):
        inp["dueDate"] = date_arg(a.due); summary.append(f"due: {a.due}")
    project = None
    if getattr(a, "project", None):
        project = r.project(a.project); inp["projectId"] = project["id"]; summary.append(f"project: {project['name']}")
    if getattr(a, "milestone", None):
        if not project:
            if for_update and getattr(a, "_current_project", None):
                project = a._current_project
            else:
                raise LinearError("--milestone needs --project (or an issue already in a project)")
        m = r.milestone(project["id"], a.milestone); inp["projectMilestoneId"] = m["id"]; summary.append(f"milestone: {m['name']}")
    if getattr(a, "cycle", None):
        if a.cycle.lower() == "none":
            inp["cycleId"] = None; summary.append("cycle: none")
        else:
            c = r.cycle(a.cycle); inp["cycleId"] = c["id"]; summary.append(f"cycle: {c['number']} ({short_date(c['startsAt'])} to {short_date(c['endsAt'])})")
    if getattr(a, "parent", None):
        p = r.issue(a.parent); inp["parentId"] = p["id"]; summary.append(f"parent: {p['identifier']} {p['title']}")
    labels = getattr(a, "label", None) or []
    if labels:
        ls = [r.label(x) for x in labels]; inp["labelIds"] = [x["id"] for x in ls]; summary.append(f"labels (set): {', '.join(x['name'] for x in ls)}")
    if getattr(a, "add_label", None):
        ls = [r.label(x) for x in a.add_label]; inp["addedLabelIds"] = [x["id"] for x in ls]; summary.append(f"labels add: {', '.join(x['name'] for x in ls)}")
    if getattr(a, "remove_label", None):
        ls = [r.label(x) for x in a.remove_label]; inp["removedLabelIds"] = [x["id"] for x in ls]; summary.append(f"labels remove: {', '.join(x['name'] for x in ls)}")
    return inp



def cmd_whoami(ctx, a):
    d = ctx.c.read("{ viewer { name email admin } organization { name urlKey } }")
    t = ctx.r.team()
    d["team"] = {"key": t["key"], "name": t["name"], "estimates": t["issueEstimationType"], "allowed_estimates": ctx.r.allowed_estimates()}
    d["limits"] = ctx.c.limits

    def text(d):
        v, o, l = d["viewer"], d["organization"], d["limits"]
        print(f"key owner  {v['name']} <{v['email']}>{' (admin)' if v['admin'] else ''}")
        print(f"workspace  {o['name']} (linear.app/{o['urlKey']})")
        print(f"team       {d['team']['key']} {d['team']['name']}, estimates {d['team']['estimates']} {d['team']['allowed_estimates']}")
        print(f"limits     requests {l.get('x-ratelimit-requests-remaining')}/{l.get('x-ratelimit-requests-limit')} per hour, "
              f"complexity {l.get('x-ratelimit-complexity-remaining')}/{l.get('x-ratelimit-complexity-limit')}")
    emit(d, ctx.json, text)


def cmd_issue_show(ctx, a):
    q = ("query($id:String!){ issue(id:$id){ " + ISSUE_F + " description createdAt creator { name } team { key } "
         "children(first:50){ nodes { identifier title state { name } estimate } } "
         "relations(first:50){ nodes { type relatedIssue { identifier title } } } "
         "inverseRelations(first:50){ nodes { type issue { identifier title } } } "
         "attachments(first:50){ nodes { title url } } "
         "documents(first:50){ nodes { id title url updatedAt updatedBy { name } } } "
         + ("comments(first:100){ nodes { id createdAt user { name } body parent { id } resolvedAt } } " if a.comments else "")
         + "} }")
    i = ctx.c.read(q, {"id": a.id})["issue"]
    if not i:
        raise LinearError(f"no issue {a.id}")

    def text(i):
        print(f"{i['identifier']}  {i['title']}")
        print(f"  {i['url']}")
        print(f"  state {i['state']['name']} · priority {i['priorityLabel']} · estimate {i['estimate']} · assignee {(i['assignee'] or {}).get('name')}")
        print(f"  project {(i['project'] or {}).get('name')} · milestone {(i['projectMilestone'] or {}).get('name')} · cycle {(i['cycle'] or {}).get('number')} · due {i['dueDate']}")
        print(f"  labels {', '.join(x['name'] for x in i['labels']['nodes']) or '-'} · parent {(i['parent'] or {}).get('identifier')}")
        if i["description"]:
            print("\n" + i["description"].strip() + "\n")
        for label, nodes, fmt in (
            ("sub-issues", i["children"]["nodes"], lambda n: f"{n['identifier']} [{n['state']['name']}] {n['title']}"),
            ("relations", i["relations"]["nodes"], lambda n: f"{n['type']} {n['relatedIssue']['identifier']} {n['relatedIssue']['title']}"),
            ("related from", i["inverseRelations"]["nodes"], lambda n: f"{n['issue']['identifier']} {n['type']} this: {n['issue']['title']}"),
            ("links", i["attachments"]["nodes"], lambda n: f"{n['title']} {n['url']}"),
            ("documents", i["documents"]["nodes"], lambda n: f"{n['title']}  {n['url']}  (edited {short_date(n['updatedAt'])} by {(n['updatedBy'] or {}).get('name')})"),
        ):
            if nodes:
                print(f"{label}:")
                for n in nodes:
                    print(f"  {fmt(n)}")
        for c in (i.get("comments") or {}).get("nodes", []):
            tag = " (reply)" if c["parent"] else ""
            res = " [resolved]" if c["resolvedAt"] else ""
            print(f"\n-- {c['user']['name'] if c['user'] else '?'} {short_date(c['createdAt'])}{tag}{res} id {c['id']}\n{c['body'].strip()}")
    emit(i, ctx.json, text)


def issue_filter(ctx, a):
    r = ctx.r
    f = {"team": {"id": {"eq": r.team()["id"]}}}
    if a.state:
        f["state"] = {"id": {"in": [r.state(s)["id"] for s in a.state]}}
    elif not a.include_done:
        f["state"] = {"type": {"nin": ["completed", "canceled", "duplicate"]}}
    if a.mine:
        f["assignee"] = {"isMe": {"eq": True}}
    elif a.assignee:
        f["assignee"] = {"id": {"eq": r.user(a.assignee)["id"]}}
    if a.label:
        f["labels"] = {"id": {"in": [r.label(x)["id"] for x in a.label]}}
    project = None
    if a.project:
        project = r.project(a.project)
        f["project"] = {"id": {"eq": project["id"]}}
    if a.milestone:
        if not project:
            raise LinearError("--milestone needs --project")
        f["projectMilestone"] = {"id": {"eq": r.milestone(project["id"], a.milestone)["id"]}}
    if a.cycle:
        f["cycle"] = {"id": {"eq": r.cycle(a.cycle)["id"]}}
    if a.unestimated:
        f["estimate"] = {"null": True}
    return f


def cmd_issues(ctx, a):
    nodes = ctx.c.pages("query($f:IssueFilter,$first:Int,$after:String){ issues(filter:$f, first:$first, after:$after, orderBy:updatedAt){ nodes { "
                        + ISSUE_F + " } pageInfo { hasNextPage endCursor } } }", "issues", {"f": issue_filter(ctx, a)}, limit=a.limit)
    emit(nodes, ctx.json, print_issues)


def cmd_search(ctx, a):
    kind = "searchDocuments" if a.docs else "searchProjects" if a.projects else "searchIssues"
    fields = {"searchIssues": "identifier title url state { name }", "searchDocuments": "id title url updatedAt issue { identifier } project { name }",
              "searchProjects": "name url state"}[kind]
    d = ctx.c.read(f"query($t:String!,$n:Int){{ {kind}(term:$t, first:$n, includeComments:{str(a.comments).lower()}){{ totalCount nodes {{ {fields} }} }} }}",
                   {"t": a.term, "n": a.limit})[kind]

    def text(d):
        print(f"{d['totalCount']} match(es)")
        for n in d["nodes"]:
            if kind == "searchIssues":
                print(f"  {n['identifier']} [{n['state']['name']}] {n['title']}")
            elif kind == "searchDocuments":
                parent = (n.get("issue") or {}).get("identifier") or (n.get("project") or {}).get("name") or ""
                print(f"  {n['title']}  ({parent}, edited {short_date(n['updatedAt'])})  id {n['id']}  {n['url']}")
            else:
                print(f"  {n['name']} [{n['state']}] {n['url']}")
    emit(d, ctx.json, text)


def cmd_projects(ctx, a):
    nodes = ctx.c.pages("query($first:Int,$after:String){ projects(first:$first, after:$after){ nodes { name state progress targetDate startDate "
                        "status { name } lead { name } url } pageInfo { hasNextPage endCursor } } }", "projects", limit=200)
    if not a.all:
        nodes = [p for p in nodes if p["state"] not in ("completed", "canceled")]

    def text(ns):
        table([[p["name"], (p["status"] or {}).get("name"), f"{round((p['progress'] or 0) * 100)}%", (p["lead"] or {}).get("name"),
                p["startDate"], p["targetDate"]] for p in ns], ["project", "status", "done", "lead", "start", "target"])
    emit(nodes, ctx.json, text)


def cmd_project_show(ctx, a):
    p = ctx.r.project(a.name)
    d = ctx.c.read("query($id:String!){ project(id:$id){ name url description content progress health targetDate startDate status { name } lead { name } "
                   "members(first:50){ nodes { name } } labels { nodes { name } } "
                   "projectMilestones(first:50){ nodes { name targetDate progress } } "
                   "projectUpdates(first:3){ nodes { createdAt health user { name } body } } "
                   "documents(first:50){ nodes { title url } } } }", {"id": p["id"]})["project"]

    def text(d):
        print(f"{d['name']}  [{(d['status'] or {}).get('name')}]  {round((d['progress'] or 0) * 100)}% done")
        print(f"  {d['url']}")
        print(f"  lead {(d['lead'] or {}).get('name')} · {d['startDate']} to {d['targetDate']} · health {d['health']} · labels {', '.join(x['name'] for x in d['labels']['nodes']) or '-'}")
        print(f"  members {', '.join(x['name'] for x in d['members']['nodes']) or '-'}")
        if d["description"]:
            print(f"  {d['description']}")
        if d["projectMilestones"]["nodes"]:
            print("milestones:")
            for m in d["projectMilestones"]["nodes"]:
                print(f"  {m['name']}  {round((m['progress'] or 0) * 100)}%  target {m['targetDate']}")
        if d["projectUpdates"]["nodes"]:
            print("latest updates:")
            for u in d["projectUpdates"]["nodes"]:
                print(f"  {short_date(u['createdAt'])} {u['health']} by {(u['user'] or {}).get('name')}: {u['body'][:160]}")
        if d["documents"]["nodes"]:
            print("documents:")
            for x in d["documents"]["nodes"]:
                print(f"  {x['title']}  {x['url']}")
    emit(d, ctx.json, text)


def cmd_milestones(ctx, a):
    p = ctx.r.project(a.project)
    ms = ctx.c.read("query($id:String!){ project(id:$id){ projectMilestones(first:100){ nodes { id name targetDate progress description } } } }",
                    {"id": p["id"]})["project"]["projectMilestones"]["nodes"]
    emit(ms, ctx.json, lambda ms: table([[m["name"], f"{round((m['progress'] or 0) * 100)}%", m["targetDate"]] for m in ms], ["milestone", "done", "target"]))


def points_of(nodes):
    by = {}
    for i in nodes:
        t = i["state"]["type"]
        by.setdefault(t, [0, 0, 0])
        by[t][0] += 1
        by[t][1] += i["estimate"] or 0
        by[t][2] += 0 if i["estimate"] is not None else 1
    return by


def print_points(nodes):
    by = points_of(nodes)
    total = sum(v[1] for v in by.values())
    done = by.get("completed", [0, 0, 0])[1]
    print(f"issues {len(nodes)} · points {total} · done {done} ({round(done / total * 100) if total else 0}%) · unestimated {sum(v[2] for v in by.values())}")
    table([[k, v[0], v[1], v[2]] for k, v in sorted(by.items())], ["state type", "issues", "points", "unestimated"])


def scoped_issues(ctx, f):
    return ctx.c.pages("query($f:IssueFilter,$first:Int,$after:String){ issues(filter:$f, first:$first, after:$after){ nodes { "
                       "identifier title estimate state { name type } assignee { name } } pageInfo { hasNextPage endCursor } } }",
                       "issues", {"f": f}, limit=1000)


def cmd_cycle(ctx, a):
    c = ctx.r.cycle(a.spec)
    d = ctx.c.read("query($id:String!){ cycle(id:$id){ number name startsAt endsAt completedAt progress } }", {"id": c["id"]})["cycle"]
    nodes = scoped_issues(ctx, {"cycle": {"id": {"eq": c["id"]}}})
    d["issues"] = nodes
    d["points"] = points_of(nodes)

    def text(d):
        print(f"cycle {d['number']}{' ' + d['name'] if d['name'] else ''}: {short_date(d['startsAt'])} to {short_date(d['endsAt'])}"
              f"{' (closed ' + short_date(d['completedAt']) + ')' if d['completedAt'] else ''} · Linear progress {round((d['progress'] or 0) * 100)}%")
        print_points(nodes)
        if a.list:
            print_issues(nodes)
    emit(d, ctx.json, text)


def cmd_points(ctx, a):
    f = {}
    if a.cycle:
        f["cycle"] = {"id": {"eq": ctx.r.cycle(a.cycle)["id"]}}
    if a.project:
        p = ctx.r.project(a.project)
        f["project"] = {"id": {"eq": p["id"]}}
        if a.milestone:
            f["projectMilestone"] = {"id": {"eq": ctx.r.milestone(p["id"], a.milestone)["id"]}}
    if a.assignee:
        f["assignee"] = {"id": {"eq": ctx.r.user(a.assignee)["id"]}}
    if not f:
        raise LinearError("give --cycle, --project (and optionally --milestone), or --assignee")
    nodes = scoped_issues(ctx, f)
    emit({"points": points_of(nodes), "issues": nodes}, ctx.json, lambda d: print_points(nodes))


def cmd_labels(ctx, a):
    emit(ctx.r.labels(), ctx.json, lambda ls: table([[l["name"], (l["team"] or {}).get("key") or "workspace"] for l in sorted(ls, key=lambda l: l["name"].lower())], ["label", "scope"]))


def cmd_states(ctx, a):
    emit(ctx.r.states(), ctx.json, lambda ss: table([[s["name"], s["type"]] for s in sorted(ss, key=lambda s: s["position"])], ["state", "type"]))


def cmd_users(ctx, a):
    emit([u for u in ctx.r.users() if u["active"]], ctx.json, lambda us: table([[u["name"], u["displayName"], u["email"]] for u in us], ["name", "handle", "email"]))


def cmd_templates(ctx, a):
    emit(ctx.r.templates(), ctx.json, lambda ts: table([[t["name"], t["type"]] for t in ts], ["template", "type"]))


def views(ctx):
    return ctx.c.read("{ customViews(first:100){ nodes { id name shared description modelName } } }")["customViews"]["nodes"]


def cmd_views(ctx, a):
    emit(views(ctx), ctx.json, lambda vs: table([[v["name"], v["modelName"], "shared" if v["shared"] else "personal"] for v in vs], ["view", "of", "visibility"]))


def cmd_view_run(ctx, a):
    v = pick("view", a.name, views(ctx))
    nodes = ctx.c.pages("query($id:String!,$first:Int,$after:String){ customView(id:$id){ issues(first:$first, after:$after){ nodes { "
                        + ISSUE_F + " } pageInfo { hasNextPage endCursor } } } }", "customView.issues", {"id": v["id"]}, limit=a.limit)
    emit(nodes, ctx.json, print_issues)


def cmd_comments(ctx, a):
    d = ctx.c.read("query($id:String!){ issue(id:$id){ comments(first:100){ nodes { id createdAt editedAt user { name } body parent { id } resolvedAt } } } }",
                   {"id": a.id})["issue"]["comments"]["nodes"]

    def text(cs):
        for c in sorted(cs, key=lambda c: c["createdAt"]):
            tag = f" reply to {c['parent']['id'][:8]}" if c["parent"] else ""
            print(f"-- {(c['user'] or {}).get('name')} {short_date(c['createdAt'])}{' edited' if c['editedAt'] else ''}{tag}"
                  f"{' [resolved]' if c['resolvedAt'] else ''} id {c['id']}\n{c['body'].strip()}\n")
    emit(d, ctx.json, text)


def cmd_docs_list(ctx, a):
    d = ctx.c.read("query($id:String!){ issue(id:$id){ documents(first:100){ nodes { id slugId title url createdAt updatedAt updatedBy { name } } } } }",
                   {"id": a.id})["issue"]["documents"]["nodes"]
    emit(d, ctx.json, lambda ds: table([[x["title"], short_date(x["updatedAt"]), (x["updatedBy"] or {}).get("name"), x["slugId"]] for x in ds],
                                       ["document", "edited", "by", "id"]))


def doc_id(s):
    """A document id, slug id, or URL (…/document/<title>-<slugId>)."""
    m = re.search(r"/document/[^/?#]*-([0-9a-f]{12})", s)
    return m.group(1) if m else s


def cmd_doc_pull(ctx, a):
    d = ctx.c.read("query($id:String!){ document(id:$id){ id title url content updatedAt } }", {"id": doc_id(a.id)})["document"]
    if d["content"] is None:
        print(f"linear: {d['title']} has no stored content (empty document)", file=sys.stderr)
    if a.out:
        pathlib.Path(a.out).write_text(d["content"] or "")
        print(f"wrote {a.out} ({len(d['content'] or '')} chars) from {d['title']}")
    else:
        emit(d, ctx.json, lambda d: print(d["content"] or ""))


def cmd_doc_history(ctx, a):
    doc = ctx.c.read("query($id:String!){ document(id:$id){ id title updatedAt documentContentId } }", {"id": doc_id(a.id)})["document"]
    # History is keyed by the content id; given the document id Linear answers success with an empty list.
    h = ctx.c.read("query($id:String!){ documentContentHistory(id:$id){ history { id createdAt contentDataSnapshotAt actorIds } } }",
                   {"id": doc["documentContentId"]})["documentContentHistory"]["history"]
    emit(h, ctx.json, lambda h: table([[x["contentDataSnapshotAt"], len(x["actorIds"] or [])] for x in h], ["snapshot at", "actors"]))


def cmd_query(ctx, a):
    q = pathlib.Path(a.graphql).read_text() if pathlib.Path(a.graphql).is_file() else a.graphql
    print(json.dumps(ctx.c.read(q, json.loads(a.vars) if a.vars else None), indent=1))


def cmd_snapshot(ctx, a):
    """Write a markdown snapshot of this workspace for the skill's references."""
    r = ctx.r
    t = r.team()
    org = ctx.c.read("{ organization { name urlKey } }")["organization"]
    cur = r.cycle("current")
    projects = ctx.c.pages("query($first:Int,$after:String){ projects(first:$first, after:$after){ nodes { name state status { name } lead { name } targetDate "
                           "projectMilestones(first:30){ nodes { name targetDate } } } pageInfo { hasNextPage endCursor } } }", "projects", limit=200)
    pstat = ctx.c.read("{ projectStatuses(first:50){ nodes { name type } } }")["projectStatuses"]["nodes"]
    tinfo = ctx.c.read("query($t:String!){ team(id:$t){ cycleDuration cycleStartDay upcomingCycleCount triageEnabled } }", {"t": t["id"]})["team"]
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    L = [f"# {org['name']} workspace snapshot", "",
         f"Generated by `linear.py snapshot` on {dt.date.today().isoformat()}. Re-run it when something here looks stale; this file is data, not rules.", "",
         f"- Workspace: {org['name']} (`linear.app/{org['urlKey']}`). Team: `{t['key']}` {t['name']}.",
         f"- Cycles: every {tinfo['cycleDuration']} week(s), starting {days[int(tinfo['cycleStartDay'])]}; {tinfo['upcomingCycleCount']} upcoming created ahead. Current: cycle {cur['number']}, {short_date(cur['startsAt'])} to {short_date(cur['endsAt'])}.",
         f"- Points: {t['issueEstimationType']}; allowed {r.allowed_estimates()}.",
         f"- Triage: {'on' if tinfo['triageEnabled'] else 'off'}.", "",
         "## Issue states", "", "| state | type |", "|---|---|"]
    L += [f"| {s['name']} | {s['type']} |" for s in sorted(r.states(), key=lambda s: s["position"])]
    L += ["", "## Project statuses", "", ", ".join(s["name"] for s in pstat), "", "## Labels", "",
          ", ".join(sorted((l["name"] for l in r.labels()), key=str.lower)), "", "## Templates", "",
          ", ".join(f"{x['name']} ({x['type']})" for x in r.templates()), "", "## Saved views", "",
          ", ".join(v["name"] for v in views(ctx)), "", "## Active projects and milestones", "", "| project | status | lead | target | milestones |", "|---|---|---|---|---|"]
    for p in projects:
        if p["state"] in ("completed", "canceled"):
            continue
        ms = ", ".join(m["name"] for m in p["projectMilestones"]["nodes"]) or "-"
        L.append(f"| {p['name']} | {(p['status'] or {}).get('name')} | {(p['lead'] or {}).get('name')} | {p['targetDate'] or '-'} | {ms} |")
    L += ["", "## People", "", ", ".join(u["name"] for u in r.users() if u["active"]), ""]
    pathlib.Path(a.out).write_text("\n".join(L))
    print(f"wrote {a.out}")



def cmd_issue_create(ctx, a):
    summary = [f"create an issue in {ctx.r.team()['key']}"]
    inp = {"teamId": ctx.r.team()["id"]}
    if a.template:
        tp = ctx.r.template(a.template); inp["templateId"] = tp["id"]; summary.append(f"template: {tp['name']}")
    if not a.title:
        raise LinearError("--title is required")
    inp.update(resolve_issue_fields(ctx, a, summary))
    plan_or_send(ctx, summary, "mutation($i:IssueCreateInput!){ issueCreate(input:$i){ success issue { identifier title url } } }", {"i": inp}, "issueCreate.issue")


def cmd_issue_update(ctx, a):
    cur = ctx.c.read("query($id:String!){ issue(id:$id){ id identifier title project { id name } } }", {"id": a.id})["issue"]
    if not cur:
        raise LinearError(f"no issue {a.id}")
    a._current_project = cur["project"]
    summary = [f"update {cur['identifier']} {cur['title']}"]
    inp = resolve_issue_fields(ctx, a, summary, for_update=True)
    if len(summary) == 1:
        raise LinearError("nothing to change; pass at least one field")
    plan_or_send(ctx, summary, "mutation($id:String!,$i:IssueUpdateInput!){ issueUpdate(id:$id, input:$i){ success issue { identifier url } } }",
                 {"id": cur["id"], "i": inp}, "issueUpdate.issue")


def cmd_issue_archive(ctx, a):
    i = ctx.r.issue(a.id)
    plan_or_send(ctx, [f"archive {i['identifier']} {i['title']}"], "mutation($id:String!){ issueArchive(id:$id){ success } }", {"id": i["id"]}, "issueArchive")


def cmd_comment_add(ctx, a):
    i = ctx.r.issue(a.id)
    body = body_arg(a)
    if not body:
        raise LinearError("--body or --body-file is required")
    inp = {"issueId": i["id"], "body": body}
    summary = [f"comment on {i['identifier']} ({len(body)} characters)"]
    if a.parent:
        inp["parentId"] = a.parent; summary.append(f"as a reply to comment {a.parent}")
    plan_or_send(ctx, summary, "mutation($i:CommentCreateInput!){ commentCreate(input:$i){ success comment { id url } } }", {"i": inp}, "commentCreate.comment")


def cmd_comment_edit(ctx, a):
    body = body_arg(a)
    if not body:
        raise LinearError("--body or --body-file is required")
    plan_or_send(ctx, [f"replace the text of comment {a.comment_id} ({len(body)} characters)"],
                 "mutation($id:String!,$i:CommentUpdateInput!){ commentUpdate(id:$id, input:$i){ success comment { id url } } }",
                 {"id": a.comment_id, "i": {"body": body}}, "commentUpdate.comment")


def cmd_comment_delete(ctx, a):
    c = ctx.c.read("query($id:String!){ comment(id:$id){ id body user { name } issue { identifier } } }", {"id": a.comment_id})["comment"]
    head = " ".join((c["body"] or "").split())[:80]
    plan_or_send(ctx, [f"delete comment {c['id']} on {c['issue']['identifier']} by {(c['user'] or {}).get('name')}: \"{head}\""],
                 "mutation($id:String!){ commentDelete(id:$id){ success } }", {"id": c["id"]}, "commentDelete")


def cmd_comment_resolve(ctx, a):
    plan_or_send(ctx, [f"resolve the thread of comment {a.comment_id}"], "mutation($id:String!){ commentResolve(id:$id){ success } }",
                 {"id": a.comment_id}, "commentResolve")


def cmd_link(ctx, a):
    i = ctx.r.issue(a.id)
    plan_or_send(ctx, [f"link {a.url} on {i['identifier']}" + (f" as {a.title!r}" if a.title else "")],
                 "mutation($i:String!,$u:String!,$t:String){ attachmentLinkURL(issueId:$i, url:$u, title:$t){ success attachment { id url } } }",
                 {"i": i["id"], "u": a.url, "t": a.title}, "attachmentLinkURL.attachment")


def cmd_relate(ctx, a):
    kinds = {"blocks": "blocks", "blocked-by": "blocks", "related": "related", "relates": "related", "duplicate": "duplicate", "duplicates": "duplicate", "similar": "similar"}
    if a.kind not in kinds:
        raise LinearError(f"relation is one of {', '.join(kinds)}")
    x, y = ctx.r.issue(a.id), ctx.r.issue(a.other)
    src, dst = (y, x) if a.kind == "blocked-by" else (x, y)
    plan_or_send(ctx, [f"{src['identifier']} {kinds[a.kind]} {dst['identifier']}"],
                 "mutation($i:IssueRelationCreateInput!){ issueRelationCreate(input:$i){ success } }",
                 {"i": {"issueId": src["id"], "relatedIssueId": dst["id"], "type": kinds[a.kind]}}, "issueRelationCreate")


def cmd_milestone_create(ctx, a):
    p = ctx.r.project(a.project)
    inp = {"projectId": p["id"], "name": a.name}
    summary = [f"create milestone {a.name!r} in {p['name']}"]
    if a.target:
        inp["targetDate"] = date_arg(a.target); summary.append(f"target {a.target}")
    if a.description:
        inp["description"] = a.description
    plan_or_send(ctx, summary, "mutation($i:ProjectMilestoneCreateInput!){ projectMilestoneCreate(input:$i){ success projectMilestone { id name } } }",
                 {"i": inp}, "projectMilestoneCreate.projectMilestone")


def cmd_milestone_update(ctx, a):
    p = ctx.r.project(a.project)
    m = ctx.r.milestone(p["id"], a.name)
    inp, summary = {}, [f"update milestone {m['name']!r} in {p['name']}"]
    if a.rename:
        inp["name"] = a.rename; summary.append(f"rename to {a.rename!r}")
    if a.target:
        inp["targetDate"] = date_arg(a.target); summary.append(f"target {a.target}")
    if a.description:
        inp["description"] = a.description; summary.append("description")
    if not inp:
        raise LinearError("nothing to change")
    plan_or_send(ctx, summary, "mutation($id:String!,$i:ProjectMilestoneUpdateInput!){ projectMilestoneUpdate(id:$id, input:$i){ success } }",
                 {"id": m["id"], "i": inp}, "projectMilestoneUpdate")


def cmd_project_update(ctx, a):
    p = ctx.r.project(a.name)
    inp, summary = {}, [f"update project {p['name']}"]
    if a.status:
        st = pick("project status", a.status, ctx.c.read("{ projectStatuses(first:50){ nodes { id name } } }")["projectStatuses"]["nodes"])
        inp["statusId"] = st["id"]; summary.append(f"status: {st['name']}")
    if a.lead:
        u = ctx.r.user(a.lead); inp["leadId"] = u["id"]; summary.append(f"lead: {u['name']}")
    if a.start:
        inp["startDate"] = date_arg(a.start); summary.append(f"start: {a.start}")
    if a.target:
        inp["targetDate"] = date_arg(a.target); summary.append(f"target: {a.target}")
    if a.priority:
        inp["priority"] = PRIORITY[a.priority.lower()]; summary.append(f"priority: {a.priority}")
    if a.description:
        inp["description"] = a.description; summary.append("summary line")
    if a.content_file:
        inp["content"] = pathlib.Path(a.content_file).read_text(); summary.append(f"content: {len(inp['content'])} characters (replaces the project's body)")
    if not inp:
        raise LinearError("nothing to change")
    plan_or_send(ctx, summary, "mutation($id:String!,$i:ProjectUpdateInput!){ projectUpdate(id:$id, input:$i){ success project { url } } }",
                 {"id": p["id"], "i": inp}, "projectUpdate.project")


def cmd_project_post(ctx, a):
    p = ctx.r.project(a.name)
    body = body_arg(a)
    if not body:
        raise LinearError("--body or --body-file is required")
    health = {"ontrack": "onTrack", "atrisk": "atRisk", "offtrack": "offTrack"}.get(a.health.lower().replace("-", "").replace("_", "").replace(" ", ""))
    if not health:
        raise LinearError("--health is onTrack, atRisk or offTrack")
    plan_or_send(ctx, [f"post a status update on {p['name']}: {health}, {len(body)} characters"],
                 "mutation($i:ProjectUpdateCreateInput!){ projectUpdateCreate(input:$i){ success projectUpdate { url } } }",
                 {"i": {"projectId": p["id"], "health": health, "body": body}}, "projectUpdateCreate.projectUpdate")


def cmd_label_create(ctx, a):
    inp = {"name": a.name}
    summary = [f"create label {a.name!r}" + (" for the whole workspace" if a.workspace else f" in team {ctx.r.team()['key']}")]
    if not a.workspace:
        inp["teamId"] = ctx.r.team()["id"]
    if a.color:
        inp["color"] = a.color
    if a.description:
        inp["description"] = a.description
    plan_or_send(ctx, summary, "mutation($i:IssueLabelCreateInput!){ issueLabelCreate(input:$i){ success issueLabel { id name } } }", {"i": inp}, "issueLabelCreate.issueLabel")


def initiatives(ctx):
    return ctx.c.read("{ initiatives(first:100){ nodes { id name status targetDate } } }")["initiatives"]["nodes"]


def initiative_input(ctx, a, summary):
    inp = {}
    if getattr(a, "description", None):
        inp["description"] = a.description; summary.append("description")
    if getattr(a, "status", None):
        inp["status"] = a.status; summary.append(f"status: {a.status}")
    if getattr(a, "target", None):
        inp["targetDate"] = date_arg(a.target); summary.append(f"target: {a.target}")
    if getattr(a, "owner", None):
        u = ctx.r.user(a.owner); inp["ownerId"] = u["id"]; summary.append(f"owner: {u['name']}")
    return inp


def cmd_initiative_create(ctx, a):
    summary = [f"create initiative {a.name!r}"]
    inp = {"name": a.name, **initiative_input(ctx, a, summary)}
    plan_or_send(ctx, summary, "mutation($i:InitiativeCreateInput!){ initiativeCreate(input:$i){ success initiative { id name url } } }", {"i": inp}, "initiativeCreate.initiative")


def cmd_initiative_update(ctx, a):
    it = pick("initiative", a.name, initiatives(ctx))
    summary = [f"update initiative {it['name']!r}"]
    inp = initiative_input(ctx, a, summary)
    if not inp:
        raise LinearError("nothing to change")
    plan_or_send(ctx, summary, "mutation($id:String!,$i:InitiativeUpdateInput!){ initiativeUpdate(id:$id, input:$i){ success } }", {"id": it["id"], "i": inp}, "initiativeUpdate")


def cmd_doc_archive(ctx, a):
    d = ctx.c.read("query($id:String!){ document(id:$id){ id title url } }", {"id": doc_id(a.id)})["document"]
    plan_or_send(ctx, [f"archive document {d['title']} ({d['url']}); restorable from Linear"], "mutation($id:String!){ documentDelete(id:$id){ success } }",
                 {"id": d["id"]}, "documentDelete")



def to_linear_md(text):
    """Markdown Linear stores as intended: no frontmatter or HTML comments, table cells on one line.

    The doc sets write a table cell as `Lead.<br>• point<br>• point`. Linear keeps raw HTML as
    literal text (it stored the docs' HTML comments as visible paragraphs), so the break becomes
    a middle dot on the same line.
    """
    text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)
    text = re.sub(r"<!--.*?-->\n?", "", text, flags=re.S)
    text = text.replace("<br>• ", " • ").replace("<br>", " ")
    return text.strip() + "\n"


def relink(text, urls):
    """A link to another file in the set points at that file's Linear document; a section anchor is dropped."""
    def sub(m):
        u = urls.get(m.group(2))
        return f"[{m.group(1)}]({u})" if u else m.group(0)
    return re.sub(r"\[([^\]]+)\]\(([\w.-]+\.md)(?:#[\w-]*)?\)", sub, text)


def sha(s):
    return hashlib.sha256((s or "").encode()).hexdigest()


def doc_title(path, raw, mode):
    if mode == "heading":
        m = re.search(r"^# (.+)$", raw, flags=re.M)
        if m:
            return m.group(1).strip()
    return path.name


def cmd_docs_publish(ctx, a):
    cfg_path = pathlib.Path(a.config).resolve()
    cfg = json.loads(cfg_path.read_text())
    base = cfg_path.parent
    mode = cfg.get("title", "filename")
    files = []
    for rel in cfg["docs"]:
        p = base / rel
        raw = p.read_text()
        files.append((p.name, doc_title(p, raw, mode), to_linear_md(raw)))
    if a.dry_run:
        out = base / ".linear-preview"
        out.mkdir(exist_ok=True)
        fake = {n: f"https://linear.app/doc/{pathlib.Path(n).stem}" for n, _, _ in files}
        for name, _, body in files:
            (out / name).write_text(relink(body, fake))
        print(f"preview written to {out} ({len(files)} files); nothing read from or sent to Linear")
        return
    issue = ctx.c.read("query($id:String!){ issue(id:$id){ id identifier url documents(first:50){ nodes { id title url content "
                       "comments(first:25){ nodes { resolvedAt } } } } } }", {"id": cfg["issue"]})["issue"]
    by_title = {d["title"]: d for d in issue["documents"]["nodes"]}
    state = cfg.setdefault("documents", {})
    plan, blocked = [], []
    for name, title, body in files:
        cur = by_title.get(title)
        if not cur:
            plan.append(("create", name, title, None)); continue
        rec = state.get(name, {})
        open_comments = sum(1 for c in cur["comments"]["nodes"] if not c["resolvedAt"])
        if rec.get("readback_sha") and rec["readback_sha"] != sha(cur["content"]) and not a.force:
            blocked.append(f"{title}: changed in Linear since the last publish (pull it with `doc pull`, or --force to overwrite)")
        elif open_comments and not a.force:
            blocked.append(f"{title}: {open_comments} unresolved inline comment(s) would lose their anchors (--force to overwrite)")
        why = "adopt the existing document (never published by this tool)" if not rec else "update"
        if cur["content"] is None:
            why += "; it is empty on Linear today"
        plan.append(("update", name, title, cur))
        plan[-1] = plan[-1] + (why,)
    print(f"{issue['identifier']} {issue['url']}")
    for step in plan:
        verb, name, title = step[0], step[1], step[2]
        extra = step[4] if len(step) > 4 else "new document"
        print(f"  {verb:7} {title}  ({extra})")
    if blocked:
        print("Stopped before sending anything:")
        for b in blocked:
            print(f"  {b}")
        sys.exit(1)
    if not ctx.yes:
        print("Nothing sent. Re-run with --yes to publish.")
        return
    urls = {}
    for step in plan:
        verb, name, title, cur = step[:4]
        if verb == "create":
            made = ctx.c.write("mutation($i:DocumentCreateInput!){ documentCreate(input:$i){ success document { id url } } }",
                               {"i": {"title": title, "content": "", "issueId": issue["id"]}})["documentCreate"]["document"]
            state[name] = {"id": made["id"], "url": made["url"]}
            print(f"  created {title}  {made['url']}")
        else:
            state.setdefault(name, {}).update({"id": cur["id"], "url": cur["url"]})
        urls[name] = state[name]["url"]
    cfg_path.write_text(json.dumps(cfg, indent=2) + "\n")
    failures = []
    for name, title, body in files:
        content = relink(body, urls)
        ctx.c.write("mutation($id:String!,$i:DocumentUpdateInput!){ documentUpdate(id:$id, input:$i){ success } }",
                    {"id": state[name]["id"], "i": {"title": title, "content": content}})
        back = ctx.c.read("query($id:String!){ document(id:$id){ content } }", {"id": state[name]["id"]})["document"]["content"]
        if not back or len(back) < 0.5 * len(content):
            failures.append(f"{title}: Linear stored {len(back or '')} characters of {len(content)} sent")
        state[name].update({"readback_sha": sha(back), "published_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")})
        cfg_path.write_text(json.dumps(cfg, indent=2) + "\n")
        print(f"  wrote   {title}  sent {len(content)}, stored {len(back or '')}")
    if failures:
        print("Read-back failed; these documents are empty or truncated on Linear:")
        for f in failures:
            print(f"  {f}")
        sys.exit(1)



def add_issue_fields(p, create):
    p.add_argument("--title", required=create)
    p.add_argument("--description", help="description text; use --body-file for markdown files")
    p.add_argument("--body-file", help="markdown file for the description")
    p.add_argument("--state"); p.add_argument("--assignee", help="me, a name, an email, or none")
    p.add_argument("--estimate", type=int); p.add_argument("--priority", help="urgent, high, medium, low, none")
    p.add_argument("--project"); p.add_argument("--milestone"); p.add_argument("--cycle", help="current, next, previous, a number, or none")
    p.add_argument("--parent", help="parent issue, making this a sub-issue"); p.add_argument("--due", help="YYYY-MM-DD")
    p.add_argument("--label", action="append", help="set labels (replaces); repeat for several")
    if not create:
        p.add_argument("--add-label", action="append"); p.add_argument("--remove-label", action="append")


def build_parser():
    ap = argparse.ArgumentParser(prog="linear.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--yes", action="store_true", help="send a change (without it, a change is only shown)")
    ap.add_argument("--team", help="team key when the workspace has several")
    sp = ap.add_subparsers(dest="group", required=True)

    sp.add_parser("whoami").set_defaults(fn=cmd_whoami)

    g = sp.add_parser("issue").add_subparsers(dest="verb", required=True)
    p = g.add_parser("show"); p.add_argument("id"); p.add_argument("--comments", action="store_true"); p.set_defaults(fn=cmd_issue_show)
    p = g.add_parser("create"); add_issue_fields(p, True); p.add_argument("--template"); p.set_defaults(fn=cmd_issue_create)
    p = g.add_parser("update"); p.add_argument("id"); add_issue_fields(p, False); p.set_defaults(fn=cmd_issue_update)
    p = g.add_parser("archive"); p.add_argument("id"); p.set_defaults(fn=cmd_issue_archive)

    p = sp.add_parser("issues")
    p.add_argument("--state", action="append"); p.add_argument("--include-done", action="store_true")
    p.add_argument("--mine", action="store_true"); p.add_argument("--assignee"); p.add_argument("--label", action="append")
    p.add_argument("--project"); p.add_argument("--milestone"); p.add_argument("--cycle")
    p.add_argument("--unestimated", action="store_true"); p.add_argument("--limit", type=int, default=50)
    p.set_defaults(fn=cmd_issues)

    p = sp.add_parser("search"); p.add_argument("term"); p.add_argument("--docs", action="store_true"); p.add_argument("--projects", action="store_true")
    p.add_argument("--comments", action="store_true", help="also match comment text"); p.add_argument("--limit", type=int, default=20); p.set_defaults(fn=cmd_search)

    p = sp.add_parser("projects"); p.add_argument("--all", action="store_true"); p.set_defaults(fn=cmd_projects)
    g = sp.add_parser("project").add_subparsers(dest="verb", required=True)
    p = g.add_parser("show"); p.add_argument("name"); p.set_defaults(fn=cmd_project_show)
    p = g.add_parser("update"); p.add_argument("name"); p.add_argument("--status"); p.add_argument("--lead"); p.add_argument("--start"); p.add_argument("--target")
    p.add_argument("--priority"); p.add_argument("--description", help="the one-line summary"); p.add_argument("--content-file", help="markdown for the project's body")
    p.set_defaults(fn=cmd_project_update)
    p = g.add_parser("post"); p.add_argument("name"); p.add_argument("--health", required=True); p.add_argument("--body"); p.add_argument("--body-file")
    p.set_defaults(fn=cmd_project_post)

    p = sp.add_parser("milestones"); p.add_argument("project"); p.set_defaults(fn=cmd_milestones)
    g = sp.add_parser("milestone").add_subparsers(dest="verb", required=True)
    p = g.add_parser("create"); p.add_argument("project"); p.add_argument("name"); p.add_argument("--target"); p.add_argument("--description"); p.set_defaults(fn=cmd_milestone_create)
    p = g.add_parser("update"); p.add_argument("project"); p.add_argument("name"); p.add_argument("--rename"); p.add_argument("--target"); p.add_argument("--description")
    p.set_defaults(fn=cmd_milestone_update)

    p = sp.add_parser("cycle"); p.add_argument("spec", nargs="?", default="current"); p.add_argument("--list", action="store_true"); p.set_defaults(fn=cmd_cycle)
    p = sp.add_parser("points"); p.add_argument("--cycle"); p.add_argument("--project"); p.add_argument("--milestone"); p.add_argument("--assignee"); p.set_defaults(fn=cmd_points)

    for name, fn in (("labels", cmd_labels), ("states", cmd_states), ("users", cmd_users), ("templates", cmd_templates), ("views", cmd_views)):
        sp.add_parser(name).set_defaults(fn=fn)
    g = sp.add_parser("view").add_subparsers(dest="verb", required=True)
    p = g.add_parser("run"); p.add_argument("name"); p.add_argument("--limit", type=int, default=100); p.set_defaults(fn=cmd_view_run)
    g = sp.add_parser("label").add_subparsers(dest="verb", required=True)
    p = g.add_parser("create"); p.add_argument("name"); p.add_argument("--color"); p.add_argument("--description"); p.add_argument("--workspace", action="store_true")
    p.set_defaults(fn=cmd_label_create)

    p = sp.add_parser("comments"); p.add_argument("id"); p.set_defaults(fn=cmd_comments)
    g = sp.add_parser("comment").add_subparsers(dest="verb", required=True)
    p = g.add_parser("add"); p.add_argument("id"); p.add_argument("--body"); p.add_argument("--body-file"); p.add_argument("--parent"); p.set_defaults(fn=cmd_comment_add)
    p = g.add_parser("edit"); p.add_argument("comment_id"); p.add_argument("--body"); p.add_argument("--body-file"); p.set_defaults(fn=cmd_comment_edit)
    p = g.add_parser("resolve"); p.add_argument("comment_id"); p.set_defaults(fn=cmd_comment_resolve)
    p = g.add_parser("delete"); p.add_argument("comment_id"); p.set_defaults(fn=cmd_comment_delete)

    p = sp.add_parser("link"); p.add_argument("id"); p.add_argument("url"); p.add_argument("--title"); p.set_defaults(fn=cmd_link)
    p = sp.add_parser("relate"); p.add_argument("id"); p.add_argument("kind"); p.add_argument("other"); p.set_defaults(fn=cmd_relate)

    g = sp.add_parser("initiative").add_subparsers(dest="verb", required=True)
    for verb, fn in (("create", cmd_initiative_create), ("update", cmd_initiative_update)):
        p = g.add_parser(verb); p.add_argument("name"); p.add_argument("--description"); p.add_argument("--status", help="Proposed, Planned, Active, Completed, Canceled")
        p.add_argument("--target"); p.add_argument("--owner"); p.set_defaults(fn=fn)

    g = sp.add_parser("docs").add_subparsers(dest="verb", required=True)
    p = g.add_parser("list"); p.add_argument("id"); p.set_defaults(fn=cmd_docs_list)
    p = g.add_parser("publish"); p.add_argument("config"); p.add_argument("--dry-run", action="store_true"); p.add_argument("--force", action="store_true")
    p.set_defaults(fn=cmd_docs_publish)
    g = sp.add_parser("doc").add_subparsers(dest="verb", required=True)
    p = g.add_parser("pull"); p.add_argument("id"); p.add_argument("-o", "--out"); p.set_defaults(fn=cmd_doc_pull)
    p = g.add_parser("history"); p.add_argument("id"); p.set_defaults(fn=cmd_doc_history)
    p = g.add_parser("archive"); p.add_argument("id"); p.set_defaults(fn=cmd_doc_archive)

    p = sp.add_parser("query"); p.add_argument("graphql", help="a query, or a file holding one"); p.add_argument("--vars"); p.set_defaults(fn=cmd_query)
    p = sp.add_parser("snapshot"); p.add_argument("-o", "--out", required=True); p.set_defaults(fn=cmd_snapshot)
    return ap


class Ctx:
    def __init__(self, a):
        self.json, self.yes = a.json, a.yes
        self._c = self._r = None
        self.team = a.team

    @property
    def c(self):
        if self._c is None:
            self._c = Client()
        return self._c

    @property
    def r(self):
        if self._r is None:
            self._r = Resolver(self.c, self.team)
        return self._r


def main(argv=None):
    a = build_parser().parse_args(argv)
    a.fn(Ctx(a), a)
    return 0


if __name__ == "__main__":
    sys.exit(main())

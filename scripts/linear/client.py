"""The Linear connection the /linear skill uses: one client, a name resolver, and output helpers.

The client talks to Linear's GraphQL API with the owner's personal key. Reads go through
`read()`, which refuses anything that is not a query, so exploring can never change Linear.
Writes go through `write()`, which the CLI calls only after showing what it will send.
The resolver turns the names people use ("In Review", "cycle 97", "me", "V6: SoR") into the
ids Linear needs, and says which names exist when one does not match.
"""
import difflib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

API = "https://api.linear.app/graphql"
MUTATION = re.compile(r"(?i)\bmutation\b")

# Allowed estimates per team scale. Linear stores t-shirt sizes as these same numbers.
SCALES = {
    "fibonacci": ([1, 2, 3, 5, 8], [13, 21]),
    "exponential": ([1, 2, 4, 8, 16], [32, 64]),
    "linear": ([1, 2, 3, 4, 5], [6, 7, 8, 9, 10]),
    "tShirt": ([1, 2, 3, 5, 8], [13, 21]),
}


class LinearError(SystemExit):
    """An error to show the user as one line, exiting non-zero."""

    def __init__(self, msg):
        super().__init__(f"linear: {msg}")


def api_key():
    """The owner's key, from the keychain service `linear-api`, else LINEAR_API_KEY. Never printed."""
    try:
        key = subprocess.run(["security", "find-generic-password", "-s", "linear-api", "-w"],
                             capture_output=True, text=True, check=True).stdout.strip()
        if key:
            return key
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    key = os.environ.get("LINEAR_API_KEY", "").strip()
    if not key:
        raise LinearError("no API key. Put LINEAR_API_KEY in ~/.zshenv, or run: "
                          "security add-generic-password -s linear-api -a \"$USER\" -w '<key>'")
    return key


class Client:
    def __init__(self, key=None):
        self.key = key or api_key()
        self.limits = {}

    def _post(self, query, variables):
        body = json.dumps({"query": query, "variables": variables or {}}).encode()
        req = urllib.request.Request(API, data=body, headers={"Authorization": self.key, "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.load(r)
                self.limits = {k.lower(): v for k, v in r.headers.items() if "ratelimit" in k.lower() or k.lower() == "x-complexity"}
        except urllib.error.HTTPError as e:
            text = e.read().decode(errors="replace")[:500]
            if e.code == 401:
                raise LinearError("401 from Linear: the key is wrong, expired or revoked")
            if e.code == 429:
                raise LinearError("429 from Linear: rate limit reached; wait for the reset shown by `linear.py whoami`")
            try:
                out = json.loads(text)
            except ValueError:
                raise LinearError(f"HTTP {e.code} from Linear: {text}")
        except urllib.error.URLError as e:
            raise LinearError(f"cannot reach Linear: {e.reason}")
        if out.get("errors"):
            msgs = []
            for err in out["errors"]:
                ext = err.get("extensions", {})
                msgs.append(ext.get("userPresentableMessage") or err.get("message", "?"))
            text = "; ".join(msgs)
            if "Invalid scope" in text:
                text += (" (the API key was created without that scope; create a key with Read and Write access in"
                         " Linear's settings under personal API keys, and replace LINEAR_API_KEY in ~/.zshenv)")
            raise LinearError(text)
        return out["data"]

    def read(self, query, variables=None):
        """Run a query. Refuses a mutation, so a read can never change anything."""
        if MUTATION.search(re.sub(r"#.*", "", query)):
            raise LinearError("read() refuses a mutation")
        return self._post(query, variables)

    def write(self, mutation, variables=None):
        return self._post(mutation, variables)

    def pages(self, query, path, variables=None, limit=250):
        """Follow `after` cursors on one connection until `limit` nodes. `path` is the dotted path to the connection."""
        variables = dict(variables or {})
        nodes, after = [], None
        while len(nodes) < limit:
            variables.update({"first": min(100, limit - len(nodes)), "after": after})
            data = self.read(query, variables)
            conn = data
            for key in path.split("."):
                conn = conn[key]
            nodes += conn["nodes"]
            if not conn["pageInfo"]["hasNextPage"]:
                break
            after = conn["pageInfo"]["endCursor"]
        return nodes


def closest(name, options, n=6):
    """The option names nearest to a miss, for an error message."""
    low = {o.lower(): o for o in options}
    hits = difflib.get_close_matches(name.lower(), list(low), n=n, cutoff=0.3)
    return [low[h] for h in hits] or sorted(options)[:n]


def pick(kind, name, items, key="name"):
    """Match one item by name: exact (case-insensitive), then unique prefix, then unique substring."""
    names = [i[key] for i in items]
    wanted = name.strip().lower()
    for i in items:
        if i[key].lower() == wanted:
            return i
    for test in (lambda s: s.startswith(wanted), lambda s: wanted in s):
        hits = [i for i in items if test(i[key].lower())]
        if len(hits) == 1:
            return hits[0]
        if len(hits) > 1:
            raise LinearError(f"{kind} {name!r} matches several: {', '.join(h[key] for h in hits)}")
    raise LinearError(f"no {kind} named {name!r}. Closest: {', '.join(closest(name, names))}")


class Resolver:
    """Names to ids, one lookup per kind per run."""

    def __init__(self, client, team_key=None):
        self.c = client
        self._cache = {}
        self.team_key = team_key or os.environ.get("LINEAR_TEAM")

    def _get(self, kind, fn):
        if kind not in self._cache:
            self._cache[kind] = fn()
        return self._cache[kind]

    def team(self):
        def load():
            teams = self.c.read("{ teams(first: 50) { nodes { id key name issueEstimationType issueEstimationAllowZero issueEstimationExtended cyclesEnabled } } }")["teams"]["nodes"]
            if self.team_key:
                return pick("team", self.team_key, teams, "key")
            if len(teams) == 1:
                return teams[0]
            raise LinearError(f"several teams; pass --team or set LINEAR_TEAM. Teams: {', '.join(t['key'] for t in teams)}")
        return self._get("team", load)

    def states(self):
        return self._get("states", lambda: self.c.read(
            "query($t:String!){ team(id:$t){ states { nodes { id name type position } } } }", {"t": self.team()["id"]})["team"]["states"]["nodes"])

    def state(self, name):
        return pick("state", name, self.states())

    def labels(self):
        return self._get("labels", lambda: self.c.pages(
            "query($first:Int,$after:String){ issueLabels(first:$first, after:$after){ nodes { id name team { key } } pageInfo { hasNextPage endCursor } } }",
            "issueLabels", limit=500))

    def label(self, name):
        return pick("label", name, self.labels())

    def users(self):
        return self._get("users", lambda: self.c.pages(
            "query($first:Int,$after:String){ users(first:$first, after:$after){ nodes { id name displayName email active } pageInfo { hasNextPage endCursor } } }",
            "users", limit=500))

    def user(self, who):
        if who.lower() in ("me", "self"):
            return self._get("viewer", lambda: self.c.read("{ viewer { id name email } }")["viewer"])
        us = [u for u in self.users() if u["active"]]
        for u in us:
            if who.lower() in (u["email"].lower(), u["displayName"].lower()):
                return u
        return pick("user", who, us)

    def projects(self):
        return self._get("projects", lambda: self.c.pages(
            "query($first:Int,$after:String){ projects(first:$first, after:$after, includeArchived:false){ nodes { id name slugId state url } pageInfo { hasNextPage endCursor } } }",
            "projects", limit=500))

    def project(self, name):
        return pick("project", name, self.projects())

    def milestone(self, project_id, name):
        ms = self.c.read("query($p:String!){ project(id:$p){ projectMilestones(first:100){ nodes { id name } } } }",
                         {"p": project_id})["project"]["projectMilestones"]["nodes"]
        return pick("milestone", name, ms)

    def cycle(self, spec):
        """`current`, `next`, `previous`, or a cycle number."""
        t = self.team()["id"]
        spec = str(spec).lower()
        if spec in ("current", "active"):
            c = self.c.read("query($t:String!){ team(id:$t){ activeCycle { id number startsAt endsAt } } }", {"t": t})["team"]["activeCycle"]
            if not c:
                raise LinearError("the team has no active cycle")
            return c
        cycles = self.c.read("query($t:String!){ team(id:$t){ cycles(first:100){ nodes { id number startsAt endsAt completedAt } } } }",
                             {"t": t})["team"]["cycles"]["nodes"]
        cycles.sort(key=lambda c: c["number"])
        if spec in ("next", "previous", "prev", "last"):
            cur = self.cycle("current")["number"]
            want = cur + 1 if spec == "next" else cur - 1
        elif spec.isdigit():
            want = int(spec)
        else:
            raise LinearError(f"cycle must be current, next, previous or a number, not {spec!r}")
        for c in cycles:
            if c["number"] == want:
                return c
        raise LinearError(f"no cycle {want}. Known: {', '.join(str(c['number']) for c in cycles[-8:])}")

    def templates(self):
        return self._get("templates", lambda: self.c.read(
            "query($t:String!){ team(id:$t){ templates(first:100){ nodes { id name type templateData } } } }",
            {"t": self.team()["id"]})["team"]["templates"]["nodes"])

    def template(self, name):
        return pick("template", name, self.templates())

    def issue(self, ident):
        i = self.c.read("query($id:String!){ issue(id:$id){ id identifier title url team { id key } } }", {"id": ident})["issue"]
        if not i:
            raise LinearError(f"no issue {ident}")
        return i

    def allowed_estimates(self):
        t = self.team()
        kind = t["issueEstimationType"]
        if kind == "notUsed":
            return []
        base, ext = SCALES.get(kind, ([], []))
        vals = list(base) + (list(ext) if t["issueEstimationExtended"] else [])
        return ([0] if t["issueEstimationAllowZero"] else []) + vals

    def estimate(self, n):
        allowed = self.allowed_estimates()
        if not allowed:
            raise LinearError(f"team {self.team()['key']} does not use estimates")
        n = int(n)
        if n not in allowed:
            raise LinearError(f"estimate {n} is not on team {self.team()['key']}'s {self.team()['issueEstimationType']} scale: {allowed}")
        return n


def emit(obj, as_json, text_fn):
    """Print JSON for an agent that asked for it, or readable text."""
    if as_json:
        print(json.dumps(obj, indent=1, default=str))
    else:
        text_fn(obj)


def short_date(s):
    return (s or "")[:10]


def table(rows, headers):
    """A plain aligned text table."""
    if not rows:
        print("(none)")
        return
    rows = [[("" if v is None else str(v)) for v in r] for r in rows]
    widths = [min(60, max(len(h), *(len(r[i]) for r in rows))) for i, h in enumerate(headers)]
    print("  ".join(h.ljust(w) for h, w in zip(headers, widths)))
    for r in rows:
        print("  ".join((v if len(v) <= w else v[: w - 1] + "…").ljust(w) for v, w in zip(r, widths)))


def fail(msg):
    print(f"linear: {msg}", file=sys.stderr)
    sys.exit(1)

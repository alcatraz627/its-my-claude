"""The shared document style, with colour roles resolved to hex.

Both document skills (/gdoc and /word-doc) read doc-style.json through this module,
so a colour written as a tone of the look's family ("@light1") or of the gray row
("@gray.dark4") means the same hex in a Google Doc and in a .docx. Switching the
look's "family" re-colours every role at the same relative shade.
"""
import json
import pathlib

SPEC_PATH = pathlib.Path(__file__).with_name("doc-style.json")


def load_raw():
    return json.loads(SPEC_PATH.read_text(encoding="utf-8"))


def resolver(raw, family):
    pal = raw["google_palette"]
    tones = dict(zip(pal["tones"], pal["families"][family]))
    gray = pal["gray"]

    def resolve(value):
        if isinstance(value, str) and value.startswith("@"):
            ref = value[1:]
            if ref.startswith("gray."):
                return gray[ref[5:]]
            return tones[ref]
        if isinstance(value, dict):
            return {k: resolve(v) for k, v in value.items()}
        if isinstance(value, list):
            return [resolve(v) for v in value]
        return value
    return resolve


def load_look(name="gdoc", family=None):
    """One look section with every colour role resolved, plus the shared callouts."""
    raw = load_raw()
    section = dict(raw[name])
    fam = family or section.get("family", "blue")
    section["family"] = fam
    look = resolver(raw, fam)(section)
    look["callouts"] = raw["callouts"]
    return look


if __name__ == "__main__":
    import sys
    look = load_look(*sys.argv[1:2])
    print(json.dumps({k: look[k] for k in ("family", "palette", "table", "callout", "quote")}, indent=1, ensure_ascii=False))

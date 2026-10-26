// Holds the shared composer and parser to what the old decision page produced.
//   bun test ~/.claude/scripts/decision-page/dp-core.test.ts

import { test, expect } from "bun:test";
import * as fs from "node:fs";
import * as path from "node:path";
import { compose, parse, freshState, DP_ROOT } from "./dp-core.ts";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const synth = JSON.parse(fs.readFileSync(path.join(HERE, "golden", "golden.json"), "utf8")).synthetic;
const realFile = path.join(DP_ROOT, ".golden-real.json");
const real = fs.existsSync(realFile) ? JSON.parse(fs.readFileSync(realFile, "utf8")).real : [];

for (const c of synth) {
  test(`compose: synthetic ${c.name}`, () => {
    expect(compose(c.config, c.state)).toBe(c.expected);
  });
  test(`parse round trip: synthetic ${c.name}`, () => {
    expect(compose(c.config, parse(c.expected, c.config))).toBe(c.expected);
  });
}

test("real answered pages are present (skip-proof)", () => {
  expect(real.length).toBeGreaterThan(0);
});

for (const r of real) {
  if (r.kind === "compose") {
    test(`compose: real ${r.slug}`, () => {
      expect(compose(r.config, r.state)).toBe(r.expected);
    });
    test(`parse round trip: real ${r.slug}`, () => {
      expect(compose(r.config, parse(r.expected, r.config))).toBe(r.expected);
    });
  } else {
    test(`parse accepts a headerless answer: ${r.slug}`, () => {
      const st = parse(r.expected, r.config);
      const codes = (r.config.decisions || []).map((d: any) => d.id + st.d[d.id]).join(" ");
      expect(codes).toBe(r.expected.trim().split("\n")[0]);
    });
  }
}

test("a pick the config does not offer falls back to the recommendation", () => {
  const cfg = { title: "t", decisions: [{ id: "D1", options: [{ code: "a", rec: true }, { code: "b" }] }] };
  expect(compose(cfg, { d: { D1: "q" } } as any)).toBe("t:\nD1a\nall items: agree as drafted");
});

test("fresh state picks every recommendation and keeps seeds", () => {
  const cfg = { decisions: [{ id: "D1", note: "seed", options: [{ code: "b", rec: true }] }], sections: [{ id: "S1" }] };
  expect(freshState(cfg)).toEqual({ d: { D1: "b" }, dnotes: { D1: "seed" }, screens: { S1: { agree: true, note: "" } }, endnotes: "" });
});

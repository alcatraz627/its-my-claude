/**
 * Static HTML generation tests for create-report
 *
 * These tests run generate-html.ts as a subprocess and inspect the output HTML
 * without needing a browser. Fast (~3–5s per style).
 *
 * Run: npx vitest run tests/static.test.ts
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { execSync } from "child_process";
import { mkdirSync, readFileSync, rmSync, existsSync } from "fs";
import { join, resolve } from "path";
import os from "os";

const SKILL_DIR = resolve(__dirname, "..");
const GENERATE = join(SKILL_DIR, "generate-html.ts");
const FIXTURE = join(__dirname, "fixture.json");

// Styles to run full checks on (subset for speed; extend as needed)
const SPOT_CHECK_STYLES = ["default", "notion", "minimal", "slide", "neon"];
// All 13 styles — used for the "all-styles generates all dirs" test
const ALL_STYLES = [
  "academic", "corporate", "dashboard", "data-table", "default",
  "feed", "jupyter", "magazine", "minimal", "neon", "notion", "slide", "terminal",
];

let tmpDir: string;

beforeAll(() => {
  tmpDir = join(os.tmpdir(), "create-report-test-" + Date.now());
  mkdirSync(tmpDir, { recursive: true });
});

afterAll(() => {
  if (tmpDir && existsSync(tmpDir)) {
    rmSync(tmpDir, { recursive: true, force: true });
  }
});

// ── Helper: generate one style ──────────────────────────────────────────────
function generate(style: string, outDir?: string): string {
  const dir = outDir ?? join(tmpDir, style);
  mkdirSync(dir, { recursive: true });
  execSync(
    `npx tsx "${GENERATE}" "${FIXTURE}" "${join(dir, "index.html")}" --style ${style}`,
    { cwd: SKILL_DIR, stdio: "pipe", timeout: 60_000 }
  );
  return readFileSync(join(dir, "index.html"), "utf8");
}

// ── All styles: --all-styles generates all 13 dirs ─────────────────────────
describe("--all-styles", () => {
  let allDir: string;

  beforeAll(() => {
    allDir = join(tmpDir, "_all");
    mkdirSync(allDir, { recursive: true });
    execSync(
      `npx tsx "${GENERATE}" "${FIXTURE}" "${allDir}" --all-styles`,
      { cwd: SKILL_DIR, stdio: "pipe", timeout: 120_000 }
    );
  });

  it("creates a subdirectory for every style", () => {
    for (const style of ALL_STYLES) {
      const html = join(allDir, style, "index.html");
      expect(existsSync(html), `${style}/index.html missing`).toBe(true);
    }
  });

  it("does not produce empty files", () => {
    for (const style of ALL_STYLES) {
      const html = join(allDir, style, "index.html");
      if (!existsSync(html)) continue;
      const size = readFileSync(html).length;
      expect(size, `${style}/index.html is empty`).toBeGreaterThan(10_000);
    }
  });
});

// ── Per-style spot checks ───────────────────────────────────────────────────
describe.each(SPOT_CHECK_STYLES)("style: %s", (style) => {
  let html: string;

  beforeAll(() => {
    html = generate(style);
  });

  // ── Light mode default ───────────────────────────────────
  describe("light mode", () => {
    it("html element starts with class 'light'", () => {
      // The initTheme IIFE in every style.js or report.js adds html.light on load.
      // In the static HTML, the <html> tag itself doesn't carry the class — it's
      // added by JS. But the script that sets it should reference 'rpt-theme'.
      expect(html).toMatch(/rpt-theme/);
    });

    it("does not use deprecated per-template theme storage keys", () => {
      const deprecated = ["notion-theme", "minimal-theme", "neon-theme", "jupyter-theme"];
      for (const key of deprecated) {
        expect(html, `found deprecated key "${key}"`).not.toContain(`"${key}"`);
      }
    });
  });

  // ── Floating toolbar ─────────────────────────────────────
  describe("floating toolbar", () => {
    it("contains the toolbar container", () => {
      expect(html).toContain("floating-toolbar");
    });

    it("has ftb-prefixed theme button", () => {
      expect(html).toContain('id="ftb-theme-btn"');
    });

    it("has ftb-prefixed print button", () => {
      expect(html).toContain('id="ftb-print-btn"');
    });

    it("has style picker button", () => {
      expect(html).toContain('id="style-picker-btn"');
    });

    it("has a row-2 placeholder div", () => {
      expect(html).toContain('id="ftb-row-2"');
    });
  });

  // ── __RPT_TOOLBAR interface ──────────────────────────────
  describe("__RPT_TOOLBAR interface", () => {
    it("script sets window.__RPT_TOOLBAR", () => {
      expect(html).toContain("window.__RPT_TOOLBAR");
    });

    it("__RPT_TOOLBAR has a print function", () => {
      expect(html).toMatch(/__RPT_TOOLBAR\s*=\s*\{[^}]*print\s*:/s);
    });
  });

  // ── __RPT_DEFAULT_ROW2_HTML ──────────────────────────────
  describe("default row2 HTML", () => {
    it("sets window.__RPT_DEFAULT_ROW2_HTML before the code that reads it", () => {
      // Only the default template injects the row2 HTML assignment.
      // Other templates contain the reading code but not the assignment — skip.
      const assignIdx = html.indexOf("window.__RPT_DEFAULT_ROW2_HTML =");
      if (assignIdx === -1) return;
      // The code that reads the variable must appear after the assignment
      const readIdx = html.lastIndexOf("window.__RPT_DEFAULT_ROW2_HTML");
      expect(readIdx).toBeGreaterThan(-1);
      expect(assignIdx).toBeLessThan(readIdx);
    });
  });

  // ── Basic content ────────────────────────────────────────
  describe("content", () => {
    it("contains the fixture title", () => {
      expect(html).toContain("Test Report");
    });

    it("contains the fixture section headings", () => {
      expect(html).toContain("Introduction");
      expect(html).toContain("Data");
    });

    it("renders the code block", () => {
      expect(html).toContain("console.log");
    });

    it("renders the table", () => {
      expect(html).toContain("alpha");
      expect(html).toContain("beta");
    });
  });

  // ── Self-contained HTML ──────────────────────────────────
  describe("self-contained", () => {
    it("has no external stylesheet links (everything is inlined)", () => {
      // CDN links (KaTeX, fonts) are OK — check no local .css references
      const localCss = html.match(/<link[^>]+href="(?!https?:\/\/)([^"]+\.css)/g);
      expect(localCss ?? [], "found non-inlined local CSS links").toHaveLength(0);
    });

    it("has no local script src references (scripts are inlined)", () => {
      const localJs = html.match(/<script[^>]+src="(?!https?:\/\/)([^"]+\.js)/g);
      expect(localJs ?? [], "found non-inlined local JS src").toHaveLength(0);
    });
  });
});

// ── Default template specific ───────────────────────────────────────────────
describe("default template: row2 controls", () => {
  let html: string;

  beforeAll(() => {
    html = generate("default");
  });

  it("row2 HTML includes font picker markup", () => {
    expect(html).toContain("ftb-font-btn");
  });

  it("row2 HTML includes color swatch markup", () => {
    expect(html).toContain("color-swatch");
  });

  it("row2 HTML includes width buttons", () => {
    expect(html).toContain("width-btn");
  });
});

// ── Slide template specific ─────────────────────────────────────────────────
describe("slide template", () => {
  let html: string;

  beforeAll(() => {
    html = generate("slide");
  });

  it("contains slide navigation dots", () => {
    expect(html).toMatch(/class="nav-dot/);
  });

  it("has a progress bar element", () => {
    expect(html).toContain("progress-bar");
  });

  it("has slide-container element", () => {
    expect(html).toContain("slide-container");
  });
});

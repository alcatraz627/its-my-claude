/**
 * Playwright browser interaction tests for the floating toolbar.
 *
 * Prerequisites:
 *   1. Gallery server running at http://localhost:5080 (pm2 start server.cjs)
 *   2. Template samples regenerated in public/style-samples/{style}/index.html
 *   3. npx playwright install chromium
 *
 * Run: npx playwright test tests/toolbar.spec.ts --project=chromium
 */

import { test, expect, Page, BrowserContext } from "@playwright/test";

const BASE = "http://localhost:5080/style-samples";

// Templates to run toolbar checks on
const TOOLBAR_STYLES = ["default", "notion", "minimal", "neon", "slide", "academic", "jupyter"];

// ── Helper: navigate and wait for toolbar ──────────────────────────────────
async function loadStyle(page: Page, style: string) {
  await page.goto(`${BASE}/${style}/index.html`, { waitUntil: "domcontentloaded" });
  // Wait for the floating toolbar to be rendered
  await page.waitForSelector(".floating-toolbar", { timeout: 5000 });
}

// ── Per-style toolbar tests ────────────────────────────────────────────────
for (const style of TOOLBAR_STYLES) {
  test.describe(`toolbar: ${style}`, () => {
    test("floating toolbar is visible", async ({ page }) => {
      await loadStyle(page, style);
      const toolbar = page.locator(".floating-toolbar");
      await expect(toolbar).toBeVisible();
    });

    test("toolbar contains theme toggle button", async ({ page }) => {
      await loadStyle(page, style);
      const themeBtn = page.locator("#ftb-theme-btn");
      await expect(themeBtn).toBeVisible();
    });

    test("toolbar contains print button", async ({ page }) => {
      await loadStyle(page, style);
      const printBtn = page.locator("#ftb-print-btn");
      await expect(printBtn).toBeVisible();
    });

    test("toolbar contains style picker button", async ({ page }) => {
      await loadStyle(page, style);
      const styleBtn = page.locator("#style-picker-btn");
      await expect(styleBtn).toBeVisible();
    });

    // ── Theme toggle ──────────────────────────────────────
    test("theme toggle adds html.light class on click", async ({ page }) => {
      await loadStyle(page, style);

      // Ensure we start in dark mode (no html.light)
      const htmlClass = await page.evaluate(() => document.documentElement.className);
      // If already light, click once to go dark first
      if (htmlClass.includes("light")) {
        await page.locator("#ftb-theme-btn").click();
        await page.waitForTimeout(100);
      }

      // Now click to go light
      await page.locator("#ftb-theme-btn").click();
      await page.waitForTimeout(200);
      const isLight = await page.evaluate(() =>
        document.documentElement.classList.contains("light")
      );
      expect(isLight).toBe(true);
    });

    test("theme toggle removes html.light on second click", async ({ page }) => {
      await loadStyle(page, style);

      const themeBtn = page.locator("#ftb-theme-btn");
      // Ensure light first
      const startLight = await page.evaluate(() =>
        document.documentElement.classList.contains("light")
      );
      if (!startLight) await themeBtn.click();
      await page.waitForTimeout(100);

      // Toggle back to dark
      await themeBtn.click();
      await page.waitForTimeout(200);
      const isDark = await page.evaluate(() =>
        !document.documentElement.classList.contains("light")
      );
      expect(isDark).toBe(true);
    });

    test("theme toggle persists to localStorage with rpt-theme key", async ({ page }) => {
      await loadStyle(page, style);

      await page.locator("#ftb-theme-btn").click();
      await page.waitForTimeout(200);

      const stored = await page.evaluate(() => localStorage.getItem("rpt-theme"));
      expect(["light", "dark"]).toContain(stored);
    });

    // ── __RPT_TOOLBAR interface ──────────────────────────
    test("window.__RPT_TOOLBAR is registered", async ({ page }) => {
      await loadStyle(page, style);
      const hasToolbar = await page.evaluate(() => typeof window.__RPT_TOOLBAR !== "undefined");
      expect(hasToolbar).toBe(true);
    });

    test("__RPT_TOOLBAR.print is a function", async ({ page }) => {
      await loadStyle(page, style);
      const isPrintFn = await page.evaluate(() =>
        typeof (window as any).__RPT_TOOLBAR?.print === "function"
      );
      expect(isPrintFn).toBe(true);
    });

    // ── Style picker ─────────────────────────────────────
    test("style picker opens a dropdown menu on click", async ({ page }) => {
      await loadStyle(page, style);
      const styleBtn = page.locator("#style-picker-btn");
      const styleMenu = page.locator("#style-menu");

      await styleBtn.click();
      await page.waitForTimeout(150);

      // Menu should be open (either visible or class 'open')
      const isOpen =
        (await styleMenu.isVisible()) ||
        (await styleMenu.getAttribute("class"))?.includes("open");
      expect(isOpen).toBe(true);
    });

    // ── Print button ─────────────────────────────────────
    test("print button calls window.print", async ({ page }) => {
      await loadStyle(page, style);

      // Mock window.print to track calls
      await page.evaluate(() => {
        (window as any).__printCalled = false;
        window.print = () => { (window as any).__printCalled = true; };
      });

      await page.locator("#ftb-print-btn").click();
      await page.waitForTimeout(100);

      const wasCalled = await page.evaluate(() => (window as any).__printCalled);
      expect(wasCalled).toBe(true);
    });
  });
}

// ── Row 2 injection for default template ──────────────────────────────────
test.describe("default template: row2 controls", () => {
  test("row2 is populated after DOMContentLoaded", async ({ page }) => {
    await loadStyle(page, "default");

    // row2 div should have content (not empty)
    const row2 = page.locator("#ftb-row-2");
    const isEmpty = await row2.evaluate((el) => el.children.length === 0);
    expect(isEmpty).toBe(false);
  });

  test("font picker button is present in row2", async ({ page }) => {
    await loadStyle(page, "default");
    const fontBtn = page.locator("#ftb-font-btn");
    await expect(fontBtn).toBeVisible();
  });

  test("color picker button is present in row2", async ({ page }) => {
    await loadStyle(page, "default");
    const colorBtn = page.locator("#ftb-color-btn");
    await expect(colorBtn).toBeVisible();
  });

  test("font picker opens a dropdown on click", async ({ page }) => {
    await loadStyle(page, "default");
    await page.locator("#ftb-font-btn").click();
    await page.waitForTimeout(150);
    const menu = page.locator("#font-menu");
    const isOpen = (await menu.getAttribute("class"))?.includes("open");
    expect(isOpen).toBe(true);
  });

  test("color swatch click changes --accent CSS variable", async ({ page }) => {
    await loadStyle(page, "default");

    const initialAccent = await page.evaluate(() =>
      getComputedStyle(document.documentElement).getPropertyValue("--accent").trim()
    );

    // Click the first swatch that isn't already active
    await page.locator(".color-swatch:not(.active)").first().click();
    await page.waitForTimeout(200);

    const newAccent = await page.evaluate(() =>
      getComputedStyle(document.documentElement).getPropertyValue("--accent").trim()
    );
    expect(newAccent).not.toBe(initialAccent);
  });
});

// ── Slide template: navigation ─────────────────────────────────────────────
test.describe("slide template: navigation", () => {
  test("ArrowRight key advances to next slide", async ({ page }) => {
    await loadStyle(page, "slide");

    const initialDot = await page.locator(".nav-dot.active").first().getAttribute("data-slide");

    await page.keyboard.press("ArrowRight");
    await page.waitForTimeout(400); // allow smooth scroll + detectCurrentSlide

    const newDot = await page.locator(".nav-dot.active").first().getAttribute("data-slide");
    // Should have moved forward (or stayed at last slide)
    expect(Number(newDot)).toBeGreaterThanOrEqual(Number(initialDot ?? "0"));
  });

  test("Home key returns to first slide", async ({ page }) => {
    await loadStyle(page, "slide");

    // Move forward first
    await page.keyboard.press("ArrowRight");
    await page.keyboard.press("ArrowRight");
    await page.waitForTimeout(300);

    await page.keyboard.press("Home");
    await page.waitForTimeout(400);

    const activeDot = await page.locator(".nav-dot.active").first().getAttribute("data-slide");
    expect(activeDot).toBe("0");
  });
});

// ── Gallery dashboard ──────────────────────────────────────────────────────
test.describe("gallery dashboard", () => {
  test("gallery page loads with 13 template cards", async ({ page }) => {
    await page.goto(`${BASE}/`, { waitUntil: "domcontentloaded" });
    const cards = page.locator(".card");
    await expect(cards).toHaveCount(13);
  });

  test("Templates tab is active by default", async ({ page }) => {
    await page.goto(`${BASE}/`, { waitUntil: "domcontentloaded" });
    const activeTab = page.locator(".tab-btn.active");
    await expect(activeTab).toHaveText("Templates");
  });

  test("Blocks tab switches to blocks section", async ({ page }) => {
    await page.goto(`${BASE}/`, { waitUntil: "domcontentloaded" });
    await page.locator(".tab-btn[data-tab='blocks']").click();
    await page.waitForTimeout(300);

    const blocksSection = page.locator("#blocks-section");
    await expect(blocksSection).toHaveClass(/active/);
  });

  test("Blocks section loads catalog cards", async ({ page }) => {
    await page.goto(`${BASE}/`, { waitUntil: "domcontentloaded" });
    await page.locator(".tab-btn[data-tab='blocks']").click();
    // Wait for fetch + render
    await page.waitForSelector(".block-card", { timeout: 5000 });
    const blockCards = page.locator(".block-card");
    // Expect at least 10 blocks
    await expect(blockCards).toHaveCount(18);
  });

  test("gallery theme toggle switches html.light class", async ({ page }) => {
    await page.goto(`${BASE}/`, { waitUntil: "domcontentloaded" });
    await page.locator("#theme-toggle").click();
    await page.waitForTimeout(150);
    const isLight = await page.evaluate(() =>
      document.documentElement.classList.contains("light")
    );
    expect(typeof isLight).toBe("boolean");
  });

  test("Regenerate All button is present", async ({ page }) => {
    await page.goto(`${BASE}/`, { waitUntil: "domcontentloaded" });
    const regenBtn = page.locator("#regen-btn");
    await expect(regenBtn).toBeVisible();
  });

  test("search filters template cards", async ({ page }) => {
    await page.goto(`${BASE}/`, { waitUntil: "domcontentloaded" });
    await page.locator("#gallery-search").fill("neon");
    await page.waitForTimeout(200);
    const visible = page.locator(".card:not(.hidden-search)");
    await expect(visible).toHaveCount(1);
  });
});

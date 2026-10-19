(function () {
  "use strict";
  var D = JSON.parse(document.getElementById("uf-data").textContent);
  var NAMES = D.names;
  var ROWS = D.rows;
  var APP = document.getElementById("app");

  // Row layout: 0 time, 1..8 dimension ids, 9 in, 10 out, 11 cache read, 12 cache write, 13 requests, 14 cost
  var DIMS = [
    { k: "plat", i: 2, label: "Platform" },
    { k: "model", i: 1, label: "Model" },
    { k: "kind", i: 3, label: "Main / subagent" },
    { k: "agent", i: 4, label: "Agent type" },
    { k: "skill", i: 5, label: "Skill" },
    { k: "proj", i: 6, label: "Project" },
    { k: "sess", i: 7, label: "Session" },
    { k: "eff", i: 8, label: "Effort" }
  ];
  var DIM = {};
  DIMS.forEach(function (d) { DIM[d.k] = d; });

  var METRICS = {
    cost: { label: "API-equivalent $", f: function (r) { return r[14]; } },
    out: { label: "Output tokens", f: function (r) { return r[10]; } },
    all: { label: "All tokens", f: function (r) { return r[9] + r[10] + r[11] + r[12]; } },
    n: { label: "Requests", f: function (r) { return r[13]; } }
  };
  var RANGES = [["today", "Today"], ["yday", "Yesterday"], ["24h", "Last 24h"], ["7d", "7 days"], ["14d", "14 days"]];
  var BINS = [["auto", "Auto"], ["5m", "5m"], ["15m", "15m"], ["1h", "1h"], ["6h", "6h"], ["1d", "1d"]];
  var BIN_SEC = { "5m": 300, "15m": 900, "1h": 3600, "6h": 21600, "1d": 86400 };
  var PLAT_LABEL = {
    cli: "Claude Code CLI", "sdk-cli": "Claude Code headless", "sdk-py": "Agent SDK (Python)",
    "sdk-ts": "Agent SDK (TS)", "claude-vscode": "VS Code extension", "claude-desktop": "Desktop app",
    "claude-jetbrains": "JetBrains plugin", unknown: "Unknown"
  };

  var state = { range: "today", bin: "auto", metric: "cost", stack: "model", hier: ["plat", "model", "kind", "agent"], off: {}, more: {}, zoom: [], view: null };
  try {
    var saved = JSON.parse(decodeURIComponent(location.hash.slice(1)));
    if (saved && typeof saved === "object") {
      ["range", "bin", "metric", "stack", "hier", "off", "view"].forEach(function (k) { if (saved[k] !== undefined) state[k] = saved[k]; });
    }
  } catch (e) { /* no saved view */ }
  if (!METRICS[state.metric]) state.metric = "cost";
  if (!DIM[state.stack]) state.stack = "model";

  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]; });
  }
  function label(dim, id) {
    var raw = NAMES[dim][id];
    if (raw === "-") return "(none)";
    if (dim === "plat") return PLAT_LABEL[raw] || raw;
    if (dim === "model") return raw.replace(/^claude-/, "").replace(/-\d{8}$/, "");
    return raw;
  }
  function fmtTok(n) {
    if (n >= 1e9) return (n / 1e9).toFixed(2) + "B";
    if (n >= 1e6) return (n / 1e6).toFixed(1) + "M";
    if (n >= 1e3) return (n / 1e3).toFixed(1) + "K";
    return String(Math.round(n));
  }
  function fmt(v) {
    if (state.metric === "cost") return "$" + (v >= 100 ? v.toFixed(0) : v >= 1 ? v.toFixed(2) : v.toFixed(3));
    if (state.metric === "n") return Math.round(v).toLocaleString();
    return fmtTok(v);
  }
  function pad(n) { return (n < 10 ? "0" : "") + n; }

  function bounds() {
    if (state.view) return state.view.slice();
    var now = new Date();
    var sod = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() / 1000;
    var t = Date.now() / 1000;
    switch (state.range) {
      case "yday": return [sod - 86400, sod];
      case "24h": return [t - 86400, t];
      case "7d": return [sod - 6 * 86400, sod + 86400];
      case "14d": return [sod - 13 * 86400, sod + 86400];
      default: return [sod, sod + 86400];
    }
  }
  // Bars stay roughly 40-220 wide at any zoom; an explicit bin that would exceed 600 bars falls back to auto.
  function autoBin(span) { return span <= 6 * 3600 ? 300 : span <= 30 * 3600 ? 900 : span <= 9 * 86400 ? 3600 : 10800; }
  function binSeconds(b) {
    var span = b[1] - b[0], bin = state.bin === "auto" ? autoBin(span) : BIN_SEC[state.bin];
    return span / bin > 600 ? autoBin(span) : bin;
  }

  var DATA_MIN = ROWS.length ? ROWS[0][0] : Date.now() / 1000 - 86400;
  function clampView(v) {
    var span = Math.min(Math.max(v[1] - v[0], 600), 30 * 86400);
    var lo = DATA_MIN - span / 4, hi = Date.now() / 1000 + 86400;
    var a = Math.min(Math.max(v[0], lo), hi - span);
    return [a, a + span];
  }
  function zoomBy(factor) {
    var b = bounds(), c = (b[0] + b[1]) / 2, half = ((b[1] - b[0]) * factor) / 2;
    state.view = clampView([c - half, c + half]);
  }
  function panBy(frac) {
    var b = bounds(), s = (b[1] - b[0]) * frac;
    state.view = clampView([b[0] + s, b[1] + s]);
  }

  // Colour follows the entity: slots are ranked once over all data, so filters never repaint survivors.
  var SLOT = {};
  DIMS.forEach(function (d) {
    var tot = {};
    ROWS.forEach(function (r) { tot[r[d.i]] = (tot[r[d.i]] || 0) + (r[14] || r[10]); });
    var order = Object.keys(tot).sort(function (a, b) { return tot[b] - tot[a]; });
    SLOT[d.k] = {};
    order.slice(0, 8).forEach(function (id, n) { SLOT[d.k][id] = n + 1; });
  });
  function slotOf(dim, id) { return SLOT[dim][id] || 0; }

  function excluded(r) {
    for (var n = 0; n < DIMS.length; n++) {
      var off = state.off[DIMS[n].k];
      if (off && off.length && off.indexOf(NAMES[DIMS[n].k][r[DIMS[n].i]]) >= 0) return true;
    }
    return false;
  }
  function inRange(r, b) { return r[0] >= b[0] && r[0] < b[1]; }

  function niceMax(v) {
    if (v <= 0) return 1;
    var p = Math.pow(10, Math.floor(Math.log10(v)));
    var m = v / p;
    return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 5 ? 5 : 10) * p;
  }

  function seg(act, items, cur) {
    return '<span class="uf-seg">' + items.map(function (it) {
      return '<button type="button" data-act="' + act + '" data-v="' + it[0] + '" class="' + (it[0] === cur ? "on" : "") + '">' + esc(it[1]) + "</button>";
    }).join("") + "</span>";
  }
  function select(act, cur, items) {
    return '<select class="uf-select" data-act="' + act + '">' + items.map(function (it) {
      return '<option value="' + it[0] + '"' + (it[0] === cur ? " selected" : "") + ">" + esc(it[1]) + "</option>";
    }).join("") + "</select>";
  }

  function controlsHTML() {
    var dimOpts = DIMS.map(function (d) { return [d.k, d.label]; });
    var metricOpts = Object.keys(METRICS).map(function (k) { return [k, METRICS[k].label]; });
    return '<div class="uf-controls">' +
      '<div class="uf-group"><span class="uf-lbl">Range</span>' + seg("range", RANGES, state.view ? "" : state.range) + "</div>" +
      '<div class="uf-group"><span class="uf-lbl">Bin</span>' + seg("bin", BINS, state.bin) + "</div>" +
      '<div class="uf-group"><span class="uf-lbl">Measure</span>' + select("metric", state.metric, metricOpts) + "</div>" +
      '<div class="uf-group"><span class="uf-lbl">Stack by</span>' + select("stack", state.stack, dimOpts) + "</div>" +
      "</div>";
  }

  function tilesHTML(rows) {
    var cost = 0, out = 0, all = 0, n = 0, sess = {};
    rows.forEach(function (r) { cost += r[14]; out += r[10]; all += r[9] + r[10] + r[11] + r[12]; n += r[13]; sess[r[7]] = 1; });
    var tiles = [
      [cost ? "$" + cost.toFixed(2) : "n/a", "API-equivalent cost"], [fmtTok(out), "output tokens"],
      [fmtTok(all), "all tokens incl. cache"], [n.toLocaleString(), "requests"], [Object.keys(sess).length, "sessions"]
    ];
    return '<div class="uf-tiles">' + tiles.map(function (t) {
      return '<div class="uf-tile"><span>' + t[1] + "</span><b>" + t[0] + "</b></div>";
    }).join("") + "</div>";
  }

  function chartData(rows, b) {
    var bin = binSeconds(b);
    var nb = Math.max(1, Math.ceil((b[1] - b[0]) / bin));
    var si = DIM[state.stack].i, f = METRICS[state.metric].f;
    var series = {}, bins = [];
    for (var i = 0; i < nb; i++) bins.push({});
    rows.forEach(function (r) {
      var bi = Math.floor((r[0] - b[0]) / bin);
      if (bi < 0 || bi >= nb) return;
      var slot = slotOf(state.stack, r[si]);
      var key = slot ? String(r[si]) : "other";
      var v = f(r);
      bins[bi][key] = (bins[bi][key] || 0) + v;
      series[key] = (series[key] || 0) + v;
    });
    var keys = Object.keys(series).sort(function (a, c) {
      var sa = a === "other" ? 99 : slotOf(state.stack, a), sc = c === "other" ? 99 : slotOf(state.stack, c);
      return sa - sc;
    });
    return { bin: bin, nb: nb, bins: bins, series: series, keys: keys };
  }
  function keyLabel(key) { return key === "other" ? "Other" : label(state.stack, key); }
  function keyClass(key) { return "c" + (key === "other" ? 0 : slotOf(state.stack, key)); }

  function chartHTML(cd, b) {
    var W = Math.max(320, (APP.clientWidth || 900) - 34), H = 270;
    var m = { l: 54, r: 8, t: 10, b: 26 }, pw = W - m.l - m.r, ph = H - m.t - m.b;
    var max = 0;
    cd.bins.forEach(function (bn) {
      var t = 0;
      for (var k in bn) t += bn[k];
      if (t > max) max = t;
    });
    var top = niceMax(max), bw = pw / cd.nb, barW = Math.max(1, bw - (bw > 6 ? 2 : 0.5));
    var s = '<svg viewBox="0 0 ' + W + " " + H + '" role="img" aria-label="Usage over time, stacked by ' + esc(DIM[state.stack].label) + '">';
    for (var g = 0; g <= 4; g++) {
      var y = m.t + ph - (ph * g) / 4;
      s += '<line class="uf-grid" x1="' + m.l + '" x2="' + (W - m.r) + '" y1="' + y + '" y2="' + y + '"/>';
      var tick = (top * g) / 4;
      var tickTxt = state.metric === "cost" ? "$" + (Number.isInteger(tick) ? tick : tick.toFixed(1)) : fmt(tick);
      s += '<text class="uf-axis" x="' + (m.l - 6) + '" y="' + (y + 4) + '" text-anchor="end">' + tickTxt + "</text>";
    }
    cd.bins.forEach(function (bn, i) {
      var acc = 0;
      cd.keys.forEach(function (k) {
        var v = bn[k];
        if (!v) return;
        var h = (v / top) * ph;
        var y0 = m.t + ph - ((acc + v) / top) * ph;
        s += '<rect class="uf-seg-r ' + keyClass(k) + '" x="' + (m.l + i * bw + (bw - barW) / 2).toFixed(2) + '" y="' + y0.toFixed(2) + '" width="' + barW.toFixed(2) + '" height="' + Math.max(0.5, h).toFixed(2) + '"/>';
        acc += v;
      });
    });
    var span = b[1] - b[0];
    var steps = [600, 1800, 3600, 3 * 3600, 6 * 3600, 86400, 2 * 86400], step = steps[steps.length - 1];
    for (var si = 0; si < steps.length; si++) {
      if (span / steps[si] <= 9) { step = steps[si]; break; }
    }
    var tzOff = -new Date(b[0] * 1000).getTimezoneOffset() * 60;
    var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    for (var t = Math.ceil((b[0] + tzOff) / step) * step - tzOff; t < b[1]; t += step) {
      var d = new Date(t * 1000), x = m.l + ((t - b[0]) / span) * pw;
      var midnight = d.getHours() === 0 && d.getMinutes() === 0;
      var txt = step >= 86400 || midnight ? days[d.getDay()] + " " + d.getDate() : pad(d.getHours()) + ":" + pad(d.getMinutes());
      s += '<text class="uf-axis" x="' + x.toFixed(1) + '" y="' + (H - 8) + '" text-anchor="middle">' + txt + "</text>";
    }
    s += '<rect class="uf-hover" id="uf-hl" x="0" y="' + m.t + '" width="0" height="' + ph + '"/>';
    s += '<rect class="uf-brush" id="uf-brush" x="0" y="' + m.t + '" width="0" height="' + ph + '"/>';
    s += '<rect id="uf-cap" x="' + m.l + '" y="' + m.t + '" width="' + pw + '" height="' + ph + '" fill="transparent" data-l="' + m.l + '" data-w="' + pw + '" data-bw="' + bw + '" data-vbw="' + W + '"/>';
    return s + "</svg>";
  }

  function legendHTML(cd) {
    return '<div class="uf-legend">' + cd.keys.map(function (k) {
      return '<span class="uf-key ' + keyClass(k) + '"><i></i>' + esc(keyLabel(k)) + " <em>" + fmt(cd.series[k]) + "</em></span>";
    }).join("") + "</div>";
  }

  function buildTree(rows, levels) {
    var f = METRICS[state.metric].f;
    var root = { name: "All", value: 0, kids: {}, order: [] };
    rows.forEach(function (r) {
      var v = f(r);
      if (!v) return;
      root.value += v;
      var node = root;
      for (var n = 0; n < levels.length; n++) {
        var dim = levels[n], id = r[DIM[dim].i], key = dim + ":" + id;
        var kid = node.kids[key];
        if (!kid) { kid = node.kids[key] = { name: label(dim, id), dim: dim, id: id, value: 0, kids: {}, key: key }; }
        kid.value += v;
        node = kid;
      }
    });
    return root;
  }

  function flameHTML(rows) {
    var levels = state.hier.filter(function (k) { return DIM[k]; });
    var root = buildTree(rows, levels);
    var node = root, path = [root];
    state.zoom.forEach(function (key) {
      if (node.kids[key]) { node = node.kids[key]; path.push(node); }
    });
    var crumbs = path.map(function (p, i) {
      return i === path.length - 1 ? "<span>" + esc(p.name) + "</span>" : '<button type="button" class="uf-btn" data-act="zoom" data-v="' + i + '">' + esc(p.name) + "</button>";
    }).join(" › ");
    var parts = [], depth = 0;
    // Each block sits under its parent and inherits the colour of its first-level ancestor.
    (function place(n, left, width, level, rootSlot) {
      var kids = Object.keys(n.kids).map(function (k) { return n.kids[k]; }).sort(function (a, c) { return c.value - a.value; });
      var x = left;
      kids.forEach(function (kid) {
        var w = (kid.value / n.value) * width;
        if (w < 0.15) { x += w; return; }
        var slot = rootSlot === null ? slotOf(kid.dim, kid.id) : rootSlot;
        parts.push({ n: kid, left: x, w: w, level: level, slot: slot });
        if (level + 1 > depth) depth = level + 1;
        place(kid, x, w, level + 1, slot);
        x += w;
      });
    })(node, 0, 100, 0, state.zoom.length ? slotOfNodePath(path) : null);
    var html = '<div class="uf-crumbs">' + crumbs + "</div>";
    html += '<div class="uf-flame" id="uf-flame" style="height:' + Math.max(1, depth) * 24 + 'px">';
    parts.forEach(function (p, i) {
      html += '<div class="uf-n c' + p.slot + '" data-l="' + Math.min(p.level, 3) + '" data-i="' + i + '" data-key="' + esc(p.n.key) + '" style="left:' + p.left.toFixed(3) + "%;width:" + p.w.toFixed(3) + "%;top:" + p.level * 24 + 'px">' + esc(p.n.name) + "</div>";
    });
    html += "</div>";
    flameHTML.parts = parts;
    flameHTML.root = node;
    flameHTML.total = root.value;
    return html;
  }
  function slotOfNodePath(path) {
    var first = path[1];
    return first ? slotOf(first.dim, first.id) : null;
  }

  function filtersHTML(rangeRows) {
    var f = METRICS[state.metric].f, html = "";
    DIMS.forEach(function (d) {
      var tot = {}, sum = 0;
      rangeRows.forEach(function (r) { var v = f(r); tot[r[d.i]] = (tot[r[d.i]] || 0) + v; sum += v; });
      var ids = Object.keys(tot).sort(function (a, c) { return tot[c] - tot[a]; });
      var off = state.off[d.k] || [];
      NAMES[d.k].forEach(function (nm, id) { if (off.indexOf(nm) >= 0 && !(id in tot)) { tot[id] = 0; ids.push(String(id)); } });
      var shown = state.more[d.k] ? ids : ids.slice(0, 10);
      html += '<div class="uf-filter"><span>' + d.label + '<br><button type="button" class="uf-btn" data-act="all" data-d="' + d.k + '">all</button> <button type="button" class="uf-btn" data-act="none" data-d="' + d.k + '">none</button></span><div class="uf-chips">';
      shown.forEach(function (id) {
        var nm = NAMES[d.k][id], isOff = off.indexOf(nm) >= 0;
        var pct = sum ? Math.round((tot[id] / sum) * 100) : 0;
        html += '<button type="button" class="uf-chip' + (isOff ? " off" : "") + '" data-act="chip" data-d="' + d.k + '" data-v="' + esc(nm) + '" aria-pressed="' + !isOff + '">' + esc(label(d.k, id)) + "<em>" + pct + "%</em></button>";
      });
      if (ids.length > 10) html += '<button type="button" class="uf-btn" data-act="more" data-d="' + d.k + '">' + (state.more[d.k] ? "fewer" : "+" + (ids.length - 10) + " more") + "</button>";
      html += "</div></div>";
    });
    return html;
  }

  function tableHTML(cd) {
    var rows = cd.keys.map(function (k) { return "<tr><td>" + esc(keyLabel(k)) + "</td><td>" + fmt(cd.series[k]) + "</td></tr>"; }).join("");
    return '<details class="uf-table"><summary>Table view</summary><table><thead><tr><th>' + esc(DIM[state.stack].label) + "</th><th>" + esc(METRICS[state.metric].label) + "</th></tr></thead><tbody>" + rows + "</tbody></table></details>";
  }

  function hierHTML() {
    var opts = DIMS.map(function (d) { return [d.k, d.label]; }).concat([["none", "(none)"]]);
    var out = "";
    for (var n = 0; n < 4; n++) out += select("hier" + n, state.hier[n] || "none", opts) + " ";
    return '<div class="uf-group"><span class="uf-lbl">Levels</span>' + out + "</div>";
  }

  function zoomBarHTML() {
    function btn(act, v, text, title) {
      return '<button type="button" data-act="' + act + '"' + (v === undefined ? "" : ' data-v="' + v + '"') + ' title="' + title + '">' + text + "</button>";
    }
    var last = [1, 3, 6, 12].map(function (h) { return btn("zlast", h, h + "h", "Last " + h + " hours"); }).join("");
    return '<div class="uf-zoom"><span class="uf-lbl">Zoom</span>' +
      '<span class="uf-seg">' + btn("zout", undefined, "−", "Zoom out 2×") + btn("zin", undefined, "+", "Zoom in 2×") +
      btn("panl", undefined, "◀", "Pan back half a window") + btn("panr", undefined, "▶", "Pan forward half a window") + "</span>" +
      '<span class="uf-seg">' + last + "</span>" +
      (state.view ? '<button type="button" class="uf-btn" data-act="zreset">Reset zoom</button>' : "") +
      '<span class="uf-hint">Drag the chart to zoom to a window, Shift+drag to pan</span></div>';
  }

  function dayText(d, withYear) {
    return d.toLocaleDateString(undefined, { weekday: "short", day: "numeric", month: "short", year: withYear ? "numeric" : undefined });
  }
  function timeText(d) { return d.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit", hour12: false }); }
  function windowText(b) {
    var d0 = new Date(b[0] * 1000), d1 = new Date((b[1] - 1) * 1000), end = new Date(b[1] * 1000), span = b[1] - b[0];
    if (d0.toDateString() === d1.toDateString()) {
      return dayText(d0, true) + (span < 86000 ? ", " + timeText(d0) + " – " + timeText(end) : "");
    }
    if (span <= 36 * 3600) return dayText(d0, false) + " " + timeText(d0) + " – " + dayText(d1, true) + " " + timeText(end);
    return dayText(d0, false) + " – " + dayText(d1, true);
  }
  // Navbar brand: icon at the left, the title with the build time under it.
  function buildBrand() {
    var title = document.querySelector(".kit-bar-inner .kit-title");
    if (!title) return;
    var brand = document.createElement("div");
    brand.className = "uf-brand";
    var ico = document.createElement("span");
    ico.className = "uf-brand-ico";
    ico.setAttribute("aria-hidden", "true");
    ico.innerHTML = D.icon || "";
    var text = document.createElement("div");
    text.className = "uf-brand-text";
    var sub = document.createElement("span");
    sub.className = "uf-sub";
    var built = new Date(D.built * 1000);
    sub.textContent = dayText(built, false) + ", " + timeText(built);
    sub.title = "Page built " + built.toLocaleString();
    title.parentNode.insertBefore(brand, title);
    text.appendChild(title);
    text.appendChild(sub);
    brand.appendChild(ico);
    brand.appendChild(text);
  }

  var CARD_ICON = {
    time: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 20v-7M10 20V5M15 20v-10M20 20v-5"/></svg>',
    flame: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5c.9 2.9 4 4.3 4 7.4a4 4 0 0 1-8 0c0-1.3.5-2.3 1.3-3.1.1 1 .7 1.7 1.5 1.9-.3-1.7.3-4.1 1.2-6.2"/></svg>',
    filter: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 5h16l-6 7.5V19l-4-2v-4.5z"/></svg>'
  };
  // One header pattern for every card: icon, title, and a muted line saying what the card shows.
  function cardHead(icon, title, subtitle) {
    return '<header class="uf-ch"><span class="uf-ch-ico">' + CARD_ICON[icon] + "</span><div><h2>" + esc(title) + "</h2><p>" + esc(subtitle) + "</p></div></header>";
  }

  function render() {
    var b = bounds();
    var rangeRows = ROWS.filter(function (r) { return inRange(r, b); });
    var rows = rangeRows.filter(function (r) { return !excluded(r); });
    var cd = chartData(rows, b);
    APP.innerHTML =
      '<div class="uf-toolbar">' + controlsHTML() + "</div>" + tilesHTML(rows) +
      '<section class="uf-card">' + cardHead("time", "Over time", windowText(b) + " · stacked by " + DIM[state.stack].label.toLowerCase() + " · " + METRICS[state.metric].label) +
      zoomBarHTML() + legendHTML(cd) + '<div class="uf-plot" id="uf-plot">' + chartHTML(cd, b) + '<div class="uf-tip" id="uf-tip" hidden></div></div>' + tableHTML(cd) + "</section>" +
      '<section class="uf-card">' + cardHead("flame", "Flame", "Width is the share of " + METRICS[state.metric].label.toLowerCase() + " · click a block to zoom") + hierHTML() + flameHTML(rows) + '<div class="uf-tip" id="uf-ftip" hidden></div></section>' +
      '<section class="uf-card">' + cardHead("filter", "Filters", "Click a chip to hide it, double-click to show only it") + filtersHTML(rangeRows) + "</section>";
    wire(cd, b);
    try { history.replaceState(null, "", "#" + encodeURIComponent(JSON.stringify({ range: state.range, bin: state.bin, metric: state.metric, stack: state.stack, hier: state.hier, off: state.off, view: state.view }))); } catch (e) { /* file:// may refuse */ }
  }

  function wire(cd, b) {
    var cap = document.getElementById("uf-cap"), tip = document.getElementById("uf-tip"), hl = document.getElementById("uf-hl");
    if (cap) {
      var svg = cap.ownerSVGElement;
      cap.addEventListener("mousemove", function (ev) {
        var rect = svg.getBoundingClientRect(), vb = svg.viewBox.baseVal;
        var scale = vb.width / rect.width;
        var x = (ev.clientX - rect.left) * scale - Number(cap.dataset.l);
        var bw = Number(cap.dataset.bw), i = Math.min(cd.nb - 1, Math.max(0, Math.floor(x / bw)));
        hl.setAttribute("x", Number(cap.dataset.l) + i * bw);
        hl.setAttribute("width", bw);
        var bn = cd.bins[i], total = 0, lines = "";
        cd.keys.slice().reverse().forEach(function (k) {
          if (!bn[k]) return;
          total += bn[k];
          lines += '<div class="' + keyClass(k) + '"><span><i></i>' + esc(keyLabel(k)) + "</span><span>" + fmt(bn[k]) + "</span></div>";
        });
        var t0 = new Date((b[0] + i * cd.bin) * 1000);
        var head = (cd.bin >= 86400 ? t0.toDateString() : t0.toDateString().slice(0, 10) + " " + pad(t0.getHours()) + ":" + pad(t0.getMinutes()));
        tip.innerHTML = "<b>" + head + "</b>" + (lines || "<div><span>no usage</span></div>") + (lines ? '<div class="tot"><span>Total</span><span>' + fmt(total) + "</span></div>" : "");
        tip.hidden = false;
        var pr = document.getElementById("uf-plot").getBoundingClientRect();
        var left = ev.clientX - pr.left + 14;
        if (left + 280 > pr.width) left = ev.clientX - pr.left - 290;
        tip.style.left = Math.max(0, left) + "px";
        tip.style.top = Math.max(0, ev.clientY - pr.top - 10) + "px";
      });
      cap.addEventListener("mouseleave", function () { tip.hidden = true; hl.setAttribute("width", 0); });
      // Drag selects a window to zoom into; Shift+drag pans the current window.
      cap.addEventListener("pointerdown", function (ev) {
        if (ev.button !== 0) return;
        ev.preventDefault();
        var rect = svg.getBoundingClientRect(), scale = svg.viewBox.baseVal.width / rect.width;
        var l = Number(cap.dataset.l), pw = Number(cap.dataset.w), span = b[1] - b[0];
        var start = b.slice(), pan = ev.shiftKey, raf = 0;
        function xAt(e) { return (e.clientX - rect.left) * scale - l; }
        function frac(x) { return Math.min(1, Math.max(0, x / pw)); }
        var x0 = xAt(ev);
        tip.hidden = true;
        function move(e) {
          var x = xAt(e);
          if (pan) {
            var dt = -((x - x0) / pw) * span;
            state.view = clampView([start[0] + dt, start[1] + dt]);
            if (!raf) raf = requestAnimationFrame(function () { raf = 0; render(); });
          } else {
            var br = document.getElementById("uf-brush");
            if (br) {
              br.setAttribute("x", l + Math.min(frac(x0), frac(x)) * pw);
              br.setAttribute("width", Math.abs(frac(x) - frac(x0)) * pw);
            }
          }
        }
        function up(e) {
          document.removeEventListener("pointermove", move);
          document.removeEventListener("pointerup", up);
          if (pan) return;
          var f0 = frac(x0), f1 = frac(xAt(e));
          if (Math.abs(f1 - f0) * pw < 6) {
            var br = document.getElementById("uf-brush");
            if (br) br.setAttribute("width", 0);
            return;
          }
          state.view = clampView([b[0] + Math.min(f0, f1) * span, b[0] + Math.max(f0, f1) * span]);
          render();
        }
        document.addEventListener("pointermove", move);
        document.addEventListener("pointerup", up);
      });
    }
    var fl = document.getElementById("uf-flame"), ft = document.getElementById("uf-ftip");
    if (fl) {
      fl.addEventListener("mousemove", function (ev) {
        var el = ev.target.closest(".uf-n");
        if (!el) { ft.hidden = true; return; }
        var p = flameHTML.parts[Number(el.dataset.i)];
        var pct = flameHTML.total ? ((p.n.value / flameHTML.total) * 100).toFixed(1) : "0";
        ft.innerHTML = "<b>" + esc(p.n.name) + "</b><div><span>" + esc(DIM[p.n.dim].label) + "</span><span>" + fmt(p.n.value) + "</span></div><div><span>Share of total</span><span>" + pct + "%</span></div>";
        ft.hidden = false;
        var sr = ft.parentElement.getBoundingClientRect();
        var left = ev.clientX - sr.left + 14;
        if (left + 280 > sr.width) left = ev.clientX - sr.left - 290;
        ft.style.left = Math.max(0, left) + "px";
        ft.style.top = (ev.clientY - sr.top + 14) + "px";
      });
      fl.addEventListener("mouseleave", function () { ft.hidden = true; });
    }
  }

  function setOff(dim, list) { state.off[dim] = list; if (!list.length) delete state.off[dim]; }

  APP.addEventListener("click", function (ev) {
    var el = ev.target.closest("[data-act]");
    if (!el) {
      return;
    }
    var act = el.dataset.act;
    if (act === "range") { state.range = el.dataset.v; state.view = null; }
    else if (act === "zin") { zoomBy(0.5); }
    else if (act === "zout") { zoomBy(2); }
    else if (act === "panl") { panBy(-0.5); }
    else if (act === "panr") { panBy(0.5); }
    else if (act === "zlast") { var t1 = Date.now() / 1000; state.view = [t1 - Number(el.dataset.v) * 3600, t1]; }
    else if (act === "zreset") { state.view = null; }
    else if (act === "bin") { state.bin = el.dataset.v; }
    else if (act === "chip") {
      var cur = (state.off[el.dataset.d] || []).slice(), at = cur.indexOf(el.dataset.v);
      if (at >= 0) cur.splice(at, 1); else cur.push(el.dataset.v);
      setOff(el.dataset.d, cur);
    }
    else if (act === "all") { setOff(el.dataset.d, []); }
    else if (act === "none") { setOff(el.dataset.d, NAMES[el.dataset.d].slice()); }
    else if (act === "more") { state.more[el.dataset.d] = !state.more[el.dataset.d]; }
    else if (act === "zoom") { state.zoom = state.zoom.slice(0, Number(el.dataset.v)); }
    else { return; }
    render();
  });
  APP.addEventListener("click", function (ev) {
    var n = ev.target.closest(".uf-n");
    if (!n) return;
    state.zoom.push(n.dataset.key);
    render();
  });
  APP.addEventListener("dblclick", function (ev) {
    var el = ev.target.closest('[data-act="chip"]');
    if (!el) return;
    var dim = el.dataset.d;
    setOff(dim, NAMES[dim].filter(function (nm) { return nm !== el.dataset.v; }));
    render();
  });
  APP.addEventListener("change", function (ev) {
    var el = ev.target.closest("select[data-act]");
    if (!el) return;
    var act = el.dataset.act;
    if (act === "metric") state.metric = el.value;
    else if (act === "stack") state.stack = el.value;
    else if (act.indexOf("hier") === 0) {
      var h = state.hier.slice(), idx = Number(act.slice(4));
      h[idx] = el.value;
      state.hier = h.filter(function (k, i) { return k !== "none" || i < idx; }).filter(function (k) { return k !== "none"; });
      state.zoom = [];
    }
    render();
  });

  // The kit hides the theme button's text (the icon replaces it); keep a hover hint in sync.
  function themeHints() {
    document.querySelectorAll("[data-kit-theme]").forEach(function (btn) { btn.title = btn.getAttribute("aria-label") || ""; });
  }
  document.addEventListener("click", function (ev) {
    if (ev.target.closest("[data-kit-theme]")) setTimeout(themeHints, 0);
  });

  var resizeTimer;
  window.addEventListener("resize", function () { clearTimeout(resizeTimer); resizeTimer = setTimeout(render, 150); });
  buildBrand();
  themeHints();
  render();
})();

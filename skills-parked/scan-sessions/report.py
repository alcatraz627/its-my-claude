"""
report.py — Generate a self-contained HTML report from scan-sessions aggregate data.

Produces a single HTML file with:
- Dark/light toggle
- Summary stats cards
- Signal breakdown charts (pure CSS bars)
- Frustration events table
- Self-correction breakdown
- Tool error categories
- Skill reliability rates
- Repeated reads heatmap
- Novel patterns highlight
"""

import json
import os
from datetime import datetime, timezone

REPORT_DIR = os.path.expanduser("~/.claude/assets/reports/scan-sessions")


def generate_report(results, output_path=None):
    """Generate an HTML report from aggregate results.

    Args:
        results: dict from aggregate()
        output_path: optional file path override

    Returns path to generated HTML file.
    """
    if not output_path:
        os.makedirs(REPORT_DIR, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        output_path = os.path.join(REPORT_DIR, f"scan-report-{ts}.html")

    s = results.get("summary", {})
    timing = results.get("timing", {})
    frustration = results.get("frustration", [])
    corrections = results.get("self_corrections", {})
    tools = results.get("tool_reliability", {})
    reads = results.get("repeated_reads", [])
    skills = results.get("skill_outcomes", {})
    novel = results.get("novel_patterns", [])
    render_ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Pre-compute chart data
    frust_by_severity = {"high": 0, "medium": 0, "low": 0}
    for f in frustration:
        sev = f.get("severity", "low")
        frust_by_severity[sev] = frust_by_severity.get(sev, 0) + 1

    correction_subtypes = corrections.get("by_subtype", {}) if isinstance(corrections, dict) else {}
    correction_events = corrections.get("events", []) if isinstance(corrections, dict) else []

    tool_categories = tools.get("by_category", {})
    tool_total = tools.get("total_errors", 0)

    # Signal breakdown for overview chart
    signal_counts = {
        "Frustration": len(frustration),
        "Self-Correction": len(correction_events),
        "Tool Errors": tool_total,
        "Repeated Reads": len(reads),
        "Skill Outcomes": sum(d.get("total", 0) for d in skills.values()) if isinstance(skills, dict) else 0,
    }
    max_signal = max(signal_counts.values()) if signal_counts.values() else 1

    # Build skill rows
    skill_rows = ""
    if isinstance(skills, dict):
        for name, data in list(skills.items())[:15]:
            total = data.get("total", 0)
            succ = data.get("success", 0) + data.get("confirmed_success", 0) + data.get("implicit_success", 0)
            err = data.get("error", 0)
            rej = data.get("rejected", 0)
            unk = data.get("unknown", 0)
            rec = data.get("error_recovered", 0)
            rate = data.get("success_rate", 0)

            # Stacked bar segments
            bar_succ = round((succ / total) * 100) if total else 0
            bar_rec = round((rec / total) * 100) if total else 0
            bar_err = round(((err + rej) / total) * 100) if total else 0
            bar_unk = 100 - bar_succ - bar_rec - bar_err

            skill_rows += f"""<tr>
              <td class="mono">{_esc(name)}</td>
              <td class="right">{total}</td>
              <td>
                <div class="stacked-bar">
                  <div class="bar-seg success" style="width:{bar_succ}%"></div>
                  <div class="bar-seg recovered" style="width:{bar_rec}%"></div>
                  <div class="bar-seg error" style="width:{bar_err}%"></div>
                  <div class="bar-seg unknown" style="width:{bar_unk}%"></div>
                </div>
              </td>
              <td class="right">{succ}</td>
              <td class="right">{rec}</td>
              <td class="right">{err + rej}</td>
              <td class="right">{unk}</td>
            </tr>"""

    # Frustration rows
    frust_rows = ""
    for f in frustration[:20]:
        sev = f.get("severity", "low")
        sev_class = f"sev-{sev}"
        text = _esc(f.get("text", "")[:80].replace("\n", " "))
        project = _esc(f.get("project", "")[:20])
        subtype = _esc(f.get("subtype", ""))
        frust_rows += f"""<tr>
          <td><span class="badge {sev_class}">{sev}</span></td>
          <td>{project}</td>
          <td class="mono">{subtype}</td>
          <td>{text}</td>
        </tr>"""

    # Tool error rows
    tool_rows = ""
    for cat, count in sorted(tool_categories.items(), key=lambda x: -x[1]):
        pct = round((count / tool_total) * 100) if tool_total else 0
        tool_rows += f"""<tr>
          <td class="mono">{_esc(cat)}</td>
          <td class="right">{count}</td>
          <td><div class="h-bar" style="width:{pct}%"></div></td>
        </tr>"""

    # Correction rows
    correction_rows = ""
    for sub, count in sorted(correction_subtypes.items(), key=lambda x: -x[1]):
        correction_rows += f"""<tr>
          <td class="mono">{_esc(sub)}</td>
          <td class="right">{count}</td>
        </tr>"""

    # Repeated reads rows
    reads_rows = ""
    for r in reads[:15]:
        fp = r.get("filepath", "")
        if len(fp) > 55:
            fp = "..." + fp[-52:]
        reads_rows += f"""<tr>
          <td class="right">{r.get('read_count', 0)}</td>
          <td class="mono">{_esc(fp)}</td>
          <td>{_esc(r.get('project', ''))}</td>
        </tr>"""

    # Novel patterns
    novel_html = ""
    if novel:
        for n in novel:
            novel_html += f"""<div class="novel-item">
              <span class="novel-type">{_esc(n.get('type', ''))}</span>
              <span class="novel-count">{n.get('count', 0)}x</span>
              <span>{_esc(n.get('suggestion', ''))}</span>
            </div>"""

    # Signal overview bars
    overview_bars = ""
    colors = {
        "Frustration": "var(--err)",
        "Self-Correction": "var(--warn)",
        "Tool Errors": "var(--accent)",
        "Repeated Reads": "var(--accent2)",
        "Skill Outcomes": "var(--purple)",
    }
    for label, count in signal_counts.items():
        w = round((count / max_signal) * 100) if max_signal else 0
        color = colors.get(label, "var(--accent)")
        overview_bars += f"""<div class="overview-row">
          <span class="overview-label">{label}</span>
          <div class="overview-bar-wrap">
            <div class="overview-bar" style="width:{w}%;background:{color}"></div>
          </div>
          <span class="overview-count">{count}</span>
        </div>"""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Scan Sessions Report</title>
<style>
  :root {{
    --bg: #0d1117; --surface: #161b22; --surface2: #1c2333;
    --text: #e6edf3; --dim: #7d8590;
    --accent: #58a6ff; --accent2: #3fb950; --purple: #a78bfa;
    --warn: #d29922; --err: #f85149; --border: #30363d;
    --radius: 8px;
  }}
  body.light {{
    --bg: #f6f8fa; --surface: #ffffff; --surface2: #f0f3f6;
    --text: #1f2328; --dim: #656d76;
    --accent: #0969da; --accent2: #1a7f37; --purple: #8250df;
    --warn: #9a6700; --err: #cf222e; --border: #d0d7de;
  }}
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif;
    background: var(--bg); color: var(--text);
    padding: 24px; line-height: 1.5; transition: background 0.2s, color 0.2s;
  }}
  .theme-toggle {{
    position: fixed; top: 12px; right: 16px; z-index: 100;
    background: var(--surface); border: 1px solid var(--border);
    color: var(--text); border-radius: 6px; padding: 6px 12px;
    cursor: pointer; font-size: 14px;
  }}
  .theme-toggle:hover {{ border-color: var(--accent); }}

  .header {{
    display: flex; align-items: baseline; gap: 16px;
    margin-bottom: 24px; padding-bottom: 16px;
    border-bottom: 1px solid var(--border);
  }}
  .header h1 {{ font-size: 22px; font-weight: 700; }}
  .header .meta {{ color: var(--dim); font-size: 13px; margin-left: auto; }}

  .grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }}
  .card {{
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--radius); padding: 16px;
  }}
  .card h2 {{
    font-size: 13px; font-weight: 600; color: var(--dim);
    text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 12px;
  }}
  .card.full {{ grid-column: 1 / -1; }}

  .stats {{ display: flex; gap: 32px; flex-wrap: wrap; }}
  .stat {{ text-align: center; }}
  .stat .value {{ font-size: 32px; font-weight: 700; color: var(--accent); }}
  .stat .label {{ font-size: 12px; color: var(--dim); margin-top: 2px; }}

  table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
  th {{
    text-align: left; padding: 8px 10px;
    border-bottom: 2px solid var(--border);
    color: var(--dim); font-weight: 600; font-size: 11px;
    text-transform: uppercase; letter-spacing: 0.5px;
  }}
  td {{ padding: 7px 10px; border-bottom: 1px solid var(--border); }}
  tr:hover td {{ background: var(--surface2); }}
  .mono {{ font-family: 'SF Mono', 'Cascadia Code', monospace; font-size: 12px; }}
  .right {{ text-align: right; }}

  .badge {{
    display: inline-block; padding: 2px 8px; border-radius: 12px;
    font-size: 11px; font-weight: 600; text-transform: uppercase;
  }}
  .sev-high {{ background: rgba(248,81,73,0.15); color: var(--err); }}
  .sev-medium {{ background: rgba(210,153,34,0.15); color: var(--warn); }}
  .sev-low {{ background: rgba(88,166,255,0.15); color: var(--accent); }}

  .h-bar {{
    height: 6px; border-radius: 3px; background: var(--accent);
    min-width: 2px; transition: width 0.3s;
  }}

  /* Stacked bar for skill outcomes */
  .stacked-bar {{
    display: flex; height: 8px; border-radius: 4px; overflow: hidden;
    background: var(--surface2); min-width: 80px;
  }}
  .bar-seg {{ height: 100%; }}
  .bar-seg.success {{ background: var(--accent2); }}
  .bar-seg.recovered {{ background: var(--warn); }}
  .bar-seg.error {{ background: var(--err); }}
  .bar-seg.unknown {{ background: var(--surface2); }}

  /* Overview bars */
  .overview-row {{
    display: flex; align-items: center; gap: 12px; margin-bottom: 8px;
  }}
  .overview-label {{ min-width: 120px; font-size: 13px; color: var(--dim); }}
  .overview-bar-wrap {{
    flex: 1; height: 10px; background: var(--surface2);
    border-radius: 5px; overflow: hidden;
  }}
  .overview-bar {{ height: 100%; border-radius: 5px; transition: width 0.3s; }}
  .overview-count {{
    min-width: 40px; text-align: right; font-weight: 600;
    font-size: 14px; font-family: 'SF Mono', monospace;
  }}

  /* Novel patterns */
  .novel-item {{
    padding: 8px 12px; margin-bottom: 6px;
    background: var(--surface2); border-radius: 6px;
    border-left: 3px solid var(--purple); font-size: 13px;
  }}
  .novel-type {{
    display: inline-block; padding: 1px 6px; border-radius: 4px;
    font-size: 11px; font-weight: 600; background: rgba(167,139,250,0.15);
    color: var(--purple); margin-right: 8px;
  }}
  .novel-count {{
    font-weight: 700; color: var(--warn); margin-right: 6px;
  }}

  .empty {{ color: var(--dim); font-style: italic; padding: 20px; text-align: center; }}

  .legend {{
    display: flex; gap: 16px; margin-top: 10px; font-size: 12px; color: var(--dim);
  }}
  .legend-item {{ display: flex; align-items: center; gap: 4px; }}
  .legend-dot {{
    width: 10px; height: 10px; border-radius: 3px; display: inline-block;
  }}

  @media (max-width: 768px) {{
    .grid {{ grid-template-columns: 1fr; }}
    table {{ font-size: 12px; }}
    .stats {{ gap: 16px; }}
  }}
</style>
</head>
<body>
<button class="theme-toggle" onclick="document.body.classList.toggle('light')">&#9728; / &#9790;</button>

<div class="header">
  <h1>Scan Sessions Report</h1>
  <span class="meta">
    {render_ts} &middot;
    {timing.get('total_s', '?')}s
    (crawl {timing.get('crawl_s', '?')}s, signals {timing.get('signals_s', '?')}s)
  </span>
</div>

<div class="grid">
  <!-- Summary stats -->
  <div class="card">
    <h2>Overview</h2>
    <div class="stats">
      <div class="stat"><div class="value">{s.get('sessions_scanned', 0)}</div><div class="label">Sessions</div></div>
      <div class="stat"><div class="value">{s.get('total_turns', 0):,}</div><div class="label">Turns</div></div>
      <div class="stat"><div class="value">{s.get('total_signals', 0)}</div><div class="label">Signals</div></div>
      <div class="stat"><div class="value">{s.get('user_turns', 0):,}</div><div class="label">User Turns</div></div>
    </div>
  </div>

  <!-- Signal breakdown -->
  <div class="card">
    <h2>Signal Breakdown</h2>
    {overview_bars}
  </div>

  <!-- Frustration table -->
  <div class="card full">
    <h2>Frustration Signals ({len(frustration)} found)</h2>
    {"<p class='empty'>No frustration signals detected</p>" if not frustration else f'''
    <table>
      <thead><tr><th>Severity</th><th>Project</th><th>Type</th><th>Text</th></tr></thead>
      <tbody>{frust_rows}</tbody>
    </table>'''}
  </div>

  <!-- Self-corrections -->
  <div class="card">
    <h2>Self-Corrections ({len(correction_events)} events)</h2>
    {"<p class='empty'>No self-corrections detected</p>" if not correction_subtypes else f'''
    <table>
      <thead><tr><th>Subtype</th><th class="right">Count</th></tr></thead>
      <tbody>{correction_rows}</tbody>
    </table>'''}
  </div>

  <!-- Tool errors -->
  <div class="card">
    <h2>Tool Errors ({tool_total} total)</h2>
    {"<p class='empty'>No tool errors detected</p>" if not tool_categories else f'''
    <table>
      <thead><tr><th>Category</th><th class="right">Count</th><th></th></tr></thead>
      <tbody>{tool_rows}</tbody>
    </table>'''}
  </div>

  <!-- Skill reliability -->
  <div class="card full">
    <h2>Skill Reliability</h2>
    {"<p class='empty'>No skill invocations detected</p>" if not skill_rows else f'''
    <table>
      <thead><tr>
        <th>Skill</th><th class="right">Uses</th><th>Outcome Distribution</th>
        <th class="right">OK</th><th class="right">Recv</th>
        <th class="right">Fail</th><th class="right">Unk</th>
      </tr></thead>
      <tbody>{skill_rows}</tbody>
    </table>
    <div class="legend">
      <div class="legend-item"><span class="legend-dot" style="background:var(--accent2)"></span> Success</div>
      <div class="legend-item"><span class="legend-dot" style="background:var(--warn)"></span> Recovered</div>
      <div class="legend-item"><span class="legend-dot" style="background:var(--err)"></span> Error/Rejected</div>
      <div class="legend-item"><span class="legend-dot" style="background:var(--surface2)"></span> Unknown</div>
    </div>'''}
  </div>

  <!-- Repeated reads -->
  <div class="card">
    <h2>Repeated Reads (top {len(reads)})</h2>
    {"<p class='empty'>No repeated reads detected</p>" if not reads else f'''
    <table>
      <thead><tr><th class="right">Reads</th><th>File</th><th>Project</th></tr></thead>
      <tbody>{reads_rows}</tbody>
    </table>'''}
  </div>

  <!-- Novel patterns -->
  <div class="card">
    <h2>Novel Patterns ({len(novel)} new)</h2>
    {"<p class='empty'>No novel patterns detected</p>" if not novel else novel_html}
  </div>
</div>

</body>
</html>"""

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write(html)

    return output_path


def _esc(s):
    """Escape HTML special characters."""
    if not s:
        return ""
    return (str(s)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;"))

"""Interactive Tailwind color picker for the Excel export — one self-contained
HTML page. Dropdowns for each group's header + body, live sheet preview, contrast
readout, and a copy-paste summary of the chosen hexes.
"""
import json

# Canonical Tailwind v3 palette (50-900) — neutrals first, then accents.
TW = {
 "slate":{50:"#F8FAFC",100:"#F1F5F9",200:"#E2E8F0",300:"#CBD5E1",400:"#94A3B8",500:"#64748B",600:"#475569",700:"#334155",800:"#1E293B",900:"#0F172A"},
 "gray":{50:"#F9FAFB",100:"#F3F4F6",200:"#E5E7EB",300:"#D1D5DB",400:"#9CA3AF",500:"#6B7280",600:"#4B5563",700:"#374151",800:"#1F2937",900:"#111827"},
 "zinc":{50:"#FAFAFA",100:"#F4F4F5",200:"#E4E4E7",300:"#D4D4D8",400:"#A1A1AA",500:"#71717A",600:"#52525B",700:"#3F3F46",800:"#27272A",900:"#18181B"},
 "neutral":{50:"#FAFAFA",100:"#F5F5F5",200:"#E5E5E5",300:"#D4D4D4",400:"#A3A3A3",500:"#737373",600:"#525252",700:"#404040",800:"#262626",900:"#171717"},
 "stone":{50:"#FAFAF9",100:"#F5F5F4",200:"#E7E5E4",300:"#D6D3D1",400:"#A8A29E",500:"#78716C",600:"#57534E",700:"#44403C",800:"#292524",900:"#1C1917"},
 "red":{50:"#FEF2F2",100:"#FEE2E2",200:"#FECACA",300:"#FCA5A5",400:"#F87171",500:"#EF4444",600:"#DC2626",700:"#B91C1C",800:"#991B1B",900:"#7F1D1D"},
 "orange":{50:"#FFF7ED",100:"#FFEDD5",200:"#FED7AA",300:"#FDBA74",400:"#FB923C",500:"#F97316",600:"#EA580C",700:"#C2410C",800:"#9A3412",900:"#7C2D12"},
 "amber":{50:"#FFFBEB",100:"#FEF3C7",200:"#FDE68A",300:"#FCD34D",400:"#FBBF24",500:"#F59E0B",600:"#D97706",700:"#B45309",800:"#92400E",900:"#78350F"},
 "yellow":{50:"#FEFCE8",100:"#FEF9C3",200:"#FEF08A",300:"#FDE047",400:"#FACC15",500:"#EAB308",600:"#CA8A04",700:"#A16207",800:"#854D0E",900:"#713F12"},
 "lime":{50:"#F7FEE7",100:"#ECFCCB",200:"#D9F99D",300:"#BEF264",400:"#A3E635",500:"#84CC16",600:"#65A30D",700:"#4D7C0F",800:"#3F6212",900:"#365314"},
 "green":{50:"#F0FDF4",100:"#DCFCE7",200:"#BBF7D0",300:"#86EFAC",400:"#4ADE80",500:"#22C55E",600:"#16A34A",700:"#15803D",800:"#166534",900:"#14532D"},
 "emerald":{50:"#ECFDF5",100:"#D1FAE5",200:"#A7F3D0",300:"#6EE7B7",400:"#34D399",500:"#10B981",600:"#059669",700:"#047857",800:"#065F46",900:"#064E3B"},
 "teal":{50:"#F0FDFA",100:"#CCFBF1",200:"#99F6E4",300:"#5EEAD4",400:"#2DD4BF",500:"#14B8A6",600:"#0D9488",700:"#0F766E",800:"#115E59",900:"#134E4A"},
 "cyan":{50:"#ECFEFF",100:"#CFFAFE",200:"#A5F3FC",300:"#67E8F9",400:"#22D3EE",500:"#06B6D4",600:"#0891B2",700:"#0E7490",800:"#155E75",900:"#164E63"},
 "sky":{50:"#F0F9FF",100:"#E0F2FE",200:"#BAE6FD",300:"#7DD3FC",400:"#38BDF8",500:"#0EA5E9",600:"#0284C7",700:"#0369A1",800:"#075985",900:"#0C4A6E"},
 "blue":{50:"#EFF6FF",100:"#DBEAFE",200:"#BFDBFE",300:"#93C5FD",400:"#60A5FA",500:"#3B82F6",600:"#2563EB",700:"#1D4ED8",800:"#1E40AF",900:"#1E3A8A"},
 "indigo":{50:"#EEF2FF",100:"#E0E7FF",200:"#C7D2FE",300:"#A5B4FC",400:"#818CF8",500:"#6366F1",600:"#4F46E5",700:"#4338CA",800:"#3730A3",900:"#312E81"},
 "violet":{50:"#F5F3FF",100:"#EDE9FE",200:"#DDD6FE",300:"#C4B5FD",400:"#A78BFA",500:"#8B5CF6",600:"#7C3AED",700:"#6D28D9",800:"#5B21B6",900:"#4C1D95"},
 "purple":{50:"#FAF5FF",100:"#F3E8FF",200:"#E9D5FF",300:"#D8B4FE",400:"#C084FC",500:"#A855F7",600:"#9333EA",700:"#7E22CE",800:"#6B21A8",900:"#581C87"},
 "fuchsia":{50:"#FDF4FF",100:"#FAE8FF",200:"#F5D0FE",300:"#F0ABFC",400:"#E879F9",500:"#D946EF",600:"#C026D3",700:"#A21CAF",800:"#86198F",900:"#701A75"},
 "pink":{50:"#FDF2F8",100:"#FCE7F3",200:"#FBCFE8",300:"#F9A8D4",400:"#F472B6",500:"#EC4899",600:"#DB2777",700:"#BE185D",800:"#9D174D",900:"#831843"},
 "rose":{50:"#FFF1F2",100:"#FFE4E6",200:"#FECDD3",300:"#FDA4AF",400:"#FB7185",500:"#F43F5E",600:"#E11D48",700:"#BE123C",800:"#9F1239",900:"#881337"},
}

DEFAULTS = {  # current applied palette
 "required":{"header":"#CBD5E1","body":"#F8FAFC"},
 "generated":{"header":"#2563EB","body":"#EFF6FF"},
 "rest":{"header":"#E2E8F0","body":"#NONE"},
}

palette_json = json.dumps(TW)
defaults_json = json.dumps(DEFAULTS)

html = """<!doctype html><html lang=en><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1"><title>Excel color picker</title>
<style>
:root{--bg:#0f1115;--surface:#1a1d23;--text:#e6e8eb;--dim:#9aa0a6;--border:#2a2e35}
[data-theme=light]{--bg:#f5f6f8;--surface:#fff;--text:#1a1d23;--dim:#5f6368;--border:#e2e5ea}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:14px/1.5 -apple-system,Segoe UI,Roboto,sans-serif;padding:24px}
header{display:flex;justify-content:space-between;align-items:center;margin-bottom:6px}h1{font-size:19px;margin:0}
button{background:var(--surface);color:var(--text);border:1px solid var(--border);border-radius:8px;padding:7px 13px;cursor:pointer}
.controls{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin:16px 0 22px;max-width:1000px}
.group{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:14px}
.group h3{margin:0 0 10px;font-size:14px}
.group label{display:block;font-size:12px;color:var(--dim);margin:8px 0 3px}
select{width:100%;background:var(--bg);color:var(--text);border:1px solid var(--border);border-radius:7px;padding:6px}
.sw{display:inline-block;width:13px;height:13px;border-radius:3px;vertical-align:middle;margin-right:6px;border:1px solid #0003}
.cr{font-size:11px;color:var(--dim);margin-top:6px}
table{border-collapse:collapse;width:100%;max-width:1000px;font-size:12px;color:#1a1d23;table-layout:fixed}
th,td{border:1px solid #c9ccd1;padding:7px 9px;text-align:left;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}th{font-weight:700}
.out{margin-top:18px;max-width:1000px;background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:14px;font-family:ui-monospace,Menlo,monospace;font-size:12px;white-space:pre-wrap}
.bad{color:#ff8888}
</style></head><body data-theme=dark>
<header><h1>Excel export — pick colors for all 3 groups</h1>
<button onclick="document.body.dataset.theme=document.body.dataset.theme=='dark'?'light':'dark'">◐ theme</button></header>
<p style="color:var(--dim);max-width:1000px;margin:2px 0 0">Header text (white/dark) is auto-chosen by contrast. <b>rest</b> body can be “none” (white). Play, then copy the summary at the bottom and tell me which to finalize.</p>
<div class=controls id=controls></div>
<table id=preview></table>
<div class=out id=out></div>
<script>
const TW=__PALETTE__, DEF=__DEFAULTS__;
const GROUPS=["required","generated","rest"];
const COLS=[["Part Number","required","BRK-10482"],["Part Type","required","Brake Pad Set"],["Brand","required","Versable"],
["Title","generated","Front Ceramic Brake Pads"],["Description","generated","Low-dust ceramic, quiet stops."],["SKU Ref","rest","A-204"]];
function lin(c){c/=255;return c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4);}
function lum(h){h=h.replace('#','');return 0.2126*lin(parseInt(h.slice(0,2),16))+0.7152*lin(parseInt(h.slice(2,4),16))+0.0722*lin(parseInt(h.slice(4,6),16));}
function contrast(a,b){const A=lum(a),B=lum(b),hi=Math.max(A,B),lo=Math.min(A,B);return ((hi+0.05)/(lo+0.05));}
function bestText(bg){const w=contrast('#FFFFFF',bg),d=contrast('#1E293B',bg);return w>=d?['#FFFFFF',w]:['#1E293B',d];}
function opts(sel,withNone){let h=withNone?'<option value="#NONE">none (white)</option>':'';
 for(const fam in TW){h+=`<optgroup label="${fam}">`;for(const sh in TW[fam]){h+=`<option value="${TW[fam][sh]}">${fam}-${sh}  ${TW[fam][sh]}</option>`;}h+='</optgroup>';}
 sel.innerHTML=h;}
const state={};
function buildControls(){const c=document.getElementById('controls');
 GROUPS.forEach(g=>{state[g]={header:DEF[g].header,body:DEF[g].body};
  const d=document.createElement('div');d.className='group';
  d.innerHTML=`<h3>${g}</h3><label>header fill</label><select id="${g}-header"></select>
   <label>body fill</label><select id="${g}-body"></select><div class=cr id="${g}-cr"></div>`;
  c.appendChild(d);
  const hs=d.querySelector(`#${g}-header`),bs=d.querySelector(`#${g}-body`);
  opts(hs,false);opts(bs,true);hs.value=DEF[g].header;bs.value=DEF[g].body;
  hs.onchange=()=>{state[g].header=hs.value;render();};bs.onchange=()=>{state[g].body=bs.value;render();};});}
function render(){
 const t=document.getElementById('preview');
 let ths='';COLS.forEach(([n,grp])=>{const bg=state[grp].header,[tx,cr]=bestText(bg);ths+=`<th style="background:${bg};color:${tx}">${n}</th>`;});
 let trs='';for(let i=0;i<3;i++){trs+='<tr>'+COLS.map(([n,grp,s])=>{const b=state[grp].body;return `<td style="background:${b=='#NONE'?'#FFFFFF':b}">${s}</td>`;}).join('')+'</tr>';}
 t.innerHTML=`<thead><tr>${ths}</tr></thead><tbody>${trs}</tbody>`;
 GROUPS.forEach(g=>{const[tx,cr]=bestText(state[g].header);const ok=cr>=4.5;
  document.getElementById(g+'-cr').innerHTML=`<span class=sw style="background:${state[g].header}"></span>hdr ${state[g].header} → ${tx=='#FFFFFF'?'white':'dark'} text <span class="${ok?'':'bad'}">${cr.toFixed(1)}:1</span>`;});
 let o='Chosen palette (copy + tell me which to finalize):\\n\\n';
 GROUPS.forEach(g=>{const[tx]=bestText(state[g].header);o+=`${g.padEnd(10)} header ${state[g].header}  text ${tx}   body ${state[g].body}\\n`;});
 document.getElementById('out').textContent=o;}
buildControls();render();
</script></body></html>"""
html = html.replace("__PALETTE__", palette_json).replace("__DEFAULTS__", defaults_json)
open("/tmp/excel-palettes/picker.html","w").write(html)
print("wrote /tmp/excel-palettes/picker.html")

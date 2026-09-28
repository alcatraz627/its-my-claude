-- Pandoc filter for /word-doc: maps the DOC.md source shape onto the named
-- styles that make_reference.py defines. Four jobs:
--
--   * a GitHub-style callout blockquote (> [!NOTE] ...) becomes a paragraph in
--     the matching "Callout <Kind>" style, with the kind as a bold lead-in
--   * a code block with no language, or with the class diagram / ascii / text,
--     becomes one "Diagram" paragraph: every line kept verbatim, joined by line
--     breaks, so the box drawing survives and the block never gets highlighted
--   * a paragraph that is only \newpage becomes a page break
--   * a code block carrying caption="..." gets a "Table Caption"-styled line
--     under it, so figures read like the tables next to them
--   * toc: true in the frontmatter becomes a static, hyperlinked contents list
--     (levels 1 to 3) under a "Contents" heading. Static on purpose: Word's TOC
--     field is empty until Word recomputes it, and Google Docs and LibreOffice
--     never do, so a field would ship blank to two of the three readers.
--
-- Everything else is pandoc's own docx writer.

local CALLOUTS = {
  NOTE = "Callout Note",
  TIP = "Callout Tip",
  WARNING = "Callout Warning",
  CAUTION = "Callout Warning",
  IMPORTANT = "Callout Important",
}

-- Glyphs pair with the colours in theme.json; keep the two in step.
local GLYPHS = {
  NOTE = "◈", TIP = "✦", WARNING = "▲", CAUTION = "▲", IMPORTANT = "●",
}

local DIAGRAM_CLASSES = { diagram = true, ascii = true, text = true, [""] = true }

-- The look comes from the metadata (render.py passes doclook=gdoc); Harbor is the default.
local LOOK = "harbor"
local QUOTE_MARK = "\u{201C}"
local NEXT_TABLE_LIGHT = false
local GDOC_GLYPHS = { NOTE = "◈", TIP = "✦", WARNING = "▲", IMPORTANT = "●", CAUTION = "■" }
local THIN = "\u{2009}"

local function is_stroke(cp)
  return (cp >= 0x2190 and cp <= 0x21FF) or (cp >= 0x2500 and cp <= 0x257F)
      or (cp >= 0x25A0 and cp <= 0x25FF) or (cp >= 0x27F0 and cp <= 0x27FF)
end

-- One diagram line as inlines, the strokes in a lighter character style.
local function stroke_inlines(line)
  local out, buf, stroke = {}, {}, nil
  local function flush()
    if #buf == 0 then return end
    local s = pandoc.Str(table.concat(buf))
    if stroke then s = pandoc.Span({ s }, pandoc.Attr("", {}, { ["custom-style"] = "Diagram Stroke" })) end
    table.insert(out, s)
    buf = {}
  end
  for _, cp in utf8.codes(line) do
    local st = is_stroke(cp)
    if stroke ~= nil and st ~= stroke then flush() end
    stroke = st
    table.insert(buf, utf8.char(cp))
  end
  flush()
  if #out == 0 then out = { pandoc.Str(" ") } end
  return out
end

local function custom(style, blocks)
  return pandoc.Div(blocks, pandoc.Attr("", {}, { ["custom-style"] = style }))
end

function BlockQuote(el)
  local first = el.content[1]
  if not (first and first.t == "Para" and first.content[1] and first.content[1].t == "Str") then
    return nil
  end
  local kind = first.content[1].text:match("^%[!(%u+)%]$")
  if not (kind and CALLOUTS[kind]) then
    if LOOK == "gdoc" then
      local mark = pandoc.Span({ pandoc.Str(QUOTE_MARK) }, pandoc.Attr("", {}, { ["custom-style"] = "Quote Mark" }))
      table.insert(first.content, 1, pandoc.Space())
      table.insert(first.content, 1, mark)
      return el
    end
    return nil
  end

  table.remove(first.content, 1)
  while first.content[1] and (first.content[1].t == "SoftBreak" or first.content[1].t == "Space") do
    table.remove(first.content, 1)
  end
  if LOOK == "gdoc" then
    -- One box: the key line (glyph + KIND), a line break, then the text at the same indent.
    local name = kind:sub(1, 1) .. kind:sub(2):lower()
    local glyph = pandoc.Span({ pandoc.Str(GDOC_GLYPHS[kind]) },
      pandoc.Attr("", {}, { ["custom-style"] = "Callout Glyph " .. name }))
    local key = pandoc.Span({ pandoc.Str(" " .. kind) },
      pandoc.Attr("", {}, { ["custom-style"] = "Callout Key " .. name }))
    table.insert(first.content, 1, pandoc.LineBreak())
    table.insert(first.content, 1, key)
    table.insert(first.content, 1, glyph)
    return custom("Callout " .. name, el.content)
  end
  -- Ruled layout: the kind on its own head line (glyph + label), body below.
  local head = custom(CALLOUTS[kind] .. " Head",
    { pandoc.Para({ pandoc.Str(GLYPHS[kind] .. "  " .. kind) }) })
  return { head, custom(CALLOUTS[kind], el.content) }
end

function CodeBlock(el)
  local cls = el.classes[1] or ""
  if not DIAGRAM_CLASSES[cls] then
    local cap = el.attributes["caption"]
    if cap then
      return { el, custom("Table Caption", { pandoc.Para({ pandoc.Str(cap) }) }) }
    end
    return nil
  end
  local inlines = {}
  for line in (el.text .. "\n"):gmatch("(.-)\n") do
    if #inlines > 0 then table.insert(inlines, pandoc.LineBreak()) end
    -- A Str may hold runs of spaces; the docx writer preserves them.
    if LOOK == "gdoc" then
      for _, x in ipairs(stroke_inlines(line)) do table.insert(inlines, x) end
    else
      table.insert(inlines, pandoc.Str(line == "" and " " or line))
    end
  end
  local blocks = { pandoc.Para(inlines) }
  local out = { custom("Diagram", blocks) }
  local cap = el.attributes["caption"]
  if cap then
    table.insert(out, custom("Image Caption", { pandoc.Para({ pandoc.Str(cap) }) }))
  end
  return out
end

local PAGE_BREAK = pandoc.RawBlock("openxml", '<w:p><w:r><w:br w:type="page"/></w:r></w:p>')

function RawBlock(el)
  if (el.format == "tex" or el.format == "latex") and el.text:match("^\\newpage%s*$") then
    return PAGE_BREAK
  end
  -- <!-- table: light --> marks the next table as the light variant (render.py swaps its style).
  if el.format == "html" and el.text:match("^<!%-%-%s*table:%s*light%s*%-%->") then
    NEXT_TABLE_LIGHT = (LOOK == "gdoc")
    return {}
  end
end

-- A date link is a chip in Google Docs; in Word it is just its text.
function Link(el)
  if el.target:match("^date:") then return el.content end
end

-- Column widths from content. Pandoc gives pipe-table columns equal widths unless
-- the author counts dashes, which nobody does, so a "#" column ends up as wide as
-- a sentence column. Measure the longest cell per column (capped, so one long cell
-- does not take the page), and set the widths from that. An author who set widths
-- explicitly keeps them.
local function cell_text(cell)
  local t = {}
  for _, b in ipairs(cell.contents) do table.insert(t, pandoc.utils.stringify(b)) end
  return table.concat(t, " ")
end

local function longest_word(text)
  local n = 0
  for w in text:gmatch("%S+") do n = math.max(n, utf8.len(w) or #w) end
  return n
end

local function size_columns(el)
  -- Authored widths (unequal dash counts) win. Equal widths are pandoc's default
  -- for a wide pipe table with equal dashes, which is the case being fixed.
  local first, authored = nil, false
  for _, cs in ipairs(el.colspecs) do
    local w = cs[2]
    if type(w) == "number" then
      if first == nil then first = w elseif math.abs(w - first) > 1e-6 then authored = true end
    end
  end
  if authored then return end
  local ncol = #el.colspecs
  local longest, word = {}, {}
  for i = 1, ncol do longest[i], word[i] = 0, 0 end
  local function scan(rows)
    for _, row in ipairs(rows) do
      for i, cell in ipairs(row.cells) do
        if i <= ncol then
          local t = cell_text(cell)
          longest[i] = math.max(longest[i], utf8.len(t) or #t)
          word[i] = math.max(word[i], longest_word(t))
        end
      end
    end
  end
  scan(el.head.rows)
  for _, body in ipairs(el.bodies) do scan(body.body) end
  -- Weight by the longest cell, floor 4 and cap 40 characters, so a long-text
  -- column shares the page instead of owning it. Then guarantee every column its
  -- longest word plus padding (about 88 characters fit across the page at the
  -- table's 10pt), so "improve-skill" never breaks across two lines.
  local LINE = 88
  local w, total = {}, 0
  for i = 1, ncol do
    w[i] = math.max(4, math.min(40, longest[i]))
    total = total + w[i]
  end
  if total == 0 then return end
  local need, spare = {}, LINE
  for i = 1, ncol do
    need[i] = math.min(word[i] + 2, 30)
    spare = spare - need[i]
  end
  local final = {}
  if spare > 0 then
    for i = 1, ncol do final[i] = need[i] + spare * (w[i] / total) end
  else
    for i = 1, ncol do final[i] = need[i] end
  end
  local sum = 0
  for i = 1, ncol do sum = sum + final[i] end
  for i = 1, ncol do el.colspecs[i] = { el.colspecs[i][1], final[i] / sum } end
end

-- A table sits flush against whatever follows it; give it a breath.
function Table(el)
  size_columns(el)
  local out = { el, custom("Table Spacer", { pandoc.Para({ pandoc.Str("") }) }) }
  if NEXT_TABLE_LIGHT then
    NEXT_TABLE_LIGHT = false
    table.insert(out, 1, custom("Table Light Marker", { pandoc.Para({ pandoc.Str(" ") }) }))
  end
  return out
end

local function toc_blocks(doc)
  local entries = {}
  for _, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level <= 3 and not b.classes:includes("unnumbered") then
      local link = pandoc.Link(b.content, "#" .. b.identifier)
      table.insert(entries, custom("TOC " .. b.level, { pandoc.Para({ link }) }))
    end
  end
  if #entries == 0 then return {} end
  local out = { custom("TOC Heading", { pandoc.Para({ pandoc.Str("Contents") }) }) }
  for _, e in ipairs(entries) do table.insert(out, e) end
  return out
end

-- Word fuses adjacent paragraphs with matching borders into one box, so two boxed blocks in a row
-- get a small spacer between them; the rule becomes a thin line in the look's colour.
local function boxed(b)
  if b.t == "CodeBlock" or b.t == "BlockQuote" then return true end
  if b.t == "Div" then
    local cs = b.attributes["custom-style"] or ""
    return cs:match("^Callout") ~= nil or cs == "Diagram"
  end
  return false
end

local function gdoc_blocks(blocks)
  local out, prev = {}, false
  for _, b in ipairs(blocks) do
    if b.t == "HorizontalRule" then
      b = custom("Rule", { pandoc.Para({ pandoc.Str("\u{00A0}") }) })
    end
    local now = boxed(b)
    if now and prev then table.insert(out, custom("Box Spacer", { pandoc.Para({ pandoc.Str(" ") }) })) end
    table.insert(out, b)
    prev = now
  end
  return out
end

function Pandoc(doc)
  if LOOK == "gdoc" then doc.blocks = gdoc_blocks(doc.blocks) end
  local want = doc.meta.toc
  if want == nil then return doc end
  if type(want) == "table" then want = pandoc.utils.stringify(want) end
  if want == false or want == "false" or want == "no" then return doc end
  local toc = toc_blocks(doc)
  for i = #toc, 1, -1 do table.insert(doc.blocks, 1, toc[i]) end
  doc.meta.toc = nil
  return doc
end

-- Inline code in the gdoc look gets a thin space either side in the same tint, as in the Google Doc.
function Code(el)
  if LOOK ~= "gdoc" then return nil end
  local function pad() return pandoc.Span({ pandoc.Str(THIN) }, pandoc.Attr("", {}, { ["custom-style"] = "Verbatim Pad" })) end
  return { pad(), el, pad() }
end

-- Pandoc runs a filter's element functions before Meta, so the look is read in a first pass.
return {
  { Meta = function(m)
      if m.doclook then LOOK = pandoc.utils.stringify(m.doclook) end
      if m.quotemark then QUOTE_MARK = pandoc.utils.stringify(m.quotemark) end
    end },
  { BlockQuote = BlockQuote, CodeBlock = CodeBlock, RawBlock = RawBlock, Table = Table, Code = Code, Link = Link },
  { Pandoc = Pandoc },
}

local ADDON, ns = ...
local LY = {}
ns.Layouts = LY

-- Physical positions (ISO names): E = number row, D = top letters, C = home row, B = bottom row.
-- B00 is the extra ISO key left of B01, C12 the key left of Enter (ISO) / above Enter (ANSI).
local BASE = {
  E00 = "`", E01 = "1", E02 = "2", E03 = "3", E04 = "4", E05 = "5", E06 = "6", E07 = "7", E08 = "8", E09 = "9", E10 = "0", E11 = "-", E12 = "=",
  D01 = "Q", D02 = "W", D03 = "E", D04 = "R", D05 = "T", D06 = "Y", D07 = "U", D08 = "I", D09 = "O", D10 = "P", D11 = "[", D12 = "]",
  C01 = "A", C02 = "S", C03 = "D", C04 = "F", C05 = "G", C06 = "H", C07 = "J", C08 = "K", C09 = "L", C10 = ";", C11 = "'", C12 = "\\",
  B01 = "Z", B02 = "X", B03 = "C", B04 = "V", B05 = "B", B06 = "N", B07 = "M", B08 = ",", B09 = ".", B10 = "/",
}

local DEFS = {
  { id = "de", name = "QWERTZ – Deutsch", iso = true, over = { E00 = "^", E11 = "ß", E12 = "´", D06 = "Z", D11 = "Ü", D12 = "+", C10 = "Ö", C11 = "Ä", C12 = "#", B00 = "<", B01 = "Y", B10 = "-" } },
  { id = "at", name = "QWERTZ – Österreich", iso = true, same = "de" },
  { id = "ch", name = "QWERTZ – Schweiz", iso = true, over = { E00 = "§", E11 = "'", E12 = "^", D06 = "Z", D11 = "Ü", D12 = "¨", C10 = "Ö", C11 = "Ä", C12 = "$", B00 = "<", B01 = "Y", B10 = "-" } },
  { id = "us", name = "QWERTY – English (US)", iso = false, over = {} },
  { id = "uk", name = "QWERTY – English (UK)", iso = true, over = { C12 = "#", B00 = "\\" } },
  { id = "fr", name = "AZERTY – Français", iso = true, over = { E00 = "²", E11 = ")", E12 = "=", D01 = "A", D02 = "Z", D11 = "^", D12 = "$", C01 = "Q", C10 = "M", C11 = "Ù", C12 = "*", B00 = "<", B01 = "W", B07 = ",", B08 = ";", B09 = ":", B10 = "!" } },
  { id = "be", name = "AZERTY – Belgique", iso = true, over = { E00 = "²", E11 = ")", E12 = "-", D01 = "A", D02 = "Z", D11 = "^", D12 = "$", C01 = "Q", C10 = "M", C11 = "Ù", C12 = "µ", B00 = "<", B01 = "W", B07 = ",", B08 = ";", B09 = ":", B10 = "=" } },
  { id = "es", name = "QWERTY – Español", iso = true, over = { E00 = "º", E11 = "'", E12 = "¡", D11 = "`", D12 = "+", C10 = "Ñ", C11 = "´", C12 = "Ç", B00 = "<", B10 = "-" } },
  { id = "la", name = "QWERTY – Latinoamérica", iso = true, over = { E00 = "|", E11 = "'", E12 = "¿", D11 = "´", D12 = "+", C10 = "Ñ", C11 = "{", C12 = "}", B00 = "<", B10 = "-" } },
  { id = "it", name = "QWERTY – Italiano", iso = true, over = { E00 = "\\", E11 = "'", E12 = "Ì", D11 = "È", D12 = "+", C10 = "Ò", C11 = "À", C12 = "Ù", B00 = "<", B10 = "-" } },
  { id = "pt", name = "QWERTY – Português (PT)", iso = true, over = { E00 = "\\", E11 = "'", E12 = "«", D11 = "+", D12 = "´", C10 = "Ç", C11 = "º", C12 = "~", B00 = "<", B10 = "-" } },
  { id = "br", name = "QWERTY – Português (BR)", iso = true, over = { E00 = "'", D11 = "´", D12 = "[", C10 = "Ç", C11 = "~", C12 = "]", B00 = "\\", B10 = ";" } },
  { id = "se", name = "QWERTY – Svenska / Suomi", iso = true, over = { E00 = "§", E11 = "+", E12 = "´", D11 = "Å", D12 = "¨", C10 = "Ö", C11 = "Ä", C12 = "'", B00 = "<", B10 = "-" } },
  { id = "dk", name = "QWERTY – Dansk", iso = true, over = { E00 = "½", E11 = "+", E12 = "´", D11 = "Å", D12 = "¨", C10 = "Æ", C11 = "Ø", C12 = "'", B00 = "<", B10 = "-" } },
  { id = "no", name = "QWERTY – Norsk", iso = true, over = { E00 = "|", E11 = "+", E12 = "\\", D11 = "Å", D12 = "¨", C10 = "Ø", C11 = "Æ", C12 = "'", B00 = "<", B10 = "-" } },
  { id = "ru", name = "ЙЦУКЕН – Русский", iso = false, over = {},
    labels = { E00 = "Ё", D01 = "Й", D02 = "Ц", D03 = "У", D04 = "К", D05 = "Е", D06 = "Н", D07 = "Г", D08 = "Ш", D09 = "Щ", D10 = "З", D11 = "Х", D12 = "Ъ",
      C01 = "Ф", C02 = "Ы", C03 = "В", C04 = "А", C05 = "П", C06 = "Р", C07 = "О", C08 = "Л", C09 = "Д", C10 = "Ж", C11 = "Э",
      B01 = "Я", B02 = "Ч", B03 = "С", B04 = "М", B05 = "И", B06 = "Т", B07 = "Ь", B08 = "Б", B09 = "Ю", B10 = "." } },
}

LY.list, LY.byId = {}, {}
for _, d in ipairs(DEFS) do
  local src = d.same and LY.byId[d.same] or nil
  local L = { id = d.id, name = d.name, iso = d.iso, tok = {}, pos = {}, labels = {} }
  local over = src and src.over or d.over
  L.over = over
  for p, t in pairs(BASE) do L.tok[p] = t end
  for p, t in pairs(over) do L.tok[p] = t end
  if not L.iso then L.tok.B00 = nil end
  for p, t in pairs(L.tok) do L.pos[t] = p end
  for p, lab in pairs(d.labels or {}) do L.labels[p] = lab end
  LY.byId[d.id] = L
  LY.list[#LY.list + 1] = L
end

-- No guessing: client language and region say nothing about the physical keyboard
-- (e.g. an English client on a German keyboard in Spain). Until the player has chosen
-- a layout, "us" is used only as neutral geometry for drawing, never for converting.
function LY.IsChosen(id)
  return id ~= nil and LY.byId[id] ~= nil
end

function LY.Get(id)
  return LY.byId[id] or LY.byId.us
end

-- Moves a chord from one layout to another, keeping the physical key.
function LY.Remap(chord, fromId, toId)
  if not LY.IsChosen(fromId) or not LY.IsChosen(toId) or fromId == toId then return chord end
  local from, to = LY.Get(fromId), LY.Get(toId)
  if from.id == to.id then return chord end
  local mods, key = ns.U.SplitChord(chord)
  local p = from.pos[key]
  if p and to.tok[p] then key = to.tok[p] end
  return ns.U.JoinChord(mods, key)
end

---------------------------------------------------------------------------
-- Geometry: every key gets x/y/w/h in key units.
---------------------------------------------------------------------------
local function row(keys, y, list, x0, block)
  local x = x0 or 0
  for _, k in ipairs(keys) do
    local tok, w = k[1], k[2] or 1
    if tok ~= "_" then
      list[#list + 1] = { token = tok ~= "" and tok or nil, pos = k.pos, x = x, y = y, w = w, h = k.h or 1, block = block or "main", label = k.label, iso = k.iso }
    end
    x = x + w
  end
end

local function P(layout, p, w) return { layout.tok[p], w or 1, pos = p } end

LY.SIZES = { "full", "tkl", "75", "65", "60" }
local COMPACT = { ["75"] = true, ["65"] = true, ["60"] = true }

-- F-row is independent of the size; nil means the usual default for that size
function LY.HasFRow(size, frow)
  if frow ~= nil then return frow end
  return size == "full" or size == "tkl" or size == "75" or size == nil
end

-- size: "full" (100 %), "tkl" (80 %), "75", "65", "60"; frow: true/false/nil
function LY.BuildKeys(layoutId, size, frow)
  local L = LY.Get(layoutId)
  size = size or "full"
  frow = LY.HasFRow(size, frow)
  local keys = {}
  local y = 0
  local compact = COMPACT[size]
  local rightCol = size == "75" or size == "65"   -- 1-unit column right of the main block
  if frow then
    if compact then
      local f = { { "ESCAPE" } }
      for i = 1, 12 do f[#f + 1] = { "F" .. i } end
      if size == "75" then f[#f + 1] = { "PRINTSCREEN" }; f[#f + 1] = { "PAUSE" }; f[#f + 1] = { "DELETE" } end
      row(f, 0, keys)
    else
      row({ { "ESCAPE" }, { "_", 1 }, { "F1" }, { "F2" }, { "F3" }, { "F4" }, { "_", .5 }, { "F5" }, { "F6" }, { "F7" }, { "F8" }, { "_", .5 },
        { "F9" }, { "F10" }, { "F11" }, { "F12" } }, 0, keys)
    end
    y = compact and 1 or 1.25
  end
  local r1 = {}
  for _, p in ipairs({ "E00", "E01", "E02", "E03", "E04", "E05", "E06", "E07", "E08", "E09", "E10", "E11", "E12" }) do r1[#r1 + 1] = P(L, p) end
  if not frow then r1[1] = { "ESCAPE" } end
  r1[#r1 + 1] = { "BACKSPACE", 2 }
  if rightCol then r1[#r1 + 1] = { size == "75" and "HOME" or "DELETE" } end
  row(r1, y, keys)
  local r2 = { { "TAB", 1.5 } }
  for _, p in ipairs({ "D01", "D02", "D03", "D04", "D05", "D06", "D07", "D08", "D09", "D10", "D11", "D12" }) do r2[#r2 + 1] = P(L, p) end
  local r3 = { { "CAPSLOCK", 1.75 } }
  for _, p in ipairs({ "C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10", "C11" }) do r3[#r3 + 1] = P(L, p) end
  local r4
  if L.iso then
    -- ISO Enter: 1.5 wide in the top row, 1.25 wide in the home row (L-shape)
    r2[#r2 + 1] = { "ENTER", 1.5, h = 2, iso = true }
    r3[#r3 + 1] = P(L, "C12")
    r4 = { { "LSHIFT", 1.25 }, P(L, "B00") }
  else
    r2[#r2 + 1] = P(L, "C12", 1.5)
    r3[#r3 + 1] = { "ENTER", 2.25 }
    r4 = { { "LSHIFT", 2.25 } }
  end
  if rightCol then r2[#r2 + 1] = { "PAGEUP" }; r3[#r3 + 1] = { "PAGEDOWN" } end
  for _, p in ipairs({ "B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B09", "B10" }) do r4[#r4 + 1] = P(L, p) end
  if rightCol then
    r4[#r4 + 1] = { "RSHIFT", 1.75 }; r4[#r4 + 1] = { "UP" }; r4[#r4 + 1] = { "END" }
  else
    r4[#r4 + 1] = { "RSHIFT", 2.75 }
  end
  row(r2, y + 1, keys); row(r3, y + 2, keys); row(r4, y + 3, keys)
  if rightCol then
    row({ { "LCTRL", 1.25 }, { "", 1.25, label = "" }, { "LALT", 1.25 }, { "SPACE", 6.25 }, { "RALT" }, { "", 1, label = "" }, { "RCTRL" },
      { "LEFT" }, { "DOWN" }, { "RIGHT" } }, y + 4, keys)
  else
    row({ { "LCTRL", 1.5 }, { "", 1.25, label = "" }, { "LALT", 1.25 }, { "SPACE", 6.5 }, { "RALT", 1.25 }, { "", 1.25, label = "" }, { "RCTRL", 2 } }, y + 4, keys)
  end

  local width = rightCol and 16 or 15
  if not compact then
    local nx = 15.5
    if frow then row({ { "PRINTSCREEN" }, { "SCROLLLOCK" }, { "PAUSE" } }, 0, keys, nx, "nav") end
    row({ { "INSERT" }, { "HOME" }, { "PAGEUP" } }, y, keys, nx, "nav")
    row({ { "DELETE" }, { "END" }, { "PAGEDOWN" } }, y + 1, keys, nx, "nav")
    row({ { "_" }, { "UP" } }, y + 3, keys, nx, "nav")
    row({ { "LEFT" }, { "DOWN" }, { "RIGHT" } }, y + 4, keys, nx, "nav")
    width = 18.5
  end
  if size == "full" then
    local nx = 19
    row({ { "NUMLOCK" }, { "NUMPADDIVIDE" }, { "NUMPADMULTIPLY" }, { "NUMPADMINUS" } }, y, keys, nx, "num")
    row({ { "NUMPAD7" }, { "NUMPAD8" }, { "NUMPAD9" }, { "NUMPADPLUS", 1, h = 2 } }, y + 1, keys, nx, "num")
    row({ { "NUMPAD4" }, { "NUMPAD5" }, { "NUMPAD6" } }, y + 2, keys, nx, "num")
    row({ { "NUMPAD1" }, { "NUMPAD2" }, { "NUMPAD3" }, { "NUMPADENTER", 1, h = 2 } }, y + 3, keys, nx, "num")
    row({ { "NUMPAD0", 2 }, { "NUMPADDECIMAL" } }, y + 4, keys, nx, "num")
    width = 23
  end
  for _, k in ipairs(keys) do
    if k.pos and L.labels[k.pos] then k.label = L.labels[k.pos] end
  end
  return keys, width, y + 5
end

local SHORT = {
  ESCAPE = "Esc", TAB = "Tab", CAPSLOCK = "Caps", ENTER = "Enter", BACKSPACE = "Backspace", SPACE = "Space",
  LSHIFT = "Shift", RSHIFT = "Shift", LCTRL = "Ctrl", RCTRL = "Ctrl", LALT = "Alt", RALT = "AltGr",
  PRINTSCREEN = "Print", SCROLLLOCK = "Scroll", PAUSE = "Pause", INSERT = "Ins", HOME = "Pos1", PAGEUP = "PgUp",
  DELETE = "Del", END = "End", PAGEDOWN = "PgDn", UP = "Up", DOWN = "Down", LEFT = "Left", RIGHT = "Right",
  NUMLOCK = "Num", NUMPADDIVIDE = "/", NUMPADMULTIPLY = "*", NUMPADMINUS = "-", NUMPADPLUS = "+", NUMPADDECIMAL = ",",
  NUMPADENTER = "Enter", MOUSEWHEELUP = "Wheel+", MOUSEWHEELDOWN = "Wheel-",
}
for i = 0, 9 do SHORT["NUMPAD" .. i] = tostring(i) end

-- Short label for a key cap.
function LY.KeyLabel(token)
  if not token then return "" end
  if token == "LSHIFT" or token == "RSHIFT" then return ns.L.MOD_SHIFT end
  if token == "LCTRL" or token == "RCTRL" then return ns.L.MOD_CTRL end
  if token == "LALT" then return ns.L.MOD_ALT end
  local m = token:match("^BUTTON(%d+)$")
  if m then return ns.L.MOUSE_BUTTON:format(tonumber(m)) end
  if token == "MOUSEWHEELUP" then return ns.L.WHEEL_UP end
  if token == "MOUSEWHEELDOWN" then return ns.L.WHEEL_DOWN end
  if SHORT[token] and GetBindingText then
    local ok, txt = pcall(GetBindingText, token, nil, true)
    if ok and type(txt) == "string" and txt ~= "" and txt ~= token and #txt <= 10 then return txt end
  end
  return SHORT[token] or token
end

-- Readable chord: "CTRL-SHIFT-E" -> "Strg+Shift+E"
function LY.ChordLabel(chord)
  if not chord then return "" end
  local mods, key = ns.U.SplitChord(chord)
  local parts = {}
  if mods.ALT then parts[#parts + 1] = ns.L.MOD_ALT end
  if mods.CTRL then parts[#parts + 1] = ns.L.MOD_CTRL end
  if mods.SHIFT then parts[#parts + 1] = ns.L.MOD_SHIFT end
  local lay = LY.Get(ns.db and ns.db.layout)
  local p = lay.pos[key]
  parts[#parts + 1] = (p and lay.labels[p]) or LY.KeyLabel(key)
  return table.concat(parts, "+")
end

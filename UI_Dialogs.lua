local ADDON, ns = ...
local U, LY, D, W = ns.U, ns.Layouts, ns.Data, ns.W
local C = U.COLORS
local L = ns.L
local DL = {}
ns.Dialogs = DL

local function dialog(name, w, h, titleText)
  local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
  W.Paint(f, C.bg, C.goldDark)
  f:SetSize(w, h); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetToplevel(true)
  f:EnableMouse(true); f:SetMovable(true); f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:SetScale(ns.db.scale or 0.9)
  f:Hide()
  W.EscClose(f)
  if titleText then
    f.title = W.Text(f, 20, C.gold, "LEFT", true); f.title:SetPoint("TOPLEFT", 26, -22); f.title:SetText(titleText)
  end
  local x = W.Button(f, "X", 30, 30, "ghost"); x:SetPoint("TOPRIGHT", -12, -12); x:SetScript("OnClick", function() f:Hide() end)
  return f
end

local function section(parent, text, anchor, y)
  local fs = W.Text(parent, 10, C.muted)
  fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y or -18)
  fs:SetText(text:upper())
  return fs
end

local function applyData(data, opts, label)
  if InCombatLockdown() then U.Print(L.IN_COMBAT); return end
  if ns.db.importBackup ~= false then D.Backup() end
  local stats, err = D.Apply(data, opts)
  if not stats then U.Print(err == "combat" and L.IN_COMBAT or tostring(err)); return end
  U.Print(L.IMPORT_DONE:format(stats.binds, stats.bars, stats.macros))
  if (stats.settings or 0) + (stats.chat or 0) > 0 then U.Print(L.IMPORT_DONE2:format(stats.settings, stats.chat)) end
  if (stats.missing or 0) > 0 then U.Print(L.PREVIEW_NA:format(stats.missing)) end
  if stats.skipped > 0 then U.Print(L.IMPORT_SKIPPED:format(stats.skipped)) end
  if stats.macroLimit > 0 then U.Print(L.MACRO_LIMIT:format(stats.macroLimit)) end
  if label then U.Print(L.PROFILE_LOADED:format(label)) end
  ns.OnStateSaved()
  if ns.Main then ns.Main.Refresh() end
  if DL.RefreshProfileManager then DL.RefreshProfileManager() end
  return stats
end
DL.ApplyData = applyData

---------------------------------------------------------------------------
-- Import / Export
---------------------------------------------------------------------------
local SECTION_LABELS = { binds = "INC_BINDS", bars = "INC_BARS", macros = "INC_MACROS", controls = "INC_CONTROLS",
  barset = "INC_BARSET", interface = "INC_INTERFACE", chat = "INC_CHAT" }

-- 2-column grid of section checkboxes bound to db[key][section]
local function sectionGrid(parent, anchor, key, onChange, cols, colW)
  cols, colW = cols or 2, colW or 230
  local boxes = {}
  for i, sec in ipairs(D.SECTIONS) do
    local c = W.Check(parent, L[SECTION_LABELS[sec]], function() return ns.db[key][sec] end,
      function(v) ns.db[key][sec] = v; if onChange then onChange() end end)
    c:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", ((i - 1) % cols) * colW, -8 - math.floor((i - 1) / cols) * 26)
    boxes[#boxes + 1] = c
  end
  return boxes
end
DL.SectionGrid = sectionGrid

-- Sections used when a saved profile is loaded (profile menu, profile manager,
-- automatic spec switch, spec suggestion)
function DL.ProfileOpts()
  return { mode = "exact", sections = U.CopyTable(ns.db.profileSections) }
end

function DL.CreateIO()
  if DL.io then return DL.io end
  local f = dialog("ConfigManagerIOFrame", 1100, 700)
  DL.io = f
  local function pane(x)
    local p = W.Frame(f, C.panel, C.border)
    p:SetPoint("TOPLEFT", x, -54); p:SetSize(512, 622)
    return p
  end
  -- Export
  local ex = pane(24)
  local et = W.Text(ex, 20, C.gold, "LEFT", true); et:SetPoint("TOPLEFT", 22, -20); et:SetText(L.EXPORT_TITLE)
  f.exMeta = W.Text(ex, 12, C.muted); f.exMeta:SetPoint("TOPLEFT", et, "BOTTOMLEFT", 0, -6)
  local s1 = section(ex, L.EXPORT_SCOPE, f.exMeta)
  f.exBoxes = sectionGrid(ex, s1, "sections", function() DL.UpdateExport() end)
  local s2 = section(ex, L.EXPORT_STRING, s1, -126)
  f.exBox = W.MultiEdit(ex); f.exBox:SetPoint("TOPLEFT", s2, "BOTTOMLEFT", 0, -8); f.exBox:SetPoint("RIGHT", -22, 0); f.exBox:SetHeight(270)
  f.exBox.edit:SetScript("OnTextChanged", function(self, user) if user and f.exportString then self:SetText(f.exportString); self:HighlightText() end end)
  f.exBox.edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  local hint = W.Text(ex, 11, C.muted); hint:SetPoint("TOPLEFT", f.exBox, "BOTTOMLEFT", 0, -8); hint:SetText(L.COPY_HINT)
  local sel = W.Button(ex, L.SELECT_ALL, 150, 34, "primary"); sel:SetPoint("BOTTOMRIGHT", -22, 20)
  sel:SetScript("OnClick", function() f.exBox.edit:SetFocus(); f.exBox.edit:HighlightText() end)

  -- Import
  local im = pane(564)
  local it = W.Text(im, 20, C.gold, "LEFT", true); it:SetPoint("TOPLEFT", 22, -20); it:SetText(L.IMPORT_TITLE)
  local ih = W.Text(im, 12, C.muted); ih:SetPoint("TOPLEFT", it, "BOTTOMLEFT", 0, -6); ih:SetText(L.IMPORT_PASTE)
  f.imBox = W.MultiEdit(im); f.imBox:SetPoint("TOPLEFT", ih, "BOTTOMLEFT", 0, -12); f.imBox:SetPoint("RIGHT", -22, 0); f.imBox:SetHeight(84)
  f.imBox.edit:SetScript("OnTextChanged", function() DL.UpdatePreview() end)
  local prev = W.Frame(im, { 0.090, 0.086, 0.102 }, C.border)
  prev:SetPoint("TOPLEFT", f.imBox, "BOTTOMLEFT", 0, -12); prev:SetPoint("RIGHT", -22, 0); prev:SetHeight(148)
  f.pvTitle = W.Text(prev, 14, C.text); f.pvTitle:SetPoint("TOPLEFT", 30, -14); f.pvTitle:SetPoint("RIGHT", -150, 0)
  f.pvDot = W.Tex(prev); f.pvDot:SetSize(10, 10); f.pvDot:SetPoint("RIGHT", f.pvTitle, "LEFT", -8, 0)
  f.pvState = W.Text(prev, 11, C.muted, "RIGHT"); f.pvState:SetPoint("TOPRIGHT", -16, -15); f.pvState:SetWidth(140)
  f.pvBoxes = {}
  for i = 1, 3 do
    local b = W.Frame(prev, { 0.122, 0.114, 0.137 }, { 0.122, 0.114, 0.137 })
    b:SetSize(144, 52); b:SetPoint("TOPLEFT", 16 + (i - 1) * 152, -40)
    b.num = W.Text(b, 20, C.text, "LEFT", true); b.num:SetPoint("TOPLEFT", 10, -7)
    b.lab = W.Text(b, 11, C.muted); b.lab:SetPoint("BOTTOMLEFT", 10, 7)
    f.pvBoxes[i] = b
  end
  f.pvNote = W.Text(prev, 11, C.muted); f.pvNote:SetPoint("TOPLEFT", 16, -100); f.pvNote:SetPoint("RIGHT", -16, 0)
  f.pvClient = W.Text(prev, 11, C.muted); f.pvClient:SetPoint("TOPLEFT", f.pvNote, "BOTTOMLEFT", 0, -6); f.pvClient:SetPoint("RIGHT", -16, 0)
  local s4 = section(im, L.IMPORT_SCOPE, prev)
  f.imBoxes = sectionGrid(im, s4, "importSections")
  local s3 = section(im, L.IMPORT_MODE, s4, -124)
  local function radio(mode, text, anchor)
    local r = W.Check(im, text, function() return ns.db.importMode == mode end, function() ns.db.importMode = mode; f.r1:Refresh(); f.r2:Refresh() end)
    r:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
    return r
  end
  f.r1 = radio("merge", L.MODE_MERGE, s3)
  f.r2 = radio("replace", L.MODE_REPLACE, f.r1)
  local bk = W.Check(im, L.BACKUP, function() return ns.db.importBackup end, function(v) ns.db.importBackup = v end)
  bk:SetPoint("TOPLEFT", f.r2, "BOTTOMLEFT", 0, -2)
  f.setInfo = W.Text(im, 11, C.muted); f.setInfo:SetPoint("TOPLEFT", bk, "BOTTOMLEFT", 0, -6)

  local go = W.Button(im, L.DO_IMPORT, 130, 34, "primary"); go:SetPoint("BOTTOMRIGHT", -22, 18)
  local save = W.Button(im, L.SAVE_AS_PROFILE, 170, 34); save:SetPoint("RIGHT", go, "LEFT", -8, 0)
  local cancel = W.Button(im, L.CANCEL, 110, 34); cancel:SetPoint("RIGHT", save, "LEFT", -8, 0)
  cancel:SetScript("OnClick", function() f:Hide() end)
  go:SetScript("OnClick", function()
    if not f.importData then return end
    local s = applyData(f.importData, { mode = ns.db.importMode, sections = U.CopyTable(ns.db.importSections) })
    if s then f:Hide() end
  end)
  save:SetScript("OnClick", function()
    if not f.importData then return end
    local m = f.importData.meta or {}
    local name = (m.className and m.specName and (m.className .. " · " .. m.specName)) or m.className or m.name or L.IMPORT_TITLE
    D.SaveProfile(D.NewProfileKey("imp"), name .. " (" .. U.Timestamp() .. ")", f.importData)
    U.Print(L.PROFILE_SAVED:format(name))
  end)
  f.goBtn, f.saveBtn = go, save
  return f
end

function DL.UpdateExport()
  local f = DL.io
  if not f then return end
  local data = D.Snapshot({ sections = U.CopyTable(ns.db.sections) })
  f.exportString = U.Encode(data)
  f.exBox.edit:SetText(f.exportString)
  f.exBox.edit:HighlightText()
  local nb = data.binds and #data.binds or 0
  f.exMeta:SetText(("%s · %s"):format(D.SpecLabel(), data.meta.client or ""))
end

function DL.UpdatePreview()
  local f = DL.io
  local text = f.imBox.edit:GetText()
  f.importData = nil
  local function boxes(a, b, c)
    local vals = { a, b, c }
    local labs = { L.PREVIEW_BINDS, L.PREVIEW_OVERWRITE, L.PREVIEW_UNKNOWN }
    for i, bx in ipairs(f.pvBoxes) do bx.num:SetText(vals[i] or "–"); bx.lab:SetText(labs[i]); bx.num:SetTextColor(C.text[1], C.text[2], C.text[3]) end
  end
  local function empty(msg)
    f.pvTitle:SetText(msg); f.pvState:SetText(""); f.pvDot:Hide(); f.pvNote:SetText(""); f.pvClient:SetText(""); boxes()
    f.goBtn:SetDisabled(true); f.saveBtn:SetDisabled(true)
  end
  if text == "" then return empty(L.PREVIEW_EMPTY) end
  local data = U.Decode(text)
  if not data then return empty(L.PREVIEW_INVALID) end
  f.importData = data
  local p = D.Preview(data)
  local m = data.meta or {}
  local r, g, b = D.ClassColor(m.class)
  f.pvDot:SetVertexColor(r, g, b); f.pvDot:Show()
  f.pvTitle:SetText((m.className and m.specName and (m.className .. " · " .. m.specName)) or m.className or m.name or "ConfigManager")
  f.pvState:SetText((m.char and (m.char .. " · ") or "") .. (m.created or ""))
  boxes(p.binds, p.changed, p.unknown)
  if p.unknown > 0 then f.pvBoxes[3].num:SetTextColor(C.warn[1], C.warn[2], C.warn[3]) end
  local lay = data.layout and LY.byId[data.layout]
  f.pvNote:SetText(("%d %s · %d %s · %d %s · %d %s · %s"):format(p.bars, L.PREVIEW_BARS, p.macros, L.PREVIEW_MACROS,
    p.settings, L.PREVIEW_SETTINGS, p.chat, L.PREVIEW_CHAT, L.PREVIEW_FROM:format(lay and lay.name or "?")))
  local missing = (p.settingsMissing or 0) + (p.chatMissing or 0)
  local client = L.PREVIEW_CLIENT:format(m.client or "?")
  if missing > 0 then client = client .. "  |cfff0a07e" .. L.PREVIEW_NA:format(missing) .. "|r" end
  f.pvClient:SetText(client)
  f.goBtn:SetDisabled(false); f.saveBtn:SetDisabled(false)
end

local baseUpdatePreview = DL.UpdatePreview
function DL.UpdatePreview()
  baseUpdatePreview()
  local f = DL.io
  if f and f.setInfo then f.setInfo:SetText(L.IMPORT_SET:format(D.BindingSet() == 2 and L.SET_CHARACTER or L.SET_ACCOUNT)) end
end

function DL.OpenIO(focus)
  local f = DL.CreateIO()
  f:SetScale(ns.db.scale or 0.9)
  f:Show()
  f.r1:Refresh(); f.r2:Refresh()
  for _, c in ipairs(f.exBoxes) do c:Refresh() end
  for _, c in ipairs(f.imBoxes) do c:Refresh() end
  DL.UpdateExport()
  if focus == "import" then f.imBox.edit:SetText(""); DL.UpdatePreview(); f.imBox.edit:SetFocus()
  else f.exBox.edit:SetFocus(); f.exBox.edit:HighlightText(); DL.UpdatePreview() end
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
function DL.ToggleSettings()
  local f = DL.settings
  if not f then
    f = dialog("ConfigManagerSettingsFrame", 760, 620, L.SETTINGS_TITLE)
    DL.settings = f
    local col1, col2 = 26, 400
    local function label(text, x, y)
      local fs = W.Text(f, 13, C.text); fs:SetPoint("TOPLEFT", x, y); fs:SetText(text); return fs
    end
    local function rebuild() if ns.Main.frame then ns.Main.RebuildKeyboard(); ns.Main.Refresh() end end
    local langs = {}
    for _, l in ipairs(ns.LANGUAGES) do langs[#langs + 1] = { l[1], l[2] or L.LANG_AUTO } end
    label(L.SET_LANGUAGE, col1, -70)
    f.lang = W.Cycle(f, 330, langs, function() return ns.db.language end, function(v) ns.db.language = v; ns.ApplyLocale(v); U.Print(L.RELOAD_LANG) end)
    f.lang:SetPoint("TOPLEFT", col1, -92)
    local lays = { { "none", L.NOT_SET } }
    for _, l in ipairs(LY.list) do lays[#lays + 1] = { l.id, l.name } end
    label(L.SET_LAYOUT, col2, -70)
    f.layout = W.Cycle(f, 330, lays, function() return LY.IsChosen(ns.db.layout) and ns.db.layout or "none" end,
      function(v) if v ~= "none" then ns.db.layout = v; ns.db.keyboardConfirmed = ns.db.size ~= nil; rebuild() end end)
    f.layout:SetPoint("TOPLEFT", col2, -92)
    label(L.SET_SIZE, col1, -146)
    f.size = W.Cycle(f, 330, { { "none", L.NOT_SET }, { "full", L.SIZE_FULL }, { "tkl", L.SIZE_TKL }, { "75", L.SIZE_75 }, { "65", L.SIZE_65 }, { "60", L.SIZE_60 } },
      function() return ns.db.size or "none" end,
      function(v) if v ~= "none" then ns.db.size = v; ns.db.keyboardConfirmed = LY.IsChosen(ns.db.layout); rebuild() end end)
    f.size:SetPoint("TOPLEFT", col1, -168)
    local mb = {}
    for i = 0, 12 do mb[#mb + 1] = { i, tostring(i) } end
    label(L.SET_MOUSE, col2, -146)
    f.mouse = W.Cycle(f, 330, mb, function() return ns.db.mouseButtons end, function(v) ns.db.mouseButtons = v; rebuild() end)
    f.mouse:SetPoint("TOPLEFT", col2, -168)
    label(L.SET_REMAP, col1, -222)
    f.remap = W.Cycle(f, 330, { { "pos", L.REMAP_POS }, { "name", L.REMAP_NAME } }, function() return ns.db.remap end, function(v) ns.db.remap = v end)
    f.remap:SetPoint("TOPLEFT", col1, -244)
    local sc = {}
    for i = 60, 130, 5 do sc[#sc + 1] = { i / 100, i .. " %" } end
    label(L.SET_SCALE, col2, -222)
    f.scale = W.Cycle(f, 330, sc, function() return math.floor((ns.db.scale or 0.9) * 20 + 0.5) / 20 end,
      function(v) ns.db.scale = v; ns.Main.ApplyScale(); f:SetScale(v) end)
    f.scale:SetPoint("TOPLEFT", col2, -244)
    local y = -310
    local function check(text, key, after)
      local c = W.Check(f, text, function() return ns.db[key] end, function(v) ns.db[key] = v; if after then after(v) end end)
      c:SetPoint("TOPLEFT", col1, y); y = y - 34
      return c
    end
    local mm = W.Check(f, L.SET_MINIMAP, function() return ns.db.minimap.show end, function(v) ns.db.minimap.show = v; DL.UpdateMinimap() end)
    mm:SetPoint("TOPLEFT", col1, -310)
    y = -344
    f.frow = W.Check(f, L.KB_FROW, function() return LY.HasFRow(ns.db.size, ns.db.frow) end,
      function(v) ns.db.frow = v; rebuild() end)
    f.frow:SetPoint("TOPLEFT", col1, -284)
    f.c2 = check(L.SET_ASK, "ask")
    f.c3 = check(L.SET_AUTOSAVE, "autosave")
    f.mm = mm
    local kbb = W.Button(f, L.KB_OPEN, 220, 30); kbb:SetPoint("TOPLEFT", col2, -290)
    kbb:SetScript("OnClick", function() DL.ShowKeyboardPrompt() end)
    local note = W.Text(f, 11, C.muted); note:SetPoint("BOTTOMLEFT", 26, 24); note:SetText(L.RELOAD_LANG)
    local done = W.Button(f, "OK", 110, 34, "primary"); done:SetPoint("BOTTOMRIGHT", -24, 18)
    done:SetScript("OnClick", function() f:Hide() end)
  end
  if f:IsShown() then f:Hide(); return end
  f:SetScale(ns.db.scale or 0.9)
  for _, k in ipairs({ "lang", "layout", "size", "mouse", "remap", "scale" }) do f[k]:Refresh() end
  f.mm:Refresh(); f.c2:Refresh(); f.c3:Refresh(); f.frow:Refresh()
  f:Show()
end

---------------------------------------------------------------------------
-- Spec suggestion
---------------------------------------------------------------------------
function DL.ShowSpecPrompt(info)
  info = info or D.PlayerSpec()
  local f = DL.spec
  if not f then
    f = dialog("ConfigManagerSpecFrame", 640, 470)
    DL.spec = f
    f.badge = W.Frame(f, { 0.141, 0.114, 0.086 }, C.gold); f.badge:SetSize(52, 52); f.badge:SetPoint("TOPLEFT", 26, -26)
    f.badgeIcon = f.badge:CreateTexture(nil, "ARTWORK"); f.badgeIcon:SetPoint("TOPLEFT", 3, -3); f.badgeIcon:SetPoint("BOTTOMRIGHT", -3, 3)
    f.badgeIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local t = W.Text(f, 20, C.gold, "LEFT", true); t:SetPoint("TOPLEFT", f.badge, "TOPRIGHT", 16, -2); t:SetText(L.SPEC_TITLE)
    f.text = W.Text(f, 13, { 0.81, 0.78, 0.73 }); f.text:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8); f.text:SetPoint("RIGHT", -26, 0)
    f.text:SetWordWrap(true)
    f.opts = {}
    for i = 1, 6 do
      local b = CreateFrame("Button", nil, f, "BackdropTemplate")
      b:SetSize(288, 62)
      b:SetPoint("TOPLEFT", 26 + ((i - 1) % 2) * 300, -112 - math.floor((i - 1) / 2) * 72)
      b.bar = W.Tex(b); b.bar:SetSize(4, 34); b.bar:SetPoint("LEFT", 12, 0)
      b.title = W.Text(b, 14, C.text); b.title:SetPoint("TOPLEFT", 26, -12); b.title:SetPoint("RIGHT", -10, 0)
      b.sub = W.Text(b, 11, C.muted); b.sub:SetPoint("TOPLEFT", b.title, "BOTTOMLEFT", 0, -5); b.sub:SetPoint("RIGHT", -10, 0)
      b:SetScript("OnEnter", function(self) if self.ok then W.Paint(self, C.selBg, C.gold) end end)
      b:SetScript("OnLeave", function(self) self:Paint() end)
      function b:Paint() W.Paint(self, { 0.090, 0.086, 0.102 }, C.border); self:SetAlpha(self.ok and 1 or 0.45) end
      b:SetScript("OnClick", function(self) if self.ok and self.action then self.action(); f:Hide() end end)
      f.opts[i] = b
    end
    f.dont = W.Check(f, L.DONT_ASK, function() return f.dontAsk end, function(v) f.dontAsk = v end)
    f.dont:SetPoint("BOTTOMLEFT", 26, 24)
    f:HookScript("OnHide", function()
      if f.specKey and f.dontAsk then ns.cdb.asked[f.specKey] = "never" end
    end)
  end
  local key = D.SpecKey(info)
  f.specKey, f.dontAsk = key, false
  f.dont:Refresh()
  f.badgeIcon:SetTexture(info.icon or "Interface\\AddOns\\ConfigManager\\Media\\ConfigManager")
  local r, g, b = D.ClassColor(info.class)
  f.badge:SetBackdropBorderColor(r, g, b)
  local hex = ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
  f.text:SetText(L.SPEC_TEXT:format(hex .. D.SpecLabel(info) .. "|r"))
  local roles = D.ClassRoles(info.class, info.classID)
  local specProf = ns.db.profiles[key]
  local classProf = D.FindClassProfile(info.class, key)
  local function done(label)
    ns.cdb.asked[key] = true
    D.SaveSpecProfile()
    if label then U.Print(L.PROFILE_LOADED:format(label)) end
  end
  local entries = {
    { title = D.SpecLabel(info), sub = specProf and L.SPEC_SUB_SPEC or L.NOT_AVAILABLE, color = { r, g, b }, ok = specProf ~= nil,
      action = function() applyData(specProf.data, DL.ProfileOpts()); done(specProf.name) end },
    { title = info.className or "?", sub = classProf and (L.SPEC_SUB_CLASS .. ": " .. classProf.p.name) or L.NOT_AVAILABLE, color = { r, g, b },
      ok = classProf ~= nil, action = function() applyData(classProf.p.data, DL.ProfileOpts()); done(classProf.p.name) end },
  }
  for _, role in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
    -- Class preset of this spec (or another spec with that role) first, generic role preset otherwise.
    local cp = ns.Presets.ForSpec(info, role)
    local p = cp or ns.Presets.ForRole(role)
    local can = roles[role] and p ~= nil
    local col = role == "TANK" and U.CAT_COLORS.MOVEMENT or (role == "HEALER" and U.CAT_COLORS.OTHER or U.CAT_COLORS.TARGETING)
    local roleKey = role == "TANK" and "ROLE_TANK" or (role == "HEALER" and "ROLE_HEALER" or "ROLE_DPS")
    local sub = not can and L.NOT_AVAILABLE or (cp and (ns.Presets.Name(cp) .. " · " .. L.SPEC_PRESET_SUB) or L.ROLE_SUB)
    entries[#entries + 1] = { title = L[roleKey], sub = sub, color = col, ok = can,
      action = function() applyData(p.data, { mode = "merge", sections = p.sections }); done(ns.Presets.Name(p)) end }
  end
  entries[#entries + 1] = { title = L.NO, sub = L.NO_SUB, color = C.dim, ok = true, action = function() ns.cdb.asked[key] = true end }
  for i, e in ipairs(entries) do
    local bt = f.opts[i]
    bt.ok, bt.action = e.ok, e.action
    bt.title:SetText(e.title); bt.sub:SetText(e.sub)
    bt.bar:SetVertexColor(e.color[1], e.color[2], e.color[3])
    bt:Paint()
  end
  f:SetScale(ns.db.scale or 0.9)
  f:Show()
end

---------------------------------------------------------------------------
-- Profile & preset menus
---------------------------------------------------------------------------
-- Own confirmation dialog: Blizzard's StaticPopup system is shared with the logout
-- countdown, so it is never touched by this addon.
local function confirm(text, fn)
  local f = DL.confirm
  if not f then
    f = dialog("ConfigManagerConfirmFrame", 460, 200)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f.text = W.Text(f, 14, C.text, "CENTER"); f.text:SetPoint("TOPLEFT", 30, -40); f.text:SetPoint("TOPRIGHT", -30, -40)
    f.text:SetWordWrap(true)
    f.yes = W.Button(f, L.YES, 120, 34, "primary"); f.yes:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -6, 22)
    f.no = W.Button(f, L.CANCEL, 120, 34); f.no:SetPoint("BOTTOMLEFT", f, "BOTTOM", 6, 22)
    f.no:SetScript("OnClick", function() f:Hide() end)
    f.yes:SetScript("OnClick", function() local cb = f.fn; f:Hide(); if cb then ns.SafeCall("confirm", cb) end end)
    DL.confirm = f
  end
  f.fn = fn
  f.text:SetText(text)
  f:SetHeight(math.max(170, (f.text.GetStringHeight and f.text:GetStringHeight() or 40) + 120))
  f:SetScale(ns.db.scale or 0.9)
  f:Show()
end
DL.Confirm, DL.Dialog = confirm, dialog

function DL.ToggleBindingSet()
  if InCombatLockdown() then U.Print(L.IN_COMBAT); return end
  local function done() if ns.Main then ns.Main.Refresh() end; if DL.io and DL.io:IsShown() then DL.UpdatePreview() end end
  if D.BindingSet() == 2 then
    confirm(L.CONFIRM_TO_ACCOUNT, function() D.SetBindingSet(1); done() end)
  else
    D.SetBindingSet(2); done()
  end
end

function DL.ProfileMenu(owner)
  local info = D.PlayerSpec()
  local specKey = D.SpecKey(info)
  local items = {
    { text = L.PROFILE_SAVE:format(D.SpecLabel(info)), color = C.gold,
      func = function() local p = D.SaveSpecProfile(); if p then U.Print(L.PROFILE_SAVED:format(p.name)) end end },
    { text = L.PROFILES:upper(), title = true },
  }
  local list = D.ListProfiles()
  if #list == 0 then items[#items + 1] = { text = L.NO_PROFILES, disabled = true } end
  for _, it in ipairs(list) do
    local p = it.p
    local mark = it.key == specKey and "  |cffe3b55b•|r" or ""
    items[#items + 1] = { text = (p.name or it.key) .. mark .. "  |cff6e685f" .. (p.saved or "") .. "|r",
      func = function() applyData(p.data, DL.ProfileOpts(), p.name) end }
  end
  items[#items + 1] = { text = L.MANAGE_PROFILES, color = C.gold, func = function() DL.OpenProfileManager() end }
  W.Menu(owner, items)
end

local function loadPreset(p)
  local name = ns.Presets.Name(p)
  confirm(L.PRESET_CONFIRM:format(name), function()
    applyData(p.data, { mode = "merge", sections = p.sections }, name)
  end)
end
DL.LoadPreset = loadPreset

function DL.PresetMenu(owner)
  local info = D.PlayerSpec()
  local items = {}
  local own = ns.Presets.ForClass(info.class)
  if #own > 0 then
    items[#items + 1] = { text = L.PRESET_CLASS:upper(), title = true }
    local cur = ns.Presets.ForSpec(info)
    for _, p in ipairs(own) do
      local mark = (cur == p) and "  |cffe3b55b•|r" or ""
      items[#items + 1] = { text = ns.Presets.Name(p) .. mark, func = function() loadPreset(p) end }
    end
  end
  items[#items + 1] = { text = L.PRESET_ROLES:upper(), title = true }
  for _, p in ipairs(ns.Presets.list) do
    items[#items + 1] = { text = ns.Presets.Name(p), func = function() loadPreset(p) end }
  end
  W.Menu(owner, items)
end

-- /cfgm checkpresets: which preset spells this character does not know.
function DL.CheckPresets()
  local info = D.PlayerSpec()
  local own = ns.Presets.ForClass(info.class)
  U.Print(L.CHECK_HEAD:format(info.className or info.class or "?"))
  for _, p in ipairs(own) do
    local missing, total = ns.Presets.Missing(p)
    if #missing == 0 then
      U.Print(L.CHECK_OK:format(ns.Presets.Name(p), total))
    else
      U.Print(L.CHECK_MISSING:format(ns.Presets.Name(p), #missing, total, table.concat(missing, ", ")))
    end
  end
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------
-- The button is a child of UIParent, not of the Minimap: minimap addons (EllesmereUI,
-- SexyMap, ...) collect and hide Minimap children into their own flyouts.
local function minimapIsSquare()
  if GetMinimapShape then
    local ok, shape = pcall(GetMinimapShape)
    if ok and shape then return shape ~= "ROUND" end
  end
  if EllesmereUI or (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUIMinimap")) then return true end
  return false
end

local function createOwnMinimapButton()
  if DL.mini or not Minimap then return end
  local b = CreateFrame("Button", "ConfigManagerMinimapButton", UIParent)
  b:SetSize(32, 32); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 10)
  b:SetClampedToScreen(true)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
  local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetSize(24, 24); bg:SetPoint("CENTER")
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  local icon = b:CreateTexture(nil, "ARTWORK"); icon:SetSize(20, 20); icon:SetPoint("CENTER")
  icon:SetTexture("Interface\\AddOns\\ConfigManager\\Media\\ConfigManager")
  local border = b:CreateTexture(nil, "OVERLAY"); border:SetSize(54, 54); border:SetPoint("TOPLEFT")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local function place()
    local a = math.rad(ns.db.minimap.angle or 215)
    local hw, hh = (Minimap:GetWidth() or 140) / 2, (Minimap:GetHeight() or 140) / 2
    local x, y = math.cos(a), math.sin(a)
    if minimapIsSquare() then
      local m = math.max(math.abs(x), math.abs(y))
      x, y = x / m * (hw + 4), y / m * (hh + 4)
    else
      x, y = x * (hw + 6), y * (hh + 6)
    end
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      ns.db.minimap.angle = math.deg(math.atan2(cy / s - my, cx / s - mx))
      place()
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  b:SetScript("OnClick", function(_, btn) if btn == "RightButton" then DL.ToggleSettings() else ns.Main.Toggle() end end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("ConfigManager", C.gold[1], C.gold[2], C.gold[3])
    GameTooltip:AddLine(L.MINIMAP_TIP, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  -- follow the minimap (hidden with it, re-placed when it is resized)
  Minimap:HookScript("OnShow", function() DL.UpdateMinimap() end)
  Minimap:HookScript("OnHide", function() b:Hide() end)
  Minimap:HookScript("OnSizeChanged", place)
  DL.mini, DL.placeMini = b, place
  place()
  DL.UpdateMinimap()
  ns.Schedule("miniplace", 3, place)
end

-- Minimap button via LibDBIcon, the standard every minimap collector understands
-- (MinimapButtonButton, EllesmereUI, SexyMap, ...). Falls back to an own button.
local ICON = "Interface\\AddOns\\ConfigManager\\Media\\ConfigManager"

function DL.CreateMinimap()
  if DL.mini or DL.ldbIcon then return end
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  local DBI = LibStub and LibStub("LibDBIcon-1.0", true)
  if not (LDB and DBI) then return createOwnMinimapButton() end
  local obj = LDB:NewDataObject("ConfigManager", {
    type = "launcher", label = "ConfigManager", icon = ICON,
    OnClick = function(_, btn) if btn == "RightButton" then DL.ToggleSettings() else ns.Main.Toggle() end end,
    OnTooltipShow = function(tt)
      tt:AddLine("ConfigManager", C.gold[1], C.gold[2], C.gold[3])
      tt:AddLine(L.MINIMAP_TIP, 1, 1, 1, true)
    end,
  })
  local m = ns.db.minimap
  m.minimapPos = m.minimapPos or m.angle or 215
  m.hide = m.show == false
  DBI:Register("ConfigManager", obj, m)
  DL.ldbIcon = DBI
  DL.UpdateMinimap()
end

-- /cfgm minimap: prints where the button is and why it may be invisible.
-- /cfgm minimapfix: forces it visible on the minimap.
function DL.MinimapDiagnose(fix)
  local P = function(...) U.Print(table.concat({ ... }, " ")) end
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  local DBI = LibStub and LibStub("LibDBIcon-1.0", true)
  P("LibStub:", tostring(LibStub ~= nil), "LDB:", tostring(LDB ~= nil), "LibDBIcon:", DBI and tostring(DBI.minor or "?") or "missing")
  P("registered:", tostring(DL.ldbIcon ~= nil), "scheduled:", tostring(ns.minimapScheduled == true),
    "setting show:", tostring(ns.db.minimap.show ~= false), "hide:", tostring(ns.db.minimap.hide))
  local b = (DBI and DBI.GetMinimapButton and DBI:GetMinimapButton("ConfigManager")) or _G.LibDBIcon10_ConfigManager or DL.mini
  if not b then
    P("button: none")
    if fix then DL.CreateMinimap(); b = (DBI and DBI:GetMinimapButton("ConfigManager")) or DL.mini; P("created now:", tostring(b ~= nil)) end
    if not b then return end
  end
  local par = b:GetParent()
  local x, y = b:GetCenter()
  P("button:", b:GetName() or "?", "parent:", par and (par:GetName() or "unnamed") or "none",
    "shown:", tostring(b:IsShown()), "visible:", tostring(b:IsVisible()), "alpha:", ("%.2f"):format(b:GetAlpha() or -1),
    "size:", ("%dx%d"):format(b:GetWidth() or 0, b:GetHeight() or 0), "pos:", x and ("%d,%d"):format(x, y) or "none")
  if fix then
    if DBI and DL.ldbIcon then ns.db.minimap.show = true; ns.db.minimap.hide = false; DBI:Show("ConfigManager") end
    b:SetAlpha(1); b:Show()
    P("forced visible – alpha:", ("%.2f"):format(b:GetAlpha() or -1), "shown:", tostring(b:IsShown()))
  end
end

function DL.UpdateMinimap()
  local show = ns.db.minimap.show ~= false
  if DL.ldbIcon then
    ns.db.minimap.hide = not show
    if show then DL.ldbIcon:Show("ConfigManager") else DL.ldbIcon:Hide("ConfigManager") end
  elseif DL.mini then
    DL.mini:SetShown(show and Minimap:IsShown())
  end
end

---------------------------------------------------------------------------
-- Button inside Blizzard's key binding settings
---------------------------------------------------------------------------
function DL.HookBlizzard()
  if DL.blizzBtn then return end
  if not SettingsPanel and KeyBindingFrame then
    -- older clients: classic key binding window
    local b = W.Button(UIParent, "ConfigManager", 140, 24, "primary")
    b:SetPoint("TOPRIGHT", KeyBindingFrame, "TOPRIGHT", -40, -8)
    b:SetFrameStrata("DIALOG")
    b:Hide()
    KeyBindingFrame:HookScript("OnShow", function() b:Show() end)
    KeyBindingFrame:HookScript("OnHide", function() b:Hide() end)
    b:SetScript("OnClick", function() if HideUIPanel then pcall(HideUIPanel, KeyBindingFrame) end; ns.Main.Open() end)
    DL.blizzBtn = b
    return
  end
  if not SettingsPanel then return end
  local b = W.Button(UIParent, "ConfigManager", 140, 26, "primary")
  b:SetPoint("TOPRIGHT", SettingsPanel, "TOPRIGHT", -46, -6)
  b:SetFrameStrata("DIALOG")
  b:SetToplevel(true)
  b:SetScript("OnClick", function()
    if HideUIPanel then pcall(HideUIPanel, SettingsPanel) end
    ns.Main.Open()
  end)
  b:Hide()
  DL.blizzBtn = b
  local kbID = Settings and Settings.KEYBINDINGS_CATEGORY_ID
  local function update(category)
    local show = true
    if kbID and category and category.GetID then
      local ok, id = pcall(category.GetID, category)
      if ok then show = id == kbID end
    end
    b:SetShown(show)
  end
  -- No hooksecurefunc on SettingsPanel methods (secure hooks on frame methods fail in
  -- current beta builds); poll the open category while the panel is shown instead.
  local poll = CreateFrame("Frame", nil, UIParent)
  poll:Hide()
  local acc = 0
  poll:SetScript("OnUpdate", function(self, elapsed)
    if not SettingsPanel:IsShown() then self:Hide(); return end
    acc = acc + (elapsed or 0)
    if acc < 0.25 then return end
    acc = 0
    local ok, cat = pcall(SettingsPanel.GetCurrentCategory, SettingsPanel)
    update(ok and cat or nil)
  end)
  SettingsPanel:HookScript("OnShow", function()
    local ok, cat = pcall(SettingsPanel.GetCurrentCategory, SettingsPanel)
    update(ok and cat or nil)
    poll:Show()
  end)
  SettingsPanel:HookScript("OnHide", function() b:Hide(); poll:Hide() end)
end

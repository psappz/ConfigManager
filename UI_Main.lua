local ADDON, ns = ...
local U, LY, D, W = ns.U, ns.Layouts, ns.Data, ns.W
local C = U.COLORS
local L = ns.L
local M = { state = { view = "keyboard", layer = "", sel = nil, cat = "ALL", filter = "all", search = "", kbSearch = "", offset = 0 } }
ns.Main = M

local FRAME_W, FRAME_H, DETAIL_W, HEADER_H, FOOTER_H = 1360, 780, 360, 56, 48
local MODMAP = { LSHIFT = "S", RSHIFT = "S", LCTRL = "C", RCTRL = "C", LALT = "A", RALT = "A" }
local COMBOS = { "", "S", "C", "A", "CS", "AS", "AC", "ACS" }
local CAT_ORDER = { "ACTIONBAR", "MOVEMENT", "TARGETING", "INTERFACE", "OTHER" }
local CAT_LABEL = { ACTIONBAR = "CAT_ACTIONBAR", MOVEMENT = "CAT_MOVEMENT", TARGETING = "CAT_TARGETING", INTERFACE = "CAT_INTERFACE", OTHER = "CAT_OTHER" }

local function layerName(code)
  if code == "" then return L.LAYER_NONE end
  local parts = {}
  if code:find("A") then parts[#parts + 1] = L.MOD_ALT end
  if code:find("C") then parts[#parts + 1] = L.MOD_CTRL end
  if code:find("S") then parts[#parts + 1] = L.MOD_SHIFT end
  return table.concat(parts, " + ")
end
M.LayerName = layerName

-- Text shown for a command: the spell/macro on its bar slot, else the binding name.
local function describe(e)
  if not e then return nil, nil end
  if e.slot then
    local a = D.ReadAction(e.slot)
    local src = L.SLOT_SOURCE:format(e.bar, e.index)
    if a and a.n then return a.n, src end
    return e.name, src .. " · " .. L.EMPTY_SLOT
  end
  return e.name, e.header ~= "" and e.header or L[CAT_LABEL[e.cat]]
end
M.Describe = describe

local function catColor(cat) return U.CAT_COLORS[cat] or U.CAT_COLORS.OTHER end

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------
function M.Create()
  if M.frame then return M.frame end
  local f = CreateFrame("Frame", "ConfigManagerMainFrame", UIParent, "BackdropTemplate")
  W.Paint(f, C.bg, C.border)
  f:SetSize(FRAME_W, FRAME_H)
  f:SetPoint("CENTER")
  f:SetFrameStrata("HIGH")
  f:SetToplevel(true)
  f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true)
  f:SetScale(ns.db.scale or 0.9)
  f:Hide()
  W.EscClose(f)
  M.frame = f

  -- Header
  local hdr = W.Frame(f, C.panel, C.border)
  hdr:SetPoint("TOPLEFT"); hdr:SetPoint("TOPRIGHT"); hdr:SetHeight(HEADER_H)
  hdr:EnableMouse(true); hdr:RegisterForDrag("LeftButton")
  hdr:SetScript("OnDragStart", function() f:StartMoving() end)
  hdr:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
  local logo = hdr:CreateTexture(nil, "ARTWORK"); logo:SetSize(28, 28); logo:SetPoint("LEFT", 18, 0)
  logo:SetTexture("Interface\\AddOns\\ConfigManager\\Media\\ConfigManager")
  local title = W.Text(hdr, 18, C.gold, "LEFT", true); title:SetPoint("LEFT", logo, "RIGHT", 10, 0); title:SetText("CONFIGMANAGER")

  M.tabKb = W.Button(hdr, L.TAB_KEYBOARD, 110, 32); M.tabKb:SetPoint("LEFT", title, "RIGHT", 24, 0)
  M.tabList = W.Button(hdr, L.TAB_LIST, 90, 32); M.tabList:SetPoint("LEFT", M.tabKb, "RIGHT", 4, 0)
  M.tabKb:SetScript("OnClick", function() M.SetView("keyboard") end)
  M.tabList:SetScript("OnClick", function() M.SetView("list") end)

  local close = W.Button(hdr, "X", 32, 32, "ghost"); close:SetPoint("RIGHT", -14, 0)
  close:SetScript("OnClick", function() f:Hide() end)
  local gear = W.Button(hdr, "", 32, 32); gear:SetPoint("RIGHT", close, "LEFT", -6, 0)
  local gi = gear:CreateTexture(nil, "ARTWORK"); gi:SetSize(18, 18); gi:SetPoint("CENTER")
  gi:SetTexture("Interface\\Icons\\INV_Misc_Gear_01"); gi:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  gear.tip = L.SETTINGS
  gear:SetScript("OnClick", function() ns.Dialogs.ToggleSettings() end)
  local exp = W.Button(hdr, L.EXPORT, 120, 32, "primary"); exp:SetPoint("RIGHT", gear, "LEFT", -8, 0)
  exp:SetScript("OnClick", function() ns.Dialogs.OpenIO("export") end)
  local imp = W.Button(hdr, L.IMPORT, 112, 32); imp:SetPoint("RIGHT", exp, "LEFT", -6, 0)
  imp:SetScript("OnClick", function() ns.Dialogs.OpenIO("import") end)
  local pre = W.Button(hdr, L.PRESETS, 100, 32); pre:SetPoint("RIGHT", imp, "LEFT", -6, 0)
  pre:SetScript("OnClick", function(self) ns.Dialogs.PresetMenu(self) end)
  local prof = W.Button(hdr, "", 230, 38); prof:SetPoint("RIGHT", pre, "LEFT", -10, 0)
  prof.text:Hide()
  prof.dot = W.Tex(prof); prof.dot:SetSize(10, 10); prof.dot:SetPoint("LEFT", 12, 0)
  prof.small = W.Text(prof, 9, C.muted); prof.small:SetPoint("TOPLEFT", 30, -6); prof.small:SetText(L.PROFILE:upper())
  prof.name = W.Text(prof, 12, C.text); prof.name:SetPoint("BOTTOMLEFT", 30, 6); prof.name:SetPoint("RIGHT", -10, 0)
  prof:SetScript("OnClick", function(self) ns.Dialogs.ProfileMenu(self) end)
  M.profileButton = prof

  -- Body & footer
  local body = CreateFrame("Frame", nil, f)
  body:SetPoint("TOPLEFT", 0, -HEADER_H); body:SetPoint("BOTTOMRIGHT", 0, FOOTER_H)
  M.body = body
  local foot = W.Frame(f, C.panel, C.border)
  foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT"); foot:SetHeight(FOOTER_H)
  M.pendDot = W.Tex(foot, C.gold); M.pendDot:SetSize(8, 8); M.pendDot:SetPoint("LEFT", 20, 0)
  M.pendText = W.Text(foot, 12, C.text); M.pendText:SetPoint("LEFT", M.pendDot, "RIGHT", 10, 0)
  M.setText = W.Text(foot, 12, C.muted); M.setText:SetPoint("LEFT", M.pendText, "RIGHT", 16, 0)
  local apply = W.Button(foot, L.APPLY, 120, 32, "primary"); apply:SetPoint("RIGHT", -16, 0)
  apply:SetScript("OnClick", function() D.SaveBindings(); ns.OnStateSaved(); M.Refresh() end)
  local discard = W.Button(foot, L.DISCARD, 110, 32); discard:SetPoint("RIGHT", apply, "LEFT", -8, 0)
  discard:SetScript("OnClick", function() D.Discard(); M.Refresh() end)
  M.applyBtn, M.discardBtn = apply, discard

  M.BuildKeyboardView()
  M.BuildDetail()
  M.BuildListView()
  M.BuildCapture()

  f:SetScript("OnShow", function()
    M.Refresh()
    if not D.KeyboardChosen() then ns.Dialogs.ShowKeyboardPrompt() end
  end)
  f:SetScript("OnHide", function() W.CloseMenu() end)
  f:RegisterEvent("MODIFIER_STATE_CHANGED")
  f:SetScript("OnEvent", function(_, ev)
    if ev == "MODIFIER_STATE_CHANGED" and M.state.view == "keyboard" and not M.capture:IsShown() then
      local code = (IsAltKeyDown() and "A" or "") .. (IsControlKeyDown() and "C" or "") .. (IsShiftKeyDown() and "S" or "")
      M.state.heldLayer = code ~= "" and code or nil
      M.RefreshKeyboard()
    end
  end)
  M.SetView(M.state.view)
  return f
end

function M.SetView(v)
  M.state.view = v
  if not M.frame then return end
  M.tabKb:SetStyle(v == "keyboard" and "active" or "ghost")
  M.tabList:SetStyle(v == "list" and "active" or "ghost")
  M.kbView:SetShown(v == "keyboard")
  M.detail:SetShown(v == "keyboard")
  M.listView:SetShown(v == "list")
  M.Refresh()
end

function M.Toggle()
  M.Create()
  if M.frame:IsShown() then M.frame:Hide() else M.frame:Show() end
end

function M.Open(view)
  M.Create()
  if view then M.SetView(view) end
  M.frame:Show()
end

---------------------------------------------------------------------------
-- Keyboard view
---------------------------------------------------------------------------
function M.BuildKeyboardView()
  local v = CreateFrame("Frame", nil, M.body)
  v:SetPoint("TOPLEFT"); v:SetPoint("BOTTOMRIGHT", -DETAIL_W, 0)
  M.kbView = v

  local lab = W.Text(v, 11, C.muted); lab:SetPoint("TOPLEFT", 24, -28); lab:SetText(L.LAYER:upper())
  M.layerButtons = {}
  local prev
  for i, code in ipairs({ "", "S", "C", "A" }) do
    local b = W.Button(v, layerName(code), code == "" and 120 or 76, 30)
    if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("LEFT", lab, "RIGHT", 14, 0) end
    b:SetScript("OnClick", function() M.state.layer = code; M.RefreshKeyboard() end)
    b.code = code
    M.layerButtons[i] = b
    prev = b
  end
  local search = W.Edit(v, 240, L.SEARCH_ACTION); search:SetPoint("TOPRIGHT", -24, -18)
  search.edit:HookScript("OnTextChanged", function(self) M.state.kbSearch = self:GetText():lower(); M.RefreshKeyboard() end)

  M.board = W.Frame(v, C.panel, C.border)
  M.board:SetPoint("TOPLEFT", 24, -62)
  M.mouseBoard = W.Frame(v, C.panel, C.border)
  M.mouseBoard:SetPoint("TOPLEFT", M.board, "BOTTOMLEFT", 0, -16)
  local ml = W.Text(M.mouseBoard, 11, C.muted); ml:SetPoint("TOPLEFT", 14, -10); ml:SetText(L.MOUSE:upper())

  M.legend = CreateFrame("Frame", nil, v)
  M.legend:SetPoint("TOPLEFT", M.mouseBoard, "TOPRIGHT", 24, -4); M.legend:SetSize(400, 80)
  local cl = W.Text(M.legend, 11, C.muted); cl:SetPoint("TOPLEFT"); cl:SetText(L.CATEGORIES:upper())
  local x, y = 0, -22
  for i, cat in ipairs(CAT_ORDER) do
    local sw = W.Tex(M.legend, catColor(cat)); sw:SetSize(14, 4); sw:SetPoint("TOPLEFT", x, y - 5)
    local t = W.Text(M.legend, 12, C.text); t:SetPoint("LEFT", sw, "RIGHT", 6, 0); t:SetText(L[CAT_LABEL[cat]])
    x = x + 30 + t:GetStringWidth()
    if i == 3 then x, y = 0, y - 20 end
  end
  M.stats = W.Text(M.legend, 11, C.muted); M.stats:SetPoint("TOPLEFT", 0, -68); M.stats:SetWidth(560); M.stats:SetWordWrap(true)

  M.keyButtons, M.mouseButtons = {}, {}
  M.RebuildKeyboard()
end

local function createKey(parent)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b.label = W.Text(b, 10, C.muted); b.label:SetPoint("TOPLEFT", 5, -4); b.label:SetPoint("RIGHT", -18, 0)
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(14, 14); b.icon:SetPoint("TOPRIGHT", -4, -4)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.action = W.Text(b, 9, C.text); b.action:SetPoint("TOPLEFT", 5, -18); b.action:SetPoint("BOTTOMRIGHT", -3, 7)
  b.action:SetJustifyV("TOP"); b.action:SetWordWrap(true)
  if b.action.SetMaxLines then b.action:SetMaxLines(2) end
  b.stripe = W.Tex(b); b.stripe:SetPoint("BOTTOMLEFT", 5, 3); b.stripe:SetPoint("BOTTOMRIGHT", -5, 3); b.stripe:SetHeight(3)
  b:SetScript("OnClick", function(self, btn)
    if not self.token then return end
    if MODMAP[self.token] then
      local c = MODMAP[self.token]
      local cur = M.state.layer
      if cur:find(c) then cur = cur:gsub(c, "") else cur = cur .. c end
      local code = (cur:find("A") and "A" or "") .. (cur:find("C") and "C" or "") .. (cur:find("S") and "S" or "")
      M.state.layer = code
    else
      M.state.sel = self.token
    end
    M.RefreshKeyboard(); M.RefreshDetail()
  end)
  b:SetScript("OnEnter", function(self)
    if not self.token then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(self.chordLabel or "", 1, 1, 1)
    if self.desc then GameTooltip:AddLine(self.desc, C.gold[1], C.gold[2], C.gold[3]) end
    if self.sub then GameTooltip:AddLine(self.sub, C.muted[1], C.muted[2], C.muted[3]) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

function M.RebuildKeyboard()
  if not M.board then return end
  for _, b in ipairs(M.keyButtons) do b:Hide() end
  for _, b in ipairs(M.mouseButtons) do b:Hide() end
  local keys, width, rows = LY.BuildKeys(ns.db.layout, ns.db.size)
  local avail = (FRAME_W - DETAIL_W) - 48 - 28
  local unit = math.min(52, math.floor(avail / width))
  local gap = 4
  M.unit = unit
  for i, k in ipairs(keys) do
    local b = M.keyButtons[i] or createKey(M.board)
    M.keyButtons[i] = b
    b:SetSize(k.w * unit - gap, k.h * unit - gap)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", 14 + k.x * unit, -14 - k.y * unit)
    if k.iso then W.IsoEnter(b, unit, gap, true) elseif b.isoLower then b.isoLower:Hide() end
    -- category stripe at the very bottom of the key (the lower part for an ISO Enter)
    local base = (k.iso and b.isoLower) or b
    b.stripe:ClearAllPoints()
    b.stripe:SetPoint("BOTTOMLEFT", base, "BOTTOMLEFT", 5, 3); b.stripe:SetPoint("BOTTOMRIGHT", base, "BOTTOMRIGHT", -5, 3)
    if b.stripe.SetDrawLayer then b.stripe:SetParent(base); b.stripe:SetDrawLayer("OVERLAY", 2) end
    b.token, b.spec = k.token, k
    b:Show()
  end
  M.board:SetSize(width * unit - gap + 28, rows * unit - gap + 28)

  local mtokens = {}
  for i = 3, 2 + (ns.db.mouseButtons or 3) do mtokens[#mtokens + 1] = "BUTTON" .. i end
  mtokens[#mtokens + 1] = "MOUSEWHEELUP"; mtokens[#mtokens + 1] = "MOUSEWHEELDOWN"
  local mw = unit * 2 - gap
  for i, tok in ipairs(mtokens) do
    local b = M.mouseButtons[i] or createKey(M.mouseBoard)
    M.mouseButtons[i] = b
    b:SetSize(mw, unit - gap)
    b:ClearAllPoints()
    local col, row = (i - 1) % 7, math.floor((i - 1) / 7)
    b:SetPoint("TOPLEFT", 14 + col * (mw + gap), -30 - row * unit)
    b.token, b.spec = tok, { token = tok }
    b:Show()
  end
  local cols = math.min(7, #mtokens)
  M.mouseBoard:SetSize(cols * (mw + gap) - gap + 28, 30 + math.ceil(#mtokens / 7) * unit - gap + 14)
end

local function paintKey(b, bg, border, shade)
  W.Paint(b, bg, border)
end

function M.RefreshKeyboard()
  if not M.frame or not M.frame:IsShown() or M.state.view ~= "keyboard" then return end
  local _, byKey, byCmd = D.ReadBindings()
  M.byKey, M.byCmd = byKey, byCmd
  local layer = M.state.heldLayer or M.state.layer
  local q = M.state.kbSearch or ""
  local bound = 0
  local lay = LY.Get(ns.db.layout)
  local function paint(b)
    local tok = b.token
    if not tok then
      W.PaintKey(b, C.keyEmpty, C.border); b.label:SetText(b.spec and b.spec.label or ""); b.action:SetText("")
      b.stripe:Hide(); b.icon:Hide(); b:SetAlpha(0.6); return
    end
    local label = (b.spec and b.spec.label) or LY.KeyLabel(tok)
    b.label:SetText(label)
    local mod = MODMAP[tok]
    if mod then
      local on = layer:find(mod) ~= nil
      W.PaintKey(b, on and C.selBg or C.keyEmpty, on and C.goldDark or C.border)
      b.label:SetTextColor((on and C.goldLight or C.muted)[1], (on and C.goldLight or C.muted)[2], (on and C.goldLight or C.muted)[3])
      b.action:SetText(""); b.stripe:Hide(); b.icon:Hide(); b:SetAlpha(1)
      b.chordLabel, b.desc, b.sub = LY.KeyLabel(tok), nil, nil
      return
    end
    local chord = U.JoinChord(U.CodeToMods(layer), tok)
    local cmd = byKey[chord]
    local e = cmd and byCmd[cmd]
    local desc, sub = describe(e)
    if e then bound = bound + 1 end
    b.chordLabel, b.desc, b.sub = LY.ChordLabel(chord), desc, sub
    local isSel = M.state.sel == tok
    local match = q == "" or (desc and desc:lower():find(q, 1, true)) or (e and e.name:lower():find(q, 1, true))
    if isSel then
      W.PaintKey(b, C.selBg, C.gold)
    elseif q ~= "" and match and e then
      W.PaintKey(b, C.key, C.goldDark)
    else
      W.PaintKey(b, e and C.key or C.keyEmpty, C.border)
    end
    b:SetAlpha((q ~= "" and not (match and e)) and 0.35 or 1)
    local lc = isSel and C.goldLight or (e and C.muted or C.dim)
    b.label:SetTextColor(lc[1], lc[2], lc[3])
    b.action:SetText(desc or "")
    if e then
      local cc = catColor(e.cat); b.stripe:SetVertexColor(cc[1], cc[2], cc[3]); b.stripe:Show()
      local tex = e.slot and D.ActionTexture(e.slot)
      if tex and b:GetWidth() >= 40 then b.icon:SetTexture(tex); b.icon:Show() else b.icon:Hide() end
    else
      b.stripe:Hide(); b.icon:Hide()
    end
  end
  for _, b in ipairs(M.keyButtons) do if b:IsShown() then paint(b) end end
  for _, b in ipairs(M.mouseButtons) do if b:IsShown() then paint(b) end end
  for _, lb in ipairs(M.layerButtons) do lb:SetStyle(lb.code == layer and "active" or "default") end
  M.stats:SetText(L.STATS_LAYER:format(bound, layerName(layer)))
end

---------------------------------------------------------------------------
-- Detail panel (all 8 modifier combinations of the selected key)
---------------------------------------------------------------------------
function M.BuildDetail()
  local p = W.Frame(M.body, C.panel, C.border)
  p:SetPoint("TOPRIGHT"); p:SetPoint("BOTTOMRIGHT"); p:SetWidth(DETAIL_W)
  M.detail = p
  local cap = W.Frame(p, { 0.165, 0.145, 0.098 }, C.gold)
  cap:SetSize(60, 60); cap:SetPoint("TOPLEFT", 22, -20)
  M.capText = W.Text(cap, 18, C.goldLight, "CENTER"); M.capText:SetPoint("CENTER")
  M.capFrame = cap
  M.detTitle = W.Text(p, 16, C.text, "LEFT", true); M.detTitle:SetPoint("TOPLEFT", cap, "TOPRIGHT", 14, -10)
  M.detSub = W.Text(p, 12, C.muted); M.detSub:SetPoint("TOPLEFT", M.detTitle, "BOTTOMLEFT", 0, -6)
  local sep = W.Tex(p, C.border); sep:SetPoint("TOPLEFT", 0, -100); sep:SetPoint("TOPRIGHT", 0, -100); sep:SetHeight(1)
  M.detHint = W.Text(p, 12, C.muted); M.detHint:SetPoint("TOPLEFT", 22, -120); M.detHint:SetPoint("RIGHT", -22, 0)
  M.detHint:SetWordWrap(true); M.detHint:SetText(L.DETAIL_HINT)

  M.detRows = {}
  for i, code in ipairs(COMBOS) do
    local r = W.Frame(p, C.panel2, C.border)
    r:SetHeight(56); r:SetPoint("TOPLEFT", 14, -110 - (i - 1) * 62); r:SetPoint("RIGHT", -14, 0)
    r.code = code
    r.mods = W.Text(r, 11, { 0.81, 0.78, 0.73 }); r.mods:SetPoint("LEFT", 10, 0); r.mods:SetWidth(84); r.mods:SetWordWrap(true)
    r.mods:SetText(code == "" and L.LAYER_NONE or layerName(code))
    r.iconBg = W.Frame(r, { 0.071, 0.067, 0.082 }, C.border); r.iconBg:SetSize(32, 32); r.iconBg:SetPoint("LEFT", 100, 0)
    r.icon = r.iconBg:CreateTexture(nil, "ARTWORK"); r.icon:SetPoint("TOPLEFT", 2, -2); r.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.ini = W.Text(r.iconBg, 13, C.text, "CENTER"); r.ini:SetPoint("CENTER")
    r.name = W.Text(r, 13, C.text); r.name:SetPoint("TOPLEFT", r.iconBg, "TOPRIGHT", 10, -1); r.name:SetPoint("RIGHT", -74, 0)
    r.sub = W.Text(r, 11, C.muted); r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -4); r.sub:SetPoint("RIGHT", -74, 0)
    r.empty = W.Text(r, 12, C.dim); r.empty:SetPoint("LEFT", 100, 0); r.empty:SetText(L.NOT_BOUND)
    r.change = W.Button(r, "...", 30, 30); r.change:SetPoint("RIGHT", -40, 0); r.change.tip = L.CHANGE
    r.remove = W.Button(r, "X", 30, 30); r.remove:SetPoint("RIGHT", -6, 0); r.remove.tip = L.REMOVE
    r.assign = W.Button(r, L.ASSIGN, 100, 30, "dashed"); r.assign:SetPoint("RIGHT", -6, 0)
    local function chord() return U.JoinChord(U.CodeToMods(code), M.state.sel) end
    r.change:SetScript("OnClick", function() M.OpenPicker(chord()) end)
    r.assign:SetScript("OnClick", function() M.OpenPicker(chord()) end)
    r.remove:SetScript("OnClick", function() D.SetKey(chord(), nil); M.Refresh() end)
    M.detRows[i] = r
  end
end

function M.RefreshDetail()
  if not M.detail or not M.detail:IsShown() then return end
  local sel = M.state.sel
  local has = sel ~= nil
  M.detHint:SetShown(not has)
  M.capFrame:SetShown(has); M.detTitle:SetShown(has); M.detSub:SetShown(has)
  for _, r in ipairs(M.detRows) do r:SetShown(has) end
  if not has then return end
  local byKey, byCmd = M.byKey, M.byCmd
  if not byKey then local _; _, byKey, byCmd = D.ReadBindings() end
  local spec
  for _, b in ipairs(M.keyButtons) do if b.token == sel then spec = b.spec end end
  local label = (spec and spec.label) or LY.KeyLabel(sel)
  M.capText:SetText(label)
  M.capFrame:SetWidth(math.max(60, M.capText:GetStringWidth() + 24))
  M.detTitle:SetText(L.KEY_TITLE:format(label))
  local count = 0
  local layer = M.state.heldLayer or M.state.layer
  for _, r in ipairs(M.detRows) do
    local chord = U.JoinChord(U.CodeToMods(r.code), sel)
    local cmd = byKey[chord]
    local e = cmd and byCmd[cmd]
    local cur = r.code == layer
    if e then
      count = count + 1
      local desc, sub = describe(e)
      local cc = catColor(e.cat)
      r.name:SetText(desc); r.sub:SetText(sub or "")
      r.iconBg:SetBackdropBorderColor(cc[1], cc[2], cc[3])
      local tex = e.slot and D.ActionTexture(e.slot)
      if tex then r.icon:SetTexture(tex); r.icon:Show(); r.ini:SetText("") else r.icon:Hide(); r.ini:SetText((desc or "?"):sub(1, 1)); r.ini:SetTextColor(cc[1], cc[2], cc[3]) end
      W.Paint(r, cur and { 0.149, 0.133, 0.102 } or C.panel2, cur and C.goldDark or C.border)
    else
      W.Paint(r, C.panel, cur and C.goldDark or { 0.165, 0.157, 0.188 })
    end
    r.iconBg:SetShown(e ~= nil); r.name:SetShown(e ~= nil); r.sub:SetShown(e ~= nil)
    r.change:SetShown(e ~= nil); r.remove:SetShown(e ~= nil)
    r.empty:SetShown(e == nil); r.assign:SetShown(e == nil)
  end
  M.detSub:SetText(L.COMBOS_BOUND:format(count))
end

---------------------------------------------------------------------------
-- Action picker
---------------------------------------------------------------------------
function M.OpenPicker(chord)
  local pk = M.picker
  if not pk then
    pk = W.Frame(M.frame, C.panel, C.goldDark)
    pk:SetSize(460, 520); pk:SetPoint("CENTER"); pk:SetFrameLevel(M.frame:GetFrameLevel() + 40)
    pk:EnableMouse(true)
    pk.title = W.Text(pk, 15, C.gold, "LEFT", true); pk.title:SetPoint("TOPLEFT", 18, -16)
    local x = W.Button(pk, "X", 28, 28, "ghost"); x:SetPoint("TOPRIGHT", -10, -10); x:SetScript("OnClick", function() pk:Hide() end)
    pk.search = W.Edit(pk, 424, L.SEARCH_LIST); pk.search:SetPoint("TOPLEFT", 18, -48)
    pk.search.edit:HookScript("OnTextChanged", function() pk.offset = 0; M.RefreshPicker() end)
    pk.rows = {}
    for i = 1, 10 do
      local r = CreateFrame("Button", nil, pk, "BackdropTemplate")
      r:SetSize(424, 40); r:SetPoint("TOPLEFT", 18, -90 - (i - 1) * 42)
      r.name = W.Text(r, 12, C.text); r.name:SetPoint("TOPLEFT", 12, -6); r.name:SetPoint("RIGHT", -10, 0)
      r.sub = W.Text(r, 10, C.muted); r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3); r.sub:SetPoint("RIGHT", -10, 0)
      r:SetScript("OnEnter", function(self) W.Paint(self, C.selBg, C.goldDark) end)
      r:SetScript("OnLeave", function(self) W.Paint(self, C.panel2, C.border) end)
      r:SetScript("OnClick", function(self)
        if self.cmd then D.SetKey(pk.chord, self.cmd); pk:Hide(); M.Refresh() end
      end)
      W.Paint(r, C.panel2, C.border)
      pk.rows[i] = r
    end
    pk:EnableMouseWheel(true)
    pk:SetScript("OnMouseWheel", function(_, d) pk.offset = math.max(0, (pk.offset or 0) - d * 3); M.RefreshPicker() end)
    M.picker = pk
  end
  pk.chord, pk.offset = chord, 0
  pk.title:SetText(L.PICK_ACTION:format(LY.ChordLabel(chord)))
  pk.search.edit:SetText("")
  pk:Show()
  M.RefreshPicker()
  pk.search.edit:SetFocus()
end

function M.RefreshPicker()
  local pk = M.picker
  local commands = D.ReadBindings()
  local q = pk.search.edit:GetText():lower()
  local list = {}
  for _, e in ipairs(commands) do
    local desc, sub = describe(e)
    local hay = (desc or "") .. " " .. e.name .. " " .. (sub or "")
    if q == "" or hay:lower():find(q, 1, true) then list[#list + 1] = { e = e, desc = desc, sub = sub } end
  end
  pk.offset = math.min(pk.offset or 0, math.max(0, #list - #pk.rows))
  for i, r in ipairs(pk.rows) do
    local it = list[i + pk.offset]
    if it then
      r.cmd = it.e.cmd
      r.name:SetText(it.desc ~= it.e.name and (it.desc .. "  |cffa39c8f(" .. it.e.name .. ")|r") or it.desc)
      r.sub:SetText(it.sub or "")
      r:Show()
    else
      r.cmd = nil; r:Hide()
    end
  end
end

---------------------------------------------------------------------------
-- List view
---------------------------------------------------------------------------
local ROW_H, VISIBLE = 44, 13

function M.BuildListView()
  local v = CreateFrame("Frame", nil, M.body)
  v:SetAllPoints()
  M.listView = v
  local side = W.Frame(v, C.panel, C.border)
  side:SetPoint("TOPLEFT"); side:SetPoint("BOTTOMLEFT"); side:SetWidth(240)
  local t = W.Text(side, 10, C.muted); t:SetPoint("TOPLEFT", 22, -20); t:SetText(L.CATEGORIES:upper())
  M.catButtons = {}
  local cats = { "ALL" }
  for _, c in ipairs(CAT_ORDER) do cats[#cats + 1] = c end
  for i, cat in ipairs(cats) do
    local b = CreateFrame("Button", nil, side, "BackdropTemplate")
    b:SetSize(216, 36); b:SetPoint("TOPLEFT", 12, -40 - (i - 1) * 38)
    b.sw = W.Tex(b, cat == "ALL" and C.text or catColor(cat)); b.sw:SetSize(4, 16); b.sw:SetPoint("LEFT", 10, 0)
    b.name = W.Text(b, 12); b.name:SetPoint("LEFT", 22, 0); b.name:SetText(cat == "ALL" and L.CAT_ALL or L[CAT_LABEL[cat]])
    b.count = W.Text(b, 11, C.muted, "RIGHT"); b.count:SetPoint("RIGHT", -10, 0)
    b.cat = cat
    b:SetScript("OnClick", function() M.state.cat = cat; M.state.offset = 0; M.RefreshList() end)
    M.catButtons[#M.catButtons + 1] = b
  end
  M.listSummary = W.Text(side, 11, C.muted); M.listSummary:SetPoint("BOTTOMLEFT", 22, 18); M.listSummary:SetPoint("RIGHT", -16, 0)
  M.listSummary:SetWordWrap(true); M.listSummary:SetJustifyV("BOTTOM")

  local main = CreateFrame("Frame", nil, v)
  main:SetPoint("TOPLEFT", side, "TOPRIGHT", 24, -18); main:SetPoint("BOTTOMRIGHT", -24, 14)
  local search = W.Edit(main, 600, L.SEARCH_LIST); search:SetPoint("TOPLEFT"); search:SetPoint("RIGHT")
  search:SetHeight(36)
  search.edit:HookScript("OnTextChanged", function(self) M.state.search = self:GetText():lower(); M.state.offset = 0; M.RefreshList() end)
  M.chips = {}
  local prev
  for _, fl in ipairs({ { "all", L.CAT_ALL }, { "bound", L.FILTER_BOUND }, { "unbound", L.FILTER_UNBOUND }, { "changed", L.FILTER_CHANGED } }) do
    local b = W.Button(main, fl[2], 20, 28)
    b:SetWidth(b.text:GetStringWidth() + 28)
    if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", 0, -46) end
    b.key = fl[1]
    b:SetScript("OnClick", function() M.state.filter = fl[1]; M.state.offset = 0; M.RefreshList() end)
    M.chips[#M.chips + 1] = b
    prev = b
  end

  local tbl = W.Frame(main, C.panel, C.border)
  tbl:SetPoint("TOPLEFT", 0, -86); tbl:SetPoint("BOTTOMRIGHT", 0, 26)
  local head = CreateFrame("Frame", nil, tbl); head:SetPoint("TOPLEFT"); head:SetPoint("TOPRIGHT"); head:SetHeight(32)
  local function col(text, x) local fs = W.Text(head, 10, C.muted); fs:SetPoint("LEFT", x, 0); fs:SetText(text:upper()) end
  col(L.COL_ACTION, 56); col(L.COL_KEY1, 560); col(L.COL_KEY2, 720)
  local hl = W.Tex(tbl, C.border); hl:SetPoint("TOPLEFT", 0, -32); hl:SetPoint("TOPRIGHT", 0, -32); hl:SetHeight(1)
  M.listRows = {}
  for i = 1, VISIBLE do
    local r = CreateFrame("Frame", nil, tbl, "BackdropTemplate")
    r:SetHeight(ROW_H); r:SetPoint("TOPLEFT", 1, -33 - (i - 1) * ROW_H); r:SetPoint("RIGHT", -10, 0)
    r.hdrStripe = W.Tex(r); r.hdrStripe:SetSize(4, 14); r.hdrStripe:SetPoint("LEFT", 16, 0)
    r.hdrText = W.Text(r, 13, C.text, "LEFT", true); r.hdrText:SetPoint("LEFT", 28, 0)
    r.iconBg = W.Frame(r, { 0.071, 0.067, 0.082 }, C.border); r.iconBg:SetSize(30, 30); r.iconBg:SetPoint("LEFT", 14, 0)
    r.icon = r.iconBg:CreateTexture(nil, "ARTWORK"); r.icon:SetPoint("TOPLEFT", 2, -2); r.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.ini = W.Text(r.iconBg, 12, C.text, "CENTER"); r.ini:SetPoint("CENTER")
    r.name = W.Text(r, 13, C.text); r.name:SetPoint("TOPLEFT", 56, -6); r.name:SetWidth(480)
    r.sub = W.Text(r, 11, C.muted); r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3); r.sub:SetWidth(480)
    r.keys = {}
    for k = 1, 2 do
      local kb = W.Button(r, "", 148, 30)
      kb:SetPoint("LEFT", k == 1 and 556 or 716, 0)
      kb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      kb:SetScript("OnClick", function(self, btn)
        if not r.e then return end
        if btn == "RightButton" then
          if self.chord then D.SetKey(self.chord, nil); M.Refresh() end
        else
          M.StartCapture(r.e.cmd, self.chord, self)
        end
      end)
      r.keys[k] = kb
    end
    r.status = W.Text(r, 11, C.muted); r.status:SetPoint("LEFT", 880, 0)
    M.listRows[i] = r
  end
  tbl:EnableMouseWheel(true)
  tbl:SetScript("OnMouseWheel", function(_, d) M.state.offset = math.max(0, M.state.offset - d * 3); M.RefreshList() end)
  M.scrollInfo = W.Text(main, 11, C.muted, "RIGHT"); M.scrollInfo:SetPoint("BOTTOMRIGHT", 0, 4)
  local hint = W.Text(main, 11, C.muted); hint:SetPoint("BOTTOMLEFT", 0, 4); hint:SetPoint("RIGHT", M.scrollInfo, "LEFT", -12, 0)
  hint:SetText(L.CAPTURE_HINT)
end

local function matches(e, desc, sub, q)
  if q == "" then return true end
  local hay = ((desc or "") .. " " .. e.name .. " " .. (sub or "")):lower()
  if hay:find(q, 1, true) then return true end
  local qq = q:gsub("%s", "")
  for _, k in ipairs(e.keys) do
    if LY.ChordLabel(k):lower():gsub("%s", ""):find(qq, 1, true) or k:lower():gsub("%-", "+"):find(qq, 1, true) then return true end
  end
  return false
end

function M.RefreshList()
  if not M.listView or not M.listView:IsShown() then return end
  local commands = D.ReadBindings()
  local counts, total, boundN = { ALL = 0 }, 0, 0
  local items, lastHeader = {}, nil
  local st = M.state
  for _, e in ipairs(commands) do
    counts[e.cat] = (counts[e.cat] or 0) + 1; counts.ALL = counts.ALL + 1
    if #e.keys > 0 then boundN = boundN + 1 end
    total = total + 1
    if st.cat == "ALL" or st.cat == e.cat then
      local desc, sub = describe(e)
      local ok = matches(e, desc, sub, st.search)
      if ok and st.filter == "bound" then ok = #e.keys > 0 end
      if ok and st.filter == "unbound" then ok = #e.keys == 0 end
      if ok and st.filter == "changed" then ok = ns.changed[e.cmd] end
      if ok then
        local h = e.header ~= "" and e.header or L[CAT_LABEL[e.cat]]
        if h ~= lastHeader then items[#items + 1] = { header = h, cat = e.cat }; lastHeader = h end
        items[#items + 1] = { e = e, desc = desc, sub = sub }
      end
    end
  end
  for _, b in ipairs(M.catButtons) do
    b.count:SetText(counts[b.cat] or 0)
    W.Paint(b, b.cat == st.cat and C.selBg or C.panel, b.cat == st.cat and C.selBg or C.panel)
    local c = b.cat == st.cat and C.goldLight or { 0.81, 0.78, 0.73 }
    b.name:SetTextColor(c[1], c[2], c[3])
  end
  for _, c in ipairs(M.chips) do c:SetStyle(c.key == st.filter and "active" or "default") end
  M.listSummary:SetText(("%s: %d\n%s: %d"):format(L.FILTER_BOUND, boundN, L.FILTER_UNBOUND, total - boundN))
  st.offset = math.min(st.offset, math.max(0, #items - VISIBLE))
  for i, r in ipairs(M.listRows) do
    local it = items[i + st.offset]
    r.e = it and it.e
    if not it then r:Hide()
    else
      r:Show()
      local isH = it.header ~= nil
      r.hdrStripe:SetShown(isH); r.hdrText:SetShown(isH)
      r.iconBg:SetShown(not isH); r.name:SetShown(not isH); r.sub:SetShown(not isH); r.status:SetShown(not isH)
      r.keys[1]:SetShown(not isH); r.keys[2]:SetShown(not isH)
      if isH then
        W.Paint(r, { 0.090, 0.086, 0.102 }, { 0.090, 0.086, 0.102 })
        local cc = catColor(it.cat); r.hdrStripe:SetVertexColor(cc[1], cc[2], cc[3])
        r.hdrText:SetText(it.header)
      else
        local e = it.e
        local capturing = M.captureCmd == e.cmd
        W.Paint(r, capturing and { 0.129, 0.118, 0.090 } or C.panel, C.panel)
        local cc = catColor(e.cat)
        r.iconBg:SetBackdropBorderColor(cc[1], cc[2], cc[3])
        local tex = e.slot and D.ActionTexture(e.slot)
        if tex then r.icon:SetTexture(tex); r.icon:Show(); r.ini:SetText("")
        else r.icon:Hide(); r.ini:SetText((it.desc or "?"):sub(1, 1)); r.ini:SetTextColor(cc[1], cc[2], cc[3]) end
        r.name:SetText(it.desc); r.sub:SetText(it.sub or "")
        for k = 1, 2 do
          local kb, chord = r.keys[k], e.keys[k]
          kb.chord = chord
          if capturing and M.captureButton == kb then
            kb.text:SetText(L.PRESS_KEY); kb:SetStyle("active")
          elseif chord then
            kb.text:SetText(LY.ChordLabel(chord)); kb:SetStyle("default")
          else
            kb.text:SetText(L.ADD_KEY); kb:SetStyle("dashed")
          end
        end
        if ns.changed[e.cmd] then
          r.status:SetText(L.FILTER_CHANGED); r.status:SetTextColor(C.goldLight[1], C.goldLight[2], C.goldLight[3])
        elseif #e.keys > 0 then
          r.status:SetText(L.FILTER_BOUND); r.status:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
        else
          r.status:SetText(L.NOT_BOUND); r.status:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
        end
      end
    end
  end
  M.scrollInfo:SetText(#items > 0 and ("%d-%d / %d"):format(st.offset + 1, math.min(#items, st.offset + VISIBLE), #items) or "")
end

---------------------------------------------------------------------------
-- Key capture
---------------------------------------------------------------------------
local IGNORE = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, LMETA = true, RMETA = true }
local MOUSE = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

function M.BuildCapture()
  local c = CreateFrame("Button", nil, M.frame)
  c:SetAllPoints(M.frame)
  c:SetFrameLevel(M.frame:GetFrameLevel() + 60)
  c:EnableMouse(true); c:EnableMouseWheel(true); c:EnableKeyboard(true)
  c:RegisterForClicks("AnyUp")
  c:Hide()
  local function finish(token)
    local cmd, old = M.captureCmd, M.captureOld
    M.StopCapture()
    if not token then return end
    local chord = U.JoinChord({ ALT = IsAltKeyDown(), CTRL = IsControlKeyDown(), SHIFT = IsShiftKeyDown() }, token)
    if old and old ~= chord then D.SetKey(old, nil) end
    D.SetKey(chord, cmd)
    M.Refresh()
  end
  c:SetScript("OnKeyDown", function(self, key)
    if IGNORE[key] then return end
    if key == "ESCAPE" then M.StopCapture(); return end
    finish(key)
  end)
  c:SetScript("OnMouseDown", function(self, btn)
    local tok = MOUSE[btn] or btn:match("^Button(%d+)$") and ("BUTTON" .. btn:match("(%d+)"))
    if tok then finish(tok) else M.StopCapture() end
  end)
  c:SetScript("OnMouseWheel", function(_, d) finish(d > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
  M.capture = c
end

function M.StartCapture(cmd, oldChord, button)
  if InCombatLockdown() then U.Print(L.IN_COMBAT); return end
  M.captureCmd, M.captureOld, M.captureButton = cmd, oldChord, button
  M.capture:Show()
  M.RefreshList()
end

function M.StopCapture()
  M.captureCmd, M.captureOld, M.captureButton = nil, nil, nil
  M.capture:Hide()
  M.RefreshList()
end

---------------------------------------------------------------------------
function M.RefreshHeader()
  if not M.frame then return end
  local info = D.PlayerSpec()
  local r, g, b = D.ClassColor(info.class)
  M.profileButton.dot:SetVertexColor(r, g, b)
  M.profileButton.name:SetText(D.SpecLabel(info))
  local n = ns.pending or 0
  M.pendText:SetText(n > 0 and L.PENDING:format(n) or L.NO_PENDING)
  M.pendDot:SetShown(n > 0)
  M.setText:SetText(L.SAVE_AS:format(D.BindingSet() == 2 and L.SET_CHARACTER or L.SET_ACCOUNT))
  M.applyBtn:SetDisabled(n == 0); M.discardBtn:SetDisabled(n == 0)
end

function M.Refresh()
  if not M.frame or not M.frame:IsShown() then return end
  M.RefreshHeader()
  if M.state.view == "keyboard" then M.RefreshKeyboard(); M.RefreshDetail() else M.RefreshList() end
end

function M.ApplyScale()
  if M.frame then M.frame:SetScale(ns.db.scale or 0.9) end
end

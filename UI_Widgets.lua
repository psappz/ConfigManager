local ADDON, ns = ...
local U = ns.U
local C = U.COLORS
local W = {}
ns.W = W

local WHITE = "Interface\\Buttons\\WHITE8X8"

function W.BodyFont() return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" end
function W.TitleFont()
  local f = GameFontNormalLarge and GameFontNormalLarge:GetFont()
  return f or "Fonts\\FRIZQT__.TTF"
end

function W.Paint(frame, bg, border, alpha)
  if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
  frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
  bg = bg or C.panel
  border = border or C.border
  frame:SetBackdropColor(bg[1], bg[2], bg[3], alpha or 1)
  frame:SetBackdropBorderColor(border[1], border[2], border[3], 1)
end

function W.Frame(parent, bg, border, alpha)
  local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  W.Paint(f, bg, border, alpha)
  return f
end

function W.Text(parent, size, color, justify, title)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(title and W.TitleFont() or W.BodyFont(), size or 12, "")
  color = color or C.text
  fs:SetTextColor(color[1], color[2], color[3])
  fs:SetJustifyH(justify or "LEFT")
  fs:SetWordWrap(false)
  return fs
end

function W.Tex(parent, color, layer)
  local t = parent:CreateTexture(nil, layer or "ARTWORK")
  t:SetTexture(WHITE)
  if color then t:SetVertexColor(color[1], color[2], color[3], color[4] or 1) end
  return t
end

-- style: "primary" (gold), "default", "ghost", "dashed"
function W.Button(parent, text, w, h, style)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(w or 110, h or 32)
  b.text = W.Text(b, 12, nil, "CENTER")
  b.text:SetPoint("CENTER")
  b.text:SetText(text or "")
  b.style = style or "default"
  function b:Refresh()
    local s = self.style
    if self.disabled then
      W.Paint(self, C.panel, C.border); self.text:SetTextColor(C.dim[1], C.dim[2], C.dim[3]); return
    end
    if s == "primary" then
      W.Paint(self, self.hover and C.goldLight or C.gold, C.gold)
      self.text:SetTextColor(0.10, 0.086, 0.055)
    elseif s == "active" then
      W.Paint(self, C.selBg, C.gold); self.text:SetTextColor(C.goldLight[1], C.goldLight[2], C.goldLight[3])
    elseif s == "ghost" then
      W.Paint(self, self.hover and C.panel2 or C.panel, C.border, self.hover and 1 or 0)
      self.text:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
    elseif s == "dashed" then
      W.Paint(self, C.panel, C.goldDark, 0); self.text:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    else
      W.Paint(self, self.hover and C.panel2 or { 0.071, 0.067, 0.082 }, C.border)
      self.text:SetTextColor(C.text[1], C.text[2], C.text[3])
    end
  end
  function b:SetStyle(st) self.style = st; self:Refresh() end
  function b:SetDisabled(v) self.disabled = v; self:SetEnabled(not v); self:Refresh() end
  b:SetScript("OnEnter", function(self)
    self.hover = true; self:Refresh()
    if self.tip then GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(self.tip, 1, 1, 1, 1, true); GameTooltip:Show() end
  end)
  b:SetScript("OnLeave", function(self) self.hover = false; self:Refresh(); GameTooltip:Hide() end)
  b:Refresh()
  return b
end

function W.Check(parent, text, get, set)
  local b = CreateFrame("Button", nil, parent)
  b:SetHeight(24)
  local box = W.Frame(b, { 0.071, 0.067, 0.082 }, C.border)
  box:SetSize(16, 16); box:SetPoint("LEFT")
  local mark = W.Tex(box, C.gold); mark:SetPoint("TOPLEFT", 3, -3); mark:SetPoint("BOTTOMRIGHT", -3, 3)
  local fs = W.Text(b, 12, C.text); fs:SetPoint("LEFT", box, "RIGHT", 8, 0); fs:SetText(text)
  b:SetWidth(fs:GetStringWidth() + 30)
  b.label = fs
  function b:Refresh() mark:SetShown(get() and true or false) end
  b:SetScript("OnClick", function(self) set(not get()); self:Refresh() end)
  b:Refresh()
  return b
end

-- "<  value  >" selector. values = list of { value, text }
function W.Cycle(parent, width, values, get, set)
  local f = W.Frame(parent, { 0.071, 0.067, 0.082 }, C.border)
  f:SetSize(width or 260, 32)
  local txt = W.Text(f, 12, C.text, "CENTER"); txt:SetPoint("LEFT", 30, 0); txt:SetPoint("RIGHT", -30, 0)
  local function idx()
    local cur = get()
    for i, v in ipairs(values) do if v[1] == cur then return i end end
    return 1
  end
  local function step(d)
    local i = idx() + d
    if i < 1 then i = #values elseif i > #values then i = 1 end
    set(values[i][1]); f:Refresh()
  end
  local prev = W.Button(f, "<", 26, 26, "ghost"); prev:SetPoint("LEFT", 3, 0); prev:SetScript("OnClick", function() step(-1) end)
  local nxt = W.Button(f, ">", 26, 26, "ghost"); nxt:SetPoint("RIGHT", -3, 0); nxt:SetScript("OnClick", function() step(1) end)
  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function(_, d) step(d > 0 and -1 or 1) end)
  function f:Refresh() txt:SetText(values[idx()][2]) end
  f.values = values
  f:Refresh()
  return f
end

function W.Edit(parent, width, placeholder)
  local holder = W.Frame(parent, { 0.071, 0.067, 0.082 }, C.border)
  holder:SetSize(width or 240, 32)
  local e = CreateFrame("EditBox", nil, holder)
  e:SetPoint("LEFT", 10, 0); e:SetPoint("RIGHT", -10, 0); e:SetHeight(24)
  e:SetFont(W.BodyFont(), 12, ""); e:SetTextColor(C.text[1], C.text[2], C.text[3])
  e:SetAutoFocus(false)
  e:SetScript("OnEscapePressed", e.ClearFocus)
  e:SetScript("OnEnterPressed", e.ClearFocus)
  local ph = W.Text(holder, 12, C.dim); ph:SetPoint("LEFT", 10, 0); ph:SetText(placeholder or "")
  e:HookScript("OnTextChanged", function(self) ph:SetShown(self:GetText() == "") end)
  e:HookScript("OnEditFocusGained", function() holder:SetBackdropBorderColor(C.goldDark[1], C.goldDark[2], C.goldDark[3]) end)
  e:HookScript("OnEditFocusLost", function() holder:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3]) end)
  holder.edit, holder.placeholder = e, ph
  return holder
end

-- Multi-line edit box in a scroll frame.
function W.MultiEdit(parent)
  local holder = W.Frame(parent, { 0.059, 0.055, 0.071 }, C.border)
  local sf = CreateFrame("ScrollFrame", nil, holder, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 8, -8); sf:SetPoint("BOTTOMRIGHT", -28, 8)
  local e = CreateFrame("EditBox", nil, sf)
  e:SetMultiLine(true); e:SetAutoFocus(false); e:SetMaxLetters(0)
  e:SetFont("Fonts\\ARIALN.TTF", 12, ""); e:SetTextColor(C.text[1], C.text[2], C.text[3])
  e:SetWidth(400)
  sf:SetScrollChild(e)
  sf:SetScript("OnSizeChanged", function(self, w) e:SetWidth(math.max(50, w)) end)
  e:SetScript("OnEscapePressed", e.ClearFocus)
  holder:EnableMouse(true)
  holder:SetScript("OnMouseDown", function() e:SetFocus() end)
  holder.edit, holder.scroll = e, sf
  return holder
end

-- Simple popup menu. items: { text=, func=, disabled=, title=, color= }
local menu
function W.Menu(owner, items)
  if not menu then
    menu = W.Frame(UIParent, C.panel, C.border)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:EnableMouse(true)
    menu.rows = {}
    menu:SetScript("OnHide", function(self) self.owner = nil end)
    menu.catcher = CreateFrame("Button", nil, UIParent)
    menu.catcher:SetAllPoints(UIParent); menu.catcher:SetFrameStrata("FULLSCREEN")
    menu.catcher:EnableMouse(true)
    menu.catcher:RegisterForClicks("AnyUp")
    menu.catcher:SetScript("OnClick", function() menu:Hide() end)
    menu.catcher:Hide()
    menu:HookScript("OnHide", function() menu.catcher:Hide() end)
    menu:Hide()
    W._menu = menu
  end
  if menu:IsShown() and menu.owner == owner then menu:Hide(); return end
  for _, r in ipairs(menu.rows) do r:Hide() end
  local width, y = 220, -6
  for i, it in ipairs(items) do
    local r = menu.rows[i]
    if not r then
      r = CreateFrame("Button", nil, menu)
      r:SetHeight(26)
      r.hl = W.Tex(r, { 1, 1, 1, 0.06 }, "BACKGROUND"); r.hl:SetAllPoints(); r.hl:Hide()
      r.text = W.Text(r, 12); r.text:SetPoint("LEFT", 10, 0); r.text:SetPoint("RIGHT", -10, 0)
      r:SetScript("OnEnter", function(self) if not self.inert then self.hl:Show() end end)
      r:SetScript("OnLeave", function(self) self.hl:Hide() end)
      menu.rows[i] = r
    end
    r.text:SetText(it.text)
    r.inert = it.title or it.disabled
    local col = it.title and C.muted or (it.disabled and C.dim) or it.color or C.text
    r.text:SetTextColor(col[1], col[2], col[3])
    r.text:SetFont(W.BodyFont(), it.title and 10 or 12, "")
    r:SetScript("OnClick", function() if not r.inert then menu:Hide(); if it.func then it.func() end end end)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 4, y); r:SetPoint("TOPRIGHT", -4, y)
    r:Show()
    width = math.max(width, r.text:GetStringWidth() + 30)
    y = y - 26
  end
  menu:SetSize(width, -y + 6)
  menu:ClearAllPoints()
  menu:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -4)
  menu.owner = owner
  menu.catcher:Show()
  menu:Show()
end

function W.CloseMenu()
  if menu and menu:IsShown() then menu:Hide() end
end

-- Escape closes the frame without UISpecialFrames (which would let addon code run
-- inside Blizzard's Escape handling). In combat the key is always passed on.
function W.EscClose(frame)
  frame:EnableKeyboard(true)
  if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(true) end
  frame:SetScript("OnKeyDown", function(self, key)
    if InCombatLockdown() then return end
    if key == "ESCAPE" then
      if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
      self:Hide()
    elseif self.SetPropagateKeyboardInput then
      self:SetPropagateKeyboardInput(true)
    end
  end)
  frame:HookScript("OnShow", function(self)
    if self.SetPropagateKeyboardInput and not InCombatLockdown() then self:SetPropagateKeyboardInput(true) end
  end)
end


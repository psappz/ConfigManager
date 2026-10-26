local ADDON, ns = ...
local U, LY, D, W = ns.U, ns.Layouts, ns.Data, ns.W
local C = U.COLORS
local L = ns.L
local DL = ns.Dialogs

local PREVIEW_W, PREVIEW_H = 848, 262
local SIZES = { { "full", "SIZE_FULL" }, { "tkl", "SIZE_TKL" }, { "60", "SIZE_60" } }

---------------------------------------------------------------------------
-- "Which keyboard do you use?" – shown until the player has confirmed one.
-- Nothing is preselected: client language and region are no hint.
---------------------------------------------------------------------------
function DL.ShowKeyboardPrompt(onDone)
  local f = DL.kb
  if not f then
    f = DL.Dialog("ConfigManagerKeyboardFrame", 900, 790, L.KB_TITLE)
    DL.kb = f
    local intro = W.Text(f, 13, { 0.81, 0.78, 0.73 }); intro:SetPoint("TOPLEFT", 26, -58); intro:SetPoint("RIGHT", -26, 0)
    intro:SetWordWrap(true); intro:SetText(L.KB_TEXT)
    local s1 = W.Text(f, 10, C.muted); s1:SetPoint("TOPLEFT", 26, -104); s1:SetText(L.KB_LAYOUT:upper())
    f.layoutButtons = {}
    for i, lay in ipairs(LY.list) do
      local b = W.Button(f, lay.name, 205, 30)
      b:SetPoint("TOPLEFT", 26 + ((i - 1) % 4) * 212, -122 - math.floor((i - 1) / 4) * 36)
      b.text:SetFont(W.BodyFont(), 11, "")
      b:SetScript("OnClick", function() f.layout = lay.id; DL.RefreshKeyboardPrompt() end)
      b.id = lay.id
      f.layoutButtons[i] = b
    end
    local rowsY = -122 - math.ceil(#LY.list / 4) * 36 - 14
    local s2 = W.Text(f, 10, C.muted); s2:SetPoint("TOPLEFT", 26, rowsY); s2:SetText(L.KB_SIZE:upper())
    f.sizeButtons = {}
    for i, sz in ipairs(SIZES) do
      local b = W.Button(f, L[sz[2]], 270, 30)
      b:SetPoint("TOPLEFT", 26 + (i - 1) * 284, rowsY - 18)
      b:SetScript("OnClick", function() f.size = sz[1]; DL.RefreshKeyboardPrompt() end)
      b.id = sz[1]
      f.sizeButtons[i] = b
    end
    local s3 = W.Text(f, 10, C.muted); s3:SetPoint("TOPLEFT", 26, rowsY - 66); s3:SetText(L.KB_CHECK:upper())
    f.preview = W.Frame(f, C.panel, C.border)
    f.preview:SetPoint("TOPLEFT", 26, rowsY - 84); f.preview:SetPoint("RIGHT", -26, 0); f.preview:SetHeight(PREVIEW_H)
    f.caps = {}
    f.hint = W.Text(f, 11, C.muted); f.hint:SetPoint("BOTTOMRIGHT", f.preview, "TOPRIGHT", 0, 6); f.hint:SetJustifyH("RIGHT")
    f.ok = W.Button(f, L.KB_CONFIRM, 220, 36, "primary"); f.ok:SetPoint("BOTTOMRIGHT", -26, 20)
    f.ok:SetScript("OnClick", function()
      if not (f.layout and f.size) then return end
      ns.db.layout, ns.db.size, ns.db.keyboardConfirmed = f.layout, f.size, true
      f:Hide()
      if ns.Main and ns.Main.frame then ns.Main.RebuildKeyboard(); ns.Main.Refresh() end
      if DL.settings and DL.settings:IsShown() then DL.settings.layout:Refresh(); DL.settings.size:Refresh() end
      local cb = f.onDone; f.onDone = nil
      if cb then ns.SafeCall("keyboard", cb) end
    end)
    f.later = W.Button(f, L.KB_LATER, 140, 36); f.later:SetPoint("RIGHT", f.ok, "LEFT", -8, 0)
    f.later:SetScript("OnClick", function() f:Hide() end)
  end
  f.layout = LY.IsChosen(ns.db.layout) and ns.db.layout or nil
  f.size = ns.db.keyboardConfirmed and ns.db.size or nil
  f.onDone = onDone
  f:SetScale(ns.db.scale or 0.9)
  f:Show()
  DL.RefreshKeyboardPrompt()
end

function DL.RefreshKeyboardPrompt()
  local f = DL.kb
  for _, b in ipairs(f.layoutButtons) do b:SetStyle(b.id == f.layout and "active" or "default") end
  for _, b in ipairs(f.sizeButtons) do b:SetStyle(b.id == f.size and "active" or "default") end
  local lay = f.layout and LY.byId[f.layout]
  for _, k in ipairs(f.caps) do k:Hide() end
  if lay then
    -- same geometry as the keyboard view: F-row, modifiers, navigation block and
    -- numpad follow the chosen size (full size while no size is picked yet)
    local keys, width, rows = LY.BuildKeys(f.layout, f.size or "full")
    local unit = math.floor(math.min((PREVIEW_W - 28) / width, (PREVIEW_H - 40) / rows))
    for i, key in ipairs(keys) do
      local k = f.caps[i]
      if not k then
        k = W.Frame(f.preview, C.key, C.border)
        k.t = W.Text(k, 11, C.text, "CENTER"); k.t:SetPoint("LEFT", 2, 0); k.t:SetPoint("RIGHT", -2, 0)
        f.caps[i] = k
      end
      k:SetSize(key.w * unit - 3, key.h * unit - 3)
      k:ClearAllPoints(); k:SetPoint("TOPLEFT", 14 + key.x * unit, -12 - key.y * unit)
      local label = key.label or (key.token and LY.KeyLabel(key.token)) or ""
      k.t:SetText(label)
      k.t:SetFont(W.BodyFont(), (#label > 3 or key.w > 1.4) and 9 or 12, "")
      local isLetter = key.pos ~= nil
      W.Paint(k, isLetter and C.key or C.keyEmpty, C.border)
      local col = isLetter and C.text or C.muted
      k.t:SetTextColor(col[1], col[2], col[3])
      k:Show()
    end
  end
  f.hint:SetText(lay and L.KB_HINT or L.KB_PICK)
  f.ok:SetDisabled(not (f.layout and f.size))
end

local ADDON, ns = ...
local U, LY, D, W = ns.U, ns.Layouts, ns.Data, ns.W
local C = U.COLORS
local L = ns.L
local DL = ns.Dialogs

-- Rows of the chosen layout as the player sees them on the physical keys
local ROWS = {
  { "E00", "E01", "E02", "E03", "E04", "E05", "E06", "E07", "E08", "E09", "E10", "E11", "E12" },
  { "D01", "D02", "D03", "D04", "D05", "D06", "D07", "D08", "D09", "D10", "D11", "D12" },
  { "C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10", "C11", "C12" },
  { "B00", "B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B09", "B10" },
}
local SIZES = { { "full", "SIZE_FULL" }, { "tkl", "SIZE_TKL" }, { "60", "SIZE_60" } }

---------------------------------------------------------------------------
-- "Which keyboard do you use?" – shown until the player has confirmed one.
-- Nothing is preselected: client language and region are no hint.
---------------------------------------------------------------------------
function DL.ShowKeyboardPrompt(onDone)
  local f = DL.kb
  if not f then
    f = DL.Dialog("ConfigManagerKeyboardFrame", 900, 660, L.KB_TITLE)
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
    f.preview:SetPoint("TOPLEFT", 26, rowsY - 84); f.preview:SetPoint("RIGHT", -26, 0); f.preview:SetHeight(150)
    f.caps = {}
    for r, row in ipairs(ROWS) do
      for c, pos in ipairs(row) do
        local k = W.Frame(f.preview, C.key, C.border)
        k:SetSize(36, 30)
        k:SetPoint("TOPLEFT", 14 + (r - 1) * 18 + (c - 1) * 40 + (pos == "B00" and 0 or 0), -10 - (r - 1) * 34)
        k.t = W.Text(k, 13, C.text, "CENTER"); k.t:SetPoint("CENTER")
        k.pos = pos
        f.caps[#f.caps + 1] = k
      end
    end
    f.hint = W.Text(f.preview, 11, C.muted); f.hint:SetPoint("BOTTOMRIGHT", -14, 10); f.hint:SetJustifyH("RIGHT")
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
  for _, k in ipairs(f.caps) do
    local tok = lay and (lay.labels[k.pos] or lay.tok[k.pos])
    k:SetShown(lay ~= nil and tok ~= nil)
    if tok then k.t:SetText(tok) end
  end
  f.hint:SetText(lay and L.KB_HINT or L.KB_PICK)
  f.ok:SetDisabled(not (f.layout and f.size))
end

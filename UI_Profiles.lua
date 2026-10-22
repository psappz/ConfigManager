local ADDON, ns = ...
local U, D, W = ns.U, ns.Data, ns.W
local C = U.COLORS
local L = ns.L
local DL = ns.Dialogs

local VISIBLE, ROW_H = 10, 46
local TYPE_LABEL = { spec = "TYPE_SPEC", backup = "TYPE_BACKUP", import = "TYPE_IMPORT", other = "TYPE_OTHER" }

local function arrowButton(parent, tex, tip)
  local b = W.Button(parent, "", 28, 28)
  local t = b:CreateTexture(nil, "ARTWORK"); t:SetSize(16, 16); t:SetPoint("CENTER"); t:SetTexture(tex)
  b.icon, b.tip = t, tip
  return b
end

---------------------------------------------------------------------------
-- Profile manager: order, multi-select delete, rename, load
---------------------------------------------------------------------------
function DL.OpenProfileManager()
  local f = DL.pm
  if not f then
    f = DL.Dialog("ConfigManagerProfileFrame", 820, 640, L.PM_TITLE)
    DL.pm = f
    f.selected, f.offset = {}, 0
    local sortLab = W.Text(f, 11, C.muted); sortLab:SetPoint("TOPLEFT", 26, -66); sortLab:SetText(L.SORT_BY:upper())
    local prev
    for _, s in ipairs({ { "name", L.SORT_NAME }, { "date", L.SORT_DATE }, { "class", L.SORT_CLASS } }) do
      local b = W.Button(f, s[2], 20, 28); b:SetWidth(b.text:GetStringWidth() + 28)
      if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("LEFT", sortLab, "RIGHT", 12, 0) end
      b:SetScript("OnClick", function() D.SortProfiles(s[1]); DL.RefreshProfileManager() end)
      prev = b
    end
    local none = W.Button(f, L.SEL_NONE, 90, 28); none:SetPoint("TOPRIGHT", -26, -58)
    none:SetScript("OnClick", function() wipe(f.selected); DL.RefreshProfileManager() end)
    local all = W.Button(f, L.SEL_ALL, 90, 28); all:SetPoint("RIGHT", none, "LEFT", -6, 0)
    all:SetScript("OnClick", function() for _, it in ipairs(D.ListProfiles()) do f.selected[it.key] = true end; DL.RefreshProfileManager() end)

    local box = W.Frame(f, C.panel, C.border)
    box:SetPoint("TOPLEFT", 26, -100); box:SetPoint("TOPRIGHT", -26, -100); box:SetHeight(VISIBLE * ROW_H + 8)
    box:EnableMouseWheel(true)
    box:SetScript("OnMouseWheel", function(_, d) f.offset = math.max(0, f.offset - d * 2); DL.RefreshProfileManager() end)
    f.rows = {}
    for i = 1, VISIBLE do
      local r = CreateFrame("Frame", nil, box, "BackdropTemplate")
      r:SetHeight(ROW_H - 4); r:SetPoint("TOPLEFT", 4, -4 - (i - 1) * ROW_H); r:SetPoint("RIGHT", -4, 0)
      r.check = W.Check(r, "", function() return r.key and f.selected[r.key] end,
        function(v) if r.key then f.selected[r.key] = v or nil; DL.RefreshProfileManager() end end)
      r.check:SetPoint("LEFT", 12, 0); r.check:SetWidth(20)
      r.dot = W.Tex(r); r.dot:SetSize(10, 10); r.dot:SetPoint("LEFT", 42, 0)
      r.name = W.Text(r, 13, C.text); r.name:SetPoint("TOPLEFT", 62, -6); r.name:SetPoint("RIGHT", -300, 0)
      r.sub = W.Text(r, 11, C.muted); r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -4); r.sub:SetPoint("RIGHT", -300, 0)
      r.edit = W.Edit(r, 360, ""); r.edit:SetPoint("LEFT", 58, 0); r.edit:Hide()
      r.edit.edit:SetScript("OnEnterPressed", function(self)
        if r.key then D.RenameProfile(r.key, self:GetText()) end
        f.renaming = nil; self:ClearFocus(); DL.RefreshProfileManager()
      end)
      r.edit.edit:SetScript("OnEscapePressed", function(self) f.renaming = nil; self:ClearFocus(); DL.RefreshProfileManager() end)
      r.load = W.Button(r, L.LOAD, 80, 30, "primary"); r.load:SetPoint("RIGHT", -8, 0)
      r.rename = W.Button(r, L.RENAME, 100, 30); r.rename:SetPoint("RIGHT", r.load, "LEFT", -6, 0)
      r.down = arrowButton(r, "Interface\\Buttons\\Arrow-Down-Up", L.MOVE_DOWN); r.down:SetPoint("RIGHT", r.rename, "LEFT", -10, 0)
      r.up = arrowButton(r, "Interface\\Buttons\\Arrow-Up-Up", L.MOVE_UP); r.up:SetPoint("RIGHT", r.down, "LEFT", -4, 0)
      r.up:SetScript("OnClick", function() if r.key then D.MoveProfile(r.key, -1); DL.RefreshProfileManager() end end)
      r.down:SetScript("OnClick", function() if r.key then D.MoveProfile(r.key, 1); DL.RefreshProfileManager() end end)
      r.rename:SetScript("OnClick", function()
        if not r.key then return end
        f.renaming = r.key; DL.RefreshProfileManager()
        r.edit.edit:SetText(ns.db.profiles[r.key].name or r.key); r.edit.edit:SetFocus(); r.edit.edit:HighlightText()
      end)
      r.load:SetScript("OnClick", function()
        local p = r.key and ns.db.profiles[r.key]
        if p then DL.ApplyData(p.data, { mode = "exact" }, p.name) end
      end)
      f.rows[i] = r
    end
    f.count = W.Text(f, 12, C.muted); f.count:SetPoint("BOTTOMLEFT", 28, 30)
    local close = W.Button(f, L.CLOSE, 110, 34); close:SetPoint("BOTTOMRIGHT", -26, 20)
    close:SetScript("OnClick", function() f:Hide() end)
    f.del = W.Button(f, "", 220, 34); f.del:SetPoint("RIGHT", close, "LEFT", -8, 0)
    f.del:SetScript("OnClick", function()
      local keys = {}
      for _, it in ipairs(D.ListProfiles()) do if f.selected[it.key] then keys[#keys + 1] = it.key end end
      if #keys == 0 then return end
      DL.Confirm(L.CONFIRM_DELETE:format(#keys), function()
        D.DeleteProfiles(keys); wipe(f.selected); DL.RefreshProfileManager()
      end)
    end)
  end
  f:SetScale(ns.db.scale or 0.9)
  f.renaming = nil
  f:Show()
  DL.RefreshProfileManager()
end

function DL.RefreshProfileManager()
  local f = DL.pm
  if not f or not f:IsShown() then return end
  local list = D.ListProfiles()
  local specKey = D.SpecKey()
  f.offset = math.min(f.offset, math.max(0, #list - VISIBLE))
  local nsel = 0
  for key in pairs(f.selected) do if ns.db.profiles[key] then nsel = nsel + 1 else f.selected[key] = nil end end
  for i, r in ipairs(f.rows) do
    local idx = i + f.offset
    local it = list[idx]
    r.key = it and it.key
    r:SetShown(it ~= nil)
    if it then
      local p = it.p
      local sel = f.selected[it.key]
      W.Paint(r, sel and C.selBg or C.panel2, sel and C.goldDark or C.border)
      local cr, cg, cb = D.ClassColor(p.class)
      r.dot:SetVertexColor(cr, cg, cb); r.dot:SetShown(p.class ~= nil)
      local active = it.key == specKey and ("  |cffe3b55b" .. L.ACTIVE .. "|r") or ""
      r.name:SetText((p.name or it.key) .. active)
      local parts = { L[TYPE_LABEL[D.ProfileType(it.key)]] }
      if p.data and p.data.meta and p.data.meta.client then parts[#parts + 1] = p.data.meta.client end
      if p.saved then parts[#parts + 1] = p.saved end
      r.sub:SetText(table.concat(parts, " · "))
      local renaming = f.renaming == it.key
      r.edit:SetShown(renaming); r.name:SetShown(not renaming); r.sub:SetShown(not renaming)
      r.up:SetDisabled(idx == 1); r.down:SetDisabled(idx == #list)
      r.check:Refresh()
    end
  end
  f.count:SetText(#list == 0 and L.NO_PROFILES or L.SELECTED_N:format(nsel, #list))
  f.del.text:SetText(L.DELETE_SELECTED:format(nsel))
  f.del:SetDisabled(nsel == 0)
  if nsel > 0 then f.del.text:SetTextColor(C.warn[1], C.warn[2], C.warn[3]) end
end

---------------------------------------------------------------------------
-- Error log
---------------------------------------------------------------------------
function DL.ShowErrors()
  local f = DL.errors
  if not f then
    f = DL.Dialog("ConfigManagerErrorFrame", 820, 560, L.ERRORS_TITLE)
    DL.errors = f
    f.box = W.MultiEdit(f); f.box:SetPoint("TOPLEFT", 26, -64); f.box:SetPoint("BOTTOMRIGHT", -26, 70)
    local close = W.Button(f, L.CLOSE, 110, 34); close:SetPoint("BOTTOMRIGHT", -26, 20)
    close:SetScript("OnClick", function() f:Hide() end)
    local clear = W.Button(f, L.ERRORS_CLEAR, 160, 34); clear:SetPoint("RIGHT", close, "LEFT", -8, 0)
    clear:SetScript("OnClick", function() ns.db.errors = {}; DL.ShowErrors(); DL.ShowErrors() end)
    local sel = W.Button(f, L.SELECT_ALL, 150, 34, "primary"); sel:SetPoint("RIGHT", clear, "LEFT", -8, 0)
    sel:SetScript("OnClick", function() f.box.edit:SetFocus(); f.box.edit:HighlightText() end)
  end
  if f:IsShown() then f:Hide(); return end
  local lines = {}
  for _, e in ipairs(ns.db.errors or {}) do
    lines[#lines + 1] = ("[%s] %s · %s\n%s\n%s"):format(e.t or "?", e.client or "?", e.where or "?", e.msg or "", e.stack or "")
  end
  f.box.edit:SetText(#lines > 0 and table.concat(lines, "\n----------\n") or L.ERRORS_NONE)
  ns.db.unseenErrors = false
  f:SetScale(ns.db.scale or 0.9)
  f:Show()
end

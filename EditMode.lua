local ADDON, ns = ...
-- Edit Mode layouts: uses Blizzard's own layout string (the same as Edit Mode's Import/Export),
-- so ConfigManager never stores frame positions itself and never touches the data of Edit Mode
-- extensions (Edit Mode Expanded, PrecisionEdit, ...). Not available in clients without Edit Mode.
local EM = {}
ns.EditMode = EM

function EM.Available()
  return C_EditMode and C_EditMode.ConvertLayoutInfoToString and C_EditMode.ConvertStringToLayoutInfo
    and EditModeManagerFrame and EditModeManagerFrame.GetActiveLayoutInfo and true or false
end

-- { s = layout string, name = layout name } of the active layout, or nil
function EM.Read()
  if not EM.Available() then return nil end
  local ok, info = pcall(EditModeManagerFrame.GetActiveLayoutInfo, EditModeManagerFrame)
  if not ok or type(info) ~= "table" then return nil end
  local ok2, s = pcall(C_EditMode.ConvertLayoutInfoToString, info)
  if not ok2 or type(s) ~= "string" or s == "" then return nil end
  return { s = s, name = info.layoutName }
end

function EM.Same(e)
  local cur = EM.Read()
  return cur and e and cur.s == e.s or false
end

-- Imports the layout as a new account layout and activates it. Returns applied, missing.
function EM.Apply(e)
  if not (e and e.s) then return 0, 0 end
  if not EM.Available() or not EditModeManagerFrame.ImportLayout then return 0, 1 end
  if InCombatLockdown() then return 0, 1 end
  if EM.Same(e) then return 0, 0 end
  local ok, info = pcall(C_EditMode.ConvertStringToLayoutInfo, e.s)
  if not ok or type(info) ~= "table" then return 0, 1 end
  local name = "CM " .. date("%m-%d %H:%M")
  local layoutType = (Enum and Enum.EditModeLayoutType and Enum.EditModeLayoutType.Account) or 1
  local ok2 = pcall(EditModeManagerFrame.ImportLayout, EditModeManagerFrame, info, layoutType, name)
  return ok2 and 1 or 0, ok2 and 0 or 1
end

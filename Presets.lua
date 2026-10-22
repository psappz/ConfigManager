local ADDON, ns = ...
-- Bundled presets. Role presets are generic layouts (US key positions, remapped to the
-- player's layout on import).
local P = {}
ns.Presets = P
local function base()
  return {
    { "W", "MOVEFORWARD" }, { "S", "MOVEBACKWARD" }, { "A", "STRAFELEFT" }, { "D", "STRAFERIGHT" },
    { "SPACE", "JUMP" }, { "NUMLOCK", "TOGGLEAUTORUN" }, { "TAB", "TARGETNEARESTENEMY" }, { "SHIFT-TAB", "TARGETPREVIOUSENEMY" },
    { "ENTER", "OPENCHAT" }, { "ESCAPE", "TOGGLEGAMEMENU" }, { "B", "OPENALLBAGS" }, { "C", "TOGGLECHARACTER0" },
    { "M", "TOGGLEWORLDMAP" }, { "L", "TOGGLEQUESTLOG" }, { "O", "TOGGLESOCIAL" }, { "PRINTSCREEN", "SCREENSHOT" },
    { "MOUSEWHEELUP", "CAMERAZOOMIN" }, { "MOUSEWHEELDOWN", "CAMERAZOOMOUT" },
  }
end

local function add(list, keys, prefix, first)
  for i, k in ipairs(keys) do list[#list + 1] = { k, prefix .. (first + i - 1) } end
end

local function rolePreset(role)
  local b = base()
  add(b, { "1", "2", "3", "4", "5", "Q", "E", "R", "F", "G", "T", "V" }, "ACTIONBUTTON", 1)
  add(b, { "SHIFT-1", "SHIFT-2", "SHIFT-3", "SHIFT-4", "SHIFT-5", "SHIFT-Q", "SHIFT-E", "SHIFT-R", "SHIFT-F", "SHIFT-G" }, "MULTIACTIONBAR1BUTTON", 1)
  add(b, { "CTRL-1", "CTRL-2", "CTRL-3", "CTRL-4", "CTRL-5", "CTRL-Q", "CTRL-E" }, "MULTIACTIONBAR2BUTTON", 1)
  add(b, { "ALT-1", "ALT-2", "ALT-3", "ALT-4" }, "MULTIACTIONBAR3BUTTON", 1)
  if role == "HEALER" then
    b[#b + 1] = { "F1", "TARGETSELF" }
    add(b, { "F2", "F3", "F4", "F5" }, "TARGETPARTYMEMBER", 1)
    add(b, { "BUTTON4", "BUTTON5", "SHIFT-BUTTON4", "SHIFT-BUTTON5" }, "MULTIACTIONBAR4BUTTON", 1)
  elseif role == "TANK" then
    add(b, { "BUTTON4", "BUTTON5" }, "MULTIACTIONBAR4BUTTON", 1)
    b[#b + 1] = { "CTRL-TAB", "FOCUSTARGET" }
    b[#b + 1] = { "SHIFT-BUTTON4", "MULTIACTIONBAR4BUTTON3" }
  else
    add(b, { "BUTTON4", "BUTTON5" }, "MULTIACTIONBAR1BUTTON", 11)
    b[#b + 1] = { "CTRL-TAB", "FOCUSTARGET" }
  end
  return { v = 1, layout = "us", meta = { role = role }, binds = b }
end

P.list = {
  { id = "role_TANK", role = "TANK", nameKey = "ROLE_TANK", data = rolePreset("TANK") },
  { id = "role_HEALER", role = "HEALER", nameKey = "ROLE_HEALER", data = rolePreset("HEALER") },
  { id = "role_DAMAGER", role = "DAMAGER", nameKey = "ROLE_DPS", data = rolePreset("DAMAGER") },
}

function P.ForRole(role)
  for _, p in ipairs(P.list) do if p.role == role then return p end end
end

function P.Name(p)
  return p.name or (ns.L[p.nameKey] .. " – " .. ns.L.ROLE_SUB)
end

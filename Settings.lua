local ADDON, ns = ...
local U = ns.U
local S = {}
ns.Settings = S

-- Game settings that exist in Classic Era and are carried over to every other version.
-- Graphics, camera, sound and window positions are deliberately left out.
S.CVARS = {
  controls = { "autoLootDefault", "lootUnderMouse", "interactOnLeftClick", "deselectOnClick", "autoSelfCast",
    "ActionButtonUseKeyDown", "autoClearAFK" },
  barset = { "lockActionBars", "alwaysShowActionBars", "countdownForCooldowns" },
  interface = { "UnitNameOwn", "UnitNamePlayerGuild", "UnitNameNPC", "UnitNameFriendlyPlayerName", "UnitNameEnemyPlayerName",
    "nameplateShowFriends", "nameplateShowEnemies", "statusText", "statusTextDisplay", "showTargetOfTarget", "buffDurations",
    "enableFloatingCombatText", "autoQuestWatch", "autoQuestProgress", "rotateMinimap", "showTutorials" },
  chat = { "chatStyle", "whisperMode", "showTimestamps", "chatBubbles", "chatBubblesParty", "profanityFilter" },
}

local function getCVar(name)
  local ok, v
  if C_CVar and C_CVar.GetCVar then ok, v = pcall(C_CVar.GetCVar, name)
  elseif GetCVar then ok, v = pcall(GetCVar, name) end
  if ok then return U.Safe(v) end
end

local function setCVar(name, value)
  local ok, res
  if C_CVar and C_CVar.SetCVar then ok, res = pcall(C_CVar.SetCVar, name, value)
  elseif SetCVar then ok, res = pcall(SetCVar, name, value) end
  return ok and res ~= false
end

-- Reads the given sections ({ controls = true, ... }) into a plain table.
function S.Read(sections)
  local out = { cvars = {} }
  for sec, list in pairs(S.CVARS) do
    if sections[sec] then
      for _, name in ipairs(list) do
        local v = getCVar(name)
        if v ~= nil then out.cvars[name] = tostring(v) end
      end
    end
  end
  if sections.controls and GetModifiedClick then
    local ok, v = pcall(GetModifiedClick, "AUTOLOOTTOGGLE")
    if ok and v then out.lootKey = v end
  end
  if sections.barset and GetActionBarToggles then
    local ok, a, b, c, d, e = pcall(GetActionBarToggles)
    if ok then out.bars = { a and true or false, b and true or false, c and true or false, d and true or false, e and true or false } end
  end
  if not next(out.cvars) then out.cvars = nil end
  if not out.cvars and not out.lootKey and not out.bars then return nil end
  return out
end

-- Counts how many entries exist / are missing on this client.
function S.Preview(st)
  local n, missing = 0, 0
  if not st then return 0, 0 end
  for name in pairs(st.cvars or {}) do
    n = n + 1
    if getCVar(name) == nil then missing = missing + 1 end
  end
  if st.lootKey then n = n + 1; if not SetModifiedClick then missing = missing + 1 end end
  if st.bars then n = n + 1; if not SetActionBarToggles then missing = missing + 1 end end
  return n, missing
end

function S.Apply(st, sections)
  local applied, missing = 0, 0
  if not st then return 0, 0 end
  local allowed = {}
  for sec, list in pairs(S.CVARS) do
    if sections[sec] then for _, name in ipairs(list) do allowed[name] = true end end
  end
  for name, value in pairs(st.cvars or {}) do
    if allowed[name] then
      if getCVar(name) == nil then missing = missing + 1
      elseif setCVar(name, value) then applied = applied + 1 end
    end
  end
  if sections.controls and st.lootKey then
    if SetModifiedClick then pcall(SetModifiedClick, "AUTOLOOTTOGGLE", st.lootKey); applied = applied + 1
    else missing = missing + 1 end
  end
  if sections.barset and st.bars then
    if SetActionBarToggles then
      local b = st.bars
      pcall(SetActionBarToggles, b[1], b[2], b[3], b[4], b[5])
      if MultiActionBar_Update then pcall(MultiActionBar_Update) end
      applied = applied + 1
    else missing = missing + 1 end
  end
  return applied, missing
end

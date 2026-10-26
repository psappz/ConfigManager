local ADDON, ns = ...
local U, LY = ns.U, ns.Layouts
local D = {}
ns.Data = D

local DEFAULTS = {
  language = "auto", layout = nil, size = nil, mouseButtons = 3, remap = "pos", scale = 0.9,
  minimap = { show = true, angle = 215 }, autosave = true, ask = true,
  sections = { binds = true, bars = true, macros = true, controls = true, barset = true, interface = true, chat = true },
  importSections = { binds = true, bars = true, macros = true, controls = true, barset = true, interface = true, chat = true },
  importMode = "merge", importBackup = true,
  profiles = {}, nextId = 1,
}

function D.InitDB()
  ConfigManagerDB = ConfigManagerDB or {}
  -- "auto" was the old default and was based on the client language: discard it,
  -- the player is asked instead
  if ConfigManagerDB.layout == "auto" then ConfigManagerDB.layout = nil end
  if not ConfigManagerDB.keyboardConfirmed then ConfigManagerDB.size = nil end
  for k, v in pairs(DEFAULTS) do
    if ConfigManagerDB[k] == nil then ConfigManagerDB[k] = U.CopyTable(v) end
  end
  ConfigManagerCharDB = ConfigManagerCharDB or {}
  ConfigManagerCharDB.asked = ConfigManagerCharDB.asked or {}
  ns.db, ns.cdb = ConfigManagerDB, ConfigManagerCharDB
end

---------------------------------------------------------------------------
-- Commands, categories, action slots
---------------------------------------------------------------------------
-- prefix -> { bar number shown to the user, first action slot - 1 }
local BAR_PREFIX = {
  { "ACTIONBUTTON", 1, 0 }, { "MULTIACTIONBAR1BUTTON", 2, 60 }, { "MULTIACTIONBAR2BUTTON", 3, 48 },
  { "MULTIACTIONBAR3BUTTON", 4, 24 }, { "MULTIACTIONBAR4BUTTON", 5, 36 }, { "MULTIACTIONBAR5BUTTON", 6, 144 },
  { "MULTIACTIONBAR6BUTTON", 7, 156 }, { "MULTIACTIONBAR7BUTTON", 8, 168 },
  { "EUI_BAR9_BUTTON", 9, 12 }, { "EUI_BAR10_BUTTON", 10, 108 },
}

function D.SlotForCommand(cmd)
  if type(cmd) ~= "string" then return end
  for _, b in ipairs(BAR_PREFIX) do
    local n = cmd:match("^" .. b[1] .. "(%d+)$")
    if n then
      n = tonumber(n)
      if n >= 1 and n <= 12 then return b[3] + n, b[2], n end
    end
  end
end

function D.CategoryOf(cmd, header)
  header = header or ""
  if cmd:find("^ACTIONBUTTON") or cmd:find("^MULTIACTIONBAR") or cmd:find("^EUI_BAR") or cmd:find("^SHAPESHIFTBUTTON")
    or cmd:find("^BONUSACTIONBUTTON") or cmd:find("^EXTRAACTIONBUTTON") or cmd:find("ACTIONPAGE") or cmd:find("ACTIONBAR") then
    return "ACTIONBAR"
  end
  if header:find("MOVEMENT") or cmd:find("^MOVE") or cmd:find("STRAFE") or cmd:find("^TURN") or cmd == "JUMP"
    or cmd == "TOGGLEAUTORUN" or cmd == "SITORSTAND" or cmd:find("^PITCH") or cmd:find("^TOGGLERUN") then
    return "MOVEMENT"
  end
  if header:find("TARGET") or cmd:find("TARGET") or cmd:find("FOCUS") or cmd == "INTERACTTARGET" or cmd:find("ASSIST") or cmd:find("ATTACK") then
    return "TARGETING"
  end
  if header:find("INTERFACE") or header:find("CHAT") or cmd:find("^TOGGLE") or cmd:find("^OPEN") or cmd:find("CHAT") or cmd:find("^SCREENSHOT") then
    return "INTERFACE"
  end
  return "OTHER"
end

local function bindingName(cmd)
  local name
  if GetBindingName then
    local ok, n = pcall(GetBindingName, cmd)
    if ok and type(n) == "string" and n ~= "" then name = n end
  end
  return name or _G["BINDING_NAME_" .. cmd] or cmd
end
D.BindingName = bindingName

local function headerText(h)
  if not h or h == "" then return "" end
  return _G[h] or _G["BINDING_HEADER_" .. h] or h
end

-- Reads every binding the client knows. Returns:
--   commands: ordered list { cmd, name, header, cat, keys = {...}, slot, bar, index }
--   byKey: chord -> command, byCmd: command -> entry
function D.ReadBindings()
  local commands, byKey, byCmd = {}, {}, {}
  local n = GetNumBindings and GetNumBindings() or 0
  for i = 1, n do
    local res = { pcall(GetBinding, i) }
    if res[1] then
      local cmd, header = res[2], res[3]
      if type(cmd) == "string" and cmd ~= "" and not cmd:find("^HEADER_") then
        local e = byCmd[cmd]
        if not e then
          local slot, bar, idx = D.SlotForCommand(cmd)
          e = { cmd = cmd, name = bindingName(cmd), header = headerText(header), rawHeader = header or "",
            cat = D.CategoryOf(cmd, header), keys = {}, slot = slot, bar = bar, index = idx }
          byCmd[cmd] = e
          commands[#commands + 1] = e
        end
        for j = 4, #res do
          local key = res[j]
          if type(key) == "string" and key ~= "" then
            e.keys[#e.keys + 1] = key
            byKey[key] = cmd
          end
        end
      end
    end
  end
  return commands, byKey, byCmd
end

---------------------------------------------------------------------------
-- Action slots
---------------------------------------------------------------------------
local function spellName(id)
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, id)
    if ok and n then return n end
  end
  if GetSpellInfo then
    local ok, n = pcall(GetSpellInfo, id)
    if ok and n then return n end
  end
end

local function itemName(id)
  if C_Item and C_Item.GetItemNameByID then
    local ok, n = pcall(C_Item.GetItemNameByID, id)
    if ok and n then return n end
  end
  if GetItemInfo then
    local ok, n = pcall(GetItemInfo, id)
    if ok and n then return n end
  end
end

-- { t = "s"|"m"|"i"|other, id, n } or nil for an empty slot
function D.ReadAction(slot)
  if not GetActionInfo then return end
  local ok, atype, id, sub = pcall(GetActionInfo, slot)
  if not ok then return end
  atype, id = U.Safe(atype), U.Safe(id)
  if not atype then return end
  if atype == "spell" then
    return { t = "s", id = id, n = spellName(id) }
  elseif atype == "macro" then
    local name = id and GetMacroInfo and U.Safe((GetMacroInfo(id)))
    if not name and GetActionText then name = U.Safe(GetActionText(slot)) end
    return { t = "m", n = name }
  elseif atype == "item" then
    return { t = "i", id = id, n = itemName(id) }
  end
  return { t = atype, id = id }
end

function D.ActionTexture(slot)
  if not GetActionTexture then return end
  local ok, tex = pcall(GetActionTexture, slot)
  if ok then return U.Safe(tex) end
end

function D.ActionLabel(slot)
  local a = slot and D.ReadAction(slot)
  return a and a.n or nil
end

---------------------------------------------------------------------------
-- Macros
---------------------------------------------------------------------------
local function macroLimits()
  return MAX_ACCOUNT_MACROS or 120, MAX_CHARACTER_MACROS or 18
end

function D.ReadMacros()
  local list = {}
  if not GetMacroInfo then return list end
  local maxAcc, maxChar = macroLimits()
  for i = 1, maxAcc + maxChar do
    local ok, name, icon, body = pcall(GetMacroInfo, i)
    if ok and name then
      list[#list + 1] = { n = name, i = icon, b = body or "", c = i > maxAcc or nil }
    end
  end
  return list
end

---------------------------------------------------------------------------
-- Player specialization
---------------------------------------------------------------------------
local FALLBACK_ROLES = {
  WARRIOR = { TANK = true, DAMAGER = true }, PALADIN = { TANK = true, HEALER = true, DAMAGER = true },
  DRUID = { TANK = true, HEALER = true, DAMAGER = true }, PRIEST = { HEALER = true, DAMAGER = true },
  SHAMAN = { HEALER = true, DAMAGER = true }, MONK = { TANK = true, HEALER = true, DAMAGER = true },
  DEATHKNIGHT = { TANK = true, DAMAGER = true }, DEMONHUNTER = { TANK = true, DAMAGER = true },
  EVOKER = { HEALER = true, DAMAGER = true }, MAGE = { DAMAGER = true }, ROGUE = { DAMAGER = true },
  HUNTER = { DAMAGER = true }, WARLOCK = { DAMAGER = true },
}

function D.PlayerSpec()
  local className, classFile, classID = UnitClass("player")
  local info = { class = classFile, className = className, classID = classID }
  local idx
  if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
    local ok, v = pcall(C_SpecializationInfo.GetSpecialization); if ok then idx = v end
  elseif GetSpecialization then
    local ok, v = pcall(GetSpecialization); if ok then idx = v end
  end
  if idx and idx > 0 then
    local getter = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo
    local ok, id, name, _, icon, role = pcall(getter, idx)
    if ok and id then
      info.specID, info.specName, info.icon, info.role = id, name, icon, role
    end
  end
  if not info.specID and GetNumTalentTabs and GetTalentTabInfo then
    local best, bestPts, bestName = nil, 0, nil
    for tab = 1, (GetNumTalentTabs() or 0) do
      local ok, a, b, c, d, e = pcall(GetTalentTabInfo, tab)
      if ok then
        local name = type(a) == "string" and a or (type(b) == "string" and b) or nil
        local pts
        for _, v in ipairs({ c, e, d }) do
          if type(v) == "number" and v >= 1 and v <= 71 then pts = v; break end
        end
        if pts and pts > bestPts then best, bestPts, bestName = tab, pts, name end
      end
    end
    if best then info.specID, info.specName = (classFile or "?") .. "-" .. best, bestName end
  end
  return info
end

function D.ClassRoles(classFile, classID)
  local roles = {}
  local num = (C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID) or GetNumSpecializationsForClassID
  if classID and num and GetSpecializationInfoForClassID then
    local ok, n = pcall(num, classID)
    if ok and n then
      for i = 1, n do
        local ok2, _, _, _, _, role = pcall(GetSpecializationInfoForClassID, classID, i)
        if ok2 and role then roles[role] = true end
      end
    end
  end
  if not next(roles) then roles = FALLBACK_ROLES[classFile] or { DAMAGER = true } end
  return roles
end

function D.ClassColor(classFile)
  local c = (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classFile))
    or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
  if c then return c.r, c.g, c.b end
  return 0.89, 0.71, 0.36
end

function D.SpecLabel(info)
  info = info or D.PlayerSpec()
  -- WoW Forever reports the class name as the (only) spec name
  if info.specName and info.specName ~= info.className then return (info.className or "") .. " · " .. info.specName end
  return info.className or ns.L.NO_SPEC
end

---------------------------------------------------------------------------
-- Snapshot / export data
---------------------------------------------------------------------------
D.SECTIONS = { "binds", "bars", "macros", "controls", "barset", "interface", "chat" }

function D.AllSections()
  local t = {}
  for _, k in ipairs(D.SECTIONS) do t[k] = true end
  return t
end

-- Merges explicit section flags with the legacy binds/bars/macros switches.
local function sectionsFrom(opts)
  local sec = U.CopyTable(opts.sections or D.AllSections())
  if opts.binds == false then sec.binds = false end
  if opts.bars == false then sec.bars = false end
  if opts.macros == false then sec.macros = false end
  return sec
end
D.SectionsFrom = sectionsFrom

-- "Forever 1.60.1.70532", "Classic Era – Hardcore 1.15.8", "MoP Classic 5.5.1", "Retail 12.0.5"
function D.ClientLabel()
  local v = GetBuildInfo and select(1, GetBuildInfo()) or "?"
  local build = GetBuildInfo and select(2, GetBuildInfo())
  local major, minor = tostring(v):match("^(%d+)%.(%d+)")
  major, minor = tonumber(major), tonumber(minor)
  local name = "WoW"
  if major == 1 and minor and minor >= 60 then name = "Forever"
  elseif major == 1 then
    name = "Classic Era"
    if C_Seasons and C_Seasons.HasActiveSeason and C_Seasons.HasActiveSeason() and Enum and Enum.SeasonID then
      local id = C_Seasons.GetActiveSeason()
      for k, val in pairs(Enum.SeasonID) do if val == id and k ~= "NoSeason" and k ~= "Placeholder" then name = name .. " – " .. k end end
    end
  elseif major == 2 then name = "TBC Classic"
  elseif major == 3 then name = "Wrath Classic"
  elseif major == 4 then name = "Cataclysm Classic"
  elseif major == 5 then name = "MoP Classic"
  elseif major and major >= 6 then name = "Retail" end
  return name .. " " .. tostring(v) .. (build and ("." .. tostring(build)) or "")
end

-- nil until the player has picked a layout (old "auto" values count as not picked)
function D.CurrentLayoutId()
  if LY.IsChosen(ns.db.layout) then return ns.db.layout end
end

function D.KeyboardChosen()
  return LY.IsChosen(ns.db.layout) and (ns.db.size == "full" or ns.db.size == "tkl" or ns.db.size == "60")
end

function D.Snapshot(opts)
  opts = opts or {}
  local sec = sectionsFrom(opts)
  local spec = D.PlayerSpec()
  local data = { v = 1, layout = D.CurrentLayoutId(),
    meta = { class = spec.class, classID = spec.classID, className = spec.className, specID = spec.specID,
      specName = spec.specName, role = spec.role, created = U.Timestamp(), char = UnitName and UnitName("player") or nil,
      client = D.ClientLabel() } }
  if sec.binds then
    local _, byKey = D.ReadBindings()
    data.binds = {}
    for key, cmd in pairs(byKey) do data.binds[#data.binds + 1] = { key, cmd } end
    table.sort(data.binds, function(a, b) return a[1] < b[1] end)
  end
  if sec.bars then
    data.actions = {}
    for slot = 1, 180 do
      local a = D.ReadAction(slot)
      if a and (a.t == "s" or a.t == "m" or a.t == "i") then data.actions[slot] = a end
    end
  end
  if sec.macros then data.macros = D.ReadMacros() end
  data.settings = ns.Settings.Read(sec)
  if sec.chat then data.chat = ns.Chat.Read() end
  return data
end

local function remapKey(key, data)
  if ns.db.remap == "pos" then return LY.Remap(key, data.layout, D.CurrentLayoutId()) end
  return key
end

function D.Preview(data)
  local _, byKey, byCmd = D.ReadBindings()
  local p = { binds = 0, changed = 0, unknown = 0, macros = data.macros and #data.macros or 0, bars = 0 }
  for _, b in ipairs(data.binds or {}) do
    local key, cmd = remapKey(b[1], data), b[2]
    p.binds = p.binds + 1
    if cmd ~= "NONE" and cmd ~= "" and not byCmd[cmd] then
      p.unknown = p.unknown + 1
    elseif (byKey[key] or "NONE") ~= cmd then
      p.changed = p.changed + 1
    end
  end
  for _ in pairs(data.actions or {}) do p.bars = p.bars + 1 end
  p.settings, p.settingsMissing = ns.Settings.Preview(data.settings)
  p.chat, p.chatMissing = ns.Chat.Preview(data.chat)
  return p
end

local function pickup(a)
  if a.t == "s" then
    local pick = (C_Spell and C_Spell.PickupSpell) or PickupSpell
    if pick and a.id then pcall(pick, a.id) end
    if not (GetCursorInfo and GetCursorInfo()) and pick and a.n then pcall(pick, a.n) end
  elseif a.t == "m" then
    local idx = a.n and GetMacroIndexByName and GetMacroIndexByName(a.n)
    if idx and idx > 0 then PickupMacro(idx) end
  elseif a.t == "i" then
    local pick = (C_Item and C_Item.PickupItem) or PickupItem
    if pick and a.id then pcall(pick, a.id) end
  end
  return GetCursorInfo and GetCursorInfo() ~= nil
end

local function sameAction(slot, a)
  local cur = D.ReadAction(slot)
  if not cur then return false end
  if cur.t ~= a.t then return false end
  if a.t == "m" then return cur.n == a.n end
  return cur.id == a.id
end

-- Applies a snapshot. opts: mode ("merge"|"replace"), binds, bars, macros (booleans)
function D.Apply(data, opts)
  opts = opts or {}
  local stats = { binds = 0, bars = 0, macros = 0, skipped = 0, macroLimit = 0, settings = 0, chat = 0, missing = 0 }
  if InCombatLockdown and InCombatLockdown() then return nil, "combat" end
  local replace = opts.mode == "replace"
  local sec = sectionsFrom(opts)

  if sec.macros and data.macros then
    local maxAcc, maxChar = macroLimits()
    for _, m in ipairs(data.macros) do
      if m.n and m.n ~= "" then
        local idx = GetMacroIndexByName and GetMacroIndexByName(m.n) or 0
        local icon = tonumber(m.i) or m.i or 134400
        if idx and idx > 0 then
          pcall(EditMacro, idx, m.n, icon, m.b or "")
          stats.macros = stats.macros + 1
        else
          local numAcc, numChar = GetNumMacros()
          local perChar = m.c and true or false
          if (perChar and numChar >= maxChar) or (not perChar and numAcc >= maxAcc) then
            stats.macroLimit = stats.macroLimit + 1
          else
            local ok = pcall(CreateMacro, m.n, icon, m.b or "", perChar)
            if ok then stats.macros = stats.macros + 1 else stats.skipped = stats.skipped + 1 end
          end
        end
      end
    end
  end

  local exact = opts.mode == "exact"
  if sec.binds and data.binds then
    if replace and LoadBindings then LoadBindings(DEFAULT_BINDINGS or 0) end
    local _, curByKey, byCmd = D.ReadBindings()
    if exact then
      -- a profile is a complete state: free every key the profile does not use
      local wanted = {}
      for _, b in ipairs(data.binds) do wanted[remapKey(b[1], data)] = true end
      for key in pairs(curByKey) do
        if not wanted[key] then SetBinding(key) end
      end
    end
    for _, b in ipairs(data.binds) do
      local key, cmd = remapKey(b[1], data), b[2]
      if cmd == "NONE" or cmd == "" then
        SetBinding(key)
        stats.binds = stats.binds + 1
      elseif byCmd[cmd] then
        if SetBinding(key, cmd) ~= false then stats.binds = stats.binds + 1 end
      else
        stats.skipped = stats.skipped + 1
      end
    end
    D.SaveBindings()
  end

  if sec.bars and data.actions then
    if ClearCursor then ClearCursor() end
    for slot = 1, 180 do
      local a = data.actions[slot] or data.actions[tostring(slot)]
      if a then
        if not sameAction(slot, a) then
          if pickup(a) and pcall(PlaceAction, slot) then
            stats.bars = stats.bars + 1
          else
            stats.skipped = stats.skipped + 1
          end
          ClearCursor()
        end
      elseif (replace or exact) and D.ReadAction(slot) then
        pcall(PickupAction, slot)
        ClearCursor()
      end
    end
  end

  local a1, m1 = ns.Settings.Apply(data.settings, sec)
  stats.settings, stats.missing = a1, m1
  if sec.chat and data.chat then
    local a2, m2 = ns.Chat.Apply(data.chat)
    stats.chat, stats.missing = a2, stats.missing + m2
  end
  ns.pending, ns.changed = 0, {}
  return stats
end

---------------------------------------------------------------------------
-- Live editing (staged until "Apply"; "Discard" reloads the saved set)
---------------------------------------------------------------------------
ns.pending, ns.changed = 0, {}

function D.SetKey(key, cmd)
  if InCombatLockdown and InCombatLockdown() then U.Print(ns.L.IN_COMBAT); return false end
  local old = GetBindingAction and GetBindingAction(key) or nil
  local ok
  if cmd then ok = SetBinding(key, cmd) else ok = SetBinding(key) end
  if ok ~= false then
    ns.pending = ns.pending + 1
    if cmd then ns.changed[cmd] = true end
    if old and old ~= "" then ns.changed[old] = true end
  end
  return ok ~= false
end

function D.BindingSet()
  return (GetCurrentBindingSet and GetCurrentBindingSet()) or 1
end

function D.SaveBindings()
  if SaveBindings then SaveBindings(D.BindingSet()) end
  ns.pending, ns.changed = 0, {}
end

function D.Discard()
  if LoadBindings then LoadBindings(D.BindingSet()) end
  ns.pending, ns.changed = 0, {}
end

---------------------------------------------------------------------------
-- Profiles (one per specialization, plus any number of named ones)
---------------------------------------------------------------------------
function D.SpecKey(info)
  info = info or D.PlayerSpec()
  if not info.class then return nil end
  return info.class .. ":" .. tostring(info.specID or "none")
end

function D.SaveProfile(key, name, data)
  data = data or D.Snapshot()
  local m = data.meta or {}
  ns.db.profiles[key] = { name = name, class = m.class, classID = m.classID, specID = m.specID, specName = m.specName,
    role = m.role, saved = U.Timestamp(), data = data }
  return ns.db.profiles[key]
end

function D.SaveSpecProfile()
  local info = D.PlayerSpec()
  local key = D.SpecKey(info)
  if not key then return end
  return D.SaveProfile(key, D.SpecLabel(info)), key
end

function D.NewProfileKey(prefix)
  local id = ns.db.nextId or 1
  ns.db.nextId = id + 1
  return (prefix or "p") .. id
end

function D.ProfileType(key)
  if key:find("^backup") then return "backup" end
  if key:find("^imp") then return "import" end
  if key:find(":") then return "spec" end
  return "other"
end

-- Profiles in the user's order (db.profileOrder); new ones are appended by name.
function D.ListProfiles()
  local db = ns.db
  db.profileOrder = db.profileOrder or {}
  local list, seen = {}, {}
  for _, key in ipairs(db.profileOrder) do
    local p = db.profiles[key]
    if p and not seen[key] then list[#list + 1] = { key = key, p = p }; seen[key] = true end
  end
  local rest = {}
  for key, p in pairs(db.profiles) do if not seen[key] then rest[#rest + 1] = { key = key, p = p } end end
  table.sort(rest, function(a, b) return (a.p.name or a.key) < (b.p.name or b.key) end)
  for _, it in ipairs(rest) do list[#list + 1] = it end
  local order = {}
  for i, it in ipairs(list) do order[i] = it.key end
  db.profileOrder = order
  return list
end

function D.SortProfiles(by)
  local list = D.ListProfiles()
  local function name(it) return (it.p.name or it.key):lower() end
  if by == "date" then
    table.sort(list, function(a, b) return (a.p.saved or "") > (b.p.saved or "") end)
  elseif by == "class" then
    table.sort(list, function(a, b)
      local ca, cb = a.p.class or "~", b.p.class or "~"
      if ca ~= cb then return ca < cb end
      return name(a) < name(b)
    end)
  else
    table.sort(list, function(a, b) return name(a) < name(b) end)
  end
  local order = {}
  for i, it in ipairs(list) do order[i] = it.key end
  ns.db.profileOrder = order
end

function D.MoveProfile(key, delta)
  D.ListProfiles()
  local order = ns.db.profileOrder
  for i, k in ipairs(order) do
    if k == key then
      local j = math.max(1, math.min(#order, i + delta))
      table.remove(order, i)
      table.insert(order, j, key)
      return j
    end
  end
end

function D.DeleteProfiles(keys)
  local n = 0
  for _, key in ipairs(keys) do
    if ns.db.profiles[key] then ns.db.profiles[key] = nil; n = n + 1 end
  end
  D.ListProfiles()
  return n
end

function D.RenameProfile(key, name)
  local p = ns.db.profiles[key]
  if p and name and name:match("%S") then p.name = name:gsub("^%s+", ""):gsub("%s+$", ""); return true end
end

function D.FindClassProfile(class, exceptKey)
  local best
  for key, p in pairs(ns.db.profiles) do
    if p.class == class and key ~= exceptKey and not key:find("^backup") then
      if not best or (p.saved or "") > (best.p.saved or "") then best = { key = key, p = p } end
    end
  end
  return best
end

function D.Backup()
  local key = "backup" .. (ns.db.nextId or 1)
  ns.db.nextId = (ns.db.nextId or 1) + 1
  -- keep the five most recent backups
  local backups = {}
  for k, p in pairs(ns.db.profiles) do if k:find("^backup") then backups[#backups + 1] = { k = k, s = p.saved or "" } end end
  table.sort(backups, function(a, b) return a.s > b.s end)
  for i = 5, #backups do ns.db.profiles[backups[i].k] = nil end
  return D.SaveProfile(key, ns.L.BACKUP_NAME:format(U.Timestamp())), key
end

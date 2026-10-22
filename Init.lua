local ADDON, ns = ...
local U, D = ns.U, ns.Data

BINDING_HEADER_CONFIGMANAGER = "ConfigManager"
BINDING_NAME_CONFIGMANAGER_TOGGLE = "ConfigManager"

---------------------------------------------------------------------------
-- Error log: errors in event handlers are kept in the saved variables, so an
-- error during logout can still be read after the next login (/cfgm errors).
---------------------------------------------------------------------------
local function logError(where, err)
  local stack = debugstack and debugstack(3, 12, 0) or ""
  local db = ns.db or ConfigManagerDB
  if db then
    db.errors = db.errors or {}
    table.insert(db.errors, 1, { t = U.Timestamp(), where = where, msg = tostring(err), stack = stack,
      client = D.ClientLabel and D.ClientLabel() or nil })
    while #db.errors > 20 do table.remove(db.errors) end
    db.unseenErrors = true
  end
  if not ns.leaving then U.Print("|cfff0a07e" .. tostring(err) .. "|r  (/cfgm errors)") end
end

function ns.SafeCall(where, fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then logError(where, err) end
  return ok, err
end

---------------------------------------------------------------------------
-- Scheduler without timer objects (WoW Forever limits an addon to 500 timers).
---------------------------------------------------------------------------
local due, ticker = {}, CreateFrame("Frame")
ticker:Hide()
ticker:SetScript("OnUpdate", function(self)
  local now = GetTime()
  local any = false
  for name, job in pairs(due) do
    if now >= job.at then
      due[name] = nil
      ns.SafeCall(name, job.fn)
    else
      any = true
    end
  end
  if not any and not next(due) then self:Hide() end
end)

local function schedule(name, delay, fn)
  due[name] = { at = GetTime() + delay, fn = fn }
  ticker:Show()
end
ns.Schedule = schedule

---------------------------------------------------------------------------
-- Last stable state of the current spec; written to the old spec's profile on a
-- spec switch, because the client swaps the action bars before the switch event.
---------------------------------------------------------------------------
function ns.RefreshCache()
  if ns.leaving or InCombatLockdown() then return end
  local info = D.PlayerSpec()
  local key = D.SpecKey(info)
  if not key then return end
  ns.cache = { specKey = key, name = D.SpecLabel(info), data = D.Snapshot() }
  if ns.db.autosave and ns.db.profiles[key] then
    D.SaveProfile(key, ns.cache.name, ns.cache.data)
  end
end

function ns.OnStateSaved()
  schedule("cache", 0.5, ns.RefreshCache)
end

local function checkPrompt(info)
  local key = D.SpecKey(info)
  if key and ns.db.ask and not ns.cdb.asked[key] and not ns.db.profiles[key] then
    ns.Dialogs.ShowSpecPrompt(info)
  end
end

local function handleSpecChange()
  if ns.leaving then return end
  if InCombatLockdown() then ns.queuedSpec = true; return end
  ns.queuedSpec = nil
  local info = D.PlayerSpec()
  local key = D.SpecKey(info)
  if not key or key == ns.lastSpec then return end
  local old = ns.lastSpec
  ns.lastSpec = key
  if ns.db.autosave and old and ns.cache and ns.cache.specKey == old then
    D.SaveProfile(old, ns.cache.name, ns.cache.data)
  end
  local prof = ns.db.profiles[key]
  if prof then
    local stats = D.Apply(prof.data, { mode = "exact" })
    if stats then U.Print(ns.L.PROFILE_LOADED:format(prof.name)) end
  else
    checkPrompt(info)
  end
  schedule("cache", 3, ns.RefreshCache)
  if ns.Main then ns.Main.Refresh() end
end

function ns.Toggle() ns.Main.Toggle() end
function ConfigManagerToggle() ns.SafeCall("toggle", ns.Main.Toggle) end

-- Blizzard addon compartment (stays visible with minimap addons that collect buttons)
function ConfigManager_OnAddonCompartmentClick(_, button)
  if button == "RightButton" then ns.Dialogs.ToggleSettings() else ns.Main.Toggle() end
end
function ConfigManager_OnAddonCompartmentEnter(_, frame)
  GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
  GameTooltip:SetText("ConfigManager", 0.89, 0.71, 0.36)
  GameTooltip:AddLine(ns.L.MINIMAP_TIP, 1, 1, 1, true)
  GameTooltip:Show()
end
function ConfigManager_OnAddonCompartmentLeave() GameTooltip:Hide() end

SLASH_CONFIGMANAGER1, SLASH_CONFIGMANAGER2 = "/configmanager", "/cfgm"
SlashCmdList.CONFIGMANAGER = function(msg)
  msg = (msg or ""):lower():match("^%s*(%S*)")
  if msg == "export" then ns.Dialogs.OpenIO("export")
  elseif msg == "import" then ns.Dialogs.OpenIO("import")
  elseif msg == "settings" or msg == "config" or msg == "options" then ns.Dialogs.ToggleSettings()
  elseif msg == "list" or msg == "liste" then ns.Main.Open("list")
  elseif msg == "profiles" or msg == "profile" then ns.Dialogs.OpenProfileManager()
  elseif msg == "spec" then ns.Dialogs.ShowSpecPrompt()
  elseif msg == "errors" or msg == "fehler" then ns.Dialogs.ShowErrors()
  else ns.Main.Toggle() end
end

local handlers = {}

function handlers.ADDON_LOADED(arg1)
  if arg1 == ADDON then
    D.InitDB()
    ns.ApplyLocale(ns.db.language)
    -- create the minimap button as early as other addons do, so minimap collectors
    -- (MinimapButtonButton, EllesmereUI, ...) see it on their first scan
    ns.Dialogs.CreateMinimap()
  elseif arg1 == "Blizzard_Settings" or arg1 == "Blizzard_BindingUI" then
    ns.Dialogs.HookBlizzard()
  end
end

function handlers.PLAYER_LOGIN(self)
  ns.Dialogs.CreateMinimap()
  ns.Dialogs.HookBlizzard()
  ns.lastSpec = D.SpecKey()
  schedule("login", 5, function()
    ns.RefreshCache()
    checkPrompt(D.PlayerSpec())
    if ns.db.unseenErrors then U.Print(ns.L.ERRORS_PENDING) end
  end)
  for _, e in ipairs({ "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE",
    "UPDATE_BINDINGS", "ACTIONBAR_SLOT_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_LEAVING_WORLD", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT" }) do
    pcall(self.RegisterEvent, self, e)
  end
end

function handlers.PLAYER_SPECIALIZATION_CHANGED(unit)
  if unit == nil or unit == "player" then schedule("spec", 1, handleSpecChange) end
end
function handlers.ACTIVE_TALENT_GROUP_CHANGED() schedule("spec", 1, handleSpecChange) end
handlers.CHARACTER_POINTS_CHANGED = handlers.ACTIVE_TALENT_GROUP_CHANGED
handlers.PLAYER_TALENT_UPDATE = handlers.ACTIVE_TALENT_GROUP_CHANGED

function handlers.UPDATE_BINDINGS()
  if ns.leaving then return end
  schedule("ui", 0.1, function() if ns.Main then ns.Main.Refresh() end end)
  schedule("cache", 3, ns.RefreshCache)
end
handlers.ACTIONBAR_SLOT_CHANGED = handlers.UPDATE_BINDINGS

-- Blocked protected calls are no Lua errors; record the ones that name this addon.
function handlers.ADDON_ACTION_BLOCKED(addon, fn)
  if addon == ADDON then logError("blocked", "ADDON_ACTION_BLOCKED: " .. tostring(fn)) end
end
function handlers.ADDON_ACTION_FORBIDDEN(addon, fn)
  if addon == ADDON then logError("forbidden", "ADDON_ACTION_FORBIDDEN: " .. tostring(fn)) end
end

function handlers.PLAYER_REGEN_ENABLED() if ns.queuedSpec then handleSpecChange() end end

-- Loading screens and logout: the client clears the bars, nothing may be recorded then.
function handlers.PLAYER_LEAVING_WORLD() ns.leaving = true; due.cache = nil end
function handlers.PLAYER_ENTERING_WORLD()
  ns.leaving = false
  schedule("cache", 3, ns.RefreshCache)
end

function handlers.PLAYER_LOGOUT()
  ns.leaving = true
  if ns.db.autosave and ns.cache and ns.cache.specKey then
    D.SaveProfile(ns.cache.specKey, ns.cache.name, ns.cache.data)
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("ADDON_ACTION_BLOCKED")
ev:RegisterEvent("ADDON_ACTION_FORBIDDEN")
ev:SetScript("OnEvent", function(self, event, arg1, arg2)
  local h = handlers[event]
  if not h then return end
  if event == "PLAYER_LOGIN" then ns.SafeCall(event, h, self) else ns.SafeCall(event, h, arg1, arg2) end
end)

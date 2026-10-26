local ADDON, ns = ...
-- Macro language repair.
-- Macros store spell and item names as plain text ("/cast Feuerball"). After the game
-- language is switched, those names no longer match and the macros stop working.
-- ConfigManager remembers, per client language, which spell or item ID every macro name
-- stands for. After a language switch it rewrites the names in the new language.
-- The same IDs travel with exported macros, so imports into a client with another
-- language are translated as well.
local U, D = ns.U, ns.Data
local ML = {}
ns.MacroLocale = ML

-- Slash commands whose arguments are spell or item names (English command names work
-- in every client language).
local LIST_CMDS = { castrandom = true, userandom = true }
local NAME_CMDS = { cast = true, spell = true, use = true, cancelaura = true, equip = true, equipslot = true,
  castsequence = true, castrandom = true, userandom = true, cancelbuff = true }

local function trimSpan(s, a, b)
  while a <= b and s:sub(a, a):match("%s") do a = a + 1 end
  while b >= a and s:sub(b, b):match("%s") do b = b - 1 end
  return a, b
end

-- Name spans inside one argument string `s` (positions relative to s).
local function argSpans(s, cmd, out)
  local pos = 1
  local len = #s
  while pos <= len do
    local semi = s:find(";", pos, true) or (len + 1)
    local a, b = pos, semi - 1
    -- skip conditionals: [mod:shift,@focus] [combat]
    a = select(1, trimSpan(s, a, b))
    while a <= b and s:sub(a, a) == "[" do
      local close = s:find("]", a, true)
      if not close or close > b then a = b + 1; break end
      a = select(1, trimSpan(s, close + 1, b))
    end
    if a <= b then
      local pieces = {}
      if cmd == "castsequence" then
        local r = s:sub(a, b):match("^(reset=%S+%s*)")
        if r then a = a + #r end
        pieces.sep = ","
      elseif LIST_CMDS[cmd] then
        pieces.sep = ","
      elseif cmd == "equipslot" then
        local slot = s:sub(a, b):match("^(%d+%s+)")
        if slot then a = a + #slot end
      end
      local p = a
      while p <= b do
        local q = pieces.sep and (s:find(pieces.sep, p, true) or (b + 1)) or (b + 1)
        if q > b + 1 then q = b + 1 end
        local x, y = trimSpan(s, p, q - 1)
        if x <= y and s:sub(x, x) == "!" then x = x + 1 end
        if x <= y then
          local name = s:sub(x, y)
          if not name:match("^%d+$") and not name:match("^item:") and not name:find("[%[%]]") then
            out[#out + 1] = { x, y, name }
          end
        end
        p = q + 1
      end
    end
    pos = semi + 1
  end
end

-- All spell/item name spans of a macro body: { {start, end, name}, ... } in body positions.
function ML.Tokens(body)
  local out = {}
  if type(body) ~= "string" then return out end
  local lineStart = 1
  while lineStart <= #body + 1 do
    local nl = body:find("\n", lineStart, true) or (#body + 1)
    local line = body:sub(lineStart, nl - 1)
    local cmdStart, cmd, argStart
    local a, c, rest = line:match("^%s*()#(%a+)%s+()")
    if a then
      cmd = c:lower()
      if cmd == "showtooltip" or cmd == "show" then argStart = rest; cmd = "cast" end
    else
      local x, c2, r2 = line:match("^%s*()/(%a+)%s+()")
      if x and NAME_CMDS[c2:lower()] then cmd, argStart = c2:lower(), r2 end
    end
    if argStart then
      local spans = {}
      argSpans(line:sub(argStart), cmd, spans)
      for _, sp in ipairs(spans) do
        out[#out + 1] = { sp[1] + argStart - 1 + lineStart - 1, sp[2] + argStart - 1 + lineStart - 1, sp[3] }
      end
    end
    lineStart = nl + 1
  end
  return out
end

---------------------------------------------------------------------------
-- Names <-> IDs
---------------------------------------------------------------------------
local function spellIdByName(name)
  if C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, name)
    if ok and type(info) == "table" and info.spellID then return info.spellID end
  end
  if GetSpellInfo then
    local r = { pcall(GetSpellInfo, name) }
    if r[1] and type(r[8]) == "number" then return r[8] end
  end
  return D.BookSpell(name)
end

local function itemIdByName(name)
  if C_Item and C_Item.GetItemInfoInstant then
    local ok, id = pcall(C_Item.GetItemInfoInstant, name)
    if ok and type(id) == "number" then return id end
  end
  if GetItemInfoInstant then
    local ok, id = pcall(GetItemInfoInstant, name)
    if ok and type(id) == "number" then return id end
  end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if get then
    local ok, _, link = pcall(get, name)
    local id = ok and type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if id then return id end
  end
end

local function spellNameById(id)
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, id); if ok and n then return n end
  end
  if GetSpellInfo then
    local ok, n = pcall(GetSpellInfo, id); if ok and type(n) == "string" then return n end
  end
end

local function itemNameById(id)
  if C_Item and C_Item.GetItemNameByID then
    local ok, n = pcall(C_Item.GetItemNameByID, id); if ok and n then return n end
  end
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if get then
    local ok, n = pcall(get, id); if ok and type(n) == "string" then return n end
  end
  if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
end

local function rankWord() return (type(RANK) == "string" and RANK ~= "") and RANK or "Rank" end

-- "s:133", "i:6948", optionally with a spell rank: "s:133:3". nil if unknown here.
function ML.Ref(name)
  local id = spellIdByName(name)
  if id then return "s:" .. id end
  local base, rank = name:match("^(.-)%s*%(%D*(%d+)%)$")
  if base and base ~= "" then
    id = spellIdByName(base)
    if id then return "s:" .. id .. ":" .. rank end
  end
  id = itemIdByName(name)
  if id then return "i:" .. id end
end

function ML.NameOf(ref)
  local kind, id, rank = tostring(ref):match("^(%a):(%d+):?(%d*)$")
  id = tonumber(id)
  if not id then return nil end
  if kind == "s" then
    local n = spellNameById(id)
    if n and rank ~= "" then n = ("%s(%s %s)"):format(n, rankWord(), rank) end
    return n
  elseif kind == "i" then
    return itemNameById(id)
  end
end

local function resolves(name) return ML.Ref(name) ~= nil end

---------------------------------------------------------------------------
-- Memory of macro names per client language
---------------------------------------------------------------------------
local function clientLocale() return (GetLocale and GetLocale()) or "enUS" end
ML.ClientLocale = clientLocale

local function store()
  ns.db.macroNames = ns.db.macroNames or {}
  return ns.db.macroNames
end

-- Records the IDs of all names in the current macros (for the current language).
function ML.Record()
  local loc = clientLocale()
  local map = store()[loc] or {}
  store()[loc] = map
  local n = 0
  for _, m in ipairs(D.ReadMacros()) do
    for _, t in ipairs(ML.Tokens(m.b)) do
      local ref = ML.Ref(t[3])
      if ref then
        if map[t[3]] ~= ref then n = n + 1 end
        map[t[3]] = ref
      end
    end
  end
  return n
end

-- ID refs of the names in one macro body (stored with exports).
function ML.RefsFor(body)
  local refs
  for _, t in ipairs(ML.Tokens(body)) do
    local ref = ML.Ref(t[3])
    if ref then refs = refs or {}; refs[t[3]] = ref end
  end
  return refs
end

-- Looks a name up in the memory of the other languages (preferring `prefer`).
local function remembered(name, prefer)
  local s = store()
  local cur = clientLocale()
  if prefer and prefer ~= cur and s[prefer] and s[prefer][name] then return s[prefer][name] end
  for loc, map in pairs(s) do
    if loc ~= cur and map[name] then return map[name] end
  end
end

-- Rewrites one body. lookup(name) -> ref for names that don't work here.
-- Returns newBody, changes { {from, to} }, unresolved { name } (known elsewhere, no name here).
function ML.TranslateBody(body, lookup)
  local tokens = ML.Tokens(body)
  local changes, unresolved = {}, {}
  local out = body
  for i = #tokens, 1, -1 do
    local t = tokens[i]
    local name = t[3]
    if not resolves(name) then
      local ref = lookup(name)
      local new = ref and ML.NameOf(ref)
      if new and new ~= name then
        out = out:sub(1, t[1] - 1) .. new .. out:sub(t[2] + 1)
        table.insert(changes, 1, { name, new })
      elseif ref and not new then
        -- known in another language, but no name here yet (item not cached)
        table.insert(unresolved, 1, name)
      end
    end
  end
  return out, changes, unresolved
end

---------------------------------------------------------------------------
-- Plan & apply
---------------------------------------------------------------------------
local MAX_BODY = 255

local function macroIndexList()
  local maxAcc = MAX_ACCOUNT_MACROS or 120
  local maxChar = MAX_CHARACTER_MACROS or 18
  local list = {}
  if not GetMacroInfo then return list end
  for i = 1, maxAcc + maxChar do
    local ok, name, icon, body = pcall(GetMacroInfo, i)
    if ok and name then list[#list + 1] = { idx = i, n = name, i = icon, b = body or "" } end
  end
  return list
end

-- What a translation would change, from the remembered names of other languages.
function ML.Plan(fromLocale)
  local plan = { macros = {}, names = 0, unresolved = {}, from = fromLocale, to = clientLocale() }
  local seenU = {}
  for _, m in ipairs(macroIndexList()) do
    local body, changes, unresolved = ML.TranslateBody(m.b, function(n) return remembered(n, fromLocale) end)
    if #changes > 0 then
      plan.macros[#plan.macros + 1] = { idx = m.idx, n = m.n, i = m.i, old = m.b, new = body, changes = changes, tooLong = #body > MAX_BODY }
      plan.names = plan.names + #changes
    end
    for _, u in ipairs(unresolved) do
      if not seenU[u] then seenU[u] = true; plan.unresolved[#plan.unresolved + 1] = u end
    end
  end
  return plan
end

-- Applies a plan. Returns translated, tooLong (nil, "combat" in combat).
function ML.Apply(plan)
  if InCombatLockdown and InCombatLockdown() then return nil, "combat" end
  local done, long = 0, 0
  for _, m in ipairs(plan.macros) do
    if m.tooLong then
      long = long + 1
    else
      -- re-read: the macro may have changed since the plan was made
      local ok, name, icon, body = pcall(GetMacroInfo, m.idx)
      if ok and name == m.n and body == m.old then
        if pcall(EditMacro, m.idx, name, icon, m.new) then done = done + 1 end
      end
    end
  end
  ML.Record()
  ns.db.clientLocale = clientLocale()
  return done, long
end

-- Called after login: remembers names, detects a language switch.
function ML.OnLogin()
  local cur = clientLocale()
  local last = ns.db.clientLocale
  if last and last ~= cur then
    local plan = ML.Plan(last)
    if #plan.macros > 0 then
      ns.Dialogs.ShowMacroTranslate(plan, true)
      ML.Record()
      return
    end
  end
  ns.db.clientLocale = cur
  ML.Record()
end

-- Accept or dismiss the switch: don't ask again for this language.
function ML.Dismiss() ns.db.clientLocale = clientLocale() end

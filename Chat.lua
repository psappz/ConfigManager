local ADDON, ns = ...
local U = ns.U
local CH = {}
ns.Chat = CH

-- Message types whose colours are copied (missing ones are skipped per version).
CH.COLOR_TYPES = { "SAY", "YELL", "EMOTE", "TEXT_EMOTE", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER", "RAID_WARNING",
  "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "GUILD", "OFFICER", "WHISPER", "WHISPER_INFORM", "BN_WHISPER", "BN_WHISPER_INFORM",
  "SYSTEM", "MONSTER_SAY", "MONSTER_YELL", "MONSTER_EMOTE", "MONSTER_WHISPER", "LOOT", "MONEY", "SKILL",
  "COMBAT_XP_GAIN", "COMBAT_FACTION_CHANGE", "COMBAT_HONOR_GAIN", "CHANNEL1", "CHANNEL2", "CHANNEL3", "CHANNEL4" }

local function call(name, ...)
  local f = _G[name]
  if type(f) ~= "function" then return false end
  return pcall(f, ...)
end

-- Standard (server) channels in client order; indices are language independent.
local function serverChannels()
  if not EnumerateServerChannels then return {} end
  return { EnumerateServerChannels() }
end

local function channelIndex(name, list)
  if type(name) ~= "string" then return end
  for i, base in ipairs(list) do
    if name == base or name:sub(1, #base + 1) == base .. " " then return i end
  end
end

local function numWindows() return NUM_CHAT_WINDOWS or 10 end

function CH.Read()
  if not GetChatWindowInfo then return nil end
  local out = { windows = {}, colors = {} }
  local servers = serverChannels()
  for i = 1, numWindows() do
    local ok, name, size, _, _, _, _, shown, _, docked = pcall(GetChatWindowInfo, i)
    if ok and name and (shown or docked or i <= 2) then
      local w = { n = name, size = size, shown = (shown or docked) and true or false, msgs = {}, chans = {} }
      if GetChatWindowMessages then
        local res = { pcall(GetChatWindowMessages, i) }
        for j = 2, #res do if type(res[j]) == "string" then w.msgs[#w.msgs + 1] = res[j] end end
      end
      if GetChatWindowChannels then
        local res = { pcall(GetChatWindowChannels, i) }
        for j = 2, #res, 2 do
          local idx = channelIndex(res[j], servers)
          if idx then w.chans[#w.chans + 1] = idx end
        end
      end
      out.windows[i] = w
    end
  end
  for _, t in ipairs(CH.COLOR_TYPES) do
    local info = ChatTypeInfo and ChatTypeInfo[t]
    if info and info.r then
      out.colors[t] = { info.r, info.g, info.b, info.colorNameByClass and true or false }
    end
  end
  return out
end

function CH.Preview(c)
  if not c then return 0, 0 end
  local n = 0
  for _ in pairs(c.windows or {}) do n = n + 1 end
  local missing = 0
  for t in pairs(c.colors or {}) do if not (ChatTypeInfo and ChatTypeInfo[t]) then missing = missing + 1 end end
  return n, missing
end

local function frameFor(i, name)
  local f = _G["ChatFrame" .. i]
  if not f then return end
  local ok, _, _, _, _, _, _, shown, _, docked = pcall(GetChatWindowInfo, i)
  if ok and (shown or docked or i <= 2) then return f end
  -- open the next free window under that name
  if FCF_OpenNewWindow then
    local ok2, nf = pcall(FCF_OpenNewWindow, name)
    if ok2 and nf then return nf end
  end
end

function CH.Apply(c)
  if not c then return 0, 0 end
  local applied, missing = 0, 0
  local servers = serverChannels()
  for i = 1, numWindows() do
    local w = c.windows and (c.windows[i] or c.windows[tostring(i)])
    if w and w.shown then
      local f = frameFor(i, w.n)
      if f then
        if w.n and FCF_SetWindowName then pcall(FCF_SetWindowName, f, w.n) end
        if w.size and FCF_SetChatWindowFontSize then pcall(FCF_SetChatWindowFontSize, nil, f, w.size) end
        if ChatFrame_RemoveAllMessageGroups and ChatFrame_AddMessageGroup then
          pcall(ChatFrame_RemoveAllMessageGroups, f)
          for _, g in ipairs(w.msgs or {}) do pcall(ChatFrame_AddMessageGroup, f, g) end
        end
        if ChatFrame_AddChannel then
          if ChatFrame_RemoveAllChannels then pcall(ChatFrame_RemoveAllChannels, f) end
          for _, idx in ipairs(w.chans or {}) do
            if servers[idx] then pcall(ChatFrame_AddChannel, f, servers[idx]) end
          end
        end
        applied = applied + 1
      end
    end
  end
  for t, col in pairs(c.colors or {}) do
    if ChatTypeInfo and ChatTypeInfo[t] then
      call("ChangeChatColor", t, col[1], col[2], col[3])
      if not call("SetChatColorNameByClass", t, col[4]) then call("ToggleChatColorNamesByClassGroup", col[4], t) end
    else
      missing = missing + 1
    end
  end
  return applied, missing
end

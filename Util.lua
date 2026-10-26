local ADDON, ns = ...
local U = {}
ns.U = U

U.COLORS = {
  bg = { 0.078, 0.075, 0.090 }, panel = { 0.106, 0.102, 0.122 }, panel2 = { 0.133, 0.125, 0.149 },
  key = { 0.149, 0.141, 0.169 }, keyEmpty = { 0.110, 0.106, 0.125 }, border = { 0.227, 0.212, 0.251 },
  gold = { 0.890, 0.710, 0.357 }, goldLight = { 0.949, 0.804, 0.510 }, goldDark = { 0.557, 0.455, 0.251 },
  selBg = { 0.227, 0.196, 0.137 }, text = { 0.925, 0.902, 0.855 }, muted = { 0.639, 0.612, 0.561 },
  dim = { 0.431, 0.408, 0.373 }, warn = { 0.941, 0.627, 0.494 }, ok = { 0.498, 0.780, 0.620 },
}
U.CAT_COLORS = {
  ACTIONBAR = { 0.890, 0.710, 0.357 }, MOVEMENT = { 0.435, 0.659, 0.863 }, TARGETING = { 0.878, 0.478, 0.322 },
  INTERFACE = { 0.663, 0.608, 0.902 }, OTHER = { 0.498, 0.780, 0.620 },
}

function U.Print(msg)
  print("|cffe3b55bConfigManager|r: " .. tostring(msg))
end

-- Values the client may hand out as "secret" (Midnight API) are never stored.
function U.Safe(v)
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end

function U.CopyTable(t)
  if type(t) ~= "table" then return t end
  local o = {}
  for k, v in pairs(t) do o[k] = U.CopyTable(v) end
  return o
end

---------------------------------------------------------------------------
-- Serializer: type-tagged, length-prefixed strings (no escaping needed).
---------------------------------------------------------------------------
local function ser(v, out)
  local t = type(v)
  if t == "string" then
    out[#out + 1] = "s" .. #v .. ":" .. v
  elseif t == "number" then
    out[#out + 1] = "n" .. string.format("%.17g", v) .. ";"
  elseif t == "boolean" then
    out[#out + 1] = v and "t" or "f"
  elseif t == "table" then
    out[#out + 1] = "{"
    for k, val in pairs(v) do
      local kt = type(k)
      if (kt == "string" or kt == "number") and (type(val) ~= "function" and type(val) ~= "userdata") then
        ser(k, out); ser(val, out)
      end
    end
    out[#out + 1] = "}"
  else
    out[#out + 1] = "z"
  end
end

function U.Serialize(v)
  local out = {}
  ser(v, out)
  return table.concat(out)
end

local function deser(s, i)
  local c = s:sub(i, i)
  if c == "s" then
    local colon = s:find(":", i + 1, true)
    if not colon then error("bad string") end
    local len = tonumber(s:sub(i + 1, colon - 1))
    if not len then error("bad length") end
    local stop = colon + len
    if stop > #s then error("truncated") end
    return s:sub(colon + 1, stop), stop + 1
  elseif c == "n" then
    local semi = s:find(";", i + 1, true)
    if not semi then error("bad number") end
    local n = tonumber(s:sub(i + 1, semi - 1))
    if not n then error("bad number") end
    return n, semi + 1
  elseif c == "t" then return true, i + 1
  elseif c == "f" then return false, i + 1
  elseif c == "z" then return nil, i + 1
  elseif c == "{" then
    local t = {}
    i = i + 1
    local guard = 0
    while s:sub(i, i) ~= "}" do
      if i > #s then error("unterminated table") end
      local k, v
      k, i = deser(s, i)
      v, i = deser(s, i)
      if k ~= nil then t[k] = v end
      guard = guard + 1
      if guard > 200000 then error("too large") end
    end
    return t, i + 1
  end
  error("unexpected '" .. c .. "' at " .. i)
end

function U.Deserialize(s)
  local ok, v, nexti = pcall(deser, s, 1)
  if not ok then return nil, v end
  if nexti ~= #s + 1 then return nil, "trailing data" end
  return v
end

---------------------------------------------------------------------------
-- Base64
---------------------------------------------------------------------------
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64I = {}
for i = 1, 64 do B64I[B64:byte(i)] = i - 1 end

function U.ToBase64(data)
  local out, n = {}, #data
  for i = 1, n, 3 do
    local a, b, c = data:byte(i, i + 2)
    local v = a * 65536 + (b or 0) * 256 + (c or 0)
    local c1 = math.floor(v / 262144) % 64
    local c2 = math.floor(v / 4096) % 64
    local c3 = math.floor(v / 64) % 64
    local c4 = v % 64
    out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
      .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
  end
  return table.concat(out)
end

function U.FromBase64(s)
  s = s:gsub("[^%w%+/=]", "")
  local out = {}
  for i = 1, #s, 4 do
    local a, b, c, d = s:byte(i, i + 3)
    a, b = B64I[a], B64I[b]
    if not a or not b then return nil end
    local cv, dv = c and B64I[c], d and B64I[d]
    local v = a * 262144 + b * 4096 + (cv or 0) * 64 + (dv or 0)
    out[#out + 1] = string.char(math.floor(v / 65536) % 256)
    if cv then out[#out + 1] = string.char(math.floor(v / 256) % 256) end
    if dv then out[#out + 1] = string.char(v % 256) end
  end
  return table.concat(out)
end

---------------------------------------------------------------------------
-- Export strings: "!CM1D!" = raw DEFLATE + base64, "!CM1P!" = plain base64 (old).
-- Compression uses the client codec where it exists (Forever, Midnight) and the
-- bundled LibDeflate everywhere else, so every version can read every string.
---------------------------------------------------------------------------
local function nativeCodec()
  return C_EncodingUtil and C_EncodingUtil.CompressString and C_EncodingUtil.DecompressString
    and Enum and Enum.CompressionMethod and Enum.CompressionMethod.Deflate
end

local function libDeflate()
  return LibStub and LibStub("LibDeflate", true)
end

function U.Compress(raw)
  if nativeCodec() then
    local ok, packed = pcall(C_EncodingUtil.CompressString, raw, Enum.CompressionMethod.Deflate)
    if ok and type(packed) == "string" then return packed end
  end
  local LD = libDeflate()
  if LD then
    local ok, packed = pcall(LD.CompressDeflate, LD, raw)
    if ok and type(packed) == "string" then return packed end
  end
end

function U.Decompress(bin)
  if nativeCodec() then
    local ok, raw = pcall(C_EncodingUtil.DecompressString, bin, Enum.CompressionMethod.Deflate)
    if ok and type(raw) == "string" and #raw > 0 then return raw end
  end
  local LD = libDeflate()
  if LD then
    local ok, raw = pcall(LD.DecompressDeflate, LD, bin)
    if ok and type(raw) == "string" then return raw end
  end
end

function U.Encode(tbl)
  local raw = U.Serialize(tbl)
  local packed = U.Compress(raw)
  if packed then return "!CM1D!" .. U.ToBase64(packed) end
  return "!CM1P!" .. U.ToBase64(raw)
end

function U.Decode(str)
  if type(str) ~= "string" then return nil, "empty" end
  str = str:gsub("^%s+", ""):gsub("%s+$", "")
  local kind, body = str:match("^!CM1([DP])!(.+)$")
  if not kind then return nil, "prefix" end
  local bin = U.FromBase64(body)
  if not bin then return nil, "base64" end
  if kind == "D" then
    bin = U.Decompress(bin)
    if not bin then return nil, "inflate" end
  end
  local t, err = U.Deserialize(bin)
  if type(t) ~= "table" or t.v ~= 1 then return nil, err or "format" end
  return t
end

---------------------------------------------------------------------------
-- Key chords
---------------------------------------------------------------------------
local MOD_ORDER = { "ALT", "CTRL", "SHIFT", "META" }

-- "CTRL-SHIFT--" -> {CTRL=true, SHIFT=true}, "-"
function U.SplitChord(chord)
  local mods = {}
  local rest = chord
  local changed = true
  while changed do
    changed = false
    for _, m in ipairs(MOD_ORDER) do
      local p = m .. "-"
      if #rest > #p and rest:sub(1, #p) == p then
        mods[m] = true
        rest = rest:sub(#p + 1)
        changed = true
      end
    end
  end
  return mods, rest
end

function U.JoinChord(mods, key)
  local s = ""
  for _, m in ipairs(MOD_ORDER) do
    if mods[m] then s = s .. m .. "-" end
  end
  return s .. key
end

-- Layer code ("", "S", "C", "A", "CS", "AS", "AC", "ACS") <-> modifier set
function U.ModsToCode(mods)
  return (mods.ALT and "A" or "") .. (mods.CTRL and "C" or "") .. (mods.SHIFT and "S" or "")
end

function U.CodeToMods(code)
  return { ALT = code:find("A") and true or nil, CTRL = code:find("C") and true or nil, SHIFT = code:find("S") and true or nil }
end

function U.Timestamp()
  return date and date("%Y-%m-%d %H:%M") or tostring(os and os.time and os.time() or 0)
end

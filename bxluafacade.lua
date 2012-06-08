--
-- bxluafacade.lua
--
luatexbase.provides_module({
  name = 'bxluafacade',
  date = '2012/06/05',
  version = '0.2c',
  description = '',
})

local t_insert, t_remove = table.insert, table.remove

--------------------

function _pre_print_args(n, c, ...)
  local args = { ... }
  local cap = { c }
  if c and type(c) ~= "number" then
    cap = { false }; t_insert(args, 1, c)
  end
  for i = 1, n do
    local x = t_remove(args, 1)
    t_insert(cap, x)
  end
  t_insert(cap, args)
  return unpack(cap)
end

local function _post_print_args(c, args)
  if c then
    return c, unpack(args)
  else
    return unpack(args)
  end
end

--- Extension to tex.print(). Each argument string may contain
-- newline characters, in which case the string is output (to
-- TeX input stream) as multiple lines.
-- @param ... string to output (string)
local function print_(...)
  local cc, args = _pre_print_args(0, ...)
  local lines = {}
  for _, cnk in ipairs(args) do
    local ls = cnk:explode("\n")
    if ls[#ls] == "" then
      t_remove(ls)
    end
    for _, l in ipairs(ls) do
      t_insert(lines, l)
    end
  end
  return tex.print(_post_print_args(cc, lines))
end

local function printf(...)
  local cc, form, args = _pre_print_args(1, ...)
  local t = string.format(form, unpack(args))
  return print_(cc, t)
end

local function writef(...)
  local cc, form, args = _pre_print_args(1, ...)
  local t = string.format(form, unpack(args))
  return tex.write(t)
end

local function sprintf(...)
  local cc, form, args = _pre_print_args(1, ...)
  local t = string.format(form, unpack(args))
  return tex.sprint(cc, t)
end

local function alert(...)
  local cc, form, args = _pre_print_args(1, ...)
  local t = string.format(form, unpack(args))
  return texio.write(t)
end


local glue_spec_id = node.id("glue_spec")

local function copy_skip(s1, s2)
  if not s1 then
    s1 = node.new(glue_spec_id)
  end
  s1.width = s2.width or 0
  s1.stretch = s2.stretch or 0
  s1.stretch_order = s2.stretch_order or 0
  s1.shrink = s2.shrink or 0
  s1.shrink_order = s2.shrink_order or 0
  return s1
end

local function to_dimen(val)
  if val == nil then
    return 0
  elseif type(val) == "number" then
    return val
  else
    return tex.sp(tostring(val))
  end
end

local function parse_dimen(val)
  val = tostring(val):lower()
  local r, fil = val:match("([-.%d]+)fi(l*)")
  if r then
    val, fil = r.."pt", fil:len() + 1
  else
    fil = 0
  end
  return tex.sp(val), fil
end

local function to_skip(val)
  if type(val) == "userdata" then
    return val
  end
  local res = node.new(glue_spec_id)
  if val == nil then
    res.width = 0
  elseif type(val) == "number" then
    res.width = val
  elseif type(val) == "table" then
    copy_skip(res, val)
  else
    local t = tostring(val):lower():explode()
    local w, p, m = t[1], t[3], t[5]
    if t[2] == "minus" then
      p, m = nil, t[3]
    end
    res.width = tex.sp(w)
    if p then
      res.stretch, res.stretch_order = parse_dimen(p)
    end
    if m then
      res.shrink, res.shrink_order = parse_dimen(m)
    end
  end
  return res
end

local function dump_skip(s)
  print(("%s+%s<%s>-%s<%s>"):format(
    s.width or 0, s.stretch or 0, s.stretch_order or 0,
    s.shrink or 0, s.shrink_order or 0))
end

local length = {}
local mt_length = {}; setmetatable(length, mt_length)
function mt_length.__index(tbl, key)
  return tex.skip[key]
end
function mt_length.__newindex(tbl, key, val)
  tex.skip[key] = to_skip(val)
end

local counter = {}
local mt_counter = {}; setmetatable(counter, mt_counter)
function mt_counter.__index(tbl, key)
  return tex.count['c@'..key]
end
function mt_counter.__newindex(tbl, key, val)
  tex.count['c@'..key] = val
end

-------------------- export
bxlt = bxlt or {}
bxlt.print = print_
bxlt.printf = printf
bxlt.writef = writef
bxlt.sprintf = sprintf
bxlt.alert = alert
bxlt.length = length
bxlt.to_dimen = to_dimen
bxlt.to_skip = to_skip
bxlt.counter = counter
bxlt.length = length
bxlt.dump_skip = dump_skip

-- EOF

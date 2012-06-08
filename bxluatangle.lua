--
-- bxluatangle.lua
--
luatexbase.provides_module({
  name = 'bxluatangle',
  date = '2012/06/05',
  version = '0.2',
  description = '',
})
local modname = 'bxlt'
_G[modname] = _G[modname] or {}
local M = _G[modname]
local t_insert, t_remove = table.insert, table.remove
local cctb = luatexbase.catcodetables
local cctb_pkg = cctb['latex-package']
local cctb_soft = cctb['luacode@table@soft']

-------------------- main

local DONE, TEX, STOP = 0, 1, 2
local co_stack = {}
local stat = setmetatable({}, { __mode = 'k' })
local check

local function print_continue_cmd(safe)
  local cmd = safe and "\\bxltg@@continue@safe" or
    "\\bxltg@@continue"
  tex.print(cctb_pkg, cmd)
end

local function print_suspend_cmd(safe)
  if safe then
    tex.print(cctb_pkg, "\\bxltg@@suspend@safe")
  end
end

local function execute_with(safe, func, ...)
  local args = { ... }
  local co = coroutine.create(function()
    return DONE, { func(unpack(args)) }
  end)
  stat[co] = { safe = safe }
  t_insert(co_stack, co)
  return check(coroutine.resume(co, ...))
end

local function tangle_execute(...)
  return execute_with(false, ...)
end

local function _tangle_execute_safe(...)
  return execute_with(true, ...)
end

local function resume_with(intr)
  if #co_stack == 0 then
    error("tangle is not going")
  end
  local co = co_stack[#co_stack]
  return check(coroutine.resume(co, intr))
end

local function tangle_resume()
  return resume_with(false)
end

local function tangle_interrupt()
  return resume_with(true)
end

local function run_tex()
  coroutine.yield(TEX, {})
end

local function tex_(form, ...)
  if type(form) == "string" then
    tex.sprint(cctb.latex, form:format(...))
  end
  run_tex()
end

local function tangle_suspend(...)
  local intr = coroutine.yield(STOP, { ... })
  if intr then
    stat[co_stack[#co_stack]].interrupted = true
    error("*INTR*")
  end
end

-- local (predeclared)
function check(costat, tstat, extra)
  local co = co_stack[#co_stack]
  if not costat then  -- error in coroutine
    local intr = stat[co].interrupted
    t_remove(co_stack)
    if intr then return end
    error(tstat)
  elseif tstat == DONE then
    t_remove(co_stack)
  elseif tstat == TEX then
    print_continue_cmd(stat[co].safe)
  else
    print_suspend_cmd(stat[co].safe)
  end
  return unpack(extra)
end

-------------------- verb-input

local function _parse_as_string(str)
  tex.sprint(cctb.other, str)
end

local function _parse_as_soft_string(str)
  tex.sprint(cctb_soft, str)
end

-------------------- export
M.tangle_execute = tangle_execute
M._tangle_execute_safe = _tangle_execute_safe
M.tangle_resume = tangle_resume
M.tangle_interrupt = tangle_interrupt
M.run_tex = run_tex
M.tex = tex_
M.tangle_suspend = tangle_suspend
M._parse_as_string = _parse_as_string
M._parse_as_soft_string = _parse_as_soft_string
return M
-- EOF

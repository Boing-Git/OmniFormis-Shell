------------------
---- HARDWARE ----
------------------
-- What this machine can handle, detected once per config load, so the same config runs on an
-- NVIDIA desktop and on an old ThinkPad. Low-spec mode is set with LowSpec in variables.lua.

local vars = require("modules.variables")

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local M = {}

-- Proprietary NVIDIA driver loaded
M.nvidia = read_file("/proc/driver/nvidia/version") ~= nil

-- Logical CPUs (threads), 0 when unknown
M.cpu_threads = 0
for line in (read_file("/proc/cpuinfo") or ""):gmatch("[^\n]+") do
    if line:match("^processor%s*:") then
        M.cpu_threads = M.cpu_threads + 1
    end
end

-- Installed RAM in GiB, 0 when unknown
M.mem_gib = (tonumber((read_file("/proc/meminfo") or ""):match("MemTotal:%s*(%d+)")) or 0) / 1048576

-- "auto" counts 4 or fewer CPU threads, or under 6 GiB of RAM, as low-spec. That covers the
-- 2-core ThinkPads from the X220/T420 up to the T470 and anything with 4 GB. Unknown values
-- never count.
local mode = string.lower(tostring(vars.LowSpec or "auto"))
if mode == "on" or mode == "true" then
    M.low_spec = true
elseif mode == "off" or mode == "false" then
    M.low_spec = false
else
    M.low_spec = (M.cpu_threads > 0 and M.cpu_threads <= 4) or (M.mem_gib > 0 and M.mem_gib < 6)
end

-- Quickshell reads the decision from here (theme/Vars.qml), so both follow the same switch.
-- Only written when it changes, since Quickshell watches the file.
local state_path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/omniformis-low-spec"
local state = M.low_spec and "1\n" or "0\n"
if read_file(state_path) ~= state then
    local f = io.open(state_path, "w")
    if f then
        f:write(state)
        f:close()
    end
end

return M

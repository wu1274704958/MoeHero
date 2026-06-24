
require 'filesystem'
local registry = require 'registry'
local ydwe = require 'tools.ydwe'
local subprocess = require 'process'
if not ydwe then
    return
end

local function get_debugger()
    local path = fs.path(os.getenv('USERPROFILE')) / '.vscode' / 'extensions'
    for extpath in path:list_directory() do
        if fs.is_directory(extpath) and extpath:filename():string():sub(1, 20) == 'actboy168.lua-debug-' then
            local dbgpath = extpath / 'windows' / 'x86' / 'debugger.dll'
            if fs.exists(dbgpath) then
                return dbgpath
            end
        end
    end
end

local root = fs.path(arg[1])
if not fs.exists(root / 'MoeHero.w3x') then
    print('地图不存在', root / 'MoeHero.w3x')
    return
end
if get_debugger() then
    --command = command .. ' -debugger 4278'
end

-- 将路径转换为字符串
print("ydwe = " .. tostring(ydwe))
local ydwe_exe = tostring(ydwe / 'YDWE.1.exe')
print("ydwe_exe = " .. ydwe_exe)
local map_file = tostring(root / 'MoeHero.w3x')
-- 使用 os.execute 启动进程
local cmd = string.format('%s -war3 -loadfile %s', ydwe_exe, map_file)

print("执行命令: " .. cmd)

-- 如果需要后台运行（不阻塞当前脚本）
-- cmd = cmd .. " &"

-- 执行命令
local result = os.execute(cmd)

if result ~= true then
    print("启动失败，错误码:", result)
end
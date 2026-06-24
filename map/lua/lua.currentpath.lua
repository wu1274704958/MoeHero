-- 标记为非 release 环境的占位文件
-- 仅需返回 true，使 base.release = not pcall(require, 'lua.currentpath') 为 false
return true

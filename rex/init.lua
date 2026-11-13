rex.bind("shift+super+r", "session.rename")
rex.bind("shift+super+h", "pane.focus.left")
rex.bind("shift+super+j", "pane.focus.down")
rex.bind("shift+super+k", "pane.focus.up")
rex.bind("shift+super+l", "pane.focus.right")

local terminal = "com.superlogical.terminal"

local function block_cwd(block_id)
    local r = rex.block.call(terminal, "pwd", { block_id = block_id })
    local dir = r and r.pwd
    if dir and dir:match("^file://") then
        dir = dir:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(h)
            return string.char(tonumber(h, 16))
        end)
    end
    if dir == nil or dir == "" then
        local p = rex.block.call(terminal, "process", { block_id = block_id })
        dir = p and p.foreground and p.foreground.cwd
    end
    return dir
end

rex.action({
    name = "session_rename_cwd",
    title = "Rename Session to Working Directory",
    run = function(ctx)
        local dir = block_cwd(ctx.block_id)
        if dir == nil or dir == "" then
            error("could not determine the working directory", 0)
        end
        local name = dir:gsub("/+$", ""):match("[^/]+$") or "/"
        local _, err = rex.session.set_label({ label = name })
        if err ~= nil then
            error(err, 0)
        end
    end,
})

rex.bind("alt+super+r", "session_rename_cwd")

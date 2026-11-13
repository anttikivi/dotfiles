---@meta

---@class rex.ActionContext
---@field block_id? string The focused block, when known.

---@class rex.ActionSpec
---@field name string
---@field title string
---@field run fun(ctx: rex.ActionContext)

---@class rex.block
local block = {}

---Call a method on a block provided by a block creator.
---@param creator string The block creator.
---@param method string
---@param params? table
---@return table? result
---@return string? err
function block.call(creator, method, params) end

---@class rex.session
local session = {}

---@param params { label: string, session_id?: string }
---@return table? result
---@return string? err
function session.set_label(params) end

---@class rex
---@field block rex.block
---@field session rex.session
rex = {}

---Bind a key to an action.
---@param key string
---@param action string
function rex.bind(key, action) end

---Remove a key binding.
---@param key string
function rex.unbind(key) end

---Define a custom action.
---@param spec rex.ActionSpec
function rex.action(spec) end

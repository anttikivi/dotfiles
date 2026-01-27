---@class config.lsp.Filter: vim.lsp.get_clients.Filter
---@field filter? fun(client: vim.lsp.Client): boolean

---@class config.Formatter
---@field name string
---@field primary? boolean
---@field format fun(bufnr: number)
---@field sources fun(bufnr: number): string[]
---@field priority number

---@class config.ConformFormatter : conform.FormatterConfigOverride

---@class config.Linter : lint.Linter
---@field name string?
---@field cmd string?
---@field parser (lint.Parser | lint.parse)?
---@field condition function?
---@field prepend_args? (string|fun():string)[]

---@class config.Root
---@field paths string[]
---@field spec config.RootSpec

---@alias config.RootFn fun(buf: number): (string | string[])
---@alias config.RootSpec string | string[] | config.RootFn

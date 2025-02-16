-- ===============================
-- Bootstrap lazy.nvim
-- ===============================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazyrepo = "https://github.com/folke/lazy.nvim.git"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ===============================
-- Global Settings
-- ===============================
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

-- ===============================
-- Plugin Setup (lazy.nvim)
-- ===============================
require("lazy").setup({
  spec = {
    { "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = {}},
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-buffer" },
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "ibhagwan/fzf-lua", dependencies = { "nvim-tree/nvim-web-devicons" }, opts = {}}
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})

-- Apply colorscheme
vim.cmd[[colorscheme tokyonight-storm]]

-- ===============================
-- Completion Setup (nvim-cmp)
-- ===============================
local cmp = require'cmp'
cmp.setup {
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept suggestion
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' }
  }
}

-- ===============================
-- Mason Setup
-- ===============================
require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "gopls", "ruby_lsp", "rubocop" },
  automatic_installation = true
})

-- ===============================
-- LSP Setup
-- ===============================
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local servers = { "lua_ls", "gopls", "ruby_lsp", "rubocop" }

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    capabilities = capabilities,
  })
end

-- Lua-specific LSP configuration
lspconfig.lua_ls.setup {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if path ~= vim.fn.stdpath('config') and (vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc')) then
        return
      end
    end
    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = { version = 'LuaJIT' },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library"
        }
      }
    })
  end,
  settings = { Lua = {} }
}

-- Additional LSP configurations
lspconfig.gopls.setup({})
lspconfig.ruby_lsp.setup({
  cmd = { "rbenv", "exec", "ruby-lsp" }
})
lspconfig.rubocop.setup({
  cmd = { "rbenv", "exec", "rubocop", "--lsp" }
})

-- Grep keymap
vim.keymap.set("n", "<leader>g", require("fzf-lua").live_grep, { noremap = true, silent = true })

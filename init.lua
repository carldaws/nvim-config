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
			{ out,                            "WarningMsg" },
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
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true

-- ===============================
-- Plugin Setup (lazy.nvim)
-- ===============================
require("lazy").setup({
	spec = {
		{ "catppuccin/nvim",                 name = "catppuccin",                              priority = 1000 },
		{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
		{ "neovim/nvim-lspconfig" },
		{ "ibhagwan/fzf-lua",                dependencies = { "nvim-tree/nvim-web-devicons" }, opts = {} },
		{ "nvim-lualine/lualine.nvim",       dependencies = { "nvim-tree/nvim-web-devicons" } },
		{ "akinsho/bufferline.nvim",         version = "*",                                    dependencies = "nvim-tree/nvim-web-devicons" },
		{ "stevearc/oil.nvim",               lazy = false,                                     dependencies = { "nvim-tree/nvim-web-devicons" } },
		{ "folke/noice.nvim",                event = "VeryLazy",                               dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" } },
		{ "carldaws/miser.nvim" },
		{ "carldaws/flotsam.nvim" }
	},
	install = { colorscheme = { "dracula" } },
	checker = { enabled = true },
})

-- ===============================
-- Styling
-- ===============================
vim.cmd("colorscheme catppuccin-mocha")
require("lualine").setup({})
require("bufferline").setup({})
require("noice").setup({
	lsp = {
		-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
	},
	-- you can enable a preset for easier configuration
	presets = {
		bottom_search = true,   -- use a classic bottom cmdline for search
		command_palette = true, -- position the cmdline and popupmenu together
		long_message_to_split = true, -- long messages will be sent to a split
		inc_rename = false,     -- enables an input dialog for inc-rename.nvim
		lsp_doc_border = true,  -- add a border to hover docs and signature help
	},
})

-- ==============================
-- Navigation
-- ==============================
require("oil").setup({ default_file_explorer = true })
vim.keymap.set("n", "-", "<cmd>Oil<CR>")
vim.keymap.set("n", "<leader>f", require("fzf-lua").files, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>g", require("fzf-lua").live_grep, { noremap = true, silent = true })
vim.keymap.set("n", "gt", "<cmd>BufferLinePick<CR>")
vim.keymap.set("n", "<leader>x", "<cmd>bd<CR>")
vim.keymap.set("n", "<leader>c", '"+y')
vim.keymap.set("v", "<leader>c", '"+y')
vim.keymap.set("n", "<leader>v", '"+p')
vim.keymap.set("v", "<leader>v", '"+p')

require("flotsam").setup({
	mappings = {
		{ keymap = "lg", command = "lazygit" },
		{ keymap = "rc", command = "rails console" }
	}
})

-- ===============================
-- Miser Setup
-- ===============================
local miser = require("miser")

miser.setup({
	tools = { "lua-language-server", "ruby-lsp", "rubocop", "gopls", "zls" },
})

-- ===============================
-- LSP Setup
-- ===============================
local lspconfig = require("lspconfig")
local servers = { "lua_ls", "gopls", "ruby_lsp", "rubocop", "zls" }

local format_on_save = function(client, bufnr)
	if client.supports_method("textDocument/formatting") then
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.format({ async = false })
			end,
		})
	end
end

local on_attach = function(client, bufnr)
	vim.keymap.set("n", "gd", require("fzf-lua").lsp_definitions, { noremap = true, silent = true, buffer = bufnr })
	vim.keymap.set("n", "gr", require("fzf-lua").lsp_references, { noremap = true, silent = true, buffer = bufnr })
	format_on_save(client, bufnr)
end

for _, server in ipairs(servers) do
	lspconfig[server].setup({
		on_attach = on_attach,
	})
end

lspconfig.lua_ls.setup({
	on_attach = on_attach,
	on_init = function(client)
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if
				path ~= vim.fn.stdpath("config")
				and (vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc"))
			then
				return
			end
		end
		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
					"${3rd}/luv/library",
				},
			},
		})
	end,
	settings = { Lua = {} },
})

-- ===============================
-- Treesitter Setup
-- ===============================
require("nvim-treesitter.configs").setup({
	ensure_installed = { "lua", "ruby", "javascript", "go" },
	highlight = {
		enable = true,
	},
})

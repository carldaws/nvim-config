local M = {}

local package_mappings = {
	["lua_ls"] = "lua_ls",
	["ruby_lsp"] = "ruby-lsp",
	["rubocop"] = "rubocop",
}

local language_mappings = {
	["lua_ls"] = "lua",
	["ruby_lsp"] = "ruby",
	["rubocop"] = "ruby",
}

local install_mappings = {
	["lua"] = "luarocks install",
	["ruby"] = "gem install",
}

M.config = {
    ensure_installed = {}, -- LSPs to install on startup
    automatic_installation = true, -- Install LSPs when opening a file
}


M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	for _, lsp in ipairs(M.config.ensure_installed) do
		M.install(lsp)
	end

	if M.config.auto_install then
        vim.api.nvim_create_autocmd("BufReadPost", {
            callback = function()
                local filetype = vim.bo.filetype
                for lsp, lang in pairs(language_mappings) do
                    if filetype == lang then
                        M.ensure_installed(lsp)
                    end
                end
            end
        })
    end
end

M.setup_lsp = function(lsp, user_opts)
    local ok, lspconfig = pcall(require, "lspconfig")
    if not ok then
        vim.notify("Miser: Missing dependency 'nvim-lspconfig'. Please install it first!", vim.log.levels.ERROR)
        return
    end

    local language = language_mappings[lsp]

    if not lspconfig[lsp] then
        vim.notify("Miser: No LSP config found for '" .. lsp .. "'", vim.log.levels.ERROR)
        return
    end

    if not language then
        vim.notify("Miser: Unknown language for LSP '" .. lsp .. "'", vim.log.levels.ERROR)
        return
    end

    M.install(lsp)

    -- Generate the correct mise-based command
    local default_cmd = lspconfig[lsp].document_config.default_config.cmd or { package_mappings[lsp] }
	local wrapped_cmd = { "mise", "exec", language, "--" }
	for _, v in ipairs(default_cmd) do
		table.insert(wrapped_cmd, v)
	end

    -- Merge user-provided options with Miser's defaults
    local opts = vim.tbl_deep_extend("force", {
        cmd = default_cmd,
    }, user_opts or {})

    -- Set up the LSP
    lspconfig[lsp].setup(opts)

    vim.notify("Miser: " .. lsp .. " set up successfully!", vim.log.levels.INFO)
end

M.install = function(lsp)
	if vim.fn.executable("mise") == 0 then
		vim.notify("Mise: Mise not found", vim.log.levels.ERROR)
		return
	end

	local language = language_mappings[lsp]
	if not language then
		vim.notify("Miser: Unknown LSP '" .. lsp .. "'", vim.log.levels.ERROR)
		return
	end

	-- Check if the language has a version set in Mise
	local current_version = vim.fn.system("mise current " .. language)
	if current_version == "" or current_version:match("not found") then
		vim.notify(
			"Miser: No version of "
				.. language
				.. " is set in Mise.\n"
				.. "Run: mise use "
				.. language
				.. "@<version> or mise use --global "
				.. language
				.. "@<version>",
			vim.log.levels.ERROR
		)
		return
	end

	-- Check if the LSP is installed
	local lsp_path = vim.fn.system("mise exec -- " .. language .. " which " .. package_mappings[lsp])
	if lsp_path == "" or lsp_path:match("not found") then
		vim.notify("Miser: Installing " .. lsp .. "...", vim.log.levels.INFO)
		vim.fn.system("mise exec -- " .. language .. " " .. install_mappings[language] .. " " .. lsp)
	end

	-- Load and attach LSP
	local lspconfig = require("lspconfig")
	if lspconfig[lsp] then
		local default_cmd = lspconfig[lsp].document_config.default_config.cmd or { lsp }

		local wrapped_cmd = { "mise", "exec", language, "--" }
		for _, x in ipairs(default_cmd) do
			table.insert(wrapped_cmd, x)
		end

		lspconfig[lsp].setup({
			cmd = wrapped_cmd,
			on_attach = function(client, bufnr)
				vim.notify("Miser: " .. lsp .. " attached to buffer " .. bufnr, vim.log.levels.INFO)
			end,
		})
		vim.notify("Miser: " .. lsp .. " installed and attached!", vim.log.levels.INFO)
	else
		vim.notify("Miser: Could not find LSP config for '" .. lsp .. "'", vim.log.levels.ERROR)
	end
end

setmetatable(M, {
    __index = function(_, key)
        return {
            setup = function(user_opts)
                M.setup_lsp(key, user_opts)
            end
        }
    end
})

_G.MiserInstall = M.install

return M

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require "telescope.config" .values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local lspconfig = require "lspconfig"
local db_utils = require("db_picker.util")


local options = {
	on_attach = require("usr.lsp.handlers").on_attach,
	capabilities = require("usr.lsp.handlers").capabilities,
}

local M = {}

--- Terminates all clients that have no buffers attached to it.
M.terminate_detached_clients = function ()
	local clients = vim.lsp.get_active_clients()

	for _, value in ipairs(clients) do
		-- does not work with '#' operator.
		if db_utils.table_size(value.attached_buffers) == 0 then
			value.rpc.terminate()
		end
	end
end

--- Configures the setup of the plugin.
---@param opts table Options that will extend the default configuration.
M.setup = function(opts)
	db_utils.setup(opts)
end

--- Telescope picker changing the compilationDatabasePath where compile_commands.json is located.
---@param directory string|nil Directory to parse for build directories. If nil the cwd is parsed.
---@param bd_path_pattern string|nil Pattern to search for in directory. If nil the default pattern is used.
M.reload = function(directory, bd_path_pattern)
	local opts = require('telescope.themes').get_dropdown{}

	local clients = db_utils.get_active_clients_by_name("clangd")
	local clients_database_path = db_utils.get_database_paths(clients)

	-- The first database paths are from active clients.
	-- The second database paths are detected by parsing the supported directory.
	-- If none is supplied the parsed directory is the cwd.
	local db_paths = db_utils.merge_tables(clients_database_path, db_utils.find_build_dirs(directory, bd_path_pattern))

	if #clients == 0 then
		vim.notify("The clangd server is not running.", vim.log.levels.WARN)
		return
	end

	pickers.new(opts, {
		prompt_title = "compilationDatabasePath",
		finder = finders.new_table {
			results = db_utils.merge_tables(db_paths, db_utils.config.directories),
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				vim.lsp.stop_client(clients, true)

				-- Config defined for clangd
				local clangConfig = require(db_utils.config.lsp_client_path)
				local selection = action_state.get_selected_entry()
				clangConfig.init_options = {compilationDatabasePath = selection[1]}
				clangConfig = vim.tbl_deep_extend("force", clangConfig, options)
				lspconfig['clangd'].setup(clangConfig)

				vim.lsp.start_client(lspconfig['clangd'])
				-- Does not work in here. However, when you call it separately, it works.
				M.terminate_detached_clients()
			end)
			return true
		end,
	}):find()
end

return M

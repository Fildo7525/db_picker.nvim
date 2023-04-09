local M = {}

M.config = {}

M.setup = function (opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", require("db_picker.config"), opts)
end

--- The function checks all the active clients and picks only those with the given name.
---@param clientName string Name of the clients to be returned.
---@return table Table of all the active clients with the given name.
M.get_active_clients_by_name = function (clientName)
	local clients = vim.lsp.get_active_clients()
	local clients_with_client_name = {}
	for _, client in ipairs(clients) do
		if client.config.name == clientName then
			table.insert(clients_with_client_name, client)
		end
	end
	return clients_with_client_name
end

--- Parses the clients and returns the compilationDatabasePath.
---@param clients table Clients to be parsed.
---@return table Table of compilationDatabasePath.
M.get_database_paths = function (clients)
	local database_paths = {}
	for _, client in ipairs(clients) do
		if client.config.init_options.compilationDatabasePath then
			table.insert(database_paths, client.config.init_options.compilationDatabasePath)
		end
	end
	return database_paths
end

--- Returns the size of the table. Sometimes the '#' operator does not work.
---@param table table Table which we want to know the size for.
---@return integer Size of the supplied table.
M.table_size = function (table)
	local size = 0

	for _ in pairs(table) do
		size = size + 1
	end

	return size
end

--- Merge two tables together. The values from the first table are inserted first.
---@param lhs table Table to be inserted first.
---@param rhs table Table to be inserted second.
---@return table Merged table.
M.merge_tables = function (lhs, rhs)
	local copy = lhs
	for _, value in ipairs(rhs) do
		if not vim.tbl_contains(copy, value) then
			table.insert(copy, value)
		end
	end
	return copy
end

M.lsp_config_location = function (server_name)
	local i, t, popen = 0, {}, io.popen

	local config_location = vim.fn.stdpath("config")
	local pfile = popen('find ' .. config_location .. ' -type f -name "*' .. server_name .. '*"')
	if pfile == nil then
		return {}
	end

	for filename in pfile:lines() do
		i = i + 1
		-- Remove the './' prefix from the filename.
		t[i] = filename:sub(3)
	end
	pfile:close()
	return config_location
end

--- Parses the inputed directory for build directories.
---@param directory string|nil Directory to be parsed.
---@param search_pattern string|nil Pattern to be searched for.
---@return table Build directories located in the directory.
M.find_build_dirs = function (directory, search_pattern)
	local i, t, popen = 0, {}, io.popen

	-- default saerch values for directory and search_pattern in case they are not supplied.
	directory = directory or M.config.default.search_directory
	search_pattern = search_pattern or M.config.default.search_pattern

	local pfile = popen('find ' .. directory .. ' -maxdepth 1 -type d -name "*' .. search_pattern .. '*"')
	if pfile == nil then
		return {}
	end

	for filename in pfile:lines() do
		i = i + 1
		-- Remove the './' prefix from the filename.
		t[i] = filename:sub(3)
	end
	pfile:close()

	return t
end

return M

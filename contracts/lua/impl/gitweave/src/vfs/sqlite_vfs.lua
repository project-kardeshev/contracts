local sqlite3 = require("lsqlite3")
local VFS = {}

-- Open SQLite database for virtual file storage
local db = sqlite3.open_memory()
db:exec([[CREATE TABLE IF NOT EXISTS vfs (
    path TEXT PRIMARY KEY,
    data BLOB,
    is_dir INTEGER
)]])

local function split_path(path)
	local sep = "/" -- Adjust if needed for other platforms
	local parts = {}
	for part in string.gmatch(path, "[^" .. sep .. "]+") do
		table.insert(parts, part)
	end
	return parts
end

local function dirname(path)
	return path:match("^(.*)/") or ""
end

local function basename(path)
	return path:match("([^/]+)$") or path
end

function VFS.mkdirp(path)
	local stmt = db:prepare("INSERT OR IGNORE INTO vfs (path, data, is_dir) VALUES (?, NULL, 1)")
	stmt:bind_values(path)
	stmt:step()
	stmt:finalize()
	return true
end

function VFS.open(path, mode)
	if mode == "w" or mode == "wx" then
		VFS.mkdirp(dirname(path))
		local stmt = db:prepare("INSERT OR REPLACE INTO vfs (path, data, is_dir) VALUES (?, ?, 0)")
		stmt:bind_values(path, "")
		stmt:step()
		stmt:finalize()
		return path
	elseif mode == "r" then
		local stmt = db:prepare("SELECT data FROM vfs WHERE path = ? AND is_dir = 0")
		stmt:bind_values(path)
		local result = stmt:step()
		local data = result == sqlite3.ROW and stmt:get_value(0) or nil
		stmt:finalize()
		return data and path or nil, "ENOENT: No such file"
	end
end

function VFS.write(fd, data)
	local stmt = db:prepare("UPDATE vfs SET data = ? WHERE path = ?")
	stmt:bind_values(data, fd)
	stmt:step()
	stmt:finalize()
	return true
end

function VFS.readFile(path)
	local stmt = db:prepare("SELECT data FROM vfs WHERE path = ?")
	stmt:bind_values(path)
	local result = stmt:step()
	local data = result == sqlite3.ROW and stmt:get_value(0) or nil
	stmt:finalize()
	return data, data and nil or "ENOENT: No such file"
end

function VFS.unlink(path)
	local stmt = db:prepare("DELETE FROM vfs WHERE path = ?")
	stmt:bind_values(path)
	stmt:step()
	stmt:finalize()
	return true
end

function VFS.scandir(path)
	local stmt = db:prepare("SELECT path, is_dir FROM vfs WHERE path LIKE ?")
	stmt:bind_values(path .. "%")
	local entries = {}
	for row in stmt:nrows() do
		table.insert(entries, { name = basename(row.path), type = row.is_dir == 1 and "directory" or "file" })
	end
	stmt:finalize()
	local i = 0
	return function()
		i = i + 1
		return entries[i]
	end
end

function VFS.rename(old, new)
	local stmt = db:prepare("UPDATE vfs SET path = ? WHERE path = ?")
	stmt:bind_values(new, old)
	stmt:step()
	stmt:finalize()
	return true
end

return VFS

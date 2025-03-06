local VFS = {}

local function split_path(path)
    local sep = "/"  -- Adjust if needed for other platforms
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

-- In-memory storage
VFS.files = {}
VFS.directories = { ["/"] = {} }

function VFS.mkdirp(path)
    local parts = split_path(path)
    local current = "/"
    for _, part in ipairs(parts) do
        if not VFS.directories[current] then
            VFS.directories[current] = {}
        end
        current = current .. "/" .. part
    end
    VFS.directories[current] = VFS.directories[current] or {}
    return true
end

function VFS.open(path, mode)
    if mode == "w" or mode == "wx" then
        VFS.mkdirp(dirname(path))
        VFS.files[path] = ""
        return path
    elseif mode == "r" then
        if VFS.files[path] then
            return path
        end
    end
    return nil, "ENOENT: No such file"
end

function VFS.write(fd, data)
    if VFS.files[fd] ~= nil then
        VFS.files[fd] = data
        return true
    end
    return false, "Bad file descriptor"
end

function VFS.readFile(path)
    return VFS.files[path], VFS.files[path] and nil or "ENOENT: No such file"
end

function VFS.unlink(path)
    VFS.files[path] = nil
    return true
end

function VFS.scandir(path)
    local entries = {}
    if VFS.directories[path] then
        for name, _ in pairs(VFS.directories[path]) do
            table.insert(entries, { name = name, type = "directory" })
        end
    end
    for file, _ in pairs(VFS.files) do
        if dirname(file) == path then
            table.insert(entries, { name = basename(file), type = "file" })
        end
    end
    local i = 0
    return function()
        i = i + 1
        return entries[i]
    end
end

function VFS.rename(old, new)
    if VFS.files[old] then
        VFS.files[new] = VFS.files[old]
        VFS.files[old] = nil
        return true
    end
    return false, "ENOENT: No such file"
end

return VFS

local ContentHash = {}

local DEFAULT_PATHS = {
	"main.lua",
	"conf.lua",
	"version.txt",
	"src",
	"assets",
}

local cache = {}

local function bytes(value)
	if type(value) == "string" then return value end
	if value and value.getString then return value:getString() end
	error("hash function returned unsupported data")
end

local function hex(value)
	return (bytes(value):gsub(".", function(character)
		return string.format("%02x", string.byte(character))
	end))
end

local function collect(path, files)
	local info = love.filesystem.getInfo(path)
	if not info then return end
	if info.type == "file" then
		files[#files + 1] = path
		return
	end
	if info.type ~= "directory" then return end
	local entries = love.filesystem.getDirectoryItems(path)
	table.sort(entries)
	for _, name in ipairs(entries) do
		if name ~= ".DS_Store" then collect(path .. "/" .. name, files) end
	end
end

function ContentHash.files(paths)
	assert(love and love.filesystem, "LÖVE filesystem is required")
	local files = {}
	for _, path in ipairs(paths or DEFAULT_PATHS) do collect(path, files) end
	table.sort(files)
	return files
end

function ContentHash.invalidate()
	cache = {}
	return true
end

function ContentHash.compute(paths)
	assert(love and love.data and love.data.hash, "LÖVE data hashing is required")
	local files = ContentHash.files(paths)
	local cache_key = table.concat(files, "\0")
	if cache[cache_key] then return cache[cache_key], files end

	local manifest = {}
	for _, path in ipairs(files) do
		local contents, read_error = love.filesystem.read(path)
		if not contents then error("could not hash " .. path .. ": " .. tostring(read_error)) end
		manifest[#manifest + 1] = table.concat({
			path,
			tostring(#contents),
			hex(love.data.hash("sha256", contents)),
		}, "\0")
	end
	local result = hex(love.data.hash("sha256", table.concat(manifest, "\n")))
	cache[cache_key] = result
	return result, files
end

return ContentHash

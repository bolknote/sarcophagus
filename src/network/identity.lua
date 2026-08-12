local Identity = {}

local RANDOM_BYTES = 32

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

function Identity.valid(value)
	return type(value) == "string" and #value == 64
		and value:match("^[0-9a-f]+$") ~= nil
end

local function urandom(length)
	if not io or not io.open then return nil, "io.open is unavailable" end
	local source, open_error = io.open("/dev/urandom", "rb")
	if not source then return nil, tostring(open_error or "could not open /dev/urandom") end
	local value = source:read(length)
	source:close()
	if type(value) ~= "string" or #value ~= length then
		return nil, "short read from /dev/urandom"
	end
	return value
end

local function bcrypt_random(length)
	local loaded, ffi = pcall(require, "ffi")
	if not loaded then return nil, "LuaJIT FFI is unavailable" end
	pcall(ffi.cdef, [[
		typedef long NTSTATUS;
		typedef void *BCRYPT_ALG_HANDLE;
		NTSTATUS BCryptGenRandom(BCRYPT_ALG_HANDLE, unsigned char *, unsigned long, unsigned long);
	]])
	local library_loaded, bcrypt = pcall(ffi.load, "bcrypt")
	if not library_loaded then return nil, tostring(bcrypt) end
	local buffer = ffi.new("unsigned char[?]", length)
	local status = bcrypt.BCryptGenRandom(nil, buffer, length, 0x00000002)
	if tonumber(status) ~= 0 then
		return nil, "BCryptGenRandom failed with status " .. tostring(status)
	end
	return ffi.string(buffer, length)
end

local function arc4random(length)
	local loaded, ffi = pcall(require, "ffi")
	if not loaded then return nil, "LuaJIT FFI is unavailable" end
	pcall(ffi.cdef, "void arc4random_buf(void *buffer, size_t length);")
	local buffer = ffi.new("unsigned char[?]", length)
	local generated, generate_error = pcall(function()
		ffi.C.arc4random_buf(buffer, length)
	end)
	if not generated then return nil, tostring(generate_error) end
	return ffi.string(buffer, length)
end

local function system_random(length)
	local operating_system = love and love.system and love.system.getOS
		and love.system.getOS() or ""
	local providers
	if operating_system == "Windows" then
		providers = { bcrypt_random }
	elseif operating_system == "OS X" or operating_system == "macOS"
		or operating_system == "iOS" then
		providers = { arc4random, urandom }
	else
		providers = { urandom, arc4random }
	end
	local errors = {}
	for _, provider in ipairs(providers) do
		local value, provider_error = provider(length)
		if type(value) == "string" and #value == length then return value end
		errors[#errors + 1] = tostring(provider_error or "secure random provider failed")
	end
	return nil, table.concat(errors, "; ")
end

local function secure_token(kind, prefix, provider)
	provider = provider or system_random
	local random, random_error = provider(RANDOM_BYTES)
	assert(type(random) == "string" and #random == RANDOM_BYTES,
		"secure random unavailable: " .. tostring(random_error or "invalid random bytes"))
	if love and love.data and love.data.hash then
		return hex(love.data.hash("sha256", table.concat({
			tostring(kind),
			tostring(prefix or "token"),
			random,
		}, "\0")))
	end
	return hex(random)
end

function Identity.public_token(prefix, provider)
	return secure_token("public", prefix, provider)
end

function Identity.secret_token(prefix, provider)
	return secure_token("secret", prefix, provider)
end

function Identity.ensure_world(world_state)
	assert(type(world_state) == "table", "world state must be a table")
	if not Identity.valid(world_state.world_id) then
		world_state.world_id = Identity.public_token("world")
	end
	return world_state.world_id
end

return Identity

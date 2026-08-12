local BlobReader = require("src.BlobReader")
local BlobWriter = require("src.BlobWriter")

local Replication = {}

Replication.STATE_MAGIC = "RST3"
Replication.WORLD_MAGIC = "RWD3"
Replication.MAX_RAW_BYTES = 8 * 1024 * 1024
Replication.MAX_STORED_BYTES = 2 * 1024 * 1024
Replication.HEADER_SIZE = 8
local LOVE_LZ4_HEADER_SIZE = 4

local function encode_u32(value)
	assert(type(value) == "number" and value >= 0 and value < 2 ^ 32
		and value == math.floor(value), "invalid replication payload size")
	return string.char(
		math.floor(value / 2 ^ 24) % 256,
		math.floor(value / 2 ^ 16) % 256,
		math.floor(value / 2 ^ 8) % 256,
		value % 256
	)
end

local function decode_u32(value, offset)
	local a, b, c, d = value:byte(offset, offset + 3)
	if not d then return nil end
	return ((a * 256 + b) * 256 + c) * 256 + d
end

local function decode_u32_le(value, offset)
	local a, b, c, d = value:byte(offset, offset + 3)
	if not d then return nil end
	return ((d * 256 + c) * 256 + b) * 256 + a
end

local actor_fields = {
	"actor_version", "actor_id", "actor_role", "ghost", "session_id",
	"truex", "truey", "tx", "ty", "xt", "yt", "state", "oldstate",
	"flip", "animation", "inv", "invsize", "invselect", "iscarry",
	"stats", "buffs", "slow", "slowed", "speedstat", "speed",
	"jumpx", "jumpy", "jump", "fall", "turbox", "rest", "unrest",
	"spenddead", "dying", "isdead", "idlecnt", "digcount", "digcountup",
	"digdone", "digxt", "digyt", "digstart", "digcant", "digback",
	"digspeed", "diganispeed", "candrop", "canthrow", "throw", "travel",
	"canuse", "candrink", "inspect", "cob", "iscob", "fishing",
	"shit", "dishes", "killed", "diet", "quests", "quest", "deaths",
	"unlock_i", "unlock_c", "visited", "ferted",
	"lastshit", "bufftick", "restquality", "restqualityb",
	"network_recovery_time", "network_deaths",
}

-- These tables describe knowledge of the shared world rather than momentary
-- actor state. The host and guest deliberately point at the same instances,
-- so copying them into both actors fifteen times per second is both redundant
-- and very expensive on older CPUs.
local shared_progress_fields = {
	"unlock_i", "unlock_c", "visited", "ferted", "quests",
}

-- Personal history changes much less often than movement, inventory and
-- survival stats. It travels with the shared progress update, but remains
-- actor-owned.
local actor_progress_fields = {
	"shit", "dishes", "killed", "diet", "quest", "deaths",
}

local progress_field = {}
for _, field in ipairs(shared_progress_fields) do progress_field[field] = true end
for _, field in ipairs(actor_progress_fields) do progress_field[field] = true end

local actor_dynamic_fields = {}
for _, field in ipairs(actor_fields) do
	if not progress_field[field] then
		actor_dynamic_fields[#actor_dynamic_fields + 1] = field
	end
end

local function serializable(value, seen)
	local kind = type(value)
	if kind == "nil" or kind == "boolean" or kind == "number"
		or kind == "string" then
		return value
	end
	if kind == "cdata" then return tonumber(value) or 0 end
	if kind ~= "table" then return nil end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local copy = {}
	seen[value] = copy
	for key, nested in next, value do
		local key_kind = type(key)
		if key_kind == "string" or key_kind == "number" or key_kind == "boolean" then
			local copied = serializable(nested, seen)
			if copied ~= nil then copy[key] = copied end
		end
	end
	return copy
end

function Replication.copy_serializable(value)
	return serializable(value)
end

function Replication.capture_actor(actor, fields)
	if type(actor) ~= "table" then return nil end
	local result = {}
	for _, field in ipairs(fields or actor_fields) do
		local copied = serializable(actor[field])
		if copied ~= nil then result[field] = copied end
	end
	return result
end

function Replication.apply_actor(actor, snapshot, options)
	if type(actor) ~= "table" or type(snapshot) ~= "table" then
		return false, "invalid actor replication"
	end
	options = options or {}
	for _, field in ipairs(options.fields or actor_fields) do
		local position = field == "truex" or field == "truey"
		local locally_animated = options.preserve_animation
			and (field == "animation" or field == "oldstate")
		if not locally_animated and (not position or (not options.defer_position
			and not options.ignore_position)) then
			-- Decoded replication packets already own fresh Lua tables. Re-copying
			-- inventories, stats and animation data here doubled allocations at
			-- 15 Hz and caused visible GC hitches on older CPUs.
			--
			-- A playing client advances presentation animation every rendered frame.
			-- Replacing that clock with a slightly older server clock on every state
			-- packet makes a frame boundary alternate back and forth. State remains
			-- authoritative; retaining oldstate makes PlayerAnimation notice a real
			-- state transition and reset the local animation exactly once.
			actor[field] = snapshot[field]
		end
	end
	if options.defer_position then
		actor.network_target_truex = tonumber(snapshot.truex)
		actor.network_target_truey = tonumber(snapshot.truey)
	end
	return true
end

local function encode(magic, payload)
	assert(magic == Replication.STATE_MAGIC or magic == Replication.WORLD_MAGIC,
		"invalid replication packet kind")
	local writer = BlobWriter()
	-- Replication packets are transient and are not checksummed or persisted.
	-- Sorting every nested table made the 15 Hz state stream needlessly costly.
	writer:write(payload)
	local raw = writer:tostring()
	assert(#raw <= Replication.MAX_RAW_BYTES, "replication payload is too large")
	local stored = love.data.compress("string", "lz4", raw)
	assert(#stored <= Replication.MAX_STORED_BYTES, "replication packet is too large")
	return magic .. encode_u32(#raw) .. stored
end

function Replication.encode_state(payload)
	return encode(Replication.STATE_MAGIC, payload)
end

function Replication.encode_world(payload)
	return encode(Replication.WORLD_MAGIC, payload)
end

function Replication.packet_kind(packet)
	if type(packet) ~= "string" or #packet <= Replication.HEADER_SIZE then return nil end
	local magic = packet:sub(1, 4)
	if magic == Replication.STATE_MAGIC then return "state" end
	if magic == Replication.WORLD_MAGIC then return "world" end
	return nil
end

function Replication.decode(packet)
	local kind = Replication.packet_kind(packet)
	if not kind then return nil, "not a replication packet" end
	local expected_size = decode_u32(packet, 5)
	if not expected_size or expected_size < 1
		or expected_size > Replication.MAX_RAW_BYTES then
		return nil, "replication raw size is invalid"
	end
	if #packet - Replication.HEADER_SIZE > Replication.MAX_STORED_BYTES then
		return nil, "replication packet exceeds size limit"
	end
	local stored = packet:sub(Replication.HEADER_SIZE + 1)
	-- LÖVE's string form of an LZ4 block starts with its own little-endian
	-- uncompressed size and allocates that amount before decoding. Inspect that
	-- allocator-facing header before calling into love.data.decompress: checking
	-- only our outer header would still permit a forged compressed bomb.
	if #stored <= LOVE_LZ4_HEADER_SIZE then
		return nil, "replication LZ4 header is invalid"
	end
	local lz4_size = decode_u32_le(stored, 1)
	if not lz4_size or lz4_size < 1 or lz4_size > Replication.MAX_RAW_BYTES then
		return nil, "replication LZ4 raw size is invalid"
	end
	if lz4_size ~= expected_size then
		return nil, "replication raw size mismatch"
	end
	local decompressed, raw = pcall(
		love.data.decompress,
		"string",
		"lz4",
		stored
	)
	if not decompressed then return nil, tostring(raw) end
	if #raw ~= expected_size then
		return nil, "replication raw size mismatch"
	end
	local decoded, value = pcall(function()
		local reader = BlobReader(raw)
		local result = reader:read()
		if reader:position() ~= reader:size() then
			error("trailing replication data")
		end
		return result
	end)
	if not decoded or type(value) ~= "table" then
		return nil, decoded and "invalid replication payload" or tostring(value)
	end
	return value, kind
end

Replication.ACTOR_FIELDS = actor_fields
Replication.ACTOR_DYNAMIC_FIELDS = actor_dynamic_fields
Replication.ACTOR_PROGRESS_FIELDS = actor_progress_fields
Replication.SHARED_PROGRESS_FIELDS = shared_progress_fields

return Replication

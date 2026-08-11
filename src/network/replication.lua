local BlobReader = require("src.BlobReader")
local BlobWriter = require("src.BlobWriter")

local Replication = {}

Replication.STATE_MAGIC = "RST2"
Replication.WORLD_MAGIC = "RWD2"
Replication.MAX_RAW_BYTES = 8 * 1024 * 1024
Replication.MAX_STORED_BYTES = 2 * 1024 * 1024

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
	"shit", "dishes", "killed", "diet", "quests", "quest",
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
	"shit", "dishes", "killed", "diet", "quest",
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
	return magic .. stored
end

function Replication.encode_state(payload)
	return encode(Replication.STATE_MAGIC, payload)
end

function Replication.encode_world(payload)
	return encode(Replication.WORLD_MAGIC, payload)
end

function Replication.packet_kind(packet)
	if type(packet) ~= "string" or #packet < 5 then return nil end
	local magic = packet:sub(1, 4)
	if magic == Replication.STATE_MAGIC then return "state" end
	if magic == Replication.WORLD_MAGIC then return "world" end
	return nil
end

function Replication.decode(packet)
	local kind = Replication.packet_kind(packet)
	if not kind then return nil, "not a replication packet" end
	if #packet - 4 > Replication.MAX_STORED_BYTES then
		return nil, "replication packet exceeds size limit"
	end
	local decompressed, raw = pcall(
		love.data.decompress,
		"string",
		"lz4",
		packet:sub(5)
	)
	if not decompressed then return nil, tostring(raw) end
	if #raw > Replication.MAX_RAW_BYTES then
		return nil, "replication payload exceeds size limit"
	end
	local decoded, value = pcall(function()
		return BlobReader(raw):read()
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

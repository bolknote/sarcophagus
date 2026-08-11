local BlobReader = require("src.BlobReader")
local BlobWriter = require("src.BlobWriter")
local Identity = require("src.network.identity")
local Protocol = require("src.network.protocol")
local StateCopy = require("src.state_copy")

local Snapshot = {}

local MAGIC = "SARCONET"
local FORMAT_VERSION = 1
local HEADER_SIZE = #MAGIC + 1 + 4
local SECTION_COUNT = 8
local CHUNK_MAGIC = "SNAP"
local MAX_RAW_BYTES = 64 * 1024 * 1024
local MAX_STORED_BYTES = 16 * 1024 * 1024
local DEFAULT_CHUNK_BYTES = 32 * 1024
local MAX_CHUNKS = 2048
local MAX_TICK = 9007199254740991

local local_game_fields = {
	autosave = true,
	save_quitting = true,
	pause = true,
	menu = true,
	escmenu = true,
	craft = true,
	achishow = true,
	achipage = true,
	inputing = true,
	textinput = true,
	textinputold = true,
	textinputinfo = true,
	fullscreen = true,
	gr2x = true,
	files = true,
	metasave = true,
	screenshot = true,
	network_time_base = true,
	network_guest_time_delta = true,
	network_last_action_result = true,
	multiplayer_prompt_session = true,
}

local function encode_u16(value)
	if type(value) ~= "number" or value < 1 or value > 65535
		or value ~= math.floor(value) then
		error("invalid snapshot chunk index")
	end
	return string.char(math.floor(value / 256), value % 256)
end

local function decode_u16(value, offset)
	local high, low = value:byte(offset, offset + 1)
	if not low then error("truncated snapshot chunk") end
	return high * 256 + low
end

local function encode_u32(value)
	if type(value) ~= "number" or value < 0 or value >= 2 ^ 32 then
		error("snapshot payload is too large")
	end
	return string.char(
		math.floor(value / 2 ^ 24) % 256,
		math.floor(value / 2 ^ 16) % 256,
		math.floor(value / 2 ^ 8) % 256,
		value % 256
	)
end

local function decode_u32(value, offset)
	local a, b, c, d = value:byte(offset, offset + 3)
	if not d then error("truncated snapshot header") end
	return ((a * 256 + b) * 256 + c) * 256 + d
end

local function bytes(value)
	if type(value) == "string" then return value end
	if value and value.getString then return value:getString() end
	error("unsupported hash data")
end

local function checksum(value)
	return (bytes(love.data.hash("sha256", value)):gsub(".", function(character)
		return string.format("%02x", string.byte(character))
	end))
end

local function integer_between(value, minimum, maximum)
	return type(value) == "number" and value == value
		and value ~= math.huge and value ~= -math.huge
		and value >= minimum and value <= maximum
		and value == math.floor(value)
end

local function valid_header(header)
	return type(header) == "table"
		and header.version == Protocol.SNAPSHOT_VERSION
		and integer_between(header.tick, 0, MAX_TICK)
		and Identity.valid(header.world_id)
		and Identity.valid(header.session_id)
end

local function gzip_declared_size(value)
	if #value < 4 then return nil end
	local a, b, c, d = value:byte(-4, -1)
	return a + b * 256 + c * 65536 + d * 16777216
end

local function copy_game(game_state)
	local copy = StateCopy.copy(game_state)
	for field in pairs(local_game_fields) do copy[field] = nil end
	return copy
end

function Snapshot.capture(state)
	assert(type(state) == "table", "snapshot state is required")
	assert(type(state.world) == "table", "snapshot world is required")
	assert(type(state.game) == "table", "snapshot game state is required")
	assert(type(state.host_actor) == "table", "snapshot host actor is required")
	assert(type(state.guest_actor) == "table", "snapshot guest actor is required")
	local snapshot = {
		header = {
			version = Protocol.SNAPSHOT_VERSION,
			tick = math.max(0, math.floor(tonumber(state.tick) or 0)),
			world_id = state.world_id or state.game.world_id,
			session_id = state.session_id,
		},
		world = StateCopy.copy(state.world),
		game = copy_game(state.game),
		host_actor = StateCopy.copy(state.host_actor),
		guest_actor = StateCopy.copy(state.guest_actor),
		tips = StateCopy.copy(state.tips or {}),
		disp = StateCopy.copy(state.disp or {}),
		mobs = StateCopy.copy(state.mobs or {}),
	}
	assert(valid_header(snapshot.header), "invalid snapshot identity or tick")
	return snapshot
end

function Snapshot.serialize(snapshot)
	assert(type(snapshot) == "table", "snapshot must be a table")
	assert(valid_header(snapshot.header), "invalid snapshot header")
	local blob = BlobWriter()
	for _, field in ipairs({
		"header", "world", "game", "host_actor",
		"guest_actor", "tips", "disp", "mobs",
	}) do
		if type(snapshot[field]) ~= "table" then
			error("invalid snapshot section " .. field)
		end
		blob:write(snapshot[field])
	end
	local raw = blob:tostring()
	if #raw > MAX_RAW_BYTES then error("snapshot exceeds raw size limit") end
	local compressed = love.data.compress("string", "gzip", raw, 6)
	local stored = MAGIC .. string.char(FORMAT_VERSION) .. encode_u32(#raw) .. compressed
	if #stored > MAX_STORED_BYTES then error("snapshot exceeds stored size limit") end
	return stored, {
		snapshot_version = Protocol.SNAPSHOT_VERSION,
		raw_size = #raw,
		stored_size = #stored,
		checksum = checksum(stored),
		tick = snapshot.header.tick,
		world_id = snapshot.header.world_id,
		session_id = snapshot.header.session_id,
	}
end

function Snapshot.deserialize(stored)
	if type(stored) ~= "string" or #stored > MAX_STORED_BYTES then
		return nil, "invalid stored snapshot size"
	end
	if stored:sub(1, #MAGIC) ~= MAGIC or #stored < HEADER_SIZE then
		return nil, "invalid snapshot container"
	end
	local version = stored:byte(#MAGIC + 1)
	if version ~= FORMAT_VERSION then return nil, "unsupported snapshot format" end
	local expected_size = decode_u32(stored, #MAGIC + 2)
	if expected_size > MAX_RAW_BYTES then return nil, "snapshot raw size is too large" end
	local compressed = stored:sub(HEADER_SIZE + 1)
	if gzip_declared_size(compressed) ~= expected_size then
		return nil, "snapshot gzip size mismatch"
	end
	local decompressed, raw = pcall(
		love.data.decompress,
		"string",
		"gzip",
		compressed
	)
	if not decompressed then return nil, tostring(raw) end
	if #raw ~= expected_size then return nil, "snapshot raw size mismatch" end

	local decoded, result = pcall(function()
		local blob = BlobReader(raw)
		local value = {
			header = blob:read(),
			world = blob:read(),
			game = blob:read(),
			host_actor = blob:read(),
			guest_actor = blob:read(),
			tips = blob:read(),
			disp = blob:read(),
			mobs = blob:read(),
		}
		if blob:position() ~= blob:size() then error("trailing snapshot data") end
		return value
	end)
	if not decoded then return nil, tostring(result) end
	for _, field in ipairs({
		"header", "world", "game", "host_actor",
		"guest_actor", "tips", "disp", "mobs",
	}) do
		if type(result[field]) ~= "table" then return nil, "invalid snapshot section" end
	end
	if not valid_header(result.header) then return nil, "invalid snapshot header" end
	return result
end

function Snapshot.chunks(stored, meta, chunk_size)
	chunk_size = math.floor(tonumber(chunk_size) or DEFAULT_CHUNK_BYTES)
	if chunk_size < 1024 or chunk_size > 60 * 1024 then
		error("invalid snapshot chunk size")
	end
	local count = math.ceil(#stored / chunk_size)
	if count < 1 or count > MAX_CHUNKS then error("invalid snapshot chunk count") end
	local chunks = {}
	for index = 1, count do
		local first = (index - 1) * chunk_size + 1
		chunks[index] = CHUNK_MAGIC .. encode_u16(index)
			.. stored:sub(first, first + chunk_size - 1)
	end
	local description = StateCopy.copy(meta or {})
	description.chunk_count = count
	description.chunk_size = chunk_size
	return chunks, description
end

function Snapshot.decode_chunk(packet)
	if type(packet) ~= "string" or packet:sub(1, #CHUNK_MAGIC) ~= CHUNK_MAGIC
		or #packet <= #CHUNK_MAGIC + 2
		or #packet > #CHUNK_MAGIC + 2 + 60 * 1024 then
		return nil, "invalid snapshot chunk"
	end
	return decode_u16(packet, #CHUNK_MAGIC + 1), packet:sub(#CHUNK_MAGIC + 3)
end

local Assembler = {}
Assembler.__index = Assembler

function Snapshot.new_assembler(meta)
	if type(meta) ~= "table" then return nil, "invalid snapshot metadata" end
	local count = meta.chunk_count
	local stored_size = meta.stored_size
	local raw_size = meta.raw_size
	local chunk_size = meta.chunk_size
	if not integer_between(count, 1, MAX_CHUNKS) then
		return nil, "invalid snapshot chunk count"
	end
	if not integer_between(stored_size, HEADER_SIZE, MAX_STORED_BYTES) then
		return nil, "invalid snapshot stored size"
	end
	if not integer_between(raw_size, 1, MAX_RAW_BYTES) then
		return nil, "invalid snapshot raw size"
	end
	if not integer_between(chunk_size, 1024, 60 * 1024)
		or count ~= math.ceil(stored_size / chunk_size) then
		return nil, "invalid snapshot chunk size"
	end
	if type(meta.checksum) ~= "string" or #meta.checksum ~= 64
		or not meta.checksum:match("^[0-9a-f]+$") then
		return nil, "invalid snapshot checksum"
	end
	if meta.snapshot_version ~= Protocol.SNAPSHOT_VERSION
		or not integer_between(meta.tick, 0, MAX_TICK)
		or not Identity.valid(meta.world_id)
		or not Identity.valid(meta.session_id) then
		return nil, "invalid snapshot metadata identity"
	end
	local normalized = {
		snapshot_version = meta.snapshot_version,
		tick = meta.tick,
		world_id = meta.world_id,
		session_id = meta.session_id,
		chunk_count = count,
		chunk_size = chunk_size,
		stored_size = stored_size,
		raw_size = raw_size,
		checksum = meta.checksum,
	}
	return setmetatable({ meta = normalized, chunks = {}, received = 0, bytes = 0 }, Assembler)
end

function Assembler:add(packet)
	local index, data = Snapshot.decode_chunk(packet)
	if not index then return false, data end
	if index > self.meta.chunk_count then return false, "snapshot chunk out of range" end
	local expected_bytes = index < self.meta.chunk_count and self.meta.chunk_size
		or self.meta.stored_size - (self.meta.chunk_count - 1) * self.meta.chunk_size
	if #data ~= expected_bytes then return false, "invalid snapshot chunk size" end
	if self.chunks[index] then
		if self.chunks[index] ~= data then return false, "conflicting snapshot chunk" end
		return true, "duplicate"
	end
	self.bytes = self.bytes + #data
	if self.bytes > self.meta.stored_size then return false, "snapshot exceeds declared size" end
	self.chunks[index] = data
	self.received = self.received + 1
	return true
end

function Assembler:complete()
	return self.received == self.meta.chunk_count
end

function Assembler:finish()
	if not self:complete() then return nil, "snapshot is incomplete" end
	local stored = table.concat(self.chunks)
	if #stored ~= self.meta.stored_size then return nil, "snapshot stored size mismatch" end
	if checksum(stored) ~= self.meta.checksum then return nil, "snapshot checksum mismatch" end
	local snapshot, snapshot_error = Snapshot.deserialize(stored)
	if not snapshot then return nil, snapshot_error end
	local header = snapshot.header
	if header.tick ~= self.meta.tick or header.world_id ~= self.meta.world_id
		or header.session_id ~= self.meta.session_id then
		return nil, "snapshot metadata mismatch"
	end
	return snapshot
end

Snapshot.SECTION_COUNT = SECTION_COUNT
Snapshot.MAX_RAW_BYTES = MAX_RAW_BYTES
Snapshot.MAX_STORED_BYTES = MAX_STORED_BYTES

return Snapshot

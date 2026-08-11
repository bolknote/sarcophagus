local json = require("src.json")
local Identity = require("src.network.identity")

local utf8_ok, utf8lib = pcall(require, "utf8")

local Protocol = {}

local UTF8_REPLACEMENT = "\239\191\189"

local function utf8_sequence_length(value, index)
	local first = value:byte(index)
	if not first then return nil end
	if first <= 0x7f then return 1 end
	local second = value:byte(index + 1)
	if first >= 0xc2 and first <= 0xdf
		and second and second >= 0x80 and second <= 0xbf then
		return 2
	end
	local third = value:byte(index + 2)
	if first == 0xe0 and second and second >= 0xa0 and second <= 0xbf
		and third and third >= 0x80 and third <= 0xbf then
		return 3
	end
	if ((first >= 0xe1 and first <= 0xec) or (first >= 0xee and first <= 0xef))
		and second and second >= 0x80 and second <= 0xbf
		and third and third >= 0x80 and third <= 0xbf then
		return 3
	end
	if first == 0xed and second and second >= 0x80 and second <= 0x9f
		and third and third >= 0x80 and third <= 0xbf then
		return 3
	end
	local fourth = value:byte(index + 3)
	if first == 0xf0 and second and second >= 0x90 and second <= 0xbf
		and third and third >= 0x80 and third <= 0xbf
		and fourth and fourth >= 0x80 and fourth <= 0xbf then
		return 4
	end
	if first >= 0xf1 and first <= 0xf3
		and second and second >= 0x80 and second <= 0xbf
		and third and third >= 0x80 and third <= 0xbf
		and fourth and fourth >= 0x80 and fourth <= 0xbf then
		return 4
	end
	if first == 0xf4 and second and second >= 0x80 and second <= 0x8f
		and third and third >= 0x80 and third <= 0xbf
		and fourth and fourth >= 0x80 and fourth <= 0xbf then
		return 4
	end
	return nil
end

-- Network and operating-system error strings eventually reach LÖVE's font
-- renderer. One malformed byte must not be able to crash the whole menu.
-- This deliberately preserves newlines and other valid ASCII used by UI text;
-- protocol field validation remains stricter through bounded_string().
function Protocol.sanitize_utf8(value, maximum)
	value = tostring(value or "")
	maximum = tonumber(maximum)
	if maximum then maximum = math.max(0, math.floor(maximum)) end
	local output, bytes, index = {}, 0, 1
	while index <= #value do
		local length = utf8_sequence_length(value, index)
		local chunk = length and value:sub(index, index + length - 1)
			or UTF8_REPLACEMENT
		if maximum and bytes + #chunk > maximum then break end
		output[#output + 1] = chunk
		bytes = bytes + #chunk
		index = index + (length or 1)
	end
	return table.concat(output)
end

Protocol.VERSION = 1
Protocol.SNAPSHOT_VERSION = 1
Protocol.DEFAULT_GAMEPLAY_PORT = 22122
Protocol.CHANNEL = {
	CONTROL = 0,
	SNAPSHOT = 1,
	WORLD = 2,
	INPUT = 3,
	STATE = 4,
}
Protocol.MAX_MESSAGE_BYTES = 64 * 1024
Protocol.MAX_INPUT_BYTES = 4 * 1024
Protocol.REQUIRED_CAPABILITIES = {
	"snapshot-v1",
	"input-v1",
	"actions-v1",
}

local message_kinds = {
	hello = true,
	welcome = true,
	reject = true,
	ready = true,
	start = true,
	input = true,
	action = true,
	action_result = true,
	event = true,
	snapshot_meta = true,
	snapshot_chunk = true,
	snapshot_done = true,
	disconnect = true,
	shutdown = true,
	ping = true,
	pong = true,
}

local function bounded_string(value, maximum)
	if type(value) ~= "string" or #value == 0 or #value > maximum
		or value:find("[%z\1-\31\127]") then
		return false
	end
	if utf8_ok and utf8lib and utf8lib.len then
		local checked, length = pcall(utf8lib.len, value)
		if not checked or length == nil then return false end
	end
	return true
end

local function normalized_version(value)
	if type(value) ~= "string" then return nil end
	value = value:match("^%s*(.-)%s*$")
	if not bounded_string(value, 64) then return nil end
	return value
end

local function nonnegative_integer(value, maximum)
	return type(value) == "number" and value == value
		and value ~= math.huge and value ~= -math.huge
		and value >= 0 and value <= (maximum or 2147483647)
		and value == math.floor(value)
end

function Protocol.is_message_kind(kind)
	return message_kinds[kind] == true
end

function Protocol.encode(kind, payload)
	assert(Protocol.is_message_kind(kind), "unknown protocol message")
	payload = payload or {}
	assert(type(payload) == "table", "protocol payload must be a table")
	local encoded = json.encode({
		v = Protocol.VERSION,
		t = kind,
		p = payload,
	})
	local maximum = kind == "input" and Protocol.MAX_INPUT_BYTES
		or Protocol.MAX_MESSAGE_BYTES
	assert(#encoded <= maximum, "protocol message exceeds size limit")
	return encoded
end

function Protocol.decode(encoded)
	if type(encoded) ~= "string" then return nil, "message is not a string" end
	if #encoded == 0 then return nil, "message is empty" end
	if #encoded > Protocol.MAX_MESSAGE_BYTES then return nil, "message is too large" end

	local decoded, envelope = pcall(json.decode, encoded)
	if not decoded then return nil, "invalid json: " .. tostring(envelope) end
	if type(envelope) ~= "table" then return nil, "invalid message envelope" end
	if envelope.v ~= Protocol.VERSION then return nil, "protocol version mismatch" end
	if not Protocol.is_message_kind(envelope.t) then return nil, "unknown message type" end
	if type(envelope.p) ~= "table" then return nil, "invalid message payload" end
	if envelope.t == "input" and #encoded > Protocol.MAX_INPUT_BYTES then
		return nil, "input message is too large"
	end
	return {
		kind = envelope.t,
		payload = envelope.p,
	}
end

function Protocol.hello(options)
	options = options or {}
	return {
		protocol_version = Protocol.VERSION,
		game_version = normalized_version(options.game_version) or "unknown",
		content_hash = options.content_hash,
		capabilities = options.capabilities or {},
		client_nonce = options.client_nonce,
	}
end

function Protocol.validate_hello(hello, expected)
	expected = expected or {}
	if type(hello) ~= "table" then return false, "invalid_hello" end
	if hello.protocol_version ~= Protocol.VERSION then
		return false, "protocol_mismatch"
	end
	local game_version = normalized_version(hello.game_version)
	local expected_version = normalized_version(expected.game_version)
	if not game_version or (expected_version and game_version ~= expected_version) then
		return false, "game_version_mismatch"
	end
	if not Identity.valid(hello.content_hash) then
		return false, "invalid_content_hash"
	end
	if expected.content_hash and hello.content_hash ~= expected.content_hash then
		return false, "content_mismatch"
	end
	if type(hello.capabilities) ~= "table" or #hello.capabilities > 32 then
		return false, "invalid_capabilities"
	end
	local capability_count = 0
	for key in pairs(hello.capabilities) do
		capability_count = capability_count + 1
		if type(key) ~= "number" or key < 1 or key > #hello.capabilities
			or key ~= math.floor(key) then
			return false, "invalid_capabilities"
		end
	end
	if capability_count ~= #hello.capabilities then
		return false, "invalid_capabilities"
	end
	for _, capability in ipairs(hello.capabilities) do
		if not bounded_string(capability, 64)
			or not capability:match("^[%w_.:%-]+$") then
			return false, "invalid_capability"
		end
	end
	local available = {}
	for _, capability in ipairs(hello.capabilities) do
		if available[capability] then return false, "duplicate_capability" end
		available[capability] = true
	end
	for _, required in ipairs(expected.capabilities or Protocol.REQUIRED_CAPABILITIES) do
		if not available[required] then return false, "missing_capability" end
	end
	if not Identity.valid(hello.client_nonce) then
		return false, "invalid_client_nonce"
	end
	if hello.reconnect_token ~= nil and not Identity.valid(hello.reconnect_token) then
		return false, "invalid_reconnect_token"
	end
	return true
end

function Protocol.validate_action_id(action_id)
	if type(action_id) == "number" then
		return nonnegative_integer(action_id, 2147483647)
	end
	return bounded_string(action_id, 64)
		and action_id:match("^[%w_.:%-]+$") ~= nil
end

function Protocol.validate_identity(value)
	return Identity.valid(value)
end

function Protocol.validate_string(value, maximum)
	return bounded_string(value, maximum)
end

function Protocol.validate_nonnegative_integer(value, maximum)
	return nonnegative_integer(value, maximum)
end

return Protocol

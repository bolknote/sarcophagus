local SaveFormat = {}

local MAGIC = "SARCOSAV"
local VERSION = 1
local CODEC_GZIP = 1
local HEADER_SIZE = #MAGIC + 1 + 1 + 4

local function encode_u32(value)
	if type(value) ~= "number" or value < 0 or value >= 2 ^ 32 then
		error("save payload is too large")
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
	if not d then
		error("truncated save header")
	end
	return ((a * 256 + b) * 256 + c) * 256 + d
end

function SaveFormat.header_size()
	return HEADER_SIZE
end

function SaveFormat.is_container(value)
	return type(value) == "string" and value:sub(1, #MAGIC) == MAGIC
end

function SaveFormat.raw_size(value)
	if not SaveFormat.is_container(value) or #value < HEADER_SIZE then
		return nil
	end
	return decode_u32(value, #MAGIC + 3)
end

function SaveFormat.encode(raw, compression_level)
	if type(raw) ~= "string" then
		error("save payload must be a string")
	end

	local compressed = love.data.compress(
		"string",
		"gzip",
		raw,
		compression_level or 6
	)
	return MAGIC
		.. string.char(VERSION, CODEC_GZIP)
		.. encode_u32(#raw)
		.. compressed
end

function SaveFormat.decode(stored, legacy_compressed)
	if type(stored) ~= "string" then
		error("save data must be a string")
	end

	if not SaveFormat.is_container(stored) then
		if legacy_compressed then
			return love.data.decompress("string", "gzip", stored)
		end
		return stored
	end

	if #stored < HEADER_SIZE then
		error("truncated save container")
	end

	local version, codec = stored:byte(#MAGIC + 1, #MAGIC + 2)
	if version ~= VERSION then
		error("unsupported save container version " .. tostring(version))
	end
	if codec ~= CODEC_GZIP then
		error("unsupported save compression codec " .. tostring(codec))
	end

	local expected_size = decode_u32(stored, #MAGIC + 3)
	local raw = love.data.decompress(
		"string",
		"gzip",
		stored:sub(HEADER_SIZE + 1)
	)
	if #raw ~= expected_size then
		error(("save size mismatch: expected %d, got %d"):format(
			expected_size,
			#raw
		))
	end
	return raw
end

return SaveFormat

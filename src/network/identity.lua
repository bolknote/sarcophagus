local Identity = {}

local function bytes(value)
	if type(value) == "string" then return value end
	if value and value.getString then return value:getString() end
	return tostring(value)
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

function Identity.token(prefix)
	local timer = love and love.timer and love.timer.getTime() or os.clock()
	local random = love and love.math and love.math.random() or math.random()
	local seed = table.concat({
		tostring(prefix or "token"),
		tostring(timer),
		tostring(os.time()),
		tostring(random),
		tostring({}),
	}, ":")
	if love and love.data and love.data.hash then
		return hex(love.data.hash("sha256", seed))
	end
	return string.format("%064x", math.floor(random * 2147483647))
end

function Identity.ensure_world(world_state)
	assert(type(world_state) == "table", "world state must be a table")
	if not Identity.valid(world_state.world_id) then
		world_state.world_id = Identity.token("world")
	end
	return world_state.world_id
end

return Identity

local InputState = {}

local MAX_SEQUENCE = 2147483647
local gameplay_actions = {
	"w", "s", "a", "d", "e", "space", "r", "lshift", "rshift",
	"mouse1", "mouse2",
}
local allowed_actions = {}
for _, action in ipairs(gameplay_actions) do allowed_actions[action] = true end
local allowed_aim = {
	world_x = true,
	world_y = true,
	tile_x = true,
	tile_y = true,
}
local MAX_AIM_VALUE = 1024 * 1024

local function valid_action(action)
	return type(action) == "string" and allowed_actions[action] == true
end

local function valid_aim(key, value)
	return allowed_aim[key] == true and type(value) == "number"
		and value == value and value ~= math.huge and value ~= -math.huge
		and math.abs(value) <= MAX_AIM_VALUE
end

local function normalized_sequence(sequence, fallback)
	if type(sequence) ~= "number" or sequence < 0 or sequence > MAX_SEQUENCE
		or sequence ~= math.floor(sequence) then
		return fallback
	end
	return sequence
end

function InputState.new()
	return {
		sequence = 0,
		held = {},
		pressed = {},
		released = {},
		aim = {},
	}
end

function InputState.set_button(state, action, down)
	assert(type(state) == "table", "input state must be a table")
	assert(valid_action(action), "invalid input action")
	state.held = state.held or {}
	state.pressed = state.pressed or {}
	state.released = state.released or {}

	down = not not down
	local previous = not not state.held[action]
	if down == previous then return false end

	state.held[action] = down or nil
	if down then
		state.pressed[action] = true
		state.released[action] = nil
	else
		state.released[action] = true
		state.pressed[action] = nil
	end
	return true
end

function InputState.is_down(state, action)
	return type(state) == "table" and type(state.held) == "table"
		and not not state.held[action]
end

function InputState.advance(state)
	assert(type(state) == "table", "input state must be a table")
	state.sequence = (normalized_sequence(state.sequence, 0) + 1)
		% (MAX_SEQUENCE + 1)
	state.pressed = {}
	state.released = {}
	return state.sequence
end

function InputState.snapshot(state)
	assert(type(state) == "table", "input state must be a table")
	local held = {}
	for action, down in pairs(state.held or {}) do
		if down and valid_action(action) then held[action] = true end
	end
	local aim = {}
	for key, value in pairs(state.aim or {}) do
		if valid_aim(key, value) then
			aim[key] = value
		end
	end
	return {
		sequence = normalized_sequence(state.sequence, 0),
		held = held,
		aim = aim,
	}
end

function InputState.capture(state, getter, aim)
	assert(type(state) == "table", "input state must be a table")
	assert(type(getter) == "function", "input getter must be a function")
	for _, action in ipairs(gameplay_actions) do
		InputState.set_button(state, action, not not getter(action))
	end
	state.aim = state.aim or {}
	for key in pairs(state.aim) do state.aim[key] = nil end
	for key, value in pairs(aim or {}) do
		if valid_aim(key, value) then
			state.aim[key] = value
		end
	end
	InputState.advance(state)
	return state
end

function InputState.apply_snapshot(state, snapshot)
	assert(type(state) == "table", "input state must be a table")
	if type(snapshot) ~= "table" or type(snapshot.held) ~= "table"
		or (snapshot.aim ~= nil and type(snapshot.aim) ~= "table") then
		return false, "invalid input snapshot"
	end
	local sequence = normalized_sequence(snapshot.sequence)
	if sequence == nil then return false, "invalid input sequence" end

	local held = {}
	local held_count = 0
	for action, down in pairs(snapshot.held) do
		held_count = held_count + 1
		if held_count > #gameplay_actions or down ~= true then
			return false, "invalid input buttons"
		end
		if not valid_action(action) then return false, "invalid input action" end
		held[action] = true
	end
	local aim = {}
	for key, value in pairs(snapshot.aim or {}) do
		if not valid_aim(key, value) then
			return false, "invalid aim value"
		end
		aim[key] = value
	end

	-- Commit only after every field has been checked. A malformed tail cannot
	-- clear or partially replace the last valid controls on the server.
	state.held = held
	state.aim = aim
	state.sequence = sequence
	state.pressed = {}
	state.released = {}
	return true
end

InputState.MAX_SEQUENCE = MAX_SEQUENCE
InputState.ACTIONS = gameplay_actions

return InputState

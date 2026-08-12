local GameAdapter = {}
GameAdapter.__index = GameAdapter

local required_callbacks = {
	"state_provider",
	"state_applier",
	"spawn_provider",
	"dropper",
	"action_handler",
	"action_rejection_handler",
	"simulation_handler",
	"replication_provider",
	"replication_applier",
	"world_delta_provider",
	"world_delta_applier",
	"world_delta_reset",
	"catchup_validator",
	"event_provider",
	"event_handler",
	"event_reset",
	"action_result_handler",
}

function GameAdapter.new(callbacks)
	assert(type(callbacks) == "table", "network game callbacks are required")
	local bound = {}
	for _, name in ipairs(required_callbacks) do
		assert(type(callbacks[name]) == "function",
			"network game callback is missing: " .. name)
		bound[name] = callbacks[name]
	end
	if callbacks.input_handler ~= nil then
		assert(type(callbacks.input_handler) == "function",
			"network input handler must be a function")
		bound.input_handler = callbacks.input_handler
	end
	return setmetatable({ callbacks = bound }, GameAdapter)
end

function GameAdapter:runtime_options(base)
	local options = {}
	for name, value in pairs(base or {}) do options[name] = value end
	for name, callback in pairs(self.callbacks) do options[name] = callback end
	return options
end

function GameAdapter.required_callbacks()
	local result = {}
	for index, name in ipairs(required_callbacks) do result[index] = name end
	return result
end

return GameAdapter

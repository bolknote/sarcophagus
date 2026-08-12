local StateCopy = require("src.state_copy")

local ActorContext = {}

local game_fields = {
	"craft",
	"achishow",
	"achipage",
	"inputing",
	"textinput",
	"textinputold",
	"textinputinfo",
	"gui_throw_down",
	"gui_mouse_down",
	"altitem",
	"showroom",
	"attackcd",
	"attackcursor",
	"attacked",
	"digdone",
	"idle",
	"lastgodown",
	"lasthit",
	"justremoved",
	"moved",
	"pass",
	"stepup",
	"throwcd",
}

local craft_fields = {
	"pointer",
	"item_recipies",
	"items",
	"str",
	"strinfo",
	"cando",
	"multitem",
	"singleitem",
	"reqblock",
	"dura",
	"itemst",
}

local transient_globals = {
	"togo",
	"haswater",
	"ithrow",
	"testthrow",
	"altshow",
	"altold",
	"ctrshow",
	"ctrold",
}

-- Some gameplay systems still keep actor-owned state in module globals. Keep
-- those values in the runtime sidecar while an actor is not the active one so
-- the host and guest cannot steal each other's fishing session.
local actor_globals = {
	"fishing",
}

local field_groups = {
	game = game_fields,
	craft = craft_fields,
	transient_global = transient_globals,
	actor_global = actor_globals,
}

-- This registry is the executable counterpart of docs/actor-state-registry.md.
-- Keep broad shared tables out of the swap list: they are authoritative world
-- state.  The entries below make the boundary inspectable by tests and review
-- tooling instead of leaving it implicit in ActorContext.run.
local state_registry = {
	actor_owned = {
		"actor table (ActorState/GhostActor)",
		"ActorRegistry runtime input",
		"ActorRegistry runtime local_globals",
	},
	shared = {
		"world", "mobs", "proj", "worldani", "tips", "disp",
		"game.time", "game.ttl_list", "game.ph_list",
	},
	host_only = {
		"save_manager", "network_world_journal", "multiplayer.session",
	},
	presentation_only = {
		"ActorRegistry runtime presentation.camera",
		"ActorRegistry runtime presentation.local_ui",
		"vi", "mouse_x", "mouse_y", "mouse_t",
	},
}

local field_members = {}
for scope, fields in pairs(field_groups) do
	field_members[scope] = {}
	for _, name in ipairs(fields) do field_members[scope][name] = true end
end

-- Legacy systems can explicitly classify new mutable state without editing
-- ActorContext's swap implementation. Shared world state must not be
-- registered here; these groups are exclusively actor-local or transient.
function ActorContext.register_field(scope, name)
	local fields = field_groups[scope]
	assert(fields, "unknown actor context field scope")
	assert(type(name) == "string" and name:match("^[%a_][%w_]*$"),
		"invalid actor context field name")
	if field_members[scope][name] then return true, "existing" end
	fields[#fields + 1] = name
	field_members[scope][name] = true
	return true, "registered"
end

function ActorContext.registered_fields(scope)
	local fields = assert(field_groups[scope], "unknown actor context field scope")
	local result = {}
	for index, name in ipairs(fields) do result[index] = name end
	return result
end

function ActorContext.state_registry()
	local result = {}
	for classification, entries in pairs(state_registry) do
		result[classification] = {}
		for index, name in ipairs(entries) do
			result[classification][index] = name
		end
	end
	result.actor_owned_fields = {}
	for scope, fields in pairs(field_groups) do
		result.actor_owned_fields[scope] = {}
		for index, name in ipairs(fields) do
			result.actor_owned_fields[scope][index] = name
		end
	end
	return result
end

local function clone_camera(reference)
	local camera = StateCopy.copy(reference or {})
	camera.xoffset = tonumber(camera.xoffset) or 0
	camera.yoffset = tonumber(camera.yoffset) or 0
	camera.xtile = tonumber(camera.xtile) or 0
	camera.ytile = tonumber(camera.ytile) or 0
	return camera
end

local function centre_camera(camera, actor)
	if not actor.truex or not actor.truey or not cf then return end
	camera.xoffset = 0
	camera.yoffset = 0
	camera.xtile = math.max(0, math.floor(actor.truex / cf.w) - 19)
	camera.ytile = math.max(0, math.floor(actor.truey / cf.h) - 10)
	camera.x = camera.xtile * cf.w
	camera.y = camera.ytile * cf.h
end

function ActorContext.ensure_camera(registry, actor, reference)
	local runtime = assert(registry:runtime(actor), "actor runtime is missing")
	local presentation = runtime.presentation
	if type(presentation.camera) ~= "table" then
		presentation.camera = clone_camera(reference)
		centre_camera(presentation.camera, actor)
	end
	return presentation.camera, runtime
end

local function swap_fields(container, fields, stored)
	local previous = {}
	for _, field in ipairs(fields) do
		previous[field] = container[field]
		container[field] = stored[field]
	end
	return previous
end

local function persist_fields(container, fields, stored, previous)
	for _, field in ipairs(fields) do
		stored[field] = container[field]
		container[field] = previous[field]
	end
end

local function screen_from_world(camera, world_x, world_y)
	local tile_x = math.floor(world_x / cf.w)
	local tile_y = math.floor(world_y / cf.h)
	return (tile_x - camera.xtile) * cf.w - camera.xoffset + world_x % cf.w,
		(tile_y - camera.ytile) * cf.h - camera.yoffset + world_y % cf.h
end

function ActorContext.run(registry, actor, options, callback)
	assert(type(registry) == "table", "actor registry is required")
	assert(type(actor) == "table", "actor is required")
	assert(type(callback) == "function", "actor callback is required")
	options = options or {}

	local camera, runtime = ActorContext.ensure_camera(registry, actor, options.camera or vi)
	local ui = runtime.presentation.local_ui
	runtime.local_globals = runtime.local_globals or {}
	ui.game = ui.game or {}
	ui.craft = ui.craft or {}
	if ui.game.craft == nil then ui.game.craft = false end

	local previous = {
		pl = pl,
		vi = vi,
		input = ACTIVE_INPUT_STATE,
		remote_action = NETWORK_REMOTE_ACTION,
		actor_id = ACTIVE_ACTOR_ID,
		dt = dt,
		mouse_x = mouse_x,
		mouse_y = mouse_y,
		mouse_t = mouse_t,
		mousemoved_last = mousemoved_last,
		mousetruemoved_last = mousetruemoved_last,
	}
	local previous_transient = {}
	for _, name in ipairs(transient_globals) do
		previous_transient[name] = _G[name]
		_G[name] = nil
	end
	local previous_actor_globals = swap_fields(_G, actor_globals, runtime.local_globals)

	pl = actor
	vi = camera
	ACTIVE_INPUT_STATE = options.input or runtime.input
	NETWORK_REMOTE_ACTION = options.remote_action or false
	ACTIVE_ACTOR_ID = actor.actor_id
	dt = tonumber(options.dt) or tonumber(dt) or 0
	mousemoved_last = tonumber(runtime.presentation.mousemoved_last) or 0
	mousetruemoved_last = tonumber(runtime.presentation.mousetruemoved_last) or 0

	local previous_game = swap_fields(game, game_fields, ui.game)
	local previous_craft = type(craft) == "table"
		and swap_fields(craft, craft_fields, ui.craft) or nil

	local position_ready = false
	local called, first, second, third = pcall(function()
		if actor.truex and actor.truey then coord_true2screen(actor) end
		position_ready = actor.x ~= nil and actor.y ~= nil
		local aim = ACTIVE_INPUT_STATE and ACTIVE_INPUT_STATE.aim or {}
		if tonumber(aim.world_x) and tonumber(aim.world_y) then
			mouse_x, mouse_y = screen_from_world(camera, aim.world_x, aim.world_y)
		elseif tonumber(aim.tile_x) and tonumber(aim.tile_y) then
			mouse_x, mouse_y = tile2px(aim.tile_x, aim.tile_y).x,
				tile2px(aim.tile_x, aim.tile_y).y
		end
		mouse_x = tonumber(mouse_x) or tonumber(actor.x) or 0
		mouse_y = tonumber(mouse_y) or tonumber(actor.y) or 0
		mouse_t = px2tile(mouse_x, mouse_y)
		return callback(actor, runtime)
	end)
	local position_restored, position_error = pcall(function()
		if position_ready then coord_screen2true(actor) end
	end)
	if called and not position_restored then
		called, first = false, position_error
	end

	persist_fields(game, game_fields, ui.game, previous_game)
	if previous_craft then
		persist_fields(craft, craft_fields, ui.craft, previous_craft)
	end
	for _, name in ipairs(transient_globals) do _G[name] = previous_transient[name] end
	persist_fields(_G, actor_globals, runtime.local_globals, previous_actor_globals)
	pl = previous.pl
	vi = previous.vi
	ACTIVE_INPUT_STATE = previous.input
	NETWORK_REMOTE_ACTION = previous.remote_action
	ACTIVE_ACTOR_ID = previous.actor_id
	dt = previous.dt
	runtime.presentation.mousemoved_last = mousemoved_last
	runtime.presentation.mousetruemoved_last = mousetruemoved_last
	mouse_x = previous.mouse_x
	mouse_y = previous.mouse_y
	mouse_t = previous.mouse_t
	mousemoved_last = previous.mousemoved_last
	mousetruemoved_last = previous.mousetruemoved_last

	if not called then error(first, 0) end
	return first, second, third
end

return ActorContext

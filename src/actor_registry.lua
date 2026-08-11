local ActorState = require("src.actor_state")
local InputState = require("src.input_state")
local ClientPresentation = require("src.client_presentation")

local ActorRegistry = {}
ActorRegistry.__index = ActorRegistry

function ActorRegistry.new()
	return setmetatable({
		by_id = {},
		runtime_by_id = {},
		host = nil,
		guest = nil,
		local_actor = nil,
	}, ActorRegistry)
end

local function default_runtime(previous, camera)
	local runtime = previous or {}
	runtime.input = runtime.input or InputState.new()
	runtime.presentation = runtime.presentation
		or ClientPresentation.new(camera)
	if camera then
		ClientPresentation.bind_camera(runtime.presentation, camera)
	end
	return runtime
end

function ActorRegistry:bind(actor, options)
	options = options or {}
	actor = ActorState.ensure(actor, {
		actor_id = options.actor_id,
		actor_role = options.actor_role,
		force_identity = options.force_identity,
	})

	local id = actor.actor_id
	local previous = self.by_id[id]
	self.by_id[id] = actor
	self.runtime_by_id[id] = default_runtime(
		self.runtime_by_id[id],
		options.camera
	)

	if previous and previous ~= actor then
		if self.host == previous then self.host = actor end
		if self.guest == previous then self.guest = actor end
		if self.local_actor == previous then self.local_actor = actor end
	end
	if options.local_actor then self.local_actor = actor end
	return actor, self.runtime_by_id[id]
end

function ActorRegistry:bind_host(actor, camera)
	local bound, runtime = self:bind(actor, {
		actor_id = "host",
		actor_role = "host",
		force_identity = true,
		local_actor = self.local_actor == nil or self.local_actor == self.host,
		camera = camera,
	})
	self.host = bound
	return bound, runtime
end

function ActorRegistry:bind_guest(actor, options)
	options = options or {}
	local bound, runtime = self:bind(actor, {
		actor_id = options.actor_id or "guest",
		actor_role = "guest",
		force_identity = true,
		local_actor = options.local_actor,
		camera = options.camera,
	})
	self.guest = bound
	return bound, runtime
end

function ActorRegistry:get(actor_or_id)
	if type(actor_or_id) == "table" then return actor_or_id end
	return self.by_id[actor_or_id]
end

function ActorRegistry:runtime(actor_or_id)
	local actor = self:get(actor_or_id)
	return actor and self.runtime_by_id[actor.actor_id] or nil
end

function ActorRegistry:set_local(actor_or_id)
	local actor = self:get(actor_or_id)
	if not actor then return false, "unknown actor" end
	self.local_actor = actor
	return true
end

function ActorRegistry:remove(actor_or_id)
	local actor = self:get(actor_or_id)
	if not actor then return nil end
	local id = actor.actor_id
	self.by_id[id] = nil
	self.runtime_by_id[id] = nil
	if self.host == actor then self.host = nil end
	if self.guest == actor then self.guest = nil end
	if self.local_actor == actor then self.local_actor = nil end
	return actor
end

return ActorRegistry

local ActorState = {}

ActorState.VERSION = 1

local function positive_integer(value, fallback)
	value = tonumber(value)
	if not value or value < 1 or value ~= math.floor(value) then
		return fallback
	end
	return value
end

local function finite_number(value, fallback)
	value = tonumber(value)
	if not value or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

local function normalized_identity(value, fallback)
	if type(value) ~= "string" or value == "" or #value > 64
		or not value:match("^[%w_.%-]+$") then
		return fallback
	end
	return value
end

function ActorState.ensure(actor, options)
	assert(type(actor) == "table", "actor state must be a table")
	options = options or {}

	actor.actor_version = ActorState.VERSION
	if options.force_identity then
		actor.actor_id = normalized_identity(options.actor_id, "host")
		actor.actor_role = normalized_identity(options.actor_role, "host")
	else
		actor.actor_id = normalized_identity(
			actor.actor_id,
			normalized_identity(options.actor_id, "host")
		)
		actor.actor_role = normalized_identity(
			actor.actor_role,
			normalized_identity(options.actor_role, "host")
		)
	end

	local animation = actor.animation
	if type(animation) ~= "table" then
		animation = {}
		actor.animation = animation
	end
	animation.frame = positive_integer(animation.frame, 1)
	animation.time = math.max(0, finite_number(animation.time, 0))
	animation.cycle = math.max(0, finite_number(animation.cycle, 0))
	animation.reverse = animation.reverse and positive_integer(animation.reverse, 0) or nil
	animation.reverse_start = animation.reverse_start
		and positive_integer(animation.reverse_start, 1) or nil

	return actor
end

function ActorState.new(options)
	options = options or {}
	return ActorState.ensure({}, {
		actor_id = options.actor_id,
		actor_role = options.actor_role,
		force_identity = true,
	})
end

function ActorState.reset_animation(actor, frame, options)
	actor = ActorState.ensure(actor)
	options = options or {}
	local animation = actor.animation
	animation.frame = positive_integer(frame, 1)
	animation.time = 0
	animation.cycle = 0
	if not options.preserve_reverse then
		animation.reverse = nil
		animation.reverse_start = nil
	end
	return animation
end

function ActorState.begin_reverse(actor)
	actor = ActorState.ensure(actor)
	actor.animation.reverse = actor.animation.reverse or 0
	return actor.animation.reverse
end

return ActorState

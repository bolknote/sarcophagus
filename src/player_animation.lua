local ActorState = require("src.actor_state")

local PlayerAnimation = {}

function PlayerAnimation.update(actor, dt, definitions)
	actor = ActorState.ensure(actor)
	local animation = actor.animation
	local definition = definitions and definitions[actor.state]
	if type(definition) ~= "table" or type(definition.dur) ~= "table" then
		ActorState.reset_animation(actor)
		actor.oldstate = actor.state
		return false, "missing animation state"
	end

	animation.time = animation.time + dt * 100 * (actor.anispeed or 1)
	-- Preserve the original counter semantics. Some gameplay diagnostics may
	-- still depend on the accumulated frame timer rather than raw dt.
	animation.cycle = animation.cycle + animation.time

	if definition.dur[animation.frame] == nil or actor.oldstate ~= actor.state then
		ActorState.reset_animation(actor, nil, { preserve_reverse = true })
		animation = actor.animation
		definition = definitions[actor.state]
	end

	if animation.time >= definition.dur[animation.frame] then
		if definition.dur[animation.frame] > 0 then
			animation.time = animation.time - definition.dur[animation.frame]
			local reverse_finished

			if animation.reverse and definition.reversable then
				animation.reverse_start = animation.reverse_start or animation.frame
				animation.reverse = animation.reverse + 1
				animation.frame = animation.reverse_start - animation.reverse

				if animation.frame > 0 then
					if definition.add and definition.add[animation.frame] then
						actor.x = actor.x - definition.add[animation.frame][1] * actor.flip
						actor.y = actor.y - definition.add[animation.frame][2]
					end
				else
					reverse_finished = true
				end
			else
				animation.frame = definition.ani[animation.frame]
				if definition.add and definition.add[animation.frame] then
					actor.x = actor.x + definition.add[animation.frame][1] * actor.flip
					actor.y = actor.y + definition.add[animation.frame][2]
				end
			end

			if type(animation.frame) == "string" or reverse_finished then
				local exit_frame = definition.exitfr or 1
				actor.state = animation.frame
				animation.frame = exit_frame
				if reverse_finished then
					actor.state = "idle"
					animation.frame = 1
				end
				animation.time = 0
				animation.cycle = 0
				animation.reverse = nil
				animation.reverse_start = nil
			end
		else
			ActorState.reset_animation(actor, nil, { preserve_reverse = true })
			animation = actor.animation
		end
	end

	definition = definitions[actor.state]
	if type(animation.frame) ~= "number" or animation.frame > definition.cnt then
		ActorState.reset_animation(actor, nil, { preserve_reverse = true })
	end
	actor.oldstate = actor.state
	return true
end

return PlayerAnimation

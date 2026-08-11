local ActorRenderer = {}

local function projected_position(actor, camera, local_actor, tile_width, tile_height)
	if actor == local_actor and actor.x and actor.y then return actor.x, actor.y end
	if not actor.truex or not actor.truey then return actor.x, actor.y end
	local tile_x = math.floor(actor.truex / tile_width)
	local tile_y = math.floor(actor.truey / tile_height)
	return (tile_x - camera.xtile) * tile_width - camera.xoffset
			+ actor.truex % tile_width,
		(tile_y - camera.ytile) * tile_height - camera.yoffset
			+ actor.truey % tile_height
end

function ActorRenderer.position(actor, options)
	options = options or {}
	return projected_position(
		actor,
		assert(options.camera, "camera is required"),
		options.local_actor,
		options.tile_width or 32,
		options.tile_height or 32
	)
end

function ActorRenderer.draw_body(actor, options)
	if type(actor) ~= "table" then return false end
	options = options or {}
	local definitions = options.definitions
	local definition = definitions and (definitions[actor.state] or definitions.idle)
	if not definition or type(definition.spr) ~= "table" then return false end
	local frame = math.floor(tonumber(actor.animation and actor.animation.frame) or 1)
	local sprite = definition.spr[frame] or definition.spr[1]
	if not sprite then return false end
	local x, y = ActorRenderer.position(actor, options)
	if not x or not y then return false end

	local previous_shader = love.graphics.getShader()
	local red, green, blue, alpha = love.graphics.getColor()
	if actor.ghost and options.ghost_shader then
		love.graphics.setShader(options.ghost_shader)
		love.graphics.setColor(1, 1, 1, 0.60)
	end
	love.graphics.draw(
		options.atlas,
		sprite,
		math.floor(x),
		math.floor(y),
		0,
		2 * (tonumber(actor.flip) or 1),
		2,
		15,
		16
	)
	if actor.ghost and options.ghost_shader then
		love.graphics.setShader(previous_shader)
		love.graphics.setColor(red, green, blue, alpha)
	end
	return true
end

function ActorRenderer.draw_carried(actor, options)
	if type(actor) ~= "table" or type(actor.iscarry) ~= "table"
		or not tonumber(actor.iscarry.b) or actor.iscarry.b <= 0 then return false end
	local block = options.blocks and options.blocks[actor.iscarry.b]
	if not block or not block.spr then return false end
	local x, y = ActorRenderer.position(actor, options)
	if not x or not y then return false end
	local definition = options.definitions[actor.state] or options.definitions.idle
	local frame = math.floor(tonumber(actor.animation and actor.animation.frame) or 1)
	local flip = tonumber(actor.flip) or 1
	local x_add, y_add = 0, 0
	if definition and definition.stoneadd and definition.stoneadd[frame] then
		x_add = definition.stoneadd[frame][1] * flip
		y_add = definition.stoneadd[frame][2]
	end
	if block.br then
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle(
			"fill",
			math.floor(x + flip * 10 + 13 + x_add) - 32,
			math.floor(y - 3 + y_add) - 34,
			36,
			36
		)
		love.graphics.setColor(1, 1, 1, 1)
	end
	love.graphics.draw(
		options.atlas,
		block.spr,
		math.floor(x + flip * 10 + 13 + x_add),
		math.floor(y - 3 + y_add),
		0, 2, 2, 15, 16
	)
	return true
end

return ActorRenderer

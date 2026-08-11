local GuestPossessions = {}

local function deep_copy(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local copy = {}
	seen[value] = copy
	for key, nested in pairs(value) do
		copy[deep_copy(key, seen)] = deep_copy(nested, seen)
	end
	return copy
end

local function coordinate(value, fallback)
	value = tonumber(value)
	if not value or value ~= value or value == math.huge or value == -math.huge then
		value = fallback
	end
	return math.floor(tonumber(value) or 1)
end

local function origin(actor, options)
	return coordinate(actor.xt or actor.tx, options.fallback_x),
		coordinate(actor.yt or actor.ty, options.fallback_y)
end

local function positions(center_x, center_y, radius)
	local result = { { center_x, center_y } }
	for distance = 1, radius do
		local left = center_x - distance
		local right = center_x + distance
		local top = center_y - distance
		local bottom = center_y + distance
		for x = left, right do result[#result + 1] = { x, top } end
		for y = top + 1, bottom do result[#result + 1] = { right, y } end
		for x = right - 1, left, -1 do result[#result + 1] = { x, bottom } end
		for y = bottom - 1, top + 1, -1 do result[#result + 1] = { left, y } end
	end
	return result
end

local function valid_cell(world, x, y)
	return type(world[y]) == "table" and type(world[y][x]) == "table"
end

local function default_add_item(world, maximum)
	return function(x, y, instance)
		if not valid_cell(world, x, y) then return false end
		local cell = world[y][x]
		cell.i = cell.i or {}
		if #cell.i >= maximum then return false end
		table.insert(cell.i, 1, instance)
		return true
	end
end

function GuestPossessions.merge_block_cell(cell, block)
	assert(type(cell) == "table", "world cell must be a table")
	assert(type(block) == "table", "carried block must be a table")
	local merged = deep_copy(cell)
	local existing_items = deep_copy(cell.i or {})
	for key, value in pairs(block) do
		if key ~= "i" then merged[deep_copy(key)] = deep_copy(value) end
	end
	-- A stale TTL from the formerly empty cell must not become the new block's
	-- TTL. Other environmental fields (water, room, dirt, etc.) survive.
	merged.t = deep_copy(block.t)
	for _, instance in pairs(block.i or {}) do
		existing_items[#existing_items + 1] = deep_copy(instance)
	end
	merged.i = next(existing_items) and existing_items or nil
	return merged
end

local function default_place_block(world)
	return function(x, y, block)
		if not valid_cell(world, x, y) then return false end
		local cell = world[y][x]
		if cell.b and cell.b ~= 0 then return false end
		world[y][x] = GuestPossessions.merge_block_cell(cell, block)
		return true
	end
end

local function sorted_inventory(actor)
	local entries = {}
	for slot, instance in pairs(actor.inv or {}) do
		if type(instance) == "table" then
			entries[#entries + 1] = { slot = slot, instance = instance }
		end
	end
	table.sort(entries, function(left, right)
		if type(left.slot) == type(right.slot) and type(left.slot) == "number" then
			return left.slot < right.slot
		end
		return tostring(left.slot) < tostring(right.slot)
	end)
	return entries
end

local function place_nearby(candidates, value, callback)
	for _, point in ipairs(candidates) do
		if callback(point[1], point[2], value) then return true, point[1], point[2] end
	end
	return false
end

local function transfer(actor, options, copy_only)
	assert(type(actor) == "table", "guest actor must be a table")
	assert(type(options) == "table" and type(options.world) == "table",
		"world is required")
	local world = options.world
	local center_x, center_y = origin(actor, options)
	local candidates = positions(center_x, center_y, options.radius or 8)
	local add_item = options.add_item
		or default_add_item(world, options.max_items_per_cell or 20)
	local place_block = options.place_block or default_place_block(world)
	local report = { items = 0, block = false }

	if type(actor.iscarry) == "table" then
		local block = copy_only and deep_copy(actor.iscarry) or actor.iscarry
		local placed = place_nearby(candidates, block, place_block)
		if not placed then return false, "no room for carried block", report end
		report.block = true
		if not copy_only then actor.iscarry = nil end
	end

	for _, entry in ipairs(sorted_inventory(actor)) do
		local instance = copy_only and deep_copy(entry.instance) or entry.instance
		local placed = place_nearby(candidates, instance, add_item)
		if not placed then return false, "no room for guest item", report end
		report.items = report.items + 1
		if not copy_only then actor.inv[entry.slot] = nil end
	end

	if not copy_only then actor.invselect = 1 end
	return true, report
end

function GuestPossessions.drop(actor, options)
	return transfer(actor, options, false)
end

function GuestPossessions.project(actor, options)
	return transfer(actor, options, true)
end

return GuestPossessions

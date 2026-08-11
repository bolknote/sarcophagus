local ItemIdentity = {}

local UID_PATTERN = "^item:(%d+)$"
local MAX_COUNTER = 9007199254740991

local function normalized_counter(value)
	value = tonumber(value)
	if not value or value < 1 or value > MAX_COUNTER
		or value ~= math.floor(value) then
		return 1
	end
	return value
end

function ItemIdentity.counter(uid)
	if type(uid) ~= "string" then return nil end
	local value = tonumber(uid:match(UID_PATTERN))
	if not value or value < 1 or value > MAX_COUNTER
		or value ~= math.floor(value) then
		return nil
	end
	return value
end

function ItemIdentity.ensure_world(world_state)
	assert(type(world_state) == "table", "world state must be a table")
	world_state.next_item_uid = normalized_counter(world_state.next_item_uid)
	return world_state.next_item_uid
end

local function reserve_next(world_state, seen)
	local counter = ItemIdentity.ensure_world(world_state)
	local uid
	repeat
		if counter > MAX_COUNTER then error("item uid space exhausted") end
		uid = "item:" .. tostring(counter)
		counter = counter + 1
	until not seen or not seen[uid]
	world_state.next_item_uid = counter
	return uid
end

function ItemIdentity.ensure(instance, world_state, seen)
	if type(instance) ~= "table" or type(instance.i) ~= "number" then
		return nil, "not an item instance"
	end
	ItemIdentity.ensure_world(world_state)

	local uid = instance.uid
	local counter = ItemIdentity.counter(uid)
	if not counter or (seen and seen[uid]) then
		uid = reserve_next(world_state, seen)
		instance.uid = uid
		counter = ItemIdentity.counter(uid)
	elseif counter >= world_state.next_item_uid then
		world_state.next_item_uid = counter + 1
	end

	if seen then seen[uid] = instance end
	return uid
end

function ItemIdentity.migrate(world_state, visit)
	assert(type(visit) == "function", "item visitor must be a function")
	ItemIdentity.ensure_world(world_state)
	local seen = {}
	local assigned = 0
	local duplicates = 0

	visit(function(instance)
		if type(instance) == "table" and type(instance.i) == "number" then
			local previous = instance.uid
			local was_duplicate = previous and seen[previous] ~= nil
			local uid = ItemIdentity.ensure(instance, world_state, seen)
			if uid and uid ~= previous then assigned = assigned + 1 end
			if was_duplicate then duplicates = duplicates + 1 end
		end
	end)

	return {
		seen = seen,
		count = (function()
			local count = 0
			for _ in pairs(seen) do count = count + 1 end
			return count
		end)(),
		assigned = assigned,
		duplicates = duplicates,
	}
end

return ItemIdentity

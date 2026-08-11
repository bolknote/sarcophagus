local ItemIdentity = require("src.item_identity")

local ActorInventory = {}

local function inventory(actor)
	assert(type(actor) == "table", "actor must be a table")
	if type(actor.inv) ~= "table" then actor.inv = {} end
	actor.invsize = math.max(0, math.floor(tonumber(actor.invsize) or 0))
	actor.invselect = actor.invselect or 1
	return actor.inv
end

function ActorInventory.count(actor)
	local count = 0
	local highest = 0
	for slot in pairs(inventory(actor)) do
		if type(slot) == "number" then
			count = count + 1
			if slot > highest then highest = slot end
		end
	end
	return count, highest
end

function ActorInventory.find(actor, item_id)
	if type(item_id) == "table" then
		for _, candidate in ipairs(item_id) do
			local slot = ActorInventory.find(actor, candidate)
			if slot ~= nil then return slot end
		end
		return nil
	end
	for slot, instance in pairs(inventory(actor)) do
		if type(instance) == "table" and instance.i == item_id then return slot end
	end
	return nil
end

function ActorInventory.add(actor, instance, world_state, options)
	options = options or {}
	if type(instance) ~= "table" then return nil, "invalid item" end
	ItemIdentity.ensure(instance, world_state)
	local values = inventory(actor)
	for slot = 1, actor.invsize do
		if values[slot] == nil then
			values[slot] = instance
			if options.select ~= false then actor.invselect = slot end
			return slot
		end
	end
	return nil, "inventory full"
end

function ActorInventory.remove(actor, slot)
	local values = inventory(actor)
	local instance = values[slot]
	if instance == nil then return nil, "empty slot" end
	values[slot] = nil
	if actor.invselect == slot then
		for candidate = 1, actor.invsize do
			if values[candidate] then
				actor.invselect = candidate
				return instance
			end
		end
		actor.invselect = 1
	end
	return instance
end

function ActorInventory.each(actor, callback)
	assert(type(callback) == "function", "inventory callback must be a function")
	for slot, instance in pairs(inventory(actor)) do callback(instance, slot) end
end

local function append_material(items, instance, source)
	if type(instance) ~= "table" then return end
	items[#items + 1] = {
		instance = instance,
		source = source,
	}
end

function ActorInventory.material_possessions(actor)
	local items = {}
	for slot, instance in pairs(inventory(actor)) do
		append_material(items, instance, { kind = "inventory", slot = slot })
	end
	if type(actor.iscarry) == "table" then
		if type(actor.iscarry.i) == "table" then
			for slot, instance in pairs(actor.iscarry.i) do
				append_material(items, instance, {
					kind = "carried_block_item",
					slot = slot,
				})
			end
		end
		items[#items + 1] = {
			block = actor.iscarry,
			source = { kind = "carried_block" },
		}
	end
	return items
end

function ActorInventory.drain_items(actor)
	local drained = {}
	local values = inventory(actor)
	for slot, instance in pairs(values) do
		if type(instance) == "table" then
			drained[#drained + 1] = instance
		end
		values[slot] = nil
	end
	actor.invselect = 1
	return drained
end

return ActorInventory

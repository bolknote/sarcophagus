local Replication = require("src.network.replication")

local WorldJournal = {}
WorldJournal.__index = WorldJournal

local function coordinate(value)
	value = tonumber(value)
	if not value or value ~= math.floor(value) or value < 0 then return nil end
	return value
end

function WorldJournal.new(options)
	options = options or {}
	return setmetatable({
		pending = {},
		count = 0,
		sequence = 0,
		max_pending = options.max_pending or 16384,
		overflowed = false,
	}, WorldJournal)
end

function WorldJournal:record(x, y)
	x, y = coordinate(x), coordinate(y)
	if not x or not y then return false, "invalid cell coordinate" end
	local key = x .. ":" .. y
	if not self.pending[key] then
		if self.count >= self.max_pending then
			self.overflowed = true
			return false, "world journal overflow"
		end
		self.pending[key] = { x = x, y = y }
		self.count = self.count + 1
	end
	return true
end

function WorldJournal:drain(world, limit, tick)
	limit = math.max(1, math.floor(tonumber(limit) or 64))
	local keys = {}
	for key in pairs(self.pending) do keys[#keys + 1] = key end
	table.sort(keys)
	local cells = {}
	for index = 1, math.min(limit, #keys) do
		local key = keys[index]
		local point = self.pending[key]
		self.pending[key] = nil
		self.count = self.count - 1
		local row = world and world[point.y]
		cells[#cells + 1] = {
			x = point.x,
			y = point.y,
			cell = Replication.copy_serializable(row and row[point.x] or {}),
		}
	end
	if #cells == 0 then return nil end
	self.sequence = self.sequence + 1
	return {
		sequence = self.sequence,
		tick = math.max(0, math.floor(tonumber(tick) or 0)),
		cells = cells,
	}
end

function WorldJournal:clear()
	self.pending = {}
	self.count = 0
	self.sequence = 0
	self.overflowed = false
end

function WorldJournal:ready()
	return not self.overflowed,
		self.overflowed and "snapshot_catchup_overflow" or nil
end

return WorldJournal

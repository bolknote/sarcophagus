local InterpolationBuffer = {}
InterpolationBuffer.__index = InterpolationBuffer

local function finite(value)
	return type(value) == "number" and value == value
		and value ~= math.huge and value ~= -math.huge
end

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function clock()
	if love and love.timer and love.timer.getTime then
		return love.timer.getTime()
	end
	return os.clock()
end

function InterpolationBuffer.new(options)
	options = options or {}
	local base_delay = clamp(tonumber(options.delay) or 0.11, 0.04, 0.5)
	return setmetatable({
		samples = {},
		base_delay = base_delay,
		delay = base_delay,
		maximum_delay = math.max(base_delay,
			tonumber(options.maximum_delay) or 0.24),
		maximum_samples = math.max(4,
			math.floor(tonumber(options.maximum_samples) or 32)),
		maximum_clock_advance = clamp(
			tonumber(options.maximum_clock_advance) or 0.08,
			0,
			0.25
		),
		jitter = 0,
		server_interval = nil,
	}, InterpolationBuffer)
end

function InterpolationBuffer:reset()
	self.samples = {}
	self.delay = self.base_delay
	self.jitter = 0
	self.server_interval = nil
end

function InterpolationBuffer:push(server_time, positions, received_at)
	server_time = tonumber(server_time)
	received_at = tonumber(received_at) or clock()
	if not finite(server_time) or server_time < 0
		or type(positions) ~= "table" or not finite(received_at) then
		return false, "invalid interpolation sample"
	end

	local previous = self.samples[#self.samples]
	if previous and server_time < previous.time then
		return false, "stale interpolation sample"
	end
	if previous and server_time == previous.time then
		previous.positions = positions
		previous.received_at = received_at
		return true, "replaced"
	end

	if previous then
		local server_delta = server_time - previous.time
		local arrival_delta = math.max(0, received_at - previous.received_at)
		if server_delta > 0 and server_delta < 2 then
			self.server_interval = self.server_interval
				and (self.server_interval * 0.9 + server_delta * 0.1)
				or server_delta
			local deviation = math.abs(arrival_delta - server_delta)
			self.jitter = self.jitter * 0.9 + deviation * 0.1
			self.delay = clamp(
				self.base_delay + self.jitter * 3,
				self.base_delay,
				self.maximum_delay
			)
		end
	end

	self.samples[#self.samples + 1] = {
		time = server_time,
		received_at = received_at,
		positions = positions,
	}
	while #self.samples > self.maximum_samples do
		table.remove(self.samples, 1)
	end
	return true
end

function InterpolationBuffer:seed_latest(group, id, x, y)
	local latest = self.samples[#self.samples]
	if not latest or type(group) ~= "string" or id == nil
		or not finite(x) or not finite(y) then
		return false
	end
	latest.positions[group] = latest.positions[group] or {}
	if latest.positions[group][id] == nil then
		latest.positions[group][id] = { x = x, y = y }
	end
	return true
end

function InterpolationBuffer:frame(now)
	now = tonumber(now) or clock()
	local count = #self.samples
	if count == 0 or not finite(now) then return nil end
	local newest = self.samples[count]
	local clock_advance = clamp(
		now - newest.received_at,
		0,
		self.maximum_clock_advance
	)
	local target = newest.time + clock_advance - self.delay
	local older, newer = self.samples[1], self.samples[1]

	if target >= newest.time then
		older, newer = newest, newest
	elseif target > self.samples[1].time then
		for index = 2, count do
			newer = self.samples[index]
			if newer.time >= target then
				older = self.samples[index - 1]
				break
			end
		end
	end

	local duration = newer.time - older.time
	local alpha = duration > 0 and clamp((target - older.time) / duration, 0, 1)
		or 0
	return {
		older = older,
		newer = newer,
		alpha = alpha,
		target = target,
		delay = self.delay,
		jitter = self.jitter,
	}
end

function InterpolationBuffer.position(frame, group, id)
	if type(frame) ~= "table" then return nil end
	local older_group = frame.older.positions[group] or {}
	local newer_group = frame.newer.positions[group] or {}
	local older = older_group[id]
	local newer = newer_group[id]
	if older and newer then
		local alpha = frame.alpha
		return older.x + (newer.x - older.x) * alpha,
			older.y + (newer.y - older.y) * alpha
	end
	if older then return older.x, older.y end
	if newer and frame.target >= frame.newer.time then
		return newer.x, newer.y
	end
	return nil
end

function InterpolationBuffer:metrics()
	return {
		delay = self.delay,
		jitter = self.jitter,
		server_interval = self.server_interval,
		samples = #self.samples,
	}
end

return InterpolationBuffer

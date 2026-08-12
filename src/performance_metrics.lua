local Metrics = {
	active = false,
	samples = {},
	metadata = {},
}

local unpack_values = table.unpack or unpack

local function wall_clock()
	if love and love.timer and love.timer.getTime then
		return love.timer.getTime()
	end
	return os.clock()
end

local function pack(...)
	return { n = select("#", ...), ... }
end

local function percentile(sorted, ratio)
	if #sorted == 0 then return nil end
	local index = math.max(1, math.ceil(#sorted * ratio))
	return sorted[math.min(index, #sorted)]
end

local function summarize(values)
	local sorted = {}
	local total = 0
	for index, value in ipairs(values or {}) do
		sorted[index] = value
		total = total + value
	end
	table.sort(sorted)
	if #sorted == 0 then
		return { count = 0 }
	end
	return {
		count = #sorted,
		mean_ms = total / #sorted,
		p50_ms = percentile(sorted, 0.50),
		p95_ms = percentile(sorted, 0.95),
		p99_ms = percentile(sorted, 0.99),
		max_ms = sorted[#sorted],
	}
end

function Metrics.reset(metadata)
	Metrics.samples = {}
	Metrics.metadata = metadata or {}
	Metrics.started_at = wall_clock()
	Metrics.started_cpu = os.clock()
	Metrics.started_memory_kb = collectgarbage("count")
	Metrics.finished_at = nil
	Metrics.finished_cpu = nil
	Metrics.finished_memory_kb = nil
	return Metrics
end

function Metrics.activate(metadata)
	Metrics.reset(metadata)
	Metrics.active = true
	return Metrics
end

function Metrics.deactivate()
	Metrics.active = false
	Metrics.finished_at = wall_clock()
	Metrics.finished_cpu = os.clock()
	Metrics.finished_memory_kb = collectgarbage("count")
	return Metrics.report()
end

function Metrics.record(name, milliseconds)
	if not Metrics.active then return end
	assert(type(name) == "string" and name ~= "", "metric name is required")
	milliseconds = tonumber(milliseconds)
	assert(milliseconds and milliseconds >= 0, "metric duration must be non-negative")
	local values = Metrics.samples[name]
	if not values then
		values = {}
		Metrics.samples[name] = values
	end
	values[#values + 1] = milliseconds
end

function Metrics.measure(name, callback, ...)
	if not Metrics.active then return callback(...) end
	local started = wall_clock()
	local results = pack(pcall(callback, ...))
	Metrics.record(name, (wall_clock() - started) * 1000)
	if not results[1] then error(results[2], 0) end
	return unpack_values(results, 2, results.n)
end

function Metrics.collect_garbage()
	return Metrics.measure("gc_full_pause", collectgarbage, "collect")
end

function Metrics.step_garbage(kilobytes)
	return Metrics.measure(
		"gc_pause", collectgarbage, "step", tonumber(kilobytes) or 200
	)
end

function Metrics.report()
	local finished_at = Metrics.finished_at or wall_clock()
	local finished_cpu = Metrics.finished_cpu or os.clock()
	local finished_memory_kb = Metrics.finished_memory_kb or collectgarbage("count")
	local phases = {}
	for name, values in pairs(Metrics.samples) do
		phases[name] = summarize(values)
	end
	return {
		metadata = Metrics.metadata,
		phases = phases,
		wall_seconds = math.max(0, finished_at - (Metrics.started_at or finished_at)),
		cpu_seconds = math.max(0, finished_cpu - (Metrics.started_cpu or finished_cpu)),
		memory_start_kb = Metrics.started_memory_kb or finished_memory_kb,
		memory_end_kb = finished_memory_kb,
		memory_growth_kb = finished_memory_kb
			- (Metrics.started_memory_kb or finished_memory_kb),
	}
end

function Metrics.format(report)
	report = report or Metrics.report()
	local names = {}
	for name in pairs(report.phases or {}) do names[#names + 1] = name end
	table.sort(names)
	local lines = {}
	for _, name in ipairs(names) do
		local phase = report.phases[name]
		lines[#lines + 1] = string.format(
			"%s n=%d p50=%.3fms p95=%.3fms p99=%.3fms max=%.3fms",
			name,
			phase.count,
			phase.p50_ms or 0,
			phase.p95_ms or 0,
			phase.p99_ms or 0,
			phase.max_ms or 0
		)
	end
	lines[#lines + 1] = string.format(
		"cpu=%.3fs wall=%.3fs memory_growth=%.1fKiB",
		report.cpu_seconds or 0,
		report.wall_seconds or 0,
		report.memory_growth_kb or 0
	)
	return table.concat(lines, "; ")
end

return Metrics

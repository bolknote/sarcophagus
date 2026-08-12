local FixedStep = {}

-- Legacy movement constants are expressed per gameplay frame. The main loop is
-- intentionally capped at 30 FPS, so simulating a remote actor at 60 Hz changes
-- jump gravity, animation timing and movement speed instead of adding fidelity.
FixedStep.STEP = 1 / 30
FixedStep.MAX_ELAPSED = 0.1
FixedStep.MAX_STEPS = 3

local function finite_nonnegative(value, fallback)
	value = tonumber(value)
	if not value or value ~= value or value == math.huge
		or value == -math.huge or value < 0 then
		return fallback
	end
	return value
end

function FixedStep.advance(accumulator, elapsed, callback)
	assert(type(callback) == "function", "fixed-step callback is required")
	local step = FixedStep.STEP
	local epsilon = step * 1e-7
	accumulator = finite_nonnegative(accumulator, 0)
	if accumulator >= step then accumulator = accumulator % step end
	elapsed = math.min(
		FixedStep.MAX_ELAPSED,
		finite_nonnegative(elapsed, 0)
	)
	accumulator = accumulator + elapsed
	local steps = math.min(
		FixedStep.MAX_STEPS,
		math.floor((accumulator + epsilon) / step)
	)
	for index = 1, steps do
		callback(step, index)
		accumulator = accumulator - step
	end
	if accumulator < 0 and accumulator > -epsilon then accumulator = 0 end
	return accumulator, steps
end

return FixedStep

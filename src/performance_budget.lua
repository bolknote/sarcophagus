local Budget = {}

-- This is the reproducible reference-machine gate. The separate Intel Mac
-- hardware pass remains a release checklist item because CI cannot emulate it.
Budget.targets = {
	minimum_samples = 120,
	minimum_fps = 30,
	combined_frame_p95_ms = 1000 / 30,
	memory_growth_kb = 32 * 1024,
	phases = {
		frame_update = { p95_ms = 20, p99_ms = 30 },
		frame_render = { p95_ms = 24, p99_ms = 32 },
		guest_simulation = { p95_ms = 8, p99_ms = 12 },
		active_world_scan = { p95_ms = 8, p99_ms = 12 },
		active_building = { minimum_samples = 30, p95_ms = 3, p99_ms = 6 },
		reconnect_backlog_replay = {
			minimum_samples = 30,
			p95_ms = 8,
			p99_ms = 12,
		},
		replication_capture = { p95_ms = 8, p99_ms = 12 },
		replication_encode = { p95_ms = 10, p99_ms = 20 },
		replication_decode = { p95_ms = 10, p99_ms = 20 },
		network_publish = { p95_ms = 3, p99_ms = 6 },
		gc_pause = { p95_ms = 4, p99_ms = 8 },
		-- A separately labelled, deliberately forced full collection is a
		-- worst-case maintenance pause, not the normal per-frame GC step.
		gc_full_pause = { max_ms = 200 },
	},
}

local function failure(failures, message)
	failures[#failures + 1] = message
end

function Budget.evaluate(report, targets)
	targets = targets or Budget.targets
	local failures = {}
	local phases = report and report.phases or {}

	for name, limits in pairs(targets.phases or {}) do
		local phase = phases[name]
		if phase then
			if limits.minimum_samples
				and phase.count < limits.minimum_samples then
				failure(failures, string.format(
					"%s samples %d < %d",
					name, phase.count, limits.minimum_samples
				))
			end
			for _, percentile_name in ipairs({ "p95_ms", "p99_ms", "max_ms" }) do
				local limit = limits[percentile_name]
				local observed = phase[percentile_name]
				if limit and observed and observed > limit then
					failure(failures, string.format(
						"%s %s %.3fms > %.3fms",
						name, percentile_name, observed, limit
					))
				end
			end
		end
	end

	local update = phases.frame_update
	local render = phases.frame_render
	if update and render then
		local samples = math.min(update.count or 0, render.count or 0)
		if samples < (targets.minimum_samples or 0) then
			failure(failures, string.format(
				"frame samples %d < %d", samples, targets.minimum_samples or 0
			))
		end
		local combined = (update.p95_ms or 0) + (render.p95_ms or 0)
		if combined > targets.combined_frame_p95_ms then
			failure(failures, string.format(
				"combined frame p95 %.3fms > %.3fms (%d FPS budget)",
				combined,
				targets.combined_frame_p95_ms,
				targets.minimum_fps
			))
		end
	end

	if report and report.memory_growth_kb
		and report.memory_growth_kb > targets.memory_growth_kb then
		failure(failures, string.format(
			"memory growth %.1fKiB > %.1fKiB",
			report.memory_growth_kb, targets.memory_growth_kb
		))
	end

	return #failures == 0, failures
end

return Budget

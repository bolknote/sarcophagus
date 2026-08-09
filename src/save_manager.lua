local SaveFormat = require("src.save_format")

local SaveManager = {}

local DEFAULT_SERIALIZE_BUDGET = 0.004
local CHECK_INTERVAL = 128
local DEFAULT_BUFFER_SIZE = 8 * 1024 * 1024

local active
local pending
local next_job_id = 0
local last_raw_size
local worker
local requests
local results
local request_channel_name
local result_channel_name

local function report_error(prefix, value)
	(oldprint or print)(prefix .. tostring(value))
end

local function call_completion(request, success, save_error, details)
	if not request or type(request.on_complete) ~= "function" then
		return
	end
	local called, callback_error = pcall(
		request.on_complete,
		success,
		save_error,
		details
	)
	if not called then
		report_error("Save completion callback failed: ", callback_error)
	end
end

local function ensure_worker()
	if worker and worker:isRunning() then
		return true
	end

	local suffix = tostring(love.timer.getTime()):gsub("[^%w]", "")
		.. "-" .. tostring(next_job_id)
	request_channel_name = "sarcophagus-save-requests-" .. suffix
	result_channel_name = "sarcophagus-save-results-" .. suffix
	requests = love.thread.getChannel(request_channel_name)
	results = love.thread.getChannel(result_channel_name)
	requests:clear()
	results:clear()

	local started, start_error = pcall(function()
		worker = love.thread.newThread("src/save_worker.lua")
		worker:start(request_channel_name, result_channel_name)
	end)
	if not started then
		worker = nil
		return false, start_error
	end
	return true
end

local function estimated_buffer_size(name)
	if last_raw_size then
		return math.max(1024, math.floor(last_raw_size * 1.05) + 1024)
	end

	local filename = tostring(name) .. ".sav"
	local info = love.filesystem.getInfo(filename, "file")
	if info then
		local prefix = love.filesystem.read(filename, SaveFormat.header_size())
		local raw_size = prefix and SaveFormat.raw_size(prefix)
		if raw_size then
			return math.max(1024, math.floor(raw_size * 1.05) + 1024)
		end
		if not prefix or not SaveFormat.is_container(prefix) then
			return math.max(1024, math.floor(info.size * 1.05) + 1024)
		end
	end

	return DEFAULT_BUFFER_SIZE
end

local function start_request(request)
	local metadata_ok, metadata = pcall(game_saveinfo_payload)
	local metadata_error
	if not metadata_ok then
		metadata_error = metadata
		metadata = nil
	end
	local snapshot_ok, snapshot = pcall(game_save_snapshot)
	if not snapshot_ok then
		return false, snapshot
	end

	next_job_id = next_job_id + 1
	local job = {
		id = next_job_id,
		name = request.name,
		filename = tostring(request.name) .. ".sav",
		request = request,
		snapshot = snapshot,
		metadata = metadata,
		metadata_error = metadata_error,
		stage = "serializing",
		checks = 0,
		deadline = 0,
	}

	job.coroutine = coroutine.create(function()
		local function checkpoint()
			job.checks = job.checks + 1
			if job.checks >= CHECK_INTERVAL then
				job.checks = 0
				if love.timer.getTime() >= job.deadline then
					coroutine.yield()
				end
			end
		end

		return game_serialize_snapshot(
			job.snapshot,
			checkpoint,
			estimated_buffer_size(job.name)
		)
	end)

	active = job
	return true, "started"
end

local function start_pending_request()
	if active or not pending then
		return
	end

	local request = pending
	pending = nil
	local started, start_error = start_request(request)
	if not started then
		call_completion(request, false, start_error)
		start_pending_request()
	end
end

local function finish_active(success, save_error, details)
	local job = active
	active = nil
	if success and details and details.raw_size then
		last_raw_size = details.raw_size
	end

	if success and job.request.screenshot ~= false then
		local captured, capture_error = pcall(
			love.graphics.captureScreenshot,
			tostring(job.name) .. ".png"
		)
		if not captured then
			report_error("Could not capture save preview: ", capture_error)
		end
	end

	if job.metadata_error then
		report_error("Could not encode game metadata: ", job.metadata_error)
	elseif details and details.metadata_error then
		report_error("Could not save game metadata: ", details.metadata_error)
	end

	call_completion(job.request, success, save_error, details)
	start_pending_request()
end

function SaveManager.start(name, options)
	options = options or {}
	local request = {
		name = name,
		kind = options.kind or "manual",
		screenshot = options.screenshot,
		on_complete = options.on_complete,
	}

	if active then
		if active.request.kind == "quit" then
			return false, "quit save already in progress"
		end

		if pending then
			if pending.kind == "quit" or request.kind ~= "quit" then
				return true, "coalesced"
			end
			local superseded = pending
			pending = request
			call_completion(superseded, false, "save request superseded")
			return true, "queued"
		end

		pending = request
		return true, "queued"
	end

	return start_request(request)
end

function SaveManager.update(serialize_budget)
	if not active then
		start_pending_request()
		return nil
	end

	if active.stage == "serializing" then
		active.deadline = love.timer.getTime()
			+ (tonumber(serialize_budget) or DEFAULT_SERIALIZE_BUDGET)
		active.checks = 0
		local resumed, value = coroutine.resume(active.coroutine)
		if not resumed then
			finish_active(false, value)
			return "failed"
		end

		if coroutine.status(active.coroutine) == "dead" then
			active.payload = value
			active.snapshot = nil
			active.coroutine = nil
			local ready, worker_error = ensure_worker()
			if not ready then
				finish_active(false, worker_error)
				return "failed"
			end

			local queued, queue_error = pcall(requests.push, requests, {
				kind = "save",
				id = active.id,
				filename = active.filename,
				payload = active.payload,
				metadata = active.metadata,
			})
			if not queued then
				finish_active(false, queue_error)
				return "failed"
			end
			active.payload = nil
			active.metadata = nil
			active.stage = "writing"
			return "writing"
		end
		return "serializing"
	end

	if active.stage == "writing" then
		local thread_error = worker and worker:getError()
		if thread_error then
			worker = nil
			finish_active(false, thread_error)
			return "failed"
		end

		local response = results and results:pop()
		while response and response.id ~= active.id do
			response = results:pop()
		end
		if response then
			if response.ok then
				finish_active(true, nil, response)
				return "saved"
			end
			finish_active(false, response.error or "save worker failed", response)
			return "failed"
		end
		return "writing"
	end
end

function SaveManager.is_busy()
	return active ~= nil or pending ~= nil
end

function SaveManager.stage()
	return active and active.stage or nil
end

function SaveManager.shutdown()
	pending = nil
	active = nil
	if worker and worker:isRunning() and requests then
		pcall(requests.push, requests, { kind = "quit" })
		pcall(worker.wait, worker)
	end
	worker = nil
	requests = nil
	results = nil
end

return SaveManager

local request_channel_name, result_channel_name = ...
local requests = love.thread.getChannel(request_channel_name)
local results = love.thread.getChannel(result_channel_name)
local SaveFormat = require("src.save_format")
local SaveIO = require("src.save_io")

local function save_job(job)
	-- Compression happens before touching either the primary save or its backup.
	-- A compression failure therefore cannot damage the previous save.
	local stored = SaveFormat.encode(job.payload)
	local written, write_error = SaveIO.write_with_backup(job.filename, stored)
	if not written then
		error(write_error or "could not write save")
	end

	local metadata_error
	if job.metadata then
		local metadata_written
		metadata_written, metadata_error = SaveIO.write_with_backup(
			"info.save",
			job.metadata
		)
		if metadata_written then
			metadata_error = nil
		end
	end

	return {
		kind = "save",
		id = job.id,
		ok = true,
		raw_size = #job.payload,
		stored_size = #stored,
		metadata_error = metadata_error,
	}
end

while true do
	local job = requests:demand()
	if job.kind == "quit" then
		break
	end

	local ok, response = pcall(save_job, job)
	if not ok then
		response = {
			kind = "save",
			id = job.id,
			ok = false,
			error = tostring(response),
		}
	end
	results:push(response)
end

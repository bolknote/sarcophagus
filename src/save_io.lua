local SaveIO = {}

function SaveIO.write_with_backup(filename, data)
	local previous = love.filesystem.read(filename)
	if previous then
		local backed_up, backup_error = love.filesystem.write(filename .. ".bak", previous)
		if not backed_up then
			return false, backup_error or "could not write backup"
		end
	end

	local written, write_error = love.filesystem.write(filename, data)
	if not written then
		return false, write_error or "could not write file"
	end
	return true
end

return SaveIO

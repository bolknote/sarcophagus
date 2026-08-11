local StateCopy = {}

function StateCopy.copy(value, seen)
	if type(value) ~= "table" then
		if type(value) == "cdata" then return 1000 end
		return value
	end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local copy = {}
	seen[value] = copy
	for key, nested in next, value do
		local copied_key = type(key) == "table" and StateCopy.copy(key, seen) or key
		copy[copied_key] = StateCopy.copy(nested, seen)
	end
	return copy
end

return StateCopy

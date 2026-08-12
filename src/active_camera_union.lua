local ActiveCameraUnion = {}

local function rectangle(camera, width, height)
	if type(camera) ~= "table" then return nil end
	local left = math.floor(tonumber(camera.xtile) or 0)
	local top = math.floor(tonumber(camera.ytile) or 0)
	return {
		left = left,
		right = left + width + 2,
		top = top,
		bottom = top + height + 2,
	}
end

local function contains(rectangle_value, x, y)
	return x >= rectangle_value.left and x <= rectangle_value.right
		and y >= rectangle_value.top and y <= rectangle_value.bottom
end

function ActiveCameraUnion.each(cameras, width, height, callback)
	assert(type(callback) == "function", "active-cell callback is required")
	width = math.max(0, math.floor(tonumber(width) or 0))
	height = math.max(0, math.floor(tonumber(height) or 0))
	local previous = {}
	local unique_count = 0
	local candidate_count = 0

	for _, camera in ipairs(cameras or {}) do
		local current = rectangle(camera, width, height)
		if current then
			for x = current.left, current.right do
				for y = current.top, current.bottom do
					candidate_count = candidate_count + 1
					local duplicate = false
					for _, seen in ipairs(previous) do
						if contains(seen, x, y) then
							duplicate = true
							break
						end
					end
					if not duplicate then
						unique_count = unique_count + 1
						callback(x, y)
					end
				end
			end
			previous[#previous + 1] = current
		end
	end

	return unique_count, candidate_count
end

return ActiveCameraUnion

local validator = {}

local color_pattern = "{#%x+}"
local format_pattern = "%%[-+#0]*%d*%.?%d*[cdeEfgGiouxXqs]"
local gameplay_markers = { "#dig", "#cut", "#chop", "#smash", "#pierce", "≈" }

local function sorted_matches(value, pattern)
	local matches = {}
	for match in value:gmatch(pattern) do
		matches[#matches + 1] = match
	end
	table.sort(matches)
	return table.concat(matches, "\0")
end

local function count_plain(value, needle)
	local count = 0
	local offset = 1
	while true do
		local found = value:find(needle, offset, true)
		if not found then
			return count
		end
		count = count + 1
		offset = found + #needle
	end
end

local function count_strings(value)
	if type(value) == "string" then
		return 1
	end
	if type(value) ~= "table" then
		return 0
	end

	local count = 0
	for _, child in pairs(value) do
		count = count + count_strings(child)
	end
	return count
end

local function validate_string(base, translation, path, errors, warnings)
	if sorted_matches(base, "_(%d+)_") ~= sorted_matches(translation, "_(%d+)_") then
		errors[#errors + 1] = path .. ": placeholder set differs"
	end

	if sorted_matches(base, color_pattern) ~= sorted_matches(translation, color_pattern) then
		errors[#errors + 1] = path .. ": color-tag set differs"
	end

	if sorted_matches(base, format_pattern) ~= sorted_matches(translation, format_pattern) then
		errors[#errors + 1] = path .. ": string.format token set differs"
	end

	if count_plain(base, "%%") ~= count_plain(translation, "%%") then
		errors[#errors + 1] = path .. ": escaped percent count differs"
	end

	for _, marker in ipairs(gameplay_markers) do
		if count_plain(base, marker) ~= count_plain(translation, marker) then
			errors[#errors + 1] = path .. ": gameplay marker differs: " .. marker
		end
	end

	if count_plain(base, "\n") ~= count_plain(translation, "\n") then
		warnings[#warnings + 1] = path .. ": newline count differs"
	end
end

local function validate_overlay(base, overlay, path, errors, warnings)
	for key, translation in pairs(overlay) do
		local base_value = base[key]
		local child_path = path .. "[" .. tostring(key) .. "]"

		if base_value == nil then
			errors[#errors + 1] = child_path .. ": key does not exist in English locale"
		elseif type(base_value) ~= type(translation) then
			errors[#errors + 1] = child_path .. ": expected " .. type(base_value)
		elseif type(translation) == "table" then
			validate_overlay(base_value, translation, child_path, errors, warnings)
		elseif type(translation) == "string" then
			validate_string(base_value, translation, child_path, errors, warnings)
		end
	end
end

function validator.validate()
	local english = require("locales.en")
	local russian = require("locales.ru")
	local errors = {}
	local warnings = {}

	validate_overlay(english, russian, "ru", errors, warnings)

	local base_strings = count_strings(english)
	local translated_strings = count_strings(russian)
	local coverage = base_strings > 0 and translated_strings / base_strings * 100 or 0
	local summary = (
		"translated=%d base=%d coverage=%.1f%% warnings=%d"
	):format(translated_strings, base_strings, coverage, #warnings)

	if #errors > 0 then
		return false, summary .. " errors=" .. table.concat(errors, "; ")
	end

	return true, summary
end

return validator

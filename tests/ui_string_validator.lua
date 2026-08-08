local validator = {}

local presentation_files = {
	"achievements.lua",
	"craft.lua",
	"draw.lua",
	"draw_gui.lua",
	"escmenu.lua",
	"items.lua",
	"joystick.lua",
	"keypressed.lua",
	"menu.lua",
	"mobs_ai.lua",
	"textgui.lua",
}

local forbidden_phrases = {
	"Pick game slot:",
	"Key setup",
	"Press joystick/keyboard key",
	"(default is ",
	"to skip this key",
	" (requires: ",
	"Loc: ",
	"Week ",
	", Day ",
	"exterminate!",
}

local ui_sinks = {
	"textwall",
	"textbubble",
	"mob_sct",
	"love.graphics.print",
	"love.graphics.printf",
}

local function is_comment(line)
	return line:match("^%s*%-%-") ~= nil
end

local function has_ui_sink(line)
	for _, sink in ipairs(ui_sinks) do
		if line:find(sink, 1, true) then
			return true
		end
	end
	return false
end

local function has_literal_phrase(line)
	for literal in line:gmatch("['\"]([^'\"]*)['\"]") do
		if literal:match("[A-Za-z][A-Za-z]+%s+[A-Za-z][A-Za-z]+") then
			return true
		end
	end
	return false
end

function validator.validate()
	local errors = {}
	local scanned = 0

	for _, filename in ipairs(presentation_files) do
		local source, read_error = love.filesystem.read(filename)
		if not source then
			errors[#errors + 1] = filename .. ": " .. tostring(read_error)
		else
			scanned = scanned + 1
			local line_number = 0
			for line in (source .. "\n"):gmatch("(.-)\n") do
				line_number = line_number + 1
				if not is_comment(line) then
					for _, phrase in ipairs(forbidden_phrases) do
						if line:find(phrase, 1, true) then
							errors[#errors + 1] = (
								"%s:%d: visible text must come from a locale: %s"
							):format(filename, line_number, phrase)
						end
					end

					if has_ui_sink(line)
						and has_literal_phrase(line)
						and not line:find("msg.", 1, true)
						and not line:find("dumpvar", 1, true)
						and not line:find("love.timer.getFPS", 1, true)
					then
						errors[#errors + 1] = (
							"%s:%d: suspicious literal passed to a UI function"
						):format(filename, line_number)
					end
				end
			end
		end
	end

	if #errors > 0 then
		return false, "files=" .. scanned .. " errors=" .. table.concat(errors, "; ")
	end

	return true, "files=" .. scanned .. " suspicious_literals=0"
end

return validator

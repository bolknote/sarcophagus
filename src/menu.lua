local function menu_message(text, replacements)
	for key, value in pairs(replacements or {}) do
		local placeholder = "_" .. key .. "_"
		text = text:gsub(placeholder, function ()
			return tostring(value)
		end)
	end
	return text
end

local function localized_save_files()
	local files = {}
	for i = 1, 9 do
		local info = game_save_slot_info(i)
		if info then
			files[i] = I18N.format_datetime(msg, info.modtime)
		else
			files[i] = "-----------------"
		end
	end
	return files
end

function menu_save_position(position, fallback)
	position = tonumber(position) or tonumber(fallback) or 1
	position = math.floor(position)
	if position < 1 or position > 9 then
		return 1
	end
	return position
end

function menu_move_save_position(position, step, fallback)
	position = menu_save_position(position, fallback)
	return ((position - 1 + step) % 9) + 1
end

local function ensure_menu_selection()
	game.metasave = game.metasave or {}
	game.savepos = menu_save_position(game.savepos, game.metasave.gamepos)
	game.files = game.files or localized_save_files()
	stradd = stradd or ""
end

local generation_started_at = 0
local generation_progress = 0
local generation_stage = 1
local generation_eta
local generation_error

local stage_progress = {
	[1] = 0.01,
	[2] = 0.13,
	[3] = 0.14,
	[4] = 0.05,
	[5] = 0.14,
	[6] = 0.14,
	[7] = 0.22,
	[8] = 0.25,
	[9] = 0.94,
	[10] = 0.94,
	[11] = 1,
}

local function format_generation_time(seconds)
	seconds = math.max(0, math.floor(seconds + 0.5))
	if seconds < 60 then
		return menu_message(msg.mapgen_ui.seconds, {[1] = seconds})
	end

	return menu_message(msg.mapgen_ui.minutes, {
		[1] = math.floor(seconds / 60),
		[2] = string.format("%02d", seconds % 60),
	})
end

local function progress_from_message(info)
	if info == 11 then
		return 1, 11
	end

	if info >= 10 and info < 11 then
		return 0.94 + (info - 10) / 0.99 * 0.05, 10
	end

	if info >= 8 and info < 9 then
		return 0.25 + (info - 8) * 0.68, 8
	end

	if info >= 6 and info < 7 then
		return 0.14 + (info - 6) / 0.99 * 0.07, 6
	end

	local stage = math.floor(info)
	return stage_progress[stage] or generation_progress, stage
end

local function update_generation_progress(info)
	local progress, stage = progress_from_message(info)
	local previous_progress = generation_progress

	-- Stage 4 means the generator could not find a valid home and starts
	-- over. Reflect the restart instead of leaving a misleading high value.
	if info == 1 and generation_stage == 4 then
		generation_progress = progress
		generation_eta = nil
	else
		generation_progress = math.max(generation_progress, progress)
	end

	generation_stage = stage

	if generation_progress > previous_progress
		and generation_progress >= 0.05
		and generation_progress < 0.99 then
		local elapsed = love.timer.getTime() - generation_started_at
		if elapsed >= 1 then
			local estimate = elapsed * (1 - generation_progress) / generation_progress
			if generation_eta then
				generation_eta = generation_eta * 0.75 + estimate * 0.25
			else
				generation_eta = estimate
			end
		end
	end
end

local function begin_map_generation()
	local info_channel = love.thread.getChannel("geninfo")
	local data_channel = love.thread.getChannel("gendata")
	info_channel:clear()
	data_channel:clear()

	startgen = true
	generation_started_at = love.timer.getTime()
	generation_progress = 0
	generation_stage = 1
	generation_eta = nil
	generation_error = nil
	game.mapgenning = true

	if spt.wcursor then
		love.mouse.setCursor(spt.wcursor)
	end

	mapthread = love.thread.newThread("src/mapthread.lua")
	mapthread:start()
end

local function finish_map_generation()
	local data_channel = love.thread.getChannel("gendata")
	local start_y = tonumber(data_channel:pop())
	local start_x = tonumber(data_channel:pop())
	local generated_world = data_channel:pop()

	if not start_x or not start_y or type(generated_world) ~= "table" then
		generation_error = "invalid generated world data"
		return false
	end

	startgen = nil
	pl.starty = start_y
	pl.startx = start_x
	world = generated_world

	game.start = {
		truex = pl.startx * cf.w - 32,
		truey = pl.starty * cf.h + 32,
	}

	vi.xtile = pl.startx
	vi.ytile = pl.starty
	pl.startheight1 = pl.starty + 1
	pl.startheight2 = pl.starty + 12

	love.keypressed = love.old_keypressed
	love.update = love.old_update
	love.draw = love.old_draw

	if legacy then
		legacy = nil
		give_legacy(game.metasave.inv)

		if game.metasave.savedscore and game.metasave.savedscore > 0 then
			pl.score = game.metasave.savedscore * -1
		else
			pl.score = (game.metasave.lastscore or 0) * -1
		end

		pl.savedscore = math.abs(pl.score)
	else
		pl.score = 0
		pl.savedscore = 0
	end

	ani_new(game.start, "start")
	achi_ini()
	player_reset()
	screen_full()
	screen_res()
	inv_show()

	game.fadeout = 1000
	game.fadein = 0.5
	if spt.cursor then
		love.mouse.setCursor(spt.cursor)
	end

	game.menu = nil
	game.mapgenning = nil
	game.moved = true
	return true
end

local function generation_menu_text()
	local language = menu_message(msg.menu.language, {[1] = msg.language.name})

	if generation_error then
		return language
			.. "{#ff0044ff}" .. msg.mapgen_ui.failed .. "{#ffffffff}\n\n"
			.. tostring(generation_error) .. "\n\n"
			.. msg.mapgen_ui.retry
	end

	local elapsed = love.timer.getTime() - generation_started_at
	local percent = math.floor(generation_progress * 100 + 0.5)
	local remaining
	if generation_eta then
		remaining = menu_message(msg.mapgen_ui.remaining, {
			[1] = format_generation_time(generation_eta),
		})
	else
		remaining = msg.mapgen_ui.estimating
	end

	return language
		.. "{#feae34ff}" .. msg.mapgen_ui.title .. "{#ffffffff}\n\n"
		.. menu_message(msg.mapgen_ui.step, {
			[1] = msg.mapgen[generation_stage] or msg.mapgen[1],
		}) .. "\n\n"
		.. draw_progress(generation_progress) .. " " .. percent .. "%\n"
		.. menu_message(msg.mapgen_ui.elapsed, {
			[1] = format_generation_time(elapsed),
		}) .. "\n"
		.. remaining
end

local function update_map_generation()
	local info_channel = love.thread.getChannel("geninfo")
	local completed = false

	-- Drain the queue every frame. The old code consumed a single message per
	-- frame while the generator produced thousands, so a finished map could
	-- remain stuck behind several minutes of obsolete progress messages.
	while true do
		local info = info_channel:pop()
		if info == nil then
			break
		end

		update_generation_progress(info)
		if info == 11 then
			completed = true
			break
		end
	end

	if completed and finish_map_generation() then
		return
	end

	if mapthread then
		generation_error = mapthread:getError() or generation_error
	end
	game.menu = generation_menu_text()
end

function love.menu_keypressed(key, scan)
	if scan == "up" then
		scan = "w"
	elseif scan == "down" then
		scan = "s"
	end

	if scan == "f2" then
		language_next()
		game.files = localized_save_files()
		stradd = ""
		return
	end

	if startgen then
		if generation_error and scan == "return" then
			begin_map_generation()
		elseif generation_error and scan == "escape" then
			startgen = nil
			game.mapgenning = nil
			game.menu = nil
			if spt.cursor then
				love.mouse.setCursor(spt.cursor)
			end
		end
		return
	end

	-- A queued key event can be delivered after love.load and before the first
	-- menu_update.  Prepare the slot state here as well, so early arrows,
	-- Enter, and save deletion cannot operate on nil fields.
	ensure_menu_selection()

	if scan == "q" then
		love.event.quit()
	end

	if scan == "c" then
		love.joy_ini()
		love.keypressed = love.joy_keypressed
		love.update = love.joy_update
		love.draw = love.joy_draw
	end

	if scan == "h" then
		love.system.openURL("https://acerbial.itch.io/sarcophagus")
	end

	if scan == "o" then
		love.system.openURL("https://discord.gg/j7c2ytY")
	end

	if scan == "l" then
		legacy = true
		scan = "return"
	end

	if scan == "return" then
		sound_add("button", 20, {kill = 1})

		if game.files[game.savepos] ~= "-----------------" then
			local selected_slot = game.savepos
			local loaded, load_error = game_load(game.savepos)
			if loaded then
				game.escmenu = nil
				game.savepos = selected_slot
				game.save = nil
				game.load = nil
				game.pause = nil
				love.keypressed = love.old_keypressed
				love.update = love.old_update
				love.draw = love.old_draw
				screen_full()
				game.moved = true
			else
				stradd = msg.persistence.load_failed
				if oldprint then
					oldprint("Could not load save slot " .. tostring(selected_slot)
						.. ": " .. tostring(load_error))
				end
			end
		else
			begin_map_generation()
		end
	end

	if scan == "w" then
		sound_add("button", 4, {kill = 1})
		stradd = ""
		game.savepos = menu_move_save_position(
			game.savepos,
			-1,
			game.metasave.gamepos
		)
		read_screenshot(game.savepos)
	end

	if scan == "s" then
		sound_add("button", 4, {kill = 1})
		stradd = ""
		game.savepos = menu_move_save_position(
			game.savepos,
			1,
			game.metasave.gamepos
		)
		read_screenshot(game.savepos)
	end

	if scan == "backspace"
		and (is_pressed("lshift") or is_pressed("rshift")) then
		sound_add("button", 20, {kill = 1})
		game.menu = nil
		stradd = ""
		game_delete_save(game.savepos)
	end
end

function read_screenshot(n)
	if love.filesystem.getInfo(n .. ".png") then
		local loaded, image = pcall(love.graphics.newImage, n .. ".png")
		if not loaded then
			screenshot = nil
			return false, image
		end
		screenshot = image
		-- Save previews are resized by a non-integer factor in the menu. Linear
		-- sampling keeps Retina text and one-pixel UI lines intact when reduced.
		screenshot:setFilter("linear", "linear")
	else
		screenshot = nil
	end
	return screenshot ~= nil
end

function save_preview_layout(
	image_width,
	image_height,
	area_x,
	area_y,
	area_width,
	area_height,
	dpi_scale
)
	if image_width <= 0 or image_height <= 0
		or area_width <= 0 or area_height <= 0 then
		return nil
	end

	dpi_scale = math.max(1, dpi_scale or 1)
	local fit_scale = math.min(
		area_width / image_width,
		area_height / image_height
	)
	-- A PNG loaded from disk has dpiscale=1 even when captureScreenshot wrote
	-- Retina backing pixels. Never enlarge one source pixel beyond one output
	-- pixel; old low-resolution save previews remain smaller instead of blurry.
	local scale = math.min(fit_scale, 1 / dpi_scale)
	local width = image_width * scale
	local height = image_height * scale

	return {
		x = area_x + (area_width - width) / 2,
		y = area_y + (area_height - height) / 2,
		width = width,
		height = height,
		scale = scale,
	}
end

local function initialize_menu()
	stradd = ""
	game.metasave = game.metasave or {}
	game.savepos = menu_save_position(game.savepos, game.metasave.gamepos)
	read_screenshot(game.savepos)

	game.files = localized_save_files()

	game.menuani = {x = 90, y = 110}
	ani_new(game.menuani, "marsh")
end

function love.menu_update(d)
	dt = d
	sound_update()

	if startgen then
		update_map_generation()
		return
	end

	if game.menu == nil then
		initialize_menu()
	end

	-- Put the language selector before the slot list, where it cannot be
	-- missed below a long menu or disappear during world generation.
	game.menu = menu_message(msg.menu.language, {[1] = msg.language.name})
		.. msg.menu.pick_slot
	game.menuani.y = 201 + game.savepos * 14

	for i = 1, 9 do
		if game.savepos == i then
			game.menu = game.menu .. "{#f77622ff}  " .. game.files[i] .. "\n"
		else
			game.menu = game.menu .. "{#ffffffff}  " .. game.files[i] .. "\n"
		end
	end

	game.menu = game.menu .. "{#ffffffff}\n\n"
	if game.files[game.savepos] ~= "-----------------" then
		game.menu = game.menu .. msg.menu.load_slot
	else
		game.menu = game.menu .. msg.menu.new_slot
		if game.metasave.inv and #game.metasave.inv > 1 then
			game.menu = game.menu .. msg.menu.legacy
		end
	end

	game.menu = game.menu .. msg.menu.switch_worlds .. "\n\n{#feae34ff}"
	if stradd ~= "" then
		game.menu = game.menu .. "\n\n{#ff0044ff}" .. stradd .. "{#ffffffff}"
	end

	game.menu = game.menu .. "\n\n\n\n\n"
	game.menu = game.menu .. "{#888888ff}───────────────────────────────────────────\n\n"
	game.menu = game.menu .. msg.menu.homepage
	game.menu = game.menu .. msg.menu.discord
	game.menu = game.menu .. msg.menu.configure
	game.menu = game.menu .. msg.menu.author
	game.menu = game.menu .. msg.menu.modification

	if server_version ~= game_version and server_version ~= "" then
		game.menu = game.menu .. menu_message(msg.menu.update, {
			[1] = game_version,
			[2] = server_version,
		})
	else
		game.menu = game.menu .. menu_message(msg.menu.version, {[1] = game_version})
	end
end

function love.menu_draw()
	if screenshot and not startgen then
		local preview_x = 700
		local image_width, image_height = screenshot:getPixelDimensions()
		local preview = save_preview_layout(
			image_width,
			image_height,
			preview_x,
			0,
			screen.width - preview_x,
			screen.height,
			love.graphics.getDPIScale()
		)
		if preview then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(
				screenshot,
				math.floor(preview.x),
				math.floor(preview.y),
				0,
				preview.scale,
				preview.scale
			)
		end
	end

	love.graphics.setColor(0, 0, 0, 0.9)
	love.graphics.rectangle("fill", 0, 86, 700, 350)
	love.graphics.setColor(1, 1, 1, 1)

	if not startgen then
		-- This is deliberately the original 12-frame marsh-light selector.
		ani_draw(game.menuani, dt)
	end

	love.graphics.draw(quad, spt.sarco, 32, 45)
	love.graphics.setFont(font2)
	love.graphics.printf(text_color(msg.menu.etymology), 35, 105, 700)
	love.graphics.setFont(font)
	love.graphics.printf(text_color(game.menu or ""), 100, 150, 700)
end

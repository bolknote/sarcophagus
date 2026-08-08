local smoke = {}

local function finish(exit_code, message)
    local stream = exit_code == 0 and io.stdout or io.stderr
    local prefix = exit_code == 0 and "SARCOPHAGUS_SMOKE_OK " or "SARCOPHAGUS_SMOKE_FAIL "
    stream:write(prefix .. message .. "\n")
    love.event.quit(exit_code)
end

local function table_size(value)
    local count = 0
    for _ in pairs(value or {}) do
        count = count + 1
    end
    return count
end

local function validate_loaded_game(slot)
    assert(game_load(slot), "game_load returned false")
    assert(type(world) == "table" and next(world), "world is empty")
    assert(type(pl) == "table", "player state is missing")
    assert(type(pl.inv) == "table", "player inventory is missing")
    assert(type(game) == "table", "game state is missing")
    assert(type(vi) == "table", "camera state is missing")
    assert(type(mobs) == "table", "mob state is missing")

    local rendered, render_error = pcall(draw_gui)
    assert(rendered, "localized HUD render failed: " .. tostring(render_error))

    return (
        "mode=load language=%s slot=%d world_rows=%d inventory=%d mobs=%d version=%s"
    ):format(
		LANGUAGE,
        slot,
        table_size(world),
        table_size(pl.inv),
        table_size(mobs),
        tostring(game.version)
    )
end

local function validate_save_fixture(slot)
    local original_identity = love.filesystem.getIdentity()
    local test_identity = "sarcophagus-load-smoke-" .. tostring(LANGUAGE)
    local save_name = tostring(slot) .. ".sav"
    love.filesystem.setIdentity(test_identity)
    love.filesystem.remove(save_name)

    local ok, result = pcall(function()
        local fixture_name = "tests/fixtures/" .. save_name
        local fixture, read_error = love.filesystem.read(fixture_name)
        assert(fixture, "cannot read save fixture: " .. tostring(read_error))
        assert(love.filesystem.write(save_name, fixture), "cannot stage save fixture")
        return validate_loaded_game(slot)
    end)

    love.filesystem.remove(save_name)
    love.filesystem.setIdentity(original_identity)

    if not ok then
        error(result)
    end

    finish(0, result)
end

local function export_atlas()
    local output_directory = os.getenv("SARCOPHAGUS_ATLAS_OUTPUT")
    assert(output_directory and output_directory ~= "", "SARCOPHAGUS_ATLAS_OUTPUT is required")
    output_directory = output_directory:gsub("/+$", "")

	local atlas_width, atlas_height = quad:getPixelDimensions()
	assert(atlas_width == 1024 and atlas_height == 1024, (
		"atlas must be 1024x1024 pixels, got %dx%d"
	):format(atlas_width, atlas_height))
	assert(quad:getDPIScale() == 1, "atlas DPI scale must stay at 1")
	assert(quadlist["sacro.png"].w == 370, "title quad width is invalid")
	assert(quadlist["sacro.png"].h == 53, "title quad height is invalid")
	assert(quadlist["marshlight1.png"].w == 16, "menu selector quad width is invalid")
	assert(quadlist["marshlight1.png"].h == 16, "menu selector quad height is invalid")

	local exported = {}
    for _, name in ipairs({ "quad.png", "quad.table" }) do
        local data, read_error = love.filesystem.read(name)
        assert(data, "cannot read generated " .. name .. ": " .. tostring(read_error))

        local target = assert(io.open(output_directory .. "/" .. name, "wb"))
        assert(target:write(data))
        assert(target:close())
        exported[name] = #data
    end

    finish(0, (
		"mode=atlas pixels=%dx%d dpi=%.1f quad_png_bytes=%d quad_table_bytes=%d"
	):format(
		atlas_width,
		atlas_height,
		quad:getDPIScale(),
		exported["quad.png"],
		exported["quad.table"]
	))
end

local function validate_settings()
    local original_identity = love.filesystem.getIdentity()
    local original_language = LANGUAGE
    local test_identity = "sarcophagus-settings-smoke"
    love.filesystem.setIdentity(test_identity)
    love.filesystem.remove("settings.json")

    local ok, result = pcall(function()
        language_set("en", false)
        assert(telltime(0) == "Week 00, Day 00, 00:00", "English time format is invalid")
        local timestamp = os.time({ year = 2026, month = 8, day = 8, hour = 16, min = 23, sec = 29 })
        assert(
            I18N.format_datetime(msg, timestamp) == "Sat Aug 8 16:23:29 2026",
            "English save timestamp format is invalid"
        )
        language_next()
        assert(LANGUAGE == "ru", "language switch did not activate Russian")
        assert(msg.menu.pick_slot == "Выберите слот игры:\n\n", "Russian menu was not activated")
        assert(telltime(0) == "Неделя 00, день 00, 00:00", "Russian time format is invalid")
        assert(
            I18N.format_datetime(msg, timestamp) == "сб, 8 авг. 2026, 16:23:29",
            "Russian save timestamp format is invalid"
        )
        assert(utf8.len(draw_tool_pad("тест")) == 13, "UTF-8 UI padding is invalid")

        local loaded = SETTINGS_STORE.load()
        assert(loaded.language == "ru", "settings language was not restored")
        return loaded.language
    end)

    language_set(original_language, false)
    love.filesystem.remove("settings.json")
    love.filesystem.setIdentity(original_identity)

    if not ok then
        error(result)
    end

    finish(0, "mode=settings language=" .. result)
end

local function validate_display()
    local width, height, flags = love.window.getMode()
    local pixel_width, pixel_height = love.graphics.getPixelDimensions()
    local dpi_scale = love.graphics.getDPIScale()

    assert(flags.highdpi == true, "high-DPI backbuffer is disabled")
    assert(flags.usedpiscale ~= false, "automatic DPI scaling is disabled")
    assert(dpi_scale >= 1, "invalid DPI scale")
    assert(math.abs(pixel_width - width * dpi_scale) < 1, "pixel width does not match DPI scale")
    assert(math.abs(pixel_height - height * dpi_scale) < 1, "pixel height does not match DPI scale")

    local pixel_font = love.graphics.newFont(
        "assets/fonts/GohuFont-Medium.ttf",
        14,
        "normal",
        1
    )
	assert(pixel_font:getDPIScale() == 1, "pixel-font DPI policy changed")

	local atlas_width, atlas_height = quad:getPixelDimensions()
	assert(atlas_width == 1024 and atlas_height == 1024, (
		"Retina changed atlas pixels to %dx%d"
	):format(atlas_width, atlas_height))
	assert(quad:getDPIScale() == 1, "Retina changed atlas DPI scale")
	assert(DEFAULT_AMBIENT_LIGHT == 0.10, "default cave visibility changed")

	local original_language = LANGUAGE
	for _, language in ipairs({"en", "ru"}) do
		language_set(language, false)
		local top = telltime(0) .. " †0"
		local location = message(msg.ui.location, {[1] = 0, [2] = 0})
		local bottom = msg.gui[38] .. "0]──[" .. location .. "]"
		local border, frame_width = status_border(top, bottom, 8)
		local row_count = 0
		for row in border:gmatch("([^\n]+)") do
			row_count = row_count + 1
			assert(utf8.len(row) == frame_width, (
				"%s HUD border row %d is %d cells instead of %d"
			):format(language, row_count, utf8.len(row), frame_width))
		end
		assert(row_count == 10, language .. " HUD border row count is invalid")
	end
	language_set(original_language, false)

    finish(0, (
		"mode=display logical=%dx%d pixels=%dx%d dpi=%.2f atlas=%dx%d highdpi=%s usedpiscale=%s"
	):format(
        width,
        height,
        pixel_width,
        pixel_height,
		dpi_scale,
		atlas_width,
		atlas_height,
        tostring(flags.highdpi),
        tostring(flags.usedpiscale)
    ))
end

local function begin_map_generation_test()
    local info_channel = love.thread.getChannel("geninfo")
	local data_channel = love.thread.getChannel("gendata")
	local started_at = love.timer.getTime()
	local stage_times = {}
	local progress_messages = 0

    info_channel:clear()
    data_channel:clear()

    local thread = love.thread.newThread("src/mapthread.lua")
    thread:start()

    love.update = function()
        local thread_error = thread:getError()
        if thread_error then
            finish(1, "mode=mapgen thread_error=" .. tostring(thread_error))
            return
        end

        while true do
            local progress = info_channel:pop()
			if progress == nil then
				break
			end

			progress_messages = progress_messages + 1
			local stage = progress == 11 and 11 or math.floor(progress)
			stage_times[stage] = stage_times[stage]
				or (love.timer.getTime() - started_at)

			if progress == 11 then
				assert(progress_messages <= 500, (
					"map generator emitted too many progress messages: %d"
				):format(progress_messages))
				local start_y = data_channel:pop()
                local start_x = data_channel:pop()
                local generated_world = data_channel:pop()

                local ok = type(generated_world) == "table"
                    and next(generated_world) ~= nil
                    and tonumber(start_x) ~= nil
                    and tonumber(start_y) ~= nil

                if not ok then
                    finish(1, "mode=mapgen invalid_generated_data")
                    return
                end

				local stage_report = {}
				for stage_number = 1, 11 do
					if stage_times[stage_number] then
						stage_report[#stage_report + 1] = ("%d:%.1f"):format(
							stage_number,
							stage_times[stage_number]
						)
					end
				end

				finish(0, (
					"mode=mapgen world_rows=%d start_x=%d start_y=%d elapsed=%.2f messages=%d stages=%s"
				):format(
					table_size(generated_world),
					tonumber(start_x),
					tonumber(start_y),
					love.timer.getTime() - started_at,
					progress_messages,
					table.concat(stage_report, ",")
				))
                return
            end
        end

        if love.timer.getTime() - started_at > 180 then
            finish(1, "mode=mapgen timeout=180")
        end
    end

    love.draw = function()
        love.graphics.print("Sarcophagus map generation smoke test", 20, 20)
    end
end

local function write_render(image_data, mode)
	local output = os.getenv("SARCOPHAGUS_RENDER_OUTPUT")
	assert(output and output ~= "", "SARCOPHAGUS_RENDER_OUTPUT is required")

	local encoded = image_data:encode("png")
	local target = assert(io.open(output, "wb"))
	assert(target:write(encoded:getString()))
	assert(target:close())
	finish(0, ("mode=%s-render output=%s"):format(mode, output))
end

local function begin_render_test(mode)
	local delegate_update = love.update
	local delegate_draw = love.draw
	local wrapper_update
	local wrapper_draw
	local requested = false
	local playable_frames = 0
	local game_started = mode == "menu"
	local started_at = love.timer.getTime()

	if mode == "new-game" or mode == "generation" then
		game.fullscreen = false
		love.menu_update(0)
		game.savepos = 1
		game.files[1] = "-----------------"
		love.menu_keypressed("return", "return")
		delegate_update = love.update
		delegate_draw = love.draw
		if mode == "generation" then
			game_started = true
		end
	end

	wrapper_update = function(dt)
		delegate_update(dt)

		-- World generation replaces all three callbacks when it finishes.
		-- Keep the render harness installed and delegate to the new gameplay
		-- callbacks from then on.
		if love.update ~= wrapper_update then
			delegate_update = love.update
			love.update = wrapper_update
			if love.draw ~= wrapper_draw then
				delegate_draw = love.draw
				love.draw = wrapper_draw
			end
			game_started = true
			playable_frames = 0
		end

		if game_started then
			playable_frames = playable_frames + 1
		end

		if love.timer.getTime() - started_at > 180 then
			finish(1, "mode=" .. mode .. "-render timeout=180")
		end
	end

	wrapper_draw = function()
		delegate_draw()
		local frames_needed = mode == "menu" and 2
			or mode == "generation" and 150
			or 90
		if game_started and playable_frames >= frames_needed and not requested then
			requested = true
			love.graphics.captureScreenshot(function(image_data)
				local ok, err = pcall(write_render, image_data, mode)
				if not ok then
					finish(1, "mode=" .. mode .. "-render " .. tostring(err))
				end
			end)
		end
	end

	love.update = wrapper_update
	love.draw = wrapper_draw
end

function smoke.install(specification)
    local mode, value = specification:match("^([^:]+):?(.*)$")
    local original_load = love.load

	-- Smoke tests drive the game directly and never expect real input.  Ignore
	-- events from the temporary LÖVE windows so typing elsewhere cannot reach
	-- partially initialized gameplay callbacks while a test is quitting.
	love.keypressed = function() end
	love.keyreleased = function() end
	love.mousepressed = function() end
	love.mousereleased = function() end
	love.wheelmoved = function() end

    love.load = function(...)
        if mode == "locales" then
            local ok, report = require("tests.locale_validator").validate()
            if ok then
                finish(0, "mode=locales " .. report)
            else
                finish(1, "mode=locales " .. report)
            end
            return
        end

        if mode == "ui-strings" then
            local ok, report = require("tests.ui_string_validator").validate()
            if ok then
                finish(0, "mode=ui-strings " .. report)
            else
                finish(1, "mode=ui-strings " .. report)
            end
            return
        end

        if mode == "settings" then
            local ok, err = pcall(validate_settings)
            if not ok then
                finish(1, "mode=settings " .. tostring(err))
            end
            return
        end

		if mode == "display" then
			local ok, err = pcall(validate_display)
			if not ok then
				finish(1, "mode=display " .. tostring(err))
			end
			return
		end

        original_load(...)

		if mode == "mapgen" then
			begin_map_generation_test()
			return
		end

		if mode == "menu-render" then
			begin_render_test("menu")
			return
		end

		if mode == "new-game-render" then
			begin_render_test("new-game")
			return
		end

		if mode == "generation-render" then
			begin_render_test("generation")
			return
		end

        if mode == "atlas" then
            local ok, err = pcall(export_atlas)
            if not ok then
                finish(1, "mode=atlas " .. tostring(err))
            end
            return
        end

        local ok, err = pcall(function()
            if mode == "load" then
                local slot = tonumber(value)
                assert(slot and slot >= 1 and slot <= 9, "invalid save slot")
                validate_save_fixture(slot)
            else
                error("unknown smoke-test mode: " .. tostring(mode))
            end
        end)

        if not ok then
            finish(1, tostring(err))
        end
    end
end

return smoke

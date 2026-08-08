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

    finish(0, (
        "mode=load language=%s slot=%d world_rows=%d inventory=%d mobs=%d version=%s"
    ):format(
		LANGUAGE,
        slot,
        table_size(world),
        table_size(pl.inv),
        table_size(mobs),
        tostring(game.version)
    ))
end

local function export_atlas()
    local output_directory = os.getenv("SARCOPHAGUS_ATLAS_OUTPUT")
    assert(output_directory and output_directory ~= "", "SARCOPHAGUS_ATLAS_OUTPUT is required")
    output_directory = output_directory:gsub("/+$", "")

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
        "mode=atlas quad_png_bytes=%d quad_table_bytes=%d"
    ):format(exported["quad.png"], exported["quad.table"]))
end

local function validate_settings()
    local original_identity = love.filesystem.getIdentity()
    local original_language = LANGUAGE
    local test_identity = "sarcophagus-settings-smoke"
    love.filesystem.setIdentity(test_identity)
    love.filesystem.remove("settings.json")

    local ok, result = pcall(function()
        language_set("en", false)
        language_next()
        assert(LANGUAGE == "ru", "language switch did not activate Russian")
        assert(msg.menu.pick_slot == "Выберите слот игры:\n\n", "Russian menu was not activated")

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

local function begin_map_generation_test()
    local info_channel = love.thread.getChannel("geninfo")
    local data_channel = love.thread.getChannel("gendata")
    local started_at = love.timer.getTime()

    info_channel:clear()
    data_channel:clear()

    local thread = love.thread.newThread("mapthread.lua")
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

            if progress == 11 then
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

                finish(0, (
                    "mode=mapgen world_rows=%d start_x=%d start_y=%d elapsed=%.2f"
                ):format(
                    table_size(generated_world),
                    tonumber(start_x),
                    tonumber(start_y),
                    love.timer.getTime() - started_at
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

function smoke.install(specification)
    local mode, value = specification:match("^([^:]+):?(.*)$")
    local original_load = love.load

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

        if mode == "settings" then
            local ok, err = pcall(validate_settings)
            if not ok then
                finish(1, "mode=settings " .. tostring(err))
            end
            return
        end

        original_load(...)

        if mode == "mapgen" then
            begin_map_generation_test()
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
                validate_loaded_game(slot)
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

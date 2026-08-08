local smoke = {}

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

    io.stdout:write((
        "SARCOPHAGUS_SMOKE_OK mode=load slot=%d world_rows=%d inventory=%d mobs=%d version=%s"
    ):format(
        slot,
        table_size(world),
        table_size(pl.inv),
        table_size(mobs),
        tostring(game.version)
    ) .. "\n")
end

function smoke.install(specification)
    local mode, value = specification:match("^([^:]+):?(.*)$")
    local original_load = love.load

    love.load = function(...)
        original_load(...)

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
            io.stderr:write("SARCOPHAGUS_SMOKE_FAIL " .. tostring(err) .. "\n")
            love.event.quit(1)
            return
        end

        love.event.quit(0)
    end
end

return smoke

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

	-- The normal draw callback initializes animation-frame globals before it
	-- delegates to draw_gui; this direct HUD smoke test must do the same.
	ba1_2 = ba1_2 or 1
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

local function validate_persistence()
	local original_identity = love.filesystem.getIdentity()
	local original_capture_screenshot = love.graphics.captureScreenshot
	local original_textwall = textwall
	local original_random = love.math.random
	local test_identity = "sarcophagus-persistence-smoke"
	local random_was_replaced = false

	love.filesystem.setIdentity(test_identity)
	for slot = 1, 3 do
		game_delete_save(slot)
	end
	for _, filename in ipairs({
		"info.save",
		"info.save.bak",
		"joy.stick",
	}) do
		love.filesystem.remove(filename)
	end

	local ok, result = pcall(function()
		local fixture, fixture_error = love.filesystem.read("tests/fixtures/9.sav")
		assert(fixture, "cannot read persistence fixture: " .. tostring(fixture_error))

		local previous_world = world
		local previous_vi = vi
		local previous_pl = pl
		local previous_game = game
		local loaded, load_error = game_load(1)
		assert(not loaded and load_error, "empty save slot was reported as loaded")
		assert(world == previous_world and vi == previous_vi
			and pl == previous_pl and game == previous_game,
			"empty save slot changed active game state")

		assert(love.filesystem.write("1.sav", "not a Sarcophagus save"))
		loaded, load_error = game_load(1)
		assert(not loaded and load_error, "damaged save was reported as loaded")
		assert(world == previous_world and vi == previous_vi
			and pl == previous_pl and game == previous_game,
			"damaged save partially replaced active game state")
		love.filesystem.remove("1.sav")

		local legacy_save = love.data.compress("string", "gzip", fixture)
		assert(love.filesystem.write("1.save", legacy_save))
		local legacy_info, legacy_filename = game_save_slot_info(1)
		assert(legacy_info and legacy_filename == "1.save",
			"legacy compressed save is invisible to the slot menu")
		assert(game_load(1), "legacy compressed save did not load")
		assert(type(world) == "table" and next(world), "legacy save world is empty")

		-- A damaged newer-format file must not hide the valid legacy fallback.
		assert(love.filesystem.write("1.sav", "damaged current save"))
		assert(game_load(1), "valid legacy fallback was not tried")
		assert(game_delete_save(1), "save slot deletion reported no files")
		assert(not love.filesystem.getInfo("1.sav")
			and not love.filesystem.getInfo("1.save")
			and not love.filesystem.getInfo("1.sav.bak"),
			"save slot deletion left a format or backup behind")

		-- Saving twice creates a known-good backup. If the primary file is later
		-- damaged, loading must transparently fall back to it.
		love.graphics.captureScreenshot = function() end
		textwall = function() end
		assert(game_save(2), "first game save failed")
		assert(game_save(2), "second game save failed")
		assert(love.filesystem.getInfo("2.sav.bak"), "save backup was not created")
		assert(love.filesystem.write("2.sav", "damaged after saving"))
		assert(game_load(2), "save backup did not recover a damaged primary save")

		assert(love.filesystem.write("info.save", "damaged metadata"))
		love.filesystem.remove("info.save.bak")
		assert(game_loadinfo() == false, "damaged metadata was reported as loaded")
		assert(type(game.metasave) == "table", "metadata fallback is not a table")

		assert(love.filesystem.write("joy.stick", "damaged controller data"))
		assert(love.joy_load() == false, "damaged controller data was reported as loaded")
		assert(type(k2j) == "table" and type(j2k) == "table",
			"damaged controller data did not restore default mappings")

		assert(love.filesystem.write("3.png", "damaged screenshot"))
		assert(read_screenshot(3) == false, "damaged save preview was reported as loaded")
		assert(screenshot == nil, "damaged save preview left an image active")

		-- Old saves may predate disaster bookkeeping. Migration must supply every
		-- field used by the current simulation.
		pl.visited = nil
			pl.ferted = nil
			pl.disaster = nil
			pl.disastercd = nil
			local hidden_slot = pl.invsize + 50
			pl.inv[hidden_slot] = item_make(31)
			game_migrate()
			assert(type(pl.visited) == "table" and type(pl.ferted) == "table",
				"save migration did not add exploration histories")
			assert(pl.inv[hidden_slot] == nil,
				"save migration left an item in an inaccessible inventory slot")
		for name in pairs(cf.disaster) do
			assert(pl.disaster[name] and type(pl.disaster[name].cd) == "number",
				"save migration did not add disaster state for " .. name)
		end

		pl.visited = {}
		pl.ferted = {}
		assert(far_frost_spawn(1) == nil, "far frost accepted an empty visited list")
		assert(amoeba_spawn(1) == nil, "amoeba accepted an empty visited list")
		assert(frost_spawn(1) == nil, "frost accepted an empty fertilized list")

		-- A random skip used to return from disaster_do and silently suppress all
		-- other due disasters. Both due entries must now advance independently.
		local previous_disaster_config = cf.disaster
		local previous_disaster_state = pl.disaster
		local previous_time = game.time
		local previous_debug = game.dbg
		cf.disaster = {
			frost = { ini = 0, cd = 10, chance = -1 },
			farfrost = { ini = 0, cd = 10, chance = -1 },
		}
		pl.disaster = {
			frost = { cd = 0, cnt = 0 },
			farfrost = { cd = 0, cnt = 0 },
		}
		game.time = 100
		game.dbg = {}
		love.math.random = function()
			return 0
		end
		random_was_replaced = true
		disaster_do()
		assert(pl.disaster.frost.cd == 110 and pl.disaster.farfrost.cd == 110,
			"one skipped disaster suppressed another due disaster")
		love.math.random = original_random
		random_was_replaced = false
		cf.disaster = previous_disaster_config
		pl.disaster = previous_disaster_state
		game.time = previous_time
		game.dbg = previous_debug

		return "mode=persistence atomic_load=true legacy=true backup=true corruption=true disasters=true"
	end)

	if random_was_replaced then
		love.math.random = original_random
	end
	love.graphics.captureScreenshot = original_capture_screenshot
	textwall = original_textwall
	for slot = 1, 3 do
		game_delete_save(slot)
	end
	for _, filename in ipairs({
		"info.save",
		"info.save.bak",
		"joy.stick",
	}) do
		love.filesystem.remove(filename)
	end
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
        assert(msg.gui.item.dig == "#копание: ", "Russian tool tags were not activated")
        for _, key in ipairs({ "dig", "cut", "chop", "smash", "pierce" }) do
            assert(
                utf8.len(msg.gui.item[key] .. "5") <= 13,
                "Russian tool tag is too wide for the item panel: " .. key
            )
        end

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
	assert(normalize_gameplay_key("up", false) == "w",
		"up arrow is not a gameplay/crafting alternative to W")
	assert(normalize_gameplay_key("down", false) == "s",
		"down arrow is not a gameplay/crafting alternative to S")
	assert(normalize_gameplay_key("up", true) == "up",
		"Ctrl+arrow no longer reaches development controls")
	assert(normalize_esc_menu_key("up", "up") == "w",
		"up arrow is not an Esc-menu alternative to W")
	assert(normalize_esc_menu_key("down", "down") == "s",
		"down arrow is not an Esc-menu alternative to S")
	assert(normalize_esc_menu_key("left", "left") == "a",
		"left arrow is not an Esc-menu alternative to A")
	assert(normalize_esc_menu_key("right", "right") == "d",
		"right arrow is not an Esc-menu alternative to D")
	assert(tool_damage_per_second({ dmgmin = 2, dmgmax = 6, digspeed = 2 }) == 2,
		"weapon DPS does not use the average of minimum and maximum damage")
	assert(next_numeric_id({ [1] = true, [3] = true }) == 4,
		"numeric ID allocation relies on the undefined length of a sparse table")
	assert(mob_collision_blocked({ right = 1, down = 1, left = 1, up = 0 }),
		"mob collision logic ignores a blocked ceiling")
	assert(not mob_collision_blocked({ right = 1, down = 1, left = 1, up = 1 }),
		"mob collision logic reports a clear path as blocked")
	assert(virtual_cursor_delta(nil, -1) == -12,
		"keyboard cursor movement lost its negative direction")
	assert(virtual_cursor_delta(-0.5, 1) == 4,
		"controller cursor movement uses the axis sign instead of the requested direction")
	local original_inventory = pl.inv
	local original_inventory_size = pl.invsize
	local original_inventory_selection = pl.invselect
	local original_inventory_show = pl.inv_show
	local original_inventory_show_cursor = pl.inv_show_c
	local duplicate_item = { i = 31, t = 1 }
	local selected_duplicate = { i = 31, t = 2 }
	pl.inv = { [1] = duplicate_item, [3] = selected_duplicate }
	pl.invsize = 3
	pl.invselect = 3
	inv_compact()
	assert(pl.inv[pl.invselect] == selected_duplicate,
		"inventory compaction changed which duplicate item was selected")
	assert(pl.inv[1] ~= nil and pl.inv[2] ~= nil and pl.inv[3] == nil,
		"inventory compaction left a numeric hole")
	local original_inv_ground_add = inv_ground_add
	local overflow_item = { i = 31, t = 2 }
	local dropped_overflow
	pl.inv[42] = overflow_item
	inv_ground_add = function(_, _, dropped)
		dropped_overflow = dropped
		return true
	end
	assert(inv_resize(-1) == 2, "inventory capacity was not reduced")
	assert(dropped_overflow == overflow_item and pl.inv[42] == nil,
		"inventory overflow left an inaccessible high-numbered slot")
	inv_ground_add = original_inv_ground_add
	local original_textwall_for_inventory = textwall
	textwall = function() end
	pl.inv = {
		[1] = { i = 31, t = 0, c = game.time },
		[2] = { i = 31, t = 0, c = game.time },
	}
	pl.invsize = 3
	pl.invselect = 1
	inv_tick_ttl()
	local expired_count = inv_count()
	assert(expired_count == 0,
		"expiring one inventory item skipped another item moved by compaction")
	textwall = original_textwall_for_inventory
	pl.inv = original_inventory
	pl.invsize = original_inventory_size
	pl.invselect = original_inventory_selection
	pl.inv_show = original_inventory_show
	pl.inv_show_c = original_inventory_show_cursor

	local original_stats = pl.stats
	pl.stats = {
		arms = { hp = 100, maxhp = 100 },
		body = { hp = 100, maxhp = 100 },
		heat = { hp = 100, maxhp = 100 },
		water = { hp = 100, maxhp = 100 },
	}
	local function equipment_state()
		return {
			slowed = pl.slowed,
			invsize = pl.invsize,
			arms_hp = pl.stats.arms.hp,
			arms_maxhp = pl.stats.arms.maxhp,
			body_hp = pl.stats.body.hp,
			body_maxhp = pl.stats.body.maxhp,
			heat_hp = pl.stats.heat.hp,
			heat_maxhp = pl.stats.heat.maxhp,
			water_hp = pl.stats.water.hp,
			water_maxhp = pl.stats.water.maxhp,
		}
	end
	for _, item_id in ipairs({ 170, 356, 357, 195, 350, 351 }) do
		local before = equipment_state()
		item[item_id].onequip()
		item[item_id].onunequip()
		local after = equipment_state()
		for field, expected in pairs(before) do
			assert(math.abs(after[field] - expected) < 0.000001, (
				"item %d does not undo equipment field %s"
			):format(item_id, field))
		end
	end
	pl.stats = original_stats

	local original_ambient = game.ambient
	game.ambient = nil
	buff[8].on_start()
	buff[8].on_remove()
	assert(game.ambient == nil, "removing dark vision left the cave permanently bright")
	game.ambient = original_ambient
	local original_adddamage = pl.adddamage
	local original_stat_spend = stat_spend
	pl.adddamage = 0
	stat_spend = function() end
	buff[22].on_start()
	buff[22].on_remove()
	assert(pl.adddamage == 0, "removing warpaint left a permanent damage bonus")
	pl.adddamage = original_adddamage
	stat_spend = original_stat_spend

	local original_buffs = pl.buffs
	local original_bufftick = pl.bufftick
	local original_lastshit = pl.lastshit
	local original_game_time = game.time
	local original_readmap_for_buffs = readmap
	local original_writemap_for_buffs = writemap
	local original_textwall_for_buffs = textwall
	local original_sound_stop = sound_stop
	local stopped_underwater_sound = false
	pl.stats = { water = { pc = 50 } }
	game.time = 100
	stat_spend = function() end
	readmap = function() return nil end
	writemap = function() end
	textwall = function() end
	sound_stop = function(name)
		if name == "underwater" then stopped_underwater_sound = true end
	end
	pl.buffs = { [19] = { ttl = 99, cnt = 1 } }
	pl.bufftick = 99
	buff_tick()
	assert(stopped_underwater_sound and pl.buffs[19] == nil,
		"naturally expired hold-breath did not run its cleanup")
	local stopped_splash_sound = false
	sound_stop = function(name)
		if name == "splash" then stopped_splash_sound = true end
	end
	pl.slowed = pl.slowed - 0.1
	pl.jumpyslow = pl.jumpyslow - 1.5
	pl.buffs = { [18] = { ttl = 99 } }
	pl.bufftick = 99
	buff_tick()
	assert(stopped_splash_sound and pl.buffs[18] == nil,
		"naturally expired submerged effect left splash audio playing")
	pl.buffs = { [16] = { ttl = 99 } }
	pl.bufftick = 99
	buff_tick()
	assert(pl.buffs[16] and pl.buffs[16].ttl > game.time,
		"diarrhoea refresh was immediately deleted by expiration cleanup")
	pl.buffs = original_buffs
	pl.bufftick = original_bufftick
	pl.lastshit = original_lastshit
	pl.stats = original_stats
	game.time = original_game_time
	stat_spend = original_stat_spend
	readmap = original_readmap_for_buffs
	writemap = original_writemap_for_buffs
	textwall = original_textwall_for_buffs
	sound_stop = original_sound_stop
	assert(mystify("Raw clay") == "??? ????",
		"ASCII undiscovered-item masking changed")
	assert(mystify("Сырая глина") == "????? ?????",
		"Russian undiscovered-item masking is not UTF-8-safe")
	local original_ambient_sound = game.ambient_sound
	game.ambient_sound = 11
	assert(sound_ambient_id() == 10 and game.ambient_sound == 10,
		"removed cave ambience can still be selected")
	game.ambient_sound = original_ambient_sound
	local center_collision = tocollide({{
		x = 32,
		y = 32,
		mode = {},
	}})
	assert(center_collision.up == nil and center_collision.down == nil
		and center_collision.left == nil and center_collision.right == nil,
		"collision check returned distances for directions that were not requested")
	local directional_collision = tocollide({{
		x = 32,
		y = 32,
		mode = { up = true, down = true, left = true, right = true },
	}})
	for _, direction in ipairs({ "up", "down", "left", "right" }) do
		assert(type(directional_collision[direction]) == "number",
			"collision check lost the " .. direction .. " distance")
	end
	local original_projectiles = proj
	local original_dt = dt
	proj = {{
		x = 32,
		y = 32,
		xspeed = 10,
		yspeed = 0,
		proj = 15,
		bounce = { 0, 0, 0, 0 },
	}}
	dt = 1 / 30
	proj_update()
	assert(proj[1] ~= nil, "projectile update unexpectedly removed a moving projectile")
	proj = original_projectiles
	dt = original_dt

	local original_random = love.math.random
	local damage_range
	love.math.random = function(minimum, maximum)
		damage_range = { minimum, maximum }
		return maximum
	end
	assert(projectile_item_damage({
		i = 5,
		tool = { dmgmin = 7, dmgmax = 9 },
	}) == 9, "thrown tool damage ignores the inventory instance stats")
	assert(damage_range[1] == 7 and damage_range[2] == 9,
		"thrown tool damage uses the wrong random range")
	damage_range = nil
	assert(projectile_item_damage({ i = 31 }) == 4,
		"fixed damage of a thrown stone changed")
	assert(damage_range == nil, "fixed projectile damage unexpectedly rolled a random value")
	love.math.random = original_random

	local animation = new_worldani("smoke-test", "assplode", {
		test_marker = 42,
	})
	assert(animation.test_marker == 42,
		"world animation options were written through an undefined object")
	worldani["smoke-test"] = nil

	local mob_list = {
		[2] = { proto = {} },
		[7] = { id = 1 },
	}
	assert(mobs_remove_prototypes(mob_list) == 1,
		"prototype mob cleanup did not report the removed entry")
	assert(mob_list[2] == nil and mob_list[7] ~= nil,
		"prototype mob cleanup removed the wrong entry")
	local original_mob_search_mobs = mobs
	local original_mob_search_readmap = readmap
	local original_global_b = _G.b
	mobs = { [4] = { tx = 2, ty = 2, id = 1 } }
	readmap = function() return nil end
	_G.b = nil
	assert(mob_search(1, 1, 5) == 1,
		"active mob search uses an out-of-scope stored-mob list")
	mobs = original_mob_search_mobs
	readmap = original_mob_search_readmap
	_G.b = original_global_b

	local original_mobs = mobs
	local original_global_m = _G.m
	local original_creature = creature[999]
	local original_readmap = readmap
	local original_tile2px = tile2px
	local original_coord_screen2true = coord_screen2true
	local original_ani_new = ani_new
	local original_ani_setstatus = ani_setstatus
	local original_mob_upgrade = mob_upgrade
	local global_m_sentinel = {}
	_G.m = global_m_sentinel
	mobs = { [1] = { id = 1 }, [3] = { id = 1 } }
	creature[999] = { proto = { type = "smoke-mob", anidef = "idle" } }
	readmap = function() return 0 end
	tile2px = function() return { x = 0, y = 0 } end
	coord_screen2true = function() end
	ani_new = function() end
	ani_setstatus = function() end
	mob_upgrade = function() end
	local created_mob_id = mob_create(1, 1, 999)
	assert(created_mob_id == 4 and mobs[4] ~= nil,
		"mob creation does not preserve IDs in a sparse mob table")
	assert(_G.m == global_m_sentinel,
		"mob creation leaked its temporary mob into a global variable")
	mobs = original_mobs
	_G.m = original_global_m
	creature[999] = original_creature
	readmap = original_readmap
	tile2px = original_tile2px
	coord_screen2true = original_coord_screen2true
	ani_new = original_ani_new
	ani_setstatus = original_ani_setstatus
	mob_upgrade = original_mob_upgrade

	local original_writemap = writemap
	local original_maptile = maptile
	local original_textwall = textwall
	local original_mob_create = mob_create
	local original_digcount = pl.digcount
	local capsule_spawns = 0
	local capsule_y_range
	readmap = function() return nil end
	writemap = function() end
	maptile = function() return 0 end
	textwall = function() end
	mob_create = function() capsule_spawns = capsule_spawns + 1 end
	love.math.random = function(minimum, maximum)
		assert(minimum <= maximum, "high-tech capsule uses an inverted random interval")
		if minimum < 0 then capsule_y_range = { minimum, maximum } end
		return minimum
	end
	assert(stone[115].ondig(10, 20) == false,
		"high-tech capsule no longer interrupts the normal dig action")
	assert(capsule_spawns == 3, "high-tech capsule did not finish its ambush")
	assert(capsule_y_range[1] == -7 and capsule_y_range[2] == -3,
		"high-tech capsule uses the wrong vertical spawn range")
	readmap = original_readmap
	writemap = original_writemap
	maptile = original_maptile
	textwall = original_textwall
	mob_create = original_mob_create
	love.math.random = original_random
	pl.digcount = original_digcount

	local original_escmenu_position = game.escmenu
	local original_sound_add = sound_add
	sound_add = function() end
	game.escmenu = 4
	esc_menu_keypress("up", "up")
	assert(game.escmenu == 2, "up arrow did not move the Esc-menu selection")
	esc_menu_keypress("down", "down")
	assert(game.escmenu == 4, "down arrow did not move the Esc-menu selection")
	game.escmenu = original_escmenu_position
	sound_add = original_sound_add

	local preview = assert(save_preview_layout(
		3024,
		1898,
		700,
		0,
		580,
		720,
		2
	), "Retina save preview layout is missing")
	assert(preview.width <= 580 and preview.height <= 720,
		"Retina save preview crosses the menu column")
	assert(preview.scale * 2 <= 1,
		"Retina save preview enlarges physical pixels")
	assert(math.abs(preview.width / preview.height - 3024 / 1898) < 0.001,
		"Retina save preview changed aspect ratio")

	local legacy_preview = assert(save_preview_layout(
		640,
		480,
		700,
		0,
		580,
		720,
		2
	), "legacy save preview layout is missing")
	assert(legacy_preview.scale == 0.5,
		"legacy save preview is being upscaled on Retina")

	local original_language = LANGUAGE
	for _, language in ipairs({"en", "ru"}) do
		language_set(language, false)
		local expected_smash_tag = language == "ru" and "#дробление" or "#smash"
		assert(craft_tool_tag("smash") == expected_smash_tag,
			language .. " crafting tool tag is invalid")
		local expected_diet_tags = language == "ru"
			and " {#d87644ff}(#экзотика, #заморозка, #сахар)"
			or " {#d87644ff}(#exotic, #freezable, #sugar)"
		assert(diet_tags_text({ "exotic", "freezable", "sugar" }) == expected_diet_tags,
			language .. " dietary tags are not localized")
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

		local card_text = "{#c0cbdcff}" .. msg.stone[2].name
			.. "\n{#fee761ff}O]{#ffffffff} " .. msg.gui[24]
		local card_border, card_width = ground_card_border(
			"┌────────────────────────────────┐\n",
			card_text,
			3
		)
		local card_rows = 0
		for row in card_border:gmatch("([^\n]+)") do
			card_rows = card_rows + 1
			assert(utf8.len(row) == card_width, (
				"%s ground card row %d is %d cells instead of %d"
			):format(language, card_rows, utf8.len(row), card_width))
		end
		assert(card_rows == 5, language .. " ground card row count is invalid")
		assert(
			utf8.len(msg.stone[2].name) <= card_width - 9,
			language .. " ground card title crosses its right border"
		)

		local action_key, action_hint = ground_card_action_hint(true, true)
		assert(action_key == "Space" and action_hint == msg.gui[14],
			language .. " carried block incorrectly inherits the ground action")
		action_key, action_hint = ground_card_action_hint(false, true)
		assert(action_key == "V" and action_hint == msg.gui[27],
			language .. " usable ground block action is missing")
		action_key, action_hint = ground_card_action_hint(false, false)
		assert(action_key == nil and action_hint == nil,
			language .. " ground card shows an unavailable action")
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

		if mode == "persistence" then
			local ok, err = pcall(validate_persistence)
			if not ok then
				finish(1, "mode=persistence " .. tostring(err))
			end
			return
		end

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

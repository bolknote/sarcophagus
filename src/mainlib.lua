-- SCREEN
--------------------------------------------------

-- love.graphics.olddraw = love.graphics.draw

-- function love.graphics.draw (...)

-- 	local ar = ...
-- 	table.insert(ar, 1, texture)
-- 	love.graphics.olddraw (ar)

-- end

function gameplay_save_on_quit_allowed()
	return not GAME_CRASHED
		and os.getenv("SARCOPHAGUS_SMOKE_TEST") == nil
		and type(world) == "table"
		and next(world) ~= nil
		and type(game) == "table"
		and type(pl) == "table"
		and game.savepos ~= nil
		and game.mapgenning == nil
		and not game.network_client
		and love.update ~= love.menu_update
		and not pl.isdead
end

function multiplayer_guest_spawn()
	local start_x = tonumber(pl.startx) or math.floor(cf.wmax / 2)
	local start_y = tonumber(pl.starty) or math.floor(cf.wmax / 2)
	local true_x = start_x * cf.w + 16
	local true_y = start_y * cf.h + 32 * 4 + 6
	local zero_based_x = math.floor(true_x / cf.w)
	local zero_based_y = math.floor(true_y / cf.h)
	local tile_x = zero_based_x + 1
	local tile_y = zero_based_y + 1
	return {
		x = (zero_based_x - vi.xtile) * cf.w - vi.xoffset + (true_x % cf.w),
		y = (zero_based_y - vi.ytile) * cf.h - vi.yoffset + (true_y % cf.h),
		truex = true_x,
		truey = true_y,
		tx = tile_x,
		ty = tile_y,
		xt = tile_x,
		yt = tile_y,
	}
end

function multiplayer_snapshot_state(session)
	return {
		world = world,
		game = game,
		host_actor = actors.host,
		guest_actor = assert(session and session.guest, "guest actor is missing"),
		tips = tips,
		disp = disp,
		mobs = mobs,
		tick = game.network_tick or 0,
		world_id = NetworkIdentity.ensure_world(game),
		session_id = session.session_id,
	}
end

function multiplayer_drop_guest(actor)
	return GuestPossessions.drop(actor, {
		world = world,
		fallback_x = pl.startx,
		fallback_y = pl.starty,
		add_item = function(x, y, instance)
			return inv_ground_add(x, y, instance) ~= nil
		end,
		place_block = function(x, y, block)
			if not world[y] or not world[y][x] then return false end
			local existing = world[y][x].b
			if existing and existing ~= 0 then return false end
			local merged = GuestPossessions.merge_block_cell(world[y][x], block)
			return writemap(x, y, merged, "all") == true
		end,
	})
end

local network_outgoing_events = {}
local network_sound_event_ticks = {}
local network_event_id = 0
local network_client_event_id = 0
local network_client_event_received_id = 0
local NETWORK_EVENT_QUEUE_LIMIT = 256
local network_pending_world_deltas = {}
local network_pending_presentation_events = {}

local function network_finite_number(value)
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function network_nonnegative_integer(value)
	return network_finite_number(value) and value >= 0
		and value == math.floor(value)
end

local function network_validate_serializable(value, budget, depth, seen)
	local kind = type(value)
	if kind == "nil" or kind == "boolean" then return true end
	if kind == "number" then return network_finite_number(value) end
	if kind == "string" then return #value <= 64 * 1024 and not value:find("%z") end
	if kind ~= "table" or depth >= 32 or seen[value] then return false end
	seen[value] = true
	for key, nested in pairs(value) do
		budget.remaining = budget.remaining - 1
		if budget.remaining < 0 then seen[value] = nil; return false end
		local key_kind = type(key)
		if (key_kind ~= "string" and key_kind ~= "number" and key_kind ~= "boolean")
			or (key_kind == "string" and (#key > 512 or key:find("%z")))
			or (key_kind == "number" and not network_finite_number(key))
			or not network_validate_serializable(nested, budget, depth + 1, seen) then
			seen[value] = nil
			return false
		end
	end
	seen[value] = nil
	return true
end

local function network_valid_actor_snapshot(actor, expected_id, expected_role)
	if type(actor) ~= "table" or actor.actor_id ~= expected_id
		or actor.actor_role ~= expected_role
		or not network_finite_number(actor.truex)
		or not network_finite_number(actor.truey)
		or type(actor.inv) ~= "table" or type(actor.stats) ~= "table" then
		return false
	end
	local tile_size = math.max(1, tonumber(cf and cf.w) or 32,
		tonumber(cf and cf.h) or 32)
	local limit = math.max(1, tonumber(cf and cf.wmax) or 1) * tile_size * 4
	return math.abs(actor.truex) <= limit and math.abs(actor.truey) <= limit
end

function multiplayer_reset_network_events(reset_sequence)
	network_outgoing_events = {}
	network_sound_event_ticks = {}
	if reset_sequence then
		network_event_id = 0
		network_client_event_id = 0
		network_client_event_received_id = 0
		network_pending_world_deltas = {}
		network_pending_presentation_events = {}
	end
	return true
end

function multiplayer_queue_sound_event(name, sound_id, options, actor_id)
	if not multiplayer or multiplayer.role ~= "host" or not multiplayer.session
		or multiplayer.session.state ~= MultiplayerSession.STATE.PLAYING then
		return false
	end
	if NETWORK_SOUND_EVENT_APPLY then return false end
	if type(name) ~= "string" or #name < 1 or #name > 96
		or type(sound_id) ~= "number" or sound_id < 1 or sound_id > 255
		or sound_id ~= math.floor(sound_id) then
		return false
	end
	options = type(options) == "table" and options or {}
	actor_id = actor_id or ACTIVE_ACTOR_ID
	if actor_id ~= nil and actor_id ~= "host" and actor_id ~= "guest" then
		actor_id = nil
	end

	local actor = actor_id and actors and actors:get(actor_id) or nil
	local x = network_finite_number(options.x) and options.x or nil
	local y = network_finite_number(options.y) and options.y or nil
	if actor and (x == nil or y == nil) then
		x = tonumber(actor.xt or actor.tx)
		y = tonumber(actor.yt or actor.ty)
	end
	if not network_finite_number(x) or not network_finite_number(y) then
		x, y = nil, nil
	end

	local tick = math.max(0, math.floor(tonumber(game and game.network_tick) or 0))
	local event_key = table.concat({ actor_id or "world", name, tostring(sound_id) }, ":")
	if network_sound_event_ticks[event_key] == tick then return true, "coalesced" end
	network_sound_event_ticks[event_key] = tick

	network_event_id = network_event_id + 1
	local event = {
		kind = "sound",
		event_id = network_event_id,
		tick = tick,
		sample_time = tonumber(game and game.network_clock)
			or (tick / 30),
		name = name,
		sound_id = sound_id,
		actor_id = actor_id,
		x = x,
		y = y,
		volume = network_finite_number(options.volume) and options.volume or nil,
		duration = network_finite_number(options.dur) and options.dur or nil,
		play = options.play and true or false,
		kill = options.kill and true or false,
	}
	if #network_outgoing_events >= NETWORK_EVENT_QUEUE_LIMIT then
		table.remove(network_outgoing_events, 1)
	end
	network_outgoing_events[#network_outgoing_events + 1] = event
	return true, event.event_id
end

function multiplayer_queue_text_event(text, temporary, actor_id)
	if not multiplayer or multiplayer.role ~= "host" or not multiplayer.session
		or multiplayer.session.state ~= MultiplayerSession.STATE.PLAYING then
		return false
	end
	if NETWORK_TEXT_EVENT_APPLY then return false end
	if type(text) ~= "string" or #text > 16 * 1024
		or text:find("%z") then
		return false
	end
	actor_id = actor_id or ACTIVE_ACTOR_ID
	if actor_id ~= "host" and actor_id ~= "guest" then return false end

	network_event_id = network_event_id + 1
	local event = {
		kind = "text",
		event_id = network_event_id,
		tick = math.max(0, math.floor(tonumber(game and game.network_tick) or 0)),
		sample_time = tonumber(game and game.network_clock)
			or (math.max(0, math.floor(tonumber(game and game.network_tick) or 0)) / 30),
		actor_id = actor_id,
		text = text,
		temporary = temporary and true or false,
	}
	if #network_outgoing_events >= NETWORK_EVENT_QUEUE_LIMIT then
		table.remove(network_outgoing_events, 1)
	end
	network_outgoing_events[#network_outgoing_events + 1] = event
	return true, event.event_id
end

function multiplayer_next_network_event()
	if #network_outgoing_events == 0 then return nil end
	return table.remove(network_outgoing_events, 1)
end

function multiplayer_apply_network_event(event)
	if type(event) ~= "table"
		or (event.kind ~= "sound" and event.kind ~= "text") then
		return false, "invalid network event"
	end
	local event_id = event.event_id
	if type(event_id) ~= "number" or event_id < 1
		or event_id ~= math.floor(event_id) then
		return false, "invalid network event id"
	end
	local seen_event_id = NETWORK_EVENT_TIMELINE_APPLY
		and network_client_event_id
		or math.max(network_client_event_id, network_client_event_received_id)
	if event_id <= seen_event_id then return true, "duplicate" end
	if event.sample_time ~= nil and (not network_finite_number(event.sample_time)
		or event.sample_time < 0) then
		return false, "invalid network event sample time"
	end

	local function buffer_for_timeline()
		if NETWORK_EVENT_TIMELINE_APPLY or not game.network_client
			or not network_interpolation_buffer then return nil end
		if not network_finite_number(event.sample_time) then
			return false, "missing network event sample time"
		end
		network_pending_presentation_events[
			#network_pending_presentation_events + 1
		] = event
		network_client_event_received_id = event_id
		return true, "buffered"
	end

	if event.kind == "text" then
		if event.actor_id ~= "host" and event.actor_id ~= "guest" then
			return false, "invalid network text actor"
		end
		if type(event.text) ~= "string" or #event.text > 16 * 1024
			or event.text:find("%z") then
			return false, "invalid network text"
		end
		if type(event.temporary) ~= "boolean" then
			return false, "invalid network text flags"
		end
		local buffered, buffer_status = buffer_for_timeline()
		if buffered ~= nil then return buffered, buffer_status end

		local local_actor = actors and actors.local_actor
		if local_actor and event.actor_id == local_actor.actor_id then
			NETWORK_TEXT_EVENT_APPLY = true
			local called, apply_error = pcall(
				textwall,
				event.text,
				event.temporary
			)
			NETWORK_TEXT_EVENT_APPLY = nil
			network_client_event_id = event_id
			if not called then
				NETWORK_TEXT_ERROR = tostring(apply_error)
				if oldprint then
					oldprint("Could not present network text: " .. NETWORK_TEXT_ERROR)
				end
				return true, "text_unavailable"
			end
		else
			network_client_event_id = event_id
		end
		return true
	end

	if type(event.name) ~= "string" or #event.name < 1 or #event.name > 96
		or event.name:find("[%z\1-\31\127]") then
		return false, "invalid network sound name"
	end
	local sound_id = event.sound_id
	if type(sound_id) ~= "number" or sound_id < 1 or sound_id > 255
		or sound_id ~= math.floor(sound_id) or not sounds or not sounds[sound_id] then
		return false, "invalid network sound id"
	end
	if event.actor_id ~= nil and event.actor_id ~= "host" and event.actor_id ~= "guest" then
		return false, "invalid network sound actor"
	end
	local x, y = event.x, event.y
	if (x == nil) ~= (y == nil) then return false, "invalid network sound position" end
	if x ~= nil then
		local limit = math.max(1, tonumber(cf and cf.wmax) or 1) * 2
		if not network_finite_number(x) or not network_finite_number(y)
			or math.abs(x) > limit or math.abs(y) > limit then
			return false, "invalid network sound position"
		end
	end
	if event.volume ~= nil and (not network_finite_number(event.volume)
		or event.volume < 0 or event.volume > 2) then
		return false, "invalid network sound volume"
	end
	if event.duration ~= nil and (not network_finite_number(event.duration)
		or event.duration < 0 or event.duration > 120) then
		return false, "invalid network sound duration"
	end
	if type(event.play) ~= "boolean" or type(event.kill) ~= "boolean" then
		return false, "invalid network sound flags"
	end
	local buffered, buffer_status = buffer_for_timeline()
	if buffered ~= nil then return buffered, buffer_status end

	local options = {
		x = x,
		y = y,
		volume = event.volume,
		dur = event.duration,
		play = event.play,
		kill = event.kill,
	}
	local local_actor = actors and actors.local_actor
	if event.actor_id and local_actor and event.actor_id == local_actor.actor_id then
		options.x, options.y = nil, nil
		options.force_relative = true
	elseif x ~= nil then
		options.force_spatial = true
	end
	local event_name = "net:" .. (event.actor_id or "world") .. ":" .. event.name
	NETWORK_SOUND_EVENT_APPLY = true
	local called, apply_error = pcall(sound_add, event_name, sound_id, options)
	NETWORK_SOUND_EVENT_APPLY = nil
	network_client_event_id = event_id
	if not called then
		NETWORK_SOUND_ERROR = tostring(apply_error)
		if oldprint then
			oldprint("Could not present network sound: " .. NETWORK_SOUND_ERROR)
		end
		return true, "audio_unavailable"
	end
	return true
end

function multiplayer_flush_network_events(render_time)
	render_time = tonumber(render_time)
	if not network_finite_number(render_time) then return false end
	local applied = 0
	while network_pending_presentation_events[1]
		and network_pending_presentation_events[1].sample_time <= render_time do
		local event = table.remove(network_pending_presentation_events, 1)
		NETWORK_EVENT_TIMELINE_APPLY = true
		local ok, apply_error = multiplayer_apply_network_event(event)
		NETWORK_EVENT_TIMELINE_APPLY = nil
		if not ok then
			if multiplayer then multiplayer.last_error = apply_error end
			return false, apply_error
		end
		applied = applied + 1
	end
	return true, applied
end

local replicated_action_keys = {
	["["] = true, ["]"] = true, ["-"] = true, ["="] = true,
	["0"] = true, ["1"] = true, ["2"] = true, ["3"] = true,
	["4"] = true, ["5"] = true, ["6"] = true, ["7"] = true,
	["8"] = true, ["9"] = true,
	q = true, z = true, tab = true, p = true, r = true, v = true,
	c = true, m = true, u = true, ["return"] = true,
	w = true, s = true, escape = true,
}

local inventory_action_keys = {
	z = true, p = true, r = true, u = true, ["return"] = true,
}

function multiplayer_record_cell(x, y)
	if not multiplayer or multiplayer.role ~= "host" or not network_world_journal then
		return false
	end
	local recorded, record_error = network_world_journal:record(x, y)
	if not recorded and record_error and multiplayer then
		multiplayer.last_error = record_error
	end
	return recorded
end

function multiplayer_session_active()
	return multiplayer and multiplayer.role == "host" and multiplayer.session
		and multiplayer.session.guest ~= nil
		and multiplayer.session.state ~= MultiplayerSession.STATE.SHUTDOWN
end

function multiplayer_merge_time(base, host_time, guest_delta)
	base = tonumber(base) or 0
	local host_delta = math.max(0, (tonumber(host_time) or base) - base)
	guest_delta = math.max(0, tonumber(guest_delta) or 0)
	return base + math.max(host_delta, guest_delta)
end

function multiplayer_finalize_shared_time()
	if not multiplayer_session_active() then
		game.network_time_base = nil
		game.network_guest_time_delta = nil
		return
	end
	if game.network_time_base ~= nil then
		game.time = multiplayer_merge_time(
			game.network_time_base,
			game.time,
			game.network_guest_time_delta
		)
	end
	game.network_time_base = tonumber(game.time) or 0
	game.network_guest_time_delta = 0
end

local function multiplayer_guest_personal_progress(actor)
	if (actor.unrest or 0) > 0 then
		local recovery = math.min(actor.unrest, 100)
		actor.unrest = math.max(0, actor.unrest - recovery)
		stat_spend("water", recovery * 0.001)
		stat_spend("food", recovery * cf.rec.food)
		stat_spend("arms", recovery * 0.003)
		stat_spend("filth", recovery * 0.0005)
		stat_recovery("heat", recovery * 0.000277)
		stat_recovery("power", recovery * cf.rec.power)
		actor.state = "idle"
		return true
	end
	if (actor.rest or 0) > 0 then
		if actor.stats.food.hp < 10 then actor.rest = 0 end
		if actor.rest > 0 then
			local quality = (actor.restquality or 1) + (actor.restqualityb or 0)
			local recovery = math.min(actor.rest, actor.restquality == 0 and 640 or 64)
			actor.rest = math.max(0, actor.rest - recovery)
			stat_recovery("arms", recovery * 0.03 * quality)
			stat_recovery("body", recovery * 0.002 * quality)
			stat_recovery("power", recovery * cf.rec.power)
			if actor.restquality ~= 0 or actor.stats.food.hp > 15 then
				stat_spend("food", recovery * cf.rec.food)
			end
			if actor.restquality ~= 0 or actor.stats.water.hp > 15 then
				stat_spend("water", recovery * 0.002)
			end
			actor.state = "zzz"
			actor.flip = 1
		end
		return true
	end
	return false
end

local function multiplayer_guest_environment_tick(actor)
	local moved = actor.xo ~= actor.x or actor.yo ~= actor.y
	if moved then
		buff_tick()
		actor.xo, actor.yo = actor.x, actor.y
		local position = px2tile(actor.x, actor.y)
		actor.xt, actor.yt = position.x, position.y
		local tile, map = maptile(actor.xt, actor.yt, "all")

		if map.w and map.w > 200 then
			actor.candrink = message(msg.gui[21], { [1] = math.ceil(map.dr or 0) })
			local dirt = actor.stats.filth.maxhp - actor.stats.filth.hp
			if dirt > 5 then
				local water_dirt = readmap(actor.xt, actor.yt, "dr") or 0
				if water_dirt < 100 then
					stat_recovery("filth", 10)
					water_dirt = water_dirt + 6 * (1000 / map.w)
					writemap(actor.xt, actor.yt, water_dirt, "dr")
				end
			end
		else
			actor.candrink = nil
		end

		if tile.onstay then tile.onstay(actor.xt, actor.yt) end
		actor.canuse = tile.onuse and true or nil

		local fire = readmap(actor.xt, actor.yt, "de") or 0
		local fire_above = readmap(actor.xt, actor.yt - 1, "de") or 0
		if fire > cf.deadfire or fire_above > cf.deadfire then
			player_hit(cf.firehit)
			textwall(msg.game[8], true)
		end

		if actor.xto ~= actor.xt or actor.yto ~= actor.yt then
			achi_trigger("tick")
			if maptile(actor.xt - 1, actor.yt) == 1
				or maptile(actor.xt + 1, actor.yt) == 1
				or actor.state ~= "walk" then
				haswater = nil
			else
				haswater = love.math.random(0, 100) < 50 and true or nil
			end

			local water_feet = readmap(actor.tx, actor.ty, "w") or 0
			local water_head = readmap(actor.tx, actor.ty - 1, "w") or 0
			if water_feet > 9000 and water_head > 0 then
				buff_add(18, "refresh")
			else
				buff_remove(18)
			end
			if water_feet > 9000 and water_head > 7000 then
				buff_add(19, "refresh")
			else
				buff_remove(19)
			end

			if readmap(actor.tx, actor.ty, "fish")
				or readmap(actor.tx, actor.ty - 1, "fish") then
				writemap(actor.tx, actor.yt, nil, "fish")
				writemap(actor.tx, actor.yt - 1, nil, "fish")
				textwall(msg.game[34])
				sound_add("click", 40)
			end

			local visited = actor.xt .. "_" .. actor.yt
			actor.visited[visited] = (actor.visited[visited] or 0) + 1
			local ground = readmap(actor.xt, actor.yt, "i")
			for _, instance in ipairs(ground or {}) do item_unlock(instance.i) end
			if tile.onstep then
				tile.onstep(actor.xt, actor.yt, actor.xto, actor.yto)
			end
			local below = maptile(actor.xt, actor.yt + 1, "all")
			if below.onstepon then
				below.onstepon(actor.xt, actor.yt + 1, actor.xto, actor.yto + 1)
			end
			if below.cold then
				stat_spend("heat", below.cold * 0.5)
				if actor.stats.heat.hp < 1 then buff_add(5, "keep") end
			end
			actor.xto, actor.yto = actor.xt, actor.yt
		end

		if (actor.state ~= "walk" and actor.state ~= "idle") or game.showroom then
			haswater = nil
		end
	end

	local nearby_fire = readmap(actor.xt, actor.yt, "de") or 0
	if nearby_fire > 0 and nearby_fire < 100 then
		local recovery = nearby_fire * dt * 0.3
		stat_recovery("heat", recovery)
		stat_recovery("arms", dt)
	end

	actor.network_recovery_time = tonumber(actor.network_recovery_time) or game.time
	if actor.rest <= 0 and actor.unrest <= 0 and actor.spenddead <= 0
		and game.time > actor.network_recovery_time + 32 then
		local recovery = game.time - actor.network_recovery_time
		actor.network_recovery_time = game.time
		actor.restquality = 1
		stat_spend("food", recovery * cf.rec.food)
		stat_spend("water", recovery * 0.004)
		if not actor.iscarry then stat_recovery("arms", recovery * 0.03) end
		stat_recovery("power", recovery * cf.rec.power)
		stat_spend("filth", recovery * 0.001)
		if actor.stats.food.hp < 1 or actor.stats.water.hp < 1 then
			stat_spend("body", recovery * 0.01)
		end
	end

	if actor.state == "idle" and actor.unrest <= 0 and actor.rest <= 0
		and actor.lastshit + time.d < game.time
		and inv_ground_count(actor.xt, actor.yt) == 0 then
		sound_add("shit", 45)
		actor.lastshit = game.time
		inv_ground_add(actor.xt, actor.yt, item_make(20))
		textwall(msg.game[25])
		for item_id in pairs(actor.shit or {}) do
			inv_ground_add(actor.xt, actor.yt, item_make(item_id))
		end
		actor.shit = {}
	end

		fishing_update()
	if moved then inv_tick_ttl() end
end

function multiplayer_respawn_guest(actor)
	local dropped, drop_error = multiplayer_drop_guest(actor)
	if not dropped then return false, drop_error end
	for name, stat in pairs(actor.stats or {}) do
		if type(stat) == "table" then
			local maximum = tonumber(stat.maxhp) or 100
			stat.hp = name == "faith" and 0 or maximum
			stat.pc = name == "faith" and 0 or (maximum > 0 and 100 or 0)
			stat.d = 0
		end
	end
	actor.buffs = {}
	actor.isdead = nil
	actor.dying = nil
	actor.rest = 0
	actor.unrest = 0
	actor.spenddead = 0
	actor.digcount = 0
	actor.throw = 0
	actor.state = "idle"
	actor.oldstate = "idle"
	actor.network_deaths = (tonumber(actor.network_deaths) or 0) + 1
	local spawn = multiplayer_guest_spawn()
	for _, field in ipairs({ "x", "y", "tx", "ty", "xt", "yt", "truex", "truey" }) do
		actor[field] = spawn[field]
	end
	local runtime = actors and actors:runtime(actor)
	local camera = runtime and runtime.presentation.camera
	if camera then
		camera.xoffset, camera.yoffset = 0, 0
		camera.xtile = math.max(0, math.floor(actor.truex / cf.w) - 19)
		camera.ytile = math.max(0, math.floor(actor.truey / cf.h) - 10)
		camera.x = camera.xtile * cf.w
		camera.y = camera.ytile * cf.h
	end
	ActorState.reset_animation(actor)
	return true
end

local function multiplayer_sanitize_guest_aim(actor, input)
	if type(input) ~= "table" then return end
	input.aim = input.aim or {}
	local maximum = 1024
	local center_x = tonumber(actor.truex) or 0
	local center_y = tonumber(actor.truey) or 0
	local world_x = tonumber(input.aim.world_x) or center_x
	local world_y = tonumber(input.aim.world_y) or center_y
	world_x = math.max(center_x - maximum, math.min(center_x + maximum, world_x))
	world_y = math.max(center_y - maximum, math.min(center_y + maximum, world_y))
	input.aim.world_x, input.aim.world_y = world_x, world_y
	input.aim.tile_x = math.floor(world_x / cf.w) + 1
	input.aim.tile_y = math.floor(world_y / cf.h) + 1
end

function multiplayer_simulate_guest(actor, input, frame_dt)
	if not actor or actor.isdead then return true end
	multiplayer_sanitize_guest_aim(actor, input)
	return ActorContext.run(actors, actor, {
		input = input,
		dt = math.min(0.1, math.max(0, tonumber(frame_dt) or 0)),
		camera = vi,
	}, function()
		local projectile_ids = {}
		for id in pairs(proj or {}) do projectile_ids[id] = true end
		local time_before = tonumber(game.time) or 0
		local recovery_before = game.recovery
		local occupied = multiplayer_guest_personal_progress(actor)
		if not occupied and not game.inputing and not game.craft then
			moving()
		end
		multiplayer_guest_environment_tick(actor)
		camera_move()
		local guest_time_delta = math.max(0, (tonumber(game.time) or time_before) - time_before)
		game.network_time_base = game.network_time_base or time_before
		game.network_guest_time_delta = math.max(
			tonumber(game.network_guest_time_delta) or 0,
			guest_time_delta
		)
		game.time = time_before
		game.recovery = recovery_before
		for id, projectile in pairs(proj or {}) do
			if not projectile_ids[id] then
				projectile.owner_id = actor.actor_id
				if not projectile.truex then coord_screen2true(projectile) end
			end
		end
		if actor.stats and actor.stats.body and actor.stats.body.hp <= 0 then
			local respawned, respawn_error = multiplayer_respawn_guest(actor)
			if not respawned then error(respawn_error) end
		end
		PlayerAnimation.update(actor, dt, gr)
	end)
end

function multiplayer_mob_target(mob)
	local host = actors and actors.host or pl
	local guest = actors and actors.guest
	if not guest or guest.isdead or not guest.truex or not guest.truey then return host end
	if not host or not host.truex or not host.truey then return guest end
	local mob_x = tonumber(mob and mob.truex)
	local mob_y = tonumber(mob and mob.truey)
	if not mob_x or not mob_y then return host end
	local host_dx, host_dy = host.truex - mob_x, host.truey - mob_y
	local guest_dx, guest_dy = guest.truex - mob_x, guest.truey - mob_y
	if guest_dx * guest_dx + guest_dy * guest_dy
		< host_dx * host_dx + host_dy * host_dy then
		return guest
	end
	return host
end

function multiplayer_run_mob_ai(mob, id)
	local target = multiplayer_mob_target(mob)
	if not target or target == pl then
		return creature[mob.id].ai(mob, id)
	end
	local projectile_ids = {}
	for projectile_id in pairs(proj or {}) do projectile_ids[projectile_id] = true end
	local result = ActorContext.run(actors, target, {
		input = actors:runtime(target).input,
		dt = dt,
		camera = vi,
	}, function()
		coord_true2screen(mob)
		col_add("player", target, target.state, "player", "player")
		local value = creature[mob.id].ai(mob, id)
		if mobs[id] then coord_screen2true(mob) end
		for projectile_id, projectile in pairs(proj or {}) do
			if not projectile_ids[projectile_id] then
				projectile.owner_id = "mob:" .. tostring(id)
				if not projectile.truex then coord_screen2true(projectile) end
			end
		end
		return value
	end)
	if mobs[id] then coord_true2screen(mob) end
	if actors.host then
		col_add("player", actors.host, actors.host.state, "player", "player")
	end
	return result
end

local function collider_overlaps(left, right)
	return left and right and not (
		left.w < right.x or left.x > right.w
		or left.h < right.y or left.y > right.h
	)
end

function multiplayer_projectile_player_collision(projectile_collider, projectile)
	if not actors or not actors.guest then return nil end
	local owner_id = projectile and projectile.owner_id
	if owner_id == (actors.host and actors.host.actor_id)
		or owner_id == (actors.guest and actors.guest.actor_id) then
		-- Player-owned projectiles never damage either player in the first
		-- multiplayer version.
		return nil
	end
	local best_collider, best_actor, best_distance
	local center_x = (projectile_collider.x + projectile_collider.w) / 2
	local center_y = (projectile_collider.y + projectile_collider.h) / 2
	for _, actor in ipairs({ actors.host, actors.guest }) do
		if actor and not actor.isdead and actor.truex and actor.truey then
			local candidate = col_add("", actor, actor.state, "player", "player")
			if collider_overlaps(projectile_collider, candidate) then
				local dx, dy = actor.truex - center_x, actor.truey - center_y
				local distance = dx * dx + dy * dy
				if not best_distance or distance < best_distance then
					best_collider, best_actor, best_distance = candidate, actor, distance
				end
			end
		end
	end
	return best_collider, best_actor
end

function multiplayer_apply_projectile_player_hit(actor, callback)
	if not actor or actor == pl then return callback() end
	local runtime = actors:runtime(actor)
	return ActorContext.run(actors, actor, {
		input = runtime and runtime.input,
		dt = dt,
		camera = vi,
	}, callback)
end

function multiplayer_guest_action(actor, payload)
	if type(payload) ~= "table" then
		return false, "unsupported guest action"
	end
	if actor.isdead then return false, "guest actor is dead" end
	local runtime = actors:runtime(actor)
	if not runtime then return false, "guest runtime is missing" end
	if payload.modifiers ~= nil and type(payload.modifiers) ~= "table" then
		return false, "invalid action modifiers"
	end
	for modifier, value in pairs(payload.modifiers or {}) do
		if (modifier ~= "shift" and modifier ~= "space")
			or type(value) ~= "boolean" then
			return false, "invalid action modifier"
		end
	end

	-- Re-publish the authoritative cell even when validation rejects a locally
	-- predicted action. That rolls back a stale client-side pickup/drop.
	multiplayer_record_cell(actor.xt, actor.yt)

	if payload.action == "pickup" then
		if not ItemIdentity.counter(payload.item_uid) then
			return false, "pickup item uid is missing"
		end
		local ground = world[actor.yt] and world[actor.yt][actor.xt]
		ground = ground and ground.i
		local index, expected
		for candidate, instance in ipairs(ground or {}) do
			if instance.uid == payload.item_uid then
				index, expected = candidate, instance
				break
			end
		end
		if not index then return false, "pickup item is stale" end
		return ActorContext.run(actors, actor, {
			input = runtime.input,
			dt = 0,
			camera = vi,
			remote_action = true,
		}, function()
			return inventory_pick_ground_item(index, expected)
		end)
	end
	if payload.action == "select" then
		local slot = payload.slot
		local valid_slot = type(slot) == "number"
			and slot >= 1 and slot <= actor.invsize and slot == math.floor(slot)
		if type(slot) == "string" then
			valid_slot = false
			for _, equipment_slot in ipairs(cf.eq or {}) do
				if slot == equipment_slot then valid_slot = true; break end
			end
		end
		local instance = valid_slot and actor.inv and actor.inv[slot]
		if not instance or payload.item_uid ~= instance.uid then
			return false, "inventory selection is stale"
		end
		return ActorContext.run(actors, actor, {
			input = runtime.input,
			dt = 0,
			camera = vi,
			remote_action = true,
		}, function()
			actor.invselect = slot
			inv_show()
			craft_ini()
			return true
		end)
	end

	if payload.action ~= "key" then return false, "unsupported guest action" end
	local key = gameplay_key_from_event(payload.key, payload.scancode)
	if type(key) ~= "string" or not replicated_action_keys[key] then
		return false, "guest key is not allowed"
	end
	local remote_ui = runtime and runtime.presentation.local_ui or {}
	if key == "escape" and not (remote_ui.game and remote_ui.game.craft) then
		return false, "guest escape action is not allowed"
	end
	if (key == "w" or key == "s")
		and not (remote_ui.game and remote_ui.game.craft) then
		return true
	end
	if key == "return" and not (remote_ui.game and remote_ui.game.craft) then
		-- Return also consumes food; it remains a valid gameplay action.
	end

	local selected = actor.inv and actor.inv[actor.invselect]
	if inventory_action_keys[key] and not (key == "return"
		and remote_ui.game and remote_ui.game.craft) then
		local actual_uid = selected and selected.uid or nil
		if payload.selected_item_uid ~= actual_uid then
			return false, "selected item is stale"
		end
	end
	if key == "q" and not actor.iscarry then
		local ground = world[actor.yt] and world[actor.yt][actor.xt]
		local first_uid = ground and ground.i and ground.i[1]
		first_uid = first_uid and first_uid.uid or nil
		if payload.ground_item_uid ~= first_uid then
			return false, "ground item is stale"
		end
	end
	if key == "tab" then
		local ground = world[actor.yt] and world[actor.yt][actor.xt]
		local first_uid = ground and ground.i and ground.i[1]
		first_uid = first_uid and first_uid.uid or nil
		if first_uid == nil or payload.ground_item_uid ~= first_uid then
			return false, "ground order is stale"
		end
	end
	local numeric_key = tonumber(key)
	if numeric_key and payload.modifiers and payload.modifiers.shift then
		local ground = world[actor.yt] and world[actor.yt][actor.xt]
		local instance = ground and ground.i and ground.i[numeric_key]
		if payload.ground_item_uid ~= (instance and instance.uid or nil) then
			return false, "ground item is stale"
		end
	end

	local held = runtime.input.held or {}
	local previous_shift = held.lshift
	local previous_space = held.space
	if type(payload.modifiers) == "table" then
		held.lshift = payload.modifiers.shift and true or nil
		held.space = payload.modifiers.space and true or nil
	end
	return ActorContext.run(actors, actor, {
		input = runtime and runtime.input,
		dt = 0,
		camera = vi,
		remote_action = true,
	}, function()
		local time_before = tonumber(game.time) or 0
		local recovery_before = game.recovery
		local called, action_error = pcall(
			love.old_keypressed,
			payload.key or key,
			payload.scancode or key
		)
		held.lshift = previous_shift
		held.space = previous_space
		local guest_time_delta = math.max(
			0,
			(tonumber(game.time) or time_before) - time_before
		)
		game.network_time_base = game.network_time_base or time_before
		game.network_guest_time_delta = math.max(
			tonumber(game.network_guest_time_delta) or 0,
			guest_time_delta
		)
		game.time = time_before
		game.recovery = recovery_before
		if not called then error(action_error, 0) end
		return true
	end)
end

function multiplayer_reject_guest_action(actor)
	if not actor then return false end
	return multiplayer_record_cell(actor.xt, actor.yt)
end

function multiplayer_replication_state(session, include_progress)
	local guest_runtime = session and session.guest
		and actors:runtime(session.guest) or nil
	local state = {
		actor_schema = 2,
		tick = game.network_tick or 0,
		sample_time = game.network_clock
			or ((tonumber(game.network_tick) or 0) / 30),
		time = game.time or 0,
		host_actor = NetworkReplication.capture_actor(
			actors.host,
			NetworkReplication.ACTOR_DYNAMIC_FIELDS
		),
		guest_actor = NetworkReplication.capture_actor(
			session and session.guest,
			NetworkReplication.ACTOR_DYNAMIC_FIELDS
		),
		mobs = NetworkReplication.copy_serializable(mobs or {}),
		projectiles = NetworkReplication.copy_serializable(proj or {}),
		world_animation = NetworkReplication.copy_serializable(worldani or {}),
		guest_fishing = NetworkReplication.copy_serializable(
			guest_runtime and guest_runtime.local_globals
				and guest_runtime.local_globals.fishing
		),
		tips = NetworkReplication.copy_serializable(tips or {}),
		disp = NetworkReplication.copy_serializable(disp or {}),
		shared_game = NetworkReplication.copy_serializable({
			time = game.time,
			state = game.state == nil and false or game.state,
			start = game.start == nil and false or game.start,
			disaster = game.disaster == nil and false or game.disaster,
			ambient = game.ambient == nil and false or game.ambient,
			ambient_sound = game.ambient_sound == nil and false or game.ambient_sound,
		}),
	}
	if include_progress then
		state.shared_progress = NetworkReplication.capture_actor(
			actors.host,
			NetworkReplication.SHARED_PROGRESS_FIELDS
		)
		state.host_progress = NetworkReplication.capture_actor(
			actors.host,
			NetworkReplication.ACTOR_PROGRESS_FIELDS
		)
		state.guest_progress = NetworkReplication.capture_actor(
			session and session.guest,
			NetworkReplication.ACTOR_PROGRESS_FIELDS
		)
	end
	return state
end

local function replace_table(target, source)
	if type(target) ~= "table" then return source or {} end
	for key in pairs(target) do target[key] = nil end
	for key, value in pairs(source or {}) do target[key] = value end
	return target
end

function multiplayer_replace_entities(target, source, options)
	options = options or {}
	target = type(target) == "table" and target or {}
	for id in pairs(target) do
		if type(source) ~= "table" or source[id] == nil then
			if options.defer_removals and type(target[id]) == "table" then
				target[id].network_removed_at = target[id].network_removed_at
					or options.removal_time
			else
				target[id] = nil
			end
		end
	end
	for id, snapshot in pairs(source or {}) do
		if type(snapshot) ~= "table" then
			target[id] = snapshot
		else
			local existed = type(target[id]) == "table"
			local entity = existed and target[id] or {}
			local current_x, current_y = entity.truex, entity.truey
			local spawn_at = entity.network_spawn_at
			replace_table(entity, snapshot)
			if options.defer_spawns then
				if existed then
					entity.network_spawn_at = spawn_at
				else
					entity.network_spawn_at = type(options.spawn_time) == "function"
						and options.spawn_time(snapshot, id)
						or options.spawn_time
				end
			end
			if options.ignore_position and snapshot.truex and snapshot.truey then
				if current_x and current_y then
					entity.truex, entity.truey = current_x, current_y
				elseif type(options.spawn_origin) == "function" then
					local origin_x, origin_y = options.spawn_origin(snapshot, id)
					if network_finite_number(origin_x)
						and network_finite_number(origin_y) then
						entity.truex, entity.truey = origin_x, origin_y
					end
				end
				entity.network_target_truex = nil
				entity.network_target_truey = nil
			elseif current_x and current_y and snapshot.truex and snapshot.truey then
				entity.truex, entity.truey = current_x, current_y
				entity.network_target_truex = snapshot.truex
				entity.network_target_truey = snapshot.truey
			end
			target[id] = entity
		end
	end
	return target
end

local function multiplayer_position_collection(source)
	local result = {}
	for id, entity in pairs(source or {}) do
		if type(entity) == "table"
			and network_finite_number(entity.truex)
			and network_finite_number(entity.truey) then
			result[id] = { x = entity.truex, y = entity.truey }
		end
	end
	return result
end

local function multiplayer_position_sample(state)
	return {
		actors = multiplayer_position_collection({
			host = state.host_actor,
			guest = state.guest_actor,
		}),
		mobs = multiplayer_position_collection(state.mobs),
		projectiles = multiplayer_position_collection(state.projectiles),
		world_animation = multiplayer_position_collection(state.world_animation),
	}
end

local function multiplayer_projectile_origin(snapshot)
	local owner_id = snapshot and snapshot.owner_id
	local actor = actors and actors:get(owner_id)
	if actor and network_finite_number(actor.truex)
		and network_finite_number(actor.truey) then
		return actor.truex, actor.truey
	end
	local mob_id = type(owner_id) == "string" and owner_id:match("^mob:(.+)$")
	local mob = mob_id and mobs and (mobs[tonumber(mob_id)] or mobs[mob_id])
	if mob and network_finite_number(mob.truex)
		and network_finite_number(mob.truey) then
		return mob.truex, mob.truey
	end
end

local function multiplayer_seed_new_projectiles(source)
	local seeded = {}
	if not network_interpolation_buffer then return seeded end
	local latest = network_interpolation_buffer.samples
		and network_interpolation_buffer.samples[
			#network_interpolation_buffer.samples
		]
	if not latest then return seeded end
	for id, snapshot in pairs(source or {}) do
		local known = latest.positions.projectiles
			and latest.positions.projectiles[id]
		if not known then
			local x, y = multiplayer_projectile_origin(snapshot)
			if x and y then
				if network_interpolation_buffer:seed_latest(
					"projectiles", id, x, y
				) then
					seeded[id] = latest.time
				end
			end
		end
	end
	return seeded
end

local function interpolate_world_position(entity, frame_dt, hard_distance, speed)
	if type(entity) ~= "table" or not entity.network_target_truex
		or not entity.network_target_truey then return false end
	local current_x = tonumber(entity.truex) or entity.network_target_truex
	local current_y = tonumber(entity.truey) or entity.network_target_truey
	local dx = entity.network_target_truex - current_x
	local dy = entity.network_target_truey - current_y
	local distance = math.sqrt(dx * dx + dy * dy)
	local factor = distance > hard_distance and 1
		or math.min(1, math.max(0, tonumber(frame_dt) or 0) * speed)
	entity.truex = current_x + dx * factor
	entity.truey = current_y + dy * factor
	if distance < 0.25 or factor == 1 then
		entity.truex = entity.network_target_truex
		entity.truey = entity.network_target_truey
		entity.network_target_truex = nil
		entity.network_target_truey = nil
	end
	return true
end

function multiplayer_interpolate_remote_state(frame_dt)
	if network_interpolation_buffer then
		local frame = network_interpolation_buffer:frame()
		if frame then
			game.network_render_time = frame.target
			if multiplayer_flush_world_deltas then
				multiplayer_flush_world_deltas(frame.target)
			end
			if multiplayer_flush_network_events then
				multiplayer_flush_network_events(frame.target)
			end
			local function apply(entity, group, id)
				local x, y = NetworkInterpolationBuffer.position(frame, group, id)
				if entity and x and y then
					entity.truex, entity.truey = x, y
					entity.network_target_truex = nil
					entity.network_target_truey = nil
				end
			end
			if actors then
				if actors.host ~= actors.local_actor then
					apply(actors.host, "actors", "host")
				end
				if actors.guest ~= actors.local_actor then
					apply(actors.guest, "actors", "guest")
				end
			end
			local function apply_collection(collection, group)
				for id, entity in pairs(collection or {}) do
					if entity.network_removed_at
						and frame.target >= entity.network_removed_at then
						collection[id] = nil
					else
						apply(entity, group, id)
					end
				end
			end
			apply_collection(mobs, "mobs")
			apply_collection(proj, "projectiles")
			apply_collection(worldani, "world_animation")
			local metrics = network_interpolation_buffer:metrics()
			game.network_interpolation_delay = metrics.delay
			game.network_interpolation_jitter = metrics.jitter
			return true
		end
	end
	local local_actor = actors and actors.local_actor
	for _, actor in ipairs({ actors and actors.host, actors and actors.guest }) do
		if actor and actor ~= local_actor then
			interpolate_world_position(actor, frame_dt, 256, 12)
		end
	end
	for _, collection in ipairs({ mobs or {}, proj or {}, worldani or {} }) do
		for _, entity in pairs(collection) do
			interpolate_world_position(entity, frame_dt, 192, 15)
		end
	end
end

function multiplayer_entity_visible(entity)
	if type(entity) ~= "table" or entity.network_spawn_at == nil then return true end
	return (tonumber(game and game.network_render_time) or -math.huge)
		>= entity.network_spawn_at
end

function multiplayer_project_dynamic_entities()
	for _, collection in ipairs({ mobs or {}, proj or {}, worldani or {} }) do
		for _, entity in pairs(collection) do
			if type(entity) == "table" and entity.truex and entity.truey then
				coord_true2screen(entity)
			end
		end
	end
end

local function multiplayer_actor_light(actor)
	-- The translucent white shader already makes the guest readable. A permanent ghost
	-- light added another full-screen lighting iteration for every rendered
	-- pixel, which is disproportionately expensive on older integrated GPUs.
	local power = 0
	local color = actor.ghost and { 0.42, 0.76, 1.0 } or { 1, 1, 1 }
	if actor.buffs and actor.buffs[1] and buff and buff[1] and buff[1].light then
		power = buff[1].light[1]
		color = { buff[1].light[2], buff[1].light[3], buff[1].light[4] }
	end
	if actor.iscarry and stone[actor.iscarry.b] and stone[actor.iscarry.b].light
		and stone[actor.iscarry.b].light[1] > power then
		local value = stone[actor.iscarry.b].light
		power, color = value[1], { value[2], value[3], value[4] }
	end
	for _, instance in pairs(actor.inv or {}) do
		local definition = item[instance.i]
		if definition and definition.light and definition.light[1] > power then
			power = definition.light[1]
			color = { definition.light[2], definition.light[3], definition.light[4] }
		end
	end
	return power, color
end

function multiplayer_refresh_actor_lights(include_local)
	for _, actor in ipairs({ actors and actors.host, actors and actors.guest }) do
		if actor and (include_local or actor ~= pl) then
			local power, color = multiplayer_actor_light(actor)
			if power > 0 then
				local x, y = ActorRenderer.position(actor, {
					camera = vi,
					local_actor = actors.local_actor,
					tile_width = cf.w,
					tile_height = cf.h,
				})
				lights["actor_" .. actor.actor_id] = {
					x = x, y = y, p = power, l = color,
				}
			end
		end
	end
end

function multiplayer_active_cameras()
	local result = { vi }
	if multiplayer_session_active() and actors.guest then
		local runtime = actors:runtime(actors.guest)
		local camera = runtime and runtime.presentation.camera
		if camera and camera ~= vi then result[#result + 1] = camera end
	end
	return result
end

function multiplayer_apply_replication(state)
	if type(state) ~= "table" then return false, "invalid replicated state" end
	local progress_present = state.shared_progress ~= nil
		or state.host_progress ~= nil or state.guest_progress ~= nil
	if not network_validate_serializable(state, { remaining = 500000 }, 0, {})
		or state.actor_schema ~= 2
		or not network_valid_actor_snapshot(state.host_actor, "host", "host")
		or not network_valid_actor_snapshot(state.guest_actor, "guest", "guest")
		or type(state.mobs) ~= "table" or type(state.projectiles) ~= "table"
		or type(state.world_animation) ~= "table"
		or type(state.tips) ~= "table" or type(state.disp) ~= "table"
		or type(state.shared_game) ~= "table"
		or (progress_present and (type(state.shared_progress) ~= "table"
			or type(state.host_progress) ~= "table"
			or type(state.guest_progress) ~= "table"))
		or (state.guest_fishing ~= nil and type(state.guest_fishing) ~= "table") then
		return false, "invalid replicated state shape"
	end
	local tick = state.tick
	if not network_nonnegative_integer(tick)
		or tick > 9007199254740991
		or tick < (tonumber(game.network_server_tick) or -1) then
		return false, "stale replicated state"
	end
	if not network_finite_number(state.time) or state.time < 0 then
		return false, "invalid replicated time"
	end
	if not network_finite_number(state.sample_time) or state.sample_time < 0 then
		return false, "invalid replicated sample time"
	end
	if not network_interpolation_buffer then
		network_interpolation_buffer = NetworkInterpolationBuffer.new()
	end
	local latest_sample = network_interpolation_buffer.samples
		and network_interpolation_buffer.samples[
			#network_interpolation_buffer.samples
		]
	if latest_sample and state.sample_time < latest_sample.time then
		return false, "stale interpolation sample"
	end
	local seeded_projectiles = multiplayer_seed_new_projectiles(state.projectiles)
	local pushed, push_error = network_interpolation_buffer:push(
		state.sample_time,
		multiplayer_position_sample(state)
	)
	if not pushed then return false, push_error end

	game.network_server_tick = tick
	game.network_server_time = state.sample_time
	game.network_tick = tick
	game.time = state.time
	for field, value in pairs(state.shared_game or {}) do
		if value == false then
			game[field] = nil
		else
			game[field] = NetworkReplication.copy_serializable(value)
		end
	end
	tips = replace_table(tips, state.tips)
	disp = replace_table(disp, state.disp)

	if actors.host and state.host_actor then
		NetworkReplication.apply_actor(actors.host, state.host_actor, {
			ignore_position = actors.local_actor ~= actors.host,
			preserve_animation = true,
			fields = NetworkReplication.ACTOR_DYNAMIC_FIELDS,
		})
	end
	if actors.guest and state.guest_actor then
		NetworkReplication.apply_actor(actors.guest, state.guest_actor, {
			defer_position = actors.local_actor == actors.guest,
			preserve_animation = true,
			fields = NetworkReplication.ACTOR_DYNAMIC_FIELDS,
		})
	end
	if progress_present and actors.host and actors.guest then
		local shared = {}
		for _, field in ipairs(NetworkReplication.SHARED_PROGRESS_FIELDS) do
			shared[field] = NetworkReplication.copy_serializable(
				state.shared_progress[field]
			)
			actors.host[field] = shared[field]
			actors.guest[field] = shared[field]
		end
		NetworkReplication.apply_actor(actors.host, state.host_progress, {
			fields = NetworkReplication.ACTOR_PROGRESS_FIELDS,
		})
		NetworkReplication.apply_actor(actors.guest, state.guest_progress, {
			fields = NetworkReplication.ACTOR_PROGRESS_FIELDS,
		})
	end
	if actors.guest then
		local guest_runtime = actors:runtime(actors.guest)
		if guest_runtime then
			guest_runtime.local_globals = guest_runtime.local_globals or {}
			guest_runtime.local_globals.fishing = NetworkReplication.copy_serializable(
				state.guest_fishing
			)
			if actors.local_actor == actors.guest then
				fishing = NetworkReplication.copy_serializable(state.guest_fishing)
			end
		end
	end
	mobs = multiplayer_replace_entities(mobs, state.mobs, {
		ignore_position = true,
		defer_removals = true,
		removal_time = state.sample_time,
		defer_spawns = true,
		spawn_time = state.sample_time,
	})
	proj = multiplayer_replace_entities(proj, state.projectiles, {
		ignore_position = true,
		defer_removals = true,
		removal_time = state.sample_time,
		defer_spawns = true,
		spawn_time = function(_, id)
			return seeded_projectiles[id] or state.sample_time
		end,
		spawn_origin = multiplayer_projectile_origin,
	})
	worldani = multiplayer_replace_entities(worldani, state.world_animation, {
		ignore_position = true,
		defer_removals = true,
		removal_time = state.sample_time,
		defer_spawns = true,
		spawn_time = state.sample_time,
	})
	multiplayer_project_dynamic_entities()
	return true
end

function multiplayer_world_delta()
	if not network_world_journal then return nil end
	local delta = network_world_journal:drain(world, 64, game.network_tick)
	if delta then
		delta.sample_time = game.network_clock
			or ((tonumber(game.network_tick) or 0) / 30)
	end
	return delta
end

local NETWORK_WORLD_DELTA_MAX_CELLS = 256

local function multiplayer_validate_world_delta(delta, current_sequence)
	if type(delta) ~= "table" or type(delta.cells) ~= "table" then
		return nil, "invalid world delta"
	end
	if not network_validate_serializable(delta, { remaining = 200000 }, 0, {}) then
		return nil, "invalid world delta payload"
	end
	local sequence = delta.sequence
	if not network_nonnegative_integer(sequence) or sequence ~= current_sequence + 1 then
		return nil, "stale world delta"
	end
	if not network_nonnegative_integer(delta.tick) then
		return nil, "invalid world delta tick"
	end
	if delta.sample_time ~= nil and (not network_finite_number(delta.sample_time)
		or delta.sample_time < 0) then
		return nil, "invalid world delta sample time"
	end

	local cell_count = 0
	for key in pairs(delta.cells) do
		if not network_nonnegative_integer(key) or key < 1
			or key > NETWORK_WORLD_DELTA_MAX_CELLS then
			return nil, "invalid world delta cells"
		end
		cell_count = cell_count + 1
	end
	if cell_count < 1 or cell_count > NETWORK_WORLD_DELTA_MAX_CELLS then
		return nil, "invalid world delta cells"
	end

	local validated = {}
	local coordinates = {}
	local world_limit = tonumber(cf and cf.wmax) or 0
	for index = 1, cell_count do
		local entry = delta.cells[index]
		if type(entry) ~= "table"
			or not network_nonnegative_integer(entry.x)
			or not network_nonnegative_integer(entry.y)
			or entry.x < 1 or entry.y < 1
			or entry.x > world_limit or entry.y > world_limit
			or type(entry.cell) ~= "table" then
			return nil, "invalid world cell delta"
		end
		local coordinate = entry.x .. ":" .. entry.y
		if coordinates[coordinate] then
			return nil, "duplicate world cell delta"
		end
		coordinates[coordinate] = true
		validated[index] = entry
	end

	return validated
end

local function multiplayer_apply_validated_world_delta(delta, validated)
	local sequence = delta.sequence
	local current_sequence = tonumber(game.network_world_sequence) or 0
	if sequence ~= current_sequence + 1 then return false, "stale world delta" end
	for _, entry in ipairs(validated) do
		world[entry.y] = world[entry.y] or {}
		world[entry.y][entry.x] = entry.cell
	end
	game.network_world_sequence = sequence
	return true
end

function multiplayer_apply_world_delta(delta)
	local delayed = game.network_client and network_interpolation_buffer ~= nil
	local current_sequence = delayed
		and (tonumber(game.network_world_received_sequence)
			or tonumber(game.network_world_sequence) or 0)
		or (tonumber(game.network_world_sequence) or 0)
	local validated, validation_error = multiplayer_validate_world_delta(
		delta,
		current_sequence
	)
	if not validated then return false, validation_error end

	if delayed then
		if not network_finite_number(delta.sample_time) then
			return false, "missing world delta sample time"
		end
		network_pending_world_deltas[#network_pending_world_deltas + 1] = {
			delta = delta,
			cells = validated,
		}
		game.network_world_received_sequence = delta.sequence
		return true, "buffered"
	end
	return multiplayer_apply_validated_world_delta(delta, validated)
end

function multiplayer_flush_world_deltas(render_time)
	render_time = tonumber(render_time)
	if not network_finite_number(render_time) then return false end
	local applied = 0
	while network_pending_world_deltas[1]
		and network_pending_world_deltas[1].delta.sample_time <= render_time do
		local pending = table.remove(network_pending_world_deltas, 1)
		local ok, apply_error = multiplayer_apply_validated_world_delta(
			pending.delta,
			pending.cells
		)
		if not ok then
			if multiplayer then multiplayer.last_error = apply_error end
			return false, apply_error
		end
		applied = applied + 1
	end
	return true, applied
end

function multiplayer_action_result(result)
	game.network_last_action_result = result
	if result and result.ok == false and result.error and oldprint then
		oldprint("Guest action rejected: " .. tostring(result.error))
	end
end

function multiplayer_handle_approval_key(key, scancode)
	if not multiplayer or not multiplayer:pending_approval() then return false end
	local normalized = scancode or key
	if normalized == "y" then
		local approved, approval_error = multiplayer:approve_guest()
		if approved then
			textwall(msg.network.join_approved, true)
		else
			textwall(tostring(approval_error), true)
		end
		return true
	end
	if normalized == "n" then
		multiplayer:reject_guest("rejected_by_host")
		textwall(msg.network.join_rejected, true)
		return true
	end
	return false
end

function multiplayer_handle_host_key(key, scancode)
	local normalized = scancode or key
	if normalized ~= "k" or not multiplayer_session_active() then return false end
	local kicked, kick_error = multiplayer:kick_guest("kicked_by_host")
	if kicked then
		textwall(msg.network.guest_kicked, true)
	else
		textwall(tostring(kick_error), true)
	end
	return true
end

function multiplayer_send_action(payload)
	if not multiplayer or multiplayer.role ~= "client"
		or multiplayer.client_state ~= "playing" then return false end
	payload = payload or {}
	game.network_action_id = (tonumber(game.network_action_id) or 0) + 1
	payload.action_id = game.network_action_id
	local sent, send_error = multiplayer:send_action(payload)
	if not sent then multiplayer.last_error = send_error end
	return sent
end

function multiplayer_send_key_action(key, scancode)
	local normalized = gameplay_key_from_event(key, scancode)
	if not replicated_action_keys[normalized] then return false end
	-- Escape opens the client's own reduced pause menu. It is only a gameplay
	-- action while closing an authoritative remote crafting screen.
	if normalized == "escape" and not game.craft then return false end
	local selected = pl.inv and pl.inv[pl.invselect]
	local numeric_key = tonumber(normalized)
	local shift = is_pressed("lshift") or is_pressed("rshift")
	local ground_index = (normalized == "q" or normalized == "tab") and 1
		or (numeric_key and shift and numeric_key or nil)
	local cell = world[pl.yt] and world[pl.yt][pl.xt]
	local ground_item = ground_index and cell and cell.i and cell.i[ground_index]
	return multiplayer_send_action({
		action = "key",
		key = key,
		scancode = scancode,
		selected_item_uid = selected and selected.uid or nil,
		ground_item_uid = ground_item and ground_item.uid or nil,
		modifiers = {
			shift = not not shift,
			space = not not is_pressed("space"),
		},
	})
end

function multiplayer_send_pickup_action(instance)
	if type(instance) ~= "table" or type(instance.uid) ~= "string" then
		return false
	end
	return multiplayer_send_action({
		action = "pickup",
		item_uid = instance.uid,
	})
end

function multiplayer_send_select_action(slot, instance)
	if type(instance) ~= "table" or not ItemIdentity.counter(instance.uid) then
		return false
	end
	return multiplayer_send_action({
		action = "select",
		slot = slot,
		item_uid = instance.uid,
	})
end

local network_airborne_states = {
	jump = true, jump_carry = true,
	fall = true, fall_carry = true,
	hang = true, pullup = true,
	stepup = true, stepupb = true,
	climb = true,
}

function multiplayer_reconcile_local_actor(frame_dt)
	local actor = actors and actors.local_actor
	if not actor or not actor.network_target_truex or not actor.network_target_truey then
		return false
	end
	local target_x = actor.network_target_truex
	local target_y = actor.network_target_truey
	local current_x = tonumber(actor.truex) or target_x
	local current_y = tonumber(actor.truey) or target_y
	local dx, dy = target_x - current_x, target_y - current_y
	local distance = math.sqrt(dx * dx + dy * dy)

	if distance > 96 then
		-- Teleports, respawns and serious prediction errors must converge at
		-- once. Small LAN latency errors are handled below without repeatedly
		-- dragging the player towards an already stale packet.
		actor.truex, actor.truey = target_x, target_y
	else
		if not network_airborne_states[actor.state] and math.abs(dy) <= 16 then
			-- A grounded sprite should share the authoritative floor exactly;
			-- fractional vertical reconciliation made the ghost hover between
			-- two block rows.
			actor.truey = target_y
			dy = 0
		end

		local frame = math.max(0, math.min(0.1, tonumber(frame_dt) or 0))
		local maximum_correction = math.max(0.5, frame * 90)
		local function correction(error, dead_zone)
			local magnitude = math.abs(error)
			if magnitude <= dead_zone then return 0 end
			local amount = math.min(magnitude - dead_zone, maximum_correction)
			return error < 0 and -amount or amount
		end
		actor.truex = current_x + correction(dx, 10)
		if dy ~= 0 then
			actor.truey = current_y + correction(
				dy,
				network_airborne_states[actor.state] and 8 or 4
			)
		end
	end

	-- Consume each authoritative target once. Keeping it alive until the next
	-- packet applied the same correction every render frame, slowing movement
	-- and producing visible rubber-banding on lower-frame-rate machines.
	actor.network_target_truex = nil
	actor.network_target_truey = nil
	coord_true2screen(actor)
	return true
end

local function preserve_predicted_stats(actor)
	local values = {}
	for name, stat in pairs(actor.stats or {}) do
		if type(stat) == "table" then
			values[name] = {
				hp = stat.hp,
				pc = stat.pc,
				d = stat.d,
				currentgrow = stat.currentgrow,
			}
		end
	end
	return function()
		for name, value in pairs(values) do
			local stat = actor.stats and actor.stats[name]
			if type(stat) == "table" then
				stat.hp = value.hp
				stat.pc = value.pc
				stat.d = value.d
				stat.currentgrow = value.currentgrow
			end
		end
	end
end

function multiplayer_client_update(frame_dt)
	dt = math.min(0.1, math.max(0, tonumber(frame_dt) or 0))
	mousemoved_last = (mousemoved_last or 0) + dt
	mousetruemoved_last = (mousetruemoved_last or 0) + dt
	mouse_x = love.mouse.getX()
	mouse_y = love.mouse.getY()
	if game.gr2x then mouse_x, mouse_y = mouse_x / 2, mouse_y / 2 end
	mouse_t = px2tile(mouse_x, mouse_y)

	if quit_countdown_update() then return end
	sound_update()
	if multiplayer.client_state ~= "playing" then return end
	-- Actor stats arrive authoritatively, but the critical-health shader and
	-- heartbeat are local presentation. Refresh them on the guest client rather
	-- than leaking those effects into the host while it simulates guest damage.
	actor_health_presentation_update(actors and actors.local_actor)

	local runtime = actors:runtime(actors.local_actor)
	local input = runtime and runtime.input
	local controls_enabled = not game.pause and love.window.hasFocus()
	if input then
		InputState.capture(input, function(action)
			if not controls_enabled then return false end
			if action == "mouse1" then
				return love.mouse.isDown(1) and not game.gui_mouse_down
			end
			if action == "mouse2" then
				return love.mouse.isDown(2) or game.gui_throw_down
			end
			return is_pressed(action)
		end, {
			world_x = vi.xtile * cf.w + vi.xoffset + mouse_x,
			world_y = vi.ytile * cf.h + vi.yoffset + mouse_y,
			tile_x = mouse_t.x,
			tile_y = mouse_t.y,
		})
		multiplayer:submit_input(input, dt)
	end

	multiplayer_interpolate_remote_state(dt)
	multiplayer_reconcile_local_actor(dt)
	game.moved = false
	if controls_enabled and not game.inputing and not game.craft and not pl.isdead then
		local prediction_input = InputState.new()
		for _, action in ipairs({ "w", "s", "a", "d", "space", "lshift", "rshift" }) do
			if InputState.is_down(input, action) then
				prediction_input.held[action] = true
			end
		end
		prediction_input.aim = StateCopy.copy(input and input.aim or {})
		local previous_input = ACTIVE_INPUT_STATE
		local previous_prediction = NETWORK_CLIENT_PREDICTION
		local time_before_prediction = game.time
		local restore_stats = preserve_predicted_stats(pl)
		ACTIVE_INPUT_STATE = prediction_input
		NETWORK_CLIENT_PREDICTION = true
		local predicted, prediction_error = pcall(moving)
		ACTIVE_INPUT_STATE = previous_input
		NETWORK_CLIENT_PREDICTION = previous_prediction
		game.time = time_before_prediction
		restore_stats()
		if not predicted then error(prediction_error, 0) end
	end
	-- The host owns fishing physics and fish depletion. The client receives
	-- the replicated bobber state and only projects it into its camera.
	if fishing then coord_true2screen(fishing) end
	camera_move()
	multiplayer_project_dynamic_entities()
	lights = {}
	multiplayer_refresh_actor_lights(true)
	for id, mob in pairs(mobs or {}) do
		if mob.light and multiplayer_entity_visible(mob) then
			lights["mob_" .. tostring(id)] = {
				x = mob.x, y = mob.y,
				p = mob.light[1],
				l = { mob.light[2], mob.light[3], mob.light[4] },
			}
		end
	end
	PlayerAnimation.update(pl, dt, gr)
	for _, actor in ipairs({ actors and actors.host, actors and actors.guest }) do
		if actor and actor ~= pl then
			PlayerAnimation.update(actor, dt, gr)
		end
	end
	game.dt = (tonumber(game.dt) or 0) + dt
end

local function multiplayer_validate_snapshot(snapshot)
	if type(snapshot) ~= "table" or type(snapshot.header) ~= "table"
		or type(snapshot.world) ~= "table" or type(snapshot.game) ~= "table"
		or type(snapshot.tips) ~= "table" or type(snapshot.disp) ~= "table"
		or type(snapshot.mobs) ~= "table"
		or snapshot.header.version ~= MultiplayerProtocol.SNAPSHOT_VERSION
		or not MultiplayerProtocol.validate_nonnegative_integer(
			snapshot.header.tick, 9007199254740991
		)
		or not MultiplayerProtocol.validate_identity(snapshot.header.world_id)
		or not MultiplayerProtocol.validate_identity(snapshot.header.session_id)
		or not network_valid_actor_snapshot(snapshot.host_actor, "host", "host")
		or not network_valid_actor_snapshot(snapshot.guest_actor, "guest", "guest")
		or not network_finite_number(snapshot.game.time)
		or snapshot.game.time < 0 then
		return false
	end
	if not network_validate_serializable(
		snapshot,
		{ remaining = 5000000 },
		0,
		{}
	) then
		return false
	end
	local world_size = tonumber(cf and cf.wmax) or 0
	if world_size < 1 or world_size ~= math.floor(world_size) then return false end
	for y = 1, world_size do
		local row = snapshot.world[y]
		if type(row) ~= "table" then return false end
		for x = 1, world_size do
			if type(row[x]) ~= "table" then return false end
		end
	end
	return true
end

function multiplayer_apply_snapshot(snapshot)
	assert(multiplayer_validate_snapshot(snapshot), "invalid network snapshot")
	multiplayer_reset_network_events(true)
	local local_game = game or {}
	local local_fields = {
		"fullscreen",
		"gr2x",
		"invertstereo",
		"mastervolume",
		"musicvolume",
		"soundvolume",
	}

	world = snapshot.world
	game = snapshot.game
	tips = snapshot.tips
	disp = snapshot.disp
	mobs = snapshot.mobs
	for _, field in ipairs(local_fields) do
		if local_game[field] ~= nil then game[field] = local_game[field] end
	end
	game.world_id = snapshot.header.world_id
	game.network_client = true
	game.nosave = true
	game.pause = nil
	game.menu = nil
	game.escmenu = nil
	game.craft = false
	game.achishow = nil
	game.achipage = nil
	game.inputing = nil
	game.textinput = ""
	game.textinputold = ""
	game.textinputinfo = ""
	game.network_tick = snapshot.header.tick or 0
	game.network_server_time = tonumber(game.network_clock) or 0
	game.network_render_time = game.network_server_time
	game.network_world_sequence = 0
	game.network_world_received_sequence = 0
	network_interpolation_buffer = NetworkInterpolationBuffer.new()

	local host_actor = ActorState.ensure(snapshot.host_actor, {
		actor_id = "host",
		actor_role = "host",
		force_identity = true,
	})
	local guest_actor = ActorState.ensure(snapshot.guest_actor, {
		actor_id = "guest",
		actor_role = "guest",
		force_identity = true,
	})
	actors:bind_host(host_actor)
	actors:bind_guest(guest_actor, { local_actor = true, camera = vi })
	pl = guest_actor

	if pl.truex and pl.truey then
		vi.xoffset = 0
		vi.yoffset = 0
		vi.xtile = math.floor(pl.truex / cf.w) - 19
		vi.ytile = math.floor(pl.truey / cf.h) - 10
		coord_true2screen(pl)
	end
	multiplayer_project_dynamic_entities()
	inv_show()
	game.menu_manual_ip = nil
	love.keyboard.setTextInput(false)
	love.keypressed = love.old_keypressed
	love.update = love.old_update
	love.draw = love.old_draw
	screen_full()
	screen_res()
	if spt and spt.cursor then love.mouse.setCursor(spt.cursor) end
	game.moved = true
	return true
end

function multiplayer_world_started()
	NetworkIdentity.ensure_world(game)
	actors:bind_host(pl, vi)
	if network_world_journal then network_world_journal:clear() end
	game.network_tick = game.network_tick or 0
	if os.getenv("SARCOPHAGUS_SMOKE_TEST") then return true, "smoke-test" end
	if not multiplayer or multiplayer.role == "client" then return true end
	if multiplayer.role == "host" then return true, multiplayer.transport.port end
	local started, port_or_error = multiplayer:start_host({
		game_version = game_version,
		world_id = game.world_id,
		display_name = "Sarcophagus #" .. tostring(game.savepos or 1),
	})
	if started then
		game.multiplayer_port = port_or_error
		return true, port_or_error
	end
	if oldprint then oldprint("Could not start LAN host: " .. tostring(port_or_error)) end
	return false, port_or_error
end

function love.quit ()
	if quit_after_save then
		-- The save snapshot already contains the guest's material possessions.
		-- Finish the live network session as well so a normal host exit reaches
		-- the client as an explicit shutdown instead of a reconnect timeout.
		if multiplayer and not GAME_CRASHED then multiplayer:prepare_quit() end
		if save_manager then save_manager.shutdown() end
		(oldprint or print) ('exit')
		return
	end

	-- Route a normal window close or Cmd+Q through the same checked save path
	-- as the in-game menu. Returning true cancels this immediate quit; a short
	-- countdown lets the queued save preview reach the next rendered frame.
	if gameplay_save_on_quit_allowed() and save_and_quit then
		save_and_quit()
		return true
	end

	if multiplayer and not GAME_CRASHED then multiplayer:prepare_quit() end

	if save_manager then save_manager.shutdown() end
	(oldprint or print) ('exit')
end

function testproj_kill ()
	testthrow = 0
	for k,v in pairs(proj) do
		if v.proj == 15 then
			proj[k] = nil
		end
	end
end

function grenade (x,y)

	inv_ground_add (x,y,item_make (50)) 

	for i=x-1,x+1 do
	for ii=y-1,y+1 do

		local g = maptile (i,ii,'gather')
		local b = readmap (i,ii,'b')
		if g and g~=0 and b~=0 then


			if (stone[b] and stone[b].digtoinv or 0)>0 then
				inv_ground_add (i,ii,item_make (stone[b].digtoinv)) 
				achi_add (24,1)
			end

			if stone[b] and stone[b].loot then
				inv_ground_add (i,ii,item_make (loot_make(stone[b].loot)))
				achi_add (24,1)
			end

			writemap (i,ii,0)
		end
		
	end	
	end
end

function new_worldani (name, id, add)

	worldani[name] = worldani[name] or {}

	ani_new (worldani[name], id)

	add = add or {}

	for k,v in pairs(add) do
		worldani[name][k] = v
	end

	return worldani[name]
end



function tablecheck(orig)

    local orig_type = type(orig)
    local copy

   -- print (orig_type)

    
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do

        	--print (type(orig_value))

        if type(orig_value) == 'cdata' then
        	print (orig_key)
        	dump (orig)
	    	orig_value = 1000
	   	 end


            copy[tablecheck(orig_key)] = tablecheck(orig_value)
        end
        setmetatable(copy, tablecheck(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
	end
    return copy
end


function love.resize(w, h)
	screen_res ()
end

function img_load (name)
	
	--return love.graphics.newImage ("assets/sprites/"..name)

	if quadlist[name] then
	 	local q = quadlist[name]
	 	return love.graphics.newQuad(q.x, q.y, q.w, q.h, quad:getDimensions())
	end

end


function screen_full ()

	if game.invertstereo then
		love.audio.setOrientation(0, 0, 1, 0,1,0)
	else
		love.audio.setOrientation(0, 0, 1, 0,-1,0)
	end

	local fullscreen_ok, fullscreen_error =
		love.window.setFullscreen(game.fullscreen or false)
	screen_res ()

	vi.mobspawndist = screen.x + 1

	game.mastervolume = game.mastervolume or 100
	love.audio.setVolume(game.mastervolume*0.01)

	return fullscreen_ok, fullscreen_error

end

function screen_res ()
	

	local h = 14
	local w = 8

	screen = {}
	screen.width, screen.height, screen.flags = love.window.getMode ()

	screen.txt = screen.height - h*14 --y coord of text

	screen.inv = screen.width - w*36

	screen.txtwidth = math.floor ((screen.width - w*36 - w*13)/w)
	if screen.txtwidth<15 then screen.txtwidth=15 end

	screen.txtcraft = math.floor (screen.width/w) - screen.txtwidth - 9

	vi.textwall_w = screen.txtwidth * w - 50
	text_canvas = love.graphics.newCanvas(vi.textwall_w,vi.textwall_h)
	draw_textwall ()


	--local ew = width - w*36
	local ew = screen.width - w*18
	local eh = screen.height - h*15 

	vi.vixmax = ew/2 + ew/10 - w*18
	vi.vixmin = ew/2 - ew/10 + w*18

	vi.viymax = eh/2 + eh/10
	vi.viymin = eh/2 - eh/10

	vi.viymax = eh/2
	vi.viymin = eh/2

	screen.x =  math.floor (screen.width / 32) + 3
	screen.y =  math.floor (screen.height / 32) + 3

	if game.gr2x then
		vi.vixmax = vi.vixmax / 2
		vi.vixmin = vi.vixmin / 2
		vi.viymax = vi.viymax / 2
		vi.viymin = vi.viymin / 2

		screen.x = math.ceil (screen.x/2)
		screen.y = math.ceil (screen.y/2)

	end

	if resize_render_canvases then
		resize_render_canvases()
	end



end



function camera_fix ()

	local fix

	while fix==nil do

		fix = true
		if vi.xoffset>=32 then
			vi.xoffset = vi.xoffset - 32
			vi.xtile = vi.xtile + 1
			fix = nil
		end

		if vi.xoffset<=-32 then
			vi.xoffset = vi.xoffset + 32
			vi.xtile = vi.xtile - 1
			fix = nil
		end

		if vi.yoffset>=32 then
			vi.yoffset = vi.yoffset - 32
			vi.ytile = vi.ytile + 1
			fix = nil
		end

		if vi.yoffset<=-32 then
			vi.yoffset = vi.yoffset + 32
			vi.ytile = vi.ytile - 1
			fix = nil
		end

		vi.x = vi.xtile * cf.w + vi.xoffset
		vi.y = vi.ytile * cf.h + vi.yoffset
	end

end

function camera_move ()
	
	local d = 0
	local up

	-- camera
	-- scroll right
	--repeat

	if pl.x > vi.vixmax then

		up = true

		d = math.ceil ((pl.x - vi.vixmax)/40)
		pl.x = pl.x - d
		vi.xoffset = vi.xoffset + d

		if vi.xoffset>=32 then
			vi.xoffset = vi.xoffset - 32
			vi.xtile = vi.xtile + 1
		end
	end

	-- scroll left
	if pl.x < vi.vixmin and vi.xtile>0 then

		up = true
		d = math.ceil ((pl.x - vi.vixmin)/40)
		pl.x = pl.x - d
		vi.xoffset = vi.xoffset + d

		if vi.xoffset<=-32 then
			vi.xoffset = vi.xoffset + 32
			vi.xtile = vi.xtile - 1
		end
	end

	-- scroll down
	if pl.y > vi.viymax then

		up = true
		d = math.ceil ((pl.y - vi.viymax)/40)
		pl.y = pl.y - d
		vi.yoffset = vi.yoffset + d

		if vi.yoffset>=32 then
			vi.yoffset = vi.yoffset - 32
			vi.ytile = vi.ytile + 1
		end
	end

	-- scroll up
	if pl.y < vi.viymin and vi.ytile>0 then

		up = true
		d = math.ceil ((pl.y - vi.viymin)/40)
		pl.y = pl.y - d
		vi.yoffset = vi.yoffset + d

		if vi.yoffset<=-32 then
			vi.yoffset = vi.yoffset + 32
			vi.ytile = vi.ytile - 1
		end
	end

	-- screen coords
	vi.x = vi.xtile * cf.w + vi.xoffset
	vi.y = vi.ytile * cf.h + vi.yoffset


	vi.cammoving = d+1
	

end


function coord_screen2true (ct)

	local r = px2tile (ct.x,ct.y)

	ct.truex = vi.xtile * cf.w + vi.xoffset + ct.x
	ct.truey = vi.ytile * cf.h + vi.yoffset + ct.y

	ct.lx = 24 - math.floor ((r.x * cf.w) - ct.truex)
	ct.ly = 26 - math.floor ((r.y * cf.h) - ct.truey)

	--print (ct.lx.." "..ct.ly)

	ct.tx = r.x
	ct.ty = r.y


end

function coord_true2screen (ct)

	if ct.truex==nil then return false end

	ct.tx = math.floor (ct.truex/cf.w)
	ct.ty = math.floor (ct.truey/cf.h)

	ct.txl = ct.truex - ct.tx*cf.w
	ct.tyl = ct.truey - ct.ty*cf.h
	
	ct.x = (ct.tx - vi.xtile)*cf.w - vi.xoffset + (ct.truex - ct.tx*cf.w)
	ct.y = (ct.ty - vi.ytile)*cf.h - vi.yoffset + (ct.truey - ct.ty*cf.h)
	ct.tx = ct.tx + 1
	ct.ty = ct.ty + 1

	return true
end

function is_onscreen(t)
	-- body
end


function tile2px (x,y)

	local w = 32
	local h = 32

	x = (x-1)*w - vi.xtile * w - vi.xoffset
	y = (y-1)*h - vi.ytile * h - vi.yoffset

	return {x = x, y = y, x2 = x+w, y2 = y+h}
	
end


function px2tile (x,y)

	local w = 32
	local h = 32

	x = x + vi.xoffset
	x = math.floor (x/w)+1 + vi.xtile
	y = y + vi.yoffset
	y = math.floor (y/h)+1 + vi.ytile

	return {x = x, y = y}, x, y
	
end


function water_add (x,y,water,str,force)
	
	str = str or 'w'
	local w = (readmap (x,y,str) or 0)

		if w < 10000 or force then

			w = w + water
			water = 0

			--and w<10001
			if w>9900 then -- overflow
				water = w - 10000
				w = 10000
			end

			writemap (x,y,w,str)

		end

	if water<100 then water = 0 end

	return water

end


-- map.w = water_eq (x-1,y, map.w,1)

function dirt_eq (x,y,water,o,str)

	if water~=nil then
	
		water = water or 0
		str = str or 'dr'

		local w = (readmap (x,y,str) or water)
		local w2 = math.ceil ((water + w)/2)

		if w2>200 then w2=200 end

		--print (w2.." "..o)
		writemap (x,y,w2,str)
		return w2

	end

end

function water_eq (x,y,water,o,str)
	
	water = water or 0
	str = str or 'w'
	local w = (readmap (x,y,str) or 0)

	if w>100 and math.floor (w/10) == math.floor (water/10) then return math.ceil (water) end

	local w2 = math.ceil ((water + w)/2)
	writemap (x,y,w2,str)

	if w2<100 then w2 = 0 end


	--print (math.abs (water-w2))

	return w2

end



-- MAP
--------------------------------------------------

function maptile(x,y,mode)

	mode = mode or 'col'
	
	if world[y] and world[y][x] then
		
		local tile = world[y][x].b

		if tile == 0 or tile == nil then

			if mode=="all" then return {},world[y][x] else return 0 end

		end

		if mode=="all" then 
			return (stone[tile] or {}),world[y][x] 
			else
				
				if mode=='col' and game.pass and stone[tile][game.pass] then 
					return 0
				end

				return stone[tile][mode] or 0

			end -- normal return

	else
		if mode=='all' then
			return {},{}
		else
			return 0,{}
		end
	end



end


function neibors (x,y)
	
	local r = 1
	local s = ''
	local c = 0
	local sf = {}
	local add = ""
	local a = {}

	for ix=r*(-1),r do
		for iy=r*(-1),r do

			if ix == 0 and iy == 0 then
			else
				local tile, map = maptile (x+iy,y+ix,"all")
				
				if map then
					if map.b == 0 or tile.col==0 then
						if map and map.n == 255 then
							add = '1'
						else
							add = '0'
						end
					else
						add = '1'
					end

					s = s..add

					table.insert (a, add)

				end

			end
		end
	end

	-- 123
	-- 405
	-- 678

	--dump (a[1])

	local cr = maptile (x,y,"cr")

	if cr==1 then

		if a[4]=="0" and a[2]=="0" then
			table.insert (sf,1)
		else
			table.insert (sf,0)
		end

		if a[2]=="0" and a[5]=="0" then
			table.insert (sf,1)
		else
			table.insert (sf,0)
		end

		if a[5]=="0" and a[7]=="0" then
			table.insert (sf,1)
		else
			table.insert (sf,0)
		end

		if a[7]=="0" and a[4]=="0" then
			table.insert (sf,1)
		else
			table.insert (sf,0)
		end

	end



	--return s
	s = tonumber(s, 2) 
	if s==0 then s=nil end
	return s,sf

end

function readmap (x,y,mode)

	if world == nil then
		return 0
	end

	if y<0 or x<0 then return false end
	if world[y] == nil or world[y][x] == nil then return false end

	if mode then return world[y][x][mode]
		else
			return tablecopy (world[y][x])
		end

end


function room_storetime (q, pc)

	if q==nil then return 1 end

	q = q * 0.1

	if pc then
		q = q * 100
		return string.format("%.0f", q)
	end

	q = 1/(1+q)
	--print (q)

	return q

end

function room_clear (x,y)
	
	local function clear (dir)
		if dir~=nil then
			for k,v in pairs(dir) do
				--dump (v)
				writemap (v[1],v[2],nil,'room')
			end
		end
	end

	clear (readmap (x,y,'rooml'))
	clear (readmap (x,y,'roomr'))

	writemap (x,y,nil,'rooml')
	writemap (x,y,nil,'roomr')

end



function room_fill (x,y,dir)

	local tofill = {}
	tofill[x.."_"..y] = {x,y}
	local dirs = {
		{0,-1}, --up
		{1,0},
		{0,1},
		{-1,0}
	}

	::recheck::

	local unchecked = nil
	local cnt = 0
	local borders = 0
	local border = 0
	local walls = {}

	for k,v in pairs(tofill) do
		for i,vv in ipairs(dirs) do
			
			if maptile (v[1]+vv[1],v[2]+vv[2],'col')==0 then
				if tofill[v[1]+vv[1].."-"..v[2]+vv[2]]==nil then
					tofill[v[1]+vv[1].."-"..v[2]+vv[2]] = {v[1]+vv[1],v[2]+vv[2]}
					unchecked = 1
				end
			else
				if walls[v[1]+vv[1].."-"..v[2]+vv[2]]==nil then
					local br = readmap (v[1]+vv[1],v[2]+vv[2],'b')
					if br ~= 183 then
						borders = borders + (cf.bricks[br] or 1)
						border = border + 1
						walls[v[1]+vv[1].."-"..v[2]+vv[2]]=1
					end
				end
			end

		end
		cnt = cnt + 1
	end

	if cnt>100 then return end

	if unchecked then
		goto recheck
	end

	cnt = cnt + 1
	--print (cnt)
	

	return tofill, borders/border, cnt


end


function createblock (b)
	local z = {}
	z.b = b
		if stone[b] and stone[b].ttl then
			z.t = game.time
		end
	return z
end

function writemap (x,y,z,mode)

	mode = mode or 'b' -- i,t

	if y<0 or x<0 then return false end
	if world[y] == nil then world[y] = {} end
	if world[y][x] == nil then world[y][x] = {} end
	
	if mode=="clear" then
		cleartable (world[y][x])
		writemap (x,y,z)
		multiplayer_record_cell(x, y)
		return true
	end

	if mode == "all" then

		world[y][x] = tabledeepcopy (z)
		game.ttl_list[x.."-"..y] = {x,y}
		multiplayer_record_cell(x, y)
		return true
		
	else

		world[y][x][mode] = z

		if mode == "f" then
			game.ttl_list[x.."-"..y] = {x,y}
		end

		if mode == "b" then

			if stone[z] and stone[z].ttl then
				writemap (x,y,game.time,'t')
				game.ttl_list[x.."-"..y] = {x,y}
			else
				writemap (x,y,nil,'t')
			end

		end
		multiplayer_record_cell(x, y)

		return z

	end

end





-- BLOCKS
--------------------------------------------------

function growup (x,y,z,w)

	local tile, map = maptile (x,y-1,"all")

	if w and readmap (x,y,'b')~=w then
		return false
	end

	if map.b == nil or map.b == 0 or map.b == 96 or map.b == 17 or map.b == 36 or map.b == 37 or map.b == 85 then
		writemap (x,y-1,z)
		return true
	end

	return false
end


function grow (x,y,w,z)

	local tile, map = maptile (x,y,"all")

	if map.b == w then
		writemap (x,y,z)
		return true
	end

	return false

end

function water_ground (x,y,z)
	local e = readmap (x,y,"wt")
	local wt = maptile (x,y,'absorb') or 0
	if wt>0 then
		e = e or 0
		writemap (x,y,e+z,'wt')
	end
end


function lookaround (x,y,z,r)
	for i,v in ipairs(z) do
		for ix=r*(-1),r do
			for iy=r*(-1),r do
				if ix == 0 and iy == 0 then
				else
				if readmap (x+ix,y+iy,'b')==v then return x+ix,y+iy end
				end
			end
		end
	end
	return nil
end

function luxaround (x,y,z,r)
	local c = 0
	for i,v in ipairs(z) do
		for ix=r*(-1),r do
			for iy=r*(-1),r do
				--if ix == 0 and iy == 0 then
				--else
				if readmap (x+ix,y+iy,'b')==v then 
					c = c + r/math.dist (0, 0, ix, iy)  
				--end
				end
			end
		end
	end
	if c>5 then c=5 end
	return c
end

function has_light_c (x,y,b,d)

	local x1,y1 = lookaround (x,y,{b},d)
	if x1 then
		--local dist = math.dist (x, y, x1,y1)
		--if dist <= d then return true end
		return true
	end

end

function has_light (x,y)

	local lux = luxaround (x,y,{5},2) +
	luxaround (x,y,{6},3) +
	luxaround (x,y,{7},4) +
	luxaround (x,y,{104},3) +
	luxaround (x,y,{132},7) +
	luxaround (x,y,{193},3)

	if lux == 0 then return nil else return lux end

end

function fertilize (x,y,z)

	local b = readmap (x,y,"b")
	local e = readmap (x,y,"e")
	e = e or 0
	writemap (x,y,e+z,'e')

	if z<0 and e<=0 then
		return
	end

	return true

end


-- PLANTS
--------------------------------------------------

function plant_dig (x,y,s)
	local s = stone[s].plant

	local stage = readmap (x,y,'stage') or 1

	for i,v in ipairs(s.loot[stage]) do
		inv_add (item_make(v))
	end

	-- if stage == s.dead then
	-- 	textwall (msg.game[31]) --died
	-- end

end

function plant_grow (x,y,s)

	local vr = readmap (x,y,'vr')

	if vr==nil then
		if love.math.random (0,100)<40 then
			writemap (x,y,1,'vr')
		else
			writemap (x,y,-1,'vr')
		end
	end


	local plant = stone[s].plant

	local wt = readmap (x,y+1,'wt') or 0
	local e = readmap (x,y+1,'e') or 0
	local mu = readmap (x,y+1,'mu') or 0
	local bb = readmap (x,y+1,'b') or 0
	

	local stage
	local age = readmap (x,y,'age') or 1
	local room = readmap (x,y,'room')
	local w = readmap (x,y,'w') or 0
	local neg = readmap (x,y,'neg') or 0
	local haslight = has_light (x,y) or 0


	local problem
	if plant.flood and w>plant.flood then problem = 1 end
	if wt<=0 and plant.wt>0 then problem = 2 end
	if e<plant.e then problem = 3 end
	if plant.light and haslight<=0 then problem = 4 end
	if bb==48 then problem = 6 end
	if age>=plant.dead then problem = 5 end
	if plant.growable and not in_array (plant.growable, bb) then
		problem = 7
	end
	if plant.indoors and room==nil then problem = 10 end

	if problem then
		if neg==0 then
			neg = game.time
		end
	else
		neg = 0
	end

	--freezing to death
	if plant.freeze and game.time-neg>plant.freeze and problem==6 then
		age = plant.dead
	end

	if neg>0 and game.time-neg>plant.neg then
		age = plant.dead
	end

	if problem==nil then

		local spend

		if age<plant.stages-1 then

			--growing

			age = age + plant.step 
			--age = age + (plant.step * (haslight-1) * 0.1)

			local mumu = 1
			
			if mu>0 then
				mu = mu - plant.step
				mumu = 0.7
			end

			if mu<0 then mu = 0 end

			wt = wt - plant.wt * mumu
			e = e - plant.e * mumu * 2
			neg = 0

		else

			age = age + plant.laststep

		end

	end


	if mu<=0 then mu = nil end
	if e<=0 then e = nil end
	if wt<=0 then wt = nil end

	stage = math.floor(age)
	if stage>plant.dead then
		stage = plant.dead
	end
	

	writemap (x,y,has_light (x,y),'lux')

	writemap (x,y,age,'age')
	writemap (x,y,stage,'stage')
	writemap (x,y+1,wt,'wt')
	writemap (x,y+1,e,'e')
	writemap (x,y+1,mu,'mu')
	writemap (x,y,neg,'neg')
	writemap (x,y,problem,'problem')
	
end

-- z = blocks, r = radius, w = what
function plant_spores (x,y,z,r,w)

	for i,v in ipairs(z) do
		for ix=r*(-1),r do
		for iy=r*(-1),r do

			if ix == 0 and iy == 0 then
			else
				if readmap (x+ix,y+iy,'b')==v and readmap (x+ix,y+iy-1,'b')==0 then 
					writemap (x+ix,y+iy-1, w) 
					return x+ix,y+iy-1
				end
			end

		end
		end
	end

end

-- COLLIDE
--------------------------------------------------

function collide_check (who,t,mode)

	local a = {}
	if type(who) == 'string' then
		who = colliders[who]
	end

	for k,v in pairs(colliders) do
		if v.type == t then

			--dump (who)
			--dump (v)
			--print (who.w.."--"..v.x.." "..who.x.."-"..v.w.." "..who.h.."-"..v.y.." "..who.y.."-"..v.h)
			
			if (who.w<v.x or who.x>v.w) or (who.h<v.y or who.y>v.h) then
			else
				
				if mode==nil then
					return v
				end

				if mode and mode.name and mode.name==v.name then
					return v
				end

				if mode and mode.arrname and in_array (mode.arrname,v.name) then
					return v
				end



				if mode and mode.arr then
					table.insert (a,v)
				end
			end
		end
	end

	if mode and mode.arr then return a end

end



function col_add (id,obj,state,name,t,num)
	
	local oldname = name
	if state and cols[name.."_"..state] then
		name = name.."_"..state
	end

	if obj.d and cols[name.."_"..obj.d] then
		name = name.."_"..obj.d
	end

	local c

	if obj.flip == -1 and oldname=='player' then

		c = {
		x = obj.truex + (cols[name][3] + cols[name][1]) * (-1), 
		y = obj.truey + cols[name][2], 
		w = obj.truex + cols[name][3] + ((cols[name][3] + cols[name][1]) * (-1)),
		h = obj.truey + cols[name][2]+cols[name][4], 
		name = name, --5
		type = t,--6
		n = num,
		actor_id = obj.actor_id,
		object = obj,
		}

	else
		
		if obj.truex==nil then
			oldprint (dumpvar (obj))
		end

		c = {
		x = obj.truex + cols[name][1], 
		y = obj.truey + cols[name][2], 
		w = obj.truex + cols[name][1]+cols[name][3],
		h = obj.truey + cols[name][2]+cols[name][4], 
		name = name, --5
		type = t,
		n = num, --6
		actor_id = obj.actor_id,
		object = obj,
		}
	end

	if id and id~='' then colliders[id] = c end
	
	return c

end

local function nearest_collision_offset(offsets)
	if #offsets == 0 then
		return nil
	end
	return math.min(unpack(offsets)) - 1
end


-- collide (obviously)
function tocollide (points, pass)

	--pass = pass or game.pass
	
	dumpout=""
	local togo = {up = {}, down = {}, right = {}, left = {}, y ={}, x={}}


	for i,v in ipairs(points) do
		local x = v.x
		local y = v.y
		local mode = v.mode or {}
		

		local r = px2tile (x,y)
		local tile = tile2px (r.x, r.y)

		if maptile (r.x,r.y) == 1 then --hit
			table.insert (togo.y, 32 - (y - tile.y2)*-1)
			table.insert (togo.x, 32 - (x - tile.x2)*-1)
		end


		--up
		if mode.up
			then
			local r = px2tile (x,y)
			local tile = tile2px (r.x, r.y-1)

			if maptile (r.x,r.y-1) == 0 or (pass and maptile (r.x,r.y-1, pass) == 1)--cango
				then
				table.insert (togo.up, (tile.y2 - y - 32)*-1)
			else
				table.insert (togo.up, (tile.y2 - y)*-1)	
			end
		end

		--down
		if mode.down
			then
			local r = px2tile (x,y)
			local tile = tile2px (r.x, r.y+1)

			if maptile (r.x,r.y+1) == 0 or (pass and maptile (r.x,r.y+1, pass) == 1) --cango
				then
				table.insert (togo.down, tile.y2 - y)
			else
				table.insert (togo.down, tile.y2 - y - 32)	
			end
		end


		--right
		if mode.right
			then
			local r = px2tile (x,y)
			local tile = tile2px (r.x, r.y)

			if maptile (r.x+1,r.y) == 0 or (pass and maptile (r.x+1,r.y, pass) == 1) --cango
				then
				table.insert (togo.right, tile.x2 - x + 32)
			else
				table.insert (togo.right, tile.x2 - x)
			end
		end


		--left
		if mode.left
			then
			local r = px2tile (x,y)
			local tile = tile2px (r.x-1, r.y)

			if maptile (r.x-1,r.y) == 0 or (pass and maptile (r.x-1,r.y, pass) == 1) --cango
				then
				table.insert (togo.left, (tile.x2 - x - 32)*-1)
			else
				table.insert (togo.left, (tile.x2 - x)*-1)
			end

		end

	end
	
	if #togo.x>0 then
	togo.x = (math.max (unpack(togo.x)))
	if togo.x < 16 then togo.x = togo.x *(-1) end 
	if togo.x > 16 then togo.x = 32-togo.x end
	else
		togo.x = nil
	end	
	
	if #togo.y>0 then
	togo.y = (math.max (unpack(togo.y)))
	if togo.y < 16 then togo.y = togo.y *(-1) end 
	if togo.y > 16 then togo.y = 32-togo.y end
	else
		togo.y = nil
	end	
	
	
	
	togo.up = nearest_collision_offset(togo.up)
	togo.down = nearest_collision_offset(togo.down)
	togo.left = nearest_collision_offset(togo.left)
	togo.right = nearest_collision_offset(togo.right)


		if togo.x then
		--	dump (togo)
		end

	return togo

end



function cd_passed (a,name,n)

	if a[name]==nil then
		a[name] = game.dt + n
		return nil
	end

	if a[name] then 
		if a[name]< game.dt then 
			a[name] = nil
			return true
		end
		return nil
	end

end



function cooldown (a,name,mode,rand)

	--mode:set
	rand = rand or 0

	if type(mode)=='number' then
		a[name.."_cd"] = game.dt + mode
		return true
	end

	if mode == "set" then
		a[name.."_cd"] = game.dt + a[name]
		return true
	end

	a[name.."_cd"] = a[name.."_cd"] or game.dt

	if a[name.."_cd"] and a[name.."_cd"] < game.dt then
		
		if mode==nil then
			a[name.."_cd"] = game.dt + a[name] + math.floor(a[name]*love.math.random (0,rand))
		end
		--mode:check
		return true
	end
	return false
end





-- INVENTORY
--------------------------------------------------

function loot_make (l)
	
	if l then 						

		local t = 0
		local t2 = 0
		for k,v in ipairs (l) do
			t = t + v.p
		end

		local rn = love.math.random (0,t)

		for k,v in ipairs(l) do
			t2 = t2 + v.p
			if rn <= t2 then
				return v.i
			end
		end
	end

end

function item_firing (x,y,tile,map, temp, time, to)

	local tneed = map.de/temp -- temperature
	writemap (x,y,tneed,'tneed')

	if tneed>1 then
		tneed = 1
		local cd = map.cd or 0
		cd = cd + dt

		local done = cd/(time/2) -- time

		if done>=1 then 
			--writemap (x,y,to,'clear') --new jug
			writemap (x,y,to) --new jug
			writemap (x,y,nil,'tneed')
			writemap (x,y,nil,'cd')
			writemap (x,y,nil,'done')
			
			return true
		end

		writemap (x,y,cd,'cd')
		writemap (x,y,done,'done')

	end

end

function item_make (i,pc)

	item_unlock (i)

	-- Id
	-- Durability
	-- Name
	-- Created
	-- Ticks

	pc = pc or 1
	if item[i] == nil then return nil end
	
	local it = {}
	it.i = i
	it.d = item[i].durability
	it.n = item[i].name
	
	if item[i].ttl then
		it.c = game.time
		it.t = item[i].ttl*pc
	end

	if item[i].tool then
		it.tool = tablecopy (item[i].tool)
	end
	ItemIdentity.ensure(it, game)

	return it

end


function inv_item (slot, stat, write)

	if pl.inv[slot] then
		if write then
			pl.inv[slot][stat] = write
			return true
		else
			return pl.inv[slot][stat]
		end
	end

	return false
end


function itemstat (i,stat)
	
	if i==nil then return nil end

	if type (i) ~= 'table' then
		i = item[tonumber (i)]
	end

	if i then
		if i.tool and i.tool[stat] then return i.tool[stat] end
		if i[stat] then return i[stat] end
	end

	if type (i) == 'table' then
		return itemstat (i.i, stat)
	end

end

function tool_damage_per_second(tool)
	if type(tool) ~= "table" then return 0 end

	local minimum = tonumber(tool.dmgmin)
	local maximum = tonumber(tool.dmgmax)
	if minimum == nil and maximum == nil then return 0 end

	minimum = minimum or maximum
	maximum = maximum or minimum
	local speed = tonumber(tool.digspeed) or 1
	if speed <= 0 then speed = 1 end

	return ((minimum + maximum) / 2) / speed
end


function next_numeric_id(values)
	local maximum = 0
	for key in pairs(values or {}) do
		if type(key) == "number" and key > maximum and key == math.floor(key) then
			maximum = key
		end
	end
	return maximum + 1
end


function inv_itemstat (slot,stat)

	local item = pl.inv[slot]
	return itemstat (item, stat)

end


function inv_add (it,mode)

	mode = mode or {}
	if it==nil then return nil end
	ItemIdentity.ensure(it, game)

	for i=1,pl.invsize do
		if pl.inv[i]==nil then

			pl.inv[i] = it

			pl.invselect = i

			if pl.inv[pl.invselect]==nil then
				pl.invselect = i
			end

			if mode.select then
				pl.invselect = i
			end

			if item[pl.inv[i].i].ontake then
				item[pl.inv[i].i].ontake ()
			end

			if mode and mode.verbose then
				textwall (msg.game[21],false,{[1] = item[pl.inv[i].i].name})
			end

			inv_compact ()
			item_unlock (it.i)
			return i
		end
	end

	item_unlock (it.i)
	if mode.pick then
		textwall (msg.game[44],true)
	end
	return inv_ground_add (pl.xt, pl.yt, it,mode)
	
end


function inv_count ()
	local c = 0
	local max = 0

	for i,v in pairs(pl.inv) do
		if type(i)=='number' then
			c = c + 1
			if i>max then max = i end
		end
	end

	return c,max

end

function inv_compact_old ()
	local e = 0
	local last = 0

	for i=1,pl.invsize do
		if pl.inv[i] then last = i end
	end

	for i=1,last do
		if pl.inv[i]==nil and e==0 then 
			e = i 
		end
	end

	if last~=0 and e~=0 and last~=e then
		pl.inv[e] = tabledeepcopy (pl.inv[last])
		pl.inv[last] = nil

		if pl.invselect==last then pl.invselect = e end
	end

end


function item_score (it)

	if it==nil then return 0 end

	if item[it.i].score then
		return item[it.i].score
	end

	local s = 0
	for i,v in ipairs({'dig','cut','chop','smash','pierce','dmgmin','dmgmax'}) do
		s = s + (itemstat(it,v) or 0)
	end


	if item[it.i].onuse then
		s = s + 50
	end

	if s>0 then s = s + 1000 end

	s = s + (itemstat(it,'calories') or 0)*0.001
	if s>0 then s = s + 100 end

	if item[it.i].onburydie then 
		s = s + 10
	end

	s = s + it.i*0.001

	return s

end

function item_score_sort (k1,k2)
	return item_score (k1) > item_score (k2)
end


function inv_tick_ttl ()
	local entries = {}
	for _, value in pairs(pl.inv or {}) do
		entries[#entries + 1] = value
	end

	for _, value in ipairs(entries) do
		local slot
		for key, current in pairs(pl.inv or {}) do
			if current == value then
				slot = key
				break
			end
		end

		local definition = value and item[value.i]
		if slot and definition then
			local elapsed = game.time - (value.c or game.time)
			value.t = (value.t or definition.ttl or 0) - elapsed * (definition.tti or 0)
			value.c = game.time

			if value.t <= 0 then
				local handled
				if definition.oninvdie then
					handled = definition.oninvdie()
				end

				if handled == nil then
					if definition.invdie and definition.invdie ~= 0 then
						textwall(msg.game[23], false, {
							[1] = definition.name,
							[2] = item[definition.invdie].name,
						})
						pl.inv[slot] = item_make(definition.invdie)
					else
						textwall(msg.game[24], false, { [1] = definition.name })
						inv_remove(slot)
					end
				end
			end
		end
	end
end


function inv_overflow ()
	local slots = {}
	for slot in pairs(pl.inv or {}) do
		if type(slot) == "number" and slot > pl.invsize then
			slots[#slots + 1] = slot
		end
	end
	table.sort(slots)

	for _, slot in ipairs(slots) do
		local dropped = inv_remove(slot, { noc = true })
		if dropped then inv_ground_add(pl.tx, pl.ty, dropped) end
	end
	if #slots > 0 then inv_compact() end
	return #slots
end


function inv_resize(delta)
	pl.invsize = math.max(0, (pl.invsize or 0) + delta)
	if delta < 0 then inv_overflow() end
	return pl.invsize
end

function inv_show ()

	pl.inv_show_c = 0
	pl.inv_show = {}

	for i=1,pl.invsize do
		if pl.inv[i] then
			
			table.insert (pl.inv_show, i)

			if i==pl.invselect then
				pl.inv_show_c = #pl.inv_show
			end

		end
	end

	for i,k in ipairs(cf.eq) do
		if pl.inv[k] then
			
			table.insert (pl.inv_show, k)

			if k==pl.invselect then
				pl.inv_show_c = #pl.inv_show
			end

		end
	end

end

function inv_compact ()


	local selected = pl.inv[pl.invselect]
	local newinv = {}

	for i=1,pl.invsize do
		if pl.inv[i] then
			newinv[#newinv + 1] = pl.inv[i]
		end
	end

	table.sort (newinv,item_score_sort)

	for i=1,pl.invsize do
		pl.inv[i] = newinv[i]
		if pl.inv[i] == selected then
			pl.invselect = i
		end
	end


	inv_show ()


end



function inv_remove (i, mode)

	mode = mode or {}

	if pl.inv[i] then

		game.justremoved = pl.inv[i].i

		local l = pl.inv[i]
		pl.inv[i] = nil

		if item[l.i].ondrop then
			item[l.i].ondrop ()
		end

		if type(i)=='number' then

			local is = nil

			for i=1,pl.invsize do
				if pl.inv[i] and pl.inv[i].i == l.i then
					pl.invselect = i
					is = true
				end
			end

			if mode.noc==nil then inv_compact () end

			if is == nil then

				while pl.inv[pl.invselect]==nil and pl.invselect>0 do
					pl.invselect = pl.invselect - 1
				end

				while pl.inv[pl.invselect]==nil and pl.invselect<9 do
					pl.invselect = pl.invselect + 1
				end


			end

		else

			if item[l.i].onunequip then
				item[l.i].onunequip ()
			end

		end


		return l

	end
	return nil
end


function inv_ground_count (x,y)
	if world[y] and world[y][x] and world[y][x].i then
		return #world[y][x].i
	end
	return 0
end

function inv_find(z,to)
	
	if type(z) == "table" then
		for i,v in ipairs(z) do
			local r = inv_find (v)
			if r~=nil then return r end
		end
		return nil
	end

	if pl.inv==nil then return nil end

	for k,v in pairs(pl.inv) do
		if v.i==z then
			if to then 
				pl.inv[k] = item_make(to)
			end
		 	return k 
		end
	end

	return nil

end


function inv_ground_find(x,y,z)
	
	if type(z) == "table" then
		for i,v in ipairs(z) do
			local r = inv_ground_find (x,y,v)
			if r~=nil then return r end
		end
		return nil
	end
	
	local inv = world[y][x].i
	if inv==nil then return nil end

	for k,v in pairs(inv) do
		if v.i==z then return v end
	end

	return nil
end

function inv_ground_find_i(x,y,z)
	
	if type(z) == "table" then
		for i,v in ipairs(z) do
			local r = inv_ground_find_i (x,y,v)
			if r~=nil then return r end
		end
		return nil
	end

	local inv = world[y][x].i
	if inv==nil then return nil end

	for k,v in pairs(inv) do
		if v.i==z then return k end
	end

	return nil
end


function inv_ground_find_r (x,y,z,r)
	for ix=x-r,x+r do
		for iy=y-r,y+r do

			if inv_ground_find_i (ix,iy,z) then
				return ix,iy
			end
		
		end
	end
end


function inv_ground_replace (x,y,i,it)
	if world[y] and world[y][x] and world[y][x].i[i] then

		if it == nil then
			inv_ground_remove (x,y,i)
			return false
		end

		ItemIdentity.ensure(it, game)
		world[y][x].i[i] = it
		multiplayer_record_cell(x, y)
		return true

	end

	return false
	
end


function inv_ground_add (x,y,it,mode)

	mode = mode or {}

	if type(mode.items) == "table" then
		for k,v in pairs(mode.items) do inv_ground_add (x,y,v) end 
	end

	if world[y] and world[y][x] and it~=nil then
		ItemIdentity.ensure(it, game)

		if world[y][x].i == nil then world[y][x].i = {} end

		if mode.groundlast then
			table.insert (world[y][x].i,it)
			else
			table.insert (world[y][x].i,1,it)
		end
		game.ttl_list[x.."-"..y] = {x,y}
		multiplayer_record_cell(x, y)
		return it

	else
		return nil
	end

end

function inv_ground_remove (x,y,i)

	if world[y] and world[y][x] and world[y][x].i then
		local r = table.remove (world[y][x].i,i)
		if #world[y][x].i == 0 then 
			world[y][x].i = nil 
			world[y][x].io = nil 
			if (maptile (x,y,'ttl') or 0)==0 then
				game.ttl_list[x.."-"..y] = nil
			end
		end
		multiplayer_record_cell(x, y)
		return r
	else
		return nil
	end

end


function item_wear (i,pc)

	if i==nil or i.i==nil then
		return nil,nil
	end

	if item[i.i].ttl then
		i.t = math.ceil (i.t - item[i.i].ttl*pc)
	end

	return i
end


-- PLAYER AND STATS
--------------------------------------------------

function give_legacy (inv)

	local how = function (x,y)
		local g = readmap (x,y,'g') or 0
		if g==-1 then
			return true
		end
	end

	local x,y = find_block (pl.startx, pl.starty+5,how,20)
	writemap (x,y,49)
	
	for k,v in pairs(inv) do
		if v.i~=26 and v.i~=27 and v.i~=284 and v.i~=285 then 
			inv_ground_add (x,y,v)
		end
	end 

end



function player_pos_reset (x,y)
	vi.xoffset = 0
	vi.yoffset = 0
	pl.x = 16
	pl.y = 32*4+6
	vi.xtile   = x or pl.startx
	vi.ytile   = y or pl.starty
	coord_screen2true (pl)
	camera_move ()
	camera_fix ()
end

function player_pos_port (x,y)
	vi.xoffset = 0
	vi.yoffset = 0

	local r = tile2px (x,y)

	pl.x = r.x
	pl.y = r.y
	--vi.xtile   = x
	--vi.ytile   = y
	coord_screen2true (pl)
	camera_move ()
	camera_fix ()
end

function actor_uses_local_presentation(actor)
	if not actor then return false end
	-- A second actor exists only while multiplayer state is installed. Its
	-- simulation may temporarily make it the global `pl`, but visual effects
	-- must still belong to the player viewing this process.
	if actors and actors.guest and actors.local_actor then
		return actor == actors.local_actor
	end
	return true
end

function actor_health_presentation_update(actor)
	if not actor_uses_local_presentation(actor) then return false end
	local body = actor.stats and actor.stats.body
	if not body then return false end
	local critical = not actor.isdead and (tonumber(body.hp) or 0) <= 10
	local runtime = actors and actors.runtime and actors:runtime(actor)
	local presentation = runtime and runtime.presentation
	if presentation and presentation.health_critical == critical then
		return false
	end
	if presentation then presentation.health_critical = critical end
	if shader then shader:send("dying", critical and 1 or 0) end
	if critical then
		sound_add('heartbeat', 24, { force_relative = true })
	else
		sound_kill('heartbeat')
	end
	return true
end

function actor_floating_text_add(actor, entry, x_offset, y_offset)
	if type(actor) ~= "table" or type(entry) ~= "table" then return false end
	x_offset = tonumber(x_offset) or 0
	y_offset = tonumber(y_offset) or 0
	entry.x = (tonumber(actor.x) or 0) + x_offset
	entry.y = (tonumber(actor.y) or 0) + y_offset
	if actor.truex and actor.truey then
		-- Keep the label in world space. ActorContext uses the guest camera while
		-- simulating its hit; leaving only screen coordinates made the host camera
		-- later reinterpret that label as if the host had been hit.
		entry.truex = actor.truex + x_offset
		entry.truey = actor.truey + y_offset
	end
	table.insert(sct, entry)
	return true
end

function player_reset ()
	
	pl.inv = {}

	player_pos_reset ()
	pl.state = 'idle'
	--player_pos_reset ()
	stat_spend ('power', 75)
	if actor_uses_local_presentation(pl) then
		shader:send("dying", 0)
		sound_kill ('heartbeat')
	end
	sound_add ('born',13)

	ani_setstatus (game.start,'born')
	writemap (pl.tx,pl.ty,0,'n')
	love.audio.setVolume(1)

end

function player_rest (x,y,q,h)


	pl.resttillhealed = true
	local r = readmap (x,y,'room') or 0
	
	pl.rest = time.h*h
	game.fadein = 0.5
	pl.restquality = q+r*0.1

	local de = readmap (pl.xt, pl.yt,"de") or 0
	if de>5 then
		pl.restquality = pl.restquality + 0.2
	end

	achi_set (10,pl.restquality*100)

	--game.autosave = true
	--game_save (game.savepos)
	--game.screenshot = true


end


function drink_dirt (dirt)

	if dirt==nil then return end

	if dirt>50 then
		achi_add (29,1)
	end

	if love.math.random (0,100)<30 then return end

	local r = love.math.random (0,dirt)
	if r>70 and pl.buffs[17]==nil then
		buff_add (17) --dizzy
		return
	end

	local r = love.math.random (0,dirt)
	if r>60 and pl.buffs[15]==nil then
		buff_add (15) --fever
		return
	end

	local r = love.math.random (0,dirt)
	if r>50 and pl.buffs[16]==nil then
		buff_add (16) --diarrhoea
		return
	end

	local r = love.math.random (0,dirt)
	if r>40 and pl.buffs[2]==nil then
		buff_add (2) -- poison
		return
	end

	local r = love.math.random (0,dirt)
	if r>25 and pl.buffs[3]==nil then
		buff_add (3) --food poison
		return
	end

end

function player_die ()

		pl.rest = 0
		pl.unrest = 0
		pl.isdead = true
		pl.score = math.ceil (pl.score / 2)
		pl.daylived = math.floor ((game.time - (pl.lastdeath or 0))/time.d)

		pl.lastdeath = game.time


		if actor_uses_local_presentation(pl) then
			shader:send("dying", 0)
			sound_kill ('heartbeat')
			sound_killall ()
		end

		pl.deaths = pl.deaths + 1
		pl.dying = 1
		
		if actor_uses_local_presentation(pl) then sct = {} end
--		pl.noflashlight = true

		pl.spenddead = time.h
		pl.stats.body.hp = 0

		for k,v in pairs(pl.inv) do

				if v.i~=26 and v.i~=27 and v.i~=284 and v.i~=285 then --flashlight

					local it = inv_remove(k,{noc=true})

					if item[it.i] and item[it.i].ttl then
						--it.t = it.t - math.floor (item[it.i].ttl*(pl.deaths*0.1))
					end
				
					inv_ground_add (pl.xt,pl.yt,it)
				end
			
		end


		diet_recovery (200)

		--shitting
		for i,v in ipairs(pl.shit) do
			inv_ground_add (pl.xt,pl.yt,item_make(i))
		end
		pl.shit = {}
		buff_remove (1)
		pl.unrest = time.min*5
		
		ttl_checks (game.ttl_list)
		buff_remove_all ()

		--stats_reset ()
		--inv_add (item_make(26))


end

function stats_reset ()

	pl.stats = {}
	pl.stats.arms = {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0.05, currentgrow = 0, maxgrow = 100}
	pl.stats.filth ={hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0}
	pl.stats.body = {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0.05, currentgrow = 0, maxgrow = 100}
	pl.stats.food = {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0.05, currentgrow = 0, maxgrow = 100}
	pl.stats.water= {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0.05, currentgrow = 0, maxgrow = 100}
	pl.stats.power= {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0}
	pl.stats.heat = {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0, currentgrow = 0, maxgrow = 100}

	pl.stats.faith= {hp = 0, maxhp = 100, lvl = 0, pc = 0, d = 0}

	pl.dishes = {}
	achi_ini ()
	achi_reset ()

end

function player_hit (hp,what)

	if pl.isdead then return end

	achi_trigger ('on_hit',hp)

	for k,v in pairs(pl.inv) do
		if type(k)~='number' and pl.inv[k] and item[pl.inv[k].i].onstruck then
			hp = item[pl.inv[k].i].onstruck((hp or 0),what)
			pl.inv[k].t = pl.inv[k].t - 1 --durability hit
		end
	end

	pl.digcount = -1
	stat_spend ('body',hp)
	hp = math.ceil (hp)
	if hp>=1 then
		sound_add ('hit',6,{volume = (100-pl.stats.body.pc)*0.1})
		hp = hp * (-1)
		actor_floating_text_add(pl, {
			text = text_color("{#e43b44ff}" .. hp),
			ttl = 0.8,
			xs = pl.flip * -1 * love.math.random(5, 30),
		}, love.math.random(-8, 8), -32)
	end
	-- pl.stats.body.hp = pl.stats.body.hp - hp
	--pl.stats.body.d = pl.stats.body.d - hp
end


function player_regen (hp,what)

	stat_recovery ('body',hp)
	--sound_add ('hit',6,{volume = (100-pl.stats.body.pc)*0.1})

	hp = math.ceil (hp)
	if hp>=1 then
		actor_floating_text_add(pl, {
			text = text_color("{#3e8948ff}+" .. hp),
			ttl = 1.8,
			xs = pl.flip * -1 * love.math.random(5, 30),
		}, love.math.random(-8, 8), -32)
	end

end

function reduce (a)
	if a then 
		a = a - 1
		if a<1 then a = nil end
	end
	return a
end

function diet_recovery (n)
	for k,v in pairs(cf.diet) do
		pl.diet[v] = pl.diet[v] - n
		if pl.diet[v] < 0 then pl.diet[v]=0 end
	end
end

function stat_spend (stat,h)
	-- pl.stats.arms = {hp = 100, maxhp = 100, lvl = 0}

	if h==nil then return end

	if pl.dying then 
		return
	end

	if h>=1 then
		game.lasthit = stat
	else
		game.lasthit = ""
	end


	if h>9 and stat~='body' then
		actor_floating_text_add(pl, {
			ys = 20,
			font = 2,
			text = text_color("{#f77622ff}-" .. math.floor(h)
				.. " " .. msg.stats[stat]),
			ttl = 2.1,
			xs = pl.flip * -1 * love.math.random(5, 40),
		}, love.math.random(-30, -20), -32)
	end


	pl.stats[stat].hp = pl.stats[stat].hp - h

	if
		pl.stats[stat].hp > pl.stats[stat].maxhp then
		pl.stats[stat].hp = pl.stats[stat].maxhp 
	end

	if pl.stats[stat].hp<=0 and pl.stats[stat].hp+h>0 and stat == 'arms' then
		buff_add (7,'keep')
		textwall (msg.game[43])
	end

	if stat == 'food' then
		diet_recovery (h/6)
	end

	if stat == 'body' then actor_health_presentation_update(pl) end

	if pl.stats[stat].hp<0 and stat ~= 'body' and stat~= 'power' and stat ~= 'filth' then
		if pl.unrest==0 then
			player_hit (math.ceil(-1*pl.stats[stat].hp))
		end
	end

	if pl.stats[stat].hp<0 then
		pl.stats[stat].hp = 0
	end

	pl.stats[stat].pc = math.floor (pl.stats[stat].hp/pl.stats[stat].maxhp*100)
end

function player_score (score)
	pl.score = pl.score + (score/(pl.deaths+1))
	pl.savedscore = (pl.savedscore or 0) + (score/(pl.deaths+1))
end

function stat_recovery (stat,h,arr)

	
	if stat=='power' and pl.isdead==nil then
		player_score (h*50)
		achi_set (26,math.ceil(pl.stats[stat].hp))
	end

	if (h>9 or stat=='faith') and stat~='body' and pl.isdead==nil then
		actor_floating_text_add(pl, {
			ys = 20,
			font = 2,
			text = text_color("{#63c74dff}+" .. math.floor(h)
				.. " " .. msg.stats[stat]),
			ttl = 2.1,
			xs = pl.flip * -1 * love.math.random(5, 40),
		}, love.math.random(10, 20), -32)
	end

	pl.stats[stat].hp = pl.stats[stat].hp + h

	if
		pl.stats[stat].hp > pl.stats[stat].maxhp then
		pl.stats[stat].hp = pl.stats[stat].maxhp 
	end

	if stat == 'body' then actor_health_presentation_update(pl) end

	pl.stats[stat].pc = math.floor (pl.stats[stat].hp/pl.stats[stat].maxhp*100)

	--2remove
	pl.stats[stat].currentgrow = pl.stats[stat].currentgrow or 0
	pl.stats[stat].maxgrow = pl.stats[stat].maxgrow or 100


	if pl.stats[stat].pc>30 and pl.stats[stat].pc<70 and pl.stats[stat].grow then
		local gr = pl.stats[stat].grow * h * (pl.stats[stat].hp/pl.stats[stat].maxhp)
		pl.stats[stat].currentgrow = pl.stats[stat].currentgrow + gr
		if pl.stats[stat].currentgrow<pl.stats[stat].maxgrow then
			pl.stats[stat].maxhp = pl.stats[stat].maxhp + gr
		end
	end

end



function consume_cal (it,consume)


	local bad = 0
	local i = it.i
	local age = 1-it.t/item[i].ttl
	local cal = item[i].calories

	local multi


	if pl.dishes==nil or pl.dishes[i]==nil then
		multi = true
		cal = cal*2	
	end

	age = math.floor (age * cal/2)
	cal = cal - age
	local oldcal = cal


	local cal2 = 0
	local recal = 0

	if item[i].diet and pl.buffs[11]==nil then

		--second type
		if item[i].diet[2] and item[i].diet[2]~='freezable' then

			cal2 = cal * 0.33
			cal = cal - cal2

			pl.diet[item[i].diet[2]] = pl.diet[item[i].diet[2]] or 0
			local diet = pl.diet[item[i].diet[2]] or 0

			if diet ~= 100 then bad = bad + 1 end

			diet = (130 - diet)/100
			cal2 = cal2 * diet

			if consume then
				pl.diet[item[i].diet[2]] = pl.diet[item[i].diet[2]] + cal2
				if pl.diet[item[i].diet[2]]>100 then
					pl.diet[item[i].diet[2]]=100
				end
			end

		end

		pl.diet[item[i].diet[1]] = pl.diet[item[i].diet[1]] or 0
		local diet = pl.diet[item[i].diet[1]] or 0

		if diet ~= 100 then bad = bad + 1 end

		diet = (130 - diet)/100
		cal = cal * diet


		--print (pl.diet[item[i].diet[1]])

		if consume then
			pl.diet[item[i].diet[1]] = pl.diet[item[i].diet[1]] + cal
			if pl.diet[item[i].diet[1]]>100 then
				pl.diet[item[i].diet[1]]=100
			end
		end
		
		if multi then
			cal2 = 0
			cal = oldcal
		end

		recal = cal + cal2
		
		local d = math.ceil (recal-oldcal)

		age = age*(-1)

		if d>0 then d = "+"..d end
		if age==0 then age = "" end
		if d==0 then d = "" end

		return age, d, recal, multi, bad

	end

	if consume then
		 buff_remove (11)
	end

	return "","",oldcal


end



-- -- editor chunk maps
-- function love.mousepressed (x,y,button)
-- 	if button==1 and game.dbg[2] then
		
-- 		if edit.fin then
-- 			edit = {}
-- 		end

-- 		edit.x = x
-- 		edit.y = y
-- 	end
-- end

-- function love.mousereleased (x,y,button)
-- 	if button==1 and game.dbg[2] then
-- 		edit.fin = 1
-- 		game.pause = true
-- 	end
-- end

-- function love.mousemoved (x,y)
-- 	if edit.x and not edit.fin and game.dbg[2] then
-- 		edit.w = x - edit.x
-- 		edit.h = y - edit.y
-- 		edit.x2 = x
-- 		edit.y2 = y
-- 		--dump (edit)
-- 	end
-- end



function savefiles ()

	local str = ""
	for i=1,9 do
		local info = game_save_slot_info and game_save_slot_info(i)
		str = str.."\n"
		if info==nil then
			str = str..i.."] -----------------"
		else
			str = str..i.."] "..I18N.format_datetime(msg, info.modtime)
		end
	end
	return str

end

function game_migrate ()
	ActorState.ensure(pl, {
		actor_id = "host",
		actor_role = "host",
		force_identity = true,
	})
	NetworkIdentity.ensure_world(game)

	-- Enhanced rendering is now an inherent part of the 2x scale. Discard the
	-- obsolete per-save switch left by development builds.
	game.smooth2x = nil
	for _, field in ipairs({
		"network_client", "network_tick", "network_server_tick",
		"network_clock", "network_server_time",
		"network_interpolation_delay", "network_interpolation_jitter",
		"network_render_time",
		"network_world_sequence", "network_action_id",
		"network_world_received_sequence",
		"network_last_action_result", "network_time_base",
		"network_guest_time_delta", "multiplayer_port",
		"multiplayer_prompt_session",
	}) do
		game[field] = nil
	end

	pl.inv = pl.inv or {}
	pl.invsize = pl.invsize or 9
	pl.invselect = pl.invselect or 1
	pl.stats = pl.stats or {}
	pl.visited = pl.visited or {}
	pl.ferted = pl.ferted or {}
	pl.disastercd = pl.disastercd or 0
	pl.disaster = pl.disaster or {}
	for name, config in pairs(cf.disaster or {}) do
		pl.disaster[name] = pl.disaster[name] or {
			cd = config.ini,
			cnt = 0,
		}
		pl.disaster[name].cd = pl.disaster[name].cd or config.ini
		pl.disaster[name].cnt = pl.disaster[name].cnt or 0
	end

	-- Older builds could leave items above invsize after a bag or temporary
	-- capacity buff was removed. Recover those hidden items onto the ground.
	inv_overflow()
	inv_compact ()
	achi_ini ()
	pl.stats.faith = pl.stats.faith or {hp = 0, maxhp = 100, lvl = 0, pc = 0, d = 0}

	local function visit_item_instances(accept)
		for _, instance in pairs(pl.inv or {}) do accept(instance) end
		if pl.iscarry and pl.iscarry.i then
			for _, instance in pairs(pl.iscarry.i) do accept(instance) end
		end
		for _, row in pairs(world or {}) do
			if type(row) == "table" then
				for _, cell in pairs(row) do
					if type(cell) == "table" and type(cell.i) == "table" then
						for _, instance in pairs(cell.i) do accept(instance) end
					end
				end
			end
		end
		for _, mob in pairs(mobs or {}) do
			if type(mob) == "table" and mob.carry then accept(mob.carry) end
		end
		for _, projectile in pairs(proj or {}) do
			if type(projectile) == "table" and projectile.inv then
				accept(projectile.inv)
			end
		end
	end

	ItemIdentity.migrate(game, visit_item_instances)

end


local save_slot_formats = {
	{ suffix = ".sav", compressed = false, priority = 1 },
	{ suffix = ".sav.bak", compressed = false, priority = 2 },
	{ suffix = ".save", compressed = true, priority = 3 },
}

local function save_slot_candidates(name)
	local candidates = {}
	for _, format in ipairs(save_slot_formats) do
		local filename = tostring(name) .. format.suffix
		local info = love.filesystem.getInfo(filename, "file")
		if info then
			candidates[#candidates + 1] = {
				filename = filename,
				compressed = format.compressed,
				priority = format.priority,
				info = info,
			}
		end
	end

	table.sort(candidates, function(left, right)
		local left_time = left.info.modtime or 0
		local right_time = right.info.modtime or 0
		if left_time == right_time then
			return left.priority < right.priority
		end
		return left_time > right_time
	end)

	return candidates
end

function game_save_slot_info(name)
	local candidate = save_slot_candidates(name)[1]
	if candidate then
		return candidate.info, candidate.filename
	end
	return nil
end

function game_delete_save(name)
	local removed = false
	for _, suffix in ipairs({ ".sav", ".sav.bak", ".save", ".png" }) do
		local filename = tostring(name) .. suffix
		if love.filesystem.getInfo(filename) then
			removed = love.filesystem.remove(filename) or removed
		end
	end
	return removed
end

local function write_with_backup(filename, data)
	return require("src.save_io").write_with_backup(filename, data)
end

local function decode_metasave(serialized)
	local decompressed = love.data.decompress("string", "gzip", serialized)
	local values = binser.deserialize(decompressed)
	if type(values) ~= "table" or type(values[1]) ~= "table" then
		error("invalid metadata payload")
	end
	return values[1]
end


function game_loadinfo ()
	for _, filename in ipairs({ "info.save", "info.save.bak" }) do
		local save = love.filesystem.read(filename)
		if save then
			local decoded, metasave = pcall(decode_metasave, save)
			if decoded then
				game.metasave = metasave
				return true
			end
		end
	end

	game.metasave = {}
	return false

end

function game_saveinfo_payload ()
	game.metasave = game.metasave or {}
	game.metasave.score = game.metasave.score or 0

	if pl.score>(game.metasave.hiscore or 0) then
		game.metasave.hiscore = pl.score
	end

	game.metasave.inv = pl.inv
	game.metasave.lastscore = pl.score
	game.metasave.savedscore = pl.savedscore
	game.metasave.oldtimes = game.time
	game.metasave.gamepos = game.savepos
	


	local serialized = binser.serialize(game.metasave)
	return love.data.compress("string", "gzip", serialized)
end

function game_saveinfo ()
	local encoded, save = pcall(game_saveinfo_payload)
	if not encoded then
		return false, save
	end

	return write_with_backup("info.save", save)

end



function table_save (name,a,deterministic)
	local BlobWriter = require('src.BlobWriter')
	blob = BlobWriter()
	if deterministic then
		blob:writeDeterministic(a)
	else
		blob:write(a)
	end
	local save = blob:tostring()
	love.filesystem.write (name, save)
end

function table_load (name)

	local BlobReader = require('src.BlobReader')
	local save = love.filesystem.read(name)

	a = {}
	if save then
		local blob = BlobReader(save)
		a = blob:read()
	end

	return a

end


local SAVE_SECTION_COUNT = 8

function game_save_snapshot ()
	local snapshot = {
		StateCopy.copy(world),
		StateCopy.copy(vi),
		StateCopy.copy(pl),
		StateCopy.copy(game),
		StateCopy.copy(tips),
		StateCopy.copy(disp),
		StateCopy.copy(cf),
		StateCopy.copy(mobs),
	}

	-- These fields describe an in-flight operation in the current process. They
	-- must never cause a loaded game to resume or repeat that operation.
	snapshot[4].autosave = nil
	snapshot[4].save_quitting = nil
	for _, field in ipairs({
		"network_client", "network_tick", "network_server_tick",
		"network_clock", "network_server_time",
		"network_interpolation_delay", "network_interpolation_jitter",
		"network_render_time",
		"network_world_sequence", "network_action_id",
		"network_world_received_sequence",
		"network_last_action_result", "network_time_base",
		"network_guest_time_delta", "multiplayer_port",
		"multiplayer_prompt_session",
	}) do
		snapshot[4][field] = nil
	end

	local guest = actors and actors.guest
	if guest then
		local projected, projection_error = GuestPossessions.project(guest, {
			world = snapshot[1],
			fallback_x = pl.startx,
			fallback_y = pl.starty,
		})
		if not projected then
			error("could not project guest possessions into save: "
				.. tostring(projection_error))
		end
	end
	return snapshot
end

function game_serialize_snapshot (snapshot, yield_callback, initial_size)
	if type(snapshot) ~= "table" then
		error("save snapshot must be a table")
	end

	local BlobWriter = require("src.BlobWriter")
	local blob = BlobWriter(initial_size)
	blob:setYieldCallback(yield_callback)
	for index = 1, SAVE_SECTION_COUNT do
		if type(snapshot[index]) ~= "table" then
			error("invalid save snapshot section " .. tostring(index))
		end
		blob:write(snapshot[index])
	end
	return blob:tostring()
end

function game_save (name)
	local encoded, save = pcall(function()
		local raw = game_serialize_snapshot(game_save_snapshot())
		return require("src.save_format").encode(raw)
	end)

	if not encoded then
		textwall(msg.persistence.save_failed, false)
		return false, save
	end

	local written, write_error = write_with_backup(tostring(name) .. ".sav", save)
	if not written then
		textwall(msg.persistence.save_failed, false)
		return false, write_error
	end

	game.lastsave = (game.dt or 0) + 60 * 10
	local metadata_saved, metadata_error = game_saveinfo()
	if not metadata_saved and oldprint then
		oldprint("Could not save game metadata: " .. tostring(metadata_error))
	end

	love.graphics.captureScreenshot(tostring(name) .. ".png")
	textwall(msg.game[1], false)
	return true
end


local function decode_game_save(serialized, compressed)
	serialized = require("src.save_format").decode(serialized, compressed)

	local BlobReader = require("src.BlobReader")
	local blob = BlobReader(serialized)
	local state = {
		world = blob:read(),
		vi = blob:read(),
		pl = blob:read(),
		game = blob:read(),
		tips = blob:read(),
		disp = blob:read(),
		saved_cf = blob:read(),
		mobs = blob:read(),
	}

	for _, key in ipairs({ "world", "vi", "pl", "game", "tips", "disp", "saved_cf", "mobs" }) do
		if type(state[key]) ~= "table" then
			error("invalid " .. key .. " section")
		end
	end
	if next(state.world) == nil then
		error("empty world section")
	end

	return state
end

local function activate_game_save(state)
	local previous = {
		world = world,
		vi = vi,
		pl = pl,
		game = game,
		tips = tips,
		disp = disp,
		ncf = ncf,
		mobs = mobs,
	}

	world = state.world
	vi = state.vi
	pl = state.pl
	if actors then actors:bind_host(pl, vi) end
	game = state.game
	tips = state.tips
	disp = state.disp
	ncf = state.saved_cf
	mobs = state.mobs

	local migrated, migration_error = pcall(function()
		game_migrate()
		game_loadinfo()
		game.lastsave = (game.dt or 0) + 60 * 10
		game.craft = false
	end)
	if migrated then
		return true
	end

	world = previous.world
	vi = previous.vi
	pl = previous.pl
	if actors then actors:bind_host(pl, vi) end
	game = previous.game
	tips = previous.tips
	disp = previous.disp
	ncf = previous.ncf
	mobs = previous.mobs
	return false, migration_error
end

function game_load (name)
	local errors = {}
	local candidates = save_slot_candidates(name)
	if #candidates == 0 then
		return false, "save slot is empty"
	end

	for _, candidate in ipairs(candidates) do
		local save, read_error = love.filesystem.read(candidate.filename)
		if save then
			local decoded, state = pcall(decode_game_save, save, candidate.compressed)
			if decoded then
				local activated, activation_error = activate_game_save(state)
				if activated then
					return true
				end
				errors[#errors + 1] = candidate.filename .. ": " .. tostring(activation_error)
			else
				errors[#errors + 1] = candidate.filename .. ": " .. tostring(state)
			end
		else
			errors[#errors + 1] = candidate.filename .. ": " .. tostring(read_error)
		end
	end

	return false, table.concat(errors, "; ")
end
	

function ini_quad ()

	if IS_DEVELOPMENT then
		--collecting quad
		local files = love.filesystem.getDirectoryItems('/assets/sprites')
		local images = {}

		for i,v in ipairs(files) do
			if v~=".DS_Store" then
				local f = {}
				f.name = v
				f.img = love.graphics.newImage ("assets/sprites/"..v)
				f.w, f.h = f.img:getPixelDimensions( )
				table.insert (images,f)
			end
		end

		table.sort (images, function (k1,k2) 
		if k1.h~=k2.h then
			return k1.h > k2.h 
		else
			return k1.name < k2.name
		end

		end)

		quadlist = {}
		local cnt = 1
		local x = 1
		local y = 1
		local nl = 0
		local dimmax = 1024
		-- The atlas is a source texture, not a display-sized render target.
		-- Letting a Retina window apply its DPI scale here creates a 2048x2048
		-- image while quad coordinates still describe a 1024x1024 atlas. Every
		-- sprite is then sampled from the wrong rectangle (the title and menu
		-- animation are the most obvious casualties).
		quad = love.graphics.newCanvas(dimmax,dimmax,{dpiscale = 1})
		love.graphics.setCanvas(quad)

		for i,v in ipairs(images) do

			if x + v.w > dimmax then
				x = 1
				y = y + nl + 1
				nl = 0
			end

			if nl==0 then
				nl = v.h
			end

			assert(y + v.h <= dimmax, "sprite atlas overflow at "..v.name)

			love.graphics.draw (v.img,x,y)
			quadlist[v.name] = 
			{
				x = x,
				y = y,
				w = v.w,
				h = v.h,
			}

			x = x + v.w + 1

		end

		table_save ('quad.table',quadlist,true)

		love.graphics.setCanvas()
		local atlas_data = quad:newImageData()
		filedata = atlas_data:encode('png','quad.png')
		quad = love.graphics.newImage(atlas_data)
		images = nil

	else

		-- Generated development atlases live in the writable save directory.
		-- A fused macOS app uses a different source mount but the same identity,
		-- so generic quad.* names can be shadowed by stale or incomplete files.
		-- Release-only names make these reads resolve to the bundled archive.
		quadlist = table_load ('sprite-atlas-v1.table')
		quad = love.graphics.newImage('sprite-atlas-v1.png')

	end

end
	


function spiral_ini (x,y)

	spiral = {

		dir = {
			{1,0},
			{0,1},
			{-1,0},
			{0,-1},
		},

		dir_n = 1,
		step = 1,
		step_l = 1,
		x = x,
		y = y,
		it = 0

	}

end


function spiral_spin (maxstep)

	spiral.it = spiral.it + 1
	if spiral.dir_n>4 then 
		spiral.dir_n = 1
		spiral.step = spiral.step + 2
		spiral.step_l = spiral.step 
		spiral.x = spiral.x-1
		spiral.y = spiral.y-1
	end

	local d = love.math.random (1,maxstep)

	if d>spiral.step_l then
		d = spiral.step_l
	end

	spiral.step_l = spiral.step_l - d

	spiral.x = spiral.x+spiral.dir[spiral.dir_n][1]*d
	spiral.y = spiral.y+spiral.dir[spiral.dir_n][2]*d

	if spiral.step_l<1 then
		spiral.dir_n = spiral.dir_n + 1 
		spiral.step_l = spiral.step 
	end

	return spiral.x, spiral.y, spiral.it


end

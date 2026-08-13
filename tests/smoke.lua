local smoke = {}
local gameplay_keypressed = love.keypressed

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

local function background_minimize_enabled()
	return os.getenv("SARCOPHAGUS_TEST_BACKGROUND") == "1"
		and os.getenv("SARCOPHAGUS_TEST_NO_MINIMIZE") ~= "1"
end

local function process_test_actor(registry)
	local ActorState = require("src.actor_state")
	local host = ActorState.new({ actor_id = "host", actor_role = "host" })
	host.inv = {}
	host.invsize = 9
	host.invselect = 1
	host.unlock_i = {}
	host.unlock_c = {}
	host.visited = {}
	host.ferted = {}
	host.quests = {}
	host.stats = { body = { hp = 100, maxhp = 100, pc = 100, d = 0 } }
	host.state = "idle"
	host.oldstate = "idle"
	host.truex, host.truey = 32, 64
	host.tx, host.ty, host.xt, host.yt = 2, 3, 2, 3
	registry:bind_host(host, {})
	return host
end

local function install_process_network_test(role, value)
	local ActorRegistry = require("src.actor_registry")
	local InputState = require("src.input_state")
	local LANDiscovery = require("src.network.discovery")
	local Replication = require("src.network.replication")
	local Runtime = require("src.network.runtime")
	local Session = require("src.network.session")
	local port_value, discovery_value = value:match("^(%d+),(%d+)$")
	local port = tonumber(port_value or value)
	local discovery_port = tonumber(discovery_value)
	assert(port and port >= 1 and port <= 65535 and port == math.floor(port),
		"invalid process-test port")
	assert(discovery_port == nil or (discovery_port >= 1
		and discovery_port <= 65535 and discovery_port == math.floor(discovery_port)),
		"invalid process-test discovery port")

	io.stdout:setvbuf("no")
	io.stderr:setvbuf("no")
	love.draw = function() end
	-- multiplayer_apply_snapshot restores the gameplay callback from
	-- love.old_draw. Keep both aliases headless in this process harness.
	love.old_draw = function() end
	local elapsed = 0
	local finished = false
	local runtime
	local function complete(code, details)
		if finished then return end
		finished = true
		if runtime and runtime.role ~= "offline" then runtime:prepare_quit() end
		finish(code, "mode=network-process-" .. role .. " " .. details)
	end
	local function guard(callback)
		love.update = function(dt)
			if finished then return end
			local ok, err = pcall(callback, dt)
			if not ok then complete(1, tostring(err)) end
		end
	end

	local registry = ActorRegistry.new()
	local host_actor = process_test_actor(registry)
	local world_id = string.rep("a", 64)
	local process_content_hash = string.rep("b", 64)
	local discovery_mode = os.getenv("SARCOPHAGUS_PROCESS_DISCOVERY")
	local multicast_discovery = discovery_mode == "multicast"
	local broadcast_discovery = discovery_mode == "broadcast"
	local forced_disconnect = (tonumber(os.getenv(
		"SARCOPHAGUS_NET_DISCONNECT_AFTER"
	)) or 0) > 0
	local crash_role = os.getenv("SARCOPHAGUS_PROCESS_CRASH_ROLE")
	local crash_phase = os.getenv("SARCOPHAGUS_PROCESS_CRASH_PHASE")
	local crash_test = crash_role == "host" or crash_role == "client"
	local crash_target = crash_test and crash_role == role
	local expect_peer_crash = crash_test and crash_role ~= role
	local idle_seconds = math.max(0, tonumber(os.getenv(
		"SARCOPHAGUS_PROCESS_IDLE_SECONDS"
	)) or 0)
	local idle_test = idle_seconds > 0
	local peer_observed = false
	local function announce_crash_ready()
		io.stdout:write("SARCOPHAGUS_PROCESS_CRASH_READY role=" .. role
			.. " phase=" .. tostring(crash_phase) .. "\n")
		local trigger_path = assert(os.getenv("SARCOPHAGUS_PROCESS_CRASH_TRIGGER"),
			"crash trigger path is required")
		while true do
			local trigger = io.open(trigger_path, "rb")
			if trigger then
				trigger:close()
				os.exit(86)
			end
			love.timer.sleep(0.05)
		end
	end
	local reconnect_backlog = math.max(2, math.floor(tonumber(os.getenv(
		"SARCOPHAGUS_PROCESS_RECONNECT_BACKLOG"
	)) or 2))
	local process_timeout = (crash_test and 18
		or (reconnect_backlog > 2 and 25 or 12)) + idle_seconds + 2
	if role == "host" then
		local action_seen, input_seen = false, false
		local idle_input_seen = not idle_test
		local idle_probe_seen = false
		local delta_sequence, event_sequence = 0, 0
		local completion_elapsed
		local reconnect_seen, reconnect_completed = false, not forced_disconnect
		runtime = Runtime.new({
			registry = registry,
			max_poll_events = crash_test and 1 or nil,
			heartbeat_interval = (crash_test or idle_test) and 0.5 or nil,
			heartbeat_timeout = (crash_test or idle_test) and 4 or nil,
			reconnect_timeout = crash_test and 5 or nil,
			state_interval = 0.01,
			progress_interval = 0.1,
			world_interval = 0.01,
			spawn_provider = function()
				return { truex = 96, truey = 128, tx = 4, ty = 5, xt = 4, yt = 5 }
			end,
			state_provider = function(session)
				if crash_target and crash_phase == "snapshot" then
					announce_crash_ready()
				end
				return {
					world = { [1] = { [1] = { b = 0 } } },
					game = { world_id = world_id, time = 7 },
					host_actor = host_actor,
					guest_actor = session.guest,
					tips = {}, disp = {}, mobs = {}, tick = 11,
					world_id = world_id,
					session_id = session.session_id,
				}
			end,
			dropper = function() return true end,
			simulation_handler = function(guest, input)
				if InputState.is_down(input, "d") then
					input_seen = true
					guest.truex = (guest.truex or 0) + 1
				elseif idle_test and input_seen then
					idle_input_seen = true
				end
			end,
			action_handler = function(_, action)
				if idle_test and action.action == "process-idle-complete" then
					idle_probe_seen = true
					return true
				end
				action_seen = action.action == "process-test"
				return action_seen
			end,
			replication_provider = function(session, include_progress)
				return {
					tick = 12,
					input_seen = input_seen,
					action_seen = action_seen,
					progress = include_progress and true or nil,
					guest_actor = Replication.capture_actor(session.guest),
				}
			end,
			world_delta_provider = function()
				local wanted = forced_disconnect and reconnect_seen
					and reconnect_backlog or 1
				if delta_sequence >= wanted then return nil end
				delta_sequence = delta_sequence + 1
				return {
					sequence = delta_sequence,
					tick = 12,
					cells = {
						{ x = 1, y = 1, cell = {
							b = delta_sequence,
						} },
					},
				}
			end,
			event_provider = function()
				local wanted = forced_disconnect and reconnect_seen
					and reconnect_backlog or 1
				local reconnect_backlog_ready = forced_disconnect and reconnect_seen
				if event_sequence >= wanted
					or (not reconnect_backlog_ready and not action_seen) then
					return nil
				end
				event_sequence = event_sequence + 1
				return {
					kind = "process-test",
					event_id = event_sequence,
					value = event_sequence,
				}
			end,
		})
		assert(runtime:start_host({
			host = multicast_discovery and "*" or "127.0.0.1",
			port = port,
			last_port = port,
				discovery = discovery_port ~= nil,
				discovery_port = discovery_port,
			game_version = "process-test",
			content_hash = process_content_hash,
			world_id = world_id,
		}))
		io.stdout:write("SARCOPHAGUS_PROCESS_HOST_READY port=" .. port .. "\n")
		guard(function(dt)
			elapsed = elapsed + dt
			runtime:update(dt)
			peer_observed = peer_observed or runtime.peer ~= nil
				or runtime.session.state ~= Session.STATE.LISTENING
			if crash_target then
				local expected_state = crash_phase == "handshake"
					and Session.STATE.AWAITING_APPROVAL
					or crash_phase == "catchup" and Session.STATE.CATCHING_UP
					or crash_phase == "playing" and Session.STATE.PLAYING
				if expected_state and runtime.session.state == expected_state then
					announce_crash_ready()
				end
			end
			if expect_peer_crash and peer_observed and runtime.last_error
				and (runtime.last_error == "transport_disconnect"
					or runtime.last_error == "heartbeat_timeout") then
				local expected_state = crash_phase == "handshake"
					and Session.STATE.LISTENING or Session.STATE.RECONNECT_GRACE
				if runtime.session.state == expected_state then
					complete(0, "peer_crash=true phase=" .. crash_phase
						.. " survivor_state=" .. runtime.session.state)
					return
				end
			end
			if idle_test and idle_probe_seen
				and (runtime.session.state == Session.STATE.LISTENING
					or runtime.session.state == Session.STATE.RECONNECT_GRACE) then
				complete(0, "handshake=true input=true action=true reconnect="
					.. tostring(reconnect_seen) .. " idle=true")
				return
			end
			if runtime.session.state == Session.STATE.RECONNECT_GRACE then
				reconnect_seen = true
			elseif reconnect_seen and runtime.session.state == Session.STATE.PLAYING then
				reconnect_completed = true
			end
			if runtime:pending_approval() then assert(runtime:approve_guest()) end
			local wanted = forced_disconnect and reconnect_backlog or 1
			if action_seen and input_seen and idle_input_seen and reconnect_completed
				and runtime.world_acked_sequence >= wanted
				and runtime.event_acked_id >= wanted then
				completion_elapsed = completion_elapsed or elapsed
				if not idle_test and elapsed - completion_elapsed >= 0.75 then
					complete(0, "handshake=true input=true action=true reconnect="
						.. tostring(reconnect_seen)
						.. " idle=" .. tostring(idle_test))
				end
			end
			if elapsed > process_timeout then
				local status = runtime:status()
				complete(1, "timeout state=" .. tostring(runtime.session.state)
					.. " resume=" .. tostring(runtime.resume_phase)
					.. " world=" .. tostring(status.streams.world_acked)
					.. "/" .. tostring(status.streams.world_highest)
					.. " event=" .. tostring(status.streams.event_acked)
					.. "/" .. tostring(status.streams.event_highest))
			end
		end)
	else
		local snapshot_seen, replicated, progress_seen, world_delta, action_result, network_event
		local discovery_requested = discovery_port ~= nil
		local discovery_seen = not discovery_requested
		local action_sent = false
		local idle_probe_sent = false
		local idle_probe_result
		local process_input
		local input_released = not idle_test
		local next_input_send = 0
		local completion_elapsed
		local reconnect_seen, reconnect_completed = false, not forced_disconnect
		local resume_barrier_verified = not forced_disconnect
		runtime = Runtime.new({
			registry = registry,
			max_poll_events = crash_test and 1 or nil,
			heartbeat_interval = (crash_test or idle_test) and 0.5 or nil,
			heartbeat_timeout = (crash_test or idle_test) and 4 or nil,
			reconnect_timeout = crash_test and 5 or nil,
			state_interval = 0.01,
			world_interval = 0.01,
			state_applier = function(snapshot)
				snapshot_seen = snapshot.header.tick == 11
				registry:bind_host(snapshot.host_actor, {})
				registry:bind_guest(snapshot.guest_actor, { local_actor = true })
			end,
			replication_applier = function(state)
				replicated = state
				progress_seen = progress_seen or state.progress == true
			end,
			world_delta_applier = function(delta) world_delta = delta end,
			action_result_handler = function(result)
				if idle_test and result.action_id == 2 then
					idle_probe_result = result
				else
					action_result = result
				end
			end,
			event_handler = function(value)
				network_event = value
				return value.kind == "process-test"
					and value.value == value.event_id
			end,
		})
		local function connect(address, gameplay_port)
			return runtime:connect({
				host = address,
				port = gameplay_port,
				game_version = "process-test",
				content_hash = process_content_hash,
			})
		end
		if discovery_port then
			assert(runtime:start_browsing({
				port = discovery_port,
				game_version = "process-test",
				content_hash = process_content_hash,
				destinations = broadcast_discovery
					and { LANDiscovery.BROADCAST } or nil,
			}))
			if not multicast_discovery and not broadcast_discovery then
				assert(runtime.browser:refresh("127.0.0.1", discovery_port))
			end
		else
			assert(connect("127.0.0.1", port))
		end
		guard(function(dt)
			elapsed = elapsed + dt
			runtime:update(dt)
			peer_observed = peer_observed or runtime.peer ~= nil
				or runtime.client_state ~= "connecting"
			if crash_target then
				local expected_state = crash_phase == "handshake"
					and "awaiting_approval"
					or crash_phase == "snapshot" and "receiving_snapshot"
					or crash_phase == "catchup" and "catching_up"
					or crash_phase == "playing" and "playing"
				if expected_state and runtime.client_state == expected_state then
					announce_crash_ready()
				end
			end
			if expect_peer_crash and peer_observed and runtime.last_error
				and (runtime.client_state == "reconnecting"
					or runtime.client_state == "disconnected") then
				complete(0, "peer_crash=true phase=" .. crash_phase
					.. " survivor_state=" .. runtime.client_state)
				return
			end
			if runtime.client_state == "reconnecting"
				or runtime.client_state == "resuming"
				or runtime.client_state == "resuming_sync" then
				reconnect_seen = true
			elseif reconnect_seen and runtime.client_state == "playing" then
				reconnect_completed = true
				assert(world_delta and world_delta.sequence == reconnect_backlog
					and network_event
					and network_event.event_id == reconnect_backlog,
					"client resumed play before applying the reconnect backlog")
				resume_barrier_verified = true
			end
			if discovery_port and runtime.role == "offline" then
				local records = runtime:servers()
				if records[1] then
					discovery_seen = (multicast_discovery or broadcast_discovery
						or records[1].address == "127.0.0.1")
						and records[1].gameplay_port == port
					assert(discovery_seen, "discovery returned an invalid host record")
					local connect_address = broadcast_discovery
						and "127.0.0.1" or records[1].address
					assert(connect(connect_address, records[1].gameplay_port))
				end
			end
			if runtime.client_state == "playing" then
				if not action_sent then
					assert(runtime:send_action({
						action_id = 1,
						action = "process-test",
					}))
					action_sent = true
				end
				if (not replicated or not replicated.input_seen)
					and elapsed >= next_input_send then
					process_input = process_input or InputState.new()
					InputState.set_button(process_input, "d", true)
					InputState.advance(process_input)
					assert(runtime:send_input(process_input))
					next_input_send = elapsed + 0.05
				elseif idle_test and not input_released and process_input then
					InputState.set_button(process_input, "d", false)
					InputState.advance(process_input)
					assert(runtime:send_input(process_input))
					input_released = true
				end
			end
			local wanted = forced_disconnect and reconnect_backlog or 1
			if input_released and reconnect_completed and resume_barrier_verified
				and discovery_seen and snapshot_seen
				and replicated and replicated.input_seen
				and replicated.action_seen and progress_seen and world_delta
				and world_delta.sequence == wanted
				and world_delta.cells[1].cell.b == wanted
				and action_result and action_result.ok and network_event
				and network_event.event_id == wanted
				and network_event.value == wanted then
				completion_elapsed = completion_elapsed or elapsed
				if idle_test and not idle_probe_sent
					and elapsed - completion_elapsed >= idle_seconds then
					assert(runtime:send_action({
						action_id = 2,
						action = "process-idle-complete",
					}))
					idle_probe_sent = true
				elseif (idle_test and idle_probe_result and idle_probe_result.ok)
					or (not idle_test
						and elapsed - completion_elapsed >= 0.25) then
					complete(0,
						"snapshot=true state=true progress=true world=true action_result=true event=true discovery="
							.. tostring(discovery_requested and discovery_seen)
							.. " reconnect=" .. tostring(reconnect_seen)
							.. " idle=" .. tostring(idle_test))
				end
			end
			if runtime.client_state == "failed" or runtime.client_state == "rejected" then
				complete(1, "state=" .. tostring(runtime.client_state)
					.. " error=" .. tostring(runtime.last_error))
			end
			if elapsed > process_timeout then
				complete(1, "timeout state=" .. tostring(runtime.client_state)
					.. " error=" .. tostring(runtime.last_error)
					.. " world=" .. tostring(runtime.received_world_sequence)
					.. " event=" .. tostring(runtime.received_event_id))
			end
		end)
	end
end

local function install_process_gameplay_test(role, value)
	local InputState = require("src.input_state")
	local Session = require("src.network.session")
	local port = tonumber(tostring(value):match("^(%d+)"))
	assert(port and port >= 1 and port <= 65535, "invalid gameplay process port")

	local identity = "sarcophagus-gameplay-process-" .. role .. "-" .. port
	love.filesystem.setIdentity(identity)
	game_delete_save(8)
	game_delete_save(9)
	local fixture, fixture_error = love.filesystem.read("tests/fixtures/9.sav")
	assert(fixture, "cannot read gameplay process fixture: " .. tostring(fixture_error))
	assert(love.filesystem.write("9.sav", fixture), "cannot stage gameplay fixture")
	assert(game_load(9), "cannot load gameplay process fixture")
	actors:bind_host(pl, vi)

	love.draw = function() end
	-- Snapshot activation restores love.draw from this alias.
	love.old_draw = function() end
	-- smoke.install suppresses physical input before love.load. Network actions
	-- must still invoke the production gameplay callback captured at module load.
	love.old_keypressed = gameplay_keypressed
	io.stdout:setvbuf("no")
	io.stderr:setvbuf("no")
	local elapsed = 0
	local finished = false
	local content_hash = string.rep("d", 64)
	local fault_disconnect_after = tonumber(os.getenv(
		"SARCOPHAGUS_NET_DISCONNECT_AFTER"
	)) or 0
	local reconnect_required = fault_disconnect_after > 0
	local reconnect_seen = false
	local function complete(code, details)
		if finished then return end
		finished = true
		if multiplayer and multiplayer.role ~= "offline" then
			multiplayer:prepare_quit()
		end
		finish(code, "mode=multiplayer-gameplay-process-" .. role .. " " .. details)
	end
	local function guard(callback)
		local guarded_update = function(frame_dt)
			if finished then return end
			dt = frame_dt
			local ok, err = pcall(callback, frame_dt)
			if not ok then complete(1, tostring(err)) end
		end
		love.update = guarded_update
		-- multiplayer_apply_snapshot restores the gameplay alias. Point it at the
		-- harness too so the state machine survives snapshot activation.
		love.old_update = guarded_update
	end
	local function tagged(container, tag)
		for slot, instance in pairs(container or {}) do
			if type(instance) == "table" and instance.e2e_role == tag then
				return instance, slot
			end
		end
	end
	local function ground_tag(x, y, tag)
		local cell = world[y] and world[y][x]
		return tagged(cell and cell.i, tag)
	end
	local function projectile_tag(tag)
		for _, projectile in pairs(proj or {}) do
			if type(projectile) == "table" and type(projectile.inv) == "table"
				and projectile.inv.e2e_role == tag then
				return projectile
			end
		end
	end
	local function tagged_item(item_id, tag)
		local instance = assert(item_make(item_id))
		instance.e2e_role = tag
		return instance
	end

	if role == "host" then
		local original_state_provider = multiplayer.state_provider
		local original_action_handler = multiplayer.action_handler
		local seeded = false
		local arena_x, arena_y, target_x, target_y
		local contention_done = false
		local far_cameras_seen = false
		local thrown_seen = false
		local autosave_done = false
		local guest_respawned = false
		local host_respawned = false
		local reunion_done = false
		local reconnect_backlog_seeded = not reconnect_required
		local reconnect_world_start, reconnect_event_start
		local saved_guest_uids = {}
		local host_deaths_before
		local craft_open_seen, craft_return_seen, craft_recipe_selected
		local craft_recipe_count, craft_inventory
		local client_done_at
		local max_throw_charge = 0

		local host_x = tonumber(pl.xt) or math.floor(cf.wmax / 2)
		local host_y = tonumber(pl.yt) or math.floor(cf.wmax / 2)
		arena_x = host_x + screen.x + 12
		if arena_x > cf.wmax - 4 then arena_x = host_x - screen.x - 12 end
		arena_x = math.max(4, math.min(cf.wmax - 4, arena_x))
		arena_y = math.max(4, math.min(cf.wmax - 4, host_y))
		local guest_truex = (arena_x - 1) * cf.w + 16
		local guest_truey = (arena_y - 1) * cf.h + 6
		local spawn = {
			truex = guest_truex,
			truey = guest_truey,
			tx = arena_x, ty = arena_y, xt = arena_x, yt = arena_y,
			x = (arena_x - 1 - vi.xtile) * cf.w - vi.xoffset + 16,
			y = (arena_y - 1 - vi.ytile) * cf.h - vi.yoffset + 6,
		}
		multiplayer.spawn_provider = function() return StateCopy.copy(spawn) end

		local function seed_world(session)
			if seeded then return end
			seeded = true
			local guest = assert(session.guest)
			target_x, target_y = arena_x + 1, arena_y
			for y = arena_y - 2, arena_y do
				for x = arena_x - 2, arena_x + 3 do
					world[y][x] = { b = 0 }
				end
			end
			for x = arena_x - 2, arena_x + 3 do
				world[arena_y + 1][x] = createblock(1)
			end
			world[target_y][target_x] = createblock(2)
			guest.inv = {
				[1] = tagged_item(2, "craft-stick-a"),
				[2] = tagged_item(2, "craft-stick-b"),
				[3] = tagged_item(104, "craft-thread"),
			}
			guest.invsize = math.max(12, tonumber(guest.invsize) or 0)
			guest.invselect = 1
			guest.unlock_i = guest.unlock_i or {}
			guest.unlock_i[2] = true
			guest.unlock_i[104] = true
			guest.iscarry = createblock(12)
			guest.candrop = 1
			guest.flip = 1
			local contest = tagged_item(31, "contest")
			local pickup = tagged_item(31, "pickup")
			assert(inv_ground_add(arena_x, arena_y, contest, { groundlast = true }))
			assert(inv_ground_add(arena_x, arena_y, pickup, { groundlast = true }))
			host_deaths_before = tonumber(pl.deaths) or 0
		end

		multiplayer.state_provider = function(session)
			seed_world(session)
			return original_state_provider(session)
		end
		multiplayer.action_handler = function(actor, payload)
			if payload.action == "e2e-complete" then
				client_done_at = elapsed
				return true
			end
			if not contention_done and payload.action == "pickup" then
				local contest, index = ground_tag(arena_x, arena_y, "contest")
				if contest and payload.item_uid == contest.uid then
					local won = assert(inv_ground_remove(arena_x, arena_y, index))
					assert(inv_ground_add(pl.xt, pl.yt, won, { groundlast = true }))
					writemap(target_x, target_y, 0, "clear")
					contention_done = true
				end
			end
			if payload.action == "key"
				and (payload.scancode == "c" or payload.key == "c") then
				local _, ingredient_slot = tagged(actor.inv, "craft-stick-a")
				assert(ingredient_slot, "craft ingredient selection is missing")
				actor.invselect = ingredient_slot
			end
			local accepted, action_error = original_action_handler(actor, payload)
			if accepted and payload.action == "key"
				and (payload.scancode == "c" or payload.key == "c") then
				craft_open_seen = true
				local actor_runtime = assert(actors:runtime(actor))
				local craft_ui = actor_runtime.presentation.local_ui.craft
				craft_recipe_count = #(craft_ui.item_recipies or {})
				local ids = {}
				for slot, instance in pairs(actor.inv or {}) do
					ids[#ids + 1] = tostring(slot) .. ":" .. tostring(instance.i)
				end
				table.sort(ids)
				craft_inventory = table.concat(ids, ",")
				for position, recipe_id in ipairs(craft_ui.item_recipies or {}) do
					local recipe = craft.recipies[recipe_id]
					if recipe and recipe.result and recipe.result[349] then
						craft_ui.pointer = position
						craft_recipe_selected = recipe_id
						break
					end
				end
			end
			if accepted and payload.action == "key"
				and (payload.scancode == "return" or payload.key == "return") then
				craft_return_seen = true
				local crafted = false
				for _, instance in pairs(actor.inv or {}) do
					crafted = crafted or instance.i == 349
				end
				if crafted and not tagged(actor.inv, "equip") then
					actor.inv[4] = tagged_item(264, "equip")
					actor.inv[5] = tagged_item(31, "drop")
					actor.inv[6] = tagged_item(31, "throw")
				end
			end
			return accepted, action_error
		end

		assert(multiplayer:start_host({
			host = "127.0.0.1",
			port = port,
			last_port = port,
			discovery = false,
			game_version = "gameplay-process",
			content_hash = content_hash,
			world_id = NetworkIdentity.ensure_world(game),
		}))
		if reconnect_required then
			-- The gameplay reconnect scenario arms the fault on the client only,
			-- after the initial snapshot has reached PLAYING. Otherwise a fast
			-- timer can test snapshot restart instead of a real gameplay backlog.
			multiplayer.transport.faults.disconnect_after = 0
		end
		io.stdout:write("SARCOPHAGUS_PROCESS_HOST_READY port=" .. port .. "\n")

		local function snapshot_uid_count(value, uid, seen)
			if type(value) ~= "table" then return 0 end
			seen = seen or {}
			if seen[value] then return 0 end
			seen[value] = true
			local count = value.uid == uid and 1 or 0
			for key, nested in pairs(value) do
				if key ~= "uid" then count = count + snapshot_uid_count(nested, uid, seen) end
			end
			return count
		end

		guard(function(frame_dt)
			elapsed = elapsed + frame_dt
			game.network_clock = (tonumber(game.network_clock) or 0) + frame_dt
			game.network_tick = (tonumber(game.network_tick) or 0) + 1
			multiplayer:update(frame_dt)
			if multiplayer_finalize_shared_time then multiplayer_finalize_shared_time() end
			if multiplayer:pending_approval() then assert(multiplayer:approve_guest()) end
			local session = multiplayer.session
			if session and session.state == Session.STATE.RECONNECT_GRACE then
				reconnect_seen = true
				if not reconnect_backlog_seeded then
					reconnect_world_start = multiplayer.world_highest_sequence
					reconnect_event_start = multiplayer.event_highest_id
					for index = 1, 16 do
						local backlog_x = 2 + ((index - 1) % 4)
						local backlog_y = 2 + math.floor((index - 1) / 4)
						writemap(backlog_x, backlog_y, index % 2 == 0 and 1 or 2)
						assert(multiplayer_queue_text_event(
							"e2e-reconnect-backlog-" .. index,
							false,
							"guest"
						))
					end
					reconnect_backlog_seeded = true
				end
			end
			local guest = session and session.guest
			local guest_runtime = guest and actors:runtime(guest)
			max_throw_charge = math.max(
				max_throw_charge,
				tonumber(guest_runtime and guest_runtime.presentation.local_ui.game
					and guest_runtime.presentation.local_ui.game.throwcd)
					or 0
			)
			if guest and session.state == Session.STATE.PLAYING then
				local cameras = multiplayer_active_cameras()
				if #cameras == 2 and math.abs((pl.xt or 0) - (guest.xt or 0)) > screen.x then
					far_cameras_seen = true
				end
				thrown_seen = thrown_seen or projectile_tag("throw") ~= nil
				local built = world[target_y] and world[target_y][target_x]
					and world[target_y][target_x].b == 12 and guest.iscarry == nil
				local crafted = false
				for _, instance in pairs(guest.inv or {}) do
					crafted = crafted or instance.i == 349
				end
				local equipped = guest.inv and guest.inv.b
					and guest.inv.b.e2e_role == "equip"
				local dropped = ground_tag(arena_x, arena_y, "drop") ~= nil
				local picked = tagged(guest.inv, "pickup") ~= nil
				local contested = ground_tag(pl.xt, pl.yt, "contest") ~= nil
				if built and crafted and equipped and dropped and picked and contested
					and thrown_seen and far_cameras_seen and contention_done
					and (not reconnect_required or reconnect_seen) then
					if not autosave_done then
						for slot = 1, guest.invsize do
							if guest.inv[slot] == nil then
								guest.inv[slot] = tagged_item(31, "autosave-" .. slot)
							end
						end
						guest.iscarry = createblock(12)
						for _, instance in pairs(guest.inv) do
							saved_guest_uids[#saved_guest_uids + 1] = instance.uid
						end
						local snapshot = game_save_snapshot()
						assert(guest.iscarry and guest.iscarry.b == 12,
							"autosave mutated the live carried block")
						for _, uid in ipairs(saved_guest_uids) do
							assert(snapshot_uid_count(snapshot, uid) == 1,
								"autosave lost or duplicated guest item " .. uid)
						end
						assert(game_save(8), "could not persist gameplay E2E save")
						autosave_done = true
						guest.stats.body.hp = 0
					end
				end
				if autosave_done and (tonumber(guest.network_deaths) or 0) >= 1 then
					guest_respawned = true
				end
				if guest_respawned and not host_respawned then
					player_die()
					assert(pl.isdead and (tonumber(pl.deaths) or 0) == host_deaths_before + 1,
						"host death path did not update authoritative state")
					assert(player_respawn() and not pl.isdead,
						"host respawn path did not restore the player")
					host_respawned = true
				end
				if host_respawned and not reunion_done then
					guest.truex, guest.truey = pl.truex + cf.w, pl.truey
					guest.tx, guest.ty = pl.tx + 1, pl.ty
					guest.xt, guest.yt = pl.xt + 1, pl.yt
					reunion_done = true
				end
			end
			local backlog_acked = reconnect_backlog_seeded
				and (not reconnect_required or (
					multiplayer.world_acked_sequence > reconnect_world_start
					and multiplayer.event_acked_id >= reconnect_event_start + 16
				))
			if autosave_done and host_respawned and reunion_done and client_done_at
				and backlog_acked
				and elapsed - client_done_at >= 1.5 then
				assert(game_load(8), "saved gameplay E2E world could not be reloaded")
				local loaded = { world, game }
				for _, uid in ipairs(saved_guest_uids) do
					assert(snapshot_uid_count(loaded, uid) == 1,
						"reloaded world lost or duplicated guest item " .. uid)
				end
				complete(0, "build=true contention=true craft=true equipment=true drop=true throw=true deaths=true cameras=true autosave=true reload=true real_backlog=" .. tostring(backlog_acked) .. " reconnect=" .. tostring(reconnect_seen))
			end
			if elapsed > 45 then
				local guest_runtime = session and session.guest
					and actors:runtime(session.guest)
				local craft_ui = guest_runtime and guest_runtime.presentation.local_ui.craft
				local guest = session and session.guest
				local selected = guest and guest.inv
					and guest.inv[guest.invselect]
				complete(1, "timeout state=" .. tostring(session and session.state)
					.. " seeded=" .. tostring(seeded)
					.. " autosave=" .. tostring(autosave_done)
					.. " deaths=" .. tostring(guest_respawned and host_respawned)
					.. " reconnect=" .. tostring(reconnect_seen)
					.. " craft=" .. tostring(craft_open_seen)
						.. "/" .. tostring(craft_return_seen)
						.. "/" .. tostring(craft_recipe_selected)
						.. " pointer=" .. tostring(craft_ui and craft_ui.pointer)
						.. " recipes=" .. tostring(craft_recipe_count)
						.. " inv=" .. tostring(craft_inventory)
					.. " throw=" .. tostring(guest and guest.throw)
						.. "/" .. tostring(guest and guest.canthrow)
						.. "/" .. tostring(guest and guest.throwcd)
						.. "/" .. tostring(selected and selected.e2e_role)
						.. "/" .. tostring(guest_runtime
							and guest_runtime.presentation.local_ui.game
							and guest_runtime.presentation.local_ui.game.throwcd)
						.. "/max:" .. tostring(max_throw_charge)
					.. " input_r=" .. tostring(guest_runtime and InputState.is_down(
						guest_runtime.input,
						"r"
					))
					.. " projectiles=" .. tostring(proj and #proj)
					.. " error=" .. tostring(multiplayer.last_error))
			end
		end)
	else
		assert(multiplayer:connect({
			host = "127.0.0.1",
			port = port,
			game_version = "gameplay-process",
			content_hash = content_hash,
		}))
		if reconnect_required then
			multiplayer.transport.faults.disconnect_after = 0
		end
		local gameplay_fault_armed = false
		local stage = 0
		local expected_action
		local contest, pickup
		local target_x, target_y
		local input = InputState.new()
		local next_input_send = 0
		local throw_started
		local observed = {
			far = false, contention = false, build = false, craft = false,
			equipment = false, drop = false, throw = false,
			deaths = false, reunion = false,
			backlog = not reconnect_required,
		}
		local reconnect_world_before, reconnect_event_before
		local host_deaths_before
		local function send_action(label, callback, expected_ok)
			game.network_last_action_result = nil
			assert(callback(), "could not send " .. label)
			expected_action = {
				id = game.network_action_id,
				label = label,
				ok = expected_ok ~= false,
			}
		end
		local function action_finished()
			if not expected_action then return true end
			local result = game.network_last_action_result
			if not result or result.action_id ~= expected_action.id then return false end
			assert(result.ok == expected_action.ok,
				expected_action.label .. " returned " .. tostring(result.error))
			expected_action = nil
			return true
		end
		local function send_key(key)
			return multiplayer_send_key_action(key, key)
		end

		guard(function(frame_dt)
			elapsed = elapsed + frame_dt
			if reconnect_required and not gameplay_fault_armed
				and multiplayer.client_state == "playing" then
				multiplayer.transport.connected_at = love.timer.getTime()
				multiplayer.transport.faults.disconnect_after = fault_disconnect_after
				gameplay_fault_armed = true
			end
			multiplayer:update(frame_dt)
			if game.network_client and multiplayer.client_state == "playing" then
				multiplayer_interpolate_remote_state(frame_dt)
				multiplayer_reconcile_local_actor(frame_dt)
			end
			if multiplayer.client_state == "reconnecting"
				or multiplayer.client_state == "resuming"
				or multiplayer.client_state == "resuming_sync" then
				reconnect_seen = true
				reconnect_world_before = reconnect_world_before
					or multiplayer.received_world_sequence
				reconnect_event_before = reconnect_event_before
					or multiplayer.received_event_id
			end
			if reconnect_seen and multiplayer.client_state == "playing"
				and reconnect_world_before and reconnect_event_before then
				observed.backlog = multiplayer.received_world_sequence
					> reconnect_world_before
					and multiplayer.received_event_id >= reconnect_event_before + 16
			end
			if multiplayer.client_state == "failed"
				or multiplayer.client_state == "rejected" then
				return complete(1, "state=" .. tostring(multiplayer.client_state)
					.. " error=" .. tostring(multiplayer.last_error))
			end
			if multiplayer.client_state == "playing" and pl.actor_id == "guest" then
				if stage == 0 then
					target_x, target_y = pl.xt + 1, pl.yt
					contest = assert(ground_tag(pl.xt, pl.yt, "contest"))
					pickup = assert(ground_tag(pl.xt, pl.yt, "pickup"))
					host_deaths_before = tonumber(actors.host.deaths) or 0
					observed.far = math.abs((actors.host.xt or 0) - (pl.xt or 0)) > screen.x
					assert(observed.far, "snapshot did not contain separated cameras")
					send_action("contested pickup", function()
						return multiplayer_send_pickup_action(contest)
					end, false)
					stage = 1
				elseif stage == 1 and action_finished() then
					observed.contention = tagged(pl.inv, "contest") == nil
					stage = 2
				elseif stage == 2 and world[target_y] and world[target_y][target_x]
					and world[target_y][target_x].b == 0 then
					assert(not ground_tag(pl.xt, pl.yt, "contest"),
						"losing client kept the contested ground item")
					send_action("authoritative pickup", function()
						local current = assert(ground_tag(pl.xt, pl.yt, "pickup"))
						return multiplayer_send_pickup_action(current)
					end, true)
					stage = 3
				elseif stage == 3 and action_finished() and tagged(pl.inv, "pickup") then
					input.aim = {
						world_x = pl.truex + cf.w,
						world_y = pl.truey,
						tile_x = target_x,
						tile_y = target_y,
					}
					InputState.set_button(input, "space", true)
					InputState.advance(input)
					assert(multiplayer:send_input(input))
					next_input_send = elapsed + 0.05
					stage = 4
				elseif stage == 4 then
					if elapsed >= next_input_send then
						InputState.advance(input)
						assert(multiplayer:send_input(input))
						next_input_send = elapsed + 0.05
					end
					if world[target_y] and world[target_y][target_x]
						and world[target_y][target_x].b == 12 and pl.iscarry == nil then
						observed.build = true
						InputState.set_button(input, "space", false)
						InputState.advance(input)
						assert(multiplayer:send_input(input))
						send_action("open craft", function() return send_key("c") end, true)
						stage = 5
					end
				elseif stage == 5 and action_finished() then
					send_action("craft recipe", function() return send_key("return") end, true)
					stage = 6
				elseif stage == 6 and action_finished() then
					for _, instance in pairs(pl.inv or {}) do
						observed.craft = observed.craft or instance.i == 349
					end
					if observed.craft then
						local equip, slot = assert(tagged(pl.inv, "equip"))
						send_action("select equipment", function()
							return multiplayer_send_select_action(slot, equip)
						end, true)
						stage = 7
					end
				elseif stage == 7 and action_finished() then
					local selected = pl.inv and pl.inv[pl.invselect]
					if selected and selected.e2e_role == "equip" then
						send_action("equip", function() return send_key("p") end, true)
						stage = 8
					end
				elseif stage == 8 and action_finished() then
					observed.equipment = pl.inv.b and pl.inv.b.e2e_role == "equip"
					if observed.equipment then
						local drop, slot = assert(tagged(pl.inv, "drop"))
						send_action("select drop", function()
							return multiplayer_send_select_action(slot, drop)
						end, true)
						stage = 9
					end
				elseif stage == 9 and action_finished() then
					local selected = pl.inv and pl.inv[pl.invselect]
					if selected and selected.e2e_role == "drop" then
						send_action("drop", function() return send_key("z") end, true)
						stage = 10
					end
				elseif stage == 10 and action_finished() then
					observed.drop = ground_tag(pl.xt, pl.yt, "drop") ~= nil
					if observed.drop then
						local throwable, slot = assert(tagged(pl.inv, "throw"))
						send_action("select throw", function()
							return multiplayer_send_select_action(slot, throwable)
						end, true)
						stage = 11
					end
				elseif stage == 11 and action_finished() then
					local selected = pl.inv and pl.inv[pl.invselect]
					-- Crafting adds authoritative recovery time. Wait until the guest
					-- can act instead of relying on the old accidental 60 Hz drain.
					if selected and selected.e2e_role == "throw"
						and (tonumber(pl.unrest) or 0) <= 0 then
					input.aim = {
						world_x = pl.truex + cf.w * 4,
						world_y = pl.truey - cf.h,
						tile_x = pl.xt + 4,
						tile_y = pl.yt - 1,
					}
					InputState.set_button(input, "r", true)
					InputState.advance(input)
					assert(multiplayer:send_input(input))
					throw_started = elapsed
					next_input_send = elapsed + 0.05
					stage = 12
					end
				elseif stage == 12 then
					if elapsed >= next_input_send then
						InputState.advance(input)
						assert(multiplayer:send_input(input))
						next_input_send = elapsed + 0.05
					end
					if elapsed - throw_started >= 1.1 then
						InputState.set_button(input, "r", false)
						InputState.advance(input)
						assert(multiplayer:send_input(input))
						stage = 13
					end
				elseif stage == 13 then
					if elapsed >= next_input_send then
						InputState.advance(input)
						assert(multiplayer:send_input(input))
						next_input_send = elapsed + 0.05
					end
					observed.throw = observed.throw or projectile_tag("throw") ~= nil
					if observed.throw then stage = 14 end
				elseif stage == 14 then
					observed.deaths = (tonumber(pl.network_deaths) or 0) >= 1
						and (tonumber(actors.host.deaths) or 0) >= host_deaths_before + 1
					observed.reunion = math.abs(
						(actors.host.xt or 0) - (pl.xt or 0)
					) <= 2
					if observed.deaths and observed.reunion and observed.backlog
						and (not reconnect_required or reconnect_seen) then
						for name, value in pairs(observed) do
							assert(value, "gameplay E2E did not observe " .. name)
						end
						send_action("E2E completion", function()
							return multiplayer_send_action({ action = "e2e-complete" })
						end, true)
						stage = 15
					end
				elseif stage == 15 and action_finished() then
					complete(0, "build=true contention=true craft=true equipment=true drop=true throw=true deaths=true cameras=true real_backlog=" .. tostring(observed.backlog) .. " reconnect=" .. tostring(reconnect_seen))
				end
			end
			if elapsed > 45 then
				complete(1, "timeout stage=" .. stage
					.. " state=" .. tostring(multiplayer.client_state)
					.. " reconnect=" .. tostring(reconnect_seen)
					.. " backlog=" .. tostring(observed.backlog)
					.. " world=" .. tostring(reconnect_world_before)
						.. "/" .. tostring(multiplayer.received_world_sequence)
					.. " event=" .. tostring(reconnect_event_before)
						.. "/" .. tostring(multiplayer.received_event_id)
					.. " deaths=" .. tostring(observed.deaths)
					.. " reunion=" .. tostring(observed.reunion)
					.. " guest_tile=" .. tostring(pl.xt) .. "," .. tostring(pl.yt)
					.. " host_tile=" .. tostring(actors.host and actors.host.xt)
						.. "," .. tostring(actors.host and actors.host.yt)
					.. " error=" .. tostring(multiplayer.last_error))
			end
		end)
	end
end

local function validate_actor_architecture()
	local ActorState = require("src.actor_state")
	local ActorRegistry = require("src.actor_registry")
	local InputState = require("src.input_state")
	local PlayerAnimation = require("src.player_animation")
	local NetworkReplication = require("src.network.replication")
	local ItemIdentity = require("src.item_identity")
	local ActorInventory = require("src.actor_inventory")
	local GhostActor = require("src.ghost_actor")
	local ActorContext = require("src.actor_context")

	assert(actors.host == pl and actors.local_actor == pl,
		"global player is not registered as the local host actor")
	assert(pl.actor_id == "host" and pl.actor_role == "host",
		"host actor identity is invalid")
	assert(type(pl.animation) == "table" and pl.animation.frame == 1,
		"host animation state is not actor-owned")

	local registry = ActorRegistry.new()
	local host = ActorState.new({ actor_id = "host", actor_role = "host" })
	host.state = "idle"
	host.oldstate = "idle"
	host.x = 0
	host.y = 0
	host.flip = 1
	local guest = ActorState.new({ actor_id = "guest", actor_role = "guest" })
	guest.state = "idle"
	guest.oldstate = "idle"
	guest.x = 100
	guest.y = 0
	guest.flip = -1

	registry:bind_host(host, {})
	registry:bind_guest(guest)
	assert(registry.host == host and registry.guest == guest,
		"actor registry did not retain both actors")
	assert(registry:runtime(host) ~= registry:runtime(guest),
		"actors unexpectedly share runtime sidecar state")

	do
		assert(ActorContext.register_field("game", "context_smoke_game"))
		assert(ActorContext.register_field("craft", "context_smoke_craft"))
		assert(ActorContext.register_field(
			"actor_global", "CONTEXT_SMOKE_ACTOR"
		))
		assert(ActorContext.register_field(
			"transient_global", "CONTEXT_SMOKE_TRANSIENT"
		))
		local guest_runtime = registry:runtime(guest)
		guest_runtime.presentation.local_ui.game = {
			context_smoke_game = "guest-game",
		}
		guest_runtime.presentation.local_ui.craft = {
			context_smoke_craft = "guest-craft",
		}
		guest_runtime.local_globals = {
			CONTEXT_SMOKE_ACTOR = "guest-global",
		}
		local original_game_value = game.context_smoke_game
		local original_craft_value = craft.context_smoke_craft
		local original_actor_value = CONTEXT_SMOKE_ACTOR
		local original_transient_value = CONTEXT_SMOKE_TRANSIENT
		local original_pl, original_vi = pl, vi
		local position_fields = {
			"x", "y", "truex", "truey", "tx", "ty", "xt", "yt",
		}
		local original_guest_position = {}
		for _, field in ipairs(position_fields) do
			original_guest_position[field] = { value = guest[field] }
		end
		game.context_smoke_game = "host-game"
		craft.context_smoke_craft = "host-craft"
		CONTEXT_SMOKE_ACTOR = "host-global"
		CONTEXT_SMOKE_TRANSIENT = "host-transient"
		guest.truex, guest.truey = 320, 320

		local context_ok, context_error = pcall(
			ActorContext.run,
			registry,
			guest,
			{ camera = vi },
			function()
				assert(game.context_smoke_game == "guest-game"
					and craft.context_smoke_craft == "guest-craft"
					and CONTEXT_SMOKE_ACTOR == "guest-global"
					and CONTEXT_SMOKE_TRANSIENT == nil,
					"actor context exposed host-local sentinel state")
				game.context_smoke_game = "guest-game-updated"
				craft.context_smoke_craft = "guest-craft-updated"
				CONTEXT_SMOKE_ACTOR = "guest-global-updated"
				CONTEXT_SMOKE_TRANSIENT = "guest-transient"
				error("actor context smoke error")
			end
		)
		assert(not context_ok and tostring(context_error):find(
			"actor context smoke error", 1, true
		), "actor context swallowed its callback error")
		assert(pl == original_pl and vi == original_vi
			and game.context_smoke_game == "host-game"
			and craft.context_smoke_craft == "host-craft"
			and CONTEXT_SMOKE_ACTOR == "host-global"
			and CONTEXT_SMOKE_TRANSIENT == "host-transient"
			and guest_runtime.presentation.local_ui.game.context_smoke_game
				== "guest-game-updated"
			and guest_runtime.presentation.local_ui.craft.context_smoke_craft
				== "guest-craft-updated"
			and guest_runtime.local_globals.CONTEXT_SMOKE_ACTOR
				== "guest-global-updated",
			"actor context did not restore globals after callback failure")

		local original_coord_true2screen = coord_true2screen
		local coordinate_callback_reached = false
		coord_true2screen = function() error("coordinate smoke error") end
		local coordinate_ok, coordinate_error = pcall(
			ActorContext.run,
			registry,
			guest,
			{ camera = vi },
			function() coordinate_callback_reached = true end
		)
		coord_true2screen = original_coord_true2screen
			assert(not coordinate_ok and tostring(coordinate_error):find(
			"coordinate smoke error", 1, true
		) and not coordinate_callback_reached
			and pl == original_pl and vi == original_vi
			and game.context_smoke_game == "host-game"
			and craft.context_smoke_craft == "host-craft"
			and CONTEXT_SMOKE_ACTOR == "host-global"
			and CONTEXT_SMOKE_TRANSIENT == "host-transient",
				"coordinate failure leaked an actor context")

			local registry_view = ActorContext.state_registry()
			assert(type(registry_view.actor_owned) == "table"
				and type(registry_view.shared) == "table"
				and type(registry_view.host_only) == "table"
				and type(registry_view.presentation_only) == "table",
				"actor state ownership registry is incomplete")
			local sentinel_previous = { game = {}, craft = {}, global = {} }
			local function remember(bucket, container, field)
				bucket[field] = { present = container[field] ~= nil, value = container[field] }
			end
			for _, field in ipairs(ActorContext.registered_fields("game")) do
				remember(sentinel_previous.game, game, field)
				game[field] = "host:game:" .. field
				guest_runtime.presentation.local_ui.game[field] = "guest:game:" .. field
			end
			for _, field in ipairs(ActorContext.registered_fields("craft")) do
				remember(sentinel_previous.craft, craft, field)
				craft[field] = "host:craft:" .. field
				guest_runtime.presentation.local_ui.craft[field] = "guest:craft:" .. field
			end
			for _, field in ipairs(ActorContext.registered_fields("actor_global")) do
				remember(sentinel_previous.global, _G, field)
				_G[field] = "host:global:" .. field
				guest_runtime.local_globals[field] = "guest:global:" .. field
			end
			for _, field in ipairs(ActorContext.registered_fields("transient_global")) do
				remember(sentinel_previous.global, _G, field)
				_G[field] = "host:transient:" .. field
			end

			ActorContext.run(registry, guest, { camera = vi }, function()
				for _, field in ipairs(ActorContext.registered_fields("game")) do
					assert(game[field] == "guest:game:" .. field,
						"host game sentinel leaked into guest: " .. field)
					game[field] = "updated:game:" .. field
				end
				for _, field in ipairs(ActorContext.registered_fields("craft")) do
					assert(craft[field] == "guest:craft:" .. field,
						"host craft sentinel leaked into guest: " .. field)
					craft[field] = "updated:craft:" .. field
				end
				for _, field in ipairs(ActorContext.registered_fields("actor_global")) do
					assert(_G[field] == "guest:global:" .. field,
						"host actor global leaked into guest: " .. field)
					_G[field] = "updated:global:" .. field
				end
				for _, field in ipairs(ActorContext.registered_fields("transient_global")) do
					assert(_G[field] == nil,
						"host transient global leaked into guest: " .. field)
					_G[field] = "guest:transient:" .. field
				end
			end)

			for _, field in ipairs(ActorContext.registered_fields("game")) do
				assert(game[field] == "host:game:" .. field
					and guest_runtime.presentation.local_ui.game[field]
						== "updated:game:" .. field,
					"game sentinel was not isolated: " .. field)
			end
			for _, field in ipairs(ActorContext.registered_fields("craft")) do
				assert(craft[field] == "host:craft:" .. field
					and guest_runtime.presentation.local_ui.craft[field]
						== "updated:craft:" .. field,
					"craft sentinel was not isolated: " .. field)
			end
			for _, field in ipairs(ActorContext.registered_fields("actor_global")) do
				assert(_G[field] == "host:global:" .. field
					and guest_runtime.local_globals[field] == "updated:global:" .. field,
					"actor global sentinel was not isolated: " .. field)
			end
			for _, field in ipairs(ActorContext.registered_fields("transient_global")) do
				assert(_G[field] == "host:transient:" .. field,
					"transient sentinel was not restored: " .. field)
			end
			local function restore(bucket, container)
				for field, saved in pairs(bucket) do
					container[field] = saved.present and saved.value or nil
				end
			end
			restore(sentinel_previous.game, game)
			restore(sentinel_previous.craft, craft)
			restore(sentinel_previous.global, _G)

			for _, field in ipairs(position_fields) do
			guest[field] = original_guest_position[field].value
		end
		game.context_smoke_game = original_game_value
		craft.context_smoke_craft = original_craft_value
		CONTEXT_SMOKE_ACTOR = original_actor_value
		CONTEXT_SMOKE_TRANSIENT = original_transient_value
	end

	local host_input = registry:runtime(host).input
	assert(InputState.set_button(host_input, "a", true))
	assert(InputState.is_down(host_input, "a"))
	assert(not InputState.is_down(registry:runtime(guest).input, "a"),
		"input state leaked between actors")
	local packet = InputState.snapshot(host_input)
	local remote_input = InputState.new()
	assert(InputState.apply_snapshot(remote_input, packet))
	assert(InputState.is_down(remote_input, "a"),
		"input snapshot did not round-trip")

	local definitions = {
		idle = {
			cnt = 2,
			dur = { 1, 1 },
			ani = { 2, 1 },
			add = { [2] = { 3, -2 } },
		},
		walk = {
			cnt = 2,
			dur = { 1, 1 },
			ani = { 2, 1 },
		},
	}
	assert(PlayerAnimation.update(host, 0.01, definitions))
	assert(host.animation.frame == 2 and host.x == 3 and host.y == -2,
		"host actor animation did not advance independently")
	assert(guest.animation.frame == 1 and guest.x == 100,
		"host animation mutated guest actor")

	guest.animation.frame = 2
	guest.animation.time = 0.4
	guest.animation.cycle = 3
	local client_animation = guest.animation
	assert(NetworkReplication.apply_actor(guest, {
		state = "idle",
		oldstate = "walk",
		animation = { frame = 1, time = 0, cycle = 0 },
	}, {
		fields = { "state", "oldstate", "animation" },
		preserve_animation = true,
	}))
	assert(guest.animation == client_animation
		and guest.animation.frame == 2 and guest.animation.time == 0.4
		and guest.oldstate == "idle",
		"replication rewound an active client animation clock")
	assert(NetworkReplication.apply_actor(guest, {
		state = "walk",
		oldstate = "walk",
		animation = { frame = 2, time = 0.9, cycle = 12 },
	}, {
		fields = { "state", "oldstate", "animation" },
		preserve_animation = true,
	}))
	assert(guest.state == "walk" and guest.oldstate == "idle"
		and guest.animation == client_animation,
		"replication hid an authoritative animation-state transition")
	assert(PlayerAnimation.update(guest, 0, definitions)
		and guest.animation.frame == 1 and guest.oldstate == "walk",
		"authoritative state transition did not reset client animation once")

	guest.state = "jump"
	guest.yspeed = -7
	guest.tx, guest.ty, guest.xt, guest.yt = 10, 11, 10, 11
	assert(NetworkReplication.apply_actor(guest, {
		state = "idle",
		yspeed = 0,
		tx = 20, ty = 21, xt = 20, yt = 21,
	}, {
		fields = { "state", "yspeed", "tx", "ty", "xt", "yt" },
		preserve_fields = {
			state = true, yspeed = true,
			tx = true, ty = true, xt = true, yt = true,
		},
	}))
	assert(guest.state == "jump" and guest.yspeed == -7
		and guest.tx == 10 and guest.ty == 11
		and guest.xt == 10 and guest.yt == 11,
		"replication overwrote locally predicted movement")
	local captured_motion = NetworkReplication.capture_actor(guest)
	assert(captured_motion.yspeed == -7,
		"replication omitted authoritative movement velocity")

	local legacy = ActorState.ensure({ state = "idle" }, {
		actor_id = "host",
		actor_role = "host",
		force_identity = true,
	})
	assert(legacy.animation.frame == 1 and legacy.animation.time == 0,
		"legacy actor migration did not supply animation state")

	local identity_world = {}
	local first = { i = 31 }
	local second = { i = 31 }
	local first_uid = assert(ItemIdentity.ensure(first, identity_world))
	local second_uid = assert(ItemIdentity.ensure(second, identity_world))
	assert(first_uid ~= second_uid, "new item instances share a uid")
	local duplicate = { i = 31, uid = first_uid }
	local seen = { [first_uid] = first }
	local repaired_uid = assert(ItemIdentity.ensure(duplicate, identity_world, seen))
	assert(repaired_uid ~= first_uid and seen[repaired_uid] == duplicate,
		"duplicate item uid was not repaired")

	host.inv = { [1] = first }
	host.invsize = 9
	host.unlock_i = { [31] = true }
	host.unlock_c = { [5] = true }
	host.visited = { ["1-1"] = true }
	host.ferted = {}
	host.stats = {
		body = { hp = 20, maxhp = 120, pc = 16, d = -5 },
		faith = { hp = 30, maxhp = 100, pc = 30, d = 1 },
	}
	local session_ghost = GhostActor.new(host, { session_id = "test-session" })
	assert(next(session_ghost.inv) == nil and session_ghost.invsize == 9,
		"ghost copied material inventory")
	assert(session_ghost.unlock_i == host.unlock_i
		and session_ghost.visited == host.visited,
		"ghost does not share world knowledge")
	assert(session_ghost.stats ~= host.stats
		and session_ghost.stats.body.hp == 120
		and session_ghost.stats.faith.hp == 0,
		"ghost personal stats were not reset independently")
	local ghost_item = { i = 31 }
	assert(ActorInventory.add(session_ghost, ghost_item, identity_world) == 1)
	assert(ActorInventory.count(session_ghost) == 1)
	assert(ActorInventory.remove(session_ghost, 1) == ghost_item)
	assert(host.inv[1] == first, "ghost inventory operation mutated host inventory")

	finish(0,
		"mode=actors registry=true input=true animation=true migration=true "
			.. "items=true ghost=true")
end

local function validate_network_core()
	local ActiveCameraUnion = require("src.active_camera_union")
	local ActorState = require("src.actor_state")
	local ActorRegistry = require("src.actor_registry")
	local ActorInventory = require("src.actor_inventory")
	local InputState = require("src.input_state")
	local Protocol = require("src.network.protocol")
	local Session = require("src.network.session")
	local ContentHash = require("src.network.content_hash")
	local Identity = require("src.network.identity")
	local EnetTransport = require("src.network.enet_transport")
	local GuestPossessions = require("src.guest_possessions")
	local GameAdapter = require("src.network.game_adapter")
	local ItemIdentity = require("src.item_identity")
	local GhostActor = require("src.ghost_actor")
	local NetworkSnapshot = require("src.network.snapshot")
	local NetworkReplication = require("src.network.replication")
	local WorldJournal = require("src.network.world_journal")
	local Runtime = require("src.network.runtime")
	local LANDiscovery = require("src.network.discovery")
	local FixedStep = require("src.network.fixed_step")
	local PlayerAnimation = require("src.player_animation")
	local PerformanceBudget = require("src.performance_budget")
	local PerformanceMetrics = require("src.performance_metrics")
	do
		local callbacks = {}
		for _, name in ipairs(GameAdapter.required_callbacks()) do
			callbacks[name] = function() return true end
		end
		local adapter = GameAdapter.new(callbacks)
		local options = adapter:runtime_options({ registry = "sentinel" })
		assert(options.registry == "sentinel"
			and options.state_provider == callbacks.state_provider,
			"network game adapter did not bind explicit dependencies")
		callbacks.state_provider = nil
		local accepted, adapter_error = pcall(GameAdapter.new, callbacks)
		assert(not accepted and tostring(adapter_error):find(
			"state_provider", 1, true
		), "network game adapter accepted a missing dependency")
	end
	do
		local visited = {}
		local unique, candidates = ActiveCameraUnion.each({
			{ xtile = 0, ytile = 0 },
			{ xtile = 2, ytile = 1 },
		}, 2, 1, function(x, y)
			local key = x .. ":" .. y
			assert(not visited[key], "camera union visited a cell twice")
			visited[key] = true
		end)
		assert(unique == 31 and candidates == 40,
			"overlapping camera union has the wrong coverage")
		assert(visited["0:0"] and visited["6:4"] and visited["2:1"],
			"camera union omitted an edge or overlap cell")
		local far_unique, far_candidates = ActiveCameraUnion.each({
			{ xtile = 0, ytile = 0 },
			{ xtile = 20, ytile = 20 },
		}, 2, 1, function() end)
		assert(far_unique == 40 and far_candidates == 40,
			"distant camera union unexpectedly discarded cells")
	end
	do
		PerformanceMetrics.activate({ scenario = "unit" })
		local first, second = PerformanceMetrics.measure(
			"returns", function() return "first", nil, "third" end
		)
		assert(first == "first" and second == nil,
			"performance wrapper changed callback returns")
		PerformanceMetrics.record("ordered", 1)
		PerformanceMetrics.record("ordered", 2)
		PerformanceMetrics.record("ordered", 10)
		local raised, raise_error = pcall(
			PerformanceMetrics.measure,
			"errors",
			function() error("measured failure") end
		)
		local report = PerformanceMetrics.deactivate()
		assert(not raised and tostring(raise_error):find("measured failure", 1, true),
			"performance wrapper swallowed callback errors")
		assert(report.phases.ordered.p50_ms == 2
			and report.phases.ordered.p95_ms == 10,
			"performance percentiles are incorrect")
		local accepted, failures = PerformanceBudget.evaluate({
			phases = {
				frame_update = { count = 120, p95_ms = 5, p99_ms = 7 },
				frame_render = { count = 120, p95_ms = 6, p99_ms = 8 },
			},
			memory_growth_kb = 0,
		})
		assert(accepted and #failures == 0,
			"valid performance report failed its budget")
		local software_targets = assert(
			PerformanceBudget.targets_for_profile("software-ci")
		)
		local slow_software_render = {
			phases = {
				frame_update = { count = 120, p95_ms = 5, p99_ms = 7 },
				frame_render = { count = 120, p95_ms = 70, p99_ms = 90 },
			},
			memory_growth_kb = 0,
		}
		local hardware_ok = PerformanceBudget.evaluate(slow_software_render)
		local software_ok = PerformanceBudget.evaluate(
			slow_software_render,
			software_targets
		)
		assert(not hardware_ok and software_ok,
			"software renderer timing leaked into the hardware FPS gate")
		local missing_render_ok = PerformanceBudget.evaluate({
			phases = {
				frame_update = { count = 120, p95_ms = 5, p99_ms = 7 },
			},
			memory_growth_kb = 0,
		}, software_targets)
		assert(not missing_render_ok,
			"software CI accepted a benchmark that never rendered")
		local unknown_targets, unknown_error =
			PerformanceBudget.targets_for_profile("unknown")
		assert(not unknown_targets and unknown_error ==
			"unknown performance profile: unknown",
			"unknown performance profile silently bypassed the gate")
	end
	local enet_ok, enet = pcall(require, "enet")
	local socket_ok, socket = pcall(require, "socket")
	assert(enet_ok and type(enet) == "table", "lua-enet is unavailable")
	assert(socket_ok and type(socket) == "table", "LuaSocket is unavailable")
	local content_hash = ContentHash.compute({ "version.txt", "conf.lua" })
	assert(type(content_hash) == "string" and #content_hash == 64,
		"content manifest hash is invalid")
	do
		local hash_probe = "network-content-hash-smoke.txt"
		assert(love.filesystem.write(hash_probe, "content hash before reload"))
		ContentHash.invalidate()
		local hash_before_reload = ContentHash.compute({ hash_probe })
		assert(love.filesystem.write(hash_probe, "content hash after reload"))
		ContentHash.invalidate()
		local hash_after_reload = ContentHash.compute({ hash_probe })
		love.filesystem.remove(hash_probe)
		ContentHash.invalidate()
		assert(hash_before_reload ~= hash_after_reload,
			"content hash stayed stale after cache invalidation")
	end
	if IS_DEVELOPMENT then
		do
			local original_compute = ContentHash.compute
			local original_runtime_hash = multiplayer.content_hash
			local reloaded_hash = string.rep("a", 64)
			ContentHash.compute = function() return reloaded_hash end
			lurker.postswap("network-content-hash-smoke.lua")
			ContentHash.compute = original_compute
			local refreshed_hash = multiplayer.content_hash
			multiplayer.content_hash = original_runtime_hash
			ContentHash.invalidate()
			assert(refreshed_hash == reloaded_hash,
				"automatic Lua hot reload did not refresh runtime content hash")
		end
	end
	local identity_state = {}
	local world_id = Identity.ensure_world(identity_state)
	local test_content_hash = string.rep("b", 64)
	local discovery_session_id = string.rep("c", 64)
	local client_nonce = string.rep("d", 64)
	local incomplete_nonce = string.rep("e", 64)
	assert(Identity.valid(world_id) and Identity.ensure_world(identity_state) == world_id,
		"world identity is not stable")
	do
		local deterministic_provider = function(length)
			assert(length == 32, "identity requested less than 256 random bits")
			return string.rep("\165", length)
		end
		local public_token = Identity.public_token("scope", deterministic_provider)
		local secret_token = Identity.secret_token("scope", deterministic_provider)
		assert(Identity.valid(public_token) and Identity.valid(secret_token)
			and public_token ~= secret_token,
			"public and secret identity domains were not separated")
		local random_token_a = Identity.secret_token("unique")
		local random_token_b = Identity.secret_token("unique")
		assert(Identity.valid(random_token_a) and Identity.valid(random_token_b)
			and random_token_a ~= random_token_b,
			"system CSPRNG did not produce unique valid secrets")
		local insecure_ok, insecure_error = pcall(
			Identity.secret_token,
			"unavailable",
			function() return nil, "entropy unavailable" end
		)
		assert(not insecure_ok and tostring(insecure_error):find(
			"secure random unavailable", 1, true
		), "identity silently fell back after CSPRNG failure")
	end

	local server, client
	local loopback_ok, loopback_error = pcall(function()
		server = assert(EnetTransport.create_server({
			host = "127.0.0.1",
			port = 23872,
			last_port = 23892,
		}))
		client = assert(EnetTransport.create_client({
			faults = {
				loss_percent = 100,
				random = function() return 0 end,
			},
		}))
		assert(client:connect("127.0.0.1", server.port))
		local server_connected
		local client_connected
		local deadline = love.timer.getTime() + 2
		while love.timer.getTime() < deadline
			and (not server_connected or not client_connected) do
			local server_event = server:poll(1)
			local client_event = client:poll(1)
			server_connected = server_connected
				or (server_event and server_event.type == "connect")
			client_connected = client_connected
				or (client_event and client_event.type == "connect")
		end
		assert(server_connected and client_connected, "ENet loopback did not connect")
		assert(client:send(nil, "ping", { nonce = "loopback" },
			Protocol.CHANNEL.CONTROL, true))
		client:flush()
		local received
		deadline = love.timer.getTime() + 2
		while love.timer.getTime() < deadline and not received do
			local event = server:poll(2)
			if event and event.type == "receive" then received = event end
		end
		assert(received, "ENet loopback packet was not received")
		local message = assert(Protocol.decode(received.data))
		assert(message.kind == "ping" and message.payload.nonce == "loopback",
			"ENet loopback payload was corrupted")
		assert(client:send_raw(nil, "fault-loss", Protocol.CHANNEL.INPUT, false))
		assert(client:stats().faults.dropped == 1,
			"artificial unreliable packet loss was not recorded")
		assert(client:send(nil, "event", {
			kind = "fault-test",
			event_id = 1,
		}, Protocol.CHANNEL.WORLD, true))
		assert(client:stats().faults.dropped == 2,
			"artificial loss did not exercise the reliable application stream")
		client.faults.loss_percent = 0
		client.faults.duplication_percent = 100
		assert(client:send_raw(nil, "fault-duplicate", Protocol.CHANNEL.INPUT, false))
		client:flush()
		local duplicates = 0
		deadline = love.timer.getTime() + 2
		while love.timer.getTime() < deadline and duplicates < 2 do
			local event = server:poll(2)
			if event and event.type == "receive"
				and event.data == "fault-duplicate" then
				duplicates = duplicates + 1
			end
		end
		assert(duplicates == 2 and client:stats().faults.duplicated == 1,
			"artificial unreliable packet duplication was not applied")
		assert(client:send(nil, "event", {
			kind = "fault-test",
			event_id = 2,
		}, Protocol.CHANNEL.WORLD, true))
		client:flush()
		local reliable_duplicates = 0
		deadline = love.timer.getTime() + 2
		while love.timer.getTime() < deadline and reliable_duplicates < 2 do
			local event = server:poll(2)
			local decoded_event = event and event.type == "receive"
				and Protocol.decode(event.data) or nil
			if decoded_event and decoded_event.kind == "event"
				and decoded_event.payload.event_id == 2 then
				reliable_duplicates = reliable_duplicates + 1
			end
		end
		assert(reliable_duplicates == 2
			and client:stats().faults.duplicated == 2,
			"artificial duplication did not exercise the reliable application stream")
		client.faults.duplication_percent = 0
		client.faults.latency_ms = 20
		assert(client:send_raw(nil, "fault-delay", Protocol.CHANNEL.INPUT, false))
		assert(client:stats().faults.queued == 1,
			"artificial latency did not queue a packet")
		love.timer.sleep(0.03)
		client:poll(0)
		client:flush()
		local delayed
		deadline = love.timer.getTime() + 2
		while love.timer.getTime() < deadline and not delayed do
			local event = server:poll(2)
			delayed = event and event.type == "receive"
				and event.data == "fault-delay"
		end
		assert(delayed and client:stats().faults.queued == 0,
			"artificial latency did not release the queued packet")
		client.faults.latency_ms = 5
		local actual_send = client._actual_send
		local transient_attempts = 0
		client._actual_send = function(self, ...)
			transient_attempts = transient_attempts + 1
			if transient_attempts == 1 then return false, "transient send failure" end
			return actual_send(self, ...)
		end
		assert(client:send_raw(nil, "retry-after-send-error",
			Protocol.CHANNEL.WORLD, true))
		love.timer.sleep(0.01)
		local _, transient_error = client:poll(0)
		assert(transient_error == "transient send failure"
			and client:stats().faults.queued == 1,
			"transport discarded a delayed packet after peer.send failed")
		client:poll(0)
		client._actual_send = actual_send
		client:flush()
		assert(client:stats().faults.queued == 0,
			"transport did not retry a retained packet")
		local retried_packet
		deadline = love.timer.getTime() + 2
		while love.timer.getTime() < deadline and not retried_packet do
			local event = server:poll(2)
			retried_packet = event and event.type == "receive"
				and event.data == "retry-after-send-error"
		end
		assert(retried_packet, "retained transport packet was not delivered")
		local client_stats = client:stats()
		local server_stats = server:stats()
		assert(client_stats.packets_sent >= 1 and client_stats.bytes_sent > 0
			and server_stats.packets_received >= 1 and server_stats.bytes_received > 0,
			"ENet transport diagnostics did not count traffic")
	end)
	if client then client:close() end
	if server then server:close() end
	assert(loopback_ok, loopback_error)
	local active_transport_peer, late_transport_peer = {}, {}
	local fake_transport = setmetatable({
		closed = false,
		peer = active_transport_peer,
		host = {
			service = function()
				return { type = "connect", peer = late_transport_peer }
			end,
		},
		outgoing_queue = {},
		outgoing_bytes = 0,
		last_due_by_channel = {},
		ignored_disconnect_peers = {},
		synthetic_events = {},
		packets_received = 0,
		bytes_received = 0,
		channel_received = {},
	}, { __index = EnetTransport })
	assert(fake_transport:poll(0).peer == late_transport_peer
		and fake_transport.peer == active_transport_peer,
		"late connect event replaced the active transport peer")

	local runtime_server, runtime_client
	local runtime_loopback_ok, runtime_loopback_error = pcall(function()
		local host_registry = ActorRegistry.new()
		local runtime_host_actor = ActorState.new({ actor_id = "host", actor_role = "host" })
		runtime_host_actor.inv = {}
		runtime_host_actor.invsize = 9
		runtime_host_actor.unlock_i = {}
		runtime_host_actor.unlock_c = {}
		runtime_host_actor.visited = {}
		runtime_host_actor.ferted = {}
		runtime_host_actor.stats = {
			body = { hp = 100, maxhp = 100, pc = 100, d = 0 },
		}
		host_registry:bind_host(runtime_host_actor, {})
		local client_registry = ActorRegistry.new()
		local applied_snapshot
		local applied_state
		local applied_pose
		local applied_world
		local simulated_input
		local handled_action
		local catchup_allowed = true
		local pending_deltas = { {
			sequence = 1,
			tick = 2,
			cells = { { x = 1, y = 1, cell = { b = 12 } } },
		} }
		local pending_events = {}
		local applied_event
		runtime_server = Runtime.new({
			registry = host_registry,
			state_interval = 0.001,
			pose_interval = 0.001,
			world_interval = 0.001,
			spawn_provider = function()
				return { truex = 32, truey = 64, tx = 2, ty = 3, xt = 2, yt = 3 }
			end,
			state_provider = function(session_state)
				return {
					world = { [1] = { [1] = { b = 0 } } },
					game = { world_id = world_id, time = 1 },
					host_actor = runtime_host_actor,
					guest_actor = session_state.guest,
					tips = {}, disp = {}, mobs = {}, tick = 1,
					world_id = world_id,
					session_id = session_state.session_id,
				}
			end,
			dropper = function() return true end,
			catchup_validator = function()
				return catchup_allowed,
					catchup_allowed and nil or "snapshot_catchup_overflow"
			end,
			simulation_handler = function(_, remote_input)
				simulated_input = InputState.is_down(remote_input, "a")
			end,
			action_handler = function(_, action)
				handled_action = action.action_id
				return true
			end,
			replication_provider = function(session_state)
				return {
					tick = 2,
					guest_actor = NetworkReplication.capture_actor(session_state.guest),
				}
			end,
			pose_provider = function(session_state)
				return {
					pose_schema = 1,
					tick = 2,
					sample_time = 0.1,
					input_sequence = 1,
					guest_actor = NetworkReplication.capture_actor(
						session_state.guest,
						NetworkReplication.ACTOR_POSE_FIELDS
					),
				}
			end,
			world_delta_provider = function()
				if #pending_deltas == 0 then return nil end
				return table.remove(pending_deltas, 1)
			end,
			event_provider = function()
				if #pending_events == 0 then return nil end
				return table.remove(pending_events, 1)
			end,
		})
		runtime_client = Runtime.new({
			registry = client_registry,
			max_poll_events = 1,
			state_interval = 0.001,
			pose_interval = 0.001,
			world_interval = 0.001,
			state_applier = function(snapshot_state)
				applied_snapshot = snapshot_state
				client_registry:bind_host(snapshot_state.host_actor, {})
				client_registry:bind_guest(snapshot_state.guest_actor, { local_actor = true })
			end,
			replication_applier = function(value) applied_state = value end,
			pose_applier = function(value) applied_pose = value end,
			world_delta_applier = function(value) applied_world = value end,
			event_handler = function(value)
				applied_event = value
				return value.kind == "runtime-test"
			end,
		})
		local started, runtime_port = runtime_server:start_host({
			host = "127.0.0.1",
			port = 23930,
			last_port = 23950,
			discovery = false,
			game_version = "test-version",
			content_hash = test_content_hash,
			world_id = world_id,
		})
		assert(started)
		assert(runtime_client:connect({
			host = "127.0.0.1",
			port = runtime_port,
			game_version = "test-version",
			content_hash = test_content_hash,
		}))
		local function pump(predicate, label)
			local deadline = love.timer.getTime() + 3
			while love.timer.getTime() < deadline and not predicate() do
				runtime_server:update(0.01)
				runtime_client:update(0.01)
				love.timer.sleep(0.001)
			end
			assert(predicate(), label)
		end
		pump(function() return runtime_server:pending_approval() ~= nil end,
			"runtime join request did not reach host")
		assert(runtime_server:approve_guest())
		local approved_guest = runtime_server.session.guest
		assert(runtime_client.client_welcome == nil
			and runtime_client.client_state == "awaiting_approval",
			"client consumed WELCOME before the pre-welcome recovery test")
		assert(runtime_server:_handle_transport_loss(
			"pre-welcome-interruption-test", runtime_server.peer
		))
		assert(runtime_client:_handle_transport_loss(
			"pre-welcome-interruption-test", runtime_client.peer
		))
		assert(runtime_client.client_state == "reconnecting"
			and runtime_client.client_resume_mode == "initial",
			"pre-welcome interruption did not retain initial handshake identity")
		pump(function()
			return runtime_client.client_state == "receiving_snapshot"
				and applied_snapshot == nil
		end, "client did not enter an interruptible snapshot transfer")
		local snapshot_guest = runtime_server.session.guest
		assert(snapshot_guest == approved_guest,
			"pre-welcome reconnect replaced the approved guest actor")
		assert(runtime_server:_handle_transport_loss(
			"snapshot-interruption-test", runtime_server.peer
		))
		assert(runtime_client:_handle_transport_loss(
			"snapshot-interruption-test", runtime_client.peer
		))
		assert(runtime_client.client_state == "reconnecting"
			and runtime_client.client_resume_mode == "snapshot",
			"interrupted snapshot did not select snapshot recovery")
		pump(function()
			return runtime_server.session.state == Session.STATE.PLAYING
				and runtime_client.client_state == "playing"
		end, "interrupted runtime snapshot did not restart and reach playing")
		assert(runtime_server.session.guest == snapshot_guest,
			"snapshot restart replaced the reserved guest actor")
		assert(applied_snapshot and applied_snapshot.header.tick == 1,
			"runtime snapshot was not applied")
		local runtime_input = InputState.new()
		InputState.set_button(runtime_input, "a", true)
		InputState.advance(runtime_input)
		assert(runtime_client:send_input(runtime_input))
		assert(runtime_client:send_action({ action_id = "runtime:1", action = "test" }))
		pump(function()
			return simulated_input and handled_action == "runtime:1"
				and applied_state and applied_pose and applied_world
		end, "runtime input/action/replication loop did not complete")
		assert(applied_pose.pose_schema == 1
			and applied_pose.guest_actor.actor_role == "guest",
			"runtime authoritative pose was corrupted")
		assert(applied_world.cells[1].cell.b == 12,
			"runtime world delta was corrupted")
		for sequence = 2, 33 do
			pending_deltas[#pending_deltas + 1] = {
				sequence = sequence,
				tick = sequence + 1,
				cells = { { x = 1, y = 1, cell = { b = sequence } } },
			}
		end
		for event_id = 1, 64 do
			pending_events[#pending_events + 1] = {
				kind = "runtime-test",
				event_id = event_id,
				value = event_id,
			}
		end
		local original_guest = runtime_server.session.guest
		assert(runtime_server:_handle_transport_loss(
			"runtime-test", runtime_server.peer
		))
		assert(not InputState.is_down(
			runtime_server.registry:runtime(original_guest).input, "a"
		), "disconnect retained stale held guest input")
		pump(function()
			return runtime_server.session.state == Session.STATE.PLAYING
				and runtime_client.client_state == "playing"
		end, "runtime reconnect did not resume playing")
		assert(runtime_server.session.guest == original_guest,
			"runtime reconnect replaced the guest actor")
		assert(applied_world and applied_world.sequence == 33
			and applied_event and applied_event.event_id == 64,
			"client entered playing before the reliable reconnect backlog was applied")
		catchup_allowed = false
		assert(runtime_server:_handle_transport_loss(
			"runtime-overflow-test", runtime_server.peer
		))
		pump(function()
			return runtime_server.session.state == Session.STATE.LISTENING
				and (runtime_client.client_state == "rejected"
					or runtime_client.client_state == "disconnected")
		end, "runtime reconnect ignored an invalid catch-up journal")
		assert(runtime_server.session.guest == nil,
			"invalid reconnect catch-up retained the guest actor")
		assert(runtime_server.peer == nil and runtime_server.transport.peer == nil,
			"rejected reconnect retained the ENet peer")
		assert(runtime_client:prepare_quit())
		catchup_allowed = true
		assert(runtime_client:connect({
			host = "127.0.0.1",
			port = runtime_port,
			game_version = "test-version",
			content_hash = test_content_hash,
		}))
		pump(function() return runtime_server:pending_approval() ~= nil end,
			"host did not accept a new peer after reconnect rejection")
		assert(runtime_server:reject_guest("rejected_by_host"))
		pump(function()
			return runtime_client.client_state == "rejected"
				or runtime_client.client_state == "disconnected"
		end, "runtime host rejection did not reach the client")
		assert(runtime_server.peer == nil and runtime_server.transport.peer == nil,
			"host rejection retained the ENet peer")
	end)
	if runtime_client then runtime_client:prepare_quit() end
	if runtime_server then runtime_server:prepare_quit() end
	assert(runtime_loopback_ok, runtime_loopback_error)

	local responder, browser
	local discovery_ok, discovery_error = pcall(function()
		local valid_advertisement = {
			protocol_version = tostring(Protocol.VERSION),
			game_version = "test-version",
			content_hash = test_content_hash,
			session_id = discovery_session_id,
			world_id = world_id,
			gameplay_port = 23872,
			players = 1,
			capacity = 2,
			joinable = true,
			display_name = "Loopback world",
		}
		assert(LANDiscovery.valid_advertisement(valid_advertisement),
			"valid LAN advertisement was rejected")
		local fractional_advertisement = {}
		for key, value in pairs(valid_advertisement) do
			fractional_advertisement[key] = value
		end
		fractional_advertisement.players = 1.5
		assert(not LANDiscovery.valid_advertisement(fractional_advertisement),
			"fractional LAN player count was accepted")
		local invalid_utf8_advertisement = {}
		for key, value in pairs(valid_advertisement) do
			invalid_utf8_advertisement[key] = value
		end
		invalid_utf8_advertisement.display_name = "bad\255name"
		assert(not LANDiscovery.valid_advertisement(invalid_utf8_advertisement),
			"invalid UTF-8 LAN display name was accepted")
		local repaired_utf8 = Protocol.sanitize_utf8("bad\255name Привет")
		local utf8_library = require("utf8")
		assert(utf8_library.len(repaired_utf8)
			and repaired_utf8:find("name Привет", 1, true),
			"invalid network text was not repaired for the menu renderer")
		assert(#Protocol.sanitize_utf8("Привет", 5) <= 5,
			"UTF-8 network text truncation split its byte budget")
		responder = assert(LANDiscovery.create_responder(function()
			return valid_advertisement
		end, { bind = "127.0.0.1", port = 23921 }))
		browser = assert(LANDiscovery.create_browser({ port = 23921 }))
		assert(browser:refresh(nil, 23921))
		local deadline = love.timer.getTime() + 2
		local records = {}
		while love.timer.getTime() < deadline and #records == 0 do
			responder:update()
			browser:update()
			records = browser:list()
		end
		assert(#records == 1
			and records[1].session_id == discovery_session_id
			and records[1].address == "127.0.0.1",
			"LAN discovery response was not retained")
		local discovery_status = browser:status()
		assert(discovery_status.refresh_count >= 1
			and discovery_status.last_response_at
			and discovery_status.destinations[LANDiscovery.GROUP]
			and discovery_status.destinations[LANDiscovery.BROADCAST],
			"LAN discovery diagnostics omitted attempts or responses")
		browser.records = {}
		browser.last_response_at = nil
		browser.first_refresh_at = socket.gettime()
			- LANDiscovery.DIAGNOSTIC_TIMEOUT - 1
		assert(browser:status().timed_out,
			"LAN discovery never reaches its diagnostic timeout")
	end)
	if browser then browser:close() end
	if responder then responder:close() end
	assert(discovery_ok, discovery_error)

	local hello = Protocol.hello({
		game_version = "test-version",
		content_hash = test_content_hash,
		capabilities = {
			"snapshot-v1", "input-v1", "actions-v1", "reliable-streams-v2",
			"pose-v1",
		},
		client_nonce = client_nonce,
	})
	local encoded = Protocol.encode("hello", hello)
	local decoded = assert(Protocol.decode(encoded))
	assert(decoded.kind == "hello"
		and decoded.payload.client_nonce == client_nonce,
		"protocol control message did not round-trip")
	local incomplete_hello = Protocol.hello({
		game_version = "test-version",
		content_hash = test_content_hash,
		capabilities = { "snapshot-v1" },
		client_nonce = incomplete_nonce,
	})
	local capability_ok, capability_error = Protocol.validate_hello(
		incomplete_hello,
		{ game_version = "test-version", content_hash = test_content_hash }
	)
	assert(not capability_ok and capability_error == "missing_capability",
		"handshake accepted a client without required capabilities")
	local invalid_hash_hello = Protocol.hello({
		game_version = "test-version",
		content_hash = "not-a-sha256",
		capabilities = {
			"snapshot-v1", "input-v1", "actions-v1", "reliable-streams-v2",
			"pose-v1",
		},
		client_nonce = client_nonce,
	})
	local hash_ok, hash_error = Protocol.validate_hello(invalid_hash_hello, {
		game_version = "test-version",
		content_hash = test_content_hash,
	})
	assert(not hash_ok and hash_error == "invalid_content_hash",
		"handshake accepted a malformed content hash")
	local resume_hello = {}
	for key, value in pairs(hello) do resume_hello[key] = value end
	resume_hello.reconnect_token = string.rep("4", 64)
	local resume_mode_ok, resume_mode_error = Protocol.validate_hello(
		resume_hello,
		{ game_version = "test-version", content_hash = test_content_hash }
	)
	assert(not resume_mode_ok and resume_mode_error == "invalid_resume_mode",
		"reconnect handshake accepted an ambiguous recovery mode")
	resume_hello.resume_mode = "snapshot"
	assert(Protocol.validate_hello(resume_hello, {
		game_version = "test-version",
		content_hash = test_content_hash,
	}), "snapshot recovery handshake was rejected")
	assert(not Protocol.decode(string.rep("x", Protocol.MAX_MESSAGE_BYTES + 1)),
		"oversized protocol message was accepted")
	local initial_retry_runtime = Runtime.new({ registry = ActorRegistry.new() })
	initial_retry_runtime.role = "client"
	initial_retry_runtime.client_state = "awaiting_approval"
	initial_retry_runtime.peer = {}
	initial_retry_runtime.early_snapshot_chunks = { "stale-snapshot-chunk" }
	initial_retry_runtime.early_snapshot_bytes = 20
	initial_retry_runtime.transport = {
		disconnect = function() return true end,
	}
	assert(initial_retry_runtime:_handle_transport_loss(
		"initial-handshake-loss", initial_retry_runtime.peer
	) and initial_retry_runtime.client_state == "reconnecting"
		and initial_retry_runtime.client_resume_mode == "initial"
		and #initial_retry_runtime.early_snapshot_chunks == 0
		and initial_retry_runtime.early_snapshot_bytes == 0,
		"pre-welcome transport loss retained stale snapshot chunks or was not retried")
	local repeated_snapshot_runtime = Runtime.new({ registry = ActorRegistry.new() })
	repeated_snapshot_runtime.role = "client"
	repeated_snapshot_runtime.client_state = "resuming"
	repeated_snapshot_runtime.client_resume_mode = "snapshot"
	repeated_snapshot_runtime.client_welcome = {
		session_id = string.rep("8", 64),
		reconnect_token = string.rep("9", 64),
		actor_id = "guest",
		snapshot_version = Protocol.SNAPSHOT_VERSION,
	}
	repeated_snapshot_runtime.peer = {}
	repeated_snapshot_runtime.early_snapshot_chunks = { "partial-retry-chunk" }
	repeated_snapshot_runtime.early_snapshot_bytes = 19
	repeated_snapshot_runtime.transport = {
		disconnect = function() return true end,
	}
	assert(repeated_snapshot_runtime:_handle_transport_loss(
		"repeated-snapshot-loss", repeated_snapshot_runtime.peer
	) and repeated_snapshot_runtime.client_state == "reconnecting"
		and repeated_snapshot_runtime.client_resume_mode == "snapshot"
		and #repeated_snapshot_runtime.early_snapshot_chunks == 0,
		"a repeated snapshot interruption switched to stream recovery")
	local initial_timeout_runtime = Runtime.new({ registry = ActorRegistry.new() })
	assert(initial_timeout_runtime.heartbeat_interval
		== Runtime.DEFAULT_HEARTBEAT_INTERVAL
		and initial_timeout_runtime.heartbeat_timeout
			== Runtime.DEFAULT_HEARTBEAT_TIMEOUT
		and initial_timeout_runtime.reconnect_timeout
			== Runtime.DEFAULT_RECONNECT_TIMEOUT,
		"runtime defaults do not survive an ordinary laptop idle/suspend period")
	local initial_timeout_status = initial_timeout_runtime:status()
	assert(initial_timeout_status.heartbeat.timeout
		== Runtime.DEFAULT_HEARTBEAT_TIMEOUT
		and initial_timeout_status.heartbeat.reconnect_timeout
			== Runtime.DEFAULT_RECONNECT_TIMEOUT,
		"network status does not expose heartbeat/reconnect diagnostics")
	initial_timeout_runtime.role = "client"
	initial_timeout_runtime.client_state = "connecting"
	initial_timeout_runtime.client_deadline = love.timer.getTime() - 1
	initial_timeout_runtime.peer = {}
	initial_timeout_runtime.transport = {
		disconnect = function() return true end,
	}
	assert(initial_timeout_runtime:_update_client_timeout()
		and initial_timeout_runtime.client_state == "reconnecting"
		and initial_timeout_runtime.client_resume_mode == "initial",
		"initial connection timeout was not retried")
	local suspend_runtime = Runtime.new({ registry = ActorRegistry.new() })
	suspend_runtime.role = "client"
	suspend_runtime.client_state = "playing"
	suspend_runtime.client_welcome = {
		session_id = string.rep("8", 64),
		reconnect_token = string.rep("9", 64),
	}
	suspend_runtime.peer = {}
	suspend_runtime.transport = {
		disconnect = function() return true end,
	}
	assert(suspend_runtime:_handle_transport_loss(
		"simulated_laptop_suspend",
		suspend_runtime.peer
	) and suspend_runtime.client_state == "reconnecting"
		and suspend_runtime:status().heartbeat.reconnect_remaining
			> Runtime.DEFAULT_RECONNECT_TIMEOUT - 1,
		"a suspended client did not retain a long reconnect window")

	local registry = ActorRegistry.new()
	local host = ActorState.new({ actor_id = "host", actor_role = "host" })
	host.inv = {}
	host.invsize = 9
	host.unlock_i = {}
	host.unlock_c = {}
	host.visited = {}
	host.ferted = {}
	host.stats = { body = { hp = 100, maxhp = 100, pc = 100, d = 0 } }
	host.state = "idle"
	host.oldstate = "idle"
	registry:bind_host(host, {})

	local clock = 0
	local drops = 0
	local dropped_items = 0
	local session_token = string.rep("f", 64)
	local reconnect_token = string.rep("1", 64)
	local session = Session.new({
		registry = registry,
		clock = function() return clock end,
		token_factory = function(prefix)
			return prefix == "session" and session_token or reconnect_token
		end,
			reconnect_timeout = 15,
			input_rate = 1,
			input_burst = 2,
		dropper = function(guest)
			drops = drops + 1
			dropped_items = #ActorInventory.drain_items(guest)
			return true
		end,
	})
	local expected = {
		game_version = "test-version",
		content_hash = test_content_hash,
	}
	local suspend_clock = 0
	local suspend_registry = ActorRegistry.new()
	local suspend_host = process_test_actor(suspend_registry)
	local default_session = Session.new({
		registry = suspend_registry,
		clock = function() return suspend_clock end,
		token_factory = function(prefix)
			return prefix == "session" and string.rep("6", 64)
				or string.rep("7", 64)
		end,
		dropper = function() return true end,
	})
	assert(default_session.reconnect_timeout
		== Session.DEFAULT_RECONNECT_TIMEOUT
		and default_session:begin_join(hello, expected, suspend_clock)
		and default_session:approve(suspend_host, { xt = 1, yt = 1 })
		and default_session:snapshot_sent(1)
		and default_session:ready(1)
		and default_session:disconnect(
			"simulated_laptop_suspend",
			false,
			suspend_clock
		), "could not create a suspended guest session")
	suspend_clock = 60
	assert(default_session:update(suspend_clock)
		and default_session.state == Session.STATE.RECONNECT_GRACE
		and default_session.guest ~= nil
		and default_session:resume(string.rep("7", 64)),
		"host discarded a sleeping guest before its reconnect window")
	assert(default_session:shutdown(),
		"suspend recovery fixture did not clean up")
	assert(session:begin_join(hello, expected, clock))
	assert(session.state == Session.STATE.AWAITING_APPROVAL)
	local approved, welcome = session:approve(host, { xt = 10, yt = 20 })
	assert(approved and welcome.reconnect_token == reconnect_token)
	assert(session.guest and registry.guest == session.guest,
		"approved guest was not registered")
	local world_state = {}
		assert(ActorInventory.add(session.guest, { i = 31 }, world_state) == 1)
		assert(session:snapshot_sent(42))
		assert(not session:ready(41),
			"host accepted READY for a different snapshot tick")
		assert(session:ready(42))
	assert(session:accept_action("action:1"))
	assert(session:record_action_result("action:1", {
		action_id = "action:1",
		ok = true,
	}))
	local duplicate_action_ok, duplicate_action_error, cached_action_result =
		session:accept_action("action:1")
	assert(not duplicate_action_ok and duplicate_action_error == "duplicate_action"
		and cached_action_result and cached_action_result.ok,
		"duplicate action did not return its cached authoritative result")
	for index = 2, 60 do
		assert(session:accept_action("action:" .. tostring(index), clock))
	end
	local rate_ok, rate_error = session:accept_action("action:61", clock)
	assert(not rate_ok and rate_error == "action_rate_limited",
		"guest action burst was not rate limited")
	assert(session:record_action_result("action:61", {
		action_id = "action:61",
		ok = false,
		error = "action_rate_limited",
	}))
	local repeated_rate_ok, repeated_rate_error, repeated_rate_result =
		session:accept_action("action:61", clock + 10)
	assert(not repeated_rate_ok and repeated_rate_error == "duplicate_action"
		and repeated_rate_result and repeated_rate_result.ok == false
		and repeated_rate_result.error == "action_rate_limited",
		"a retried rate-limited transaction changed its authoritative result")
	local input = InputState.new()
		InputState.set_button(input, "a", true)
		InputState.advance(input)
		assert(session:accept_input(InputState.snapshot(input)))
		local authoritative_input = registry:runtime(session.guest).input
		local malformed_input = {
			sequence = 2,
			held = { a = true },
			aim = { world_x = math.huge },
		}
		assert(not InputState.apply_snapshot(authoritative_input, malformed_input)
			and authoritative_input.sequence == 1
			and InputState.is_down(authoritative_input, "a"),
			"malformed input partially replaced the last valid state")
		local duplicate_input_ok, duplicate_input_error = session:accept_input(
			InputState.snapshot(input)
		)
		assert(not duplicate_input_ok and duplicate_input_error == "stale_input",
			"duplicate input sequence was accepted")
		InputState.advance(input)
		assert(session:accept_input(InputState.snapshot(input)))
		InputState.advance(input)
		local input_rate_ok, input_rate_error = session:accept_input(InputState.snapshot(input))
		assert(not input_rate_ok and input_rate_error == "input_rate_limited",
			"guest input burst was not rate limited")

	clock = 10
	assert(session:disconnect("wifi", false, clock))
	assert(session.state == Session.STATE.RECONNECT_GRACE)
	local reconnect_deadline = session.deadline
	clock = 11
	assert(session:disconnect("wifi-again", false, clock)
		and session.deadline == reconnect_deadline,
		"unauthenticated reconnect churn extended the reserved session")
	assert(not session:resume(string.rep("0", 64)))
	assert(session:resume(reconnect_token))
	assert(session.state == Session.STATE.PLAYING)
	assert(session:disconnect("wifi", false, clock))
	assert(session:resume_snapshot(reconnect_token, clock)
		and session.state == Session.STATE.SENDING_SNAPSHOT,
		"interrupted snapshot could not restart under the reconnect token")
	assert(session:snapshot_sent(43) and session:ready(43))
	assert(session:disconnect("wifi", false, clock))
	clock = 27
	assert(session:update(clock))
	assert(drops == 1 and dropped_items == 1,
		"guest possessions were not dropped exactly once")
	assert(session.state == Session.STATE.LISTENING and registry.guest == nil
		and session.client_nonce == nil and next(session.dropped_sessions) == nil,
		"expired guest session was not cleaned up")
	assert(session:update(clock + 100) and drops == 1,
		"finished session repeated possession drop")
	for cycle = 1, 128 do
		assert(session:begin_join(hello, expected, clock))
		assert(session:approve(host, { xt = 10, yt = 20 }))
		assert(session:snapshot_sent(100 + cycle))
		assert(session:ready(100 + cycle))
		assert(session:disconnect("cycle", true, clock))
	end
	assert(drops == 129 and next(session.dropped_sessions) == nil,
		"completed join/drop cycles retained session ids or repeated cleanup")

	local timeout_clock = 0
	local timeout_drops = 0
	local timeout_registry = ActorRegistry.new()
	timeout_registry:bind_host(host, {})
	local timeout_session = Session.new({
		registry = timeout_registry,
		clock = function() return timeout_clock end,
		token_factory = function(prefix)
			return prefix == "session" and string.rep("2", 64)
				or string.rep("3", 64)
		end,
		snapshot_timeout = 2,
		catchup_timeout = 2,
		dropper = function()
			timeout_drops = timeout_drops + 1
			return true
		end,
	})
	assert(timeout_session:begin_join(hello, expected, timeout_clock))
	assert(timeout_session:approve(host, { xt = 10, yt = 20 }))
	assert(timeout_session:snapshot_sent(7))
	timeout_clock = 3
	local timed_out, timeout_reason = timeout_session:update(timeout_clock)
	assert(timed_out and timeout_reason == "catchup_timeout"
		and timeout_drops == 1
		and timeout_session.state == Session.STATE.LISTENING,
		"snapshot catch-up timeout did not clean the guest")

	local function empty_world()
		local result = {}
		for y = 1, 5 do
			result[y] = {}
			for x = 1, 5 do result[y][x] = {} end
		end
		return result
	end
	local possession_state = {}
	local carried_item = { i = 32 }
	local inventory_item = { i = 31 }
	ItemIdentity.ensure(carried_item, possession_state)
	ItemIdentity.ensure(inventory_item, possession_state)
	local possession_actor = {
		xt = 3,
		yt = 3,
		inv = { [1] = inventory_item },
		invselect = 1,
		iscarry = { b = 12, i = { carried_item } },
	}
	local projected_world = empty_world()
	local existing_ground_item = { i = 33 }
	ItemIdentity.ensure(existing_ground_item, possession_state)
	projected_world[3][3] = {
		b = 0,
		w = 500,
		room = 7,
		i = { existing_ground_item },
	}
	local projected, projection_report = GuestPossessions.project(possession_actor, {
		world = projected_world,
		fallback_x = 1,
		fallback_y = 1,
	})
	assert(projected and projection_report.items == 1 and projection_report.block,
		"guest possessions were not projected into save world")
	assert(possession_actor.inv[1] == inventory_item and possession_actor.iscarry,
		"save projection mutated live guest possessions")
	assert(projected_world[3][3].b == 12
		and projected_world[3][3].w == 500
		and projected_world[3][3].room == 7
		and #projected_world[3][3].i == 3,
		"carried block projection destroyed environmental data or ground items")
	local dropped_world = empty_world()
	local dropped, drop_report = GuestPossessions.drop(possession_actor, {
		world = dropped_world,
		fallback_x = 1,
		fallback_y = 1,
	})
	assert(dropped and drop_report.items == 1 and drop_report.block,
		"guest possessions were not dropped into live world")
	assert(next(possession_actor.inv) == nil and possession_actor.iscarry == nil,
		"dropped possessions remained attached to guest actor")

	do
		local dense_world = {}
		for y = 1, 17 do
			dense_world[y] = {}
			for x = 1, 17 do dense_world[y][x] = { b = 1 } end
		end
		local dense_actor = {
			xt = 9,
			yt = 9,
			inv = { [1] = { i = 31 } },
			invselect = 1,
			iscarry = { b = 12 },
		}
		local dense_drop, dense_drop_error = GuestPossessions.drop(dense_actor, {
			world = dense_world,
			fallback_x = 9,
			fallback_y = 9,
		})
		assert(not dense_drop and dense_drop_error == "no room for carried block",
			"dense-world possession regression was not reproduced")
		local dense_recovery = {}
		assert(GuestPossessions.stash(dense_actor, dense_recovery, {
			session_id = string.rep("6", 64),
			reason = dense_drop_error,
		}))
		assert(#dense_recovery == 1 and dense_recovery[1].iscarry.b == 12
			and dense_recovery[1].inv[1].i == 31
			and next(dense_actor.inv) == nil and dense_actor.iscarry == nil,
			"dense-world fallback lost or duplicated guest possessions")
		local dense_registry = ActorRegistry.new()
		dense_registry:bind_host(host, {})
		local cleanup_recovery = {}
		local dense_session = Session.new({
			registry = dense_registry,
			clock = function() return clock end,
			token_factory = function(prefix)
				return prefix == "session" and string.rep("6", 64)
					or string.rep("7", 64)
			end,
			dropper = function(guest, id)
				local recovered, recovery_error = GuestPossessions.drop(guest, {
					world = dense_world,
					fallback_x = 9,
					fallback_y = 9,
				})
				if recovered then return true end
				return GuestPossessions.stash(guest, cleanup_recovery, {
					session_id = id,
					reason = recovery_error,
				})
			end,
		})
		assert(dense_session:begin_join(hello, expected, clock))
		assert(dense_session:approve(host, { xt = 9, yt = 9 }))
		dense_session.guest.inv = { [1] = { i = 32 } }
		dense_session.guest.iscarry = { b = 12 }
		assert(dense_session:snapshot_sent(300) and dense_session:ready(300))
		assert(dense_session:disconnect("dense", true, clock))
		assert(dense_session.state == Session.STATE.LISTENING
			and dense_registry.guest == nil
			and #cleanup_recovery == 1
			and next(dense_session.dropped_sessions) == nil,
			"dense-world fallback left the session stuck in DROPPING")
		assert(dense_session:shutdown()
			and dense_session.state == Session.STATE.SHUTDOWN,
			"dense-world recovery prevented host shutdown")
	end

	local snapshot_session_id = string.rep("4", 64)
	local snapshot = NetworkSnapshot.capture({
		world = { [1] = { [1] = { b = 12 } } },
		game = { world_id = world_id, time = 123, pause = true },
		host_actor = host,
		guest_actor = GhostActor.new(host, { session_id = snapshot_session_id }),
		tips = { a = true },
		disp = {},
		mobs = {},
		tick = 77,
		session_id = snapshot_session_id,
	})
	assert(snapshot.game.pause == nil, "network snapshot copied local pause state")
	local stored, snapshot_meta = NetworkSnapshot.serialize(snapshot)
	local snapshot_chunks, chunk_meta = NetworkSnapshot.chunks(stored, snapshot_meta, 1024)
	local assembler = assert(NetworkSnapshot.new_assembler(chunk_meta))
	for index = #snapshot_chunks, 1, -1 do
		assert(assembler:add(snapshot_chunks[index]))
	end
	local restored_snapshot = assert(assembler:finish())
	assert(restored_snapshot.header.tick == 77
		and restored_snapshot.world[1][1].b == 12
		and restored_snapshot.guest_actor.actor_role == "guest",
		"fragmented network snapshot did not round-trip")
	local malformed_meta = {}
	for key, value in pairs(chunk_meta) do malformed_meta[key] = value end
	malformed_meta.stored_size = tostring(malformed_meta.stored_size)
	assert(not NetworkSnapshot.new_assembler(malformed_meta),
		"snapshot assembler accepted string metadata sizes")
	local wrong_tick_meta = {}
	for key, value in pairs(chunk_meta) do wrong_tick_meta[key] = value end
	wrong_tick_meta.tick = wrong_tick_meta.tick + 1
	local wrong_tick_assembler = assert(NetworkSnapshot.new_assembler(wrong_tick_meta))
	for _, packet in ipairs(snapshot_chunks) do assert(wrong_tick_assembler:add(packet)) end
	local mismatched_snapshot, mismatch_error = wrong_tick_assembler:finish()
	assert(not mismatched_snapshot and mismatch_error == "snapshot metadata mismatch",
		"snapshot body was not matched to its metadata")
	local malformed_chunk_assembler = assert(NetworkSnapshot.new_assembler(chunk_meta))
	local chunk_ok, chunk_error = malformed_chunk_assembler:add(
		snapshot_chunks[1] .. "x"
	)
	assert(not chunk_ok and chunk_error == "invalid snapshot chunk size",
		"snapshot assembler accepted a malformed chunk size")
	local ready_assembler = assert(NetworkSnapshot.new_assembler(chunk_meta))
	for _, packet in ipairs(snapshot_chunks) do assert(ready_assembler:add(packet)) end
	local ready_peer = {}
	local ready_runtime = Runtime.new({
		registry = ActorRegistry.new(),
		state_applier = function() return true end,
	})
	ready_runtime.role = "client"
	ready_runtime.peer = ready_peer
	ready_runtime.client_state = "receiving_snapshot"
	ready_runtime.client_welcome = {
		session_id = snapshot_session_id,
		reconnect_token = string.rep("5", 64),
		actor_id = "guest",
		snapshot_version = Protocol.SNAPSHOT_VERSION,
	}
	ready_runtime.assembler = ready_assembler
	ready_runtime.snapshot_done_tick = chunk_meta.tick
	ready_runtime.transport = {
		send = function(_, _, kind)
			if kind == "ready" then return false, "temporary ready failure" end
			return true
		end,
		disconnect = function() return true end,
	}
	assert(ready_runtime:_finish_client_snapshot()
		and ready_runtime.client_state == "reconnecting"
		and ready_runtime.client_resume_mode == "stream",
		"READY send failure discarded an already applied snapshot")

	do
	local BlobWriter = require("src.BlobWriter")
	local replicated_actor = NetworkReplication.capture_actor(restored_snapshot.guest_actor)
	local state_packet = NetworkReplication.encode_state({
		tick = 78,
		guest_actor = replicated_actor,
		mobs = { [1] = { id = 4, truex = 32, truey = 64 } },
	})
	local restored_state, restored_kind = NetworkReplication.decode(state_packet)
	assert(restored_kind == "state" and restored_state.tick == 78
		and restored_state.guest_actor.actor_role == "guest"
		and restored_state.mobs[1].truey == 64,
		"authoritative state packet did not round-trip")
	local pose_packet = NetworkReplication.encode_pose({
		pose_schema = 1,
		tick = 79,
		sample_time = 2.5,
		input_sequence = 9,
		guest_actor = NetworkReplication.capture_actor(
			restored_snapshot.guest_actor,
			NetworkReplication.ACTOR_POSE_FIELDS
		),
	})
	local restored_pose, restored_pose_kind = NetworkReplication.decode(pose_packet)
	assert(restored_pose_kind == "pose" and restored_pose.tick == 79
		and restored_pose.input_sequence == 9
		and restored_pose.guest_actor.actor_role == "guest",
		"authoritative pose packet did not round-trip")
	local function smoke_u32_be(value)
		return string.char(
			math.floor(value / 2 ^ 24) % 256,
			math.floor(value / 2 ^ 16) % 256,
			math.floor(value / 2 ^ 8) % 256,
			value % 256
		)
	end
	local function smoke_u32_le(value)
		return string.char(
			value % 256,
			math.floor(value / 2 ^ 8) % 256,
			math.floor(value / 2 ^ 16) % 256,
			math.floor(value / 2 ^ 24) % 256
		)
	end
	local original_decompress = love.data.decompress
	local decompress_calls = 0
	love.data.decompress = function(...)
		decompress_calls = decompress_calls + 1
		return original_decompress(...)
	end
	local declared_bomb, declared_bomb_error = NetworkReplication.decode(
		NetworkReplication.STATE_MAGIC
			.. smoke_u32_be(NetworkReplication.MAX_RAW_BYTES + 1)
			.. state_packet:sub(NetworkReplication.HEADER_SIZE + 1)
	)
	local wrong_size, wrong_size_error = NetworkReplication.decode(
		NetworkReplication.STATE_MAGIC
			.. smoke_u32_be(NetworkReplication.MAX_RAW_BYTES)
			.. state_packet:sub(NetworkReplication.HEADER_SIZE + 1)
	)
	local internal_bomb, internal_bomb_error = NetworkReplication.decode(
		NetworkReplication.STATE_MAGIC
			.. smoke_u32_be(NetworkReplication.MAX_RAW_BYTES)
			.. smoke_u32_le(NetworkReplication.MAX_RAW_BYTES + 1)
			.. state_packet:sub(NetworkReplication.HEADER_SIZE + 5)
	)
	love.data.decompress = original_decompress
	assert(not declared_bomb
		and declared_bomb_error == "replication raw size is invalid"
		and not wrong_size
		and wrong_size_error == "replication raw size mismatch"
		and not internal_bomb
		and internal_bomb_error == "replication LZ4 raw size is invalid"
		and decompress_calls == 0,
		"replication raw-size preflight ran after a dangerous allocation")
	local trailing_writer = BlobWriter()
	trailing_writer:write({ first = true })
	trailing_writer:write({ second = true })
	local trailing_raw = trailing_writer:tostring()
	local trailing_packet = NetworkReplication.STATE_MAGIC
		.. smoke_u32_be(#trailing_raw)
		.. love.data.compress("string", "lz4", trailing_raw)
	local trailing_value, trailing_error = NetworkReplication.decode(trailing_packet)
	assert(not trailing_value and tostring(trailing_error):find(
		"trailing replication data", 1, true
	), "replication decoder accepted trailing serialized values")
	end
	local InterpolationBuffer = require("src.network.interpolation_buffer")
	local interpolation = InterpolationBuffer.new({ delay = 0.11 })
	assert(interpolation:push(0, {
		actors = { host = { x = 0, y = 20 } },
	}, 10))
	assert(interpolation:push(0.1, {
		actors = { host = { x = 10, y = 30 } },
	}, 10.1))
	local interpolation_frame = assert(interpolation:frame(10.15))
	local interpolated_x, interpolated_y = InterpolationBuffer.position(
		interpolation_frame, "actors", "host"
	)
	assert(interpolated_x > 3.9 and interpolated_x < 4.1
		and interpolated_y > 23.9 and interpolated_y < 24.1,
		"remote render state did not interpolate between buffered snapshots")
	assert(interpolation:seed_latest("projectiles", 7, 4, 5)
		and interpolation.samples[#interpolation.samples]
			.positions.projectiles[7].x == 4,
		"a new projectile could not be seeded at its owner's position")
	do
		local function simulate_jump(render_hz)
			local accumulator, y, yspeed, steps = 0, 0, -9.5, 0
			local frame_count = math.floor(render_hz * 0.2 + 0.5)
			for _ = 1, frame_count do
				local executed
				accumulator, executed = FixedStep.advance(
					accumulator,
					1 / render_hz,
					function()
						yspeed = math.min(12, yspeed + 0.7)
						y = y + yspeed
					end
				)
				steps = steps + executed
			end
			return y, yspeed, steps, accumulator
		end

		local expected_y, expected_speed, expected_steps = simulate_jump(60)
		assert(expected_steps == 6, "fixed-step reference used the wrong tick count")
		for _, render_hz in ipairs({ 30, 120 }) do
			local y, yspeed, steps, accumulator = simulate_jump(render_hz)
			assert(steps == expected_steps
				and math.abs(y - expected_y) < 1e-9
				and math.abs(yspeed - expected_speed) < 1e-9
				and accumulator >= 0 and accumulator < FixedStep.STEP,
				("network movement diverged at %d FPS"):format(render_hz))
		end
		local bounded_calls = 0
		local bounded_accumulator, bounded_steps = FixedStep.advance(0, 10, function()
			bounded_calls = bounded_calls + 1
		end)
		assert(bounded_steps == FixedStep.MAX_STEPS
			and bounded_calls == FixedStep.MAX_STEPS
			and bounded_accumulator >= 0
			and bounded_accumulator < FixedStep.STEP,
			"fixed-step catch-up exceeded its stall budget")

		local function simulate_stepup(render_hz)
			local actor = ActorState.ensure({
				actor_id = "guest", actor_role = "guest",
				state = "stepup", oldstate = "stepup",
				x = 100, y = 100, flip = 1, anispeed = 1,
				animation = { frame = 1, time = 0, cycle = 0 },
			})
			local definitions = {
				stepup = {
					cnt = 3, dur = { 1, 1, 1 }, ani = { 2, 3, "walk" },
					add = { [2] = { 3, -12 }, [3] = { 7, -10 } },
					exitfr = 1,
				},
				walk = { cnt = 1, dur = { 1000 }, ani = { 1 } },
			}
			local accumulator = 0
			for _ = 1, math.floor(render_hz * 0.2 + 0.5) do
				accumulator = FixedStep.advance(
					accumulator,
					1 / render_hz,
					function(fixed_dt)
						PlayerAnimation.update(actor, fixed_dt, definitions)
					end
				)
			end
			return actor
		end
		local expected_stepup = simulate_stepup(60)
		for _, render_hz in ipairs({ 30, 120 }) do
			local actor = simulate_stepup(render_hz)
			assert(actor.x == expected_stepup.x and actor.y == expected_stepup.y
				and actor.state == expected_stepup.state
				and actor.animation.frame == expected_stepup.animation.frame,
				("scripted movement diverged at %d FPS"):format(render_hz))
		end
	end
	local journal = WorldJournal.new()
	local delta_world = { [2] = { [3] = { b = 12, i = { { i = 31 } } } } }
	assert(journal:record(3, 2) and journal:record(3, 2))
	local delta = assert(journal:drain(delta_world, 64, 79))
	assert(#delta.cells == 1 and delta.cells[1].cell.b == 12,
		"world journal did not coalesce a changed cell")
	local world_packet = NetworkReplication.encode_world(delta)
	local restored_delta, delta_kind = NetworkReplication.decode(world_packet)
	assert(delta_kind == "world" and restored_delta.cells[1].cell.i[1].i == 31,
		"world delta packet did not round-trip")
	local outbox_world_provided = false
	local outbox_event_provided = false
	local outbox_world_attempts = 0
	local outbox_event_attempts = 0
	local outbox_send_order = {}
	local outbox_peer = {}
	local outbox_runtime = Runtime.new({
		registry = ActorRegistry.new(),
		world_interval = 0.001,
		world_delta_provider = function()
			if outbox_world_provided then return nil end
			outbox_world_provided = true
			return {
				sequence = 1,
				tick = 1,
				cells = { { x = 1, y = 1, cell = { b = 5 } } },
			}
		end,
		event_provider = function()
			if outbox_event_provided then return nil end
			outbox_event_provided = true
			return { kind = "test", event_id = 1 }
		end,
	})
	outbox_runtime.role = "host"
	outbox_runtime.peer = outbox_peer
	outbox_runtime.session = {
		state = Session.STATE.PLAYING,
		session_id = string.rep("8", 64),
	}
	outbox_runtime.transport = {
		send_raw = function(_, _, packet)
			local kind = packet:sub(1, 4) == NetworkReplication.WORLD_MAGIC
				and "world" or assert(Protocol.decode(packet)).kind
			outbox_send_order[#outbox_send_order + 1] = kind
			if kind == "world" then
				outbox_world_attempts = outbox_world_attempts + 1
				if outbox_world_attempts == 1 then
					return false, "temporary world failure"
				end
			elseif kind == "event" then
				outbox_event_attempts = outbox_event_attempts + 1
				if outbox_event_attempts == 1 then
					return false, "temporary event failure"
				end
			end
			return true
		end,
		send = function(_, _, kind)
			outbox_send_order[#outbox_send_order + 1] = kind
			return true
		end,
		flush = function() end,
		disconnect = function() return true end,
	}
	outbox_runtime:_publish(0.01)
	assert(#outbox_runtime.world_outbox == 1
		and #outbox_runtime.event_outbox == 1
		and outbox_runtime.world_outbox[1].sent == false
		and outbox_runtime.event_outbox[1].sent == false,
		"runtime discarded a reliable item after send failure")
	outbox_runtime:_publish(0.01)
	assert(outbox_runtime.world_outbox[1].sent == true
		and outbox_runtime.event_outbox[1].sent == true,
		"runtime did not retry retained reliable items")
	outbox_runtime.resume_phase = "waiting_ready"
	outbox_runtime.resume_deadline = love.timer.getTime() + 1
	outbox_runtime:_host_message({ peer = outbox_peer }, {
		kind = "resume_ready",
		payload = { world_sequence = 0, event_id = 0 },
	})
	assert(outbox_runtime.resume_phase == "sending_sync"
		and not outbox_runtime.world_outbox[1].sent
		and not outbox_runtime.event_outbox[1].sent,
		"resume handshake did not mark unacknowledged streams for replay")
	assert(outbox_runtime:_advance_resume_sync())
	assert(outbox_runtime.resume_phase == "sending_sync"
		and outbox_send_order[#outbox_send_order - 1] == "world"
		and outbox_send_order[#outbox_send_order] == "event",
		"resume replay did not precede its synchronization barrier")
	assert(outbox_runtime:_acknowledge_streams({
		world_sequence = 1,
		event_id = 1,
	}))
	assert(#outbox_runtime.world_outbox == 0 and #outbox_runtime.event_outbox == 0
		and outbox_runtime.world_outbox_bytes == 0
		and outbox_runtime.event_outbox_bytes == 0,
		"acknowledged stream items remained in the outbox")
	assert(outbox_runtime:_advance_resume_sync())
	assert(outbox_runtime.resume_phase == nil
		and outbox_send_order[#outbox_send_order] == "resume_synced",
		"resume barrier was sent before replay was applied and acknowledged")
	assert(not outbox_runtime:_queue_event({ kind = "test", event_id = 3 }),
		"host accepted a gap in the reliable event stream")
	local source_sound = { kind = "sound", event_id = 1 }
	local source_sound_available = true
	local source_sound_runtime = Runtime.new({
		registry = ActorRegistry.new(),
		event_provider = function()
			if not source_sound_available then return nil end
			source_sound_available = false
			return source_sound
		end,
	})
	source_sound_runtime.role = "host"
	source_sound_runtime.peer = {}
	source_sound_runtime.session = { state = Session.STATE.PLAYING }
	source_sound_runtime.resume_phase = "sending_sync"
	source_sound_runtime.transport = {
		send_raw = function() return true end,
	}
	assert(source_sound_runtime:_drain_event_stream(1)
		and source_sound_runtime.event_outbox[1].event.replayed == true,
		"sound waiting in the producer queue survived reconnect as fresh audio")
	local stalled_peer = {}
	local stalled_disconnect_reason
	local stalled_runtime = Runtime.new({ registry = ActorRegistry.new() })
	stalled_runtime.role = "host"
	stalled_runtime.peer = stalled_peer
	stalled_runtime.stream_ack_timeout = 6
	stalled_runtime.world_outbox = { {
		sequence = 1,
		packet = "stalled-world",
		bytes = 13,
		sent = true,
	} }
	stalled_runtime.world_outbox_bytes = 13
	stalled_runtime.world_ack_progress_at = love.timer.getTime() - 7
	stalled_runtime.session = {
		state = Session.STATE.PLAYING,
		disconnect = function(self, reason)
			stalled_disconnect_reason = reason
			self.state = Session.STATE.RECONNECT_GRACE
			return true
		end,
	}
	stalled_runtime.transport = {
		disconnect = function() return true end,
	}
	stalled_runtime.resume_phase = "waiting_ready"
	assert(stalled_runtime:_check_stream_health()
		and stalled_runtime.peer == stalled_peer,
		"old acknowledgement timer interrupted an authenticated reconnect")
	stalled_runtime.resume_phase = nil
	local stalled_ok, stalled_error = stalled_runtime:_check_stream_health()
	assert(not stalled_ok and stalled_error == "world_stream_ack_timeout"
		and stalled_disconnect_reason == "world_stream_ack_timeout"
		and stalled_runtime.peer == nil
		and not stalled_runtime.world_outbox[1].sent,
		"stalled application acknowledgements did not trigger recoverable replay")

	local sequence_peer = {}
	local sequence_event_calls = 0
	local sequence_ack_calls = 0
	local sequence_disconnected = false
	local sequence_runtime = Runtime.new({
		registry = ActorRegistry.new(),
		event_handler = function()
			sequence_event_calls = sequence_event_calls + 1
			return true
		end,
	})
	sequence_runtime.role = "client"
	sequence_runtime.client_state = "playing"
	sequence_runtime.peer = sequence_peer
	sequence_runtime.client_welcome = {
		session_id = string.rep("9", 64),
		reconnect_token = string.rep("a", 64),
	}
	sequence_runtime.received_event_id = 1
	sequence_runtime.transport = {
		send = function(_, _, kind)
			if kind == "stream_ack" then sequence_ack_calls = sequence_ack_calls + 1 end
			return true
		end,
		flush = function() end,
		disconnect = function()
			sequence_disconnected = true
			return true
		end,
	}
	sequence_runtime:_client_message({
		kind = "event",
		payload = { kind = "test", event_id = 1 },
	})
	assert(sequence_runtime:_flush_stream_ack(true))
	assert(sequence_event_calls == 0 and sequence_ack_calls == 1,
		"duplicate reliable event was presented or not cumulatively acknowledged")
	sequence_runtime:_client_message({
		kind = "event",
		payload = { kind = "test", event_id = 3 },
	})
	assert(not sequence_disconnected and sequence_runtime.peer == sequence_peer
		and sequence_runtime.client_state == "playing"
		and sequence_runtime.received_event_id == 1
		and sequence_runtime.event_reorder_count == 1,
		"event sequence gap was applied or discarded instead of buffered")
	sequence_runtime:_client_message({
		kind = "event",
		payload = { kind = "test", event_id = 2 },
	})
	assert(sequence_event_calls == 2
		and sequence_runtime.received_event_id == 3
		and sequence_runtime.event_reorder_count == 0,
		"filling an event gap did not drain the ordered buffered tail")

	local world_gap_peer = {}
	local world_gap_applied = 0
	local world_gap_runtime = Runtime.new({
		registry = ActorRegistry.new(),
		world_delta_applier = function(delta)
			world_gap_applied = delta.sequence
			return true
		end,
	})
	world_gap_runtime.role = "client"
	world_gap_runtime.client_state = "playing"
	world_gap_runtime.peer = world_gap_peer
	world_gap_runtime.client_welcome = {
		session_id = string.rep("b", 64),
		reconnect_token = string.rep("c", 64),
	}
	world_gap_runtime.transport = {
		disconnect = function() return true end,
	}
	world_gap_runtime:_receive({
		peer = world_gap_peer,
		channel = Protocol.CHANNEL.WORLD,
		data = NetworkReplication.encode_world({
			sequence = 2,
			tick = 1,
			cells = {},
		}),
	})
	assert(world_gap_applied == 0 and world_gap_runtime.peer == world_gap_peer
		and world_gap_runtime.client_state == "playing"
		and world_gap_runtime.received_world_sequence == 0
		and world_gap_runtime.world_reorder_count == 1,
		"world sequence gap was applied or discarded instead of buffered")
	world_gap_runtime:_receive({
		peer = world_gap_peer,
		channel = Protocol.CHANNEL.WORLD,
		data = NetworkReplication.encode_world({
			sequence = 1,
			tick = 1,
			cells = {},
		}),
	})
	assert(world_gap_applied == 2
		and world_gap_runtime.received_world_sequence == 2
		and world_gap_runtime.world_reorder_count == 0,
		"filling a world gap did not drain the ordered buffered tail")
	local current_peer, stale_peer = {}, {}
	local stale_disconnect_delivered = false
	local stale_runtime = Runtime.new({ registry = ActorRegistry.new() })
	stale_runtime.role = "client"
	stale_runtime.client_state = "playing"
	stale_runtime.peer = current_peer
	stale_runtime.next_heartbeat = math.huge
	stale_runtime.transport = {
		poll = function()
			if stale_disconnect_delivered then return nil end
			stale_disconnect_delivered = true
			return { type = "disconnect", peer = stale_peer, data = 0 }
		end,
		send = function() return true end,
		flush = function() end,
		disconnect = function() return true end,
	}
	stale_runtime:update(0)
	assert(stale_runtime.peer == current_peer and stale_runtime.client_state == "playing",
		"late disconnect from an old peer cleared the active connection")

	local silent_registry = ActorRegistry.new()
	local silent_host = process_test_actor(silent_registry)
	local silent_closed = false
	local silent_runtime = Runtime.new({ registry = silent_registry })
	silent_runtime.role = "host"
	silent_runtime.peer = {}
	silent_runtime.transport = {
		port = 23999,
		poll = function() return nil end,
		send = function() return true end,
		flush = function() end,
		disconnect = function()
			silent_closed = true
			return true
		end,
	}
	silent_runtime.session = Session.new({
		registry = silent_registry,
		dropper = function() return true end,
	})
	silent_runtime.host_hello_deadline = 0
	silent_runtime.next_heartbeat = math.huge
	assert(not silent_runtime:advertisement().joinable,
		"host advertised a slot already occupied by a pre-hello peer")
	silent_runtime:update(0)
	assert(silent_closed and silent_runtime.peer == nil
		and silent_runtime.session.state == Session.STATE.LISTENING,
		"silent pre-hello peer was not evicted at its deadline")

	local approval_registry = ActorRegistry.new()
	local approval_host = process_test_actor(approval_registry)
	local approval_session = Session.new({
		registry = approval_registry,
		dropper = function() return true end,
	})
	assert(approval_session:begin_join(hello, expected))
	local approval_peer = {}
	local approval_event_delivered = false
	local approval_runtime = Runtime.new({ registry = approval_registry })
	approval_runtime.role = "host"
	approval_runtime.peer = approval_peer
	approval_runtime.session = approval_session
	approval_runtime.approval_request = { session_id = approval_session.session_id }
	approval_runtime.next_heartbeat = math.huge
	approval_runtime.transport = {
		poll = function()
			if approval_event_delivered then return nil end
			approval_event_delivered = true
			return { type = "disconnect", peer = approval_peer, data = 0 }
		end,
		send = function() return true end,
		flush = function() end,
		disconnect = function() return true end,
	}
	approval_runtime:update(0)
	assert(approval_runtime.approval_request == nil
		and approval_runtime:pending_approval() == nil,
		"transport disconnect retained a stale approval request")
	local integrity_closed = false
	local integrity_runtime = Runtime.new({
		registry = ActorRegistry.new(),
		world_delta_applier = function()
			return false, "invalid test delta"
		end,
	})
	integrity_runtime.role = "client"
	integrity_runtime.client_state = "playing"
	integrity_runtime.peer = {}
	integrity_runtime.transport = {
		send = function() return true end,
		flush = function() end,
		disconnect = function()
			integrity_closed = true
			return true
		end,
	}
	integrity_runtime:_receive({
		channelID = Protocol.CHANNEL.WORLD,
		data = world_packet,
	})
	assert(integrity_runtime.client_state == "failed"
		and integrity_runtime.last_error == "invalid test delta"
		and integrity_closed,
		"client ignored an explicitly rejected authoritative delta")
	local wrong_channel_closed = false
	local wrong_channel_runtime = Runtime.new({
		registry = ActorRegistry.new(),
		world_delta_applier = function() return true end,
	})
	wrong_channel_runtime.role = "client"
	wrong_channel_runtime.client_state = "playing"
	wrong_channel_runtime.peer = {}
	wrong_channel_runtime.transport = {
		send = function() return true end,
		flush = function() end,
		disconnect = function()
			wrong_channel_closed = true
			return true
		end,
	}
	wrong_channel_runtime:_receive({
		channelID = Protocol.CHANNEL.STATE,
		data = world_packet,
	})
	assert(wrong_channel_runtime.client_state == "failed"
		and wrong_channel_runtime.last_error == "replication received on invalid channel"
		and wrong_channel_closed,
		"client accepted replication on the wrong ENet channel")
	local retry_sends = 0
	local retry_runtime = Runtime.new({ registry = ActorRegistry.new() })
	retry_runtime.role = "client"
	retry_runtime.client_state = "playing"
	retry_runtime.peer = {}
	retry_runtime.transport = {
		send = function(_, _, kind)
			if kind == "action" then retry_sends = retry_sends + 1 end
			return true
		end,
		flush = function() end,
		disconnect = function() return true end,
	}
	assert(retry_runtime:send_action({ action_id = 77, action = "retry-test" }))
	assert(retry_sends == 1 and #retry_runtime.pending_action_order == 1,
		"client did not retain an unconfirmed action")
	retry_runtime.client_welcome = {
		session_id = string.rep("6", 64),
		reconnect_token = string.rep("7", 64),
		actor_id = "guest",
		snapshot_version = Protocol.SNAPSHOT_VERSION,
	}
	retry_runtime.client_resume_mode = "stream"
	retry_runtime.reconnect_deadline = love.timer.getTime() + 0.01
	retry_runtime.client_state = "resuming"
	retry_runtime:_client_message({
		kind = "welcome",
		payload = {
			resumed = true,
			resume_mode = "stream",
			session_id = string.rep("6", 64),
			reconnect_token = string.rep("7", 64),
			actor_id = "guest",
		},
	})
	assert(retry_runtime.client_state == "resuming_sync" and retry_sends == 1
		and retry_runtime.reconnect_deadline == nil
		and retry_runtime.client_deadline ~= nil,
		"stream synchronization retained the connect timer or replayed actions early")
	retry_runtime:_client_message({
		kind = "resume_synced",
		payload = {
			session_id = string.rep("6", 64),
			world_sequence = 0,
			event_id = 0,
		},
	})
	assert(retry_runtime.client_state == "playing" and retry_sends == 2,
		"client did not retry an unconfirmed action after synchronized reconnect")
	retry_runtime:_client_message({
		kind = "action_result",
		payload = { action_id = 77, ok = true },
	})
	assert(#retry_runtime.pending_action_order == 0,
		"client retained an acknowledged action")
	local sync_timeout_runtime = Runtime.new({ registry = ActorRegistry.new() })
	sync_timeout_runtime.role = "client"
	sync_timeout_runtime.client_state = "resuming_sync"
	sync_timeout_runtime.client_resume_mode = "stream"
	sync_timeout_runtime.client_welcome = {
		session_id = string.rep("d", 64),
		reconnect_token = string.rep("e", 64),
		actor_id = "guest",
		resumed = true,
		resume_mode = "stream",
	}
	sync_timeout_runtime.client_deadline = love.timer.getTime() - 1
	sync_timeout_runtime.peer = {}
	sync_timeout_runtime.transport = {
		disconnect = function() return true end,
	}
	assert(sync_timeout_runtime:_update_client_timeout()
		and sync_timeout_runtime.client_state == "reconnecting"
		and sync_timeout_runtime.client_resume_mode == "stream"
		and sync_timeout_runtime.last_error == "resume_sync_timeout",
		"stream synchronization timeout was terminal instead of recoverable")
	local queued_action_attempts = 0
	local queued_action_runtime = Runtime.new({
		registry = ActorRegistry.new(),
		action_retry_interval = 0.1,
	})
	queued_action_runtime.role = "client"
	queued_action_runtime.client_state = "playing"
	queued_action_runtime.peer = {}
	queued_action_runtime.next_heartbeat = math.huge
	queued_action_runtime.transport = {
		poll = function() return nil end,
		send = function(_, _, kind)
			if kind == "action" then
				queued_action_attempts = queued_action_attempts + 1
				if queued_action_attempts == 1 then return false, "temporary action failure" end
			end
			return true
		end,
		flush = function() end,
		disconnect = function() return true end,
	}
	assert(queued_action_runtime:send_action({
		action_id = 78,
		action = "queued-retry-test",
	}))
	assert(#queued_action_runtime.pending_action_order == 1,
		"client discarded an action whose first send failed")
	queued_action_runtime:update(0.11)
	assert(queued_action_attempts == 2,
		"client did not retry a locally queued action")
	local bounded_journal = WorldJournal.new({ max_pending = 1 })
	assert(bounded_journal:record(1, 1))
	local overflow_ok, overflow_error = bounded_journal:record(2, 1)
	local catchup_ok, catchup_error = bounded_journal:ready()
	assert(not overflow_ok and overflow_error == "world journal overflow"
		and not catchup_ok and catchup_error == "snapshot_catchup_overflow",
		"world catch-up overflow was not made explicit")
	bounded_journal:clear()
	assert(bounded_journal:ready(), "cleared catch-up journal stayed invalid")

	finish(0,
		"mode=network enet=true loopback=true socket=true discovery=true hash=true "
			.. "protocol=true handshake=true "
			.. "actions=true reconnect=true drop_once=true save_projection=true snapshot=true "
			.. "replication=true journal=true runtime_loopback=true runtime_reconnect=true "
			.. "runtime_reconnect_overflow=true timeouts=true rejection_cleanup=true")
end

local function validate_loaded_game(slot)
    assert(game_load(slot), "game_load returned false")
    assert(type(world) == "table" and next(world), "world is empty")
    assert(type(pl) == "table", "player state is missing")
    assert(type(pl.inv) == "table", "player inventory is missing")
    assert(type(game) == "table", "game state is missing")
    assert(type(vi) == "table", "camera state is missing")
	assert(type(mobs) == "table", "mob state is missing")
	local item_uids = {}
	for _, instance in pairs(pl.inv) do
		assert(type(instance.uid) == "string",
			"loaded inventory item has no stable uid")
		assert(not item_uids[instance.uid], "loaded inventory contains duplicate item uid")
		item_uids[instance.uid] = true
	end

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

local function begin_multiplayer_benchmark()
	local GhostActor = require("src.ghost_actor")
	local InputState = require("src.input_state")
	local PerformanceBudget = require("src.performance_budget")
	local PerformanceMetrics = require("src.performance_metrics")
	local Replication = require("src.network.replication")
	local socket = require("socket")
	local profile_name = os.getenv("SARCOPHAGUS_PERFORMANCE_PROFILE")
		or "reference"
	local performance_targets, profile_error =
		PerformanceBudget.targets_for_profile(profile_name)
	assert(performance_targets, profile_error)
	local renderer_name, renderer_version, renderer_vendor, renderer_device =
		love.graphics.getRendererInfo()
	local renderer = table.concat({
		tostring(renderer_name or "unknown"),
		tostring(renderer_version or "unknown"),
		tostring(renderer_vendor or "unknown"),
		tostring(renderer_device or "unknown"),
	}, "/"):gsub("[\r\n;]", " ")
	local original_identity = love.filesystem.getIdentity()
	local test_identity = "sarcophagus-multiplayer-benchmark"
	love.filesystem.setIdentity(test_identity)
	game_delete_save(9)
	local fixture, fixture_error = love.filesystem.read("tests/fixtures/9.sav")
	assert(fixture, "cannot read benchmark fixture: " .. tostring(fixture_error))
	assert(love.filesystem.write("9.sav", fixture), "cannot stage benchmark fixture")
	assert(game_load(9), "cannot load benchmark fixture")
	-- Save projection intentionally omits presentation-only dimensions.
	vi.textwall_w = tonumber(vi.textwall_w) or 700
	vi.textwall_h = tonumber(vi.textwall_h) or 140
	screen_res()
	game.pause = nil
	game.inputing = nil
	game.mapgenning = nil
	pl.dying = nil
	actors:bind_host(pl, vi)

	local spawn = multiplayer_guest_spawn()
	local guest = GhostActor.new(pl, {
		actor_id = "guest",
		session_id = string.rep("8", 64),
		x = spawn.x,
		y = spawn.y,
		tx = spawn.tx,
		ty = spawn.ty,
		xt = spawn.xt,
		yt = spawn.yt,
		truex = spawn.truex,
		truey = spawn.truey,
	})
	local distant_camera = {}
	for key, value in pairs(vi) do distant_camera[key] = value end
	local host_camera_x = tonumber(vi.xtile) or 0
	local host_camera_y = tonumber(vi.ytile) or 0
	local distant_camera_x = host_camera_x
		+ (tonumber(screen.x) or 0) + 40
	local distant_camera_y = host_camera_y
		+ (tonumber(screen.y) or 0) + 24
	distant_camera.xtile = distant_camera_x
	distant_camera.ytile = distant_camera_y
	distant_camera.xoffset = 0
	distant_camera.yoffset = 0
	actors:bind_guest(guest, { camera = distant_camera })
	local input = InputState.new()
	local session = { guest = guest, session_id = string.rep("8", 64) }

	local dense_mobs = {}
	for index = 1, 96 do
		dense_mobs[index] = {
			id = 1,
			truex = spawn.truex + (index % 16) * cf.w,
			truey = spawn.truey + math.floor(index / 16) * cf.h,
			hp = 100,
			state = "idle",
			ani_status = "walk",
			ani_frame = 1,
		}
	end
	local reconnect_backlog = {}
	for sequence = 1, 64 do
		reconnect_backlog[sequence] = Replication.encode_world({
			sequence = sequence,
			tick = sequence,
			sample_time = sequence / 30,
			cells = {{
				x = math.max(1, math.min(cf.wmax, (pl.xt or 1) + sequence % 4)),
				y = math.max(1, math.min(cf.wmax, (pl.yt or 1) + sequence % 3)),
				cell = { b = sequence % 2 == 0 and 1 or 2 },
			}},
		})
	end

	local udp_constructor = socket.udp4 or socket.udp
	local receiver = assert(udp_constructor())
	assert(receiver:setsockname("127.0.0.1", 0))
	receiver:settimeout(0)
	local _, publish_port = receiver:getsockname()
	local publisher = assert(udp_constructor())
	publisher:settimeout(0)

	local gameplay_update = assert(love.old_update, "gameplay update is unavailable")
	local gameplay_draw = assert(love.old_draw, "gameplay draw is unavailable")
	local original_has_focus = love.window.hasFocus
	love.window.hasFocus = function() return true end
	local frame = 0
	local rendered = 0
	local frame_limit = 180
	local finished = false
	local latest_packet_size = 0

	local function cleanup()
		love.window.hasFocus = original_has_focus
		publisher:close()
		receiver:close()
		game_delete_save(9)
		love.filesystem.setIdentity(original_identity)
	end

	local function complete(code, details)
		if finished then return end
		finished = true
		cleanup()
		finish(code, "mode=multiplayer-benchmark " .. details)
	end

	collectgarbage("collect")
	PerformanceMetrics.activate({
		scenario = "near-distant-build-reconnect-dense-replication",
		frames = frame_limit,
		profile = profile_name,
		renderer = renderer,
	})

	local function benchmark_update()
		if finished then return end
		local ok, benchmark_error = pcall(function()
				frame = frame + 1
				dt = 1 / 30
				if frame <= 45 then
					distant_camera.xtile = host_camera_x + 2
					distant_camera.ytile = host_camera_y + 1
				else
					distant_camera.xtile = distant_camera_x
					distant_camera.ytile = distant_camera_y
				end
				if frame > 90 and frame <= 135 then
					local build_x = math.max(1, math.min(cf.wmax, (pl.xt or 1) + 2))
					local build_y = math.max(1, math.min(cf.wmax, pl.yt or 1))
					PerformanceMetrics.measure(
						"active_building",
						writemap,
						build_x,
						build_y,
						frame % 2 == 0 and 1 or 2
					)
				elseif frame > 135 then
					PerformanceMetrics.measure("reconnect_backlog_replay", function()
						for offset = 0, 3 do
							local index = ((frame - 136) * 4 + offset) % 64 + 1
							local delta, kind = Replication.decode(reconnect_backlog[index])
							assert(delta and kind == "world" and delta.sequence == index,
								"benchmark reconnect backlog did not round-trip")
						end
					end)
				end
				PerformanceMetrics.measure(
				"guest_simulation",
				multiplayer_simulate_guest,
				guest,
				input,
				1 / 30
			)
			multiplayer_each_active_cell(
				{ vi, distant_camera },
				screen.x,
				screen.y,
				function(x, y)
					-- Match the hot loop's table lookup without mutating the world.
					local _ = world[y] and world[y][x]
				end
			)

			local previous_mobs = mobs
			mobs = dense_mobs
			local captured, state_or_error = pcall(
				PerformanceMetrics.measure,
				"replication_capture",
				multiplayer_replication_state,
				session,
				frame % 30 == 0
			)
			mobs = previous_mobs
			assert(captured, state_or_error)
			local packet = PerformanceMetrics.measure(
				"replication_encode", Replication.encode_state, state_or_error
			)
			latest_packet_size = #packet
			local decoded, packet_kind = PerformanceMetrics.measure(
				"replication_decode", Replication.decode, packet
			)
			assert(decoded and packet_kind == "state",
				"benchmark state packet did not round-trip")
			local datagram_count = math.ceil(#packet / 8000)
			local sent, send_error = PerformanceMetrics.measure(
				"network_publish",
				function()
					for offset = 1, #packet, 8000 do
						local bytes, publish_error = publisher:sendto(
							packet:sub(offset, offset + 7999),
							"127.0.0.1",
							publish_port
						)
						if not bytes then return nil, publish_error end
					end
					return #packet
				end
			)
			assert(sent == #packet, "benchmark publish failed: "
				.. tostring(send_error) .. " packet=" .. latest_packet_size
				.. " port=" .. tostring(publish_port))
			for _ = 1, datagram_count do receiver:receivefrom() end

			gameplay_update(1 / 30)
			PerformanceMetrics.step_garbage(200)
		end)
		if not ok then
			PerformanceMetrics.active = false
			complete(1, tostring(benchmark_error))
		end
	end

	local function benchmark_draw()
		if finished then return end
		local ok, draw_error = pcall(gameplay_draw)
		if not ok then
			PerformanceMetrics.active = false
			complete(1, tostring(draw_error))
			return
		end
		rendered = rendered + 1
		if frame >= frame_limit and rendered >= frame_limit then
			PerformanceMetrics.collect_garbage()
			local report = PerformanceMetrics.deactivate()
			local accepted, failures = PerformanceBudget.evaluate(
				report,
				performance_targets
			)
			local formatted = PerformanceMetrics.format(report)
			if not accepted then
				complete(1, "profile=" .. profile_name .. " renderer=" .. renderer
					.. "; " .. table.concat(failures, ", ") .. "; " .. formatted)
			else
				complete(0, "profile=" .. profile_name .. " renderer=" .. renderer
					.. "; packet=" .. latest_packet_size .. "B; " .. formatted)
			end
		end
	end

	love.update = benchmark_update
	love.draw = benchmark_draw
end

local function validate_multiplayer_gameplay()
	local original_identity = love.filesystem.getIdentity()
	local test_identity = "sarcophagus-multiplayer-gameplay-smoke"
	love.filesystem.setIdentity(test_identity)
	game_delete_save(9)
	local ok, result = pcall(function()
		local fixture, fixture_error = love.filesystem.read("tests/fixtures/9.sav")
		assert(fixture, "cannot read multiplayer fixture: " .. tostring(fixture_error))
		assert(love.filesystem.write("9.sav", fixture), "cannot stage multiplayer fixture")
		assert(game_load(9), "cannot load multiplayer fixture")
		actors:bind_host(pl, vi)
		local gameplay_session_id = string.rep("5", 64)
		local spawn = multiplayer_guest_spawn()
		local guest = GhostActor.new(pl, {
			actor_id = "guest",
			session_id = gameplay_session_id,
			x = spawn.x, y = spawn.y,
			tx = spawn.tx, ty = spawn.ty,
			xt = spawn.xt, yt = spawn.yt,
			truex = spawn.truex, truey = spawn.truey,
		})
		actors:bind_guest(guest)
			local runtime = assert(actors:runtime(guest))
			local function capture_host_actor_context()
				local captured = { game = {}, craft = {}, globals = {} }
				for _, field in ipairs(ActorContext.registered_fields("game")) do
					captured.game[field] = { value = game[field] }
				end
				for _, field in ipairs(ActorContext.registered_fields("craft")) do
					captured.craft[field] = { value = craft[field] }
				end
				for _, scope in ipairs({ "actor_global", "transient_global" }) do
					for _, field in ipairs(ActorContext.registered_fields(scope)) do
						captured.globals[field] = { value = _G[field] }
					end
				end
				return captured
			end
			local function assert_host_actor_context(captured, path)
				for field, saved in pairs(captured.game) do
					assert(game[field] == saved.value,
						path .. " leaked game." .. field)
				end
				for field, saved in pairs(captured.craft) do
					assert(craft[field] == saved.value,
						path .. " leaked craft." .. field)
				end
				for field, saved in pairs(captured.globals) do
					assert(_G[field] == saved.value,
						path .. " leaked global " .. field)
				end
			end

		multiplayer_reset_network_events(true)
		local previous_role, previous_session = multiplayer.role, multiplayer.session
		local previous_resume_phase = multiplayer.resume_phase
		local previous_active_actor = ACTIVE_ACTOR_ID
		multiplayer.role = "host"
		multiplayer.session = { state = MultiplayerSession.STATE.PLAYING }
		multiplayer.session.state = MultiplayerSession.STATE.RECONNECT_GRACE
		assert(not multiplayer_queue_sound_event(
			"smoke_disconnected_sound", 5, {}, "host"
		), "ephemeral sound was queued while the guest was disconnected")
		assert(multiplayer_queue_text_event(
			"smoke reconnect text", false, "host"
		), "durable text was dropped during reconnect grace")
		assert(multiplayer_next_network_event().kind == "text",
			"reconnect grace queued an unexpected presentation event")
		multiplayer_reset_network_events(true)
		multiplayer.session.state = MultiplayerSession.STATE.PLAYING
		multiplayer.resume_phase = "sending_sync"
		assert(not multiplayer_queue_sound_event(
			"smoke_resume_sound", 5, {}, "host"
		), "ephemeral sound was queued during stream replay")
		multiplayer.resume_phase = nil
		ACTIVE_ACTOR_ID = "guest"
		-- gravel.ogg is stereo. Network presentation must gracefully fall back
		-- to non-spatial playback because OpenAL only positions mono sources.
		sound_add("smoke_network_sound", 5)
		ACTIVE_ACTOR_ID = previous_active_actor
		local sound_event = multiplayer_next_network_event()
		multiplayer.role, multiplayer.session = previous_role, previous_session
		multiplayer.resume_phase = previous_resume_phase
		assert(sound_event and sound_event.kind == "sound"
			and sound_event.actor_id == "guest"
			and sound_event.x == guest.xt and sound_event.y == guest.yt,
			"guest sound was not captured as a spatial network event")
		actors:set_local(guest)
		assert(multiplayer_apply_network_event(sound_event),
			"valid spatial sound event was rejected")
		assert(allsounds["net:guest:smoke_network_sound"],
			"spatial sound event was not presented on the client")
		sound_kill("guest:smoke_network_sound")
		sound_kill("net:guest:smoke_network_sound")
		local unavailable_event = StateCopy.copy(sound_event)
		unavailable_event.event_id = sound_event.event_id + 1
		unavailable_event.name = "smoke_unavailable_sound"
		local original_sound_add = sound_add
		sound_add = function() error("simulated audio device failure") end
		local audio_ok, audio_status = multiplayer_apply_network_event(
			unavailable_event
		)
		sound_add = original_sound_add
		assert(audio_ok and audio_status == "audio_unavailable",
			"audio presentation failure broke authoritative synchronization")
		actors:set_local(pl)
		multiplayer_reset_network_events(true)
		previous_role, previous_session = multiplayer.role, multiplayer.session
		multiplayer.role = "host"
		multiplayer.session = { state = MultiplayerSession.STATE.PLAYING }
		multiplayer_run_as_actor("host", function()
			sound_add("smoke_host_network_sound", 5, { x = 0.5, y = 1 })
		end)
		local host_sound_event = multiplayer_next_network_event()
		multiplayer.role, multiplayer.session = previous_role, previous_session
		assert(host_sound_event and host_sound_event.kind == "sound"
			and host_sound_event.actor_id == "host"
			and host_sound_event.x == pl.xt and host_sound_event.y == pl.yt,
			"host-relative sound was serialized as a world-origin sound")
		sound_kill("smoke_host_network_sound")
		multiplayer_reset_network_events(true)

		local attacker_mob_id, attacker_mob
		for candidate_id, candidate in pairs(mobs) do
			if type(candidate) == "table" and type(candidate.hp) == "number"
				and type(candidate.save) == "table" then
				attacker_mob_id, attacker_mob = candidate_id, candidate
				break
			end
		end
		assert(attacker_mob_id and type(attacker_mob) == "table",
			"multiplayer fixture has no mob for attacker attribution")
		local attacker_before = attacker_mob.last_attacker_id
		local hostile_before = attacker_mob.hostile
		local save_hostile_before = attacker_mob.save and attacker_mob.save.hostile
		local sleep_before = attacker_mob.sleep
		local hp_before = attacker_mob.hp
		local sct_before = #sct
		attacker_mob.last_attacker_id = "guest"
		multiplayer_run_as_actor("host", function()
			mob_hit(attacker_mob_id, 0, true)
		end)
		assert(attacker_mob.last_attacker_id == "host",
			"host hit retained stale guest kill attribution")
		attacker_mob.last_attacker_id = attacker_before
		attacker_mob.hostile = hostile_before
		if attacker_mob.save then attacker_mob.save.hostile = save_hostile_before end
		attacker_mob.sleep = sleep_before
		attacker_mob.hp = hp_before
		while #sct > sct_before do table.remove(sct) end

		do
			local live_registry = actors
			local network_time_base = game.network_time_base
			local network_guest_time_delta = game.network_guest_time_delta
			local function simulate_at(render_hz, viewport_width, viewport_height)
				local registry = ActorRegistry.new()
				registry:bind_host(StateCopy.copy(pl), StateCopy.copy(vi))
				local simulated_guest = StateCopy.copy(guest)
				local simulated_camera = StateCopy.copy(vi)
				if viewport_width and viewport_height then
					local ew = viewport_width - 8 * 18
					local eh = viewport_height - 14 * 15
					simulated_camera.vixmax = ew / 2 + ew / 10 - 8 * 18
					simulated_camera.vixmin = ew / 2 - ew / 10 + 8 * 18
					simulated_camera.viymax = eh / 2
					simulated_camera.viymin = eh / 2
					if game.gr2x then
						simulated_camera.vixmax = simulated_camera.vixmax / 2
						simulated_camera.vixmin = simulated_camera.vixmin / 2
						simulated_camera.viymax = simulated_camera.viymax / 2
						simulated_camera.viymin = simulated_camera.viymin / 2
					end
				end
				local simulated_runtime = select(2, registry:bind_guest(
					simulated_guest,
					{ camera = simulated_camera }
				))
				InputState.set_button(simulated_runtime.input, "d", true)
				simulated_runtime.input.aim = {
					world_x = simulated_guest.truex + 64,
					world_y = simulated_guest.truey,
				}
				actors = registry
				local ran, run_error = pcall(function()
					local steps = 0
					for _ = 1, math.floor(render_hz * 0.2 + 0.5) do
						local simulated, executed = multiplayer_simulate_guest(
							simulated_guest,
							simulated_runtime.input,
							1 / render_hz
						)
						assert(simulated, "guest cross-FPS simulation failed")
						steps = steps + executed
					end
					return {
						truex = simulated_guest.truex,
						truey = simulated_guest.truey,
						xspeed = simulated_guest.xspeed,
						yspeed = simulated_guest.yspeed,
						state = simulated_guest.state,
						steps = steps,
					}
				end)
				actors = live_registry
				assert(ran, run_error)
				return run_error
			end

			local reference = simulate_at(60)
			assert(reference.steps == 6,
				"guest cross-FPS reference used the wrong tick count")
			for _, render_hz in ipairs({ 30, 120 }) do
				local simulated = simulate_at(render_hz)
				assert(simulated.steps == reference.steps
					and math.abs(simulated.truex - reference.truex) < 1e-7
					and math.abs(simulated.truey - reference.truey) < 1e-7
					and math.abs(simulated.xspeed - reference.xspeed) < 1e-7
					and math.abs(simulated.yspeed - reference.yspeed) < 1e-7
					and simulated.state == reference.state,
					("guest simulation diverged at %d FPS"):format(render_hz))
			end
			for _, viewport in ipairs({ { 1280, 720 }, { 720, 1280 } }) do
				local simulated = simulate_at(60, viewport[1], viewport[2])
				assert(simulated.steps == reference.steps
					and math.abs(simulated.truex - reference.truex) < 1e-7
					and math.abs(simulated.truey - reference.truey) < 1e-7
					and simulated.state == reference.state,
					("guest simulation depends on %dx%d viewport"):format(
						viewport[1], viewport[2]
					))
			end
			game.network_time_base = network_time_base
			game.network_guest_time_delta = network_guest_time_delta
		end

		InputState.set_button(runtime.input, "d", true)
		runtime.input.aim = {
			world_x = guest.truex + 64,
			world_y = guest.truey,
			tile_x = guest.xt + 2,
			tile_y = guest.yt,
		}
		local host_truex, host_truey = pl.truex, pl.truey
		local guest_start_x, guest_start_y = guest.truex, guest.truey
		local simulation_context = capture_host_actor_context()
		local simulation_steps = 0
		for _ = 1, 45 do
			local simulated, steps = multiplayer_simulate_guest(
				guest,
				runtime.input,
				1 / 30
			)
			assert(simulated, "guest fixed-step simulation failed")
			simulation_steps = simulation_steps + steps
		end
		assert(simulation_steps == 45,
			"30 FPS host did not execute the 30 Hz guest simulation")
		assert_host_actor_context(simulation_context, "guest simulation")
		assert(pl.truex == host_truex and pl.truey == host_truey,
			"guest simulation moved the host actor")
		assert(guest.truex ~= guest_start_x or guest.truey ~= guest_start_y,
			"guest actor did not move under remote input")
		assert(guest.animation and guest.animation.frame,
			"guest animation was not simulated")
		local food_before = guest.stats.food.hp
		guest.network_recovery_time = game.time - 64
		InputState.set_button(runtime.input, "d", false)
		multiplayer_simulate_guest(guest, runtime.input, 1 / 30)
		assert(guest.stats.food.hp < food_before,
			"guest hunger did not follow shared world time")

		local host_body_before = pl.stats.body.hp
		local guest_body_before = guest.stats.body.hp
		guest.stats.body.hp = 11
		guest.stats.body.pc = 11
		local damage_sound_add = sound_add
		local heartbeat_calls = 0
		local damage_text_count = #sct
		sound_add = function(name)
			if name == "heartbeat" then heartbeat_calls = heartbeat_calls + 1 end
		end
		ActorContext.run(actors, guest, {
			input = runtime.input,
			dt = 0,
			camera = vi,
		}, function()
			assert(not actor_uses_local_presentation(pl),
				"remote guest unexpectedly owned the host presentation")
			player_hit(2)
		end)
		assert(pl.stats.body.hp == host_body_before
			and guest.stats.body.hp == 9,
			"guest damage changed the host body stat")
		assert(heartbeat_calls == 0,
			"guest critical health enabled the host heartbeat")
		local damage_text = sct[#sct]
		assert(#sct == damage_text_count + 1 and damage_text.truex
			and math.abs(damage_text.truex - guest.truex) <= 8
			and damage_text.truey == guest.truey - 32,
			"guest damage text was projected through the host camera")
		table.remove(sct)
		actors:set_local(guest)
		assert(actor_health_presentation_update(guest)
			and heartbeat_calls == 1,
			"guest critical health was not presented on its own client")
		guest.stats.body.hp = guest_body_before
		guest.stats.body.pc = math.floor(
			guest_body_before / guest.stats.body.maxhp * 100
		)
		actor_health_presentation_update(guest)
		actors:set_local(pl)
		actor_health_presentation_update(pl)
		sound_add = damage_sound_add

		local host_fishing = { owner = "host" }
		fishing = host_fishing
		runtime.local_globals = runtime.local_globals or {}
		runtime.local_globals.fishing = { owner = "guest" }
		ActorContext.run(actors, guest, {
			input = runtime.input,
			dt = 0,
			camera = vi,
		}, function()
			assert(fishing.owner == "guest", "guest fishing state was not activated")
			fishing.changed = true
		end)
		assert(fishing == host_fishing and runtime.local_globals.fishing.changed,
			"guest fishing state leaked into the host runtime")
		runtime.local_globals.fishing = nil
		fishing = nil

		local pickup = item_make(31)
		assert(inv_ground_add(guest.xt, guest.yt, pickup, { groundlast = true }))
		local stale_ok = multiplayer_guest_action(guest, {
			action = "pickup",
			item_uid = "item:stale",
		})
		assert(stale_ok == false, "server accepted a stale ground item uid")
			local action_context = capture_host_actor_context()
			assert(multiplayer_guest_action(guest, {
				action = "pickup",
				item_uid = pickup.uid,
			}), "server rejected the authoritative ground item uid")
			assert_host_actor_context(action_context, "guest action")
		local picked, picked_slot
		for slot, instance in pairs(guest.inv) do
			if instance.uid == pickup.uid then picked, picked_slot = true, slot end
		end
		assert(picked, "validated guest pickup did not reach guest inventory")
		guest.invselect = picked_slot == 1 and 2 or 1
		assert(multiplayer_guest_action(guest, {
			action = "select",
			slot = picked_slot,
			item_uid = "item:stale",
		}) == false, "server accepted a stale inventory selection uid")
		assert(multiplayer_guest_action(guest, {
			action = "select",
			slot = picked_slot,
			item_uid = pickup.uid,
		}), "server rejected an authoritative inventory selection")
		assert(guest.invselect == picked_slot,
			"validated inventory selection did not reach the guest actor")

		-- Eating is authoritative for the guest actor, but all of its HUD text
		-- must be delivered to the guest client instead of redrawing the host's
		-- shared text canvas.
		local food_slot
		for slot = 1, guest.invsize do
			if guest.inv[slot] == nil then food_slot = slot; break end
		end
		assert(food_slot, "guest inventory has no slot for the eating regression")
		local guest_food = assert(item_make(201))
		guest.inv[food_slot] = guest_food
		guest.invselect = food_slot
		local guest_food_max = guest.stats.food.maxhp
		guest.stats.food.hp = math.max(0, guest_food_max - 40)
		guest.stats.food.pc = math.floor(
			guest.stats.food.hp / guest_food_max * 100
		)
		local guest_food_before = guest.stats.food.hp
		local host_food_before = pl.stats.food.hp
		local host_food_pc_before = pl.stats.food.pc
		local host_dishes_before = pl.dishes and pl.dishes[guest_food.i]
		local host_inventory_before = {}
		for slot, instance in pairs(pl.inv) do
			host_inventory_before[slot] = instance
		end
		local host_log_before = #pl.log
		local guest_log_before = #guest.log

		multiplayer_reset_network_events(true)
		previous_role, previous_session = multiplayer.role, multiplayer.session
		multiplayer.role = "host"
		multiplayer.session = { state = MultiplayerSession.STATE.PLAYING }
		local smoke_keypressed = love.old_keypressed
		love.old_keypressed = gameplay_keypressed
		local ate, eat_error = multiplayer_guest_action(guest, {
			action = "key",
			key = "u",
			scancode = "u",
			selected_item_uid = guest_food.uid,
		})
		love.old_keypressed = smoke_keypressed
		multiplayer.role, multiplayer.session = previous_role, previous_session
		assert(ate, "guest could not eat authoritative food: " .. tostring(eat_error))
		assert(guest.stats.food.hp > guest_food_before,
			("guest eating did not recover guest hunger (%s -> %s)")
				:format(tostring(guest_food_before), tostring(guest.stats.food.hp)))
		for _, instance in pairs(guest.inv) do
			assert(instance.uid ~= guest_food.uid,
				"guest food was not removed after eating")
		end
		assert(pl.stats.food.hp == host_food_before
			and pl.stats.food.pc == host_food_pc_before
			and (pl.dishes and pl.dishes[guest_food.i]) == host_dishes_before,
			"guest eating changed host hunger or food history")
		for slot, instance in pairs(host_inventory_before) do
			assert(pl.inv[slot] == instance,
				"guest eating changed a host inventory slot")
		end
		for slot, instance in pairs(pl.inv) do
			assert(host_inventory_before[slot] == instance,
				"guest eating added an item to the host inventory")
		end
		assert(#pl.log == host_log_before and #guest.log == guest_log_before,
			"guest eating wrote its message into a host-side HUD log")

		local eating_events = {}
		local eating_sound, eating_text = false, false
		while true do
			local event = multiplayer_next_network_event()
			if not event then break end
			eating_events[#eating_events + 1] = event
			if event.kind == "sound" and event.name == "eating"
				and event.actor_id == "guest"
				and event.x == guest.xt and event.y == guest.yt then
				eating_sound = true
			elseif event.kind == "text" and event.actor_id == "guest" then
				eating_text = true
			end
		end
		assert(eating_sound,
			"guest eating was not presented as a positional guest sound")
		assert(eating_text, "guest eating message was not routed to the guest")

		actors:set_local(guest)
		local host_actor = pl
		pl = guest -- model the client after multiplayer_apply_snapshot()
		for _, event in ipairs(eating_events) do
			assert(multiplayer_apply_network_event(event),
				"guest eating presentation event was rejected")
		end
		pl = host_actor
		actors:set_local(host_actor)
		assert(#guest.log > guest_log_before and #pl.log == host_log_before,
			"guest eating text did not appear exclusively in the guest log")
		sound_kill("guest:eating")
		sound_kill("net:guest:eating")
		multiplayer_reset_network_events(true)

		local client_pickup = item_make(31)
		assert(inv_ground_add(guest.xt, guest.yt, client_pickup))
		local original_network_client = game.network_client
		local original_send_key_action = multiplayer_send_key_action
		game.network_client = true
		multiplayer_send_key_action = function() return true end
		love.old_keypressed("q", "q")
		multiplayer_send_key_action = original_send_key_action
		game.network_client = original_network_client
		local ground_cell = world[guest.yt][guest.xt]
		local client_item_still_grounded = false
		local client_item_in_inventory = false
		for _, instance in ipairs(ground_cell.i or {}) do
			client_item_still_grounded = client_item_still_grounded
				or instance.uid == client_pickup.uid
		end
		for _, instance in pairs(guest.inv) do
			client_item_in_inventory = client_item_in_inventory
				or instance.uid == client_pickup.uid
		end
		assert(client_item_still_grounded and not client_item_in_inventory,
			"network client applied an authoritative pickup locally")

		local invalid_replication = multiplayer_replication_state({ guest = guest })
		invalid_replication.guest_actor.truex = math.huge
		local previous_server_tick = game.network_server_tick
		local previous_game_time = game.time
		local replication_ok, replication_error = multiplayer_apply_replication(
			invalid_replication
		)
		assert(not replication_ok
			and replication_error == "invalid replicated state shape"
			and game.network_server_tick == previous_server_tick
			and game.time == previous_game_time,
			"malformed replication mutated authoritative client state")
		local invalid_entity_replication = multiplayer_replication_state({ guest = guest })
		invalid_entity_replication.mobs[1] = 1
		local entities_before = mobs
		local entity_ok, entity_error = multiplayer_apply_replication(
			invalid_entity_replication
		)
		assert(not entity_ok and entity_error == "invalid replicated state shape"
			and mobs == entities_before,
			"scalar replicated entity reached the client runtime")
		local invalid_shared_game = multiplayer_replication_state({ guest = guest })
		invalid_shared_game.shared_game.network_client = true
		local network_client_before = game.network_client
		local shared_ok, shared_error = multiplayer_apply_replication(invalid_shared_game)
		assert(not shared_ok and shared_error == "invalid replicated state shape"
			and game.network_client == network_client_before,
			"replication accepted an arbitrary shared game field")

		local previous_sequence = tonumber(game.network_world_sequence) or 0
		local original_first_cell = world[1][1]
		local applied, apply_error = multiplayer_apply_world_delta({
			sequence = previous_sequence + 1,
			tick = tonumber(game.network_tick) or 0,
			cells = {
				{ x = 1, y = 1, cell = { b = 999 } },
				{ x = cf.wmax + 1, y = 1, cell = { b = 999 } },
			},
		})
		assert(not applied and apply_error == "invalid world cell delta"
			and world[1][1] == original_first_cell
			and (tonumber(game.network_world_sequence) or 0) == previous_sequence,
			"malformed world delta was applied partially")
		assert(multiplayer_mob_target({
			truex = guest.truex,
			truey = guest.truey,
		}) == guest, "mob AI did not select the nearest guest actor")
		local projectile_collider = {
			x = guest.truex - 2,
			y = guest.truey - 2,
			w = guest.truex + 2,
			h = guest.truey + 2,
		}
		local _, projectile_target = multiplayer_projectile_player_collision(
			projectile_collider,
			{ owner_id = "mob:test" }
		)
		assert(projectile_target == guest,
			"hostile projectile did not collide with the guest")
		assert(multiplayer_projectile_player_collision(
			projectile_collider,
			{ owner_id = guest.actor_id }
		) == nil, "friendly projectile could hit a player")

		local dense_cells = {}
		for y = math.max(1, guest.yt - 8), math.min(cf.wmax, guest.yt + 8) do
			for x = math.max(1, guest.xt - 8), math.min(cf.wmax, guest.xt + 8) do
				dense_cells[#dense_cells + 1] = {
					x = x,
					y = y,
					cell = StateCopy.copy(world[y][x]),
				}
				world[y][x] = { b = 1 }
			end
		end
		local function restore_dense_cells()
			for _, entry in ipairs(dense_cells) do
				world[entry.y][entry.x] = entry.cell
			end
		end
		local original_guest_carry = guest.iscarry
		guest.iscarry = createblock(12)
		local dense_save = game_save_snapshot()
		local saved_recovery = dense_save[4].network_guest_recovery
		local saved_record = saved_recovery and saved_recovery[#saved_recovery]
		assert(saved_record and saved_record.iscarry
			and saved_record.iscarry.b == 12
			and guest.iscarry and guest.iscarry.b == 12,
			"dense-world autosave lost or mutated guest possessions")
		guest.iscarry = original_guest_carry

		local original_live_recovery = game.network_guest_recovery
		game.network_guest_recovery = nil
		local recovery_actor = {
			actor_id = "guest",
			session_id = string.rep("9", 64),
			xt = guest.xt,
			yt = guest.yt,
			inv = { [1] = item_make(31) },
			invselect = 1,
			iscarry = createblock(12),
		}
		local cleanup_ok, cleanup_report = multiplayer_drop_guest(
			recovery_actor,
			recovery_actor.session_id
		)
		assert(cleanup_ok and cleanup_report and cleanup_report.stored
			and game.network_guest_recovery
			and #game.network_guest_recovery == 1
			and next(recovery_actor.inv) == nil
			and recovery_actor.iscarry == nil,
			"dense-world disconnect did not enter durable recovery")
		for attempt = 1, 8 do
			local retry_ok, retry_error = multiplayer_recover_guest_possessions(true)
			assert(not retry_ok and retry_error == "no room for carried block",
				"dense-world recovery retry lost its failure state")
		end
		local parked, parked_status = multiplayer_recover_guest_possessions(false)
		assert(parked and parked_status == "parked",
			"unchanged dense world caused unbounded recovery retries")
		restore_dense_cells()
		local recovered, recovery_error = multiplayer_recover_guest_possessions(true)
		assert(recovered and recovery_error == "recovered"
			and game.network_guest_recovery == nil,
			"durable guest possessions were not retried after space returned")
		restore_dense_cells()
		game.network_guest_recovery = original_live_recovery
		if network_world_journal then network_world_journal:clear() end

		local snapshot = NetworkSnapshot.capture(multiplayer_snapshot_state({
			guest = guest,
			session_id = gameplay_session_id,
		}))
		local stored = NetworkSnapshot.serialize(snapshot)
		assert(type(stored) == "string" and #stored > 0,
			"real-world multiplayer snapshot was not serializable")
		local replication_started = love.timer.getTime()
		local replication_state = multiplayer_replication_state({ guest = guest })
		local state_packet = NetworkReplication.encode_state(replication_state)
		local pose_state = multiplayer_pose_state({ guest = guest })
		local pose_packet = NetworkReplication.encode_pose(pose_state)
		local replication_ms = (love.timer.getTime() - replication_started) * 1000
		local progress_state = multiplayer_replication_state({ guest = guest }, true)
		local progress_packet = NetworkReplication.encode_state(progress_state)
		local actor_packet = NetworkReplication.encode_state({
			host_actor = replication_state.host_actor,
			guest_actor = replication_state.guest_actor,
		})
		local entity_packet = NetworkReplication.encode_state({
			mobs = replication_state.mobs,
			projectiles = replication_state.projectiles,
			world_animation = replication_state.world_animation,
		})
		local presentation_packet = NetworkReplication.encode_state({
			guest_fishing = replication_state.guest_fishing,
			tips = replication_state.tips,
			disp = replication_state.disp,
			shared_game = replication_state.shared_game,
		})
		assert(#state_packet < NetworkReplication.MAX_STORED_BYTES,
			"real-world replication state exceeded its packet budget")
		assert(#state_packet < 16 * 1024,
			"frequent actor state regressed to a full progress payload")
		assert(#pose_packet < 2 * 1024,
			"30 Hz authoritative pose is too large")
		assert(#progress_packet < NetworkReplication.MAX_STORED_BYTES,
			"progress replication state exceeded its packet budget")
		local decoded_state, decoded_kind = NetworkReplication.decode(state_packet)
		assert(decoded_state and decoded_kind == "state"
			and decoded_state.actor_schema == 2,
			"fast LZ4 replication state did not round-trip")
		local decoded_pose, decoded_pose_kind = NetworkReplication.decode(pose_packet)
		assert(decoded_pose and decoded_pose_kind == "pose"
			and decoded_pose.pose_schema == 1,
			"compact authoritative pose did not round-trip")

		local marker = "multiplayer_smoke_progress"
		progress_state.shared_progress.visited[marker] = 7
		progress_state.host_progress.quest = 3
		progress_state.guest_progress.quest = 4
		assert(multiplayer_apply_replication(progress_state),
			"progress replication state was rejected")
		assert(actors.host.visited == actors.guest.visited
			and actors.host.visited[marker] == 7
			and actors.host.quest == 3 and actors.guest.quest == 4,
			"shared or personal actor progress was not applied correctly")

		local saved_x, saved_y, saved_state = guest.truex, guest.truey, guest.state
		local saved_xspeed, saved_yspeed = guest.xspeed, guest.yspeed
		actors:set_local(guest)
		guest.state = "idle"
		guest.yspeed = 0
		guest.network_target_truex = guest.truex + 5
		guest.network_target_truey = guest.truey + 3.5
		assert(multiplayer_reconcile_local_actor(1 / 60)
			and guest.truex == saved_x
			and guest.truey == saved_y + 3.5
			and guest.network_target_truex == nil
			and guest.network_target_truey == nil,
			"local reconciliation dragged or vertically floated the ghost")
		guest.truex, guest.truey = saved_x, saved_y
		guest.state, guest.yspeed = "jump", -5
		guest.network_target_truex = saved_x
		guest.network_target_truey = saved_y + 12
		guest.network_target_motion = { state = "idle", xspeed = 0, yspeed = 0 }
		assert(multiplayer_reconcile_local_actor(1 / 60)
			and guest.truey > saved_y and guest.truey < saved_y + 12
			and guest.state == "jump" and guest.yspeed == -5,
			"a delayed grounded packet cancelled the predicted jump")
		guest.truex, guest.truey = saved_x - 18, saved_y + cf.h
		guest.state, guest.yspeed = "idle", 0
		guest.network_target_truex = saved_x
		guest.network_target_truey = saved_y
		guest.network_target_motion = {
			state = "idle", oldstate = "idle", xspeed = 0, yspeed = 0,
			animation = { frame = 1, time = 0, cycle = 0 },
		}
		assert(multiplayer_reconcile_local_actor(1 / 60)
			and guest.truex == saved_x and guest.truey == saved_y
			and guest.state == "idle" and guest.yspeed == 0,
			"a grounded client remained beside the host's raised block")
		guest.truex, guest.truey = saved_x, saved_y
		guest.network_target_truex = saved_x
		guest.network_target_truey = saved_y + 120
		guest.network_target_motion = { state = "idle", xspeed = 0, yspeed = 0 }
		assert(multiplayer_reconcile_local_actor(1 / 60)
			and guest.truey == saved_y + 120
			and guest.state == "idle" and guest.yspeed == 0,
			"a serious prediction error did not restore host movement state")
		guest.truex, guest.truey, guest.state = saved_x, saved_y, saved_state
		guest.xspeed, guest.yspeed = saved_xspeed, saved_yspeed
		coord_true2screen(guest)
		actors:set_local(pl)
		local draw_x, draw_y = ActorRenderer.position(guest, {
			camera = vi,
			local_actor = pl,
			tile_width = cf.w,
			tile_height = cf.h,
		})
		assert(type(draw_x) == "number" and type(draw_y) == "number",
			"remote guest could not be projected into the host camera")
	assert(ghost_shader, "translucent white ghost shader did not compile")
		assert(multiplayer_merge_time(100, 125, 40) == 140
			and multiplayer_merge_time(100, 160, 40) == 160,
			"shared time summed actor deltas instead of taking the maximum")
		local decoded_snapshot = assert(NetworkSnapshot.deserialize(stored))
		assert(multiplayer_apply_snapshot(decoded_snapshot)
			and game.network_client == true
			and pl.actor_id == "guest"
			and actors.local_actor == pl,
			"real multiplayer snapshot was not applied as a guest world")
		assert(game.textinput == "" and game.textinputold == ""
			and game.textinputinfo == "" and game.inputing == nil
			and game.craft == false and game.escmenu == nil,
			"network snapshot discarded local client UI defaults")
		do
			local client_runtime = assert(actors:runtime(pl))
			local saved_actor = NetworkReplication.capture_actor(pl)
			local saved_x, saved_y = pl.x, pl.y
			local base_time = tonumber(game.network_server_time) or 0
			local jump_pose = NetworkReplication.capture_actor(
				pl,
				NetworkReplication.ACTOR_POSE_FIELDS
			)
			jump_pose.state, jump_pose.oldstate = "jump", "jump"
			jump_pose.truex, jump_pose.truey = pl.truex + 18, pl.truey - 24
			jump_pose.xspeed, jump_pose.yspeed = 3, -5
			jump_pose.animation = { frame = 2, time = 1, cycle = 1 }
			assert(multiplayer_apply_pose({
				pose_schema = 1,
				tick = 1,
				sample_time = base_time + 0.05,
				input_sequence = 1,
				guest_actor = jump_pose,
			}) and client_runtime.network_pose_authoritative
				and pl.state == "jump",
				"client did not enter host-authoritative jump rendering")
			assert(multiplayer_apply_local_authoritative_pose()
				and math.abs(pl.truex - jump_pose.truex) < 1e-7
				and math.abs(pl.truey - jump_pose.truey) < 1e-7,
				"authoritative jump pose was re-simulated locally")

			local delayed_state = StateCopy.copy(replication_state)
			delayed_state.tick = (tonumber(game.network_server_tick) or 0) + 1
			delayed_state.sample_time = base_time + 0.025
			delayed_state.time = game.time
			assert(multiplayer_apply_replication(delayed_state)
				and client_runtime.network_pose_authoritative
				and pl.state == "jump",
				"an older full state overrode a newer authoritative pose")

			local landed_pose = StateCopy.copy(jump_pose)
			landed_pose.state, landed_pose.oldstate = "idle", "idle"
			landed_pose.truex, landed_pose.truey =
				saved_actor.truex, saved_actor.truey
			landed_pose.xspeed, landed_pose.yspeed = 0, 0
			landed_pose.animation = { frame = 1, time = 0, cycle = 0 }
			assert(multiplayer_apply_pose({
				pose_schema = 1,
				tick = 2,
				sample_time = base_time + 0.1,
				input_sequence = 2,
				guest_actor = landed_pose,
			}) and not client_runtime.network_pose_authoritative,
				"client did not leave host-authoritative jump rendering")
			assert(multiplayer_reconcile_local_actor(1 / 30)
				and pl.truex == landed_pose.truex
				and pl.truey == landed_pose.truey,
				"landing pose left the ghost below the ledge")

			local newer_state = StateCopy.copy(delayed_state)
			newer_state.tick = (tonumber(game.network_server_tick) or 0) + 1
			newer_state.sample_time = base_time + 0.15
			newer_state.time = game.time
			for _, field in ipairs(NetworkReplication.ACTOR_POSE_FIELDS) do
				newer_state.guest_actor[field] = StateCopy.copy(landed_pose[field])
			end
			assert(multiplayer_apply_replication(newer_state)
				and not client_runtime.network_pose_authoritative
				and pl.state == "idle",
				"newer full state did not establish the landed pose")
			local stale_ok, stale_status = multiplayer_apply_pose({
				pose_schema = 1,
				tick = 3,
				sample_time = base_time + 0.125,
				input_sequence = 3,
				guest_actor = jump_pose,
			})
			assert(stale_ok and stale_status == "stale"
				and not client_runtime.network_pose_authoritative
				and pl.state == "idle",
				"an older pose packet failed or overrode a newer full state")

			local real_moving = moving
			local prediction_ok, prediction_error = pcall(function()
				local saw_predicted_jump_input = false
				moving = function()
					saw_predicted_jump_input = InputState.is_down(
						ACTIVE_INPUT_STATE,
						"w"
					)
					pl.state = "fall"
					pl.y = pl.y + cf.h
					pl.yspeed = 7
				end
				local input = InputState.new()
				InputState.set_button(input, "w", true)
				local before_truex, before_truey = pl.truex, pl.truey
				assert(multiplayer_predict_local_actor(1 / 30, input, true))
				assert(not saw_predicted_jump_input,
					"client still starts a second jump before host confirmation")
				assert(pl.state == "idle" and pl.yspeed == 0
					and pl.truex == before_truex and pl.truey == before_truey,
					"client prediction crossed an unconfirmed ledge")
			end)
			moving = real_moving
			assert(prediction_ok, prediction_error)

			NetworkReplication.apply_actor(pl, saved_actor)
			pl.x, pl.y = saved_x, saved_y
			client_runtime.network_pose_authoritative = false
			client_runtime.network_pose_latest = nil
			client_runtime.network_prediction_accumulator = 0
			network_local_pose_buffer = NetworkInterpolationBuffer.new({
				delay = 0.05,
				maximum_delay = 0.12,
				maximum_clock_advance = 0.05,
			})
			game.network_pose_tick = -1
			coord_true2screen(pl)
		end
		do
			local client_runtime = assert(actors:runtime(pl))
			local fields = {
				"state", "oldstate", "animation", "flip",
				"x", "y", "truex", "truey", "tx", "ty", "xt", "yt",
			}
			local saved = {}
			for _, field in ipairs(fields) do
				saved[field] = {
					present = pl[field] ~= nil,
					value = StateCopy.copy(pl[field]),
				}
			end
			local saved_accumulator = client_runtime.network_prediction_accumulator
			local function restore_actor()
				for _, field in ipairs(fields) do
					pl[field] = saved[field].present
						and StateCopy.copy(saved[field].value) or nil
				end
				client_runtime.network_prediction_accumulator = 0
			end
			local function predict_stepup(render_hz)
				restore_actor()
				pl.state, pl.oldstate, pl.flip = "stepup", "stepup", 1
				pl.animation = { frame = 1, time = 0, cycle = 0 }
				for _ = 1, math.floor(render_hz * 0.2 + 0.5) do
					assert(multiplayer_predict_local_actor(
						1 / render_hz,
						client_runtime.input,
						false
					))
				end
				return {
					truex = pl.truex, truey = pl.truey,
					state = pl.state,
					frame = pl.animation.frame,
					time = pl.animation.time,
				}
			end
			local reference = predict_stepup(60)
			for _, render_hz in ipairs({ 30, 120 }) do
				local predicted = predict_stepup(render_hz)
				assert(math.abs(predicted.truex - reference.truex) < 1e-7
					and math.abs(predicted.truey - reference.truey) < 1e-7
					and predicted.state == reference.state
					and predicted.frame == reference.frame
					and math.abs(predicted.time - reference.time) < 1e-7,
					("client step-up prediction diverged at %d FPS"):format(render_hz))
			end
			restore_actor()
			client_runtime.network_prediction_accumulator = saved_accumulator
		end
		local aligned_cell_before = world[1][1]
		local aligned_sample_time = (tonumber(game.network_server_time) or 0) + 0.2
		local aligned_ok, aligned_status = multiplayer_apply_world_delta({
			sequence = 1,
			tick = tonumber(game.network_tick) or 0,
			sample_time = aligned_sample_time,
			cells = { { x = 1, y = 1, cell = { b = 77 } } },
		})
		assert(aligned_ok and aligned_status == "buffered"
			and world[1][1] == aligned_cell_before,
			"reliable world change appeared ahead of the render timeline")
		assert(multiplayer_flush_world_deltas(aligned_sample_time - 0.01)
			and world[1][1] == aligned_cell_before,
			"world change ignored its interpolation timestamp")
		assert(multiplayer_flush_world_deltas(aligned_sample_time)
			and world[1][1].b == 77,
			"world change was not applied on its render timestamp")
		local aligned_log_before = #pl.log
		local aligned_event_time = aligned_sample_time + 0.1
		local event_ok, event_status = multiplayer_apply_network_event({
			kind = "text",
			event_id = 1,
			tick = tonumber(game.network_tick) or 0,
			sample_time = aligned_event_time,
			actor_id = "guest",
			text = "timeline smoke",
			temporary = false,
		})
		assert(event_ok and event_status == "buffered" and #pl.log == aligned_log_before,
			"presentation event appeared ahead of the render timeline")
		assert(multiplayer_flush_network_events(aligned_event_time)
			and #pl.log == aligned_log_before + 1,
			"presentation event was not shown on its render timestamp")
		local replay_log_before = #pl.log
		local replay_time = aligned_event_time + 0.1
		local replay_text_ok, replay_text_status = multiplayer_apply_network_event({
			kind = "text",
			event_id = 2,
			tick = tonumber(game.network_tick) or 0,
			sample_time = replay_time,
			actor_id = "guest",
			text = "before expired sound",
			temporary = false,
		})
		local replay_sound_ok, replay_sound_status = multiplayer_apply_network_event({
			kind = "sound",
			event_id = 3,
			tick = tonumber(game.network_tick) or 0,
			sample_time = replay_time + 0.01,
			name = "expired_reconnect_sound",
			sound_id = 5,
			actor_id = "host",
			x = pl.xt,
			y = pl.yt,
			play = false,
			kill = false,
			replayed = true,
		})
		assert(replay_text_ok and replay_text_status == "buffered"
			and replay_sound_ok and replay_sound_status == "buffered",
			"reconnect presentation events did not retain timeline ordering")
		assert(multiplayer_flush_network_events(replay_time + 0.01)
			and #pl.log == replay_log_before + 1
			and not allsounds["net:host:expired_reconnect_sound"],
			"expired reconnect sound skipped text or produced stale audio")
		local lagged_sound_time = replay_time + 0.02
		local lagged_ok, lagged_status = multiplayer_apply_network_event({
			kind = "sound",
			event_id = 4,
			tick = tonumber(game.network_tick) or 0,
			sample_time = lagged_sound_time,
			name = "lagged_reconnect_sound",
			sound_id = 5,
			actor_id = "host",
			x = pl.xt,
			y = pl.yt,
			play = false,
			kill = false,
		})
		assert(lagged_ok and lagged_status == "buffered"
			and multiplayer_flush_network_events(lagged_sound_time + 2)
			and not allsounds["net:host:lagged_reconnect_sound"],
			"lagged buffered audio burst after interpolation recovery")

		local timeline_base = tonumber(game.network_server_time) or 0
		local server_time_before_future = game.network_server_time
		local future_state = multiplayer_replication_state({ guest = actors.guest })
		future_state.tick = (tonumber(game.network_server_tick) or 0) + 1
		future_state.sample_time = timeline_base + 60
		local future_state_ok, future_state_error = multiplayer_apply_replication(
			future_state
		)
		assert(not future_state_ok
			and future_state_error == "replicated sample time is too far ahead"
			and game.network_server_time == server_time_before_future,
			"future replication state poisoned the client timeline")

		local function timeline_event(event_id, sample_time)
			return {
				kind = "text",
				event_id = event_id,
				tick = tonumber(game.network_tick) or 0,
				sample_time = sample_time,
				actor_id = "guest",
				text = "bounded timeline",
				temporary = false,
			}
		end
		local function event_runtime()
			return MultiplayerRuntime.new({
				registry = ActorRegistry.new(),
				event_handler = multiplayer_apply_network_event,
			})
		end
		multiplayer_reset_network_events(true)
		local future_event_runtime = event_runtime()
		local future_event_ok, future_event_error =
			future_event_runtime:_apply_event_payload(
				timeline_event(1, timeline_base + 60),
				MultiplayerProtocol.MAX_MESSAGE_BYTES
			)
		assert(not future_event_ok
			and future_event_error == "network event sample time is too far ahead"
			and future_event_runtime.received_event_id == 0,
			"future presentation event advanced its ACK")

		multiplayer_reset_network_events(true)
		local event_count_runtime = event_runtime()
		for event_id = 1, 1024 do
			assert(event_count_runtime:_apply_event_payload(
				timeline_event(event_id, timeline_base + 1),
				1
			))
		end
		local event_count_ok, event_count_error =
			event_count_runtime:_apply_event_payload(
				timeline_event(1025, timeline_base + 1),
				1
			)
		assert(not event_count_ok
			and event_count_error == "network event timeline overflow"
			and event_count_runtime.received_event_id == 1024,
			"presentation count limit advanced its ACK")

		multiplayer_reset_network_events(true)
		local event_bytes_runtime = event_runtime()
		for event_id = 1, 128 do
			assert(event_bytes_runtime:_apply_event_payload(
				timeline_event(event_id, timeline_base + 1),
				MultiplayerProtocol.MAX_MESSAGE_BYTES
			))
		end
		local event_bytes_ok, event_bytes_error =
			event_bytes_runtime:_apply_event_payload(
				timeline_event(129, timeline_base + 1),
				MultiplayerProtocol.MAX_MESSAGE_BYTES
			)
		assert(not event_bytes_ok
			and event_bytes_error == "network event timeline overflow"
			and event_bytes_runtime.received_event_id == 128,
			"presentation byte limit advanced its ACK")

		local original_world_sequence = game.network_world_sequence
		local original_received_sequence = game.network_world_received_sequence
		local function timeline_delta(sequence, sample_time)
			return {
				sequence = sequence,
				tick = tonumber(game.network_tick) or 0,
				sample_time = sample_time,
				cells = { { x = 1, y = 1, cell = { b = 77 } } },
			}
		end
		local function world_runtime()
			return MultiplayerRuntime.new({
				registry = ActorRegistry.new(),
				world_delta_applier = multiplayer_apply_world_delta,
			})
		end
		multiplayer_reset_network_events(true)
		game.network_world_sequence = 0
		game.network_world_received_sequence = 0
		local future_world_runtime = world_runtime()
		local future_world_ok, future_world_error =
			future_world_runtime:_apply_world_payload(
				timeline_delta(1, timeline_base + 60),
				NetworkReplication.HEADER_SIZE + 64
			)
		assert(not future_world_ok
			and future_world_error == "world delta sample time is too far ahead"
			and future_world_runtime.received_world_sequence == 0,
			"future world delta advanced its ACK")

		multiplayer_reset_network_events(true)
		game.network_world_sequence = 0
		game.network_world_received_sequence = 0
		local world_count_runtime = world_runtime()
		for sequence = 1, 512 do
			assert(world_count_runtime:_apply_world_payload(
				timeline_delta(sequence, timeline_base + 1),
				1
			))
		end
		local world_count_ok, world_count_error =
			world_count_runtime:_apply_world_payload(
				timeline_delta(513, timeline_base + 1),
				1
			)
		assert(not world_count_ok
			and world_count_error == "world delta timeline overflow"
			and world_count_runtime.received_world_sequence == 512,
			"world-delta count limit advanced its ACK")

		multiplayer_reset_network_events(true)
		game.network_world_sequence = 0
		game.network_world_received_sequence = 0
		local world_bytes_runtime = world_runtime()
		local maximum_world_packet = NetworkReplication.MAX_STORED_BYTES
			+ NetworkReplication.HEADER_SIZE
		for sequence = 1, 15 do
			assert(world_bytes_runtime:_apply_world_payload(
				timeline_delta(sequence, timeline_base + 1),
				maximum_world_packet
			))
		end
		local world_bytes_ok, world_bytes_error =
			world_bytes_runtime:_apply_world_payload(
				timeline_delta(16, timeline_base + 1),
				maximum_world_packet
			)
		assert(not world_bytes_ok
			and world_bytes_error == "world delta timeline overflow"
			and world_bytes_runtime.received_world_sequence == 15,
			"world-delta byte limit advanced its ACK")
		multiplayer_reset_network_events(true)
		game.network_world_sequence = original_world_sequence
		game.network_world_received_sequence = original_received_sequence
		local gameplay_key_handler = love.keypressed
		esc_menu()
		assert(game.escmenu == 1 and #msg.escmenu_guest == 2
			and escmenu[1] and escmenu[2] and escmenu[4] == nil,
			"guest Escape menu exposed host save or display settings")
		esc_menu()
		assert(game.escmenu == nil and love.keypressed == gameplay_key_handler,
			"guest Escape menu did not restore gameplay input")
		local original_esc_menu = esc_menu
		local escape_opened = false
		esc_menu = function()
			escape_opened = true
			game.inputing = true
		end
		pl.isdead = nil
		local escape_ok, escape_error = pcall(
			gameplay_keypressed,
			"escape",
			"escape"
		)
		esc_menu = original_esc_menu
		assert(escape_ok and escape_opened and game.inputing == true,
			("client Escape fell through into text input: %s (opened=%s input=%s)")
				:format(tostring(escape_error), tostring(escape_opened),
					tostring(game.inputing)))
		game.inputing = nil
		return ("mode=multiplayer-gameplay moved=%.1f snapshot=%d state=%d pose=%d progress=%d actors=%d entities=%d presentation=%d encode_ms=%.2f white_ghost=true sound_event=true stereo_audio=true actor_text=true eating_isolated=true damage_isolated=true ui_defaults=true reconciliation=true"):format(
			math.dist(guest_start_x, guest_start_y, guest.truex, guest.truey),
			#stored,
			#state_packet,
			#pose_packet,
			#progress_packet,
			#actor_packet,
			#entity_packet,
			#presentation_packet,
			replication_ms
		)
	end)
	game_delete_save(9)
	love.filesystem.setIdentity(original_identity)
	if not ok then error(result) end
	finish(0, result)
end

local function validate_persistence()
	local original_identity = love.filesystem.getIdentity()
	local original_capture_screenshot = love.graphics.captureScreenshot
	local original_textwall = textwall
	local original_random = love.math.random
	local test_identity = "sarcophagus-persistence-smoke"
	local random_was_replaced = false
	local SaveFormat = require("src.save_format")

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

		-- Current releases must continue to load the original uncompressed .sav
		-- payloads even though newly written saves use a compressed container.
		assert(not SaveFormat.is_container(fixture),
			"legacy fixture unexpectedly uses the new save container")
		assert(love.filesystem.write("1.sav", fixture))
		assert(game_load(1), "legacy uncompressed .sav did not load")
		assert(game_delete_save(1), "legacy uncompressed save was not deleted")
		previous_world = world
		previous_vi = vi
		previous_pl = pl
		previous_game = game

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
		local current_save = assert(love.filesystem.read("2.sav"))
		assert(SaveFormat.is_container(current_save),
			"new game save is not compressed")
		local decoded_save = SaveFormat.decode(current_save)
		assert(#decoded_save == SaveFormat.raw_size(current_save),
			"compressed save header has an invalid raw size")
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
			game.network_guest_recovery = {
				{ inv = {}, recovery_attempts = 8, recovery_last_error = "dense" },
			}
			local hidden_slot = pl.invsize + 50
			pl.inv[hidden_slot] = item_make(31)
			game_migrate()
			assert(type(pl.visited) == "table" and type(pl.ferted) == "table",
				"save migration did not add exploration histories")
			assert(pl.inv[hidden_slot] == nil,
				"save migration left an item in an inaccessible inventory slot")
			assert(game.network_guest_recovery[1].recovery_attempts == 0
				and game.network_guest_recovery[1].recovery_last_error == nil,
				"loaded recovery storage remained permanently parked")
			game.network_guest_recovery = nil
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

local function validate_autosave()
	local original_identity = love.filesystem.getIdentity()
	local original_capture_screenshot = love.graphics.captureScreenshot
	local original_textwall = textwall
	local original_game_save_async = game_save_async
	local test_identity = "sarcophagus-autosave-smoke"
	local messages = {}
	local SaveFormat = require("src.save_format")

	local function finish_background_save()
		local deadline = love.timer.getTime() + 30
		local started_at = love.timer.getTime()
		local saw_serializing = false
		local saw_writing = false
		local longest_update = 0
		local update_count = 0
		local serialize_update_count = 0
		while save_manager.is_busy() and love.timer.getTime() < deadline do
			local stage = save_manager.stage()
			saw_serializing = saw_serializing or stage == "serializing"
			saw_writing = saw_writing or stage == "writing"
			if stage == "serializing" then
				serialize_update_count = serialize_update_count + 1
			end
			local update_started = love.timer.getTime()
			save_manager.update()
			update_count = update_count + 1
			longest_update = math.max(
				longest_update,
				love.timer.getTime() - update_started
			)
			love.timer.sleep(0.001)
		end
		assert(not save_manager.is_busy(), "background save timed out")
		return saw_serializing, saw_writing, longest_update,
			love.timer.getTime() - started_at, update_count, serialize_update_count
	end

	love.filesystem.setIdentity(test_identity)
	game_delete_save(1)
	game_delete_save(2)
	love.filesystem.remove("info.save")
	love.filesystem.remove("info.save.bak")

	local ok, result = pcall(function()
		local fixture, fixture_error = love.filesystem.read("tests/fixtures/9.sav")
		assert(fixture, "cannot read autosave fixture: " .. tostring(fixture_error))
		assert(love.filesystem.write("1.sav", fixture), "cannot stage autosave fixture")
		assert(game_load(1), "autosave fixture did not load")

		love.graphics.captureScreenshot = function() end
		textwall = function(message)
			messages[#messages + 1] = message
		end

		-- Save and Quit must be a checked operation rather than an unconditional
		-- delayed quit. A failed write leaves the paused menu intact; a successful
		-- write closes it and freezes the game until the quit event is sent.
		local original_exit = exit
		local original_quit_after_save = quit_after_save
		local original_pause = game.pause
		local original_escmenu_state = game.escmenu
		local original_escmenu = escmenu
		local original_keypressed = love.keypressed
		local original_oldkeypressed = love.oldkeypressed
		local original_screenshot = game.screenshot
		game.escmenu = 2
		game.pause = true
		exit = nil
		quit_after_save = nil
		love.oldkeypressed = love.keypressed
		game_save_async = function()
			return false, "simulated write failure"
		end
		local saved, save_error = save_and_quit()
		assert(not saved and save_error == "simulated write failure",
			"Save and Quit ignored a failed game save")
		assert(game.escmenu == 2 and game.pause == true and exit == nil,
			"failed Save and Quit still closed the menu or scheduled an exit")

		game_save_async = function(_, options)
			options.on_complete(true)
			return true
		end
		assert(save_and_quit(), "successful Save and Quit was rejected")
		assert(game.escmenu == nil and game.pause == nil
			and exit == 10 and quit_after_save == true,
			"successful Save and Quit did not enter the guarded exit state")
		exit = 2
		assert(quit_countdown_update() and exit == 1,
			"quit countdown does not advance independently of simulation state")

		exit = original_exit
		quit_after_save = original_quit_after_save
		game.pause = original_pause
		game.escmenu = original_escmenu_state
		escmenu = original_escmenu
		love.keypressed = original_keypressed
		love.oldkeypressed = original_oldkeypressed
		game.screenshot = original_screenshot
		game_save_async = original_game_save_async

		game.savepos = 1
		game.dt = 0
		game.lastsave = nil
		game.idle = true
		game.nosave = nil
		game.fadein = nil
		game.fadeout = nil
		local before_save = assert(love.filesystem.read("1.sav"))
		assert(autosave_update(game.dt, 4) == "scheduled"
			and game.lastsave == 600,
			"fresh game did not schedule its first autosave for ten minutes")
		game.dt = 601

		assert(autosave_update(game.dt, 4) == "queued",
			"elapsed autosave timer did not queue a save")
		assert(game.autosave == true, "queued autosave flag is missing")
		assert(love.filesystem.read("1.sav") == before_save,
			"autosave wrote before the queued frame")
		assert(messages[#messages] == msg.game[3],
			"autosave queue message is missing or not localized")

		game.fadein = 0.5
		local message_count = #messages
		assert(autosave_update(game.dt, 4) == "deferred",
			"autosave was not deferred during a fade")
		assert(game.autosave == true and #messages == message_count,
			"deferred autosave was lost or repeated its queue message")

		game.fadein = nil
		local snapshot_started = love.timer.getTime()
		assert(autosave_update(game.dt, 4) == "started",
			"queued autosave did not start after the fade")
		local snapshot_time = love.timer.getTime() - snapshot_started
		assert(snapshot_time < 0.5,
			"save snapshot caused an excessive main-thread stall")
		assert(game.autosave == "saving" and save_manager.is_busy(),
			"background autosave state is missing")
		world.__async_save_probe = "changed after snapshot"
		assert(love.filesystem.read("1.sav") == before_save,
			"background autosave replaced the file before serialization finished")
		assert(save_manager.update(0.0001) == "serializing",
			"large save serialization was not split across frames")
		local saw_serializing, saw_writing, longest_update,
			autosave_elapsed, autosave_updates,
			autosave_serialize_updates = finish_background_save()
		assert(saw_serializing and saw_writing,
			"autosave did not pass through serialization and worker stages")
		assert(longest_update < 0.02,
			"incremental save exceeded its per-frame time budget")
		assert(autosave_serialize_updates < 180,
			"incremental save took too many rendered frames")
		assert(game.autosave == nil and game.lastsave == 1201,
			"successful autosave did not schedule the next ten-minute interval")
		assert(love.filesystem.getInfo("1.sav.bak"),
			"autosave did not preserve the previous save as a backup")
		local compressed_save = assert(love.filesystem.read("1.sav"))
		assert(compressed_save ~= before_save,
			"autosave did not replace the staged save")
		assert(SaveFormat.is_container(compressed_save),
			"autosave did not use the compressed save container")
		local raw_size = assert(SaveFormat.raw_size(compressed_save))
		assert(#compressed_save < raw_size,
			"compressed save is not smaller than its raw payload")
		assert(game_load(1), "autosaved game could not be loaded again")
		assert(world.__async_save_probe == nil,
			"live world mutations leaked into an in-progress save snapshot")
		assert(game.autosave == nil,
			"autosave queue flag leaked into the saved game")

		-- Save and Quit runs while the simulation is paused. Its serialization
		-- should finish in one update instead of inheriting the deliberately tiny
		-- autosave slices and making the user wait for many rendered frames.
		local quit_saved
		local quit_save_error
		assert(game_save_async(2, {
			kind = "quit",
			screenshot = false,
			on_complete = function(saved, completion_error)
				quit_saved = saved
				quit_save_error = completion_error
			end,
		}), "background quit save did not start")
		local quit_serialize_started = love.timer.getTime()
		assert(save_manager.update() == "writing",
			"quit serialization was spread across autosave-sized slices")
		local quit_serialize_time = love.timer.getTime() - quit_serialize_started
		finish_background_save()
		assert(quit_saved and quit_save_error == nil,
			"background quit save failed")

		game_delete_save(2)
		game.savepos = 2
		game.dt = 2000
		game.lastsave = 1000
		game.autosave = nil
		game.idle = true
		game.nosave = true
		assert(autosave_update(game.dt, 4) == nil,
			"No autosave setting did not suppress the timer")
		assert(not love.filesystem.getInfo("2.sav") and game.autosave == nil,
			"No autosave setting still created a save")

		game.nosave = nil
		game.lastsave = 1000
		assert(autosave_update(game.dt, 2) == nil,
			"active mouse input did not postpone autosave")

		game.autosave = true
		game.dt = 3000
		game.fadein = nil
		game.fadeout = nil
		game_save_async = function()
			return false, "simulated autosave failure"
		end
		assert(autosave_update(game.dt, 4) == "failed",
			"failed autosave was reported as successful")
		assert(game.autosave == nil and game.lastsave == 3030,
			"failed autosave did not schedule a bounded retry")
		game_save_async = original_game_save_async

		return ("mode=autosave timer=600 incremental=true worker=true compressed=true backup=true reload=true disabled=true retry=30 snapshot_ms=%.1f max_step_ms=%.1f autosave_elapsed_ms=%.1f autosave_updates=%d autosave_serialize_updates=%d quit_serialize_ms=%.1f raw=%d stored=%d")
			:format(
				snapshot_time * 1000,
				longest_update * 1000,
				autosave_elapsed * 1000,
				autosave_updates,
				autosave_serialize_updates,
				quit_serialize_time * 1000,
				raw_size,
				#compressed_save
			)
	end)

	save_manager.shutdown()
	love.graphics.captureScreenshot = original_capture_screenshot
	textwall = original_textwall
	game_save_async = original_game_save_async
	game_delete_save(1)
	game_delete_save(2)
	love.filesystem.remove("info.save")
	love.filesystem.remove("info.save.bak")
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
		if name == "quad.table" then
			local BlobWriter = require("src.BlobWriter")
			local deterministic = BlobWriter()
				:writeDeterministic(quadlist)
				:tostring()
			assert(data == deterministic,
				"quad.table was not written with deterministic key ordering")
		end

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
		assert(msg.menu.lan_found:find("В астрале отозвался живой мир", 1, true)
			and msg.menu.lan_found:find("войти призраком", 1, true),
			"Russian multiplayer discovery does not use the astral-world metaphor")
		assert(msg.network.quality == "Астральная связь: _1_",
			"Russian multiplayer quality exposes technical measurements")
		local multiplayer_copy = {
			msg.escmenu_guest[2],
			msg.menu.lan_found,
		}
		local function append_multiplayer_copy(value)
			if type(value) == "string" then
				multiplayer_copy[#multiplayer_copy + 1] = value
			elseif type(value) == "table" then
				for _, child in pairs(value) do
					append_multiplayer_copy(child)
				end
			end
		end
		append_multiplayer_copy(msg.network)
		local visible_multiplayer_copy = table.concat(multiplayer_copy, "\n")
		for _, technical_term in ipairs({
			"LAN", "RTT", "host", "Host", "локальной сет", "сетев",
			"подключ", "соедин", "сесси", "клиент", "протокол", "сервер",
			"тайм-аут", "мультипле", "синхрони", "сборк", "идентификатор",
			"верси",
		}) do
			assert(not visible_multiplayer_copy:find(technical_term, 1, true),
				"Russian multiplayer UI exposes technical term: " .. technical_term)
		end
		local inventory_hint, inventory_hint_rows = inventory_mode_toggle_hint(true, 1)
		assert(inventory_hint:find("Инвентарь", 1, true) and inventory_hint_rows == 2,
			"equipment view does not point back to the populated inventory")
		local equipment_hint, equipment_hint_rows = inventory_mode_toggle_hint(false, 1)
		assert(equipment_hint:find("Надетые предметы", 1, true)
			and equipment_hint_rows == 2,
			"inventory view does not expose the equipment list")
		local empty_hint, empty_hint_rows = inventory_mode_toggle_hint(false, 0)
		assert(empty_hint == "" and empty_hint_rows == 0,
			"inventory shows an unusable equipment shortcut")
		local numeric_slots = inventory_numeric_slots({
			[1] = { i = 5 },
			[7] = { i = 26 },
			r = { i = 5 },
			l = { i = 19 },
		}, 9)
		assert(#numeric_slots == 2
			and numeric_slots[1] == 1
			and numeric_slots[2] == 7,
			"equipped items leak into the numeric inventory view")
		assert(inventory_z_action_label(item[109]) == "В руки    ",
			"a placeable inventory item is misleadingly labelled as a ground drop")
		assert(inventory_z_action_label(item[5]) == "Положить  ",
			"an ordinary inventory item lost its ground-drop label")
		assert(msg.escmenu[5] == "Масштаб 2×"
			and msg.escmenu[6] == "Инвертировать стерео",
			"obsolete smooth 2x menu option is still exposed")
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
    local application_icon = love.window.getIcon()
    assert(application_icon ~= nil,
        "the running application is still using the inherited LÖVE icon")
    assert(application_icon:getWidth() == 256 and application_icon:getHeight() == 256,
        "the running application icon has unexpected dimensions")

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
	local russian_death_title = assert(
		quadlist["wasted_ru.png"],
		"Russian death title is missing from the sprite atlas"
	)
	assert(russian_death_title.w == 437 and russian_death_title.h == 78,
		"Russian death title dimensions changed")
	local english_title = {}
	local russian_title = {
		getViewport = function()
			return 0, 0, 437, 78
		end,
	}
	local death_titles = { en = english_title, ru = russian_title }
	assert(death_title_sprite(death_titles, "ru") == russian_title,
		"Russian locale does not select its localized death title")
	assert(death_title_sprite(death_titles, "unknown") == english_title,
		"Unknown locale does not fall back to the English death title")
	local title_x, title_y, score_x, score_y = death_title_layout(
		russian_title,
		width,
		height,
		"ru"
	)
	assert(title_x == math.floor((width - 437) / 2),
		"localized death title is not centered by its real width")
	assert(title_y == math.floor(height / 2 - 100)
		and score_x == title_x + 12 and score_y == title_y + 76,
		"localized death score layout is invalid")
	local _, english_title_y, _, english_score_y = death_title_layout(
		{
			getViewport = function()
				return 0, 0, 256, 78
			end,
		},
		width,
		height,
		"en"
	)
	assert(english_score_y == english_title_y + 72,
		"English death score spacing changed")
	assert(DEFAULT_AMBIENT_LIGHT == 0.10, "default cave visibility changed")
	local clean_water = { water_render_colors(0) }
	local dirty_water = { water_render_colors(200) }
	assert(clean_water[4] < 0.35 and dirty_water[4] < 0.35,
		"water fill is opaque enough to look like a solid rectangle")
	assert(dirty_water[1] > clean_water[1]
		and dirty_water[2] > clean_water[2]
		and dirty_water[3] < clean_water[3],
		"dirty water no longer changes from blue towards green")
	assert(clean_water[8] > clean_water[4],
		"water surface is not distinguishable from its fill")
	local _, wrapped_inventory_name = pixel_font:getWrap(
		"2]·Очень длинное название предмета для проверки",
		210
	)
	assert(gui_wrapped_line_count(
		"2]·Очень длинное название предмета для проверки",
		210,
		pixel_font
	) == #wrapped_inventory_name and #wrapped_inventory_name > 1,
		"inventory frame does not account for wrapped item names")
	local localized_item_details = table.concat({
		"{#3e8948ff}#дробление: 3",
		"{#ff0044ff}урон: 4-5    урон/с: 6.00",
		"{#8b9bb4ff}Очень длинное локализованное описание свойства инструмента",
		"",
		"{#fee761ff}Z] {#ffffffff}Положить  {#fee761ff}R] {#ffffffff}Бросить   ",
		"{#fee761ff}P] {#ffffffff}Надеть    {#fee761ff}I] {#ffffffff}Осмотреть ",
	}, "\n").."\n"
	local visible_item_details = localized_item_details
		:gsub("{#%x+}", "")
		:gsub("\n+$", "")
	local _, wrapped_item_details = pixel_font:getWrap(
		visible_item_details,
		210
	)
	assert(gui_wrapped_text_line_count(
		localized_item_details,
		210,
		pixel_font
	) == #wrapped_item_details and #wrapped_item_details > 6,
		"inventory details frame does not account for localized wrapped rows")
	local current_x, current_y = gui_restored_panel_origin(100, 200, nil, nil)
	assert(current_x == 100 and current_y == 200,
		"ground inventory reused a panel origin from an earlier frame")
	local restored_x, restored_y = gui_restored_panel_origin(100, 200, 30, 40)
	assert(restored_x == 30 and restored_y == 40,
		"ground card did not restore its current-frame panel origin")
	assert(normalize_gameplay_key("up", false) == "w",
		"up arrow is not a gameplay/crafting alternative to W")
	assert(normalize_gameplay_key("down", false) == "s",
		"down arrow is not a gameplay/crafting alternative to S")
	assert(normalize_gameplay_key("up", true) == "up",
		"Ctrl+arrow no longer reaches development controls")
	assert(gameplay_key_from_event("z", "q") == "z",
		"a layout-reported Z is mistaken for the Q pick-up action")
	assert(gameplay_key_from_event("я", "z") == "z",
		"the physical Z shortcut does not work in a Cyrillic layout")
	assert(gameplay_key_from_event("q", "z") == "q",
		"a layout-reported Q is mistaken for the Z drop action")

	-- Digging may use a tool from an equipment slot, but that internal choice
	-- must not switch the inventory UI from its selected numeric slot. This was
	-- especially visible when a full inventory could not select newly dug loot.
	local original_inv_for_digging = pl.inv
	local original_invsize_for_digging = pl.invsize
	local original_invselect_for_digging = pl.invselect
	pl.invsize = 9
	pl.inv = { r = { i = 11, t = 100 } }
	for slot = 1, pl.invsize do
		pl.inv[slot] = { i = 3 }
	end
	pl.invselect = 4
	local digging_tool = digging_tool_selection({ dig = 1 }, pl.invselect)
	assert(digging_tool.slot == "r" and not digging_tool.cant,
		"digging did not find the equipped bone tool")
	assert(pl.invselect == 4 and type(pl.invselect) == "number",
		"automatic digging-tool choice changed the inventory selection")
	pl.inv[4] = { i = 5, t = 100 }
	digging_tool = digging_tool_selection({ dig = 1 }, pl.invselect)
	assert(digging_tool.slot == 4 and pl.invselect == 4,
		"digging ignored the already selected suitable tool")
	digging_tool = digging_tool_selection({ dig = 0 }, pl.invselect)
	assert(not digging_tool.cant and digging_tool.no_tool
		and digging_tool.slot == 4 and pl.invselect == 4,
		"tool-free digging changed the inventory selection")
	pl.inv = original_inv_for_digging
	pl.invsize = original_invsize_for_digging
	pl.invselect = original_invselect_for_digging

	local original_stats_for_prayer = pl.stats
	local original_dying_for_prayer = pl.dying
	local original_isdead_for_prayer = pl.isdead
	local original_unrest_for_prayer = pl.unrest
	local original_lasthit_for_prayer = game.lasthit
	local original_sct_for_prayer = sct
	pl.stats = {
		faith = { hp = 5, maxhp = 100, pc = 5 },
		body = { hp = 40, maxhp = 100, pc = 40 },
	}
	pl.dying = nil
	pl.isdead = nil
	pl.unrest = 0
	sct = {}
	assert(reset_failed_prayer_faith() == 5,
		"failed prayer did not consume the accumulated faith")
	assert(pl.stats.faith.hp == 0 and pl.stats.faith.pc == 0
		and pl.stats.body.hp == 40,
		"failed prayer dealt the missing faith as body damage")
	pl.stats = original_stats_for_prayer
	pl.dying = original_dying_for_prayer
	pl.isdead = original_isdead_for_prayer
	pl.unrest = original_unrest_for_prayer
	game.lasthit = original_lasthit_for_prayer
	sct = original_sct_for_prayer

	local original_buffs_after_death = pl.buffs
	local original_dying_after_death = pl.dying
	local original_isdead_after_death = pl.isdead
	pl.buffs = {}
	pl.dying = 1
	pl.isdead = true
	assert(buff_add(12, "keep") == false and next(pl.buffs) == nil,
		"a skull can apply chills after the player has died")
	pl.buffs = original_buffs_after_death
	pl.dying = original_dying_after_death
	pl.isdead = original_isdead_after_death

	-- Reproduce the reported case: the stone is selected, moss is the first
	-- ground item, and the true/player tile pairs temporarily disagree.  Z must
	-- prepend the stone to the visible ground list without removing the moss.
	local original_world_for_drop = world
	local original_ttl_list_for_drop = game.ttl_list
	local original_justremoved_for_drop = game.justremoved
	local original_inv_for_drop = pl.inv
	local original_invsize_for_drop = pl.invsize
	local original_invselect_for_drop = pl.invselect
	local original_inv_show_for_drop = pl.inv_show
	local original_inv_show_c_for_drop = pl.inv_show_c
	local original_xt_for_drop, original_yt_for_drop = pl.xt, pl.yt
	local original_tx_for_drop, original_ty_for_drop = pl.tx, pl.ty
	local ground_moss = { i = 109 }
	local other_tile_item = { i = 31 }
	world = {
		[10] = { [10] = { b = 0, i = { ground_moss } } },
		[11] = { [11] = { b = 0, i = { other_tile_item } } },
	}
	game.ttl_list = {}
	pl.inv = { { i = 26 }, { i = 5 } }
	pl.invsize = 9
	pl.invselect = 2
	pl.xt, pl.yt = 10, 10
	pl.tx, pl.ty = 11, 11
	inv_show()
	local original_gr2x_for_mouse = game.gr2x
	local original_inventory_mouse_rows = game.inventory_mouse_rows
	local original_inventory_action_mouse_rows = game.inventory_action_mouse_rows
	local original_ground_mouse_rows = game.ground_mouse_rows
	local original_craft_ini_for_mouse = craft_ini
	local original_item_unlock_for_mouse = item_unlock
	local original_keypressed_for_mouse = love.keypressed
	local original_gui_throw_down_for_mouse = game.gui_throw_down
	craft_ini = function() end
	item_unlock = function() end
	game.gr2x = true
	game.inventory_mouse_rows = {
		{ x = 100, y = 100, width = 100, height = 20, slot = 1 },
	}
	game.inventory_action_mouse_rows = {
		{ x = 100, y = 160, width = 100, height = 20, key = "p" },
		{ x = 210, y = 160, width = 100, height = 20, key = "r", hold = true },
	}
	game.ground_mouse_rows = {}
	assert(inventory_gui_mousepressed(110, 110),
		"inventory row mouse click was not consumed")
	assert(pl.invselect == 1,
		"inventory row mouse click selected the wrong slot")
	local clicked_action
	love.keypressed = function(key, scancode)
		clicked_action = { key, scancode }
	end
	assert(inventory_gui_mousepressed(110, 170),
		"inventory action mouse click was not consumed")
	assert(clicked_action and clicked_action[1] == "p"
		and clicked_action[2] == "p",
		"inventory action mouse click did not dispatch its displayed shortcut")
	assert(inventory_gui_mousepressed(220, 170),
		"held inventory action mouse click was not consumed")
	assert(game.gui_throw_down,
		"mouse-down on the throw action did not start charging a throw")
	game.gui_throw_down = nil
	love.keypressed = original_keypressed_for_mouse
	pl.invselect = 2
	assert(inventory_drop_selected_item(),
		"Z failed to put the selected stone on the ground")
	assert(#pl.inv == 1 and pl.inv[1].i == 26,
		"Z removed or retained the wrong inventory item")
	assert(world[10][10].i[1].i == 5 and world[10][10].i[2] == ground_moss,
		"Z picked up/replaced the moss instead of dropping the stone")
	assert(#world[11][11].i == 1 and world[11][11].i[1] == other_tile_item,
		"Z dropped the stone on a different coordinate pair")
	game.inventory_mouse_rows = {}
	game.ground_mouse_rows = {
		{
			x = 100,
			y = 130,
			width = 100,
			height = 20,
			index = 2,
			ground_item = ground_moss,
		},
	}
	assert(inventory_gui_mousepressed(110, 140),
		"ground row mouse click was not consumed")
	assert(inv_find(109) and #world[10][10].i == 1
		and world[10][10].i[1].i == 5,
		"ground row mouse click picked up the wrong item")
	game.gr2x = original_gr2x_for_mouse
	game.inventory_mouse_rows = original_inventory_mouse_rows
	game.inventory_action_mouse_rows = original_inventory_action_mouse_rows
	game.ground_mouse_rows = original_ground_mouse_rows
	craft_ini = original_craft_ini_for_mouse
	item_unlock = original_item_unlock_for_mouse
	love.keypressed = original_keypressed_for_mouse
	game.gui_throw_down = original_gui_throw_down_for_mouse
	world = original_world_for_drop
	game.ttl_list = original_ttl_list_for_drop
	game.justremoved = original_justremoved_for_drop
	pl.inv = original_inv_for_drop
	pl.invsize = original_invsize_for_drop
	pl.invselect = original_invselect_for_drop
	pl.inv_show = original_inv_show_for_drop
	pl.inv_show_c = original_inv_show_c_for_drop
	pl.xt, pl.yt = original_xt_for_drop, original_yt_for_drop
	pl.tx, pl.ty = original_tx_for_drop, original_ty_for_drop

	-- Placeable inventory items enter the carried-block state on Z and are
	-- placed with Space. A second/repeated Z must not immediately return the
	-- block to the inventory; Q remains the explicit return action.
	local original_carry_for_put = pl.iscarry
	local original_candrop_for_put = pl.candrop
	local original_canthrow_for_put = pl.canthrow
	local original_ithrow_for_put = ithrow
	local original_justremoved_for_put = game.justremoved
	local original_inv_for_put = pl.inv
	local original_invsize_for_put = pl.invsize
	local original_invselect_for_put = pl.invselect
	local original_inv_show_for_put = pl.inv_show
	local original_inv_show_c_for_put = pl.inv_show_c
	pl.iscarry = nil
	pl.candrop = nil
	pl.inv = { { i = 109 }, { i = 26 } }
	pl.invsize = 9
	pl.invselect = 1
	inv_show()
	assert(inventory_z_action(), "Z did not move moss into the carried-block state")
	local carried_moss = pl.iscarry
	assert(carried_moss and carried_moss.b == 108,
		"Z prepared the wrong placeable block")
	assert(not inventory_z_action(), "repeated Z toggled the carried block")
	assert(pl.iscarry == carried_moss and not inv_find(109),
		"repeated Z returned the carried moss to the inventory")
	pl.iscarry = original_carry_for_put
	pl.candrop = original_candrop_for_put
	pl.canthrow = original_canthrow_for_put
	ithrow = original_ithrow_for_put
	game.justremoved = original_justremoved_for_put
	pl.inv = original_inv_for_put
	pl.invsize = original_invsize_for_put
	pl.invselect = original_invselect_for_put
	pl.inv_show = original_inv_show_for_put
	pl.inv_show_c = original_inv_show_c_for_put

	assert(not development_reload_requested("f7", false, true),
		"plain F7 triggers a development reload instead of prayer")
	assert(development_reload_requested("f7", true, true),
		"Ctrl+F7 no longer triggers a development reload")
	assert(not development_reload_requested("f7", true, false),
		"release build accepts the development reload shortcut")
	assert(normalize_esc_menu_key("up", "up") == "w",
		"up arrow is not an Esc-menu alternative to W")
	assert(normalize_esc_menu_key("down", "down") == "s",
		"down arrow is not an Esc-menu alternative to S")
	assert(normalize_esc_menu_key("left", "left") == "a",
		"left arrow is not an Esc-menu alternative to A")
	assert(normalize_esc_menu_key("right", "right") == "d",
		"right arrow is not an Esc-menu alternative to D")
	assert(achievement_page_after_key(1, "right", 7) == 2,
		"right arrow does not advance achievement pages")
	assert(achievement_page_after_key(1, "left", 7) == 7,
		"left arrow does not wrap achievement pages")
	assert(achievement_page_after_key(7, "d", 7) == 1,
		"D does not wrap achievement pages")
	assert(achievement_page_after_key(2, "a", 7) == 1,
		"A does not move to the previous achievement page")
	assert(menu_save_position(nil, nil) == 1,
		"menu has no safe initial save slot before its first update")
	assert(menu_save_position(nil, 4) == 4,
		"menu ignores the save slot restored from metadata")
	assert(menu_save_position("invalid", 12) == 1,
		"menu accepts a malformed save slot")
	assert(menu_move_save_position(nil, -1, nil) == 9,
		"an immediate up-arrow cannot wrap from the first save slot")
	assert(menu_move_save_position(nil, 1, nil) == 2,
		"an immediate down-arrow cannot move from the first save slot")
	local compatible_lan_server = {
		protocol_version = MultiplayerProtocol.VERSION,
		game_version = (game_version or ""):match("^%s*(.-)%s*$"),
		content_hash = multiplayer and multiplayer.content_hash,
		joinable = true,
	}
	local prompt_state, prompt_server = menu_lan_prompt_state({
		{
			protocol_version = MultiplayerProtocol.VERSION + 1,
			game_version = compatible_lan_server.game_version,
			content_hash = compatible_lan_server.content_hash,
			joinable = true,
		},
		compatible_lan_server,
	})
	assert(prompt_state == "found" and prompt_server == compatible_lan_server,
		"LAN menu does not offer the first compatible discovered game")
	assert(menu_lan_prompt_state({
		{
			protocol_version = compatible_lan_server.protocol_version,
			game_version = compatible_lan_server.game_version,
			content_hash = compatible_lan_server.content_hash,
			joinable = false,
		},
	}) == "unavailable", "LAN menu offers an occupied game")
	assert(menu_lan_prompt_state({}, "multicast unavailable")
		== "discovery_unavailable", "LAN discovery failure has no friendly menu state")
	assert(menu_lan_prompt_state({}, nil, { timed_out = true }) == "timeout",
		"silent LAN discovery has no finite diagnostic state")
	assert(menu_lan_prompt_state({}) == "searching",
		"empty LAN discovery does not leave the menu in its searching state")
	assert(menu_lan_prompt_text("found") == msg.menu.lan_found,
		"an actionable discovered game is hidden from the menu")
	for _, state in ipairs({
		"searching", "unavailable", "discovery_unavailable", "timeout",
	}) do
		assert(menu_lan_prompt_text(state) == "",
			"non-actionable LAN state leaks into the main menu: " .. state)
	end
	assert(msg.menu.lan_found:find("J", 1, true)
		and not msg.menu.lan_found:find("_1_", 1, true),
		"discovered-game prompt exposes technical data instead of the J action")
	assert(tool_damage_per_second({ dmgmin = 2, dmgmax = 6, digspeed = 2 }) == 2,
		"weapon DPS does not use the average of minimum and maximum damage")
	assert(next_numeric_id({ [1] = true, [3] = true }) == 4,
		"numeric ID allocation relies on the undefined length of a sparse table")
	assert(mob_collision_blocked({ right = 1, down = 1, left = 1, up = 0 }),
		"mob collision logic ignores a blocked ceiling")
	assert(not mob_collision_blocked({ right = 1, down = 1, left = 1, up = 1 }),
		"mob collision logic reports a clear path as blocked")
	assert(carried_block_placement_warning(56, nil) == msg.stone[56].info,
		"stonework placement failure does not explain its support requirement")
	assert(carried_block_placement_warning(56, { 1, 1 }) == nil,
		"stonework rejects a valid attachment point")
	assert(carried_block_placement_warning(35, nil) == nil,
		"ordinary carried blocks incorrectly require side support")
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

	local original_world_for_ttl = world
	local original_time_for_ttl = game.time
	local original_ttl_list = game.ttl_list
	local ttl_test_id = 9999
	local original_ttl_test_stone = stone[ttl_test_id]
	local observed_ttl_times = {}
	world = { [10] = { [10] = { b = ttl_test_id, t = 0 } } }
	game.ttl_list = {}
	stone[ttl_test_id] = {
		ttl = 10,
		die = ttl_test_id,
		ondie = function ()
			observed_ttl_times[#observed_ttl_times + 1] = game.time
		end,
	}
	game.time = 35
	assert(ttl_advance_block(10, 10) == 3,
		"off-screen TTL simulation discarded missed cycles")
	assert(#observed_ttl_times == 3
		and observed_ttl_times[1] == 10
		and observed_ttl_times[2] == 20
		and observed_ttl_times[3] == 30,
		"missed TTL cycles were not replayed at their scheduled times")
	assert(world[10][10].t == 30 and game.time == 35,
		"TTL catch-up lost the next deadline or changed current game time")

	world = {
		[10] = {
			[10] = { b = 100, t = 0, age = 1, stage = 1 },
			[12] = { b = 5 },
		},
		[11] = {
			[10] = { b = 13, wt = 1000, e = 1000 },
		},
	}
	game.ttl_list = {}
	game.time = stone[100].ttl * 3 + 1
	assert(ttl_advance_block(10, 10) == 3,
		"off-screen plant did not replay every missed growth cycle")
	assert(math.abs(world[10][10].age - 1.3) < 0.000001,
		"off-screen plant age advanced by the wrong amount")

	-- The giant weed's late seed stage is deterministic when it reaches a
	-- solid ceiling. Catch-up must preserve that original rule as well.
	world = {
		[9] = { [10] = { b = 1 } },
		[10] = {
			[10] = { b = 14, t = 0 },
			[12] = { b = 5 },
		},
	}
	game.ttl_list = {}
	game.time = stone[14].ttl + stone[15].ttl + 1
	assert(ttl_advance_block(10, 10) == 2 and world[10][10].b == 16,
		"giant weed cannot reach its ceiling seed stage during catch-up")

	stone[ttl_test_id] = original_ttl_test_stone
	world = original_world_for_ttl
	game.time = original_time_for_ttl
	game.ttl_list = original_ttl_list

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

	local original_skull_mob_create = mob_create
	local original_skull_textwall = textwall
	local awakened_skull
	local awakened_skull_message
	mob_create = function(x, y, id)
		awakened_skull = { x = x, y = y, id = id }
	end
	textwall = function(message_text)
		awakened_skull_message = message_text
	end
	item[12].ongrounddie(7, 8)
	assert(awakened_skull and awakened_skull.x == 7
		and awakened_skull.y == 8 and awakened_skull.id == 12,
		"expired ground skull did not awaken as a skull mob")
	assert(awakened_skull_message == msg.item[12].txt[1],
		"awakened ground skull did not report its localized message")
	mob_create = original_skull_mob_create
	textwall = original_skull_textwall

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
	local original_font = font
	assert(locked_txt("flammable items") == "fiaimabia irair ",
		"English locked-hint obfuscation changed")
	local tagged_locked_hint = locked_txt(
		"{#fee761ff}flammable{#ffffffff} items"
	)
	assert(tagged_locked_hint:find("{#fee761ff}", 1, true)
		and tagged_locked_hint:find("{#ffffffff}", 1, true),
		"locked-hint obfuscation damaged a color marker")
	-- validate_display runs before love.load, while the live reload happens
	-- during gameplay. Supply the same kind of initialized runtime font so
	-- language_set also reapplies names to the content tables in this test.
	font = pixel_font
	for _, language in ipairs({"en", "ru"}) do
		language_set(language, false)
		local locked_hint_count = 0
		for collection_name, collection in pairs({
			item = msg.item,
			stone = msg.stone,
		}) do
			for definition_id, definition in pairs(collection) do
				for tip_number, tip in pairs(definition.tips or {}) do
					local locked_tip = locked_txt(tip)
					local _, source_newlines = tip:gsub("\n", "")
					local _, locked_newlines = locked_tip:gsub("\n", "")
					assert(locked_tip ~= tip .. " ", (
						"%s %s %s tip %s is readable while locked"
					):format(language, collection_name, definition_id, tip_number))
					assert(utf8.len(locked_tip) == utf8.len(tip) + 1, (
						"%s %s %s tip %s changed display length while locked"
					):format(language, collection_name, definition_id, tip_number))
					assert(source_newlines == locked_newlines, (
						"%s %s %s tip %s changed line count while locked"
					):format(language, collection_name, definition_id, tip_number))
					locked_hint_count = locked_hint_count + 1
				end
			end
		end
		assert(locked_hint_count > 0,
			language .. " locale has no locked hints to validate")
		local expected_tool_tags = language == "ru" and {
			dig = "#копание",
			cut = "#резка",
			chop = "#рубка",
			smash = "#дробление",
			pierce = "#пробой",
			water = "#вода",
			oil = "#масло",
			vinegar = "#уксус",
			salsa = "#сальса",
		} or {
			dig = "#dig",
			cut = "#cut",
			chop = "#chop",
			smash = "#smash",
			pierce = "#pierce",
			water = "#water",
			oil = "#oil",
			vinegar = "#vinegar",
			salsa = "#salsa",
		}
		for tool, expected_tag in pairs(expected_tool_tags) do
			assert(craft_tool_tag(tool) == expected_tag,
				language .. " tool tag is invalid: " .. tool)
			local tool_panel = draw_tool({ tool = { [tool] = 2 } }, "", 0)
			assert(tool_panel:find(msg.gui.item[tool] .. "2", 1, true),
				language .. " inventory tool stat is not localized: " .. tool)
		end
		for _, tool in ipairs({ "dig", "cut", "chop", "smash", "pierce" }) do
			local expected_tag = expected_tool_tags[tool]
			assert(
				ground_gather_requirements({ [tool] = 2 })
					== " {#3e8948ff}(" .. expected_tag .. ":2)",
				language .. " ground requirement is not localized: " .. tool
			)
			if language == "ru" then
				assert(not msg.gui.itemlack[tool]:find("#" .. tool, 1, true),
					"Russian missing-tool message leaks English tag: " .. tool)
			end
		end
		for stone_id, definition in pairs(stone) do
			for tool in pairs(definition.gather or {}) do
				assert(expected_tool_tags[tool],
					("stone %s has an unlocalized gather tool: %s")
						:format(stone_id, tostring(tool)))
			end
		end
		local unknown_recipe_tools = {}
		for recipe_id, recipe in pairs(craft.recipies) do
			for tool in pairs(recipe.tools or {}) do
				if not expected_tool_tags[tool] then
					unknown_recipe_tools[tool] = recipe_id
				end
			end
		end
		local unknown_recipe_tool_names = {}
		for tool, recipe_id in pairs(unknown_recipe_tools) do
			unknown_recipe_tool_names[#unknown_recipe_tool_names + 1] =
				tool .. " (recipe " .. recipe_id .. ")"
		end
		table.sort(unknown_recipe_tool_names)
		assert(#unknown_recipe_tool_names == 0,
			"unlocalized recipe tools: " .. table.concat(unknown_recipe_tool_names, ", "))
		local internal_tool_stats = {
			crafthit = true,
			craftspeed = true,
			dighands = true,
			dighit = true,
			digstat = true,
			digspeed = true,
			dmg = true,
			dmgmax = true,
			dmgmin = true,
			dmgtype = true,
			hithit = true,
		}
		local unknown_item_tool_stats = {}
		for item_id, definition in pairs(item) do
			for stat in pairs(definition.tool or {}) do
				if not expected_tool_tags[stat] and not internal_tool_stats[stat] then
					unknown_item_tool_stats[stat] = item_id
				end
			end
		end
		local unknown_item_tool_names = {}
		for stat, item_id in pairs(unknown_item_tool_stats) do
			unknown_item_tool_names[#unknown_item_tool_names + 1] =
				stat .. " (item " .. item_id .. ")"
		end
		table.sort(unknown_item_tool_names)
		assert(#unknown_item_tool_names == 0,
			"unclassified item tool stats: " .. table.concat(unknown_item_tool_names, ", "))
		assert(
			ground_gather_requirements(stone[144].gather)
				== " {#3e8948ff}(" .. expected_tool_tags.cut .. ":2)",
			language .. " seaweed requirement is not localized"
		)
		if language == "ru" then
			assert(msg.item[12].txt[1] ==
				"Лежащий на земле череп пробуждается.",
				"awakened ground skull message has a misleading translation")
			assert(msg.item[281].name == "Памятка об огне и плавке",
				"fire tutorial item is still presented as a burning fire")
			assert(msg.item[193].info ==
				"Использование: расходует камень и возвращает вас на Перекрёсток.",
				"Hearthstone still advertises the nonexistent Innkeeper")
			local russian_seaweed_name = stone[144].name
			stone[144].name = "Seaweed"
			language_set(language, false)
			assert(stone[144].name == russian_seaweed_name
				and stone[144].name == "Водоросли",
				("Russian content names are not restored after a Lua reload "
					.. "(before=%s, after=%s, message=%s)"):format(
						tostring(russian_seaweed_name),
						tostring(stone[144].name),
						tostring(msg.stone[144] and msg.stone[144].name)
					))
		end
		assert(msg.achi.gui[6]:find("←/→", 1, true),
			language .. " achievement controls omit the arrow keys")
		local expected_gather_tag = language == "ru"
			and " {#3e8948ff}(#рубка:3)"
			or " {#3e8948ff}(#chop:3)"
		assert(ground_gather_requirements({ chop = 3 }) == expected_gather_tag,
			language .. " ground gathering requirement is not localized")
		assert(ground_gather_requirements({ dig = 0 }) == "",
			language .. " zero-level ground gathering requirement is visible")
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
	action_key, action_hint = ground_card_action_hint(false, false, stone[89])
	assert(action_key == "Space" and action_hint == msg.gui[45],
		language .. " Jack-o'-lantern pickup action is missing")
	assert(stone[89].digtoinv == 92 and item[92].put == 89,
		language .. " Jack-o'-lantern no longer round-trips through inventory")
	action_key, action_hint = ground_card_action_hint(false, false, {
		gather = { dig = 1 },
	})
	assert(action_key == "Space" and action_hint == msg.gui[46],
		language .. " diggable ground block action is missing")
	action_key, action_hint = ground_card_action_hint(false, false)
	assert(action_key == nil and action_hint == nil,
		language .. " ground card shows an unavailable action")
	end
	language_set(original_language, false)
	font = original_font

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

local function validate_smooth2x_filter()
	assert(smooth2x_available(),
		"the optional smooth 2x shader pipeline did not compile")

	local previous_canvas = love.graphics.getCanvas()
	local previous_shader = love.graphics.getShader()
	local previous_blend_mode, previous_alpha_mode = love.graphics.getBlendMode()
	local red, green, blue, alpha = love.graphics.getColor()
	local source = love.graphics.newCanvas(8, 8, { dpiscale = 1 })
	local output = love.graphics.newCanvas(16, 16, { dpiscale = 1 })
	source:setFilter("nearest", "nearest")

	love.graphics.setCanvas(source)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.setColor(1, 1, 1, 1)
	for y = 0, 7 do
		for x = 0, y do
			love.graphics.rectangle("fill", x, y, 1, 1)
		end
	end

	love.graphics.setCanvas(output)
	love.graphics.clear(0, 0, 0, 1)
	assert(draw_smooth2x_world(source),
		"smooth 2x draw helper rejected valid render targets")
	love.graphics.setCanvas(previous_canvas)

	local pixels = output:newImageData()
	local blended_pixels = 0
	for y = 0, 15 do
		for x = 0, 15 do
			local value = pixels:getPixel(x, y)
			if value > 0.015 and value < 0.985 then
				blended_pixels = blended_pixels + 1
			end
		end
	end
	local white = pixels:getPixel(2, 14)
	local black = pixels:getPixel(14, 2)
	assert(blended_pixels >= 8,
		"smooth 2x did not interpolate any intermediate edge pixels")
	assert(white > 0.95 and black < 0.05,
		"smooth 2x blurred flat image regions")

	pixels:release()
	source:release()
	output:release()
	love.graphics.setShader(previous_shader)
	love.graphics.setBlendMode(previous_blend_mode, previous_alpha_mode)
	love.graphics.setColor(red, green, blue, alpha)
end

local function wait_for_window_mode(predicate, timeout)
	local deadline = love.timer.getTime() + (timeout or 2)
	repeat
		love.event.pump()
		if predicate() then return true end
		love.timer.sleep(0.01)
	until love.timer.getTime() >= deadline
	return predicate()
end

local function validate_display_modes()
	local original_width, original_height, original_flags = love.window.getMode()
	local original_fullscreen_setting = game.fullscreen
	local original_double_setting = game.gr2x
	local background = os.getenv("SARCOPHAGUS_TEST_BACKGROUND") == "1"

	local ok, result = pcall(function()
		game.fullscreen = false
		local windowed_ok, windowed_error = screen_full()
		assert(windowed_ok ~= false,
			"windowed mode request failed: " .. tostring(windowed_error))
		assert(wait_for_window_mode(function()
			local _, _, flags = love.window.getMode()
			return not flags.fullscreen
		end), "windowed mode transition timed out")
		local width, height, flags = love.window.getMode()
		assert(not flags.fullscreen, "windowed mode did not activate")
		assert(width > 0 and height > 0, "windowed mode has invalid dimensions")

		game.gr2x = false
		screen_res()
		assert(not enhanced_2x_enabled(),
			"enhanced 2x renderer is active at normal scale")
		local normal_x, normal_y = screen.x, screen.y
		assert(normal_x == math.floor(width / 32) + 3,
			"normal-size horizontal viewport is invalid")
		assert(normal_y == math.floor(height / 32) + 3,
			"normal-size vertical viewport is invalid")

		game.gr2x = true
		screen_res()
		game.smooth2x = false
		assert(enhanced_2x_enabled(),
			"legacy smooth2x setting still disables 2x rendering")
		game.smooth2x = nil
		assert(screen.x == math.ceil(normal_x / 2)
			and screen.y == math.ceil(normal_y / 2),
			"double-size mode does not halve the logical viewport")

		local fullscreen_width, fullscreen_height = width, height
		local fullscreen_status = "skipped-background"
		if not background then
			game.fullscreen = true
			local fullscreen_ok, fullscreen_error = screen_full()
			fullscreen_status = "skipped-unfocused"
			if fullscreen_ok == false then
				assert(not love.window.hasFocus(),
					"fullscreen mode request failed: " .. tostring(fullscreen_error)
						.. " (focus=true)")
			else
				assert(wait_for_window_mode(function()
					local _, _, current_flags = love.window.getMode()
					return current_flags.fullscreen
				end), "fullscreen mode transition timed out (focus="
					.. tostring(love.window.hasFocus()) .. ")")
				local fullscreen_flags
				fullscreen_width, fullscreen_height, fullscreen_flags =
					love.window.getMode()
				assert(fullscreen_flags.fullscreen,
					"fullscreen mode did not activate")
				assert(fullscreen_width > 0 and fullscreen_height > 0,
					"fullscreen mode has invalid dimensions")
				fullscreen_status = ("%dx%d"):format(
					fullscreen_width,
					fullscreen_height
				)
			end
		end

		game.fullscreen = false
		windowed_ok, windowed_error = screen_full()
		assert(windowed_ok ~= false,
			"windowed restore request failed: " .. tostring(windowed_error))
		assert(wait_for_window_mode(function()
			local _, _, current_flags = love.window.getMode()
			return not current_flags.fullscreen
		end), "windowed restore transition timed out")
		local _, _, restored_window_flags = love.window.getMode()
		assert(not restored_window_flags.fullscreen,
			"windowed mode did not return after fullscreen")
		local layout = render_canvas_layout()
		local canvas_width, canvas_height = gr2x:getPixelDimensions()
		local output_width, output_height = smooth2x_canvas:getPixelDimensions()
		local water_width, water_height = water_canvas:getPixelDimensions()
		assert(canvas_width == layout.world_width
			and canvas_height == layout.world_height
			and output_width == layout.output_width
			and output_height == layout.output_height
			and water_width == layout.water_width
			and water_height == layout.water_height,
			"logical render targets were not resized with the Retina window")
		assert(gr2x:getDPIScale() == 1 and smooth2x_canvas:getDPIScale() == 1
			and block_canvas:getDPIScale() == 1
			and water_canvas:getDPIScale() == 1,
			"pixel-art render targets unexpectedly allocate at Retina density")
		validate_smooth2x_filter()

		return ("mode=display-modes window=%dx%d fullscreen=%s double=true"):format(
			width,
			height,
			fullscreen_status
		)
	end)

	-- Restore the mode in which the smoke-test process was launched before it
	-- exits, so desktop fullscreen never leaks into a failed test run.
	game.fullscreen = original_flags.fullscreen or false
	game.gr2x = original_double_setting
	love.window.setMode(original_width, original_height, original_flags)
	if background_minimize_enabled() and love.window.minimize then
		pcall(love.window.minimize)
	end
	screen_res()
	game.fullscreen = original_fullscreen_setting

	if not ok then
		error(result)
	end
	finish(0, result)
end

local function begin_display_modes_test()
	local frames = 0
	love.draw = function() end
	love.update = function()
		frames = frames + 1
		if frames < 2 then return end
		love.update = function() end
		local ok, err = pcall(validate_display_modes)
		if not ok then
			finish(1, "mode=display-modes " .. tostring(err))
		end
	end
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

local function begin_render_test(mode, cleanup)
	local delegate_update = love.update
	local delegate_draw = love.draw
	local wrapper_update
	local wrapper_draw
	local requested = false
	local playable_frames = 0
	local game_started = mode == "menu" or mode == "loaded"
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
			or mode == "loaded" and 30
			or 90
		if game_started and playable_frames >= frames_needed and not requested then
			requested = true
			love.graphics.captureScreenshot(function(image_data)
				if cleanup then cleanup() end
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

local function begin_loaded_render_test(slot)
	local original_identity = love.filesystem.getIdentity()
	local test_identity = "sarcophagus-loaded-render-smoke"
	local save_name = tostring(slot) .. ".sav"
	love.filesystem.setIdentity(test_identity)
	love.filesystem.remove(save_name)

	local fixture_name = "tests/fixtures/" .. save_name
	local fixture, fixture_error = love.filesystem.read(fixture_name)
	assert(fixture, "cannot read render fixture: " .. tostring(fixture_error))
	assert(love.filesystem.write(save_name, fixture), "cannot stage render fixture")
	assert(game_load(slot), "cannot load render fixture")

	game.savepos = slot
	game.gr2x = true
	game.menu = nil
	screen_res()
	love.update = love.old_update
	love.draw = love.old_draw

	begin_render_test("loaded", function()
		love.filesystem.remove(save_name)
		love.filesystem.setIdentity(original_identity)
	end)
end

function smoke.install(specification)
    local mode, value = specification:match("^([^:]+):?(.*)$")
    local original_load = love.load

	local function ignore_real_input()
		love.keypressed = function() end
		love.keyreleased = function() end
		love.mousepressed = function() end
		love.mousereleased = function() end
		love.wheelmoved = function() end
	end

	-- Smoke tests drive the game directly and never expect real input.  Ignore
	-- events from the temporary LÖVE windows so typing elsewhere cannot reach
	-- partially initialized gameplay callbacks while a test is quitting.
	ignore_real_input()

	love.load = function(...)
		if background_minimize_enabled() and love.window.minimize then
			pcall(love.window.minimize)
		end
		if mode == "multiplayer-gameplay-process-host"
			or mode == "multiplayer-gameplay-process-client" then
			original_load(...)
			ignore_real_input()
			local role = mode:match("multiplayer%-gameplay%-process%-(.+)")
			local ok, err = pcall(install_process_gameplay_test, role, value)
			if not ok then
				finish(1, "mode=" .. mode .. " " .. tostring(err))
			end
			return
		end

		if mode == "network-process-host" or mode == "network-process-client" then
			local role = mode:match("network%-process%-(.+)")
			local ok, err = pcall(install_process_network_test, role, value)
			if not ok then
				finish(1, "mode=" .. mode .. " " .. tostring(err))
			end
			return
		end

		if mode == "network" then
			local ok, err = pcall(validate_network_core)
			if not ok then
				finish(1, "mode=network " .. tostring(err))
			end
			return
		end

		if mode == "actors" then
			local ok, err = pcall(validate_actor_architecture)
			if not ok then
				finish(1, "mode=actors " .. tostring(err))
			end
			return
		end

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
		if background_minimize_enabled() and love.window.minimize then
			pcall(love.window.minimize)
		end
		-- love.load installs the menu callbacks, so suppress real events again.
		-- Tests that need menu input call love.menu_keypressed directly.
		ignore_real_input()

		if mode == "persistence" then
			local ok, err = pcall(validate_persistence)
			if not ok then
				finish(1, "mode=persistence " .. tostring(err))
			end
			return
		end

		if mode == "autosave" then
			local ok, err = pcall(validate_autosave)
			if not ok then
				finish(1, "mode=autosave " .. tostring(err))
			end
			return
		end

		if mode == "multiplayer-gameplay" then
			local ok, err = pcall(validate_multiplayer_gameplay)
			if not ok then
				finish(1, "mode=multiplayer-gameplay " .. tostring(err))
			end
			return
		end

		if mode == "multiplayer-benchmark" then
			local ok, err = xpcall(begin_multiplayer_benchmark, debug.traceback)
			if not ok then
				finish(1, "mode=multiplayer-benchmark " .. tostring(err))
			end
			return
		end

		if mode == "display-modes" then
			begin_display_modes_test()
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

		if mode == "load-render" then
			local slot = tonumber(value)
			assert(slot and slot >= 1 and slot <= 9,
				"invalid render save slot")
			begin_loaded_render_test(slot)
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

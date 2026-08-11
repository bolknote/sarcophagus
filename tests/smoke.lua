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
	local multicast_discovery = os.getenv(
		"SARCOPHAGUS_PROCESS_DISCOVERY"
	) == "multicast"
	local forced_disconnect = (tonumber(os.getenv(
		"SARCOPHAGUS_NET_DISCONNECT_AFTER"
	)) or 0) > 0
	if role == "host" then
		local action_seen, input_seen, delta_sent, event_sent = false, false, false, false
		local completion_elapsed
		local reconnect_seen, reconnect_completed = false, not forced_disconnect
		runtime = Runtime.new({
			registry = registry,
			state_interval = 0.01,
			progress_interval = 0.1,
			world_interval = 0.01,
			spawn_provider = function()
				return { truex = 96, truey = 128, tx = 4, ty = 5, xt = 4, yt = 5 }
			end,
			state_provider = function(session)
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
				end
			end,
			action_handler = function(_, action)
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
				if delta_sent then return nil end
				delta_sent = true
				return {
					sequence = 1,
					tick = 12,
					cells = { { x = 1, y = 1, cell = { b = 77 } } },
				}
			end,
			event_provider = function()
				if event_sent or not action_seen then return nil end
				event_sent = true
				return { kind = "process-test", value = 91 }
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
			if runtime.session.state == Session.STATE.RECONNECT_GRACE then
				reconnect_seen = true
			elseif reconnect_seen and runtime.session.state == Session.STATE.PLAYING then
				reconnect_completed = true
			end
			if runtime:pending_approval() then assert(runtime:approve_guest()) end
			if action_seen and input_seen and reconnect_completed then
				completion_elapsed = completion_elapsed or elapsed
				if elapsed - completion_elapsed >= 0.75 then
					complete(0, "handshake=true input=true action=true reconnect="
						.. tostring(reconnect_seen))
				end
			end
			if elapsed > 12 then
				complete(1, "timeout state=" .. tostring(runtime.session.state))
			end
		end)
	else
		local snapshot_seen, replicated, progress_seen, world_delta, action_result, network_event
		local discovery_requested = discovery_port ~= nil
		local discovery_seen = not discovery_requested
		local action_sent = false
		local process_input
		local next_input_send = 0
		local reconnect_seen, reconnect_completed = false, not forced_disconnect
		runtime = Runtime.new({
			registry = registry,
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
			action_result_handler = function(result) action_result = result end,
			event_handler = function(value)
				network_event = value
				return value.kind == "process-test" and value.value == 91
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
			}))
			if not multicast_discovery then
				assert(runtime.browser:refresh("127.0.0.1", discovery_port))
			end
		else
			assert(connect("127.0.0.1", port))
		end
		guard(function(dt)
			elapsed = elapsed + dt
			runtime:update(dt)
			if runtime.client_state == "reconnecting"
				or runtime.client_state == "resuming" then
				reconnect_seen = true
			elseif reconnect_seen and runtime.client_state == "playing" then
				reconnect_completed = true
			end
			if discovery_port and runtime.role == "offline" then
				local records = runtime:servers()
				if records[1] then
					discovery_seen = (multicast_discovery
						or records[1].address == "127.0.0.1")
						and records[1].gameplay_port == port
					assert(discovery_seen, "discovery returned an invalid host record")
					assert(connect(records[1].address, records[1].gameplay_port))
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
				end
			end
			if reconnect_completed and discovery_seen and snapshot_seen
				and replicated and replicated.input_seen
				and replicated.action_seen and progress_seen and world_delta
				and world_delta.cells[1].cell.b == 77
				and action_result and action_result.ok and network_event then
				complete(0,
					"snapshot=true state=true progress=true world=true action_result=true event=true discovery="
						.. tostring(discovery_requested and discovery_seen)
						.. " reconnect=" .. tostring(reconnect_seen))
			end
			if runtime.client_state == "failed" or runtime.client_state == "rejected" then
				complete(1, "state=" .. tostring(runtime.client_state)
					.. " error=" .. tostring(runtime.last_error))
			end
			if elapsed > 12 then
				complete(1, "timeout state=" .. tostring(runtime.client_state)
					.. " error=" .. tostring(runtime.last_error))
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
	local ItemIdentity = require("src.item_identity")
	local GhostActor = require("src.ghost_actor")
	local NetworkSnapshot = require("src.network.snapshot")
	local NetworkReplication = require("src.network.replication")
	local WorldJournal = require("src.network.world_journal")
	local Runtime = require("src.network.runtime")
	local LANDiscovery = require("src.network.discovery")
	local enet_ok, enet = pcall(require, "enet")
	local socket_ok, socket = pcall(require, "socket")
	assert(enet_ok and type(enet) == "table", "lua-enet is unavailable")
	assert(socket_ok and type(socket) == "table", "LuaSocket is unavailable")
	local content_hash = ContentHash.compute({ "version.txt", "conf.lua" })
	assert(type(content_hash) == "string" and #content_hash == 64,
		"content manifest hash is invalid")
	local identity_state = {}
	local world_id = Identity.ensure_world(identity_state)
	local test_content_hash = string.rep("b", 64)
	local discovery_session_id = string.rep("c", 64)
	local client_nonce = string.rep("d", 64)
	local incomplete_nonce = string.rep("e", 64)
	assert(Identity.valid(world_id) and Identity.ensure_world(identity_state) == world_id,
		"world identity is not stable")

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
		local client_stats = client:stats()
		local server_stats = server:stats()
		assert(client_stats.packets_sent >= 1 and client_stats.bytes_sent > 0
			and server_stats.packets_received >= 1 and server_stats.bytes_received > 0,
			"ENet transport diagnostics did not count traffic")
	end)
	if client then client:close() end
	if server then server:close() end
	assert(loopback_ok, loopback_error)

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
		local applied_world
		local simulated_input
		local handled_action
		local catchup_allowed = true
		local pending_delta = {
			sequence = 1,
			tick = 2,
			cells = { { x = 1, y = 1, cell = { b = 12 } } },
		}
		runtime_server = Runtime.new({
			registry = host_registry,
			state_interval = 0.001,
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
			world_delta_provider = function()
				local value = pending_delta
				pending_delta = nil
				return value
			end,
		})
		runtime_client = Runtime.new({
			registry = client_registry,
			state_interval = 0.001,
			world_interval = 0.001,
			state_applier = function(snapshot_state)
				applied_snapshot = snapshot_state
				client_registry:bind_host(snapshot_state.host_actor, {})
				client_registry:bind_guest(snapshot_state.guest_actor, { local_actor = true })
			end,
			replication_applier = function(value) applied_state = value end,
			world_delta_applier = function(value) applied_world = value end,
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
		pump(function()
			return runtime_server.session.state == Session.STATE.PLAYING
				and runtime_client.client_state == "playing"
		end, "runtime snapshot handshake did not reach playing")
		assert(applied_snapshot and applied_snapshot.header.tick == 1,
			"runtime snapshot was not applied")
		local runtime_input = InputState.new()
		InputState.set_button(runtime_input, "a", true)
		InputState.advance(runtime_input)
		assert(runtime_client:send_input(runtime_input))
		assert(runtime_client:send_action({ action_id = "runtime:1", action = "test" }))
		pump(function()
			return simulated_input and handled_action == "runtime:1"
				and applied_state and applied_world
		end, "runtime input/action/replication loop did not complete")
		assert(applied_world.cells[1].cell.b == 12,
			"runtime world delta was corrupted")
		local original_guest = runtime_server.session.guest
		assert(runtime_server.session:disconnect("runtime-test", false))
		assert(runtime_server.transport:disconnect(0, true))
		runtime_server.peer = nil
		pump(function()
			return runtime_server.session.state == Session.STATE.PLAYING
				and runtime_client.client_state == "playing"
		end, "runtime reconnect did not resume playing")
		assert(runtime_server.session.guest == original_guest,
			"runtime reconnect replaced the guest actor")
		catchup_allowed = false
		assert(runtime_server.session:disconnect("runtime-overflow-test", false))
		assert(runtime_server.transport:disconnect(0, true))
		runtime_server.peer = nil
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
	end)
	if browser then browser:close() end
	if responder then responder:close() end
	assert(discovery_ok, discovery_error)

	local hello = Protocol.hello({
		game_version = "test-version",
		content_hash = test_content_hash,
		capabilities = { "snapshot-v1", "input-v1", "actions-v1" },
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
		capabilities = { "snapshot-v1", "input-v1", "actions-v1" },
		client_nonce = client_nonce,
	})
	local hash_ok, hash_error = Protocol.validate_hello(invalid_hash_hello, {
		game_version = "test-version",
		content_hash = test_content_hash,
	})
	assert(not hash_ok and hash_error == "invalid_content_hash",
		"handshake accepted a malformed content hash")
	assert(not Protocol.decode(string.rep("x", Protocol.MAX_MESSAGE_BYTES + 1)),
		"oversized protocol message was accepted")

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
	assert(not session:resume(string.rep("0", 64)))
	assert(session:resume(reconnect_token))
	assert(session.state == Session.STATE.PLAYING)
	assert(session:disconnect("wifi", false, clock))
	clock = 26
	assert(session:update(clock))
	assert(drops == 1 and dropped_items == 1,
		"guest possessions were not dropped exactly once")
	assert(session.state == Session.STATE.LISTENING and registry.guest == nil,
		"expired guest session was not cleaned up")
	assert(session:update(clock + 100) and drops == 1,
		"finished session repeated possession drop")

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
	retry_runtime.client_state = "resuming"
	retry_runtime:_client_message({
		kind = "welcome",
		payload = {
			resumed = true,
			session_id = string.rep("6", 64),
			reconnect_token = string.rep("7", 64),
			actor_id = "guest",
		},
	})
	assert(retry_runtime.client_state == "playing" and retry_sends == 2,
		"client did not retry an unconfirmed action after reconnect")
	retry_runtime:_client_message({
		kind = "action_result",
		payload = { action_id = 77, ok = true },
	})
	assert(#retry_runtime.pending_action_order == 0,
		"client retained an acknowledged action")
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

		multiplayer_reset_network_events(true)
		local previous_role, previous_session = multiplayer.role, multiplayer.session
		local previous_active_actor = ACTIVE_ACTOR_ID
		multiplayer.role = "host"
		multiplayer.session = { state = MultiplayerSession.STATE.PLAYING }
		ACTIVE_ACTOR_ID = "guest"
		-- gravel.ogg is stereo. Network presentation must gracefully fall back
		-- to non-spatial playback because OpenAL only positions mono sources.
		sound_add("smoke_network_sound", 5)
		ACTIVE_ACTOR_ID = previous_active_actor
		local sound_event = multiplayer_next_network_event()
		multiplayer.role, multiplayer.session = previous_role, previous_session
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

		InputState.set_button(runtime.input, "d", true)
		runtime.input.aim = {
			world_x = guest.truex + 64,
			world_y = guest.truey,
			tile_x = guest.xt + 2,
			tile_y = guest.yt,
		}
		local host_truex, host_truey = pl.truex, pl.truey
		local guest_start_x, guest_start_y = guest.truex, guest.truey
		for _ = 1, 45 do multiplayer_simulate_guest(guest, runtime.input, 1 / 30) end
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
		assert(multiplayer_guest_action(guest, {
			action = "pickup",
			item_uid = pickup.uid,
		}), "server rejected the authoritative ground item uid")
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
		assert(#progress_packet < NetworkReplication.MAX_STORED_BYTES,
			"progress replication state exceeded its packet budget")
		local decoded_state, decoded_kind = NetworkReplication.decode(state_packet)
		assert(decoded_state and decoded_kind == "state"
			and decoded_state.actor_schema == 2,
			"fast LZ4 replication state did not round-trip")

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
		actors:set_local(guest)
		guest.state = "idle"
		guest.network_target_truex = guest.truex + 5
		guest.network_target_truey = guest.truey + 3.5
		assert(multiplayer_reconcile_local_actor(1 / 60)
			and guest.truex == saved_x
			and guest.truey == saved_y + 3.5
			and guest.network_target_truex == nil
			and guest.network_target_truey == nil,
			"local reconciliation dragged or vertically floated the ghost")
		guest.truex, guest.truey, guest.state = saved_x, saved_y, saved_state
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
		return ("mode=multiplayer-gameplay moved=%.1f snapshot=%d state=%d progress=%d actors=%d entities=%d presentation=%d encode_ms=%.2f white_ghost=true sound_event=true stereo_audio=true actor_text=true eating_isolated=true damage_isolated=true ui_defaults=true reconciliation=true"):format(
			math.dist(guest_start_x, guest_start_y, guest.truex, guest.truey),
			#stored,
			#state_packet,
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
	assert(menu_lan_prompt_state({}) == "searching",
		"empty LAN discovery does not leave the menu in its searching state")
	assert(msg.menu.lan_manual == nil and msg.menu.manual_prompt == nil,
		"main menu still exposes manual IP entry")
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
		local canvas_width, canvas_height = gr2x:getPixelDimensions()
		local window_pixel_width, window_pixel_height =
			love.graphics.getPixelDimensions()
		assert(canvas_width == window_pixel_width
			and canvas_height == window_pixel_height,
			"world render targets were not resized with the Retina window")
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
	if background and love.window.minimize then pcall(love.window.minimize) end
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
		if os.getenv("SARCOPHAGUS_TEST_BACKGROUND") == "1"
			and love.window.minimize then
			pcall(love.window.minimize)
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
		if os.getenv("SARCOPHAGUS_TEST_BACKGROUND") == "1"
			and love.window.minimize then
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

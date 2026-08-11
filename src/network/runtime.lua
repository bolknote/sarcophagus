local ContentHash = require("src.network.content_hash")
local Discovery = require("src.network.discovery")
local EnetTransport = require("src.network.enet_transport")
local Identity = require("src.network.identity")
local InputState = require("src.input_state")
local Protocol = require("src.network.protocol")
local Replication = require("src.network.replication")
local Session = require("src.network.session")
local Snapshot = require("src.network.snapshot")

local Runtime = {}
Runtime.__index = Runtime

local function trimmed(value)
	if type(value) ~= "string" then return tostring(value or "unknown") end
	return value:match("^%s*(.-)%s*$")
end

local channels_from_guest = {
	hello = Protocol.CHANNEL.CONTROL,
	ready = Protocol.CHANNEL.CONTROL,
	disconnect = Protocol.CHANNEL.CONTROL,
	stream_ack = Protocol.CHANNEL.CONTROL,
	resume_ready = Protocol.CHANNEL.CONTROL,
	ping = Protocol.CHANNEL.CONTROL,
	pong = Protocol.CHANNEL.CONTROL,
	input = Protocol.CHANNEL.INPUT,
	action = Protocol.CHANNEL.WORLD,
}

local channels_from_host = {
	welcome = Protocol.CHANNEL.CONTROL,
	reject = Protocol.CHANNEL.CONTROL,
	snapshot_meta = Protocol.CHANNEL.CONTROL,
	snapshot_done = Protocol.CHANNEL.CONTROL,
	start = Protocol.CHANNEL.CONTROL,
	shutdown = Protocol.CHANNEL.CONTROL,
	disconnect = Protocol.CHANNEL.CONTROL,
	action_result = Protocol.CHANNEL.WORLD,
	event = Protocol.CHANNEL.WORLD,
	resume_synced = Protocol.CHANNEL.WORLD,
	ping = Protocol.CHANNEL.CONTROL,
	pong = Protocol.CHANNEL.CONTROL,
}

local function valid_message_channel(role, kind, channel)
	local expected = role == "host" and channels_from_guest[kind]
		or channels_from_host[kind]
	return expected ~= nil and channel == expected
end

local function valid_reason(value)
	return value == nil or Protocol.validate_string(value, 256)
end

local function sanitized_reason(value, fallback)
	value = Protocol.sanitize_utf8(value or fallback or "network_error")
	value = value:gsub("[%z\1-\31\127]", " ")
	value = Protocol.sanitize_utf8(value, 256)
	if not Protocol.validate_string(value, 256) then return fallback or "network_error" end
	return value
end

local function valid_welcome(payload)
	if type(payload) ~= "table"
		or not Protocol.validate_identity(payload.session_id)
		or not Protocol.validate_identity(payload.reconnect_token)
		or payload.actor_id ~= "guest" then
		return false
	end
	if payload.resumed == true then return true end
	return payload.resumed == nil
		and payload.snapshot_version == Protocol.SNAPSHOT_VERSION
end

local function valid_action_result(payload)
	return type(payload) == "table"
		and Protocol.validate_action_id(payload.action_id)
		and type(payload.ok) == "boolean"
		and valid_reason(payload.error)
end

local function valid_stream_position(value)
	return Protocol.validate_nonnegative_integer(value, 9007199254740991)
end

local function valid_stream_ack(payload)
	return type(payload) == "table"
		and valid_stream_position(payload.world_sequence)
		and valid_stream_position(payload.event_id)
end

local function valid_ping(payload)
	return type(payload) == "table"
		and Protocol.validate_nonnegative_integer(payload.nonce, 2147483647)
end

local function action_key(action_id)
	return type(action_id) .. ":" .. tostring(action_id)
end

function Runtime.new(options)
	options = options or {}
	assert(type(options.registry) == "table", "actor registry is required")
	return setmetatable({
		registry = options.registry,
		state_provider = options.state_provider,
		state_applier = options.state_applier,
		spawn_provider = options.spawn_provider,
		dropper = options.dropper,
		action_handler = options.action_handler,
		action_rejection_handler = options.action_rejection_handler,
		input_handler = options.input_handler,
		simulation_handler = options.simulation_handler,
		replication_provider = options.replication_provider,
		replication_applier = options.replication_applier,
		world_delta_provider = options.world_delta_provider,
		world_delta_applier = options.world_delta_applier,
		world_delta_reset = options.world_delta_reset,
		event_provider = options.event_provider,
		event_handler = options.event_handler,
		event_reset = options.event_reset,
		catchup_validator = options.catchup_validator,
		action_result_handler = options.action_result_handler,
		pending_actions = {},
		pending_action_order = {},
		max_pending_actions = 256,
		action_retry_accumulator = 0,
		action_retry_interval = math.max(0.1,
			tonumber(options.action_retry_interval) or 0.75),
		world_outbox = {},
		world_acked_sequence = 0,
		world_highest_sequence = 0,
		max_world_outbox = math.max(32,
			math.floor(tonumber(options.max_world_outbox) or 512)),
		event_outbox = {},
		event_acked_id = 0,
		event_highest_id = 0,
		max_event_outbox = math.max(64,
			math.floor(tonumber(options.max_event_outbox) or 1024)),
		received_world_sequence = 0,
		received_event_id = 0,
		role = "offline",
		transport = nil,
		session = nil,
		peer = nil,
		content_hash = nil,
		game_version = nil,
		world_id = nil,
		client_state = "offline",
		client_hello = nil,
		client_welcome = nil,
		assembler = nil,
		early_snapshot_chunks = {},
		early_snapshot_bytes = 0,
		snapshot_done_tick = nil,
		snapshot_ready_tick = nil,
		last_error = nil,
		last_event = nil,
		approval_request = nil,
		discovery = nil,
		browser = nil,
		next_discovery_refresh = 0,
		discovery_error = nil,
		display_name = nil,
		advertisement_id = nil,
		state_accumulator = 0,
		progress_accumulator = 0,
		world_accumulator = 0,
		input_accumulator = 0,
		state_interval = math.max(1 / 120,
			tonumber(options.state_interval) or (1 / 15)),
		progress_interval = math.max(0.1,
			tonumber(options.progress_interval) or 1),
		world_interval = math.max(1 / 120,
			tonumber(options.world_interval) or (1 / 15)),
		input_interval = math.max(1 / 120,
			tonumber(options.input_interval) or (1 / 30)),
		connection_host = nil,
		connection_port = nil,
		client_deadline = nil,
		connect_timeout = math.max(1, tonumber(options.connect_timeout) or 10),
		approval_timeout = math.max(1, tonumber(options.approval_timeout) or 35),
		snapshot_timeout = math.max(1, tonumber(options.snapshot_timeout) or 60),
		hello_timeout = math.max(1, tonumber(options.hello_timeout) or 8),
		reconnect_timeout = math.max(5, tonumber(options.reconnect_timeout) or 20),
		heartbeat_interval = math.max(0.5,
			tonumber(options.heartbeat_interval) or 2),
		heartbeat_timeout = math.max(4,
			tonumber(options.heartbeat_timeout) or 12),
		heartbeat_nonce = 0,
		next_heartbeat = nil,
		last_peer_activity = nil,
		host_hello_deadline = nil,
		resume_phase = nil,
		resume_deadline = nil,
		reconnect_deadline = nil,
		next_reconnect_attempt = nil,
	}, Runtime)
end

local function clock()
	if love and love.timer then return love.timer.getTime() end
	return os.clock()
end

function Runtime:_reset_outboxes()
	self.world_outbox = {}
	self.world_acked_sequence = 0
	self.world_highest_sequence = 0
	self.event_outbox = {}
	self.event_acked_id = 0
	self.event_highest_id = 0
end

function Runtime:_reset_received_streams()
	self.received_world_sequence = 0
	self.received_event_id = 0
end

local function discard_acknowledged(outbox, field, acknowledged)
	while outbox[1] and outbox[1][field] <= acknowledged do
		table.remove(outbox, 1)
	end
end

function Runtime:_acknowledge_streams(payload)
	if not valid_stream_ack(payload) then return false, "invalid stream acknowledgement" end
	if payload.world_sequence > self.world_highest_sequence
		or payload.event_id > self.event_highest_id then
		return false, "stream acknowledgement is ahead of host"
	end
	if payload.world_sequence > self.world_acked_sequence then
		self.world_acked_sequence = payload.world_sequence
		discard_acknowledged(self.world_outbox, "sequence", payload.world_sequence)
	end
	if payload.event_id > self.event_acked_id then
		self.event_acked_id = payload.event_id
		discard_acknowledged(self.event_outbox, "event_id", payload.event_id)
	end
	return true
end

function Runtime:_mark_outboxes_for_replay()
	for _, item in ipairs(self.world_outbox) do item.sent = false end
	for _, item in ipairs(self.event_outbox) do item.sent = false end
end

function Runtime:_neutralize_guest_input()
	local guest = self.session and self.session.guest
	local runtime = guest and self.registry:runtime(guest)
	local input = runtime and runtime.input
	if not input then return end
	-- Keep the sequence so the next client snapshot remains monotonic, but never
	-- simulate held movement or actions from the instant before a disconnect.
	input.held = {}
	input.pressed = {}
	input.released = {}
	input.aim = {}
end

function Runtime:_send_stream_ack()
	if self.role ~= "client" or not self.transport or not self.peer then
		return false, "peer is not connected"
	end
	local sent, send_error = self.transport:send(self.peer, "stream_ack", {
		world_sequence = self.received_world_sequence,
		event_id = self.received_event_id,
	}, Protocol.CHANNEL.CONTROL, true)
	if not sent then self.last_error = tostring(send_error) end
	return sent, send_error
end

function Runtime:_queue_world_delta(delta)
	if type(delta) ~= "table"
		or not valid_stream_position(delta.sequence)
		or delta.sequence ~= self.world_highest_sequence + 1 then
		return false, "invalid host world sequence"
	end
	if #self.world_outbox >= self.max_world_outbox then
		return false, "world acknowledgement backlog overflow"
	end
	self.world_highest_sequence = delta.sequence
	self.world_outbox[#self.world_outbox + 1] = {
		sequence = delta.sequence,
		delta = delta,
		packet = nil,
		sent = false,
	}
	return true
end

function Runtime:_send_world_outbox(limit)
	local sent_count = 0
	for _, item in ipairs(self.world_outbox) do
		if not item.sent then
			if not item.packet then
				local built, packet = pcall(Replication.encode_world, item.delta)
				if not built then return false, tostring(packet), sent_count end
				item.packet = packet
			end
			local sent, send_error = self.transport:send_raw(
				self.peer, item.packet, Protocol.CHANNEL.WORLD, true
			)
			if not sent then return false, tostring(send_error), sent_count end
			item.sent = true
			sent_count = sent_count + 1
			if sent_count >= limit then break end
		end
	end
	return true, nil, sent_count
end

function Runtime:_queue_event(event)
	if type(event) ~= "table" or not valid_stream_position(event.event_id)
		or event.event_id ~= self.event_highest_id + 1 then
		return false, "invalid host event sequence"
	end
	if #self.event_outbox >= self.max_event_outbox then
		return false, "event acknowledgement backlog overflow"
	end
	self.event_highest_id = event.event_id
	self.event_outbox[#self.event_outbox + 1] = {
		event_id = event.event_id,
		event = event,
		sent = false,
	}
	return true
end

function Runtime:_send_event_outbox(limit)
	local sent_count = 0
	for _, item in ipairs(self.event_outbox) do
		if not item.sent then
			local sent, send_error = self.transport:send(
				self.peer,
				"event",
				item.event,
				Protocol.CHANNEL.WORLD,
				true
			)
			if not sent then return false, tostring(send_error), sent_count end
			item.sent = true
			sent_count = sent_count + 1
			if sent_count >= limit then break end
		end
	end
	return true, nil, sent_count
end

function Runtime:_complete_resume_sync()
	if self.role ~= "host" or self.resume_phase ~= "sending_sync"
		or not self.peer or not self.session then return false end
	local sent, send_error = self.transport:send(
		self.peer,
		"resume_synced",
		{ session_id = self.session.session_id },
		-- This confirmation and all replayed deltas share a reliable channel,
		-- which makes their ordering explicit across an ENet reconnect.
		Protocol.CHANNEL.WORLD,
		true
	)
	if not sent then
		self.last_error = tostring(send_error)
		return false, send_error
	end
	self.transport:flush()
	self.resume_phase = nil
	self.resume_deadline = nil
	self.last_error = nil
	return true
end

function Runtime:_set_client_state(state)
	self.client_state = state
	local timeout
	if state == "connecting" then
		timeout = self.connect_timeout
	elseif state == "awaiting_approval" then
		timeout = self.approval_timeout
	elseif state == "receiving_snapshot" or state == "catching_up" then
		timeout = self.snapshot_timeout
	end
	self.client_deadline = timeout and (clock() + timeout) or nil
end

function Runtime:_fail_client(reason)
	self.last_error = tostring(reason or "invalid authoritative state")
	self:_set_client_state("failed")
	self:_send_peer_and_close("disconnect", { reason = self.last_error })
	return false, self.last_error
end

function Runtime:_send_peer_and_close(kind, payload, peer)
	local target = peer or self.peer
	local sent, send_error = true
	if self.transport and target and kind then
		sent, send_error = self.transport:send(
			target,
			kind,
			payload or {},
			Protocol.CHANNEL.CONTROL,
			true
		)
		self.transport:flush()
	end
	local closed, close_error = true
	local close_data = self.role == "host" and 1 or 0
	if self.transport then
		if self.transport.disconnect_peer then
			closed, close_error = self.transport:disconnect_peer(target, close_data, false)
		else
			closed, close_error = self.transport:disconnect(close_data, false)
		end
	end
	if target == self.peer then self.peer = nil end
	if not sent then return false, send_error end
	if not closed then return false, close_error end
	return true
end

function Runtime:_close_lost_peer(peer)
	local target = peer or self.peer
	if self.transport and target then
		if self.transport.disconnect_peer then
			self.transport:disconnect_peer(target, 0, true)
		else
			self.transport:disconnect(0, true)
		end
	end
	if target == self.peer then self.peer = nil end
end

function Runtime:_handle_transport_loss(reason, peer)
	reason = tostring(reason or "transport_disconnect")
	local target = peer or self.peer
	if target and self.peer and target ~= self.peer then return false, "stale peer" end
	self.last_error = reason
	self.last_peer_activity = nil
	self.next_heartbeat = nil
	self.host_hello_deadline = nil
	self.resume_phase = nil
	self.resume_deadline = nil
	self:_close_lost_peer(target)
	if self.role == "host" then
		self.approval_request = nil
		self:_neutralize_guest_input()
		if self.session then self.session:disconnect(reason, false) end
		self:_mark_outboxes_for_replay()
		return true
	end
	local reconnectable = self.client_welcome
		and self.client_welcome.reconnect_token
		and (self.client_state == "playing"
			or self.client_state == "catching_up"
			or self.client_state == "resuming"
			or self.client_state == "resuming_sync"
			or self.client_state == "reconnecting")
	if reconnectable then
		self:_set_client_state("reconnecting")
		self.reconnect_deadline = clock() + self.reconnect_timeout
		self.next_reconnect_attempt = clock() + 0.1
	else
		self:_set_client_state("disconnected")
	end
	return true
end

function Runtime:_update_heartbeat()
	if not self.peer or not self.transport or not self.last_peer_activity then return end
	local current = clock()
	if self.last_peer_activity and current - self.last_peer_activity > self.heartbeat_timeout then
		self:_handle_transport_loss("heartbeat_timeout", self.peer)
		return
	end
	if current < (self.next_heartbeat or 0) then return end
	self.heartbeat_nonce = (self.heartbeat_nonce + 1) % 2147483648
	local sent, send_error = self.transport:send(
		self.peer,
		"ping",
		{ nonce = self.heartbeat_nonce },
		Protocol.CHANNEL.CONTROL,
		true
	)
	if not sent then self.last_error = tostring(send_error) end
	self.next_heartbeat = current + self.heartbeat_interval
end

function Runtime:_content_hash(value)
	if value then return value end
	if not self.content_hash then self.content_hash = ContentHash.compute() end
	return self.content_hash
end

function Runtime:_catchup_status()
	if type(self.catchup_validator) ~= "function" then return true end
	local checked, valid, validation_error = pcall(self.catchup_validator)
	if not checked then return false, tostring(valid) end
	if valid ~= true then
		return false, tostring(validation_error or "snapshot_catchup_overflow")
	end
	return true
end

function Runtime:_reset_events(reset_sequence)
	if type(self.event_reset) ~= "function" then return true end
	local called, reset, reset_error = pcall(self.event_reset, reset_sequence)
	if not called then return false, tostring(reset) end
	if reset == false then return false, tostring(reset_error or "could not reset events") end
	return true
end

function Runtime:start_host(options)
	options = options or {}
	if self.role ~= "offline" then return false, "network runtime is already active" end
	local transport, transport_error = EnetTransport.create_server({
		host = options.host or "*",
		port = options.port or Protocol.DEFAULT_GAMEPLAY_PORT,
		last_port = options.last_port or (Protocol.DEFAULT_GAMEPLAY_PORT + 10),
		max_peers = 1,
		channels = 5,
		faults = options.faults,
	})
	if not transport then return false, transport_error end

	self.transport = transport
	self.role = "host"
	self:_set_client_state("offline")
	self.game_version = trimmed(options.game_version)
	self.content_hash = self:_content_hash(options.content_hash)
	self.world_id = options.world_id
	self.display_name = options.display_name or "Sarcophagus"
	self.advertisement_id = Identity.token("advertisement")
	self.last_error = nil
	self.state_accumulator = 0
	self.progress_accumulator = 0
	self.world_accumulator = 0
	self.action_retry_accumulator = 0
	self:_reset_outboxes()
	self:_reset_received_streams()
	self.host_hello_deadline = nil
	self.resume_phase = nil
	self.resume_deadline = nil
	self.last_peer_activity = nil
	self.next_heartbeat = nil
	self.session = Session.new({
		registry = self.registry,
		dropper = self.dropper,
		approval_timeout = options.approval_timeout,
		-- The host keeps grace slightly longer than the client's retry window so
		-- a final reconnect attempt cannot lose a race with session cleanup.
		reconnect_timeout = options.reconnect_timeout or (self.reconnect_timeout + 5),
		snapshot_timeout = options.snapshot_timeout,
		catchup_timeout = options.catchup_timeout,
	})
	if self.browser then self.browser:close(); self.browser = nil end
	if options.discovery ~= false then
		local responder, discovery_error = Discovery.create_responder(function()
			return self:advertisement()
		end, {
			port = options.discovery_port,
			group = options.discovery_group,
		})
		self.discovery = responder
		self.discovery_error = discovery_error
			or (responder and responder.multicast_error)
	end
	return true, transport.port
end

function Runtime:advertisement()
	assert(self.role == "host" and self.transport, "host is not active")
	return {
		protocol_version = tostring(Protocol.VERSION),
		game_version = self.game_version,
		content_hash = self.content_hash,
		session_id = self.advertisement_id,
		world_id = self.world_id,
		gameplay_port = self.transport.port,
		players = self.session and self.session.guest and 2 or 1,
		capacity = 2,
		joinable = self.session and self.session:is_joinable() and self.peer == nil or false,
		display_name = self.display_name,
	}
end

function Runtime:start_browsing(options)
	options = options or {}
	if self.role ~= "offline" then return false, "network runtime is active" end
	if self.browser then return true end
	self.game_version = trimmed(options.game_version or self.game_version)
	self.content_hash = self:_content_hash(options.content_hash)
	local browser, browser_error = Discovery.create_browser(options)
	if not browser then
		self.discovery_error = browser_error
		return false, browser_error
	end
	self.browser = browser
	self.next_discovery_refresh = 0
	self.discovery_error = nil
	return true
end

function Runtime:refresh_servers()
	if not self.browser then return false, "LAN browser is not active" end
	local refreshed, refresh_error = self.browser:refresh()
	self.discovery_error = refreshed and nil or refresh_error
	return refreshed, refresh_error
end

function Runtime:servers()
	return self.browser and self.browser:list() or {}
end

function Runtime:connect(options)
	options = options or {}
	if self.role ~= "offline" then return false, "network runtime is already active" end
	local transport, transport_error = EnetTransport.create_client({
		faults = options.faults,
	})
	if not transport then return false, transport_error end
	local peer, connect_error = transport:connect(
		options.host or "127.0.0.1",
		options.port or Protocol.DEFAULT_GAMEPLAY_PORT
	)
	if not peer then
		transport:close()
		return false, connect_error
	end
	self.transport = transport
	self.peer = peer
	self.role = "client"
	self:_set_client_state("connecting")
	self.game_version = trimmed(options.game_version)
	self.content_hash = self:_content_hash(options.content_hash)
	self.client_hello = Protocol.hello({
		game_version = self.game_version,
		content_hash = self.content_hash,
		capabilities = {
			"snapshot-v1",
			"input-v1",
			"actions-v1",
			"reliable-streams-v1",
		},
		client_nonce = Identity.token("client"),
	})
	self.client_welcome = nil
	self.pending_actions = {}
	self.pending_action_order = {}
	self.action_retry_accumulator = 0
	self:_reset_received_streams()
	self.assembler = nil
	self.early_snapshot_chunks = {}
	self.early_snapshot_bytes = 0
	self.snapshot_done_tick = nil
	self.snapshot_ready_tick = nil
	self.last_error = nil
	self.connection_host = options.host or "127.0.0.1"
	self.connection_port = options.port or Protocol.DEFAULT_GAMEPLAY_PORT
	self.reconnect_deadline = nil
	self.next_reconnect_attempt = nil
	self.last_peer_activity = nil
	self.next_heartbeat = nil
	if self.browser then self.browser:close(); self.browser = nil end
	return true
end

function Runtime:pending_approval()
	return self.role == "host" and self.approval_request or nil
end

function Runtime:reject_guest(reason)
	if not self.session then return false, "host session is not active" end
	local rejected, reject_error = self.session:reject(reason)
	if not rejected then return false, reject_error end
	local closed, close_error = self:_send_peer_and_close("reject", {
		reason = reason or "rejected_by_host",
	})
	self.approval_request = nil
	return closed, close_error
end

function Runtime:kick_guest(reason)
	if self.role ~= "host" or not self.session or not self.session.guest then
		return false, "no connected guest"
	end
	reason = reason or "kicked_by_host"
	local dropped, drop_error = self.session:disconnect(reason, true)
	if not dropped then return false, drop_error end
	return self:_send_peer_and_close("shutdown", { reason = reason })
end

function Runtime:approve_guest()
	if self.role ~= "host" or not self.session or not self.peer then
		return false, "no pending guest"
	end
	if type(self.state_provider) ~= "function" then
		return false, "snapshot state provider is not configured"
	end
	local spawn = type(self.spawn_provider) == "function" and self.spawn_provider() or {}
	local approved, welcome = self.session:approve(self.registry.host, spawn)
	if not approved then return false, welcome end

	local built, stored, meta, chunks = pcall(function()
		local state = self.state_provider(self.session)
		local snapshot = Snapshot.capture(state)
		local payload, description = Snapshot.serialize(snapshot)
		local packets, chunked = Snapshot.chunks(payload, description)
		return payload, chunked, packets
	end)
	if not built then
		self.last_error = tostring(stored)
		self.session:disconnect("snapshot_failed", true)
		self:_send_peer_and_close("reject", { reason = "snapshot_failed" })
		return false, self.last_error
	end
	if type(self.world_delta_reset) == "function" then
		local reset, reset_error = pcall(self.world_delta_reset, meta.tick)
		if not reset or reset_error == false then
			self.last_error = tostring(not reset and reset_error
				or "could not reset snapshot journal")
			self.session:disconnect("snapshot_journal_failed", true)
			self:_send_peer_and_close("reject", {
				reason = "snapshot_journal_failed",
			})
			return false, self.last_error
		end
	end
	local events_reset, event_reset_error = self:_reset_events(true)
	if not events_reset then
		self.last_error = event_reset_error
		self.session:disconnect("snapshot_event_reset_failed", true)
		self:_send_peer_and_close("reject", {
			reason = "snapshot_event_reset_failed",
		})
		return false, self.last_error
	end
	self:_reset_outboxes()

	local sent, send_error = self.transport:send(
		self.peer,
		"welcome",
		welcome,
		Protocol.CHANNEL.CONTROL,
		true
	)
	if sent then
		sent, send_error = self.transport:send(
			self.peer,
			"snapshot_meta",
			meta,
			Protocol.CHANNEL.CONTROL,
			true
		)
	end
	if sent then
		for _, packet in ipairs(chunks) do
			sent, send_error = self.transport:send_raw(
				self.peer,
				packet,
				Protocol.CHANNEL.SNAPSHOT,
				true
			)
			if not sent then break end
		end
	end
	if sent then
		sent, send_error = self.transport:send(
			self.peer,
			"snapshot_done",
			{ tick = meta.tick },
			Protocol.CHANNEL.CONTROL,
			true
		)
	end
	if not sent then
		self.last_error = tostring(send_error)
		self.session:disconnect("snapshot_send_failed", true)
		self:_send_peer_and_close("reject", { reason = "snapshot_send_failed" })
		return false, self.last_error
	end
	self.transport:flush()
	local snapshot_sent, snapshot_error = self.session:snapshot_sent(meta.tick)
	if not snapshot_sent then
		self.last_error = tostring(snapshot_error)
		self.session:disconnect("snapshot_state_failed", true)
		self:_send_peer_and_close("reject", { reason = "snapshot_state_failed" })
		return false, self.last_error
	end
	self.approval_request = nil
	return true
end

local host_messages_by_state = {
	[Session.STATE.LISTENING] = { hello = true, ping = true, pong = true },
	[Session.STATE.AWAITING_APPROVAL] = { disconnect = true, ping = true, pong = true },
	[Session.STATE.SENDING_SNAPSHOT] = { disconnect = true, ping = true, pong = true },
	[Session.STATE.CATCHING_UP] = {
		ready = true, disconnect = true, ping = true, pong = true,
	},
	[Session.STATE.PLAYING] = {
		input = true,
		action = true,
		disconnect = true,
		stream_ack = true,
		resume_ready = true,
		ping = true,
		pong = true,
	},
	[Session.STATE.RECONNECT_GRACE] = { hello = true, ping = true, pong = true },
}

function Runtime:_host_message(event, message)
	local allowed = self.session and host_messages_by_state[self.session.state]
	if not allowed or not allowed[message.kind] then
		return self:_fail_host_peer("unexpected guest message", event.peer)
	end
	if self.resume_phase and message.kind ~= "ping" and message.kind ~= "pong"
		and message.kind ~= "resume_ready" and message.kind ~= "disconnect" then
		return self:_fail_host_peer("guest message received during resume", event.peer)
	end
	if message.kind == "ping" or message.kind == "pong" then
		if not valid_ping(message.payload) then
			return self:_fail_host_peer("invalid heartbeat", event.peer)
		end
		if message.kind == "ping" then
			local sent, send_error = self.transport:send(
				event.peer,
				"pong",
				{ nonce = message.payload.nonce },
				Protocol.CHANNEL.CONTROL,
				true
			)
			if not sent then self.last_error = tostring(send_error) end
		end
		return
	end
	if message.kind == "hello" then
		self.host_hello_deadline = nil
		if self.session.state == Session.STATE.RECONNECT_GRACE
			and message.payload.reconnect_token then
			local compatible, compatibility_error = Protocol.validate_hello(
				message.payload,
				{ game_version = self.game_version, content_hash = self.content_hash }
			)
			local resumed, resume_error = false, compatibility_error
			local invalid_catchup = false
			if compatible then
				local catchup_ready, catchup_error = self:_catchup_status()
				if catchup_ready then
					resumed, resume_error = self.session:resume(
						message.payload.reconnect_token
					)
				else
					resume_error = catchup_error
					invalid_catchup = true
					self.last_error = catchup_error
				end
			end
			if resumed then
				self.peer = event.peer
				self.resume_phase = "waiting_ready"
				self.resume_deadline = clock() + self.connect_timeout
				local sent, send_error = self.transport:send(event.peer, "welcome", {
					resumed = true,
					session_id = self.session.session_id,
					reconnect_token = self.session.reconnect_token,
					actor_id = self.session.guest.actor_id,
				}, Protocol.CHANNEL.CONTROL, true)
				if not sent then
					self:_handle_transport_loss("resume_send_failed: "
						.. tostring(send_error), event.peer)
				end
			else
				if invalid_catchup then
					self.session:disconnect(resume_error, true)
				end
				self:_send_peer_and_close("reject", {
					reason = resume_error or "resume_failed",
				}, event.peer)
			end
			return
		end
		local accepted, response = self.session:begin_join(message.payload, {
			game_version = self.game_version,
			content_hash = self.content_hash,
		})
		if accepted then
			self.approval_request = response
			self.approval_request.hello = message.payload
		else
			if self.session.state == Session.STATE.AWAITING_APPROVAL then
				self.session:reject(response)
				self.approval_request = nil
			end
			self:_send_peer_and_close("reject", { reason = response }, event.peer)
		end
		return
	end
	if message.kind == "stream_ack" then
		local acknowledged, acknowledge_error = self:_acknowledge_streams(message.payload)
		if not acknowledged then
			return self:_fail_host_peer(acknowledge_error, event.peer)
		end
		return
	end
	if message.kind == "resume_ready" then
		if self.resume_phase ~= "waiting_ready" then
			return self:_fail_host_peer("unexpected resume synchronization", event.peer)
		end
		if not valid_stream_ack(message.payload)
			or message.payload.world_sequence < self.world_acked_sequence
			or message.payload.event_id < self.event_acked_id then
			return self:_fail_host_peer("client lost acknowledged stream state", event.peer)
		end
		local acknowledged, acknowledge_error = self:_acknowledge_streams(message.payload)
		if not acknowledged then
			return self:_fail_host_peer(acknowledge_error, event.peer)
		end
		self:_mark_outboxes_for_replay()
		self.resume_phase = "sending_sync"
		return
	end
	if message.kind == "ready" then
		local catchup_ready, catchup_error = self:_catchup_status()
		if not catchup_ready then
			self.last_error = catchup_error
			self.session:disconnect(catchup_error, true)
			self:_send_peer_and_close("reject", { reason = catchup_error }, event.peer)
			return
		end
		local ready, ready_error = self.session:ready(message.payload.tick)
		if not ready then
			self.last_error = ready_error
			self.session:disconnect(ready_error, true)
			self:_send_peer_and_close("reject", { reason = ready_error }, event.peer)
		else
			local sent, send_error = self.transport:send(event.peer, "start", {
				session_id = self.session.session_id,
				tick = self.session.last_server_tick,
			}, Protocol.CHANNEL.CONTROL, true)
			if not sent then
				self.last_error = tostring(send_error)
				self.session:disconnect("start_send_failed", true)
				self:_send_peer_and_close("reject", {
					reason = "start_send_failed",
				}, event.peer)
			else
				self.transport:flush()
			end
		end
		return
	end
	if message.kind == "input" then
		local accepted, input_error = self.session:accept_input(message.payload)
		if accepted and type(self.input_handler) == "function" then
			self.input_handler(self.session.guest,
				self.registry:runtime(self.session.guest).input)
		elseif not accepted then
			self.last_error = input_error
		end
		return
	end
	if message.kind == "action" then
		local action_id = message.payload.action_id
		local accepted, action_error, cached_result = self.session:accept_action(action_id)
		local result = cached_result or { action_id = action_id, ok = accepted }
		if cached_result then
			-- A reconnect retry receives the original result without executing
			-- the authoritative transaction a second time.
		elseif accepted and type(self.action_handler) == "function" then
			local handled, value, handler_error = pcall(
				self.action_handler,
				self.session.guest,
				message.payload
			)
			result.ok = handled and value ~= false
			if not handled then
				result.error = sanitized_reason(value, "action handler failed")
			elseif value == false then
				result.error = sanitized_reason(handler_error, "action rejected")
			end
		elseif not accepted then
			result.error = sanitized_reason(action_error, "action rejected")
			if type(self.action_rejection_handler) == "function" then
				local rolled_back, rollback_error = pcall(
					self.action_rejection_handler,
					self.session.guest,
					message.payload,
					action_error
				)
				if not rolled_back then self.last_error = tostring(rollback_error) end
			end
		end
		if accepted then self.session:record_action_result(action_id, result) end
		local sent, send_error = self.transport:send(
			event.peer,
			"action_result",
			result,
			Protocol.CHANNEL.WORLD,
			true
		)
		if not sent then self.last_error = tostring(send_error) end
		return
	end
	if message.kind == "disconnect" then
		if not valid_reason(message.payload.reason) then
			return self:_fail_host_peer("invalid disconnect reason", event.peer)
		end
		self.session:disconnect(message.payload.reason, true)
		self.approval_request = nil
		self.resume_phase = nil
		self.resume_deadline = nil
		self:_send_peer_and_close()
	end
end

function Runtime:_forget_pending_action(action_id)
	local key = action_key(action_id)
	if not self.pending_actions[key] then return false end
	self.pending_actions[key] = nil
	for index, pending_key in ipairs(self.pending_action_order) do
		if pending_key == key then
			table.remove(self.pending_action_order, index)
			break
		end
	end
	return true
end

function Runtime:_resend_pending_actions()
	for _, key in ipairs(self.pending_action_order) do
		local action = self.pending_actions[key]
		if action then
			local sent, send_error = self.transport:send(
				nil,
				"action",
				action,
				Protocol.CHANNEL.WORLD,
				true
			)
			if not sent then return false, send_error end
		end
	end
	self.transport:flush()
	return true
end

function Runtime:_client_message(message)
	if message.kind == "ping" or message.kind == "pong" then
		if not valid_ping(message.payload) then
			return self:_fail_client("invalid heartbeat")
		end
		if message.kind == "ping" then
			local sent, send_error = self.transport:send(
				self.peer,
				"pong",
				{ nonce = message.payload.nonce },
				Protocol.CHANNEL.CONTROL,
				true
			)
			if not sent then self.last_error = tostring(send_error) end
		end
		return
	end
	if message.kind == "reject" then
		if not valid_reason(message.payload.reason) then
			return self:_fail_client("invalid rejection reason")
		end
		self.last_error = message.payload.reason or "connection rejected"
		self:_set_client_state("rejected")
		self:_send_peer_and_close()
		return
	end
	if message.kind == "welcome" then
		local resumed = message.payload.resumed == true
		if not valid_welcome(message.payload)
			or (resumed and self.client_state ~= "resuming")
			or (not resumed and self.client_state ~= "awaiting_approval") then
			return self:_fail_client("invalid welcome message")
		end
		self.client_welcome = message.payload
		if resumed then
			self.snapshot_ready_tick = nil
			self:_set_client_state("resuming_sync")
			local sent, send_error = self.transport:send(
				self.peer,
				"resume_ready",
				{
					world_sequence = self.received_world_sequence,
					event_id = self.received_event_id,
				},
				Protocol.CHANNEL.CONTROL,
				true
			)
			if not sent then
				return self:_handle_transport_loss(send_error, self.peer)
			end
			self.transport:flush()
		else
			self:_set_client_state("receiving_snapshot")
		end
		return
	end
	if message.kind == "resume_synced" then
		if self.client_state ~= "resuming_sync" or not self.client_welcome
			or message.payload.session_id ~= self.client_welcome.session_id then
			return self:_fail_client("invalid resume synchronization")
		end
		self:_set_client_state("playing")
		self.reconnect_deadline = nil
		self.next_reconnect_attempt = nil
		self.last_error = nil
		local resent, resend_error = self:_resend_pending_actions()
		if not resent then self.last_error = tostring(resend_error) end
		return
	end
	if message.kind == "snapshot_meta" then
		if self.client_state ~= "receiving_snapshot" or not self.client_welcome
			or message.payload.session_id ~= self.client_welcome.session_id then
			return self:_fail_client("unexpected snapshot metadata")
		end
		local assembler, assembler_error = Snapshot.new_assembler(message.payload)
		if not assembler then
			return self:_fail_client(assembler_error)
		else
			self.assembler = assembler
			for _, packet in ipairs(self.early_snapshot_chunks) do
				local accepted, chunk_error = self.assembler:add(packet)
				if not accepted then
					self.early_snapshot_chunks = {}
					self.early_snapshot_bytes = 0
					return self:_fail_client(chunk_error)
				end
			end
			self.early_snapshot_chunks = {}
			self.early_snapshot_bytes = 0
			if self.snapshot_done_tick and self.assembler:complete() then
				self:_finish_client_snapshot()
			end
		end
		return
	end
	if message.kind == "snapshot_done" then
		local tick = message.payload.tick
		if self.client_state ~= "receiving_snapshot" or not self.assembler
			or not Protocol.validate_nonnegative_integer(tick, 9007199254740991)
			or tick ~= self.assembler.meta.tick then
			return self:_fail_client("invalid snapshot completion")
		end
		self.snapshot_done_tick = tick
		if self.assembler and self.assembler:complete() then
			self:_finish_client_snapshot()
		end
		return
	end
	if message.kind == "start" then
		if self.client_state ~= "catching_up" or not self.client_welcome
			or message.payload.session_id ~= self.client_welcome.session_id
			or not Protocol.validate_nonnegative_integer(
				message.payload.tick, 9007199254740991
			)
			or message.payload.tick ~= self.snapshot_ready_tick then
			return self:_fail_client("invalid start confirmation")
		end
		self.snapshot_ready_tick = nil
		self:_set_client_state("playing")
		self.last_error = nil
		return
	end
	if message.kind == "shutdown" then
		if not valid_reason(message.payload.reason) then
			return self:_fail_client("invalid shutdown reason")
		end
		self.last_error = message.payload.reason or "host shutdown"
		self:_set_client_state("disconnected")
		self:_send_peer_and_close()
		return
	end
	if message.kind == "action_result" then
		if self.client_state ~= "playing" or not valid_action_result(message.payload) then
			return self:_fail_client("invalid action result")
		end
		self:_forget_pending_action(message.payload.action_id)
		if type(self.action_result_handler) == "function" then
			local called, handler_error = pcall(
				self.action_result_handler,
				message.payload
			)
			if not called then return self:_fail_client(handler_error) end
		end
		return
	end
	if message.kind == "event" then
		if self.client_state ~= "playing" and self.client_state ~= "catching_up" then
			return self:_fail_client("event received before playing")
		end
		local event_id = message.payload and message.payload.event_id
		if not valid_stream_position(event_id) or event_id < 1 then
			return self:_fail_client("invalid network event sequence")
		end
		if event_id <= self.received_event_id then
			self:_send_stream_ack()
			return
		end
		if event_id ~= self.received_event_id + 1 then
			return self:_handle_transport_loss("network event sequence gap", self.peer)
		end
		if type(self.event_handler) ~= "function" then
			return self:_fail_client("network event handler is not configured")
		end
		local called, accepted, event_error = pcall(self.event_handler, message.payload)
		if not called or accepted == false then
			return self:_fail_client(not called and accepted
				or event_error or "network event was rejected")
		end
		self.received_event_id = event_id
		self:_send_stream_ack()
		return
	end
	return self:_fail_client("unexpected host message")
end

function Runtime:_finish_client_snapshot()
	if not self.assembler or not self.assembler:complete() then return false end
	if self.client_state ~= "receiving_snapshot" or not self.client_welcome
		or self.snapshot_done_tick ~= self.assembler.meta.tick then
		return self:_fail_client("snapshot completed in an invalid state")
	end
	local snapshot, snapshot_error = self.assembler:finish()
	if not snapshot then
		self.last_error = snapshot_error
		self:_set_client_state("failed")
		self:_send_peer_and_close("disconnect", { reason = snapshot_error })
		return false
	end
	if snapshot.header.session_id ~= self.client_welcome.session_id then
		return self:_fail_client("snapshot session mismatch")
	end
	if type(self.state_applier) ~= "function" then
		self.last_error = "snapshot state applier is not configured"
		self:_set_client_state("failed")
		self:_send_peer_and_close("disconnect", { reason = self.last_error })
		return false
	end
	local called, accepted, apply_error = pcall(self.state_applier, snapshot)
	if not called or accepted == false then
		return self:_fail_client(not called and accepted
			or apply_error or "snapshot state was rejected")
	end
	self:_reset_received_streams()
	self.world_id = snapshot.header.world_id
	self.snapshot_ready_tick = snapshot.header.tick
	self:_set_client_state("catching_up")
	local sent, send_error = self.transport:send(
		nil,
		"ready",
		{ tick = snapshot.header.tick },
		Protocol.CHANNEL.CONTROL,
		true
	)
	if not sent then return self:_fail_client(send_error) end
	self.transport:flush()
	self.assembler = nil
	self.snapshot_done_tick = nil
	return true
end

function Runtime:_fail_host_peer(reason, peer)
	reason = tostring(reason or "invalid protocol message")
	self.last_error = reason
	if self.session and self.session.state ~= Session.STATE.RECONNECT_GRACE then
		self.session:disconnect(reason, true)
	end
	self.approval_request = nil
	self.host_hello_deadline = nil
	self.resume_phase = nil
	self.resume_deadline = nil
	self:_send_peer_and_close("reject", {
		reason = "invalid_protocol_message",
	}, peer)
	return false, reason
end

function Runtime:_receive(event)
	local channel = event.channelID or event.channel
	if self.role == "client" and channel == Protocol.CHANNEL.SNAPSHOT then
		if self.client_state ~= "awaiting_approval"
			and self.client_state ~= "receiving_snapshot" then
			return self:_fail_client("unexpected snapshot chunk")
		end
		local chunk_index, chunk_error = Snapshot.decode_chunk(event.data)
		if not chunk_index then return self:_fail_client(chunk_error) end
		if not self.assembler then
			local next_bytes = self.early_snapshot_bytes + #event.data
			if #self.early_snapshot_chunks >= 2048
				or next_bytes > Snapshot.MAX_STORED_BYTES + 2048 * 6 then
				return self:_fail_client("too many early snapshot chunks")
			end
			self.early_snapshot_chunks[#self.early_snapshot_chunks + 1] = event.data
			self.early_snapshot_bytes = next_bytes
			return
		end
		local accepted, assembler_error = self.assembler:add(event.data)
		if not accepted then return self:_fail_client(assembler_error) end
		if self.snapshot_done_tick and self.assembler:complete() then
			self:_finish_client_snapshot()
		end
		return
	end

	local packet_kind = Replication.packet_kind(event.data)
	if self.role == "client" and packet_kind then
		if self.client_state == "resuming_sync" and packet_kind == "state" then
			-- State snapshots are transient. A packet queued on the old connection
			-- is allowed to expire while the reliable world stream is synchronized.
			return
		end
		if self.client_state ~= "playing" and self.client_state ~= "catching_up" then
			return self:_fail_client("replication received before playing")
		end
		local expected_channel = packet_kind == "state"
			and Protocol.CHANNEL.STATE or Protocol.CHANNEL.WORLD
		if channel ~= expected_channel then
			return self:_fail_client("replication received on invalid channel")
		end
		local payload, decode_error = Replication.decode(event.data)
		if not payload then return self:_fail_client(decode_error) end
		if packet_kind == "world" then
			if not valid_stream_position(payload.sequence) or payload.sequence < 1 then
				return self:_fail_client("invalid world stream sequence")
			end
			if payload.sequence <= self.received_world_sequence then
				self:_send_stream_ack()
				return
			end
			if payload.sequence ~= self.received_world_sequence + 1 then
				return self:_handle_transport_loss("world stream sequence gap", self.peer)
			end
		end
		local applier = packet_kind == "state" and self.replication_applier
			or self.world_delta_applier
		if type(applier) ~= "function" then
			return self:_fail_client("replication applier is not configured")
		end
		local called, accepted, apply_error = pcall(applier, payload)
		if not called or accepted == false then
			return self:_fail_client(not called and accepted
				or apply_error or "replicated state was rejected")
		end
		if packet_kind == "world" and valid_stream_position(payload.sequence) then
			self.received_world_sequence = payload.sequence
			self:_send_stream_ack()
		end
		return
	end

	local message, decode_error = Protocol.decode(event.data)
	if not message then
		if self.role == "host" then
			return self:_fail_host_peer(decode_error, event.peer)
		end
		return self:_fail_client(decode_error)
	end
	if not valid_message_channel(self.role, message.kind, channel) then
		if self.role == "host" then
			return self:_fail_host_peer("message received on invalid channel", event.peer)
		end
		return self:_fail_client("message received on invalid channel")
	end
	if self.role == "host" then
		self:_host_message(event, message)
	else
		self:_client_message(message)
	end
end

function Runtime:_publish(dt)
	if self.role ~= "host" or not self.peer or not self.session
		or self.session.state ~= Session.STATE.PLAYING
		or self.resume_phase ~= nil then return end
	local catchup_ready, catchup_error = self:_catchup_status()
	if not catchup_ready then
		self.last_error = catchup_error
		self.session:disconnect(catchup_error, true)
		self:_send_peer_and_close("shutdown", { reason = catchup_error })
		return
	end
	dt = math.max(0, tonumber(dt) or 0)
	self.state_accumulator = self.state_accumulator + dt
	self.progress_accumulator = self.progress_accumulator + dt
	self.world_accumulator = self.world_accumulator + dt

	if self.state_accumulator >= self.state_interval
		and type(self.replication_provider) == "function" then
		self.state_accumulator = self.state_accumulator % self.state_interval
		local include_progress = self.progress_accumulator >= self.progress_interval
		local built, packet = pcall(function()
			return Replication.encode_state(self.replication_provider(
				self.session,
				include_progress
			))
		end)
		if built then
			local sent, send_error = self.transport:send_raw(
				self.peer, packet, Protocol.CHANNEL.STATE, false
			)
			if sent and include_progress then
				self.progress_accumulator = self.progress_accumulator
					% self.progress_interval
			elseif not sent then
				self.last_error = tostring(send_error)
			end
		else
			self.last_error = tostring(packet)
		end
	end

	if self.world_accumulator >= self.world_interval
		and (#self.world_outbox > 0
			or type(self.world_delta_provider) == "function") then
		self.world_accumulator = self.world_accumulator % self.world_interval
		local sent, send_error, sent_count = self:_send_world_outbox(4)
		if not sent then
			self.last_error = tostring(send_error)
			return
		end
		for _ = sent_count + 1, 4 do
			if type(self.world_delta_provider) ~= "function" then break end
			if #self.world_outbox >= self.max_world_outbox then
				self.last_error = "world acknowledgement backlog overflow"
				break
			end
			local provided, delta = pcall(self.world_delta_provider, self.session)
			if not provided then
				self.last_error = tostring(delta)
				break
			end
			if not delta then break end
			local queued, queue_error = self:_queue_world_delta(delta)
			if not queued then
				self.last_error = tostring(queue_error)
				break
			end
			sent, send_error = self:_send_world_outbox(1)
			if not sent then
				self.last_error = tostring(send_error)
				break
			end
		end
	end

	if #self.event_outbox > 0 or type(self.event_provider) == "function" then
		local sent, send_error, sent_count = self:_send_event_outbox(32)
		if not sent then
			self.last_error = tostring(send_error)
			return
		end
		for _ = sent_count + 1, 32 do
			if type(self.event_provider) ~= "function" then break end
			if #self.event_outbox >= self.max_event_outbox then
				self.last_error = "event acknowledgement backlog overflow"
				break
			end
			local provided, event = pcall(self.event_provider, self.session)
			if not provided then
				self.last_error = tostring(event)
				break
			end
			if event == nil then break end
			if type(event) ~= "table" then
				self.last_error = "invalid network event"
				break
			end
			local queued, queue_error = self:_queue_event(event)
			if not queued then
				self.last_error = tostring(queue_error)
				break
			end
			sent, send_error = self:_send_event_outbox(1)
			if not sent then
				self.last_error = tostring(send_error)
				break
			end
		end
	end
end

function Runtime:_update_reconnect()
	if self.role ~= "client"
		or (self.client_state ~= "reconnecting"
			and self.client_state ~= "resuming"
			and self.client_state ~= "resuming_sync") then
		return
	end
	local current = clock()
	if current >= (self.reconnect_deadline or 0) then
		self:_set_client_state("disconnected")
		self.last_error = self.last_error or "reconnect_timeout"
		self:_close_lost_peer(self.peer)
		return
	end
	if self.client_state == "reconnecting" and not self.peer
		and current >= (self.next_reconnect_attempt or 0) then
		local peer, connect_error = self.transport:connect(
			self.connection_host,
			self.connection_port
		)
		if peer then
			self.peer = peer
			self.next_reconnect_attempt = current + 0.75
		else
			self.last_error = tostring(connect_error)
			self.next_reconnect_attempt = current + 0.75
		end
	end
end

function Runtime:_update_client_timeout()
	if self.role ~= "client" or not self.client_deadline
		or clock() < self.client_deadline then return end
	local reason = self.client_state == "connecting" and "connection_timeout"
		or self.client_state == "awaiting_approval" and "approval_timeout"
		or self.client_state == "receiving_snapshot" and "snapshot_timeout"
		or self.client_state == "catching_up" and "catchup_timeout"
		or "network_timeout"
	self.last_error = reason
	self:_set_client_state("failed")
	if self.peer then
		self:_send_peer_and_close("disconnect", { reason = reason })
	else
		self:_send_peer_and_close()
	end
end

function Runtime:update(dt)
	if self.discovery then self.discovery:update() end
	if self.browser then
		local current = love and love.timer and love.timer.getTime() or os.clock()
		if current >= self.next_discovery_refresh then
			self:refresh_servers()
			self.next_discovery_refresh = current + 1
		end
		self.browser:update()
	end
	if not self.transport then return end
	for _ = 1, 128 do
		local event, poll_error = self.transport:poll(0)
		if poll_error then
			self.last_error = poll_error
			break
		end
		if not event then break end
		self.last_event = event.type
		if event.type == "connect" then
			if self.peer and event.peer ~= self.peer then
				if self.transport.disconnect_peer then
					self.transport:disconnect_peer(event.peer, 1, true)
				end
			else
				self.peer = event.peer
				self.last_peer_activity = clock()
				self.next_heartbeat = clock() + self.heartbeat_interval
			end
			if self.peer == event.peer and self.role == "client" then
				local reconnecting = self.client_state == "reconnecting"
					or self.client_state == "resuming"
					or self.client_state == "resuming_sync"
				self:_set_client_state(reconnecting and "resuming" or "awaiting_approval")
				if reconnecting and self.client_welcome then
					self.client_hello.reconnect_token = self.client_welcome.reconnect_token
				end
				local sent, send_error = self.transport:send(event.peer, "hello", self.client_hello,
					Protocol.CHANNEL.CONTROL, true)
				if sent then
					self.transport:flush()
				else
					self:_handle_transport_loss(send_error, event.peer)
				end
			elseif self.peer == event.peer then
				self.host_hello_deadline = clock() + self.hello_timeout
			end
		elseif event.type == "receive" then
			if self.peer and (not event.peer or event.peer == self.peer) then
				self.last_peer_activity = clock()
				self:_receive(event)
			elseif self.transport.disconnect_peer then
				self.transport:disconnect_peer(event.peer, 1, true)
			end
		elseif event.type == "disconnect" then
			local current_peer = not event.peer or event.peer == self.peer
			if current_peer and self.role == "host" and self.session then
				self:_neutralize_guest_input()
				self.session:disconnect("transport_disconnect", false)
				self.approval_request = nil
				self.resume_phase = nil
				self.resume_deadline = nil
				self:_mark_outboxes_for_replay()
			elseif current_peer then
				local terminal = self.client_state == "rejected"
					or self.client_state == "failed"
					or self.client_state == "disconnected"
				if terminal then
					-- Preserve the more useful terminal state and its reason.
				elseif tonumber(event.data) == 1 then
					self.last_error = self.last_error or "host_closed_connection"
					self:_set_client_state("disconnected")
				elseif (self.client_state == "playing"
					or self.client_state == "catching_up"
					or self.client_state == "resuming"
					or self.client_state == "resuming_sync")
					and self.client_welcome
					and self.client_welcome.reconnect_token then
					self:_set_client_state("reconnecting")
					self.reconnect_deadline = clock() + self.reconnect_timeout
					self.next_reconnect_attempt = clock() + 0.1
				else
					self:_set_client_state("disconnected")
				end
			end
			if current_peer then
				self.peer = nil
				self.last_peer_activity = nil
				self.next_heartbeat = nil
				self.host_hello_deadline = nil
			end
		end
	end
	self:_update_heartbeat()
	if self.role == "host" and self.session then
		local current = clock()
		if self.peer and self.host_hello_deadline
			and current >= self.host_hello_deadline then
			self:_fail_host_peer("hello_timeout", self.peer)
		end
		if self.peer and self.resume_phase and self.resume_deadline
			and current >= self.resume_deadline then
			self:_handle_transport_loss("resume_sync_timeout", self.peer)
		elseif self.resume_phase == "sending_sync" then
			self:_complete_resume_sync()
		end
		local previous_state = self.session.state
		local updated, update_error = self.session:update()
		if not updated then self.last_error = tostring(update_error) end
		local handshake_timed_out = (
			previous_state == Session.STATE.AWAITING_APPROVAL
				and self.session.state == Session.STATE.LISTENING
		) or (
			(previous_state == Session.STATE.SENDING_SNAPSHOT
				or previous_state == Session.STATE.CATCHING_UP)
				and (self.session.state == Session.STATE.DROPPING
					or self.session.state == Session.STATE.LISTENING)
		)
		if handshake_timed_out then
			local reason = update_error or self.session.last_disconnect_reason
				or "approval_timeout"
			self.last_error = tostring(reason)
			self:_send_peer_and_close("reject", { reason = reason })
			self.approval_request = nil
		end
		if self.session.state == Session.STATE.PLAYING and self.resume_phase == nil
			and self.session.guest and type(self.simulation_handler) == "function" then
			local simulated, simulation_error = pcall(
				self.simulation_handler,
				self.session.guest,
				self.registry:runtime(self.session.guest).input,
				dt
			)
			if not simulated then self.last_error = tostring(simulation_error) end
		end
		self:_publish(dt)
	end
	self:_update_client_timeout()
	self:_update_reconnect()
	if self.role == "client" and self.client_state == "playing"
		and #self.pending_action_order > 0 then
		self.action_retry_accumulator = self.action_retry_accumulator
			+ math.max(0, tonumber(dt) or 0)
		if self.action_retry_accumulator >= self.action_retry_interval then
			self.action_retry_accumulator = self.action_retry_accumulator
				% self.action_retry_interval
			local resent, resend_error = self:_resend_pending_actions()
			if not resent then self.last_error = tostring(resend_error) end
		end
	end
end

function Runtime:send_input(input_state)
	if self.role ~= "client" or self.client_state ~= "playing" then
		return false, "client is not playing"
	end
	return self.transport:send(nil, "input", InputState.snapshot(input_state),
		Protocol.CHANNEL.INPUT, false)
end

function Runtime:submit_input(input_state, dt)
	if self.role ~= "client" or self.client_state ~= "playing" then
		return false, "client is not playing"
	end
	self.input_accumulator = self.input_accumulator + math.max(0, tonumber(dt) or 0)
	if self.input_accumulator < self.input_interval then return true, "deferred" end
	self.input_accumulator = self.input_accumulator % self.input_interval
	return self:send_input(input_state)
end

function Runtime:send_action(action)
	if self.role ~= "client" or self.client_state ~= "playing" then
		return false, "client is not playing"
	end
	if type(action) ~= "table" or not Protocol.validate_action_id(action.action_id) then
		return false, "invalid action"
	end
	local key = action_key(action.action_id)
	if self.pending_actions[key] then return false, "action is already pending" end
	if #self.pending_action_order >= self.max_pending_actions then
		return false, "too many pending actions"
	end
	local copy = Replication.copy_serializable(action)
	self.pending_actions[key] = copy
	self.pending_action_order[#self.pending_action_order + 1] = key
	local sent, send_error = self.transport:send(
		nil,
		"action",
		copy,
		Protocol.CHANNEL.WORLD,
		true
	)
	if not sent then
		-- The action is now an application-level reliable transaction. Keep it
		-- queued and retry until action_result arrives, including after reconnect.
		self.last_error = tostring(send_error)
		return true, "queued"
	end
	return true
end

function Runtime:prepare_quit()
	if self.role == "offline" then
		if self.browser then self.browser:close(); self.browser = nil end
		return true
	end
	if self.role == "host" then
		if self.session then
			local stopped, stop_error = self.session:shutdown()
			if not stopped then return false, stop_error end
		end
		if self.peer then
			self.transport:send(self.peer, "shutdown", { reason = "host_quit" },
				Protocol.CHANNEL.CONTROL, true)
			self.transport:flush()
		end
	elseif self.peer then
		self.transport:send(self.peer, "disconnect", { reason = "client_quit" },
			Protocol.CHANNEL.CONTROL, true)
		self.transport:flush()
	end
	if self.transport then self.transport:close() end
	if self.discovery then self.discovery:close(); self.discovery = nil end
	if self.browser then self.browser:close(); self.browser = nil end
	self.transport = nil
	self.peer = nil
	self.role = "offline"
	self:_set_client_state("offline")
	self.connection_host = nil
	self.connection_port = nil
	self.client_hello = nil
	self.client_welcome = nil
	self.pending_actions = {}
	self.pending_action_order = {}
	self.action_retry_accumulator = 0
	self:_reset_outboxes()
	self:_reset_received_streams()
	self.assembler = nil
	self.early_snapshot_chunks = {}
	self.early_snapshot_bytes = 0
	self.snapshot_done_tick = nil
	self.snapshot_ready_tick = nil
	self.reconnect_deadline = nil
	self.next_reconnect_attempt = nil
	self.last_peer_activity = nil
	self.next_heartbeat = nil
	self.host_hello_deadline = nil
	self.resume_phase = nil
	self.resume_deadline = nil
	return true
end

local function network_quality(stats)
	if type(stats) ~= "table" then return "unknown" end
	local rtt = tonumber(stats.rtt_ms)
	local loss = tonumber(stats.packet_loss_percent)
	if not rtt and not loss then return "unknown" end
	rtt = math.max(0, rtt or 0)
	loss = math.max(0, loss or 0)
	if rtt <= 80 and loss < 1 then return "excellent" end
	if rtt <= 160 and loss < 3 then return "good" end
	if rtt <= 300 and loss < 8 then return "poor" end
	return "bad"
end

function Runtime:status()
	local transport_stats = self.transport and self.transport.stats
		and self.transport:stats() or nil
	return {
		role = self.role,
		client_state = self.client_state,
		port = self.transport and self.transport.port or nil,
		session_state = self.session and self.session.state or nil,
		world_id = self.world_id,
		last_error = self.last_error,
		discovery_error = self.discovery_error,
		transport = transport_stats,
		quality = network_quality(transport_stats),
	}
end

return Runtime

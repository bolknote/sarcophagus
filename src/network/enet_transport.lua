local Protocol = require("src.network.protocol")

local EnetTransport = {}
EnetTransport.__index = EnetTransport

local enet_ok, enet = pcall(require, "enet")

local function clock()
	if love and love.timer then return love.timer.getTime() end
	return os.clock()
end

local function endpoint(host, port)
	host = host or "127.0.0.1"
	port = tonumber(port)
	assert(port and port >= 1 and port <= 65535 and port == math.floor(port),
		"invalid ENet port")
	if host:find(":", 1, true) and host:sub(1, 1) ~= "[" then
		host = "[" .. host .. "]"
	end
	return host .. ":" .. tostring(port)
end

local function bounded_number(value, fallback, minimum, maximum)
	value = tonumber(value)
	if not value or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return math.max(minimum, math.min(maximum, value))
end

local function fault_options(options)
	local supplied = options and options.faults
	if supplied == false then supplied = {} end
	local from_environment = supplied == nil
	supplied = type(supplied) == "table" and supplied or {}
	local function value(field, environment)
		if supplied[field] ~= nil then return supplied[field] end
		return from_environment and os.getenv(environment) or nil
	end
	return {
		latency_ms = bounded_number(value("latency_ms", "SARCOPHAGUS_NET_LATENCY_MS"), 0, 0, 60000),
		jitter_ms = bounded_number(value("jitter_ms", "SARCOPHAGUS_NET_JITTER_MS"), 0, 0, 60000),
		loss_percent = bounded_number(value("loss_percent", "SARCOPHAGUS_NET_LOSS_PERCENT"), 0, 0, 100),
		duplication_percent = bounded_number(value("duplication_percent", "SARCOPHAGUS_NET_DUPLICATION_PERCENT"), 0, 0, 100),
		disconnect_after = bounded_number(value("disconnect_after", "SARCOPHAGUS_NET_DISCONNECT_AFTER"), 0, 0, 86400),
		random = type(supplied.random) == "function" and supplied.random or nil,
	}
end

local function wrap(host, role, port, options)
	return setmetatable({
		host = host,
		role = role,
		port = port,
		peer = nil,
		closed = false,
		started_at = clock(),
		bytes_sent = 0,
		bytes_received = 0,
		packets_sent = 0,
		packets_received = 0,
		channel_sent = {},
		channel_received = {},
		faults = fault_options(options),
		fault_attempted = 0,
		fault_dropped = 0,
		fault_duplicated = 0,
		fault_disconnects = 0,
		fault_disconnect_triggered = false,
		connected_at = nil,
		outgoing_sequence = 0,
		outgoing_queue = {},
		outgoing_bytes = 0,
		last_due_by_channel = {},
		last_fault_error = nil,
		synthetic_events = {},
		ignored_disconnect_peers = {},
	}, EnetTransport)
end

local function record_channel(channels, channel, bytes)
	channel = math.floor(tonumber(channel) or Protocol.CHANNEL.CONTROL)
	local entry = channels[channel] or { packets = 0, bytes = 0 }
	entry.packets = entry.packets + 1
	entry.bytes = entry.bytes + bytes
	channels[channel] = entry
end

local function peer_metric(peer, name)
	if not peer then return nil end
	local read, member = pcall(function() return peer[name] end)
	if not read then return nil end
	if type(member) == "function" then
		local called, value = pcall(member, peer)
		if called and type(value) == "number" and value == value then return value end
	elseif type(member) == "number" and member == member then
		return member
	end
	return nil
end

local function random_unit(profile)
	local generated, value
	if profile.random then
		generated, value = pcall(profile.random)
	elseif love and love.math and love.math.random then
		generated, value = pcall(love.math.random)
	else
		generated, value = pcall(math.random)
	end
	if not generated or type(value) ~= "number" or value ~= value then return 0.5 end
	return math.max(0, math.min(1, value))
end

function EnetTransport.available()
	return enet_ok, enet_ok and nil or tostring(enet)
end

function EnetTransport.create_server(options)
	if not enet_ok then return nil, tostring(enet) end
	options = options or {}
	local first_port = tonumber(options.port) or Protocol.DEFAULT_GAMEPLAY_PORT
	local last_port = tonumber(options.last_port) or first_port
	local bind_host = options.host or "*"
	local last_error
	for port = first_port, last_port do
		local created, host_or_error = pcall(
			enet.host_create,
			endpoint(bind_host, port),
			options.max_peers or 1,
			options.channels or 5,
			options.incoming_bandwidth or 0,
			options.outgoing_bandwidth or 0
		)
		if created and host_or_error then
			return wrap(host_or_error, "server", port, options)
		end
		last_error = created and "could not bind ENet server" or host_or_error
	end
	return nil, tostring(last_error or "no gameplay port available")
end

function EnetTransport.create_client(options)
	if not enet_ok then return nil, tostring(enet) end
	options = options or {}
	local created, host_or_error = pcall(
		enet.host_create,
		nil,
		options.max_peers or 1,
		options.channels or 5,
		options.incoming_bandwidth or 0,
		options.outgoing_bandwidth or 0
	)
	if not created or not host_or_error then
		return nil, tostring(host_or_error or "could not create ENet client")
	end
	return wrap(host_or_error, "client", nil, options)
end

function EnetTransport:connect(host, port, data)
	if self.closed then return nil, "transport is closed" end
	if self.role ~= "client" then return nil, "only a client can connect" end
	local connected, peer_or_error = pcall(
		self.host.connect,
		self.host,
		endpoint(host, port),
		5,
		tonumber(data) or 0
	)
	if not connected or not peer_or_error then
		return nil, tostring(peer_or_error or "could not start ENet connection")
	end
	self.peer = peer_or_error
	return peer_or_error
end

function EnetTransport:_actual_send(peer, data, channel, reliable)
	local sent, send_error = pcall(
		peer.send,
		peer,
		data,
		channel,
		reliable == false and "unreliable" or "reliable"
	)
	if not sent then return false, tostring(send_error) end
	self.packets_sent = self.packets_sent + 1
	self.bytes_sent = self.bytes_sent + #data
	record_channel(self.channel_sent, channel, #data)
	return true
end

function EnetTransport:_drain_outgoing(force)
	if #self.outgoing_queue == 0 then return true end
	local current = clock()
	local remaining = {}
	local remaining_bytes = 0
	local first_error
	local blocked_channels = {}
	for _, packet in ipairs(self.outgoing_queue) do
		if blocked_channels[packet.channel] then
			remaining[#remaining + 1] = packet
			remaining_bytes = remaining_bytes + #packet.data
		elseif force or packet.due <= current then
			local sent, send_error = self:_actual_send(
				packet.peer,
				packet.data,
				packet.channel,
				packet.reliable
			)
			if not sent then
				-- A delayed reliable packet is still owned by the transport until
				-- peer.send succeeds. Dropping it here used to create silent gaps in
				-- the world stream whenever a transient send error occurred.
				remaining[#remaining + 1] = packet
				remaining_bytes = remaining_bytes + #packet.data
				blocked_channels[packet.channel] = true
				if not first_error then first_error = send_error end
			end
		else
			remaining[#remaining + 1] = packet
			remaining_bytes = remaining_bytes + #packet.data
		end
	end
	self.outgoing_queue = remaining
	self.outgoing_bytes = remaining_bytes
	self.last_fault_error = first_error or self.last_fault_error
	return first_error == nil, first_error
end

function EnetTransport:_fault_disconnect()
	local profile = self.faults
	if self.fault_disconnect_triggered or not self.peer or not self.connected_at
		or profile.disconnect_after <= 0
		or clock() - self.connected_at < profile.disconnect_after then
		return false
	end
	self.fault_disconnect_triggered = true
	self.fault_disconnects = self.fault_disconnects + 1
	self.outgoing_queue = {}
	self.outgoing_bytes = 0
	local disconnected_peer = self.peer
	local disconnected, disconnect_error = pcall(
		disconnected_peer.disconnect_now,
		disconnected_peer,
		0
	)
	if not disconnected then self.last_fault_error = tostring(disconnect_error) end
	self.peer = nil
	self.connected_at = nil
	self.last_due_by_channel = {}
	self.ignored_disconnect_peers[disconnected_peer] = true
	self.synthetic_events[#self.synthetic_events + 1] = {
		type = "disconnect",
		peer = disconnected_peer,
		data = 0,
		fault = true,
	}
	return disconnected
end

function EnetTransport:poll(timeout)
	if self.closed then return nil end
	local drained, drain_error = self:_drain_outgoing(false)
	if not drained then return nil, drain_error end
	self:_fault_disconnect()
	if #self.synthetic_events > 0 then
		return table.remove(self.synthetic_events, 1)
	end
	local event
	for attempt = 1, 8 do
		local serviced, event_or_error = pcall(
			self.host.service,
			self.host,
			attempt == 1 and math.max(0, math.floor(tonumber(timeout) or 0)) or 0
		)
		if not serviced then return nil, tostring(event_or_error) end
		event = event_or_error
		if not event then return nil end
		if event.type == "disconnect" and self.ignored_disconnect_peers[event.peer] then
			self.ignored_disconnect_peers[event.peer] = nil
			event = nil
		else
			break
		end
	end
	if not event then return nil end
	if event and event.peer and event.type == "connect"
		and (not self.peer or event.peer == self.peer) then
		self.peer = event.peer
		self.connected_at = clock()
	end
	if event and event.type == "receive" and type(event.data) == "string" then
		self.packets_received = self.packets_received + 1
		self.bytes_received = self.bytes_received + #event.data
		record_channel(
			self.channel_received,
			event.channelID or event.channel,
			#event.data
		)
	end
	if event and event.peer == self.peer and event.type == "disconnect" then
		self.peer = nil
		self.connected_at = nil
		self.outgoing_queue = {}
		self.outgoing_bytes = 0
		self.last_due_by_channel = {}
	end
	return event
end

function EnetTransport:send_raw(peer, data, channel, reliable)
	if self.closed then return false, "transport is closed" end
	peer = peer or self.peer
	if not peer then return false, "peer is not connected" end
	if type(data) ~= "string" then return false, "packet is not a string" end
	channel = math.floor(tonumber(channel) or Protocol.CHANNEL.CONTROL)
	if channel < 0 or channel > Protocol.CHANNEL.STATE then
		return false, "invalid ENet channel"
	end
	self.fault_attempted = self.fault_attempted + 1
	local profile = self.faults
	if reliable == false and profile.loss_percent > 0
		and random_unit(profile) * 100 < profile.loss_percent then
		self.fault_dropped = self.fault_dropped + 1
		return true, "fault_drop"
	end
	local copies = 1
	if reliable == false and profile.duplication_percent > 0
		and random_unit(profile) * 100 < profile.duplication_percent then
		copies = 2
		self.fault_duplicated = self.fault_duplicated + 1
	end
	for _ = 1, copies do
		if profile.latency_ms > 0 or profile.jitter_ms > 0 then
			if self.outgoing_bytes + #data > 32 * 1024 * 1024 then
				return false, "network fault queue overflow"
			end
			local jitter = (random_unit(profile) * 2 - 1) * profile.jitter_ms
			local due = clock() + math.max(0, profile.latency_ms + jitter) / 1000
			due = math.max(due, self.last_due_by_channel[channel] or 0)
			self.last_due_by_channel[channel] = due
			self.outgoing_sequence = self.outgoing_sequence + 1
			self.outgoing_queue[#self.outgoing_queue + 1] = {
				peer = peer,
				data = data,
				channel = channel,
				reliable = reliable,
				due = due,
				sequence = self.outgoing_sequence,
			}
			self.outgoing_bytes = self.outgoing_bytes + #data
		else
			local sent, send_error = self:_actual_send(peer, data, channel, reliable)
			if not sent then return false, send_error end
		end
	end
	return true
end

function EnetTransport:send(peer, kind, payload, channel, reliable)
	local encoded, encode_error = pcall(Protocol.encode, kind, payload)
	if not encoded then return false, tostring(encode_error) end
	return self:send_raw(peer, encode_error, channel, reliable)
end

function EnetTransport:flush()
	if not self.closed then self:_drain_outgoing(false) end
	if not self.closed and self.host and self.host.flush then self.host:flush() end
end

function EnetTransport:disconnect_peer(peer, data, immediate)
	peer = peer or self.peer
	if not peer then return true end
	self:_drain_outgoing(true)
	local disconnected, disconnect_error
	if immediate and peer.disconnect_now then
		disconnected, disconnect_error = pcall(peer.disconnect_now, peer, data or 0)
	else
		disconnected, disconnect_error = pcall(peer.disconnect, peer, data or 0)
		self:flush()
	end
	if not disconnected then return false, tostring(disconnect_error) end
	if peer == self.peer then
		self.peer = nil
		self.connected_at = nil
		self.outgoing_queue = {}
		self.outgoing_bytes = 0
		self.last_due_by_channel = {}
	end
	return true
end

function EnetTransport:disconnect(data, immediate)
	return self:disconnect_peer(self.peer, data, immediate)
end

function EnetTransport:close()
	if self.closed then return end
	self:disconnect(0, true)
	self.closed = true
	self.host = nil
	self.peer = nil
end

function EnetTransport:stats()
	local loss = peer_metric(self.peer, "packet_loss")
	if loss then
		if loss >= 0 and loss <= 1 then
			loss = loss * 100
		elseif loss > 100 then
			loss = loss * 100 / 65536
		end
	end
	return {
		rtt_ms = peer_metric(self.peer, "round_trip_time"),
		packet_loss_percent = loss,
		bytes_sent = self.bytes_sent,
		bytes_received = self.bytes_received,
		packets_sent = self.packets_sent,
		packets_received = self.packets_received,
		channel_sent = self.channel_sent,
		channel_received = self.channel_received,
		connected_seconds = math.max(0, clock() - self.started_at),
		faults = {
			latency_ms = self.faults.latency_ms,
			jitter_ms = self.faults.jitter_ms,
			loss_percent = self.faults.loss_percent,
			duplication_percent = self.faults.duplication_percent,
			disconnect_after = self.faults.disconnect_after,
			attempted = self.fault_attempted,
			dropped = self.fault_dropped,
			duplicated = self.fault_duplicated,
			disconnects = self.fault_disconnects,
			queued = #self.outgoing_queue,
			queued_bytes = self.outgoing_bytes,
			last_error = self.last_fault_error,
		},
	}
end

EnetTransport.fault_options = fault_options

return EnetTransport

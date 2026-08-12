local json = require("src.json")
local Identity = require("src.network.identity")
local Protocol = require("src.network.protocol")

local Discovery = {}

Discovery.GROUP = "239.255.77.77"
Discovery.BROADCAST = "255.255.255.255"
Discovery.PORT = 22121
Discovery.VERSION = 1
Discovery.MAGIC = "SARCO-LAN"
Discovery.MAX_PACKET_BYTES = 2048
Discovery.DIAGNOSTIC_TIMEOUT = 6

local socket_ok, socket = pcall(require, "socket")

local function clock()
	return socket_ok and socket.gettime() or os.clock()
end

local function bounded_string(value, maximum, allow_empty)
	if allow_empty and value == "" then return true end
	return Protocol.validate_string(value, maximum)
end

local function integer_between(value, minimum, maximum)
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value == math.floor(value)
		and value >= minimum and value <= maximum
end

local function encode(kind, payload)
	payload.magic = Discovery.MAGIC
	payload.version = Discovery.VERSION
	payload.type = kind
	local value = json.encode(payload)
	if #value > Discovery.MAX_PACKET_BYTES then error("discovery packet is too large") end
	return value
end

local function decode(value)
	if type(value) ~= "string" or #value == 0
		or #value > Discovery.MAX_PACKET_BYTES then
		return nil, "invalid discovery packet size"
	end
	local decoded, packet = pcall(json.decode, value)
	if not decoded or type(packet) ~= "table" then return nil, "invalid discovery json" end
	if packet.magic ~= Discovery.MAGIC or packet.version ~= Discovery.VERSION then
		return nil, "discovery version mismatch"
	end
	if packet.type ~= "discover" and packet.type ~= "announce" then
		return nil, "invalid discovery packet type"
	end
	if not Identity.valid(packet.nonce) then return nil, "invalid discovery nonce" end
	return packet
end

local function nonblocking_udp()
	if not socket_ok then return nil, tostring(socket) end
	-- LuaSocket 3 may default socket.udp() to the platform-preferred address
	-- family. Discovery uses an IPv4 administratively scoped multicast group,
	-- so request an IPv4 socket explicitly when that constructor is available.
	local constructor = socket.udp4 or socket.udp
	local udp, udp_error = constructor()
	if not udp then return nil, udp_error end
	udp:settimeout(0)
	return udp
end

local Responder = {}
Responder.__index = Responder

function Discovery.create_responder(provider, options)
	assert(type(provider) == "function", "discovery provider is required")
	options = options or {}
	local udp, udp_error = nonblocking_udp()
	if not udp then return nil, udp_error end
	pcall(udp.setoption, udp, "reuseaddr", true)
	pcall(udp.setoption, udp, "broadcast", true)
	pcall(udp.setoption, udp, "ip-multicast-loop", true)
	local port = tonumber(options.port) or Discovery.PORT
	local bound, bind_error = udp:setsockname(options.bind or "*", port)
	if not bound then udp:close(); return nil, bind_error end
	local group = options.group or Discovery.GROUP
	local join_called, joined, join_error = pcall(udp.setoption, udp, "ip-add-membership", {
		multiaddr = group,
		interface = options.interface or "0.0.0.0",
	})
	if join_called and joined then pcall(udp.setoption, udp, "ip-multicast-ttl", 1) end
	return setmetatable({
		udp = udp,
		provider = provider,
		port = port,
		group = group,
		multicast_error = join_called and joined and nil
			or tostring(join_error or joined or "could not join multicast group"),
	}, Responder)
end

local function valid_advertisement(value)
	return type(value) == "table"
		and bounded_string(value.protocol_version, 32)
		and bounded_string(value.game_version, 64)
		and Identity.valid(value.content_hash)
		and Identity.valid(value.session_id)
		and Identity.valid(value.world_id)
		and integer_between(value.gameplay_port, 1, 65535)
		and integer_between(value.players, 0, 2)
		and integer_between(value.capacity, 1, 2)
		and value.players <= value.capacity
		and type(value.joinable) == "boolean"
		and bounded_string(value.display_name, 96)
end

function Responder:update()
	for _ = 1, 32 do
		local value, address, port = self.udp:receivefrom()
		if not value then break end
		local packet = decode(value)
		if packet and packet.type == "discover" then
			local supplied, advertisement = pcall(self.provider)
			if supplied and valid_advertisement(advertisement) then
				local response = {}
				for key, nested in pairs(advertisement) do response[key] = nested end
				response.nonce = packet.nonce
				local encoded, payload = pcall(encode, "announce", response)
				if encoded then self.udp:sendto(payload, address, port) end
			end
		end
	end
end

function Responder:close()
	if self.udp then
		pcall(self.udp.setoption, self.udp, "ip-drop-membership", {
			multiaddr = self.group,
			interface = "0.0.0.0",
		})
		self.udp:close()
		self.udp = nil
	end
end

local Browser = {}
Browser.__index = Browser

function Discovery.create_browser(options)
	options = options or {}
	local udp, udp_error = nonblocking_udp()
	if not udp then return nil, udp_error end
	local bound, bind_error = udp:setsockname(options.bind or "*", 0)
	if not bound then udp:close(); return nil, bind_error end
	pcall(udp.setoption, udp, "broadcast", true)
	pcall(udp.setoption, udp, "ip-multicast-ttl", 1)
	pcall(udp.setoption, udp, "ip-multicast-loop", true)
	return setmetatable({
		udp = udp,
		group = options.group or Discovery.GROUP,
		port = tonumber(options.port) or Discovery.PORT,
		ttl = tonumber(options.ttl) or 5,
		nonces = {},
		records = {},
		started_at = clock(),
		first_refresh_at = nil,
		last_refresh_at = nil,
		last_response_at = nil,
		refresh_count = 0,
		destinations = {},
		configured_destinations = options.destinations,
	}, Browser)
end

function Browser:refresh(target_address, target_port)
	local refreshed_at = clock()
	self.first_refresh_at = self.first_refresh_at or refreshed_at
	self.last_refresh_at = refreshed_at
	self.refresh_count = self.refresh_count + 1
	local nonce = Identity.public_token("discover")
	self.nonces[nonce] = clock() + self.ttl
	local packet = encode("discover", { nonce = nonce })
	local port = target_port or self.port
	local destinations = target_address and { target_address }
		or self.configured_destinations or {
			self.group,
			Discovery.BROADCAST,
			"127.0.0.1",
		}
	local sent_any = false
	local errors = {}
	for _, address in ipairs(destinations) do
		local sent, send_error = self.udp:sendto(packet, address, port)
		self.destinations[address] = {
			ok = sent and true or false,
			error = sent and nil or tostring(send_error),
			last_attempt_at = refreshed_at,
		}
		if sent then
			sent_any = true
		else
			errors[#errors + 1] = ("%s: %s"):format(
				address,
				tostring(send_error)
			)
		end
	end
	if not sent_any then
		self.nonces[nonce] = nil
		return false, table.concat(errors, "; ")
	end
	return true, nonce
end

local function validate_announcement(packet)
	return packet.type == "announce"
		and valid_advertisement(packet)
		and packet.protocol_version == tostring(Protocol.VERSION)
end

function Browser:update()
	local current = clock()
	for _ = 1, 64 do
		local value, address = self.udp:receivefrom()
		if not value then break end
		local packet = decode(value)
		if packet and validate_announcement(packet)
			and self.nonces[packet.nonce]
			and self.nonces[packet.nonce] >= current then
			local key = packet.session_id .. "@" .. address
			packet.address = address
			packet.last_seen = current
			packet.expires_at = current + self.ttl
			self.records[key] = packet
			self.last_response_at = current
		end
	end
	for nonce, expires_at in pairs(self.nonces) do
		if expires_at < current then self.nonces[nonce] = nil end
	end
	for key, record in pairs(self.records) do
		if record.expires_at < current then self.records[key] = nil end
	end
end

function Browser:status()
	local current = clock()
	local records = self:list()
	local waiting_since = self.last_response_at or self.first_refresh_at
	local waiting_seconds = waiting_since and math.max(0, current - waiting_since) or 0
	local multicast = self.destinations[self.group]
	local broadcast = self.destinations[Discovery.BROADCAST]
	return {
		refresh_count = self.refresh_count,
		searching_seconds = waiting_seconds,
		timed_out = #records == 0 and self.refresh_count > 0
			and waiting_seconds >= Discovery.DIAGNOSTIC_TIMEOUT,
		last_response_at = self.last_response_at,
		multicast_error = multicast and multicast.error or nil,
		broadcast_error = broadcast and broadcast.error or nil,
		broadcast_fallback = multicast and not multicast.ok
			and broadcast and broadcast.ok or false,
		destinations = self.destinations,
	}
end

function Browser:list()
	local records = {}
	for _, record in pairs(self.records) do records[#records + 1] = record end
	table.sort(records, function(left, right)
		if left.joinable ~= right.joinable then return left.joinable end
		if left.display_name ~= right.display_name then
			return left.display_name < right.display_name
		end
		return left.address < right.address
	end)
	return records
end

function Browser:close()
	if self.udp then self.udp:close(); self.udp = nil end
	self.records = {}
	self.nonces = {}
end

Discovery.encode = encode
Discovery.decode = decode
Discovery.valid_advertisement = valid_advertisement

return Discovery

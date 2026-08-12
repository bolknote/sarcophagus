local GhostActor = require("src.ghost_actor")
local InputState = require("src.input_state")
local Identity = require("src.network.identity")
local Protocol = require("src.network.protocol")

local Session = {}
Session.__index = Session

-- Runtime gives the host a few extra seconds beyond the client's retry
-- deadline. This standalone default follows the same suspend-safe policy.
Session.DEFAULT_RECONNECT_TIMEOUT = 30 * 60 + 5

Session.STATE = {
	LISTENING = "listening",
	AWAITING_APPROVAL = "awaiting_host_approval",
	SENDING_SNAPSHOT = "sending_snapshot",
	CATCHING_UP = "catching_up",
	PLAYING = "playing",
	RECONNECT_GRACE = "reconnect_grace",
	DROPPING = "dropping_possessions",
	SHUTDOWN = "shutdown",
}

local function default_clock()
	if love and love.timer then return love.timer.getTime() end
	return os.clock()
end

local function default_token(prefix)
	return Identity.secret_token(prefix)
end

local function now(session, value)
	return tonumber(value) or session.clock()
end

local function bounded_positive(value, fallback, maximum, integer)
	if type(value) ~= "number" or value ~= value or value == math.huge
		or value == -math.huge or value <= 0 or value > maximum
		or (integer and value ~= math.floor(value)) then
		return fallback
	end
	return value
end

function Session.new(options)
	options = options or {}
	assert(type(options.registry) == "table", "actor registry is required")
	return setmetatable({
		registry = options.registry,
		protocol = options.protocol or Protocol,
		clock = options.clock or default_clock,
		token_factory = options.token_factory or default_token,
		dropper = options.dropper,
		state = Session.STATE.LISTENING,
		session_id = nil,
		client_nonce = nil,
		reconnect_token = nil,
		pending = nil,
		guest = nil,
		last_server_tick = 0,
		approval_timeout = math.max(1, tonumber(options.approval_timeout) or 30),
		reconnect_timeout = math.max(1, tonumber(options.reconnect_timeout)
			or Session.DEFAULT_RECONNECT_TIMEOUT),
		snapshot_timeout = math.max(1, tonumber(options.snapshot_timeout) or 60),
		catchup_timeout = math.max(1, tonumber(options.catchup_timeout) or 30),
		deadline = nil,
		processed_actions = {},
		processed_action_results = {},
		processed_action_order = {},
		last_numeric_action_id = nil,
		max_processed_actions = bounded_positive(
			options.max_processed_actions, 2048, 16384, true
		),
		action_rate = bounded_positive(options.action_rate, 30, 1000),
		action_burst = bounded_positive(options.action_burst, 60, 10000),
		action_tokens = bounded_positive(options.action_burst, 60, 10000),
		action_token_time = nil,
		input_rate = bounded_positive(options.input_rate, 60, 1000),
		input_burst = bounded_positive(options.input_burst, 120, 10000),
		input_tokens = bounded_positive(options.input_burst, 120, 10000),
		input_token_time = nil,
		dropped_sessions = {},
		last_disconnect_reason = nil,
	}, Session)
end

function Session:is_joinable()
	return self.state == Session.STATE.LISTENING and self.guest == nil
end

function Session:begin_join(hello, expected, timestamp)
	if not self:is_joinable() then return false, "session_not_joinable" end
	local valid, reason = self.protocol.validate_hello(hello, expected)
	if not valid then return false, reason end

	local session_id = self.token_factory("session")
	if not Identity.valid(session_id) then return false, "invalid_session_token" end
	self.session_id = session_id
	self.client_nonce = hello.client_nonce
	self.pending = { hello = hello }
	self.state = Session.STATE.AWAITING_APPROVAL
	self.deadline = now(self, timestamp) + self.approval_timeout
	self.action_tokens = self.action_burst
	self.action_token_time = now(self, timestamp)
	self.input_tokens = self.input_burst
	self.input_token_time = now(self, timestamp)
	return true, {
		session_id = self.session_id,
		client_nonce = hello.client_nonce,
	}
end

function Session:reject(reason)
	if self.state ~= Session.STATE.AWAITING_APPROVAL then
		return false, "no_pending_join"
	end
	self.pending = nil
	self.client_nonce = nil
	self.deadline = nil
	self.state = Session.STATE.LISTENING
	return true, reason or "rejected_by_host"
end

function Session:approve(host_actor, spawn)
	if self.state ~= Session.STATE.AWAITING_APPROVAL then
		return false, "no_pending_join"
	end
	spawn = spawn or {}
	local reconnect_token = self.token_factory("reconnect")
	if not Identity.valid(reconnect_token) then
		return false, "invalid_reconnect_token"
	end
	self.reconnect_token = reconnect_token
	self.guest = GhostActor.new(host_actor, {
		actor_id = "guest",
		session_id = self.session_id,
		x = spawn.x,
		y = spawn.y,
		tx = spawn.tx,
		ty = spawn.ty,
		xt = spawn.xt,
		yt = spawn.yt,
		truex = spawn.truex,
		truey = spawn.truey,
	})
	self.registry:bind_guest(self.guest)
	self.pending = nil
	self.deadline = now(self) + self.snapshot_timeout
	self.state = Session.STATE.SENDING_SNAPSHOT
	return true, {
		session_id = self.session_id,
		reconnect_token = self.reconnect_token,
		actor_id = self.guest.actor_id,
		snapshot_version = self.protocol.SNAPSHOT_VERSION,
	}
end

function Session:snapshot_sent(server_tick)
	if self.state ~= Session.STATE.SENDING_SNAPSHOT then
		return false, "snapshot_not_expected"
	end
	if not self.protocol.validate_nonnegative_integer(server_tick, 9007199254740991) then
		return false, "invalid_snapshot_tick"
	end
	self.last_server_tick = server_tick
	self.deadline = now(self) + self.catchup_timeout
	self.state = Session.STATE.CATCHING_UP
	return true
end

function Session:ready(snapshot_tick)
	if self.state ~= Session.STATE.CATCHING_UP then return false, "not_catching_up" end
	snapshot_tick = tonumber(snapshot_tick)
	if not snapshot_tick or snapshot_tick < 0 or snapshot_tick ~= math.floor(snapshot_tick)
		or snapshot_tick ~= self.last_server_tick then
		return false, "invalid_snapshot_tick"
	end
	self.deadline = nil
	self.state = Session.STATE.PLAYING
	return true
end

function Session:_remember_action(action_id, key)
	key = key or (type(action_id) .. ":" .. tostring(action_id))
	if self.processed_actions[key] then return true end
	if type(action_id) == "number" then self.last_numeric_action_id = action_id end
	self.processed_actions[key] = true
	self.processed_action_order[#self.processed_action_order + 1] = key
	if #self.processed_action_order > self.max_processed_actions then
		local expired = table.remove(self.processed_action_order, 1)
		self.processed_actions[expired] = nil
		self.processed_action_results[expired] = nil
	end
	return true
end

function Session:accept_action(action_id, timestamp)
	if self.state ~= Session.STATE.PLAYING then return false, "not_playing" end
	if not self.protocol.validate_action_id(action_id) then
		return false, "invalid_action_id"
	end
	local key = type(action_id) .. ":" .. tostring(action_id)
	if self.processed_actions[key] then
		return false, "duplicate_action", self.processed_action_results[key]
	end
	if type(action_id) == "number" and self.last_numeric_action_id
		and action_id <= self.last_numeric_action_id then
		return false, "stale_action_id"
	end
	local current = now(self, timestamp)
	local previous = self.action_token_time or current
	local elapsed = math.max(0, current - previous)
	self.action_token_time = current
	self.action_tokens = math.min(
		self.action_burst,
		(tonumber(self.action_tokens) or self.action_burst)
			+ elapsed * self.action_rate
	)
	if self.action_tokens < 1 then
		-- A lost negative result must not turn into a successful transaction when
		-- the same application-reliable action is retried after tokens replenish.
		self:_remember_action(action_id, key)
		return false, "action_rate_limited"
	end
	self.action_tokens = self.action_tokens - 1
	self:_remember_action(action_id, key)
	return true
end

function Session:record_action_result(action_id, result)
	if not self.protocol.validate_action_id(action_id) or type(result) ~= "table" then
		return false, "invalid_action_result"
	end
	local key = type(action_id) .. ":" .. tostring(action_id)
	if not self.processed_actions[key] then return false, "unknown_action" end
	self.processed_action_results[key] = {
		action_id = action_id,
		ok = result.ok == true,
		error = result.error,
	}
	return true
end

function Session:accept_input(snapshot, timestamp)
	if self.state ~= Session.STATE.PLAYING then return false, "not_playing" end
	local runtime = self.registry:runtime(self.guest)
	if not runtime then return false, "missing_guest_runtime" end
	local sequence = snapshot and snapshot.sequence
	local previous = tonumber(runtime.input.sequence) or 0
	if type(sequence) ~= "number" or sequence < 0
		or sequence > InputState.MAX_SEQUENCE or sequence ~= math.floor(sequence) then
		return false, "invalid_input_sequence"
	end
	local sequence_space = InputState.MAX_SEQUENCE + 1
	local distance = (sequence - previous) % sequence_space
	if distance == 0 or distance > sequence_space / 2 then
		return false, "stale_input"
	end
	local current = now(self, timestamp)
	local previous_time = self.input_token_time or current
	local elapsed = math.max(0, current - previous_time)
	self.input_token_time = current
	self.input_tokens = math.min(
		self.input_burst,
		(tonumber(self.input_tokens) or self.input_burst)
			+ elapsed * self.input_rate
	)
	if self.input_tokens < 1 then return false, "input_rate_limited" end
	self.input_tokens = self.input_tokens - 1
	return InputState.apply_snapshot(runtime.input, snapshot)
end

function Session:_finish_drop()
	local guest = self.guest
	if not guest then
		self.state = Session.STATE.LISTENING
		return true
	end
	local id = self.session_id
	if not self.dropped_sessions[id] then
		if type(self.dropper) ~= "function" then
			return false, "guest possession dropper is not configured"
		end
		local called, dropped, drop_error = pcall(self.dropper, guest, id)
		if not called then return false, dropped end
		if dropped == false then return false, drop_error or "could not drop possessions" end
		self.dropped_sessions[id] = true
	end
	self.registry:remove(guest)
	self.dropped_sessions[id] = nil
	self.guest = nil
	self.client_nonce = nil
	self.reconnect_token = nil
	self.deadline = nil
	self.processed_actions = {}
	self.processed_action_results = {}
	self.processed_action_order = {}
	self.last_numeric_action_id = nil
	self.state = Session.STATE.LISTENING
	return true
end

function Session:disconnect(reason, clean, timestamp)
	self.last_disconnect_reason = reason or "disconnected"
	if not self.guest then
		self.pending = nil
		self.client_nonce = nil
		self.deadline = nil
		self.state = Session.STATE.LISTENING
		return true
	end
	if clean then
		self.state = Session.STATE.DROPPING
		return self:_finish_drop()
	end
	-- A peer that connects and disappears without proving possession of the
	-- reconnect token must not extend the reserved slot forever.
	if self.state == Session.STATE.RECONNECT_GRACE and self.deadline then
		return true
	end
	self.state = Session.STATE.RECONNECT_GRACE
	self.deadline = now(self, timestamp) + self.reconnect_timeout
	return true
end

function Session:resume(reconnect_token)
	if self.state ~= Session.STATE.RECONNECT_GRACE then return false, "not_reconnecting" end
	if type(reconnect_token) ~= "string" or reconnect_token ~= self.reconnect_token then
		return false, "invalid_reconnect_token"
	end
	self.deadline = nil
	self.state = Session.STATE.PLAYING
	return true
end

function Session:resume_snapshot(reconnect_token, timestamp)
	if self.state ~= Session.STATE.RECONNECT_GRACE then return false, "not_reconnecting" end
	if type(reconnect_token) ~= "string" or reconnect_token ~= self.reconnect_token then
		return false, "invalid_reconnect_token"
	end
	self.deadline = now(self, timestamp) + self.snapshot_timeout
	self.state = Session.STATE.SENDING_SNAPSHOT
	return true
end

function Session:update(timestamp)
	local current = now(self, timestamp)
	if self.state == Session.STATE.AWAITING_APPROVAL and current >= self.deadline then
		return self:reject("approval_timeout")
	end
	if self.state == Session.STATE.RECONNECT_GRACE and current >= self.deadline then
		self.state = Session.STATE.DROPPING
		return self:_finish_drop()
	end
	if (self.state == Session.STATE.SENDING_SNAPSHOT
		or self.state == Session.STATE.CATCHING_UP)
		and self.deadline and current >= self.deadline then
		local reason = self.state == Session.STATE.SENDING_SNAPSHOT
			and "snapshot_timeout" or "catchup_timeout"
		self.last_disconnect_reason = reason
		self.state = Session.STATE.DROPPING
		local dropped, drop_error = self:_finish_drop()
		return dropped, dropped and reason or drop_error
	end
	if self.state == Session.STATE.DROPPING then return self:_finish_drop() end
	return true
end

function Session:shutdown()
	if self.guest then
		self.state = Session.STATE.DROPPING
		local dropped, drop_error = self:_finish_drop()
		if not dropped then return false, drop_error end
	end
	self.state = Session.STATE.SHUTDOWN
	return true
end

return Session

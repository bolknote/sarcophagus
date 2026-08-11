local ActorState = require("src.actor_state")

local GhostActor = {}

local shared_progress_fields = {
	"unlock_i",
	"unlock_c",
	"visited",
	"ferted",
	"quests",
}

local function deep_copy(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local copy = {}
	seen[value] = copy
	for key, nested in pairs(value) do
		copy[deep_copy(key, seen)] = deep_copy(nested, seen)
	end
	return copy
end

local function reset_stats(stats)
	for name, stat in pairs(stats or {}) do
		if type(stat) == "table" then
			local maximum = tonumber(stat.maxhp) or 100
			if name == "faith" then
				stat.hp = 0
				stat.pc = 0
			else
				stat.hp = maximum
				stat.pc = maximum > 0 and 100 or 0
			end
			stat.d = 0
			stat.currentgrow = 0
		end
	end
end

function GhostActor.new(host, options)
	assert(type(host) == "table", "host actor must be a table")
	options = options or {}
	local ghost = deep_copy(host)
	ActorState.ensure(ghost, {
		actor_id = options.actor_id or "guest",
		actor_role = "guest",
		force_identity = true,
	})

	for _, field in ipairs(shared_progress_fields) do
		host[field] = host[field] or {}
		ghost[field] = host[field]
	end

	ghost.inv = {}
	ghost.invsize = math.max(0, math.floor(tonumber(options.invsize) or 9))
	ghost.invselect = 1
	ghost.inv_show = {}
	ghost.inv_show_c = 0
	ghost.iscarry = nil
	ghost.candrop = nil
	ghost.buffs = {}
	ghost.shit = {}
	ghost.dishes = {}
	ghost.killed = {}
	ghost.log = {}
	ghost.logoffset = 0
	ghost.score = 0
	ghost.savedscore = 0
	ghost.deaths = 0
	ghost.isdead = nil
	ghost.dying = nil
	ghost.lastdeath = nil
	ghost.lastshit = 0
	ghost.bufftick = 0
	ghost.rest = 0
	ghost.unrest = 0
	ghost.spenddead = 0
	ghost.idlecnt = 0
	ghost.digcount = 0
	ghost.digcountup = 0
	ghost.digdone = 0
	ghost.throw = 0
	ghost.travel = 0
	ghost.state = "idle"
	ghost.oldstate = "idle"
	ghost.ghost = true
	ghost.session_id = options.session_id
	reset_stats(ghost.stats)
	ActorState.reset_animation(ghost)

	if options.x then ghost.x = options.x end
	if options.y then ghost.y = options.y end
	if options.tx then ghost.tx = options.tx end
	if options.ty then ghost.ty = options.ty end
	if options.xt then ghost.xt = options.xt end
	if options.yt then ghost.yt = options.yt end
	if options.truex then ghost.truex = options.truex end
	if options.truey then ghost.truey = options.truey end

	return ghost
end

return GhostActor

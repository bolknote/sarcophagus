-- http = require "socket.http"


-- server_version = http.request ('http://spectator.ru/sarcophagus/version.php')
-- if server_version then
-- 	server_version = string.gsub(server_version, '{"latest":"', "")
-- 	server_version = string.gsub(server_version, '"}', "")
-- else
-- 	server_version = ""
-- end

server_version = ""
game_version = love.filesystem.read('version.txt')
BUILD_MODE = require("src.build_mode").detect()
IS_DEVELOPMENT = BUILD_MODE == "development"
GAME_CRASHED = false
world = {}

local default_errorhandler = love.errorhandler
if default_errorhandler then
	function love.errorhandler(message)
		GAME_CRASHED = true
		return default_errorhandler(message)
	end
end

io.stdout:setvbuf("no")

local imgData = love.image.newImageData('packaging/icon.png')
love.window.setIcon(imgData)
love.window.setTitle('Sarcophagus v.'..game_version)

-- Automated LÖVE checks still need a real graphics context, but they do not
-- need to steal focus or cover the user's desktop.
if os.getenv("SARCOPHAGUS_TEST_BACKGROUND") == "1"
	and os.getenv("SARCOPHAGUS_TEST_NO_MINIMIZE") ~= "1"
	-- On macOS, minimizing before a smoke test toggles fullscreen can invalidate
	-- Metal render targets. The test launcher already opens it without focus.
	and (not love.system
		or (love.system.getOS() ~= "OS X" and love.system.getOS() ~= "macOS"))
	and love.window.minimize then
	pcall(love.window.minimize)
end

love.graphics.setDefaultFilter("nearest", "nearest", 1)
--love.window.maximize ()

love.audio.setOrientation(0, 0, 1, 0,-1,0)
--love.audio.setDistanceModel("inverseclamped")
love.audio.setDistanceModel("exponentclamped")

if IS_DEVELOPMENT then
	lurker = require "tools.dev.lurker"
end

binser = require "src.binser"
ActorState = require("src.actor_state")
ActorRegistry = require("src.actor_registry")
InputState = require("src.input_state")
ActorContext = require("src.actor_context")
ActorRenderer = require("src.actor_renderer")
PlayerAnimation = require("src.player_animation")
ItemIdentity = require("src.item_identity")
StateCopy = require("src.state_copy")
ActorInventory = require("src.actor_inventory")
GhostActor = require("src.ghost_actor")
GuestPossessions = require("src.guest_possessions")
MultiplayerProtocol = require("src.network.protocol")
MultiplayerSession = require("src.network.session")
MultiplayerContentHash = require("src.network.content_hash")
NetworkIdentity = require("src.network.identity")
EnetTransport = require("src.network.enet_transport")
NetworkSnapshot = require("src.network.snapshot")
NetworkReplication = require("src.network.replication")
NetworkInterpolationBuffer = require("src.network.interpolation_buffer")
WorldJournal = require("src.network.world_journal")
LANDiscovery = require("src.network.discovery")
MultiplayerRuntime = require("src.network.runtime")
NetworkGameAdapter = require("src.network.game_adapter")
actors = ActorRegistry.new()
network_world_journal = WorldJournal.new()
require ("src.mainlib")
save_manager = require("src.save_manager")

function game_save_async(name, options)
	return save_manager.start(name, options)
end

ini_quad ()


require ("src.load")
require ("src.update")
require ("src.draw")

require ("src.vars")
NetworkIdentity.ensure_world(game)
actors:bind_host(pl, vi)
require ("src.menu")
require ("src.items")
require ("src.stones")
require ("src.dispenser")
require ("src.mapgen")
require ("src.checks")
require ("src.mobs_ai")
require ("src.craft")
require ("src.msg")
require ("src.textgui")
require ("src.keypressed")
require ("src.ext")
require ("src.moving")
require ("src.ani")
require ("src.buffs")
require ("src.disaster")
require ("src.projes")
require ("src.sound")
require ("src.fishing")
require ("src.escmenu")
require ("src.joystick")
require ("src.achievements")
require ("src.draw_gui")

local multiplayer_game_adapter = NetworkGameAdapter.new({
	state_provider = multiplayer_snapshot_state,
	state_applier = multiplayer_apply_snapshot,
	spawn_provider = multiplayer_guest_spawn,
	dropper = multiplayer_drop_guest,
	action_handler = multiplayer_guest_action,
	action_rejection_handler = multiplayer_reject_guest_action,
	simulation_handler = multiplayer_simulate_guest,
	replication_provider = multiplayer_replication_state,
	replication_applier = multiplayer_apply_replication,
	world_delta_provider = multiplayer_world_delta,
	world_delta_applier = multiplayer_apply_world_delta,
	world_delta_reset = function()
		network_world_journal:clear()
		return true
	end,
	catchup_validator = function()
		return multiplayer_network_catchup_ready()
	end,
	event_provider = multiplayer_next_network_event,
	event_handler = multiplayer_apply_network_event,
	event_reset = multiplayer_reset_network_events,
	action_result_handler = multiplayer_action_result,
})
multiplayer = MultiplayerRuntime.new(multiplayer_game_adapter:runtime_options({
	registry = actors,
}))

if IS_DEVELOPMENT and lurker then
	lurker.preswap = function(path)
		if multiplayer and multiplayer.role ~= "offline" then
			local stopped, stop_error = multiplayer:prepare_quit()
			if not stopped then
				if oldprint then
					oldprint("Hot reload blocked for " .. tostring(path) .. ": "
						.. tostring(stop_error))
				end
				return true
			end
		end
		return false
	end
	lurker.postswap = function(path)
		if multiplayer and multiplayer.invalidate_content_hash then
			local invalidated, invalidate_error =
				multiplayer:invalidate_content_hash(true)
			if not invalidated and oldprint then
				oldprint("Could not refresh content hash after " .. tostring(path)
					.. ": " .. tostring(invalidate_error))
			end
		elseif MultiplayerContentHash and MultiplayerContentHash.invalidate then
			MultiplayerContentHash.invalidate()
		end
	end
end

utf8 = require("utf8")

local smoke_test = os.getenv("SARCOPHAGUS_SMOKE_TEST")
if smoke_test then
	require("tests.smoke").install(smoke_test)
end

if IS_DEVELOPMENT then
	moving_editor = loadfile('tools/dev/moving_editor.lua')
end

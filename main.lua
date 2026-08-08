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
world = {}

io.stdout:setvbuf("no")

--local imgData = love.image.newImageData ('packaging/icon.png')
--love.window.setIcon (imgData)
love.window.setTitle('Sarcophagus v.'..game_version)

love.graphics.setDefaultFilter("nearest", "nearest", 1)
--love.window.maximize ()

love.audio.setOrientation(0, 0, 1, 0,-1,0)
--love.audio.setDistanceModel("inverseclamped")
love.audio.setDistanceModel("exponentclamped")

if IS_DEVELOPMENT then
	lurker = require "tools.dev.lurker"
end

binser = require "src.binser"
require ("src.mainlib")

ini_quad ()


require ("src.load")
require ("src.update")
require ("src.draw")

require ("src.vars")
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

utf8 = require("utf8")

local smoke_test = os.getenv("SARCOPHAGUS_SMOKE_TEST")
if smoke_test then
	require("tests.smoke").install(smoke_test)
end

if IS_DEVELOPMENT then
	moving_editor = loadfile('tools/dev/moving_editor.lua')
end


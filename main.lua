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
BUILD_MODE = require("build_mode").detect()
IS_DEVELOPMENT = BUILD_MODE == "development"
world = {}

io.stdout:setvbuf("no")

--local imgData = love.image.newImageData ('font/icon.png') 
--love.window.setIcon (imgData)
love.window.setTitle('Sarcophagus v.'..game_version)
love.window.setMode(1280, 720, {usedpiscale = false, centered = false, resizable = true, borderless = false, vsync = 1})

love.graphics.setDefaultFilter("nearest", "nearest", 1)
--love.window.maximize ()

love.audio.setOrientation(0, 0, 1, 0,-1,0)
--love.audio.setDistanceModel("inverseclamped")
love.audio.setDistanceModel("exponentclamped")

if IS_DEVELOPMENT then
	lurker = require "lurker"		
end

binser = require "binser"
require ("mainlib")

ini_quad ()


require ("load")
require ("update")
require ("draw")

require ("vars")
require ("menu")
require ("items")
require ("stones")
require ("dispenser")
require ("mapgen")
require ("checks")
require ("mobs_ai")
require ("craft")
require ("msg")
require ("textgui")
require ("keypressed")
require ("ext")
require ("moving")
require ("ani")
require ("buffs")
require ("disaster")
require ("projes")
require ("sound")
require ("fishing")
require ("escmenu")
require ("joystick")
require ("achievements")
require ('draw_gui')

utf8 = require("utf8")

local smoke_test = os.getenv("SARCOPHAGUS_SMOKE_TEST")
if smoke_test then
	require("tests.smoke").install(smoke_test)
end

if IS_DEVELOPMENT then
	moving_editor = loadfile('moving_editor.lua')
end




io.stdout:setvbuf("no")
love.window.setTitle('sarcophagus')
love.window.setMode(1440, 900, {centered = true, resizable = true, vsync = true})
love.graphics.setDefaultFilter("nearest", "nearest", 1)
love.filesystem.setIdentity("sarcophagus")
		

lurker = require "lurker"		
binser = require "binser"
require ("load")
require ("update")
require ("draw")
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
utf8 = require("utf8")


moving_editor =  loadfile ('moving_editor.lua')


require ("mainlib")
require ("vars")


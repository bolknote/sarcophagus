io.stdout:setvbuf("no")
love.filesystem.setIdentity("sarcophagus")

require ("src.vars")
binser = require "src.binser"
require ("src.mainlib")

function img_load (name)
	return name
end

require ("src.mapgen")
require ("src.ext")
require ("src.stones")
require ('love.math')

function img_load (name)
	return name
end

do_map ()

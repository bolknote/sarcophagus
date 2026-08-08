io.stdout:setvbuf("no")
love.filesystem.setIdentity("sarcophagus")

require ("vars")
binser = require "binser"
require ("mainlib")

function img_load (name)
	return name
end

require ("mapgen")
require ("ext")
require ("stones")
require ('love.math')

function img_load (name)
	return name
end

do_map ()
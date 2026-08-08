love.filesystem.setIdentity("sarcophagus")
local name,world, vi, pl, game, tips, disp, cf, mobs = ...



		local BlobWriter = require('BlobWriter')
		blob = BlobWriter()

		
		blob:write(world)
		:write(vi)
		:write(pl)
		:write(game)
		:write(tips)
		:write(disp)
		:write(cf)
		:write(mobs)

		local save = blob:tostring()


-- binser = require "binser"
-- local save = binser.serialize (world, vi, pl, game, tips, disp, cf, mobs)

save = love.data.compress ('string', 'gzip', save)
love.filesystem.write (name..'.save', save)
love.thread.getChannel('saveinfo'):clear()
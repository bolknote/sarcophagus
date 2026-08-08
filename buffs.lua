-- pl.buffs[n=>ttl]

-- on_tick
-- on_start
-- on_remove
-- on_ttl

-- buff_remove ()
-- buff_add (n, refresh, add, keep)


function buff_remove_all ()
	for k,v in pairs(pl.buffs) do
		if buff[k].on_remove then
			buff[k].on_remove ()
		end
	end
	pl.buffs = {}
end

function buff_remove (a)
	if pl.buffs[a] then
		textwall (msg.game[19],false,{[1] = msg.buff[a].name, [2] = msg.buff[a].desc})
		if buff[a].on_remove then
			buff[a].on_remove ()
		end
		pl.buffs[a]=nil
	end
end


function buff_add (a,mode,num) --refresh, add, keep
	mode = mode or 'refresh'

	if mode=='add' and pl.buffs[a]==nil then
		mode='refresh'
	end

	if mode=='keep' and pl.buffs[a]==nil then
		mode='refresh'
	end

	if mode=='refresh' then

		if buff[a].on_start and pl.buffs[a]==nil then buff[a].on_start() end

		if pl.buffs[a]==nil and buff[a].silent == nil then
			textwall (msg.game[18],false,{[1] = msg.buff[a].name, [2] = msg.buff[a].desc})
			if buff[a].sound then
				sound_add ('buff',buff[a].sound)
			end
		end

		if pl.buffs[a]==nil then
			table.insert (sct,{font='norm', x=pl.x+love.math.random(-8,8),y=pl.y-50,text=text_color("{#ead4aaff}"..msg.buff[a].name),ttl=1.8,xs=pl.flip*-1*(love.math.random(5,30))})
		end

		pl.buffs[a] = pl.buffs[a] or {}
		pl.buffs[a].ttl = game.time + buff[a].ttl
		pl.buffs[a].cd = game.time

		if buff[a].cnt and pl.buffs[a].cnt==nil then
			pl.buffs[a].cnt = buff[a].cnt
		end

	end

	if mode=='add' and pl.buffs[a] then
		pl.buffs[a].ttl = pl.buffs[a].ttl + buff[a].ttl
		if buff[a].cnt then
			pl.buffs[a].cnt = (pl.buffs[a].cnt or 1) + (num or 1)
		end
	end
end

function buff_tick ()

	if game.time~=pl.bufftick then

		pl.bufftick = game.time

		for k,v in pairs(pl.buffs) do

			if v.ttl<game.time then
				
					local onttl = buff[k].on_ttl

					if onttl then
						onttl (k)
					end
					
					if buff[k].silent == nil then
						textwall (msg.game[19],false,{[1] = msg.buff[k].name, [2] = msg.buff[k].desc})
					end

					pl.buffs[k]=nil

				break
			end

			if buff[k].on_tick then
				buff[k].on_tick (k)
			end

		end
	end
end


buff = {}


buff[1] = --glowing
{
	ttl = time.d,
	on_tick = nil,
	on_start = nil,
	on_remove = nil,
	on_ttl = nil,
	light = {64,0.9,0.9,1},
	sound = 39
}

buff[2] = --poisoned
{
	ttl = 64*50,
	on_tick = function (b)

		local cnt = pl.buffs[b].cnt or 1

		if game.time%32==1 then
			player_hit (cnt)

			if cnt>1 then
				pl.buffs[b].cnt = pl.buffs[b].cnt - 1
			end
		end

	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = nil,
	cnt = 1,
	sound = 40
}

buff[3] = --food poison
{
	ttl = 32*35,
	on_tick = function ( ... )
		if game.time%32==1 then
			stat_spend ("water",1)
		end
	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = nil,
	sound = 40
}

buff[4] = --farsight
{
	--ttl = time.h*4,
	ttl = time.h*5,
	on_tick = function ()
		if game.time%32==1 then
			local dist = math.dist (pl.tx, pl.ty, pl.startx, pl.starty)
			achi_set (11, dist)
		end
	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = function ( ... )
		pl.unrest = time.h
		game.fadein = 0.1
		pl.restquality = 0.25
		textwall (msg.game[20])
	end,
	sound = 39
}

buff[5] = --slowed
{
	silent = true,
	ttl = 32*5,
	on_tick = nil,
	on_start = function ()
		pl.slowed = pl.slowed - 0.3
	end,
	on_remove = function ()
		pl.slowed = pl.slowed + 0.3
	end,
	on_ttl = function ()
		pl.slowed = pl.slowed + 0.3
	end,
}

buff[6] = --haste
{

	ttl = 32*100,
	on_tick = function ( ... )
		stat_spend ("water", 0.01)
	end,
	on_start = function ()
		pl.slowed = pl.slowed + 0.5
	end,
	on_remove = function ()
		pl.slowed = pl.slowed - 0.5
	end,
	on_ttl = function ()
		pl.slowed = pl.slowed - 0.5
	end,
	sound = 39
}

buff[7] = --bleeding
{
	ttl = 32*100,
	on_tick = function ( ... )
		if game.time%64==1 then
			player_hit (1)
		end
	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = function ( ... )
		player_hit (10)
	end,
	sound = 40
}


buff[8] = --dark vision
{
	ttl = time.h*3,
	on_tick = nil,
	on_start = function ( ... )
		game.ambient = 0.24
	end,
	on_remove = nil,
	on_ttl = function ( ... )
		game.ambient = nil
	end,
}

buff[9] = --blessing
{
	ttl = time.h*3,
	on_tick = nil,
	on_start = nil,
	on_remove = nil,
	on_ttl = nil,
	sound = 39
}


buff[10] = --Meteorism (Tympanites)
{
	ttl = time.h*3,
	on_tick = nil,
	on_start = nil,
	on_remove = nil,
	on_ttl = nil,
	sound = 39

}


buff[11] = --Ketchup
{
	ttl = time.h*3,
	on_tick = nil,
	on_start = nil,
	on_remove = nil,
	on_ttl = nil,

}


buff[12] = --chilled
{
	ttl = 32*4,
	on_tick = function ( ... )
		if game.time%32==1 then
			stat_spend ('heat',1)
		end
	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = nil,
	sound = 40

}

buff[13] = --webbed
{
	ttl = 32*10,
	on_tick = function ()
		pl.xspeed = pl.xspeed + love.math.random (-1,1)
	end,
	on_start = function ()
		pl.slowed = pl.slowed - 0.4
		pl.jumpyslow = pl.jumpyslow - 0.5
	end,
	on_remove = function ()
		pl.slowed = pl.slowed + 0.4
		pl.jumpyslow = pl.jumpyslow + 0.5
	end,
	on_ttl = function ()
		pl.slowed = pl.slowed + 0.4
		pl.jumpyslow = pl.jumpyslow + 0.5
	end,
	sound = 40
}

buff[14] = --well feed
{
	ttl = 32*1000,
	on_tick = function ( ... )
		if game.time%32==1 then
			stat_recovery ('heat',0.02)
			stat_recovery ('arms',0.02)
			stat_recovery ('body',0.02)
			stat_recovery ('food',0.02)
		end
	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = function (...)
	end,
	sound = 39

}

buff[15] = --fever
{
	ttl = time.d,
	on_tick = function ( ... )
		--if game.time%32==1 then
			
			if pl.stats.arms.pc>35 then
				stat_spend ('arms',0.1)
			end
		--end
	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = function (...)
	end,
	sound = 40

}

buff[16] = --diarrhoea
{
	ttl = 32*10,
	on_tick = function ( ... )
		if game.time%32==1 then	

			
			
			
		end
	end,
	on_start = nil,
	on_remove = function (...)
		--buff[16].on_ttl ()
	end,

	on_ttl = function (...)

		pl.lastshit = game.time + time.d

		stat_spend ('filth',10)
		stat_spend ("water",10)

		if readmap (pl.tx,pl.ty,'w')==nil then
			writemap (pl.tx,pl.ty,400,'w')
		end

		writemap (pl.tx,pl.ty,200,'dr')

		if pl.stats.water.pc>35 then
			buff_add (16)
		end

	end,
	sound = 40

}

buff[17] = --dizziness
{
	ttl = time.d,
	on_tick = function ( ... )
		if game.time%32==1 and math.random (0,100)<10 then
			pl.cantclimb = true
		end
	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = function (...)
	end,
	sound = 40

}



buff[18] = --submerged
{
	ttl = 320,
	
	on_start = function ()
		pl.slowed = pl.slowed - 0.1
		pl.jumpyslow = pl.jumpyslow - 1.5
		sound_add ('splash',32)
	end,
	on_remove = function ()
		pl.slowed = pl.slowed + 0.1
		pl.jumpyslow = pl.jumpyslow + 1.5
		sound_stop ('splash')
	end,
	on_ttl = function ()
		pl.slowed = pl.slowed + 0.1
		pl.jumpyslow = pl.jumpyslow + 1.5
	end,
}


buff[19] = --holdbreath
{
	ttl = 32000,

	on_start = function ()
		sound_add ('underwater',33)
	end,

	on_remove = function ()
		sound_stop ('underwater')
	end,

	on_tick = function (b)

		local cnt = pl.buffs[b].cnt or 1

		if game.time%32==1 then
			if cnt>0 then
				pl.buffs[b].cnt = pl.buffs[b].cnt - 1
			end

			if cnt==0 then 
				buff_add (20)
			end
		end

	end,
	cnt = 10
}


buff[20] = --suffocate
{
	ttl = 32000,

	on_tick = function (b)

		if pl.buffs[19]==nil then
			buff_remove (20)
		end

		player_hit (1)

	end,
	sound = 40

}

buff[21] = --doctor ward
{
	ttl = time.d,

	on_tick = function (b)

		if (pl.buffs[21].cd or 0) < game.time then
			pl.buffs[21].cd = game.time + time.h
			player_regen (1)
		end

		

	end,
	sound = 39

}


buff[22] = --warpaint
{
	ttl = time.h,

	on_start = function ()
		pl.adddamage = (pl.adddamage or 0) + 1
		stat_spend ('filth',20)
	end,

	on_ttl = function ()
		pl.adddamage = (pl.adddamage or 0) - 1
	end,
	sound = 39

}


buff[23] = --bandaged
{
	ttl = time.h,

	on_tick = function (b)

		if game.time%100==1 then
			if pl.buffs[b].cnt>0 then 
				pl.buffs[b].cnt = pl.buffs[b].cnt - 1

				player_regen (pl.stats.body.maxhp/100)
			else
				buff_remove (23)
			end
		end

	end,

	on_ttl = function ()
		if pl.buffs[23].cnt and pl.buffs[23].cnt>0 then
			player_regen (pl.buffs[23].cnt)
		end
	end,

	cnt = 10

}


buff[24] = --good boy
{
	ttl = 500,
	on_tick = function ( ... )
			stat_recovery ('heat',0.1)
			stat_recovery ('arms',0.1)
			stat_recovery ('body',0.1)
			stat_recovery ('food',0.1)
	end,
	on_start = nil,
	on_remove = nil,
	on_ttl = function (...)
	end,
	sound = 39

}


buff[25] = --hoarding
{
	ttl = time.h*24,
	on_tick = function ( ... )
	end,
	on_start = function ()
		pl.invsize = pl.invsize + 10
	end,
	on_remove = function ()
		pl.invsize = pl.invsize - 10
	end,
	on_ttl = function (...)
		pl.invsize = pl.invsize - 10
	end,
	sound = 39

}


buff[26] = --eat shit
{
	ttl = time.h*1,
	on_tick = function ( ... )
	end,
	on_start = function ()
	end,
	on_remove = function ()
	end,
	on_ttl = function (...)
	end,
	sound = 39

}


buff[27] = --bad food
{
	ttl = time.h,

	on_tick = function (b)

		if game.time%100==1 then
			if pl.buffs[b].cnt>0 then 
				pl.buffs[b].cnt = pl.buffs[b].cnt - 1
				player_regen (1)
			else
				buff_remove (27)
			end
		end

	end,

	on_ttl = function ()

	end,

	cnt = 1

}


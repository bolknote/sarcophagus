creature_buffs = {
	[1] = --slow
	{
		ttl = 300,
		on_tick = function (mob)
		end,
		on_start = function (mob)
			mob_sct (mob,msg.combat[3],16,1.5)
			mob.speed = mob.speed / 2
			mob.speedhostile = mob.speedhostile / 2
		end,
		on_ttl = function (mob)
			mob.speed = mob.speed * 2
			mob.speedhostile = mob.speedhostile * 2
		end

	},

	[2] = --poison
	{
		ttl = 32*5,
		on_tick = function (mob,v)
			if v%32==1 and mob.hp>0 then
				mob_hit (mob.n,1)
			end
		end,
		on_start = function (mob)
			mob_sct (mob,msg.combat[4],16,1.5)
		end,
		on_ttl = function (mob)
		end

	},

	[3] = --fire
	{
		ttl = 32*5,
		on_tick = function (mob,v)
		--print (v%32)
			if v%32==1 and mob.hp>0 then
				mob_hit (mob.n,1)
			end
		end,
		on_start = function (mob)
			mob_sct (mob,msg.combat[5],16,1.5)
		end,
		on_ttl = function (mob)
		end

	},
}

function mob_buff(mob, buff, ttl)
	mob.buff = mob.buff or {}
	if mob.buff[buff]==nil then
		mob.buff[buff] = ttl or creature_buffs[buff].ttl
		creature_buffs[buff].on_start (mob)
	else
		mob.buff[buff] = mob.buff[buff] + creature_buffs[buff].ttl
	end
end

function mob_buffs_tick (mob)


	if (readmap (mob.tx, mob.ty,'de') or 0)>cf.deadfire then
		mob_buff(mob, 3)
	end

	if mob.buff then

		for k,v in pairs(mob.buff) do

			mob.buff[k] = mob.buff[k] - math.ceil (dt*10)

			creature_buffs[k].on_tick (mob, v)

			if v<0 then
				mob.buff[k] = nil
				creature_buffs[k].on_ttl (mob)
			end
		end
	end
end

function mob_sct (mob,text,add,ttl)
	add = add or 0
	ttl = ttl or 0.7
	table.insert (sct,{x=mob.x-16,y=mob.y-32-add,text=text_color(text),ttl=ttl,xs=mob.flip*-1*(love.math.random(15,30))})
end











function mob_collision_blocked(togo)
	return togo.right == 0 or togo.down == 0
		or togo.left == 0 or togo.up == 0
end

creature = {}

creature[1] = 	--slime slinger
{
	proto = 
	{
		type = 'slime',
		hostile = 1000,
		shoot = 1.5,
		speed = 20,
		speedhostile = 40,
		hp = 10,
		light = {32,0.8,0.8,1},
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		loot = {{i=44,p=5}},
		save = {},
		line = 0,
		ani_size = 2,
		z = 1,
		proj = 2,
		sound = 2
	},

	upgrades =
	{
		{'speedhostile',1,40},
		{'speedhostile',1,80},
		{'hp',1,200},
		{'shoot',-0.01,0.5},

	},

	ai = function (mob,id)
		mob_slime (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
		mob_hostile ('slime')
		
		if mobs[m].ty<pl.ty  then
			mobs[m].stick = nil
		end
	end,
}


function mob_slime(mob,id)

	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then

		if mob.stick~='down' then 
			mob.stick = nil 
			mob.d = mob_turn (mob.d,0)
		else	
			ani_setstatus (mob,'die',true)
			if mob.ani_frame == 5 and mob.ani_frametime>2 then
				if mob.loot then
					inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
				end
				mob_destory(id,true)
				return
			end
		end

	end

	--sleeping
	mob.sleep =  mob.sleep or 0
	if mob.sleep>0 then 
		mob.sleep = mob.sleep - dt
		ani_setstatus (mob,'sleep')
		return true
	else
		ani_setstatus (mob,'walk')
	end

	-- check every 1px
	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end

	if mob.delta >= 1 or mob.stick == nil then

	if love.math.random (0,100+(mob.n*5))<15 then return end

		--dehostile
		if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
		mob_buffs_tick (mob)

		local step = math.floor (mob.delta)
		mob.delta = 0

		--eating
		if (mob.save.hostile==nil or mob.save.hostile==0) and mob.save.eating then

			local i = inv_ground_find_i(mob.tx,mob.ty,{37,3,15})

			if i then
				local o = world[mob.ty][mob.tx].i[i]

				if o then
					if o.t>0 then
						o.t = o.t - item[o.i].ttl*0.003
						return
					else
						inv_ground_remove (mob.tx,mob.ty,i)
						mob.save.ate = (mob.save.ate or 0) + 1

						if mob.save.ate > 10 and game.time>mob.birth+time.d then

							achi_add (31,1)
							local m = mob_create (mob.tx,mob.ty,1)
							inv_ground_add (mob.tx,mob.ty,item_make(183))
							mob.save.ate = 0
							mob.birth = game.time

						end

					end
				end
			end

			mob.save.eating = nil

		end

		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then

			mob.line = mob.line + 1

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist+3 then
				mob_save (mob.tx,mob.ty,id)
				return
			end

			mob.txo = mob.tx
			mob.tyo = mob.ty

			local b = readmap (mob.tx,mob.ty,'b')

			-- eat clover
			if b == 36 and (love.math.random (0,100)<10 or mob.save.ate==nil) then
				writemap (mob.tx,mob.ty,0)
				inv_ground_add (mob.tx,mob.ty,item_make(3))
			end

			if b == 5 or b == 6 or b == 7 then -- remember glowing tree
				mob.save.flip = 0
			end

			mob.save.flip = (mob.save.flip or 0) - 1

			-- flip on spiny
			if (b == 95 or b == 20) and mob.line>2 then
				mob_flip (mob)
				mob.line=0
			end

			-- start eating
			local o = inv_ground_find_i(mob.tx,mob.ty,{37,3,15})
			if o and readmap (mob.tx,mob.ty,'b')~=124 and mob.stick then
				mob.save.eating = true
				return
			end

		end

		--sleep on top
		if mob.stick == 'up' and love.math.random (0,100)==1 then
			mob.sleep = mob.sleeptime
		end


		--kicked
		if mob.deltax then
			local points = {}
			table.insert (points, {x=mob.x,y=mob.y,mode={}})
			local togo = tocollide (points)

			local r = px2tile (mob.x + mob.deltax, mob.y)
			local c = maptile(r.x,r.y)

			if c==0 then
				mob.x = mob.x + mob.deltax 
				mob.deltax = nil
			end
		end



		mob_crawling (mob,step)


		--if mob.stick ~= nil then

			if mob.save.hostile==nil then

				if mob.save.flip and mob.save.flip < -32 then

					mob_flip (mob)
					mob.save.flip = 0
				 	
				end

			end

			if mob.save.hostile then

			 	if ani_getstatus (mob,'uncont')==nil then

				 	if math.abs(mob.ty-pl.ty)<5 and mob.flip == 1 and mob.tx > pl.tx then
				 		mob_flip (mob)
				 	end

				 	if math.abs(mob.ty-pl.ty)<5 and mob.flip == -1 and mob.tx < pl.tx then
				 		mob_flip (mob)
				 	end
				end


				if mob.hp>0 and math.abs(mob.ty-pl.ty)<5 and cooldown (mob,'shoot',true,2) and mob.stick == 'down' and mob.d == 0 then

				 	ani_setstatus (mob,'attack')
				 	sound_add ("mobattack_"..id, 3, {x = mob.tx, y = mob.ty})

				end

				if mob.ani_status == 'attack' and mob.ani_frame == 3 and cooldown (mob,'shoot',nil,2) then

					 	local d = pl.x - mob.x
					 	local d2 = pl.y - mob.y

					 	mob.shootspeedy = 200
					 	mob.shootspeedx = d * 1.2 - d2

						 	--if mob.shootspeedx<600 and mob.shootspeedx>-600 then

						 	 	local m =
									{
										x = mob.x-8,
										y = mob.y-20,
										xspeed = mob.shootspeedx,
										yspeed = mob.shootspeedy*-1,
										proj = 2,
										bounce = {1,1,1,1},
									}

									if projes[mob.proj] then
										m.light = projes[mob.proj].light
									end

									proj[next_numeric_id(proj)] = m

							--end

				end

			end
			


		
		--end	
		
		coord_screen2true (mob)

	end
end


















creature[2] = 
{
	proto = 
	{
		type = 'spider',
		speed = 40,
		speedhostile = 80,
		attack = 2, -- attack cd
		dmg = 2,
		hp = 10,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		sleeptime = 300,
		loot = {{i=103,p=5}},
		q = {}, -- last moves
		line = 0,
		qcnt = 0, -- last moves cnt
		hostile = 1000,
		save = {},
		z = 1,
		sound = 12,

		shootspeedx = 400,
		shootspeedy = 200,
		proj = 13,
		shoot = 5,
		hasweb = 0 --is shooting web

	},

	ai = function (mob,id)
		mob_spider (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

	upgrades =
	{
		{'speedhostile',1,120},
		{'hp',1,200},
		{'attack',-0.05,0.5},
		{'dmg',1,10},
		{'hasweb',1,1,5}
	},

}





function mob_spider (mob,id)
	
	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then
		--mob.stick = nil
		ani_setstatus (mob,'die',true)
		if mob.ani_frame == 6 and mob.ani_frametime>2 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end
			mob_destory(id,true)
			return
		end
		--return
	end

	--kicked
	-- if mob.deltax then
	-- 	mob.x = mob.x + mob.deltax 
	-- 	mob.deltax = nil
	-- end


	--slide
	if mob.slide then
		ani_setstatus (mob,'slide')
	else
		--sleeping
		if mob.sleep>0 then 

			if mob.save.hostile and mob.tx == pl.tx and mob.d == 180 then
				mob.slide = 32*10
				mob.sleep = 0
			end

			--inv found
			--writemap (mob.tx,mob.sleepcheck,32)
			if readmap (mob.tx,mob.sleepcheck,'i') then
				mob.slide = 32*20
				mob.sleep = 0
			end

			mob.d = mob_turn (mob.d,180)
			mob.sleep = mob.sleep - dt
			ani_setstatus (mob,'sleep')
			return true
		else
			ani_setstatus (mob,'walk')
		end
	end

	if mob.sleep<0 then
		mob.slide = 32*5
		mob.sleep = 0
	end

	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end

	-- check every 1px
	if mob.delta < 1 and mob.ani_status ~= 'die' then return end
	local step = math.floor (mob.delta)
	mob.delta = 0

	--dehostile
	if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
	mob_buffs_tick (mob)



	if mob.dir == nil then
		mob.dir = 'up'
	end

	local x = colliders['mob_'..id].x - vi.x
	local y = colliders['mob_'..id].y - vi.y
	local w = colliders['mob_'..id].w - vi.x
	local h = colliders['mob_'..id].h - vi.y

	local points = {}
	table.insert (points, {x=x,y=y,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=w,y=y,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=w,y=h,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=x,y=h,mode={up = true, down = true, left = true, right = true}})
	local togo = tocollide (points)

	if mob.ani_status == 'die' and mob.ani_frame > 2 then
		mob.d = mob_turn (mob.d,0)
		mob.y = mob.y + math.min(5,togo.down)
		coord_screen2true (mob)
		return
	end


	if mob.slide then
		mob.slide = mob.slide - 1
		if mob.slide<0 then mob.slide = nil end
		mob.y = mob.y + math.min(step*3,togo.down)

		if readmap (mob.tx, mob.ty, 'b') == 0 then
			writemap (mob.tx, mob.ty, 87)
		end

		if readmap (mob.tx, mob.ty-1, 'b') == 87 then
			writemap (mob.tx, mob.ty-1, 86)
		end

		if togo.down==0 then
			mob.slide = nil
		end

		coord_screen2true (mob)
		return
	end


	--check each tile
	if mob.txo~=mob.tx or mob.tyo~=mob.ty then

		--stuck fix
		if maptile (mob.tx,mob.ty,'col')==1 then
			mob.y = mob.y+32
			coord_screen2true (mob)
			return
		end
		--save mob
		local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
		if dist>vi.mobspawndist+3 then

			mob_save (mob.tx,mob.ty,id)
			return

		end

		--eating meat
		local notnew

		local i = inv_ground_find_i(mob.tx, mob.ty, {14,44})  

		if i then

			if cd_passed (mob,'eating',3) == nil then
				ani_setstatus (mob,'attack')
				notnew = true
			else
				achi_add (27,1)
				inv_ground_remove (mob.tx, mob.ty,i)
				inv_ground_add (mob.tx, mob.ty,item_make(90))
				inv_ground_add (mob.tx, mob.ty,item_make(90))
				inv_ground_add (mob.tx, mob.ty,item_make(90))
				
				mob.save.ate = (mob.save.ate or 0) + 1

			end

		end


		if notnew == nil then
			mob.txo = mob.tx
			mob.tyo = mob.ty

			local q = mob.tx.."_"..mob.ty
			mob.q[q] = mob.q[q] or 0
			mob.q[q] = mob.q[q] + 1

			mob.qcnt = mob.qcnt + 1

			mob.nextile = mob.nextile or 0
			mob.nextile = mob.nextile + 1
		end

	end


	mob.line = mob.line + 1


	if mob.qcnt>100 then
		mob.qcnt = 0
		mob.q = {}
	end

	local pr = 
	{
		up = mob.q[mob.tx.."_"..(mob.ty-1)] or 0,
		left = mob.q[(mob.tx-1).."_"..mob.ty] or 0,
		right = mob.q[(mob.tx+1).."_"..mob.ty] or 0,
		down = mob.q[mob.tx.."_"..(mob.ty+1)] or 0,
	}


	if mob.save.ate then

		if mob.tx > pl.tx then pr.left = pr.left * (1-mob.save.ate*0.02) end
		if mob.tx < pl.tx then pr.right = pr.right * (1-mob.save.ate*0.02) end
		if mob.ty > pl.ty then pr.up = pr.up * 0.4 - (1-mob.save.ate*0.02) end
		if mob.ty < pl.ty then pr.down = pr.down * (1-mob.save.ate*0.02) end

	end

	if mob.hunger then
		mob.findx, mob.findy = inv_ground_find_r (mob.tx, mob.ty, {14,44}, 40)
		mob.hunger = nil
	end

	if mob.save.hostile==nil and mob.findx then

		mob.tryfinding = (mob.tryfinding or 0) + 1

		if mob.tx > mob.findx then pr.left = pr.left * 0.4 - 1 end
		if mob.tx < mob.findx then pr.right = pr.right * 0.4 - 1 end
		if mob.ty > mob.findy then pr.up = pr.up * 0.4 - 1 end
		if mob.ty < mob.findy then pr.down = pr.down * 0.4 - 1 end

	end

	if mob.tryfinding and mob.tryfinding>1000 then
		mob.findx = nil
		mob.hunger = nil
	end

	if mob.findx==mob.tx and mob.findy==mob.ty then
		mob.findx = nil
	end

	local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)

	if mob.save.hostile then

		if (mob.hasweb or 0)>0 and mob.save.hostile and dist>1 and dist<5 then

			if cooldown (mob,'shoot',nil,2) then


				local xth = pl.x - mob.x
			 	local yth = pl.y - mob.y
			 	local ya = math.cos (math.atan2 (yth,xth))
				local ya2 = math.sin (math.atan2 (yth,xth))


				local m =
				{
					x = mob.x-8,
					y = mob.y-20,
					xspeed = 200 * (ya),
					yspeed = 100 * (ya2),
					yspeed_dim = 200,
					proj = mob.proj,
					bounce = {0,0,0,0}
				}

				if projes[mob.proj] then
					m.light = projes[mob.proj].light
				end

				proj[next_numeric_id(proj)] = m

			end
		end


		if mob.tx > pl.tx then pr.left = pr.left * 0.4 - 1 end
		if mob.tx < pl.tx then pr.right = pr.right * 0.4 - 1 end
		if mob.ty > pl.ty then pr.up = pr.up * 0.4 - 1 end
		if mob.ty < pl.ty then pr.down = pr.down * 0.4 - 1 end

		if mob.save.hostile<game.time then mob.save.hostile = nil end

		if math.abs (mob.truex-pl.truex)<20 and math.abs (mob.truey-pl.truey)<25 and cooldown (mob,'attack') then
			ani_setstatus (mob,'attack')
		end

		if mob.attacked==nil and mob.ani_status == 'attack' and mob.ani_frame == 2 and math.abs (mob.truex-pl.truex)<20 and math.abs (mob.truey-pl.truey)<25 then
			buff_add (2, 'add')
			player_hit (mob.dmg, mob)
			mob.attacked = true
		end

		if mob.ani_status ~= 'attack' then
			mob.attacked = nil
		end

	end

	
	local xp = 0
	local yp = 0

	if togo.right == 0 then 
		pr.right = nil 
		mob.q[(mob.tx+1).."_"..mob.ty]=100000 
	end
	
	if togo.left == 0 then 
		pr.left = nil 
		mob.q[(mob.tx-1).."_"..mob.ty]=100000 
	end
	
	if togo.up == 0 then 
		pr.up = nil 
		mob.q[mob.tx.."_"..(mob.ty-1)] = 100000
	end
	
	if togo.down == 0 then 
		pr.down = nil 
		mob.q[mob.tx.."_"..(mob.ty+1)] = 100000
	end

		

	local min = 100000
	local dir = ''

	for k,v in pairs(pr) do

		if v<min and k~=mob.dir then
			mob.qcnt = mob.qcnt + 0.1 --stuck fix
			min = v
			dir = k
		end

		if v==min and k~=mob.dir and love.math.random (0,100)<50 then
			min = v
			dir = k
		end

	end

	--

	--sleep start
	if mob.save.hostile==nil and togo.up<4 and mob.txl==14 and readmap (mob.tx,mob.ty,'b')==0 then

		mob.sleep = 600
		--mob.sleep = 6


		writemap (mob.tx,mob.ty,85)
		mob.hunger = (mob.hunger or 0) + 1

		if mob.save.ate and mob.save.ate>1 then
			writemap (mob.tx,mob.ty,178) --lay eggs
			mob.save.ate = nil
		end

		mob.qcnt = 0
		mob.q = {}

		mob.sleepcheck = mob.ty+1

		while maptile (mob.tx,mob.sleepcheck,'col')==0 do
			mob.sleepcheck = mob.sleepcheck + 1
		end

		mob.sleepcheck = mob.sleepcheck - 1
	end


	if (pr[mob.dir]==nil or ((mob.nextile and mob.nextile>1) and mob.line>16)) then
		mob.dir = dir
		mob.line = 0
		mob.nextile = nil
	end



	if ani_getstatus (mob,'uncont')==nil then

		if mob.dir == 'right' then mob.x = mob.x + math.min(step,togo[mob.dir]) end
		if mob.dir == 'left' then mob.x = mob.x - math.min(step,togo[mob.dir]) end
		if mob.dir == 'up' then mob.y = mob.y - math.min(step,togo[mob.dir])  end
		if mob.dir == 'down' then mob.y = mob.y + math.min(step,togo[mob.dir]) end

		if mob.dir == 'up' then mob.d = mob_turn (mob.d,0) end
		if mob.dir == 'right' then mob.d = mob_turn (mob.d,90) end
		if mob.dir == 'down' then mob.d = mob_turn (mob.d,180) end
		if mob.dir == 'left' then mob.d = mob_turn (mob.d,270) end

	end

	coord_screen2true (mob)




end















creature[3] = 	
{
	proto = 
	{
		type = 'worm', --small
		toid = 6,
		speed = 8,
		hp = 1,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		ani_size = 1,
		z = 1,
		loot = {{i=279,p=5}},
	},

	ai = function (mob,id)
		mob_worm (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

	upgrades =
	{
		{'speed',1,80},
		{'hp',1,200},
	},

}


function mob_worm (mob,id)

	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end
			mob_destory(id, true)
			return
	end

	if mob.ani_status == 'gone' and mob.ani_frame == 5 then
		fertilize (mob.tx, mob.ty+1, 20)
		mob_destory(id)
		return
	end

	-- check every 1px
	mob.delta = mob.delta + mob.speed*dt
	if mob.delta >= 1 or mob.stick == nil then

		mob_buffs_tick (mob)
		if love.math.random (0,100+id)<15 then return end

		local step = math.floor (mob.delta)
		mob.delta = 0

		mob.save.moved = (mob.save.moved or 0) + 1


		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then


			local notnew

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist+3 then

				mob_save (mob.tx,mob.ty,id)
				return

			end

			--eating Foliage
			local i = inv_ground_find_i(mob.tx, mob.ty, 3)

			if i then
				if cd_passed (mob,'eating',10) == nil then
					ani_setstatus (mob,'eat')
					notnew = true
				else
					inv_ground_remove (mob.tx, mob.ty,i)
					inv_ground_add (mob.tx, mob.ty, item_make(59)) --fertilizer

					mob.save.ate = (mob.save.ate or 0) + 1
					ani_setstatus (mob,'walk')
				end
			else
				ani_setstatus (mob,'walk')
			end

			if notnew == nil then
				mob.txo = mob.tx
				mob.tyo = mob.ty
			end


			-- flip on spiny
			local b = readmap (mob.tx,mob.ty,'b')
			if b == 95 or b == 20 then
				mob_flip (mob)
			else
				-- burrowing
				if mob.stick == 'down' and mob.d == 0 and mob.save.moved and mob.save.moved>100 and mob.ani_frame == 3 
				and in_array ({102, 1,2,9,12,13},readmap (mob.tx,mob.ty+1,'b')) then
					ani_setstatus (mob,'gone')
				end
			end
		
		end




		
		-- growing
		if mob.ani_size==1 and mob.save.ate and mob.save.ate>5 then
			mob_replace (id,4)
		end

		if mob.save.ate and mob.save.ate>10 then
			inv_ground_add (mob.tx, mob.ty, item_make(20)) --shit
			--mob.save.ate = 0
			mob_create (mob.tx, mob.ty,3)
			mob_create (mob.tx, mob.ty,3)
			mob_destory(id)
			return
		end


		mob_crawling (mob,step)

				if mob.stick == 'up' then 
					mob.stick = nil 
					mob.flip = mob.flip * -1
				end
		
		coord_screen2true (mob)

	end
end


creature[4] = --big worm
{
	proto =
	{	
		type = 'worm',
		toid = 99,
		speed = 20,
		hp = 10,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		loot = {{i=44,p=5}},
		ani_size = 2,
		z = 1,
	},

	ai = function (mob,id)
		mob_worm (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

	upgrades =
	{
		{'speed',1,80},
		{'hp',1,200},
	},

}



















creature[5] = 	
{
	proto =
	{
		type = 'marsh',
		charge = 0,
		supercharge = 0,
		superchargemax = 2,
		speed = 40,
		speedhostile = 40,
		attack = 2, -- attack cd
		dmg = 1,
		--toid = 18
		hp = 1,
		--light = {32,0.8,0.8,1},
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		sleeptime = 300,
		loot = {
			--{i=115,p=5},
			{i=263,p=2}
		},
		q = {}, -- last moves
		line = 0,
		qcnt = 0, -- last moves cnt
		hostile = 1000,
		save = {},
		light = {32,0.5,0.5,0},
		ani_size=2,
		z = 1,
		passthu = nil,

	},

	upgrades =
	{
		{'speedhostile',1,90},
		{'superchargemax',1,40,10},
		{'hp',1,20},
		{'attack',-0.01,0.5},
		{'dmg',0.1,2},
		{'passthu',1,1,5}
	},

	ai = function (mob,id)
		mob_marsh (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

}

function mob_marsh (mob,id)
	
	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then
		--mob.stick = nil

		mob.xspeed = 0
		mob.yspeed = love.math.random (1,2)

		ani_setstatus (mob,'die',true)
		lines[id] = nil
		
		if mob.ani_frame == 8 and mob.ani_frametime>0.15 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end

			
			mob_destory(id, true)
			return
		end
		--return
	end

	--kicked
	if mob.deltax then
		mob.x = mob.x + mob.deltax 
		mob.deltax = nil
	end


	if mob.xspeed==nil or mob.xspeed==0 or mob.yspeed==0 then
		mob.xspeed = love.math.random (-10,10)/5
		mob.yspeed = love.math.random (-10,10)/5
		mob.xy = -1
		mob.sin = love.math.random (5,30)
		return
	end


	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end

	-- check every 1px
	if mob.delta < 1 and mob.ani_status ~= 'die' then return end
	local xstep = math.floor (mob.delta * mob.xspeed)
	local ystep = math.floor (mob.delta * mob.yspeed)
	mob.delta = 0
	mob.line = mob.line + 0.1

	--dehostile
	if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
	mob_buffs_tick (mob)

	--check each tile
	local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
	if mob.txo~=mob.tx or mob.tyo~=mob.ty then


	--save mob
	--	local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
	
		if dist>vi.mobspawndist+3 then

			mob_save (mob.tx,mob.ty,id)
			return

		end

		
		mob.txo = mob.tx
		mob.tyo = mob.ty

		--mob.line = mob.line + 1


			if dist<12 and (dist>7 or mob.save.hostile) then

				if mob.tx > pl.tx then mob.xspeed = -1 end
				if mob.tx < pl.tx then mob.xspeed = 1 end
				if mob.ty > pl.ty then mob.yspeed = -1 end
				if mob.ty < pl.ty then mob.yspeed = 1 end

				if math.abs (mob.tx-pl.tx)>math.abs(mob.ty-pl.ty) then
					mob.xy = 1
				else
					mob.xy = -1
				end

			end


	end




	if mob.line>5 then
		mob.sin = love.math.random (5,30)
		mob.line = 0
	end


	if dist<4 and mob.hp>0 and (mob.save.hostile or pl.buffs[1]==nil) then


		mob.charge = mob.charge+dt

		if mob.charge>0.1 and mob.charge<0.2 then
			if mob.supercharge==0 then
				buff_add (5,'keep')
			end
		end

		if cooldown (mob,'attack') then
			player_hit (mob.dmg+mob.supercharge, mob)

			if (mob.supercharge) < (mob.superchargemax or 2) then
				mob.supercharge = mob.supercharge + 1
			end

		end


		local x = math.ceil ((pl.x - mob.x)/4)
		local y = math.ceil ((pl.y - mob.y)/4)
		
		lines[id] = { 
		mob.x, mob.y,
		mob.x+x+(love.math.random (-10,10)*0.1*x),mob.y+y+(love.math.random (-10,10)*0.1*y),
		mob.x+x+x+(love.math.random (-20,20)*0.1*x),mob.y+y+y+(love.math.random (-20,20)*0.1*y),
		pl.x, pl.y
		}

	else
		lines[id] = nil
		mob.charge = 0
		mob.supercharge = 0

	end


	local x = colliders['mob_'..id].x - vi.x
	local y = colliders['mob_'..id].y - vi.y
	local w = colliders['mob_'..id].w - vi.x
	local h = colliders['mob_'..id].h - vi.y

	local points = {}
	table.insert (points, {x=x,y=y,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=w,y=y,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=w,y=h,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=x,y=h,mode={up = true, down = true, left = true, right = true}})
	local togo = tocollide (points)

	if mob.save.hostile and mob.passthru then
		togo.up = 10
		togo.down = 10
		togo.left = 10
		togo.right = 10
	end

	if ani_getstatus (mob,'uncont')==nil then

		if mob.save.hostile==nil then

			if mob.xy==-1 then
				xstep = math.cos (mob.y/mob.sin)*2
			else
				ystep = math.cos (mob.x/mob.sin)*2
			end

		end



		if mob.xspeed>0 and togo.right<5 then mob.xspeed = mob.xspeed*(-1) mob.xy = mob.xy*(-1) return end
		if mob.xspeed<0 and togo.left<5 then mob.xspeed = mob.xspeed*(-1)  mob.xy = mob.xy*(-1) return end
		if mob.yspeed>0 and togo.down<5 then mob.yspeed = mob.yspeed*(-1) mob.xy = mob.xy*(-1) return end
		if mob.yspeed<0 and togo.up<5 then mob.yspeed = mob.yspeed*(-1)  mob.xy = mob.xy*(-1) return end

		if xstep>0 then
			mob.x = mob.x + math.min(xstep,togo.right)
		else
			mob.x = mob.x + math.max(xstep,togo.left*-1)
		end

		if ystep>0 then
			mob.y = mob.y + math.min(ystep,togo.down)
		else
			mob.y = mob.y + math.max(ystep,togo.up*-1)
		end

		if mob_collision_blocked(togo) and mob.line>5 then
				mob.xspeed = love.math.random (-10,10)/5
				mob.yspeed = love.math.random (-10,10)/5
				mob.line = 0
				
		end

	end

	coord_screen2true (mob)




end






creature[6] = 	
{
	proto =
	{
		type = 'invader',
		speed = 20,
		defspeed = 20,
		speedhostile = 80,
		shoot = 0.5,
		attack = 2, -- attack cd
		hp = 1,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		sleeptime = 300,
		loot = {{i=114,p=5}},
		line = 0,
		hostile = 1000,
		save = {},
		light = {32,0,0.5,0},
		ani_size=2,
		proj = 4,
		nospin = true,
		dmg = 13,
	},

	ai = function (mob,id)
		mob_invader (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

	upgrades =
	{
		{'speedhostile',1,90},
		{'superchargemax',1,40,10},
		{'hp',1,200},
		{'attack',-0.05,1},
		{'dmg',0.1,3},
	},

}




function mob_invader (mob,id)
	
	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then
		ani_setstatus (mob,'die',true)
		
		if mob.ani_frame == 3 and mob.ani_frametime>0.2 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end
			
			mob_destory(id, true)
			return
		end
	end

	--kicked
	if mob.deltax then
		mob.x = mob.x + mob.deltax 
		mob.deltax = nil
	end


	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end


	-- check every 1px
	if mob.delta < 1 and mob.ani_status ~= 'die' then return end

	mob_buffs_tick (mob)

	local step
	if mob.dir == 'left' or mob.dir == 'right' then
		step = (mob.delta+mob.txl/6*dt*mob.speed)
	else
		step = (mob.delta+mob.tyl/6*dt*mob.speed)
	end

	--step = math.floor (mob.delta)
	mob.delta = 0
	
	--check each tile
	if mob.txo~=mob.tx or mob.tyo~=mob.ty then


		-- save to map
		local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
		if dist>vi.mobspawndist+3 then

			mob_save (mob.tx,mob.ty,id)
			return

		end

		if mob.speed<mob.defspeed*2 then
			mob.speed = mob.speed + 0.25
		end

		mob.txo = mob.tx
		mob.tyo = mob.ty

		local m = collide_check ('mob_'..id,'player')
		if m then
			player_hit (mob.dmg, mob)
		end

		
		if mob.dir == 'left' or mob.dir == 'right' then

			local m =
			{
				x = mob.x+18,
				y = mob.y+30,
				xspeed = love.math.random (-20,20),
				yspeed = -1,
				proj = mob.proj
			}

			proj[next_numeric_id(proj)] = m
		end

		mob.dir = mob.dir or 'right'

		local down = 0
		for i=mob.ty+1,mob.ty+10 do
			
			local t = readmap (mob.tx,i,'b')
			if t==0 then
				down = down + 1
			else 
				break
			end
		end



		if mob.dir=='up' then
			if (maptile(mob.tx,mob.ty-1,'col') or 0)~=0 or down>6 then
				mob.dir = 'right'
			end
		end

		if down>7 and mob.dir == 'right' then
			mob.dir = 'downleft'
			return
		end

		if down>7 and mob.dir == 'left' then
			mob.dir = 'downright'
			return
		end


		if mob.dir=='right' and mob.tx>pl.tx+6 and (maptile(mob.tx,mob.ty+1,'col') or 0)==0 then
			mob.dir = 'downleft'
			return
		end

		if mob.dir=='left' and mob.tx<pl.tx-6 and (maptile(mob.tx,mob.ty+1,'col') or 0)==0 then
			mob.dir = 'downright'
			return
		end


		if mob.dir == 'downleft' then
			mob.dir = 'left'
		end

		if mob.dir == 'downright' then
			mob.dir = 'right'
		end


		if down<1 then
			mob.line = mob.line + 1
		end

		if mob.dir=='right' then
			if (maptile(mob.tx+1,mob.ty,'col') or 0)~=0 then

			if down<1 and mob.line>7 then
				mob.dir = 'up'
				mob.line = 0
				return
			end
				
				if (maptile(mob.tx,mob.ty+1,'col') or 0)==0 then
					mob.dir = 'downleft'
				else
					mob.dir = 'left'
				end

				return
			end
		end

		if mob.dir=='left' then
			if (maptile(mob.tx-1,mob.ty,'col') or 0)~=0 then

				if down<1 and mob.line>7 then
					mob.dir = 'up'
					mob.line = 0
					return
				end
				
				if (maptile(mob.tx,mob.ty+1,'col') or 0)==0 then
					mob.dir = 'downright'
				else
					mob.dir = 'right'
				end

				return
			end
		end

	

		mob.line = mob.line + 1



	end


	if mob.save.hostile then
	end


	if ani_getstatus (mob,'uncont')==nil then

		if mob.dir == 'right' then mob.x = mob.x + step end
		if mob.dir == 'left' then mob.x = mob.x - step end
		if mob.dir == 'up' then mob.y = mob.y - step  end
		if mob.dir == 'down' or mob.dir == 'onedown' 
		or mob.dir == 'downleft' or mob.dir == 'downright'
		then mob.y = mob.y + step end

	end



	coord_screen2true (mob)

end







creature[7] = --frostie
{
	proto =
	{
		type = 'frostie',
		--toid = 18,
		speed = 7,
		speedhostile = 15,

		shootspeedx = 500,
		shootspeedy = 150,

		shoot = 1.5,
		proj = 9,
		hp = 10,
		d = 0, -- degrees

		hostile = 1000,
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		save = {},
		line = 0,
		loot = {
			{i=40,p=10},
			{i=344,p=1}
		},
		--light = {25,0.5,0.5,0.8}
		z = 1,
		sound = 37,
	},

	upgrades =
	{
		{'speedhostile',1,30},
		{'hp',1,200},
		{'shoot',-0.01,0.5},
	},

	ai = function (mob,id)
		mob_frostie (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,
}


function mob_frostie (mob,id)

	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then

		if mob.stick~='down' then 
			mob.stick = nil 
			mob.d = mob_turn (mob.d,0)
		else			


			ani_setstatus (mob,'die',true)
			if mob.ani_frame == 7 and mob.ani_frametime>2 then


				if mob.loot then
					inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
					inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
				end

				mob_destory(id, true)

				return
		end

	end
	end

	-- check every 1px
	mob.delta = mob.delta + mob.speed*dt
	if mob.delta >= 1 or mob.stick == nil then


		--fire damage
		if (readmap (mob.tx, mob.ty, 'de') or 0)>100 then mob_hit (id,1) end


		if love.math.random (0,100+id)<15 then return end

		--dehostile
		if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
		mob_buffs_tick (mob)
		

		local step = math.floor (mob.delta)
		mob.delta = 0

		mob.save.moved = (mob.save.moved or 0) + 1

		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then


			mob.line = (mob.line or 0) + 1

			local notnew

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist+3 then

				mob_save (mob.tx,mob.ty,id)
				return

			end

			if notnew == nil then
				mob.txo = mob.tx
				mob.tyo = mob.ty
			end


			-- flip on spiny
			-- local b = readmap (mob.tx,mob.ty,'b')
			-- if b == 95 or b == 20 then
			-- 	mob_flip (mob)
			-- end


			if mob.stick then

				local lo = {
					left = {-1,0},
					up = {0,-1},
					right = {1,0},
					down = {0,1},
				}

				lo = lo[mob.stick]

				local under = readmap (mob.tx+lo[1], mob.ty+lo[2],'b')
				--dump (under)

				local freezable = {1,2,12,13,102,99}

				--writemap (mob.tx+lo[1], mob.ty+lo[2],48)

				if in_array (freezable, under) and mob.line>1 then

					writemap (mob.tx+lo[1], mob.ty+lo[2],48)
					--writemap (mob.tx+lo[1], mob.ty+lo[2],nil,'wt')
					
					mob_flip (mob)
					mob.line = 0

				end
		


			end


		
		end


		if mob.save.hostile then

			if math.abs(mob.ty-pl.ty)<5 and cooldown (mob,'shoot',true,2) and mob.stick == 'down' and mob.d == 0 then

			 	ani_setstatus (mob,'attack')

			end


			if mob.ani_status == 'attack' and mob.ani_frame == 3 and cooldown (mob,'shoot') then

			
				--if cooldown (mob,'shoot',nil,2) then


					 	local d = pl.x - mob.x
					 	local d2 = pl.y - mob.y

					 	mob.shootspeedx = d * 1.5 - d2

						 	if mob.shootspeedx<600 and mob.shootspeedx>-600 then

						 	 		local m =
									{
										x = mob.x-8,
										y = mob.y-20,
										xspeed = mob.shootspeedx-love.math.random (0,70),
										yspeed = mob.shootspeedy*-1,
										proj = mob.proj,
										bounce = {1,1,1,1}
									}

									local m2 =
									{
										x = mob.x-8,
										y = mob.y-20,
										xspeed = mob.shootspeedx+love.math.random (0,70),
										yspeed = (mob.shootspeedy+love.math.random (0,10))*-1,
										proj = mob.proj,
										bounce = {1,1,1,1}
									}

									local m3 =
									{
										x = mob.x-8,
										y = mob.y-30,
										xspeed = mob.shootspeedx,
										yspeed = (mob.shootspeedy+love.math.random (0,100))*-1,
										proj = mob.proj,
										bounce = {1,1,1,1}
									}

									if projes[mob.proj] then
										m.light = projes[mob.proj].light
									end

									proj[next_numeric_id(proj)] = m
									proj[next_numeric_id(proj)] = m2
									proj[next_numeric_id(proj)] = m3


							end

				end

		end



		if mob.stick and mob.dir then

			local c = mob.dir.."-"..mob.stick

			if c == 'down-right' or c == 'down-left' then
				mob.stick = nil
				mob.x = mob.x + mob.flip*8
			end

		end

		mob_crawling (mob,step)
		
		coord_screen2true (mob)

	end
end














creature[8] = --snake
{
	proto = 
	{
		type = 'snake',
		attack = 1, -- attack cd
		dmg = 1,
		--toid = 18,
		speed = 30,
		speedhostile = 50,
		hp = 5,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		save = {},
		line = 0,
		loot = {{i=165,p=5}},
		z = 1,
		hostile = 1000,
	},

	upgrades =
	{
		{'speedhostile',1,90},
		{'hp',1,200},
		{'attack',-0.05,0.5},
		{'dmg',0.1,10},
	},

	ai = function (mob,id)
		mob_snake (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,
}



function mob_snake (mob,id)

	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then
		ani_setstatus (mob,'die',true)
		if mob.ani_frame == 5 and mob.ani_frametime>2 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end
			mob_destory(id, true)
			return
		end
	end


	if (math.abs(mob.tx-pl.tx))>20 and mob.stick=="down" then
		ani_setstatus (mob,'sleep')
	end

	if mob.ani_status == 'sleep' and  (math.abs(mob.tx-pl.tx))<4 then
		ani_setstatus (mob,'walk')
	end


	-- check every 1px
	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end

	if mob.delta >= 1 or mob.stick == nil then

		if love.math.random (0,100+id)<15 then return end

		--dehostile
		if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
		mob_buffs_tick (mob)
		

		local step = (mob.delta)
		mob.delta = 0

		mob.save.moved = (mob.save.moved or 0) + 1

		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then

			mob.attacked = reduce (mob.attacked)

			if math.abs(mob.tx-pl.tx)<6 then
				mob.save.hostile = game.time + mob.hostile
			else
				mob.save.hostile = nil
			end

			mob.line = (mob.line or 0) + 1

			local notnew

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist+3 then

				mob_save (mob.tx,mob.ty,id)
				return

			end
	
		end



		if mob.stick and mob.dir then --and mob.d == 0

			local c = mob.dir.."-"..mob.stick

			if c == 'down-right' or c == 'down-left' then
				mob.stick = nil
				mob.dir = nil
				mob.x = mob.x + mob.flip*16
			end
			
			if mob.dir == 'up' then
				step = step * 4
			end
		end



		if ani_getstatus (mob,'uncont')==nil then

		 	local flip = false

		 	 	if (math.abs(mob.ty-pl.ty)<5 and mob.flip == 1 and mob.tx > pl.tx)
				or
			 	(math.abs(mob.ty-pl.ty)<5 and mob.flip == -1 and mob.tx < pl.tx)
			 	then flip = true end

			 	if mob.attacked and flip then flip = not flip end
			 	if flip then mob_flip (mob) end

		end


		mob_crawling (mob,step)

		if math.abs (mob.truex-pl.truex)<20 and math.abs (mob.truey-pl.truey)<30 then
			if cooldown (mob,'attack') then 
				mob.attacked = nil
				ani_setstatus (mob,'attack')
			end

		end

		if mob.attacked==nil and mob.ani_status == 'attack' and mob.ani_frame == 2 and math.abs (mob.truex-pl.truex)<25 and math.abs (mob.truey-pl.truey)<30 then
			buff_add (2, 'add', 2)
			player_hit (mob.dmg, mob)
			mob.attacked = love.math.random (10,30)
		end

		
		coord_screen2true (mob)

	end
end






















creature[9] = 	
{
	proto =
	{
		type = 'ameba',
		charge = 0,
		supercharge = 0,
		speed = 20,
		speedhostile = 40,
		attack = 2, -- attack cd
		dmg = 1,
		toid = 18,
		hp = 1,
		--light = {32,0.8,0.8,1},
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		sleeptime = 300,
		loot = {
			{i=184,p=6},
			{i=183,p=3},
		},
		q = {}, -- last moves
		line = 0,
		qcnt = 0, -- last moves cnt
		hostile = 100,
		save = {},
		light = {32,0,0.5,0},
		ani_size=1,
		sound = 15,
	},

	upgrades =
	{
		{'speedhostile',1,90},
		{'hp',1,200},
	},

	ai = function (mob,id)
		mob_ameba (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

}

function mob_ameba (mob,id)
	
	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then
		--mob.stick = nil

		mob.xspeed = 0
		mob.yspeed = 0.7

		ani_setstatus (mob,'die',true)
		lines[id] = nil
		
		if mob.ani_frame == 4 and mob.ani_frametime>0.05 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end

			
			mob_destory(id, true)
			return
		end
		--return
	end



	--kicked
	if mob.deltax then
		mob.x = mob.x + mob.deltax 
		mob.deltax = nil
	end


	if mob.xspeed==nil then
		mob.xspeed = love.math.random (-10,10)/5
		mob.yspeed = love.math.random (-10,10)/5
		mob.xy = -1
		mob.sin = love.math.random (5,30)
	end


	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end



	-- check every 1px
	if mob.delta < 1 and mob.ani_status ~= 'die' then return end

	--dehostile
	if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
	mob_buffs_tick (mob)

	local xstep = math.floor (mob.delta * mob.xspeed)
	local ystep = math.floor (mob.delta * mob.yspeed)
	mob.delta = 0
	mob.line = mob.line + 0.05



	--check each tile
	local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
	if mob.txo~=mob.tx or mob.tyo~=mob.ty then

		
		if readmap (mob.tx,mob.ty,'b')==85 then
			writemap (mob.tx, mob.ty,178)
			mob_destory (id)
			return
		end

		local l = has_light (mob.tx,mob.ty)

		if mob.haslight and l==nil then
			mob.xspeed = mob.xspeed * (-1)
			mob.yspeed = mob.yspeed * (-1)
			mob.line = 0
		end

		mob.haslight = l

		if l then

			mob.save.photo = (mob.save.photo or 0) + l

			--print (mob.save.photo)
			
			if mob.ani_size==1 and mob.save.photo>100 and game.time>mob.birth+time.d then
				mob_replace (id,10)
				mob.birth = game.time
				mob.save.photo = 0
				return
			end

			if mob.ani_size==2 and mob.save.photo>100 and game.time>mob.birth+time.d then
				mob_create  (mob.tx, mob.ty,9)
				mob_create  (mob.tx, mob.ty,9)
				mob_destory (id)
				return
			end


		end


	--save mob
	--	local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
		--print (dist)
		if dist>vi.mobspawndist+3 then

			mob_save (mob.tx,mob.ty,id)
			return

		end

		
		mob.txo = mob.tx
		mob.tyo = mob.ty

		mob.line = mob.line + 1


			if dist<7 and love.math.random (0,100)>10 then

				if pl.buffs[1] then

					if mob.tx > pl.tx then mob.xspeed = -1 end
					if mob.tx < pl.tx then mob.xspeed = 1 end
					if mob.ty > pl.ty then mob.yspeed = -1 end
					if mob.ty < pl.ty then mob.yspeed = 1 end

					if math.abs (mob.tx-pl.tx)>math.abs(mob.ty-pl.ty) then
						mob.xy = 1
					else
						mob.xy = -1
					end

				else

					if mob.save.hostile then
						if mob.tx < pl.tx then mob.xspeed = -1 end
						if mob.tx > pl.tx then mob.xspeed = 1 end
						if mob.ty < pl.ty then mob.yspeed = -1 end
						if mob.ty > pl.ty then mob.yspeed = 1 end

						if math.abs (mob.tx-pl.tx)>math.abs(mob.ty-pl.ty) then
							mob.xy = 1
						else
							mob.xy = -1
						end
					end

				end

			end


	end



	if mob.line>7 and mob.ani_frame == 4 then

		mob.sin = love.math.random (5,30)
		mob.line = 0

	end


	if dist<4 and mob.hp>0 and pl.buffs[1]==nil then
		--mob.save.hostile = game.time + 1000
	end


--print (tostring (mob.save.hostile))

	
	


	local x = colliders['mob_'..id].x - vi.x
	local y = colliders['mob_'..id].y - vi.y
	local w = colliders['mob_'..id].w - vi.x
	local h = colliders['mob_'..id].h - vi.y

	local points = {}
	table.insert (points, {x=x,y=y,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=w,y=y,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=w,y=h,mode={up = true, down = true, left = true, right = true}})
	table.insert (points, {x=x,y=h,mode={up = true, down = true, left = true, right = true}})
	local togo = tocollide (points)


	if ani_getstatus (mob,'uncont')==nil then


		if mob.save.hostile==nil then

			if mob.xy==-1 then
				xstep = math.cos (mob.y/mob.sin)*2
			else
				ystep = math.cos (mob.x/mob.sin)*2
			end

		end



		if mob.xspeed>0 and togo.right<5 then mob.xspeed = mob.xspeed*(-1) mob.xy = mob.xy*(-1) return end
		if mob.xspeed<0 and togo.left<5 then mob.xspeed = mob.xspeed*(-1)  mob.xy = mob.xy*(-1) return end
		if mob.yspeed>0 and togo.down<5 then mob.yspeed = mob.yspeed*(-1) mob.xy = mob.xy*(-1) return end
		if mob.yspeed<0 and togo.up<5 then mob.yspeed = mob.yspeed*(-1)  mob.xy = mob.xy*(-1) return end

		if xstep>0 then
			mob.x = mob.x + math.min(xstep,togo.right)
		else
			mob.x = mob.x + math.max(xstep,togo.left*-1)
		end

		if ystep>0 then
			mob.y = mob.y + math.min(ystep,togo.down)
		else
			mob.y = mob.y + math.max(ystep,togo.up*-1)
		end

		if mob_collision_blocked(togo) and mob.line>5 then
				mob.xspeed = love.math.random (-10,10)/5
				mob.yspeed = love.math.random (-10,10)/5
				mob.line = 0
				
		end

	end

	coord_screen2true (mob)




end


creature[10] = 	--fat amoeba
{
	proto =
	{
		type = 'ameba',
		colname = 'bigameba',
		charge = 0,
		supercharge = 0,
		speed = 20,
		speedhostile = 80,
		attack = 2, -- attack cd
		dmg = 1,
		toid = 18,
		hp = 5,
		--light = {32,0.8,0.8,1},
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		sleeptime = 300,
		loot = {
			{i=192,p=50},
			{i=176,p=1}
		},
		q = {}, -- last moves
		line = 0,
		qcnt = 0, -- last moves cnt
		hostile = 1000,
		save = {},
		light = {42,0,0.7,0},
		ani_size=2,
		sound = 15,
	},

	upgrades =
	{
		{'speedhostile',1,90},
		{'hp',1,200},
	},

	ai = function (mob,id)
		mob_ameba (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,
}



creature[11] = --robot
{
	proto =
	{
		type = 'robot',
		attack = 1, -- attack cd
		dmg = 1,
		--toid = 18,
		speed = 30,
		speedhostile = 60,
		hp = 20,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		save = {},
		line = 0,
		hostile = 1000,
		loot = {{i=280,p=1}}
	},

	upgrades =
	{
		{'speedhostile',1,90},
		{'hp',2,200},
		{'attack',-0.05,0.2},
		{'dmg',0.1,10},
	},

	ai = function (mob,id)
		mob_robot (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

}


function mob_robot (mob,id)

	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then
		mob.z = 1
		--mob.stick = nil
		ani_setstatus (mob,'die',true)
		if mob.ani_frame == 6 and mob.ani_frametime>2 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end
			mob_destory(id, true)
			return
		end
		--return
	end


	local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)

	if dist>10 and mob.stick=="down" and
		mob.d == 0 and
		readmap (mob.tx+1, mob.ty, 'b')==0 and
		readmap (mob.tx-1, mob.ty, 'b')==0 then
			ani_setstatus (mob,'sleep')
			mob.save.charge = 0
	end
	
	if mob.ani_status == 'sleep' then

		dist = math.floor (dist - 2)

		if dist<8 and dist>0 then
			textbubble ('mob'..id,mob.tx,mob.ty+1,dist,0.1,{style=5,theme=3,pad=10,w=300,out=1})
		end

		if dist<1 then
			textbubble ('mob'..id,mob.tx,mob.ty+1,msg.ui.robot_exterminate,1,{style=5,theme=3,pad=10,w=300,out=1})
		
			ani_setstatus (mob,'walk')
		end
	end

	if mob.ani_status == 'sleep' and mob.save.hostile then
		ani_setstatus (mob,'walk')
	end



	if dist<4 and mob.hp>0 and mob.save.charge and math.ceil (mob.save.charge)>10 then

		if cooldown (mob,'attack') then 
			player_hit (1, mob)
			mob.save.charge = mob.save.charge - 0.3
			if pl.stats.arms.hp > 5 then
				stat_spend ('arms',5)	
			end
		end

		local x = math.ceil ((pl.x - mob.x)/4)
		local y = math.ceil ((pl.y - mob.y)/4)
		
		lines[id] = { 
		mob.x, mob.y,
		mob.x+x+(love.math.random (-10,10)*0.2*x),mob.y+y+(love.math.random (-10,10)*0.1*y),
		mob.x+x+x+(love.math.random (-20,20)*0.2*x),mob.y+y+y+(love.math.random (-20,20)*0.1*y),
		pl.x, pl.y
		}


	else

		lines[id] = nil

	end


	-- check every 1px
	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end

	-- if dist>2 then
	-- 	mob.delta = mob.delta * 1.5
	-- end


	if mob.delta >= 1 or mob.stick == nil then

		if love.math.random (0,100+id)<15 then return end

		--dehostile
		if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
		mob_buffs_tick (mob)

		local step = math.floor (mob.delta)
		mob.delta = 0

		mob.save.moved = (mob.save.moved or 0) + 1

		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then

			mob.line = (mob.line or 0) + 1

			local notnew

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist+3 then

				mob_save (mob.tx,mob.ty,id)
				return

			end
	
		end



		if mob.stick and mob.dir then

			local c = mob.dir.."-"..mob.stick

			if c == 'down-right' or c == 'down-left' then
				mob.stick = nil
				mob.dir = nil
				mob.x = mob.x + mob.flip*16
			end
			
			if mob.dir == 'up' then
				step = step * 4
			end
		end



		if ani_getstatus (mob,'uncont')==nil then

		 	local flip = false

		 	 	if (math.abs(mob.ty-pl.ty)<5 and mob.flip == 1 and mob.tx > pl.tx)
				or
			 	(math.abs(mob.ty-pl.ty)<5 and mob.flip == -1 and mob.tx < pl.tx)
			 	then flip = true end

			 	if flip then 
			 		mob_flip (mob) 
			 		mob.save.charge = (mob.save.charge or 0) + 1
			 	end

		end


		mob_crawling (mob,step)

		if math.abs (mob.truex-pl.truex)<20 and math.abs (mob.truey-pl.truey)<30 then
			if cooldown (mob,'attack') then 
				player_hit (mob.dmg, mob)
			end

		end

		-- if mob.attacked==nil and mob.ani_status == 'attack' and mob.ani_frame == 2 and math.abs (mob.truex-pl.truex)<25 and math.abs (mob.truey-pl.truey)<30 then
		-- 	buff_add (2, 'keep')
		-- 	player_hit (mob.dmg)
		-- 	mob.attacked = love.math.random (10,30)
		-- end

		
		coord_screen2true (mob)

	end
end








creature[12] = 	
{
	proto =
	{
		type = 'skull',
		charge = 0,
		supercharge = 0,
		speed = 20,
		speedhostile = 80,
		attack = 2, -- attack cd
		dmg = 1,
		toid = 12,
		hp = 1,
		--light = {32,0.8,0.8,1},
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		sleeptime = 300,
		loot = {
			{i=12,p=6},
		},
		q = {}, -- last moves
		line = 0,
		qcnt = 0, -- last moves cnt
		hostile = 1000,
		save = {},
		light = {20,0.7,0.7,0.7},
		ani_size=2,
		z = 1,
	},

	ai = function (mob,id)
		mob_skull (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

}


creature[13] = --stealer
{
	proto =
	{
		type = 'stealer',
		attack = 1, -- attack cd
		dmg = 1,
		--toid = 18,
		speed = 30,
		speedhostile = 40,
		hostile = 32,
		hp = 1,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		save = {},
		line = 0,
		loot = {
			{i=267,p=9},
			{i=20,p=1}
		},
		z = 1,
		oldstick = "",
		anidef = 'spawn'
	},

	upgrades =
	{
		{'speed',0.1,40},
		{'speedhostile',0.1,60},
		{'hp',0.05,100},
	},

	ai = function (mob,id)
		mob_stealer (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
	end,

}




--filth colon
function mob_stealer (mob,id)

	coord_true2screen (mob)

	-- if mob.dir == nil then
	-- 	mob.dir = 'left'
	-- end


	--fall damage
	if mob.felt and mob.felt>0 and mob.carry then
		--print (mob.felt)
		mob.felt = math.floor ((mob.felt-32)/32)
		if mob.felt>3 then
			mob_hit (id,mob.felt)
		end
		mob.felt = 0
	end
	
	-- dying
	if mob.hp<=0 then
		mob.stick = nil
		mob.d = mob_turn (mob.d,0)
		ani_setstatus (mob,'die',true)
		if mob.ani_frame == 5 and mob.ani_frametime>2 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end

			if mob.carry then
				inv_ground_add (mob.tx, mob.ty,mob.carry)
			end

			mob_destory(id, true)
			return
		end
		--return
	end


	-- check every 1px
	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end


	if mob.delta >= 1 or mob.stick == nil then

		mob_buffs_tick (mob)

		if love.math.random (0,100+id)<15 then return end

		if mob.ani_status == 'walk' and mob.carry then 
			mob.ani_status = 'carrywalk'
		end

		if mob.ani_status == 'carrywalk' and mob.carry==nil then 
			mob.ani_status = 'walk'
		end

		local step = math.floor (mob.delta)
		--local step = 1
		
		
		mob.delta = mob.delta - step
		mob.save.moved = (mob.save.moved or 0) + 1

		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist+3 then

				mob_save (mob.tx,mob.ty,id)
				return

			end

			mob.line = (mob.line or 0) + 1
			mob.txo=mob.tx
			mob.tyo=mob.ty

			mob.carry = item_wear (mob.carry, 0.01) --

			if mob.carry and mob.carry.t<0 then
				mob.carry = nil
				mob.stick = nil
				mob_hit (id,99)
			end

			if inv_ground_count(mob.tx, mob.ty)>0 and readmap (mob.tx,mob.ty,'b')~=124 then

				local i = inv_ground_remove (mob.tx, mob.ty,1)
				if i then

					if mob.carry then
						inv_ground_add (mob.tx, mob.ty,mob.carry)
					else
						mob_flip (mob)
					end

					mob.carry = i

				end
			
			end
	
		end


		

		if mob.stick and mob.dir then

			local c = mob.dir.."-"..mob.stick
			
			if (c == 'down-right' or c == 'down-left') and
			(mob.oldstick == 'down-left' or mob.oldstick == 'down-right') then
				
				-- mob.stick = nil
				--mob.x = mob.x + mob.flip*16

				
			end

		end



		-- if mob.dir == 'up' then
		-- 	step = step / 2
		-- end


		-- local c = 'n'
		-- if mob.stick and mob.dir then
		-- 	c = mob.dir.."-"..mob.stick
		-- end
		--print (mob.x.." "..mob.y.." "..c)


		mob_crawling (mob,step)
		
		coord_screen2true (mob)

	end
end



creature[14] = --
{
	proto =
	{
		type = 'spinner',
		attack = 0.2, -- attack cd
		dmg = 1,
		--toid = 18,
		speed = 20,
		speedhostile = 40,
		hostile = 10000000,

		shoot = 3,
		shootdec = 0.05, --shoot speedup on dmg
		shootspeedx = 10,
		shootspeedy = 200,
		hp = 10,
		d = 0, -- degrees
		stuck = 0,
		flip = -1,
		delta = 0,
		wake = 0,
		save = {},
		line = 0,
		loot = {{i=310,p=5}},
		z = 1,
		isdown = 0,
		proj = 10,
		sleeptime = 300,
	},

	ai = function (mob,id)
		mob_spinner (mob,id)
	end,

	hit = function (m,d)


		mob = mobs[m]
		mob.save.hostile = game.time + mob.hostile


		if mob.ani_status == 'spin' then
			mob.light = {14,0.7,0.7,0},
			ani_setstatus (mob,'jump',true)
			mob_sct (mob,msg.combat[1])
			mob_flip (mob)


			--shoot on miss
			local m =
				{
					x = mob.x,
					y = mob.y-10,
					xspeed = pl.flip * 32,
					yspeed = math.random (0,mob.shootspeedy)*-1,
					proj = mob.proj,
					bounce = {1,1,1,1}
				}

			if projes[mob.proj] then
				m.light = projes[mob.proj].light
			end

			proj[next_numeric_id(proj)] = m


			return
		end

		if mob.shoot>=0.1 then
			mob.shoot = mob.shoot - mob.shootdec
		end

		mob_hit (m,d, true)
	end,

}




function mob_spinner (mob,id)

	
	if mob.stick==nil and mob.spawned==nil and maptile (mob.tx, mob.ty-1)==1 then
		mob.truex = mob.truex + 16
		mob.d = 180
		mob.spawned = true
		--mob.stick = 'up'
		mob.sleep = 1000
	end

	coord_true2screen (mob)



	--fall damage
	-- if mob.felt and mob.felt>0 and mob.carry then
	-- 	print (mob.felt)
	-- 	mob.felt = math.floor ((mob.felt-32)/32)
	-- 	if mob.felt>3 then
	-- 		mob_hit (id,mob.felt)
	-- 	end
	-- 	mob.felt = 0
	-- end
	
	-- dying
	if mob.hp<=0 then
		mob.stick = nil
		mob.d = mob_turn (mob.d,0)
		--ani_setstatus (mob,'die',true)
		--if mob.ani_frame == 5 and mob.ani_frametime>2 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end

			--shoot on dying
			for i=1,10 do
			
				local m =
					{
						x = mob.x,
						y = mob.y-10,
						xspeed = love.math.random (-100,100),
						yspeed = 100,
						proj = mob.proj,
						bounce = {1,1,1,1}
					}

				proj[next_numeric_id(proj)] = m

			end

			mob_destory(id, true)
			return
		--end
		--return
	end


	-- check every 1px
	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end

	if mob.delta >= 1 or mob.stick == nil then

		--dehostile
		if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
		mob_buffs_tick (mob)

		--sleeping
		if mob.sleep then 

			--stuck fix
			if (maptile (mob.tx, mob.ty,'col') or 0)==1 then
				mob_destory (id)
			end

			mob.sleep = mob.sleep - dt
			ani_setstatus (mob,'sleep')
			mob.light = nil

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)

			if dist<2 then
				mob.save.hostile = game.time + 1000
			end

			if mob.sleep<=0 or dist<2 then 
				mob.sleep = nil
				ani_setstatus (mob,'walk')
			end

			return true

		end

		--sleep on top
		if mob.save.hostile==nil and mob.stick == 'up' and love.math.random (0,100)==10 then
			mob.sleep = mob.sleeptime
		end

		--if love.math.random (0,100+id)<15 then return end

		local step = math.floor (mob.delta)

		local step = 1
		--local step = mob.delta

		mob.delta = mob.delta - step
		mob.save.moved = (mob.save.moved or 0) + 1

		--print (mob.dir)

		
		
		if mob.isdown > 0 then
			step = 2
			if mob.ani_status ~= 'jump' then
				mob.light = nil
				ani_setstatus (mob,'spin',true)
			end
		else
			mob.light = {14,0.7,0.7,0},
			ani_setstatus (mob,'walk',true)
		end


		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist+3 then

				mob_save (mob.tx,mob.ty,id)
				return

			end

			if mob.stick == 'up' then
				mob.isdown = 0
			end

			if mob.stick == 'down' then
					mob.isdown = 15
				else
					--mob.isdown = mob.isdown - 1
			end

			mob.line = (mob.line or 0) + 1
			mob.txo=mob.tx
			mob.tyo=mob.ty
	
		end


		if mob.save.hostile and mob.stick=='up' and math.abs (mob.tx-pl.tx)<5 and cooldown (mob,'shoot',nil,2) then

						 	 	
	 	 	local m =
				{
					x = mob.x,
					y = mob.y+10,
					xspeed = (pl.x-mob.x)*((pl.y-mob.y)/100),
					yspeed = math.random (0,mob.shootspeedy),
					proj = mob.proj,
					bounce = {1,1,1,1}
				}

				if projes[mob.proj] then
					m.light = projes[mob.proj].light
				end

				proj[next_numeric_id(proj)] = m
		end


		-- if ani_getstatus (mob,'uncont')==nil then

		--  	local flip = false

		--  	if mob.stick=="up" and mob.ty>pl.ty then
		 		
		--  		if mob.tx < pl.tx and mob.dir=='left' then flip = true end
		-- 		if mob.tx > pl.tx and mob.dir=='right' then flip = true end
		-- 	 	if flip then mob_flip (mob) end
		-- 	end

		-- end


		-- if mob.dir == 'up' then
		-- 	step = step / 2
		-- end


		-- local c = 'n'
		-- if mob.stick and mob.dir then
		-- 	c = mob.dir.."-"..mob.stick
		-- end
		--print (mob.x.." "..mob.y.." "..c)


		mob_crawling (mob,step)
		
		coord_screen2true (mob)

	end
end









creature[15] =
{
	proto =
	{
		type = 'louse',
		attack = 3, -- attack cd
		dmg = 2,
		--toid = 18,
		chargespeed  = 3, --
		speed = 30,
		speedhostile = 40,
		hostile = 100,
		hp = 5,
		d = 0, -- degrees
		stuck = 0,
		flip = -1,
		delta = 0,
		wake = 0,
		sleep = 0,
		save = {},
		line = 0,
		loot = {{i=273,p=5}},
		z = 1,
		isup = 0,
		turnspeed = 5,
		sound = 36,
	},

	upgrades =
	{
		{'chargespeed',1,4,10},
		{'turnspeed',-1,3,10},
		{'speed',1,40},
		{'attack',-0.05,1},
		{'dmg',0.1,10},
		{'hp',1,100},
	},

	ai = function (mob,id)
		mob_louse (mob,id)
	end,

	hit = function (m,d)


		local mob = mobs[m]

		mob.isup = -5

		if mob.flip ~= pl.flip then
			ani_setstatus (mob,'block',true)
			mob_sct (mob,msg.combat[2])
			return
		end

		d = math.ceil (d/2)
		mob_hit (m,d, true)

		if mob.hp>0 then
			mob_flip (mob)
		end

	end,

	--light = {16,0.8,0.8,1},
}




function mob_louse (mob,id)

	coord_true2screen (mob)

	--fall damage
	-- if mob.felt and mob.felt>0 and mob.carry then
	-- 	print (mob.felt)
	-- 	mob.felt = math.floor ((mob.felt-32)/32)
	-- 	if mob.felt>3 then
	-- 		mob_hit (id,mob.felt)
	-- 	end
	-- 	mob.felt = 0
	-- end
	
	-- dying
	if mob.hp<=0 then

		mob.stick = nil
		mob.d = mob_turn (mob.d,0)
		ani_setstatus (mob,'die',true)
		
		if mob.ani_frame == 3 and mob.ani_frametime>2 then

			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end

			if mob.carry then
				inv_ground_add (mob.tx, mob.ty,mob.carry)
			end

			mob_destory(id, true)
			return
		end

		--return
	end


	-- check every 1px
	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end


	if mob.delta >= 1 or mob.stick == nil then


		--dehostile
		if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
		mob_buffs_tick (mob)


		if love.math.random (0,100+id)<15 then return end

		local step = math.floor (mob.delta)
		local step = 1

		mob.delta = mob.delta - step
		mob.save.moved = (mob.save.moved or 0) + 1

		if mob.ani_status == 'attack' then 
			step = mob.chargespeed		
		end



		--eating
		if (mob.save.hostile==nil or mob.save.hostile==0) and mob.save.eating then

			local i = inv_ground_find_i(mob.tx,mob.ty,{31,5,10,29,60,36})

			if i then
				local o = world[mob.ty][mob.tx].i[i]

				if o then
					if o.t>0 then
						o.t = o.t - item[o.i].ttl*0.01
						return
					else
						inv_ground_remove (mob.tx,mob.ty,i)
						mob.save.ate = (mob.save.ate or 0) + 1

						--and game.time>mob.birth+time.d
						if mob.save.ate > 5 then
							--local m = mob_create (mob.tx,mob.ty,1)
							inv_ground_add (mob.tx,mob.ty,item_make(46))
							mob.save.ate = 0
							mob.birth = game.time
						end

					end
				end
			end

			mob.save.eating = nil

		end

		




		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then


		--save mob
		local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
		if dist>vi.mobspawndist+3 then
			mob_save (mob.tx,mob.ty,id)
			return
		end


			mob.line = (mob.line or 0) + 1
			mob.txo=mob.tx
			mob.tyo=mob.ty

			if mob.stick == 'up' or mob.dir=='up' then
				mob.isup = mob.isup + 1
			else
				mob.isup = 0
			end

			if mob.isup > 15 then
				mob.isup = -5
				--mob.stick = nil
				mob_flip (mob)
			end

			if mob.save.hostile then

			 	if ani_getstatus (mob,'uncont')==nil then

				 	if math.abs(mob.ty-pl.ty)<5 and mob.flip == 1 and mob.tx > pl.tx and math.abs(mob.tx-pl.tx)>mob.turnspeed then
				 		mob_flip (mob)
				 	end

				 	if math.abs(mob.ty-pl.ty)<5 and mob.flip == -1 and mob.tx < pl.tx and math.abs(mob.tx-pl.tx)>mob.turnspeed then
				 		mob_flip (mob)
				 	end
				end
			end

			-- start eating
			local o = inv_ground_find_i(mob.tx,mob.ty,{31,5,10,29,60,36})
			if o and readmap (mob.tx,mob.ty,'b')~=124 then
				mob.save.eating = true
				return
			end
	
		end


		--attack
		if mob.hp>0 then 

			if math.abs (mob.truex-pl.truex)<30 and math.abs (mob.truey-pl.truey)<50 and cooldown (mob,'attack') then
				ani_setstatus (mob,'attack')

				if mob.stick == 'down' and mob.flip == pl.flip then
					mob_flip (mob)
				end

			end

			if mob.attacked==nil and mob.ani_status == 'attack' and mob.ani_frame > 1
			and mob.ani_frame<4 then
				
				if collide_check ('mob_'..id,'player') then
					player_hit (mob.dmg, mob)
				end

				if mob.ani_frame == 5 then
					mob.attacked = true
				end

			end

			if mob.ani_status ~= 'attack' then
				mob.attacked = nil
			end

		end
		

		if mob.stick and mob.dir then

			local c = mob.dir.."-"..mob.stick
			
			if (c == 'down-right' or c == 'down-left') and
			(mob.oldstick == 'down-left' or mob.oldstick == 'down-right') then
				
				mob.stick = nil
				--mob.x = mob.x + mob.flip*16

				
			end

		end


		-- if mob.stick == 'down' then
		-- 	ani_setstatus (mob,'spin',true)
		-- else
		-- 	ani_setstatus (mob,'walk',true)
		-- end




		-- if mob.dir == 'up' then
		-- 	step = step / 2
		-- end


		-- local c = 'n'
		-- if mob.stick and mob.dir then
		-- 	c = mob.dir.."-"..mob.stick
		-- end
		--print (mob.x.." "..mob.y.." "..c)


		mob_crawling (mob,step)
		
		coord_screen2true (mob)

	end
end


























----------------------------------------------




creature[16] = --butler
{
	proto =
	{
		type = 'butler',
		attack = 1, -- attack cd
		dmg = 1,
		--toid = 345,
		speed = 80,
		speedhostile = 40,
		hostile = 32,
		hp = 100,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		save = {},
		line = 0,
		loot = {
			{i=267,p=9},
			{i=20,p=1}
		},
		z = 1,
		oldstick = "",
		anidef = 'walk',
		change = 0,

	},

	upgrades =
	{
		{'speed',0.1,40},
		{'speedhostile',0.1,60},
		{'hp',0.05,100},
	},

	ai = function (mob,id)
		mob_butler (mob,id)
	end,

	hit = function (m,d)

		local mob = mobs[m]
		mob.sort = {}

		if mob.carry then
			inv_ground_add (mob.tx, mob.ty,mob.carry)
			inv_ground_sort (mob.tx, mob.ty)
			mob.carry = nil
		end

		mob_sct (mob,msg.combat[6])
		sound_add ('click',40)
		mob_flip (mob)
		mob.toid = 345

	end,

}




--filth colon
function mob_butler (mob,id)

	if mob.carry==nil then
		mob.toid = 345
	else
		mob.toid = nil
	end

		coord_true2screen (mob)

	-- if mob.dir == nil then
	-- 	mob.dir = 'left'
	-- end


	--fall damage
	-- if mob.felt and mob.felt>0 and mob.carry then
	-- 	--print (mob.felt)
	-- 	mob.felt = math.floor ((mob.felt-32)/32)
	-- 	if mob.felt>3 then
	-- 		mob_hit (id,mob.felt)
	-- 	end
	-- 	mob.felt = 0
	-- end
	
	-- dying
	if mob.hp<=0 then
		mob.stick = nil
		mob.d = mob_turn (mob.d,0)
		ani_setstatus (mob,'die',true)
		if mob.ani_frame == 5 and mob.ani_frametime>2 then
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end

			if mob.carry then
				inv_ground_add (mob.tx, mob.ty,mob.carry)
			end

			mob_destory(id, true)
			return
		end
		--return
	end


	-- check every 1px
	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end


	if mob.delta >= 1 or mob.stick == nil then

		--if love.math.random (0,100+id)<15 then return end

		if mob.ani_status == 'walk' and mob.carry then 
			mob.ani_status = 'carrywalk'
		end

		if mob.ani_status == 'carrywalk' and mob.carry==nil then 
			mob.ani_status = 'walk'
		end

		local step = math.floor (mob.delta)
		local step = 1
		
		
		mob.delta = mob.delta - step
		mob.save.moved = (mob.save.moved or 0) + 1

		mob.change = (mob.change or 0) - 1

		--check each tile
		if (mob.txo~=mob.tx or mob.tyo~=mob.ty) and mob.change<0 then

			mob.change = 10

			--print (mob.line)

			if mob.stick == 'up' and mob.line>3 then 
				mob_flip (mob) 
				mob.line = 0
			end

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist*5 then

				mob_save (mob.tx,mob.ty,id)
				return

			end

			mob.line = (mob.line or 0) + 1
			mob.txo=mob.tx
			mob.tyo=mob.ty

			--mob.carry = item_wear (mob.carry, 0.01) --

			-- if mob.carry and mob.carry.t<0 then
			-- 	mob.carry = nil
			-- 	mob.stick = nil
			-- 	mob_hit (id,99)
			-- end


			if mob.sort and (mob.sort.shitcarry or 0)>50 then
				mob.sort.pickpos = ''
			end
				-- dump (mob.tx.." "..mob.ty)

			local max = maptile (mob.tx, mob.ty,'itemcount') or 0
			if max==0 then max=cf.itemmax end

			local ic = inv_ground_count(mob.tx, mob.ty)
			if ic>0 then

				mob.sort = mob.sort or {}
				mob.sort.itemtable = mob.sort.itemtable or {}
				mob.sort.itemtable_c = mob.sort.itemtable_c or {}
				

				local c, arr = inv_ground_sort (mob.tx, mob.ty)
				local inv = readmap (mob.tx, mob.ty,'i')
				local topick = inv[1].i

				--max items
				if ic<max then

					for k,v in pairs(arr) do
						if (mob.sort.itemtable[k] or 0)<v then
							mob.sort.itemtable[k] = v
							mob.sort.itemtable_c[k] = mob.tx..'-'..mob.ty
						end
					end



					if mob.carry then
						mob.sort.shitcarry = (mob.sort.shitcarry or 0) + 1
					end

					if mob.carry and candrop(mob.tx, mob.ty)
						and mob.sort.pickpos ~= mob.tx.."-"..mob.ty then

						if (arr[mob.carry.i] or 0) > 0 or --similar items
							(inv==nil and (mob.sort.itemtable[mob.carry.i] or 0)==1) --fill empty space with one item
							then

							inv_ground_add (mob.tx, mob.ty,mob.carry,{groundlast = 1})
							inv_ground_sort (mob.tx, mob.ty)
							mob.carry = nil
							mob_flip (mob)

							return

						end

					end
				end



				--and c>0 

				if mob.carry==nil and readmap (mob.tx,mob.ty,'b')~=124 then

					mob.sort.shitcarry = 0

					for ii,v in ipairs(inv) do

						local topick = v.i

						--print (v.n.." "..(mob.sort.itemtable[topick] or 0).." "..(mob.sort.itemtable_c[topick] or ""))

						--dump (mob.sort.itemtable_c)
						
						if ((arr[topick] or 0) < (mob.sort.itemtable[topick] or 0) and (mob.sort.itemtable[topick] or 0) > 1)
						or ((mob.sort.itemtable[topick] or 0)==1 and #inv~=1) --single items from stack
						or ((mob.sort.itemtable[topick] or 0)==1 and #inv==1 and (mob.sort.itemtable_c[topick] or "") ~= mob.tx..'-'..mob.ty)
						or ic>max --big pile
	

						then

							--dump (mob.sort.itemtable)
							--print ('pick = inv:'..dumpvar (arr[topick]).." ground:"..dumpvar (mob.sort.itemtable[topick])..' '..v.n)


							mob_flip (mob)

							local i = inv_ground_remove (mob.tx, mob.ty,ii)
							mob.carry = i

							mob.sort.count = c
							mob.sort.pickpos = mob.tx.."-"..mob.ty
							mob.sort.pickposcount = 0
							mob.sort.lastpicked = mob.carry.i

							return
							--break
							
							

						end

					end

				end

				-- dump (mob.sort.shitcarry or 0)
				-- dump (mob.carry)
				-- dump (mob.sort.pickpos)
				-- dump (mob.tx.." "..mob.ty)





				
			
				--	mob_flip (mob)
				
				


				
			
			else

				if ic<max and mob.carry and candrop(mob.tx, mob.ty) 
					and (mob.sort.itemtable_c[mob.carry.i] or "") ~= mob.tx..'-'..mob.ty then

					 --fill empty space with one item
					if (mob.sort.itemtable[mob.carry.i] or 0)<2 then

						mob.sort.itemtable_c[mob.carry.i] = mob.tx..'-'..mob.ty
						inv_ground_add (mob.tx, mob.ty,mob.carry)
						inv_ground_sort (mob.tx, mob.ty)
						mob.carry = nil
						return

					end

				end

			end
	
		

		end



		

		if mob.stick and mob.dir then

			local c = mob.dir.."-"..mob.stick
			
			if (c == 'down-right' or c == 'down-left') and
			(mob.oldstick == 'down-left' or mob.oldstick == 'down-right') then
				
				-- mob.stick = nil
				--mob.x = mob.x + mob.flip*16

				
			end

		end



		-- if mob.dir == 'up' then
		-- 	step = step / 2
		-- end


		-- local c = 'n'
		-- if mob.stick and mob.dir then
		-- 	c = mob.dir.."-"..mob.stick
		-- end
		--print (mob.x.." "..mob.y.." "..c)



		mob_crawling (mob,step)
		
		coord_screen2true (mob)

	end
end


















creature[18] = 	--little chicken
{
	proto = 
	{
		type = 'chicken',
		toid = 365,
		hostile = 1000,
		shoot = 1.5,
		speed = 20,
		speedhostile = 100,
		hp = 1,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		loot = {{i=14,p=5}},
		save = {},
		line = 0,
		ani_size = 1,
		z = 1,
		coltype = 'critter',
		eatable = {154, 267, 6, 279, 20, 98, 7, 113, 112, 100, 189, 97, 176, 38, 52, 174, 191, 235, 1, 94, 190, 126, 188}
	},

	upgrades =
	{
		{'speedhostile',1,40},
		{'speedhostile',1,80},
		{'hp',1,20},
		{'shoot',-0.01,0.5},

	},

	ai = function (mob,id)
		mob_chicken (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
		
		if mobs[m].ty<pl.ty  then
			mobs[m].stick = nil
		end
	end,
}




creature[17] = 	--chicken
{
	proto = 
	{
		type = 'chicken',
		toid = 358,
		hostile = 1000,
		shoot = 1.5,
		speed = 20,
		speedhostile = 100,
		hp = 7,
		d = 0, -- degrees
		stuck = 0,
		flip = 1,
		delta = 0,
		wake = 0,
		sleep = 0,
		loot = {{i=366,p=5}},
		save = {},
		line = 0,
		ani_size = 2,
		z = 1,
		coltype = 'critter',
		eatable = {154, 267, 6, 279, 20, 98, 7, 113, 112, 100, 189, 97, 176, 38, 52, 174, 191, 235, 1, 94, 190, 126, 188}
	},

	upgrades =
	{
		{'speedhostile',1,40},
		{'speedhostile',1,80},
		{'hp',1,20},
		{'shoot',-0.01,0.5},

	},

	ai = function (mob,id)
		mob_chicken (mob,id)
	end,

	hit = function (m,d)
		mob_hit (m,d, true)
		
		if mobs[m].ty<pl.ty  then
			mobs[m].stick = nil
		end
	end,
}


function mob_chicken(mob,id)

	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then

		
		if mob.ani_status~='die' then
			ani_setstatus (mob,'die')
		end

		if mob.stick~='down' and mob.stick~=nil then 
	
			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end
			mob_destory(id,true)
			return

		end
		

	end

	--sleeping
	mob.sleep =  mob.sleep or 0

	if mob.stick=='up' then
		mob.x = mob.x - mob.flip*10
		mob.stick = nil
		mob.dir = nil
	end

	if mob.ani_status~='die' then
		if mob.save.eating then
			ani_setstatus (mob,'eat')
		else
			if mob.stick=='left' or mob.stick=='right' or mob.stick=='nil' then
				ani_setstatus (mob,'fly')
			else
				ani_setstatus (mob,'walk')
			end
		end
	end

	-- check every 1px
	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end

	if mob.delta >= 1 or mob.stick == nil then

	if love.math.random (0,100+(mob.n*5))<15 then return end

		--dehostile
		if mob.save.hostile and mob.save.hostile<game.time then mob.save.hostile = nil end
		mob_buffs_tick (mob)

		local step = math.floor (mob.delta)
		mob.delta = 0

		--eating
		if (mob.save.hostile==nil or mob.save.hostile==0) and mob.save.eating then

			local i = inv_ground_find_i(mob.tx, mob.ty, mob.eatable)

			if i then

				mob.save.flip = 0

				local o = world[mob.ty][mob.tx].i[i]

				if o then
					if o.t>0 then
						o.t = o.t - item[o.i].ttl*0.03
						return
					else
						inv_ground_remove (mob.tx,mob.ty,i)
						mob.save.ate = (mob.save.ate or 0) + 1

						if love.math.random (0,100)<30 then
							inv_ground_add (mob.tx,mob.ty,item_make(362))
						end

						if mob.save.ate and mob.save.ate>5 and game.time>mob.birth+time.d/4 then

							inv_ground_add (mob.tx,mob.ty,item_make(359))
							mob.save.ate = mob.save.ate - 5
							mob.birth = game.time

						end

					end
				end
			end

			mob.save.eating = nil

		end

		--check each tile
		if mob.txo~=mob.tx or mob.tyo~=mob.ty then

			--grow up
			if mob.ani_size==1 and ((mob.save.ate and mob.save.ate>0) or game.time>mob.birth+time.d) then
				mob_replace (id,17)
				mob.stick = nil
				mob.dir = nil
				mob.flip = 1
			end

			--, 
			local m = collide_check ('critter_'..id, 'mob',{arrname={'worm','snake','stealer'}})
			if m then
				ani_setstatus (mob,'eat')
				mob_hit (m.n, 666)
			end

			mob.line = mob.line + 1

			local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
			if dist>vi.mobspawndist+3 then
				mob_save (mob.tx,mob.ty,id)
				return
			end

			mob.txo = mob.tx
			mob.tyo = mob.ty

			local b = readmap (mob.tx,mob.ty,'b')

			-- eat clover
			-- if b == 36 and (love.math.random (0,100)<10 or mob.save.ate==nil) then
			-- 	writemap (mob.tx,mob.ty,0)
			-- 	inv_ground_add (mob.tx,mob.ty,item_make(3))
			-- end

			mob.save.flip = (mob.save.flip or 0) - 1


			-- start eating
			local o = inv_ground_find_i(mob.tx,mob.ty,mob.eatable)
			if o and readmap (mob.tx,mob.ty,'b')~=124 and mob.stick 
				and (mob.save.hostile==nil or mob.save.hostile==0)
				then


				sound_add ('chick_'..id, 44, {x = mob.tx, y = mob.ty, play = 1})

				ani_setstatus (mob,'eat',true)
				mob.save.eating = true
				return
			end

		end


		mob_crawling (mob,step)


		--if mob.stick ~= nil then



		
		--end	
		
		coord_screen2true (mob)

	end
end







function mob_level (id)
	--dump (pl.killed)
	return pl.killed[id] or 0

end


function mob_upgrade (mob,lvl)

	--upgradeable
	if creature[mob.id].upgrades==nil then
		return
	end

	if lvl==nil then
		lvl = mob_level (mob.id)
	end

	local cnt = lvl - (mob.lvl or 0)

	--print ('upgrade:+'..cnt)
	local ups = {}

	for i=1,cnt*5 do

		if cnt<=0 then break end

		-- random upgrade
		local n = love.math.random (1,#creature[mob.id].upgrades)
		local up = creature[mob.id].upgrades[n]

		if up then
			up[4] = up[4] or 1

			--{'speedhostile',1,80},
			if cnt>=up[4] then
				if 	(up[2]>0 and mob[up[1]] and mob[up[1]]<up[3]) or
					(up[2]<0 and mob[up[1]] and mob[up[1]]>up[3]) then

						mob[up[1]] = (mob[up[1]] or 0) + up[2]
						cnt = cnt - up[4]

						ups[up[1]] = (ups[up[1]] or 0) + up[2]
				
				end
			end
		end

	end

	mob.lvl = lvl

	--dump (ups)

end


-- count mobs in radius
function mob_search (x,y,r,id)

	r = r or 30
	local cnt = 0

	for ix=r*(-1),r do
		for iy=r*(-1),r do
			if ix == 0 and iy == 0 then
			else
				local b = readmap (x+ix,y+iy,'mobs') or {}
				if b and b~=0 then
					
					if id==nil then
						cnt = cnt + #b 
					else
						for i,v in ipairs(b) do
							if v.id == id then
								cnt = cnt + 1
							end
						end
					end

				end
				
			end
		end
	end

	for k,v in pairs(mobs) do
		local dist = math.dist (x,y,v.tx,v.ty)
		if dist<r then
			if id==nil then
				cnt = cnt + 1
			else
				if v.id == id then
					cnt = cnt + 1
				end
			end
		end
	end

	return cnt

end


function mob_save (x,y,id)

	local b = readmap (x,y,'mobs') or 0
	if b == 0 then b = {} end
	table.insert (b,mobs[id])
	writemap (x,y,b,'mobs')
	mob_destory(id)
	
end


function mob_restore (x,y)

	local b = readmap (x,y,'mobs')
	if b == nil then return end

	for k,v in pairs(b) do
		mob_upgrade (v)
		mobs[next_numeric_id(mobs)] = v
	end

	writemap (x,y,nil,'mobs')

end



function mob_hostile (mobtype)

	--print ('hostle '..mobtype)

	for i,mob in pairs(mobs) do

		if mob.type == mobtype then
			mob.save.hostile = game.time + (mob.hostile or 0)
			--mob.hostile = (mob.hostile or 0) * 2
			--if love.math.random (0,100)<50 then mob.sleep = 0 end
		end

	end

end


function mob_flip (cr)
	local d = {right = 'left', left = 'right', up = 'down', down = 'up'}
	cr.flip = cr.flip*-1
	cr.dir = d[cr.dir]
end


function mob_turn (d,turn)

	if d == turn then return d end

	local step = 18
	local step = 22.5
	


	if (turn - d) < -180 then
		d = d + step
		if d>360 then					
			d = d - 360
		end
	else if (turn - d) > 180 then
			d = d - step
			if d<0 then
				d = d + 360
			end
		else
			if turn > d then d = d + step end
			if turn < d then d = d - step end
		end
	end

	return d

end


function mob_destory (m,killed)
	
	-- kill count
	if killed then
		local credited = mobs[m].last_attacker_id
			and actors and actors:get(mobs[m].last_attacker_id) or pl
		credited = credited or pl
		credited.killed = credited.killed or {}
		credited.killed[mobs[m].id] = (credited.killed[mobs[m].id] or 0) + 1
		if game.dbg[1] then print ("killed "..mobs[m].id) end
	end

	if killed then sound_kill ('mob_'..m) end
	colliders['mob_'..m] = nil
	mobs[m] = nil

end


function mob_hit (m,d, gate)

	if gate==nil and mobs[m] then
		local id = mobs[m].id
		creature[id].hit (m,d)
		return 
	end


	local mob = mobs[m]

	if mob==nil then return end

	mob.hostile = (mob.hostile or 0) + 32
	if ACTIVE_ACTOR_ID and actors and actors:get(ACTIVE_ACTOR_ID) then
		mob.last_attacker_id = ACTIVE_ACTOR_ID
	end
	mob.save.hostile = game.time + mob.hostile

	--mobs[m].stick = nil
	--mobs[m].deltax = 18*pl.flip

	d = math.ceil (d)
	if mobs[m].hp>0 then
		mob_sct (mobs[m],"{#63c74dff}-"..d)
	end

	mobs[m].sleep = 0
	mobs[m].hp = mobs[m].hp - d

	-- if mob.ani_status ~= 'attack' then
	-- 	mobs[m].shoot_cd = 0
	-- end			

end


function mob_create (x,y,id,mode)

	local m = tablecopy (creature[id].proto)
	m.id = id
	m.save = {}
	m.birth = game.time

	local n = readmap (x,y,'n')
	
	if n and n==255 then 
		return
	end

	local r = tile2px (x,y)
	m.x = r.x+8
	m.y = r.y+8
	coord_screen2true (m)

	ani_new (m, m.type)
	ani_setstatus (m,m.anidef)

	local w = next_numeric_id(mobs)
	mobs[w] = m

	mob_upgrade (mobs[w])
	return w

end


function mob_replace (modid,id)
	mobs[modid] = tablecopy (creature [id].proto, mobs[modid])
end
























function mob_skull (mob,id)
	
	coord_true2screen (mob)

	-- dying
	if mob.hp<=0 then
		--mob.stick = nil

		mob.xspeed = 0
		mob.yspeed = 0.7

		ani_setstatus (mob,'die',true)
		lines[id] = nil
		
		if mob.ani_frame == 4 and mob.ani_frametime>0.05 then

			if pl.buffs[12] then
				player_hit (math.floor (pl.stats['body'].hp/4))
				buff_remove (12)
			end

			if mob.loot then
				inv_ground_add (mob.tx, mob.ty,item_make(loot_make (mob.loot)))
			end

			
			mob_destory(id, true)
			return
		end
		--return
	end



	--kicked
	if mob.deltax then
		mob.x = mob.x + mob.deltax 
		mob.deltax = nil
	end


	if mob.xspeed==nil then
		mob.xspeed = love.math.random (-10,10)/5
		mob.yspeed = love.math.random (-10,10)/5
	end


	if mob.save.hostile then
		mob.delta = mob.delta + mob.speedhostile*dt
	else
		mob.delta = mob.delta + mob.speed*dt
	end



	-- check every 1px
	-- if mob.delta < 1 and mob.ani_status ~= 'die' then return end

	local xstep =  (mob.delta * mob.xspeed)
	local ystep =  (mob.delta * mob.yspeed)
	mob.delta = 0
	mob.line = mob.line + 0.05


	if mob.xspeed == 0 and mob.yspeed == 0 then
		buff_add (12,'keep')  
		mob.xspeed = love.math.random (-1,1)*0.4
		mob.yspeed = love.math.random (-1,1)*0.4
	end


	--check each tile
	local dist = math.dist (pl.tx, pl.ty, mob.tx, mob.ty)
	if mob.txo~=mob.tx or mob.tyo~=mob.ty then

	
		if dist>vi.mobspawndist+3 then

			mob_save (mob.tx,mob.ty,id)
			return

		end

		
		mob.txo = mob.tx
		mob.tyo = mob.ty

		mob.line = mob.line + 1


	-- local de = math.rad (math.atan(mob.tx-pl.tx,mob.ty-pl.ty))
	-- mob.xspeed=math.cos (de)
	-- mob.yspeed=math.sin (de) 
	-- mob.yspeed=mob.yspeed*(-1)


					mob.xspeed =  (pl.tx - mob.tx)
					mob.yspeed =  (pl.ty - mob.ty - 2)
					


					-- if mob.tx > pl.tx then mob.xspeed = -1 end
					-- if mob.tx < pl.tx then mob.xspeed = 1 end
					-- if mob.ty > pl.ty then mob.yspeed = -1 end
					-- if mob.ty < pl.ty then mob.yspeed = 1 end

					-- if math.abs (mob.tx-pl.tx)>math.abs(mob.ty-pl.ty) then
					-- 	mob.xy = 1
					-- else
					-- 	mob.xy = -1
					-- end


			


	end




	--if ani_getstatus (mob,'uncont')==nil then
		mob.x = mob.x + xstep
		mob.y = mob.y + ystep
	--else

	coord_screen2true (mob)




end






























































function mob_crawling (mob, step)
	

		local points = {}
		table.insert (points, {x=mob.x,y=mob.y,mode={up = true, down = true, left = true, right = true}})
		local togo = tocollide (points)

		--dump (togo)

		-- falling
		if mob.stick == nil then
			if togo.down > 0 then
				step = math.floor (300*dt)
				mob.y = mob.y + math.min(step,togo.down)
				mob.felt = (mob.felt or 0) - step
			else
				mob.felt = (mob.felt or 0) * (-1)
				mob.stick = 'down'
				if mob.dir == nil then 
					if love.math.random (0,100)>50 then
						mob.dir = 'left' 
						mob.flip = -1
					else
						mob.dir = 'right' 
						mob.flip = 1
					end
				end
			end

		end

		mob.flipped = (mob.flipped or 0) - 1
			

			if mob.stick ~= nil then
			
			if togo[mob.stick]>2 and mob.flipped<0 then --and mob.stuck == 0 


			if mob.id==16 then 
				--print (togo[mob.stick].." "..mob.stick..' f'..mob.flipped)
			end

				-- local r = px2tile (mob.x, mob.y)
				-- local r = tile2px (r.x, r.y)

				-- local dx = mob.x - r.x
				-- local dy = mob.y - r.y

				-- if dx>16 then dx = dx - 32 end
				-- if dy>16 then dy = dy - 32 end

				-- print (dx.." "..dy)

			
				local c = mob.stick.."-"..mob.dir
				mob.oldstick = c
				--print (c)
				--love.timer.sleep(0.1)

				local tr = 0
				
				--clockwise
				if c == 'down-right' then mob.stick = 'left' mob.dir = 'down' mob.flip = 1 tr=1 end
				if c == 'left-down' then mob.stick = 'up' mob.dir = 'left' mob.flip = 1  tr=2 end
				if c == 'up-left' then mob.stick = 'right' mob.dir = 'up' mob.flip = 1  tr=3 end
				if c == 'right-up' then mob.stick = 'down' mob.dir = 'right' mob.flip = 1  tr=4 end
				

				--clockdumb
				if c == 'down-left' then mob.stick = 'right' mob.dir = 'down' mob.flip = -1 tr=5 end
				if c == 'right-down' then mob.stick = 'up' mob.dir = 'right' mob.flip = -1  tr=6 end
				if c == 'up-right' then mob.stick = 'left' mob.dir = 'up' mob.flip = -1  tr=7 end
				if c == 'left-up' then mob.stick = 'down' mob.dir = 'left' mob.flip = -1  tr=8 end

				step = step + 3
				mob.stuck = mob.stuck + 1
				mob.flipped = 5

				if mob.id==16 then 
					--print ("stick: "..mob.stick.." "..mob.dir..' '..tr)
					--love.timer.sleep(1)

					--print (mob.stuck)
					--dump (togo)
				end

			end

			
			if togo[mob.dir]<1 then -- hit wall
				local c = mob.stick.."-"..mob.dir
				if c == 'down-right' then mob.stick = 'right' mob.dir = 'up' mob.flip = 1 end
				if c == 'left-down' then mob.stick = 'down' mob.dir = 'right' mob.flip = 1 end
				if c == 'up-left' then mob.stick = 'left' mob.dir = 'down' mob.flip = 1 end
				if c == 'right-up' then mob.stick = 'up' mob.dir = 'left' mob.flip = 1 end

				if c == 'down-left' then mob.stick = 'left' mob.dir = 'up' mob.flip = -1 end
				if c == 'right-down' then mob.stick = 'down' mob.dir = 'left' mob.flip = -1 end
				if c == 'up-right' then mob.stick = 'right' mob.dir = 'down' mob.flip = -1 end
				if c == 'left-up' then mob.stick = 'up' mob.dir = 'right' mob.flip = -1 end

				step = step + 3
				mob.stuck = mob.stuck + 1
				--mob.change = 5

				if mob.id==16 then 
					--print 'hit all'
				end

			end

			if togo[mob.stick]<10 and togo[mob.dir]>0 then mob.stuck = 0 end


			if mob.stuck > 15 then 
				mob.stick = nil 
				mob.dir = nil 
				mob.stuck = 0
			end


			if ani_getstatus (mob,'uncont')==nil then

				--local c = mob.stick.."-"..mob.stuck.."-"..mob.dir.." togo:"..togo[mob.dir]..""
				--oldprint (c..game.dt)

				if mob.dir == 'right' then mob.x = mob.x + math.min(step,togo[mob.dir]) end
				if mob.dir == 'left' then mob.x = mob.x - math.min(step,togo[mob.dir]) end
				if mob.dir == 'up' then mob.y = mob.y - math.min(step,togo[mob.dir])  end
				if mob.dir == 'down' then mob.y = mob.y + math.min(step,togo[mob.dir]) end

				if mob.stick == 'down' then mob.d = mob_turn (mob.d,0) end
				if mob.stick == 'left' then mob.d = mob_turn (mob.d,90) end
				if mob.stick == 'up' then mob.d = mob_turn (mob.d,180) end
				if mob.stick == 'right' then mob.d = mob_turn (mob.d,270) end

				if mob.stick == 'up' then 
					--mob.stick = nil 
					--mob.flip = mob.flip * -1
				end

			end

		end

end


function candrop (x,y)
	if maptile (x,y+1,'col')==1 then
		return true
	end
end

function inv_ground_sort (x,y)

	local inv = readmap (x,y,'i')
	local s = {}
	local c = {}

	if inv then

		for i,v in ipairs(inv) do
			c[v.i] = (c[v.i] or 0) + 1
		end

		table.sort (inv,function (k1,k2)
			if k1.i==k2.i then
				return k1.t<k2.t
			else
				if c[k1.i]==c[k2.i] then
					return k1.t<k2.t
				else
					return c[k1.i]<c[k2.i]
				end
			end
		end)

		return c[inv[1].i], c

	end

	return 0, c

end

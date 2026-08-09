function carried_block_placement_warning (block_id,support)
	local definition = stone[block_id]
	if support or not definition or not definition.coby then
		return nil
	end

	local localized = msg.stone and msg.stone[block_id]
	return (localized and localized.info) or msg.game[37]
end

local digging_tool_stats = { "dig", "cut", "chop", "smash", "pierce" }

function digging_tool_selection (gather, selected_slot)
	local selection = {
		slot = selected_slot,
		cant = true,
		no_tool = nil,
		bonus = 1,
		needed = nil,
		needed_level = nil,
	}

	if gather.dig == 0 then
		selection.cant = false
		selection.no_tool = true
		return selection
	end

	for _, stat in ipairs(digging_tool_stats) do
		local required_level = gather[stat]
		if required_level then
			local tool_level = inv_itemstat(selected_slot, stat) or 0
			if tool_level >= required_level then
				selection.cant = false
				selection.bonus = tool_level - required_level
				return selection
			end
			selection.needed = stat
			selection.needed_level = required_level
		end
	end

	local minimum_speed = 10
	for slot in pairs(pl.inv) do
		local speed = inv_itemstat(slot, "digspeed") or 0
		for _, stat in ipairs(digging_tool_stats) do
			local required_level = gather[stat]
			local tool_level = inv_itemstat(slot, stat) or 0
			if required_level and tool_level >= required_level
				and minimum_speed > speed then
				selection.slot = slot
				selection.cant = false
				selection.bonus = tool_level - required_level
				minimum_speed = speed
			end
		end
	end

	return selection
end


function moving ()

	game.pass = 'playerpass'

	if pl.unrest > 0 then 
--		return
	end

	if game.inputing then
		return
	end

	-- if pl.questtexting and pl.questing then

	-- 		local dist = math.ceil (math.dist (pl.startx,pl.starty+7,pl.xt,pl.yt))
	-- 		if dist>screen.y/3 and dist<screen.y/2 then 
				 
	-- 			if pl.oldstate~='ave' then
	-- 				pl.state = 'ave'
	-- 			end
				
	-- 			if pl.x>pl.startx then
	-- 				pl.flip = -1
	-- 			else
	-- 				pl.flip = 1
	-- 			end

	-- 			--return
	-- 		end
	-- end
	-- speed

	if pl.state~='ave' and pl.state~='stepup' and pl.state~='stepupb' and pl.state~='fell' and pl.state~='jump' and pl.state~='hang' and pl.state~='pullup' 
		and pl.state~='buttscratch'
		and pl.state~='dying'
		and pl.state~='flex' then
		pl.state = 'idle'
	end


	if pl.idlecnt>7 and pl.state=='idle' and pl.iscarry == nil then
		pl.state = 'buttscratch'
		pl.idlecnt = (-1)*love.math.random (5,10)
	end


	if pl.idlecnt>7 and pl.state=='idle' and pl.iscarry then
		pl.state = 'flex'
		pl.idlecnt = (-1)*love.math.random (5,10)
	end

	
	
	local slow = pl.slowed

	--turbo
	if (is_pressed('rshift') or is_pressed('lshift'))
		and pl.stats.arms.pc>=33 then	
			slow = slow + 1
			pl.turbox = pl.x 
	else
		pl.turbox = nil
	end

	if slow<0 then slow=0.2 end
	
	if pl.stats.arms.pc<33 then 
		pl.speedstat = 3
	elseif pl.stats.arms.pc<66 then
		pl.speedstat = 2
	else
		pl.speedstat = 1
	end


	pl.speed = pl.speeds[pl.speedstat]
	pl.jumpx = pl.jumpxs[pl.speedstat] + pl.jumpxs[pl.speedstat]*((slow-1)/2)
	pl.jumpy = pl.jumpys[pl.speedstat]

	local step = pl.speed*dt*slow
	if pl.iscarry and step>1 then
		step = step * pl.walkcarry
	end

	-- collide
	local points = {}
	--table.insert (points, {x=pl.x+col.x,  y=pl.y+col.y,mode={up = true, down = true, left = true, right = true}}) --левый верхний
	--table.insert (points, {x=pl.x+col.x+col.w,  y=pl.y+col.y,mode={up = true, down = true, left = true, right = true}}) -- правый верхний

	table.insert (points, {x=pl.x+col.x/2,  y=pl.y+col.y,mode={up = true, down = true, left = true, right = true}}) --средний верхний

	table.insert (points, {x=pl.x+col.x+col.w,  y=pl.y+col.y+col.h/2,mode={up = true, down = true,left = true, right = true}}) -- правый средний
	table.insert (points, {x=pl.x+col.x,  y=pl.y+col.y+col.h/2,mode={up = true, down = true,left = true, right = true}}) -- левый средний
	table.insert (points, {x=pl.x+col.x+col.w,  y=pl.y+col.y+col.h,mode={up = true, down = true,left = true, right = true}}) --правый нижний
	table.insert (points, {x=pl.x+col.x,  y=pl.y+col.y+col.h,mode={up = true, down = true,left = true, right = true}}) -- левый нижний
	
	togo = tocollide (points)

	
	-- pick mob
	if is_pressed("space") and pl.digcount==0 then
		local col = col_add ('',pl,'pick','player')
		local col = col_add ('pick',pl,'pick','player')--(id,obj,state,name,t,num)
		local m = collide_check (col,'mob') or collide_check (col,'critter')

		if m and m.n>0 and mobs[m.n] and mobs[m.n].toid then

			pl.state = "pick"

			if currentFrame==4 and pl.oldstate=='pick' then
				inv_add (item_make(mobs[m.n].toid))
				mob_destory (m.n)
				pl.digcount = -1
			end

		end
	
	end



	if is_pressed("space") == false and pl.iscarry then
		pl.candrop = 1
	end


	-- drop brick 
	if is_pressed("space") and pl.candrop == 1 and pl.iscarry
		--and ((stone[pl.iscarry.b].coby and pl.cob) or stone[pl.iscarry.b].coby==nil)
		then

		local br = {}
		br.x = pl.xt
		br.y = pl.yt

		if pl.flip == 1 then 
			br.x = br.x + 1
		else
			br.x = br.x - 1
		end

		local placement_warning = carried_block_placement_warning (
			pl.iscarry.b,
			pl.cob
		)
		if placement_warning then
			textwall (placement_warning)
			-- Consume this press. Without this guard the failed placement returned
			-- from moving every frame until Space was released, leaving the player
			-- apparently stuck without explaining the attachment requirement.
			pl.candrop = 0
			return
		end

		if pl.cob then
			br.x = pl.cob[1]
			br.y = pl.cob[2]
		end

		-- low drop
		if maptile (br.x,br.y,'solid') == 1 then
			br.y = br.y - 1
		end

		-- bottom drop
		if maptile (br.x,br.y,'solid') == 1 then
			br.x = pl.xt
			br.y = pl.yt+1
		end

		if maptile (br.x,br.y,'solid') == 0 then 

			local i = 1
			while maptile (br.x,br.y+i,'solid')==0 do
				i = i + 1
			end

			if maptile (br.x,br.y+i,'unstack') == nil or maptile (br.x,br.y+i,'unstack') == 0 or pl.cob then

				local i = world[br.y][br.x].i

				local de = stone[readmap (br.x,br.y,'b')]

				local de2
				local de3
				if de and de.ondestroy then
					de2, de3 = de.ondestroy (br.x,br.y,pl.iscarry.b)
				end
				
				if de2 then
					
					writemap (br.x, br.y, de2)

					if de3 then
						if readmap (br.x,br.y-1,'b')==0 then
							writemap (br.x,br.y-1,de3)	
						end
					end

				else
					
					local w = readmap (br.x, br.y, 'w')
					local dr = readmap (br.x, br.y, 'dr')
					local room = readmap (br.x, br.y, 'room')
					
					
					writemap (br.x, br.y, pl.iscarry,"all")

					if w then
						writemap (br.x,br.y,w,'w')
						writemap (br.x,br.y,dr,'dr')
					end

					writemap (br.x,br.y,room,'room')

					--world[br.y][br.x] = pl.iscarry

				end

				if pl.iscarry and pl.iscarry.i then

					i = i or {}
					for k,v in pairs(pl.iscarry.i) do
					table.insert(i,v)
					end

				end

				world[br.y][br.x].i = i

				writemap (br.x, br.y, 0, "f")

				local de = stone[readmap (br.x,br.y,'b')]
				if de.onfalling then
					de.onfalling (br.x, br.y)
				end

				pl.iscarry = nil
				pl.candrop = 0
				pl.digcount = -1
			
			end
		end


	end




	-- throwing item
	--and type(pl.invselect)=='number'
	if (is_pressed("r") or love.mouse.isDown(2)) and pl.inv[pl.invselect] and item[pl.inv[pl.invselect].i].throw~=nil  then

		local ithrow = pl.inv[pl.invselect]

		if ithrow then
			ithrow = item[ithrow.i].throw or 1
			ithrow = pl.throwmax * ithrow
		else
			ithrow = 1
		end

		--sling
		if pl.inv['r'] and item[pl.inv['r'].i].sling then
			if in_array (item[pl.inv['r'].i].sling.items, pl.inv[pl.invselect].i) then
				--print (ithrow.." ")
				ithrow = ithrow * item[pl.inv['r'].i].sling.add
				--print (ithrow)
				
			end
		end

		--throwing cd
		game.throwcd = (game.throwcd or 0) + dt

		if (pl.canthrow==1 or pl.canthrow<0) and ithrow>0 then

			pl.throw = math.dist(pl.x,pl.y,mouse_x,mouse_y)
		 	pl.throw = pl.throw * 3


		 	if pl.throw > ithrow then pl.throw = ithrow end
		 	--pl.throw = ithrow)

		 	dumpout3 = math.floor (pl.throw/ithrow*100)

		 	--dumpout3 = draw_pc (math.floor (pl.throw/ithrow*100)-10)

			if not is_pressed("a") and not is_pressed("d") then

				if pl.x>mouse_x then
				pl.flip = -1
				else
				pl.flip = 1
				end

			end
		 	
		 	if pl.throw <= 0 then
		 		pl.throw = 0
		 		pl.canthrow = 0
		 	end


		 	--test throw
		 	testthrow = (testthrow or 0)

		 	if mousemoved_last==0 and testthrow>=10 then
		 		testproj_kill ()
		 	end

		 	if testthrow<10 and mousemoved_last>0.4 then

		 		testthrow = testthrow + 1
			 	local xth = pl.x - mouse_x
				local yth = pl.y - mouse_y

				local ya = math.cos (math.atan2 (yth,xth))
				local ya2 = math.sin (math.atan2 (yth,xth))

				local b = {1,1,1,1}

				if pl.inv[pl.invselect] then
					b = item[pl.inv[pl.invselect].i].bounce
				end

				local m =
				{
					x = pl.x,
					y = pl.y,
					xspeed = pl.throw * (ya) * -1,
					yspeed = pl.throw * (ya2) * -1,
					bounce = b,
					proj = 15
				}

				if oxth and oxth~=xth and oyth~=yth then
--		 			testproj_kill ()
		 		end

				oxth = xth
				oyth = yth

				proj[next_numeric_id(proj)] = m
			end


		 end

	else
		
		local pc = math.ceil ((game.throwcd or 0)/pl.throwcd * 5)
		game.throwcd = nil

		pl.canthrow = 1
		dumpout3 = nil

		if pl.throw>0 then

			testproj_kill ()
	
			if pl.inv[pl.invselect] and item[pl.inv[pl.invselect].i].throw~=nil and pc>=5 then

				local xth = pl.x - mouse_x
			 	local yth = pl.y - mouse_y
			 	local ya = math.cos (math.atan2 (yth,xth))
				local ya2 = math.sin (math.atan2 (yth,xth))

			 	local oth = item[pl.inv[pl.invselect].i].onthrow

			 	if oth then
			 		oth = item[pl.inv[pl.invselect].i].onthrow (pl.invselect)
			 	end

			 	local i = oth or inv_remove (pl.invselect)

			 	local p = item[i.i].proj or 1

			 	--print ("x:"..ya.." y:"..ya2)

			 	local m =
				{
					x = pl.x,
					y = pl.y,
					xspeed = pl.throw * (ya) * -1,
					yspeed = pl.throw * (ya2) * -1,
					bounce = item[i.i].bounce,
					inv = i,
					proj = p
				}

				proj[next_numeric_id(proj)] = m
				pl.throw = 0

			else
				
				pl.throw = 0

			end

		end
	end






	-- local climb = maptile (pl.xt, pl.yt, 'climb') or 0
	-- local climb2 = maptile (pl.xt, pl.yt-1, 'climb') or 0
	-- local climb_stand = maptile (pl.xt, pl.yt+1, 'climb') or 0
	local dij

	if ((is_pressed("a") or is_pressed("d")) and is_pressed("w")) then
		dij = true
	end

	--climb
	local xcl = pl.x + math.floor (col.x/2)
	local ycl = pl.y + col.y+col.h+1 
	local r = px2tile (xcl,ycl)
	local cclimb = maptile (r.x, r.y,'climb') or 0
	local cclimbup = maptile (r.x, r.y-1,'climb') or 0

	local solid = (maptile (pl.xt, pl.yt,'col') or 0) + (maptile (pl.xt, pl.yt-1,'col') or 0)
	if solid == 0 then solid = nil end

	--dump (solid)
	

	local bridge = maptile (r.x, r.y,'bridge') or 0


	local ycl = pl.y + col.y+col.h 
	local r = px2tile (xcl,ycl)
	local cclimbdown = maptile (r.x, r.y,'climb') or 0

	if pl.cantclimb then

		if cclimb == 0 and cclimbup == 0 and cclimbdown == 0 then
			pl.cantclimb = nil
		end

		cclimb = 0
		cclimbup = 0
		cclimbdown = 0
	end


	if cclimb==1 and pl.state~='hang' and pl.state~='pullup' then
		pl.isclimbing = true

		if cclimbup==0 and cclimbdown==0 then
			pl.isclimbing = nil
		end

	else
		pl.isclimbing = nil
	end

	-- stick to the end of ladder
	if not is_pressed("s") and cclimbup == 0 and cclimb == 1 and cclimbdown == 1 then
		
		if pl.ly>1 and pl.ly<10 then
			pl.y = pl.y - pl.ly+1
			pl.state = "idle"
			pl.jumpleft = 0
			pl.isclimbing = nil
		end

		pl.topladder = true

	else
		pl.topladder = nil
	end


	if pl.isclimbing and pl.state ~= 'stepup' and pl.state ~= 'stepupb' and pl.state~='hang' and pl.state~='pullup' then
		pl.anispeed = 0
	else
		pl.anispeed = math.max (0.8, slow)
	end




	--print (pl.ly.." "..cclimbup.." "..cclimb.." "..cclimbdown)

	-- climb
	if is_pressed("s") and cclimb==1 and dij==nil then
		pl.anispeed = 1.5
		pl.y = pl.y + math.min(step*1.75,togo.down)
		--climb to middle
		if (pl.lx-8)<0 then pl.x = pl.x + 1 end
		if (pl.lx-8)>0 then pl.x = pl.x - 1 end
		pl.jumpleft = 0
		if pl.stats.arms.hp>70 then stat_spend ("arms", 0.02*step) end
		game.time = math.floor (game.time) + math.ceil (step)
	end

	--cclimb==1 and cclimbdown==1
	if is_pressed("w") and not is_pressed("space") and pl.isclimbing and dij==nil then
		pl.anispeed = 1
		pl.y = pl.y - math.min(step*0.75,togo.up)
		--climb to middle
		if (pl.lx-8)<0 then pl.x = pl.x + 1 end
		if (pl.lx-8)>0 then pl.x = pl.x - 1 end
		pl.jumpleft = 0
		if pl.stats.arms.hp>70 then stat_spend ("arms", 0.02*step) end
		game.time = math.floor (game.time) + math.ceil (step)
	end
	

	-- не стучаться головой если низко
	if togo.up<10 and togo.down==0 then
		--pl.jumpleft = 0
	end

	if cclimb==1 and dij==nil then
		pl.jumpleft = 0
	end

	if cclimb==1 and dij then
	 	if pl.buffs[10] then --farts
	 		pl.jumpleft = 2
	 	else
	 		pl.jumpleft = 1
	 	end
	end


	--if pl.buffs[13] then pl.jumpleft = 0 end
	-- jump
	if is_pressed("w") and not is_pressed("space") 
		and pl.jumpleft > 0 and pl.jumppress==nil then  
		--pl.digcount = -1 

		if togo.down~=0 then
			pl.cantclimb = true
		end

		sound_add ('jump', 9,{x = pl.flip*(-0.5), y = 1})

		--if math.ceil(togo.down) == 0 or (cclimb==1 and dij) then

			local mul = 1

			if pl.iscarry ~= nil then
				mul = pl.jumpcarry
			end

			pl.yspeed = pl.jumpy * (-1) * mul * math.max (0,pl.jumpyslow)

			if is_pressed("d") then
				pl.xspeed = pl.jumpx * mul * pl.jumpxslow
			end

			if is_pressed("a") then
				pl.xspeed = pl.jumpx * mul * -1 * pl.jumpxslow
			end

			pl.jumppress = true
			pl.jumpleft = pl.jumpleft - 1

			stat_spend ('arms',1)

			if pl.turbox then
				local a = 3+(3*(100-pl.stats.arms.pc)/100)
				--print (a)
				stat_spend ('arms',a)
			end

		--end

	end


	if cclimb==1 and dij==nil then
		pl.yspeed = 0
	end


	if not is_pressed("w") then
		pl.jumppress = nil
		if math.ceil(togo.down) == 0 or (cclimb==1 and dij) then
			
			if pl.state=='fell' or pl.state=='jump' then
				pl.state = 'idle'
			end

			if pl.buffs[10] then --farts
		 		pl.jumpleft = 2
		 	else
		 		pl.jumpleft = 1
		 	end

		end
	end


	-- hit ceiling
	if (togo.up == 0 or not is_pressed("w")) and pl.yspeed < 0 then
		pl.yspeed = 0
	end


	--trying to hang
	if togo.down > 0 and cclimb==0 and bridge==0 and gr[pl.state].nofall==nil 
		and pl.yspeed~=0
		--and pl.xspeed==0 
		and cclimb~=1
		and not is_pressed("s")
		and solid == nil
		then

		
		local points = {}
		local dir = ""

		if pl.flip==1 then
			table.insert (points, {x=pl.x+col.x+col.w,  y=pl.y+col.y,mode={up = true, down = true, left = true, right = true}}) -- правый верхний
			dir = 'right'
		else
			table.insert (points, {x=pl.x+col.x,  y=pl.y+col.y,mode={up = true, down = true, left = true, right = true}}) --левый верхний
			dir = 'left'
		end

		-- hang check while falling
		local hang = tocollide (points)
		--dump (hang)
		--love.timer.sleep(0.1)

		if pl.iscarry == nil and pl.hangcancel==nil then
			if pl.is.hangold and pl.is.hangold~=hang[dir] and hang[dir]<13 then

				local r
				if pl.flip==1 then
					r = px2tile (pl.x+col.x+col.w+1+hang[dir], pl.y+col.y-10)
				else
					r = px2tile (pl.x+col.x-10-hang[dir], pl.y+col.y-10)
				end

				--writemap (r.x,r.y,64)
				--writemap (r.x,r.y-1,64)
				
				if maptile (r.x, r.y,'col')==0 and maptile (r.x, r.y-1,'col')==0 
					and readmap (r.x, r.y-1,'f')==nil 
					and maptile (pl.tx, pl.ty,'col')==0 --ladder
					then

					--writemap (pl.tx, pl.ty,32)
					--print 'hang!'

					pl.y = pl.y - (63 - hang.down) --height fix
			
					pl.x = pl.x + hang[dir]*pl.flip
					pl.jumpleft = 0
					pl.xspeed = 0
					pl.state = 'hang'
					pl.is.hangtime = 0
					pl.fell = 0
					pl.yspeed = 0

				end
			end

		end

		pl.is.hangold = hang[dir]

	end

	if pl.state == 'hang' 
		and maptile (pl.xt,pl.yt-2,'col')==0 --free on top
		and maptile (pl.xt,pl.yt-1,'col')==0 --free on top
		and (is_pressed("w") or
		(pl.flip == 1 and is_pressed("d")) or
		(pl.flip == -1 and is_pressed("a"))) then
			stat_spend ("arms",1)
			pl.state = 'pullup'
			--writemap (pl.xt,pl.yt-1,4)
	end

	if pl.state == 'hang' then
		pl.is.hangtime = pl.is.hangtime + dt
	end

	if pl.state == 'hang' and (is_pressed("s") or pl.is.hangtime>2) then
		stat_spend ("arms",1)
		pl.state = 'fall'
		pl.hangcancel = true
	end



	-- can go down
	if togo.down > 0 and cclimb==0 and bridge==0 and gr[pl.state].nofall==nil then

		if game.lastgodown == nil and pl.state~='jump' and pl.state~='fall' then
			
			pl.jumpleft = pl.jumpleft - 1

			if is_pressed("d") then
				pl.xspeed = pl.xspeed + 1
			end

			if is_pressed("a") then
				pl.xspeed = pl.xspeed - 1
			end

		end

		pl.yspeed = pl.yspeed + 0.7

		if pl.yspeed == 0 then
			pl.yspeed = 0.1
		end
		
		local md = 30*dt
		if pl.yspeed > 0 then
			md = md * (-1)
		end

		if pl.yspeed > 12 then
			pl.yspeed = 12
		end

		if pl.yspeed>0 then
			pl.fell = pl.fell + math.min(pl.yspeed,togo.down)
		end

		game.lastgodown = true

	else

		game.lastgodown = nil
		pl.hangcancel = nil

	end
	



	if pl.yspeed>0 and gr[pl.state].nofall==nil then
		pl.y = pl.y + math.min(pl.yspeed,togo.down)
		pl.state = "fall"
	end

	if pl.yspeed<0 then
		pl.state = "jump"
		--if (currentFrame>1 and pl.state=='jump') or pl.state~="jump" then
			local l = math.min((-1)*pl.yspeed,togo.up)
			pl.y = pl.y - l 
		--end
		
	end



	if pl.xspeed>0 then

		if pl.xspeed>8 then pl.xspeed = 8 end
		pl.x = pl.x + math.min(pl.xspeed,togo.right)
		if togo.down>0 and ((togo.right == 0 and pl.yspeed > 0) or not is_pressed("d")) then
			pl.xspeed = 1
		end

		if togo.right < 1 and togo.down == 0 then pl.xspeed = pl.xspeed*0.5 end
		
	end

	if pl.xspeed<0 then

		if pl.xspeed<-8 then pl.xspeed = -8 end
		local l = math.min((-1)*pl.xspeed,togo.left)
		if togo.down>0 and ((togo.left == 0 and pl.yspeed > 0) or not is_pressed("a")) then
			pl.xspeed = -1
		end
		pl.x = pl.x - l 

		if togo.left < 1 and togo.down == 0 then pl.xspeed = pl.xspeed*0.5 end
		
	end


	local points = {}
	--table.insert (points, {x=pl.x+col.x,  y=pl.y+col.y,mode={up = true, down = true, left = true, right = true}}) --левый верхний
	--table.insert (points, {x=pl.x+col.x+col.w,  y=pl.y+col.y,mode={up = true, down = true, left = true, right = true}}) -- правый верхний

	table.insert (points, {x=pl.x+col.x/2,  y=pl.y+col.y,mode={up = true, down = true, left = true, right = true}}) --средний верхний

	table.insert (points, {x=pl.x+col.x+col.w,  y=pl.y+col.y+col.h/2,mode={up = true, down = true,left = true, right = true}}) -- правый средний
	table.insert (points, {x=pl.x+col.x,  y=pl.y+col.y+col.h/2,mode={up = true, down = true,left = true, right = true}}) -- левый средний
	table.insert (points, {x=pl.x+col.x+col.w,  y=pl.y+col.y+col.h,mode={up = true, down = true,left = true, right = true}}) --правый нижний
	table.insert (points, {x=pl.x+col.x,  y=pl.y+col.y+col.h,mode={up = true, down = true,left = true, right = true}}) -- левый нижний
	
	togo = tocollide (points)


	--unclip
	if togo.x and (pl.state=='kick' or pl.state=='idle' or pl.state=='walk') then
		if togo.x > 0 and maptile (pl.xt+1,pl.yt,'col')==0 and maptile (pl.xt+1,pl.yt-1,'col')==0 then pl.x = pl.x + togo.x pl.x = pl.x + 3 end
		if togo.x < 0 and maptile (pl.xt-1,pl.yt,'col')==0 and maptile (pl.xt-1,pl.yt-1,'col')==0 then pl.x = pl.x + togo.x pl.x = pl.x - 3 end
	end

	if math.ceil(togo.down) == 0 or (cclimb==1 and dij==nil) then

			pl.cantclimb = nil

			if pl.xspeed ~= 0 then
				
				local s = maptile (pl.xt, pl.yt+1,"slide") or 0.7
				if s == 0 then s = 0.7 end
				if cclimb==1 then s=0 end

				pl.xspeed = pl.xspeed*s
				if pl.xspeed<0.1 and pl.xspeed>-0.1 then
					pl.xspeed = 0
				end
			end

		--end

		
		if cclimb==1 then pl.fell=0 end

		-- falling gamage and land
		if pl.fell>0 then

			sound_add ('land',8,{volume = 0.1 + 0.15*pl.fell/32})

			pl.yspeed = 0

			tile, map = maptile (pl.xt, pl.yt+1,"all")

			
			-- if map.b ~= 47 then --ice
			-- 	--pl.xspeed = 0
			-- else
			-- 	pl.xspeed = pl.xspeed * 1.5
			-- end

			pl.fell = math.floor (pl.fell/32)

			--print (pl.fell)

			-- fall gamage
			if pl.fell>5 then
				--pl.fell = pl.fell - 3
				--stat_spend ("arms", pl.fell)
				pl.fell = math.floor (2 * pl.fell^2.1)
			end

			local dmg = math.floor (pl.fell/20)

			if dmg>50 then
				buff_add (7)
			end

			if dmg>0 then
				player_hit (dmg)
			end

			pl.fell = 0

		end


		local mul = 1
		local gameplay_mouse_down = love.mouse.isDown(1) and not game.gui_mouse_down
		--if cclimb==1 and maptile (r.x,r.y+1,'col')==0 then mul = 0.5 end

		-- walk right
		if (not is_pressed("e") and not gameplay_mouse_down) and is_pressed("d") and pl.state~='pullup' then

			--pl.iswalking=true
			pl.flip = 1

			--cclimb~=1 and
			if  togo.right<5 and pl.iscarry==nil and not is_pressed("s") and (togo.down<=0 or math.ceil (togo.down)==32) 
				and solid == nil then		

				if maptile (pl.tx+1,pl.ty-1,'col')==0 and maptile (pl.tx+1,pl.ty-2,'col')==0
					and readmap (pl.tx+1,pl.ty,'f')==nil --fallin block
					and maptile (pl.tx,pl.ty-2,'col')==0  --over head
					and pl.yspeed == 0
					then

					if pl.state~='stepup' and pl.state~='stepupb' then

						if game.stepup then
							pl.state = 'stepupb'
							game.stepup = not game.stepup
						else
							pl.state = 'stepup'
							game.stepup = not game.stepup
						end
					end
				end

				--pullup if close
				if maptile (pl.tx+1,pl.ty-1,'col')==1 and maptile (pl.tx+1,pl.ty-2,'col')==0 and maptile (pl.tx+1,pl.ty-3,'col') == 0
					and maptile (pl.tx,pl.ty-2,'col')==0 --over head
					and maptile (pl.tx+1,pl.ty-3,'col')==0 --after climb
					and togo.right<4
					then
					pl.state = 'hang'
					pl.x = pl.x + togo.right*pl.flip
					pl.y = pl.y - 9
					pl.jumpleft = 0
					pl.xspeed = 0
					pl.is.hangtime = 0
					pl.fell = 0
					pl.yspeed = 0
				end

			else

				--climb to the wall fix
				if togo.right==0 and cclimb==1 then
					pl.y = pl.y - math.min(step*1.75,togo.up)
				end

				pl.anispeed = math.max (0.8, pl.slowed)
				--print (pl.anispeed)

				pl.digcount = 0
				if pl.state ~= 'stepup' and pl.state ~= "jump" and pl.state~='fall' then pl.state = "walk" end
				pl.x = pl.x + math.min(step*mul,togo.right)
				
				if togo.right>0 and not game.dbg[2] then game.time = game.time + 1 end
				pl.moving = 'right'

				if pl.xspeed < 0 then
					pl.xspeed = pl.xspeed + dt*2
					if pl.xspeed > 0 then pl.xspeed = 0 end
				end

			end

		end


		--walk left
		if (not is_pressed("e") and not gameplay_mouse_down) and is_pressed("a") and pl.state~='pullup' then

			--pl.iswalking = true
			pl.flip = -1

			--dump (togo.down)
			--cclimb~=1 and 

			if togo.left<5 and pl.iscarry==nil and not is_pressed("s") and (togo.down<=0 or math.ceil (togo.down)==32) 
				and solid == nil then
--		
				if maptile (pl.tx-1,pl.ty-1,'col')==0 and maptile (pl.tx-1,pl.ty-2,'col')==0 
					and readmap (pl.tx-1,pl.ty,'f')==nil --fallin block
					and maptile (pl.tx,pl.ty-2,'col')==0 --over head
					and pl.yspeed == 0
					then
					
					if pl.state~='stepup' and pl.state~='stepupb' then
						if game.stepup then
							pl.state = 'stepupb'
							game.stepup = not game.stepup
						else
							pl.state = 'stepup'
							game.stepup = not game.stepup
						end
					end
				end

				--pullup if close
				if maptile (pl.tx-1,pl.ty-1,'col')==1 and maptile (pl.tx-1,pl.ty-2,'col')==0 and maptile (pl.tx-1,pl.ty-3,'col') == 0
					and maptile (pl.tx,pl.ty-2,'col')==0 --over head
					and maptile (pl.tx-1,pl.ty-3,'col')==0 --after climb
					and togo.left<4
					then
					pl.state = 'hang'
					pl.x = pl.x + togo.left*pl.flip
					pl.y = pl.y - 9
					pl.jumpleft = 0
					pl.xspeed = 0
					pl.is.hangtime = 0
					pl.fell = 0
					pl.yspeed = 0
				end

			else

				--climb to the wall fix
				if togo.left==0 and cclimb==1 then
					pl.y = pl.y - math.min(step*1.75,togo.up)
				end

				pl.anispeed = math.max (0.8, pl.slowed)
				pl.digcount = 0 
				if pl.state ~= "jump" and pl.state~='fall' then pl.state = "walk" end
				pl.x = pl.x - math.min(step*mul,togo.left)
				
				if togo.left>0 and not game.dbg[2] then game.time = game.time + 1 end
				pl.moving = 'left'

				if pl.xspeed > 0 then
					pl.xspeed = pl.xspeed - dt*2
					if pl.xspeed < 0 then pl.xspeed = 0 end
				end

			end

		end

		if gameplay_mouse_down and pl.state~='pick' then
			-- if pl.x > mouse_x then pl.flip = -1 end
			-- if pl.x < mouse_x then pl.flip = 1 end
		end

		local old_anis = pl.anispeed 

		if not is_pressed("a") and not is_pressed("d") then
			pl.iswalking = nil
		end

		if (is_pressed("e") or gameplay_mouse_down) and pl.iscarry == nil then
			
			if pl.oldstate~='kick' then

				local r = px2tile (mouse_x,mouse_y)
				ground = readmap (r.x,r.y,'b') or 0

				if ground>0 then
					pl.inspect = ground
					block_inspect ()
				end

			end

			pl.state = "kick"


			if not is_pressed("e") then

				if pl.x > mouse_x+16 and pl.flip~=-1 then 
					pl.flip = -1 
					currentTime = 0
					currentFrame = 2
				end
				
				if pl.x < mouse_x-16 and pl.flip~=1 then 
					pl.flip = 1 
					currentTime = 0
					currentFrame = 2
				end

			else

				if currentFrame < 3 and is_pressed ('d') then
					pl.flip = 1
				end

				if currentFrame < 3 and is_pressed ('a') then
					pl.flip = -1
				end

			end

			local it = pl.inv.r

			if it==nil then
				it = pl.inv[pl.invselect]
			end

			if it and it.tool and it.tool.digspeed then
				pl.anispeed = math.max (0.8, pl.slowed)
				pl.anispeed = pl.anispeed / (it.tool.digspeed or 1)
				--it.tool.digspeed
			else
				it = pl.inv[pl.invselect]
			end

			--print (it.tool.digspeed or 1)

			if pl.oldstate == 'kick' then

				if currentFrame == 5 then
					sound_add ('whoosh',21, {x = pl.flip*0.5, y = 1})
				end

			
				if currentFrame == 10 then
					sound_add ('whoosh2',22, {x = pl.flip*0.5, y = -1})
				end

				if currentFrame == 7 then
					sound_add ("step1",30)
				end

				-- if currentFrame == 11 then
				-- 	sound_add ("step2",30)
				-- end


				if currentFrame == 12 then
					sound_add ('whoosh3',23, {x = pl.flip*0.5, y = 0})
				end
			end

			--autopick right tool
			if currentFrame == 4 and pl.state == "kick" and (it==nil or it.tool==nil or it.tool.dmgmin==nil) then
			
				local mins = 0
				for ii=1,pl.invsize do
					local it = pl.inv[ii]

					local dps = 0
					if it and it.tool then
						dps = tool_damage_per_second(it.tool)
					end
	
					if dps>mins then
						pl.invselect = ii
						mins = dps
					end
				end
			end


			game.attackcursor = 1
			game.attackcd = (game.attackcd or 0) + dt

			if currentFrame>5 then
				game.attackcd = 0
				--game.attacked=nil
			end

			if pl.oldstate == 'kick' then
				game.attackcursor = currentFrame
				if game.attackcursor>3 then game.attackcursor=3 end
				if game.attackcursor<1 then game.attackcursor=1 end
			else
				game.attackcursor = 1
			end
			--if pc>3 then pc = 3 end
			
		
			--print (currentFrame.." "..dumpvar(game.attacked))

			if pl.oldstate == 'kick' and 
				((currentFrame==5 and game.attacked~=5) or
				(currentFrame==10 and game.attacked~=10))
				then

				game.attacked = currentFrame

				--print (currentFrame.." "..game.attacked)

				--print (cycleTime)
				--print (game.attackcd)

				game.attackcd = nil

				col_add ('strike',pl,'strike','player','kick')
				local m = collide_check ('strike','mob') or collide_check ('strike','critter')

				if m and m.n>0 then

					local id
					if pl.inv.r then
						id = 'r'
					else 
						id = pl.invselect
					end

					local spend = 3 * (inv_itemstat (id,'dighands') or 1)
					stat_spend ("arms",spend)
					local dmg = love.math.random (inv_itemstat (id,'dmgmin') or 1,inv_itemstat (id,'dmgmax') or 1)

					if currentFrame == 5 then
						dmg = math.ceil (dmg * 0.5)
					end

					dmg = dmg + (pl.adddamage or 0)

					--dump (pl.adddamage)

					mob_hit (m.n, dmg)

					if pl.inv[id] then
						if item[pl.inv[id].i].onhit then
							item[pl.inv[id].i].onhit (pl.x, pl.y, 'melee',m)
						end

						if item[pl.inv[id].i].tool then
							pl.inv[id].t = pl.inv[id].t - (item[pl.inv[id].i].tool.hithit or 1)
						end
					end

				end

			end

		else
			game.attackcd = nil
			game.attacked = nil
			game.attackcursor = nil
			pl.anispeed = old_anis
		end


	end







	-- digging

	if is_pressed("space") and pl.digcount > -1 and pl.iscarry == nil and pl.isjump == 0 and pl.state ~= 'pick' 
		and (pl.state =='idle' or pl.state == 'dig') then

		--print (pl.state..' dig'..game.dt)

		haswater = nil

		if pl.digxt then
			r.x = pl.digxt
			r.y = pl.digyt
		else
			r.x = pl.xt
			r.y = pl.yt

			--and togo.up<10
			if is_pressed("w") and pl.iscarry == nil then

				-- dig up
				r.y = r.y - 1
				
				--climb fix
				if (maptile (r.x,r.y,'gather') or 0) == 0 or maptile (r.x,r.y-1,'dpr') == 1 then
					r.y = r.y - 1
				end

				pl.digstart = 1
			
			else

				if pl.flip == 1 then 
					r.x = r.x + 1
				else
					r.x = r.x - 1
				end

				-- higher leverl

				if not is_pressed("s") then
					r.y = r.y - 1
				end

				pl.digstart = 2
				

				--same level
				if (maptile (r.x,r.y,'gather') or 0) == 0 or maptile (r.x,r.y-1,'dpr') == 1 then
					r.y = r.y + 1
				end

				-- under feet
				if (maptile (r.x,r.y,'gather') or 0) == 0 or maptile (r.x,r.y-1,'dpr') == 1 then
					r.y = r.y + 1
					pl.digstart = 3
				end


				-- under char
				if (maptile (r.x,r.y,'gather') or 0) == 0 or maptile (r.x,r.y-1,'dpr') == 1 then
					
					r.y = r.y - 1
					
					if pl.flip == 1 then 
						r.x = r.x - 1
					else
						r.x = r.x + 1
					end

					pl.digstart = 3
				end

			end

			pl.digxt = r.x
			pl.digyt = r.y

		end




		local gather = maptile (r.x,r.y,'gather') or 0


		if gather and gather~=0 and maptile (r.x,r.y-1,'dpr') ~=1 then

			local tile, map = maptile (r.x,r.y,"all")

			pl.state = "dig"
			pl.digcount = tonumber (pl.digcount) + dt

			local r2 = tile2px (r.x,r.y)
			pl.digx = r2.x
			pl.digy = r2.y

			local m = tile.digtime
			local dig = tile.dig

			local digging_tool = digging_tool_selection(gather, pl.invselect)
			local dig_tool_slot = digging_tool.slot
			local needed = digging_tool.needed
			local neededn = digging_tool.needed_level
			pl.digcant = digging_tool.cant
			pl.no_tool_dig = digging_tool.no_tool
			pl.toolbonus = digging_tool.bonus


			if pl.digcant == false then
				sound_add ('dig',25,{x = pl.flip, y = -1})
			end


			if m>0 then

				if pl.stats.arms.pc<33 then 
					pl.digspeed = 3
				elseif pl.stats.arms.pc<66 then
					pl.digspeed = 2
				else
					pl.digspeed = 1
				end

				if pl.buffs[9] then
					pl.digspeed = pl.digspeed * 0.5
				end

				if pl.no_tool_dig == true then
					pl.toolbonus = 0
				end
				
				pl.toolbonus = 1-(pl.toolbonus*0.15)
				if pl.toolbonus<0.3 then
					pl.toolbonus = 0.3
				end



				pl.digspeed = pl.digspeed * pl.toolbonus
				pl.digspeed = pl.digspeed / pl.slowed

				pl.digspeed = pl.digspeed / (pl.digslowed or 1)

				-- if pl.inv['r'] and item[pl.inv['r'].i].shovel then
					
				-- end

				--print (tostring(pl.no_tool_dig))

				if inv_itemstat(dig_tool_slot,'digspeed') and pl.no_tool_dig==nil then
					pl.digspeed = pl.digspeed * inv_itemstat(dig_tool_slot,'digspeed')
				end

				--print (inv_itemstat(dig_tool_slot,'digspeed'))

				if pl.digcant and pl.digdone>50 then
					pl.digback = true
					textwall (msg.gui.itemlack[needed],false,{[1] = neededn})
				end

				local hasgloves = (pl.inv.a and pl.inv.a.i==357)
				local de = readmap (r.x,r.y,"de") or 0
				if de>cf.deadfire and pl.digdone>50 and hasgloves~=true then
					player_hit (cf.firehit)
					textwall (msg.game[6]) 
					pl.digback = true
					pl.digdone = 0
				end

				if pl.digback then
					pl.digdone = pl.digdone * 0.95
					pl.digcount = pl.digcount * 0.95

					if pl.digdone<5 then
						pl.digcount = -1 
					end

				else
					pl.digdone = math.floor ((pl.digcount/pl.digspeed)/m*100)
				end

			end

			--dump (1/0.7)
			--dump (1/(m/pl.digspeed))
			pl.diganispeed = ((1.1) * (1/(m/pl.digspeed)))
			if pl.diganispeed < 1 then pl.diganispeed = 1 end

			if m>0 and pl.digdone>99 then

				-- wearing off
				local stat = 'arms'

				m = m * (pl.digspend or 1)
				if inv_itemstat(dig_tool_slot,'dighands') then
					stat_spend (stat, m*inv_itemstat(dig_tool_slot,'dighands'))
				else
					stat_spend (stat, m)
				end

				stat_spend ('water', m*0.05)


				game.time = game.time + m * 50 --32
				game.recovery = game.recovery + m * 50

				if pl.no_tool_dig==nil and inv_itemstat(dig_tool_slot,'dighit') then
					local t = inv_item(dig_tool_slot,'t')
					t = t - inv_itemstat(dig_tool_slot,'dighit')
					inv_item (dig_tool_slot,'t',t)
				end


				local done

				if tile.ondig then
					done = tile.ondig (r.x,r.y,tile,map)
				end

				if done then 
					pl.digcount = -1
					pl.candrop = 0
					game.digdone = 1
				end


				if done==nil then

					local l = maptile(r.x,r.y,'loot')

					if l and l~=0 then 
						l = loot_make (l)
						achi_trigger ('on_dug',l,1)
						inv_add (item_make (l))
					end

					m = maptile (r.x,r.y,'digtoinv')
					

					if m and m>0 then

						local itm = item_make(m)
						local ittl = readmap (r.x,r.y,'ittl')
						if ittl then 
							itm.t = ittl
						end

						if inv_add (itm) then
							achi_trigger ('on_dug',m,1)
							writemap(r.x,r.y,maptile (r.x,r.y,'digtoid'))
						end

						pl.digcount = -1 

					end
						
					local b = maptile (r.x,r.y,'digtoid')
					writemap(r.x,r.y,b)

					local ondug = tile.ondug

					if ondug then
						ondug (r.x,r.y)
					end
					
					
					local container = stone[b] and stone[b].cont
					local wadd
					local wdirt

					if b>0 then

						pl.iscarry = readmap (r.x,r.y)
						if container==nil then pl.iscarry.i = nil end

						if pl.iscarry.w then
							wadd = (readmap (r.x,r.y,'w') or 0)
							wdirt = (readmap (r.x,r.y,'dr') or 0)
							pl.iscarry.w = nil
						end
						
					end

					local i = readmap (r.x,r.y,'i')
					writemap(r.x,r.y,0,'clear')

					if wadd then 
						writemap (r.x, r.y, wadd, 'w')
						writemap (r.x, r.y, wdirt, 'dr')
					end
							
					if container==nil then writemap(r.x,r.y,i,'i') end

					pl.digcount = -1
					pl.candrop = 0

					game.digdone = 1
					game.moved = true

				end

			end

		end

	else
		sound_stop ('dig')
	end


	--if not is_pressed("space") then
	if pl.state~='dig' and not is_pressed("space") then
		pl.digxt = nil
		pl.digyt = nil
		pl.digcount = 0
		pl.digdone = 0
		pl.digback = false
	end




	if is_pressed("d") and (pl.state=='jump' or pl.state=='fall') then
		pl.flip = 1
	end

	if is_pressed("a") and (pl.state=='jump' or pl.state=='fall') then
		pl.flip = -1
	end


	if pl.isclimbing and pl.iswalking==nil 
		and pl.state ~= 'kick' and pl.state ~= 'stepup' and pl.state ~= 'stepupb' and pl.state~='hang' and pl.state~='pullup'
		then
		pl.state = 'climb'
		if pl.cantclimb==nil then pl.yspeed = 0 end
	end

	-- if pl.state == "walk" or pl.state == "stepup" or pl.state == "stepupb" 
	-- 	or (pl.state == "climb" and pl.anispeed~=0) then
	-- 	sound_add ('walk',5)
	-- else
	-- 	sound_stop ('walk')
	-- end

	if pl.oldstate == 'walk' and (currentFrame==2) then
		sound_add ("step1",30)
	end

	if pl.oldstate == 'walk' and (currentFrame==8) then
		sound_add ("step2",31)
	end



	if togo.y then 
		--print (togo.y)
	end

	--print (pl.y..' '..pl.x)

	if pl.state == "pullup" and currentFrame<3 then
		
		if pl.flip==1 and (is_pressed ('d')==false and is_pressed ('w')==false) then
			aniReverce = aniReverce or 0
			pl.hangcancel = true
		end

		if pl.flip==-1 and (is_pressed ('a')==false and is_pressed ('w')==false)  then
			aniReverce = aniReverce or 0
			pl.hangcancel = true
		end
	end



	if (pl.state == "stepup" or pl.state == "stepupb") and currentFrame<3 then

		if pl.flip==1 and is_pressed ('d')==false then
			if aniReverce==nil then
				--dump (togo.x)
			end
			aniReverce = aniReverce or 0
		end

		if pl.flip==-1 and is_pressed ('a')==false then
			aniReverce = aniReverce or 0
		end
		
	end

	if (pl.state == "stepup" or pl.state == "stepupb") and currentFrame>2 then
		sound_add ('stepup',5)
	else
		--sound_stop ('climb')
	end

	if pl.state == "climb" and pl.anispeed~=0 then
		sound_add ('climb',5)
	else
		sound_stop ('climb')
	end


	if pl.state == "pullup" then
		sound_add ('pullup',7,{x = pl.flip*0.5, y = 1})
	else
		sound_stop ('pullup')
	end

	if pl.state~='kick' then
		sound_stop ('whoosh')
		sound_stop ('whoosh2')
		sound_stop ('whoosh3')
	end

	--dump (allsounds)

	if pl.state == "walk" and pl.iscarry then
		pl.state = "walk_carry"
	end


	if pl.state == "jump" and pl.iscarry then
		pl.state = "walk_carry"
	end

	if pl.state == "idle" and pl.iscarry then
		pl.state = "idle_carry"
	end

	if pl.state == "jump" and pl.iscarry then
		pl.state = "jump_carry"
	end

	if pl.state == "fall" and pl.iscarry then
		pl.state = "fall_carry"
	end


	if pl.state == 'idle' then
		game.idle = (game.idle or 0) + dt
	else
		game.idle = 0
	end

	if fishing and pl.state=='idle' then
		pl.state = 'fishing'
	end

	if pl.state~='idle' and pl.state~='fishing' and fishing then
		fishing = nil
	end

	--nausea
	if pl.state=='pullup' and pl.buffs[17] and currentFrame==1 
		and math.random (0,100)<5 then
		pl.jumpleft = 0
		pl.state = 'fall'
	end

	if pl.state=='dig' then
		--pl.anispeed = pl.diganispeed
	end



	if pl.state=='idle' and mousetruemoved_last<1 then
		if pl.x>mouse_x	then
			pl.flip = -1
			else
			pl.flip = 1
		end
	end


	if pl.state=='idle' and mousetruemoved_last<1 
		and mouse_y<pl.y-50 then
			pl.state = 'headup'
	end

	if pl.state=='idle' and mousetruemoved_last<1 
		and mouse_y>pl.y+50 then
			pl.state = 'headdown'
	end


	-- if pl.state~='dig' then
	-- 	pl.digxt = nil
	-- end


	--love.timer.sleep(0.1)
	--print (pl.anispeed.." "..pl.state)

	coord_screen2true (pl)
	col_add ('player',pl,pl.state,'player','player')


	--turbo
	if pl.turbox and pl.turbox ~= pl.x 
		and pl.state ~= "fall"
		and pl.state ~= "jump"
		then
			local r = math.abs (pl.turbox - pl.x)*0.05
			stat_spend ('arms',r)
	end

	-- last non-falling
	if pl.stats.body.hp>0 and togo.down==0 then
		
		pl.ltx = pl.tx
		pl.lty = pl.ty


	end

	game.pass = nil

	--pl.anispeed = 0.3


end
	

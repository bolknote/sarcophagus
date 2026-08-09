function mobs_remove_prototypes(active_mobs)
	local removed = 0
	for id, mob in pairs(active_mobs or {}) do
		if mob.proto then
			active_mobs[id] = nil
			removed = removed + 1
		end
	end
	return removed
end

function virtual_cursor_delta(value, direction)
	local amount = math.abs(tonumber(value) or 1)
	if amount == 1 then amount = amount * 1.5 end
	return amount * 8 * direction
end

local AUTOSAVE_INTERVAL = 60 * 10
local AUTOSAVE_RETRY_INTERVAL = 30
local AUTOSAVE_MOUSE_IDLE = 3

function autosave_update(now, mouse_idle)
	now = tonumber(now) or tonumber(game.dt) or 0
	mouse_idle = tonumber(mouse_idle) or tonumber(mousemoved_last) or 0

	-- A fade temporarily makes taking the save preview unsafe. Keep the queued
	-- save, but do not enqueue it again (and flood the text log) every frame.
	if game.autosave then
		if game.fadein ~= nil or game.fadeout ~= nil then
			return "deferred"
		end

		-- The queued flag is runtime-only. Clear it before serialization so an
		-- autosaved game does not immediately save itself again when loaded.
		game.autosave = nil
		world = tablecheck(world)
		local saved = game_save(game.savepos)
		if saved then
			game.lastsave = now + AUTOSAVE_INTERVAL
			return "saved"
		end

		-- A transient filesystem failure should be retried soon without trying
		-- (and showing an error) on every rendered frame.
		game.lastsave = now + AUTOSAVE_RETRY_INTERVAL
		return "failed"
	end

	-- Fresh games used to fall back to 100 seconds here even though every
	-- subsequent interval is ten minutes. Establish the first deadline from
	-- the same clock and interval as all later autosaves.
	if game.lastsave == nil then
		game.lastsave = now + AUTOSAVE_INTERVAL
		return "scheduled"
	end

	if game.idle
		and mouse_idle > AUTOSAVE_MOUSE_IDLE
		and game.nosave == nil
		and game.lastsave < now
	then
		game.autosave = true
		textwall(msg.game[3], true)
		return "queued"
	end
end

function quit_countdown_update()
	if not exit then return false end

	exit = exit - 1
	if exit < 0 then
		exit = nil
		sound_killall()
		love.event.quit()
	end
	return true
end


function love.update(d)

	--love.audio.setVolume(0.1)

	--local direction = joystick:getAxis(1)
	--dump (direction)

	mousemoved_last = mousemoved_last or 0
	mousemoved_last = mousemoved_last + d

	mousetruemoved_last = mousetruemoved_last or 0
	mousetruemoved_last = mousetruemoved_last + d


	--mouse joystick move

	local k,a = is_pressed ('kp6')  --right
	if k then
		mousemoved_last = 0
		mousemoved = true
		a = virtual_cursor_delta(a, 1)

		local x = love.mouse.getX( )
		love.mouse.setX(x+a)
	end


	local k,a = is_pressed ('kp4') --left
	if k then
		mousemoved = true
		a = virtual_cursor_delta(a, -1)

		local x = love.mouse.getX( )
		love.mouse.setX(x+a)
	end


	local k,a = is_pressed ('kp8')  --up
	if k then
		mousemoved = true
		a = virtual_cursor_delta(a, -1)

		local x = love.mouse.getY( )
		love.mouse.setY(x+a)
	end


	local k,a = is_pressed ('kp2')  --down
	if k then
		mousemoved = true
		a = virtual_cursor_delta(a, 1)

		local x = love.mouse.getY( )
		love.mouse.setY(x+a)
	end

	








	mouse_x = love.mouse.getX()
	mouse_y = love.mouse.getY()
	
	if game.gr2x then
		mouse_x = mouse_x/2
		mouse_y = mouse_y/2
	end

	mouse_t = px2tile (mouse_x,mouse_y)

	--dump (mouse_t)


	dt = d
	if dt>1 then dt = 0 end
	
	next_time = next_time + min_dt

	-- A successful Save and Quit freezes the simulation immediately. Keep the
	-- short preview-capture countdown running even if focus changes meanwhile.
	if quit_countdown_update() then
		return
	end

	if not love.window.hasFocus() then
		return
	end

	if game.pause then
		sound_update ()
		return
	end


	if game.shaken then
		game.shaken = game.shaken - 5
		if game.shaken<0 then game.shaken = nil end
	end

	
	if game.fadeout then
		if game.fade==0 then game.fade = 1 end
		game.fade = game.fade - game.fadeout*dt
		local f = game.fade
		shader:send("f",f)
		if game.fade<0 then 
			game.fadeout = nil 
			game.fade = 0
		end
	elseif game.stayfade then
		game.stayfade = game.stayfade - dt
		if game.stayfade<0 then 
			game.stayfade = nil
		end
	elseif game.fadein then
		if game.fade==1 then game.fade = 0 end
		game.fade = game.fade + game.fadein*dt
		local f = game.fade
		shader:send("f",f)
		if game.fade>1 then 
			game.fadein = nil 
			game.fade = 1
		end
	end

	if game.screenshot then
		shader:send("f",1)
		game.screenshot = nil
		love.graphics.captureScreenshot(game.savepos..".png")
	end

	

	local ambient_id = sound_ambient_id ()
	if allsounds.cave==nil or allsounds.cave.id~=ambient_id then
		sound_add ('cave',ambient_id,{kill = 1})
	end

	sound_update ()
	
	--print ((game.time/time.h).." "..math.log (game.time/time.h))
	--dump (game.showroom)

	autosave_update(game.dt, mousemoved_last)

	-- player position changed
	game.moved = false

	if pl.xo ~= pl.x or pl.yo ~= pl.y then

		buff_tick ()

		game.moved = true

		pl.xo = pl.x
		pl.yo = pl.y
		r, pl.xt, pl.yt = px2tile (pl.x, pl.y)

		local tile,map = maptile (pl.xt, pl.yt,"all")

		--drink water
		if map.w and map.w>200 then
			pl.candrink = message (msg.gui[21],{[1] = math.ceil(map.dr or 0)})

			local dirt = pl.stats.filth.maxhp - pl.stats.filth.hp
			if dirt>5 then

				local dr = readmap (pl.xt, pl.yt,'dr') or 0

				if dr<100 then
		
					stat_recovery ('filth',10)
					dirt = dirt - 10
					dr = dr + 6*(1000/map.w)
					writemap (pl.xt, pl.yt, dr,'dr')

				end

				
			end
		else
			pl.candrink = nil
		end


		if tile.onstay then
			tile.onstay (pl.xt, pl.yt)
		end

		if tile.onuse then
			pl.canuse = true
		else
			pl.canuse = nil
		end

		local de = readmap (pl.xt, pl.yt,"de") or 0
		local de2 = readmap (pl.xt, pl.yt-1,"de") or 0

		if de>cf.deadfire or de2>cf.deadfire then
			player_hit (cf.firehit)
			textwall (msg.game[8], true) 
		end 


		--tile changed
		if pl.xto ~= pl.xt or pl.yto ~= pl.yt then

			achi_trigger ('tick')

			if maptile (pl.xt-1,pl.yt)==1 or maptile (pl.xt+1,pl.yt)==1 or pl.state~='walk' then
				haswater = nil
			else
				if love.math.random (0,100)<50 then
					haswater = true
				else
					haswater = nil
				end
			end


			love.audio.setPosition(pl.xt, pl.yt, 0)

			local waterfeet = readmap (pl.tx, pl.ty, 'w') or 0
			local waterhead = readmap (pl.tx, pl.ty-1, 'w') or 0

			if waterfeet>9000 and waterhead>0 then
				buff_add (18,'refresh')
			else
				buff_remove (18)
			end

			if waterfeet>9000 and waterhead>7000 then
				buff_add (19,'refresh')
			else
				buff_remove (19)
			end

			


			if readmap (pl.tx, pl.ty, 'fish') or readmap (pl.tx, pl.ty-1, 'fish') then
				writemap (pl.tx, pl.yt,nil,'fish')
				writemap (pl.tx, pl.yt-1,nil,'fish')
				textwall (msg.game[34])
				sound_add ('click',40)
			end


			local vs = pl.xt.."_"..pl.yt
			pl.visited[vs] = pl.visited[vs] or 0
			pl.visited[vs] = pl.visited[vs] + 1

			
			local ground = readmap (pl.xt,pl.yt,'i')
			if ground then for k,v in ipairs(ground) do
				item_unlock (v.i)
			end end

			if tile.onstep then
				tile.onstep (pl.xt, pl.yt,pl.xto,pl.yto)
			end

			local tile,map = maptile (pl.xt, pl.yt+1,"all")

			if tile.onstepon then
				tile.onstepon (pl.xt, pl.yt+1,pl.xto,pl.yto+1)
			end

			if tile.cold then
				stat_spend ('heat',tile.cold*0.5)
				if pl.stats.heat.hp<1 then
					buff_add (5,'keep')
				end

			end

			pl.xto = pl.xt
			pl.yto = pl.yt


		end

		if (pl.state~='walk' and pl.state~='idle') or game.showroom then 
			haswater = nil 
		end
		

	end

	local de = readmap (pl.xt,pl.yt,'de') or 0

	--dump (de)

	if de>0 and de<100 then
		re = de*dt*0.3
		stat_recovery ('heat',re)
		stat_recovery ('arms',dt)
		--print (dt)
	end

	if #mobs<3 then
		--local m = mobs[mob_create (pl.xt,pl.yt,11)]
	end

	
	game.dt = game.dt + dt
	local r


	lights = {}
	-- inventory lights

	if pl.buffs[1] then
		lights.p = lights.p or {}
		--local r = tile2px (x,y)
		lights.p.x = pl.x
		lights.p.y = pl.y
		lights.p.p = buff[1].light[1]
		lights.p.l = {buff[1].light[2],buff[1].light[3],buff[1].light[4]}			
	end


	if pl.iscarry and stone[pl.iscarry.b] and stone[pl.iscarry.b].light then
		lights.p = lights.p or {}
		--local r = tile2px (x,y)
		lights.p.x = pl.x
		lights.p.y = pl.y
		lights.p.p = stone[pl.iscarry.b].light[1]
		lights.p.l = {stone[pl.iscarry.b].light[2],stone[pl.iscarry.b].light[3],stone[pl.iscarry.b].light[4]}		
	end

	for i,v in pairs(pl.inv) do
		if item[v.i].light and (lights.p==nil or item[v.i].light[1]>(lights.p.p or 0)) then
			lights.p = lights.p or {}
			--local r = tile2px (x,y)
			lights.p.x = pl.x
			lights.p.y = pl.y
			if lights.p.p then
				lights.p.p = lights.p.p + math.floor(item[v.i].light[1]/2)
			else
				lights.p.p = item[v.i].light[1]
			end	
			lights.p.l = {item[v.i].light[2],item[v.i].light[3],item[v.i].light[4]}		
		end
	end




	-- dead
	--dying
	if pl.dying==1 then 
		local points = {}
		table.insert (points, {x=pl.x+col.x,  y=pl.y+col.y+col.h,mode={up = true, down = true,left = true, right = true}}) -- левый нижний
		togo = tocollide (points)
		if togo.down>0 then
			pl.y = pl.y + math.min(16,togo.down)
		else
			pl.state = 'dying'
			pl.dying=2
		end
		return 
	end

	if pl.dying==2 and pl.oldstate=='dying' and currentFrame == 5 then
		sound_add ('cello', 29)
		pl.dying=3
	end


	if pl.dying==3 and pl.oldstate=='dying' and currentFrame == 8 then
		game.fadeout = 0.1
		game.fadein = 0.2
		game.stayfade = 7
		pl.dying=4
	end

	-- power rec
	if pl.dying==4 then

		if pl.stats.power.hp<99 then
			game.time = game.time + time.h
			stat_recovery ("power",time.h * cf.rec.powerdead)
		else
			pl.dying = 5
		end

		ttl_checks (game.ttl_list)
		game.stayfade = 5
		pl.lastshit = game.time

	end


	if pl.dying==5 then	
		
		if pl.spenddead > 0 then
			pl.spenddead = pl.spenddead - time.h
			game.time = game.time + time.h
			stat_recovery ("power",time.h * cf.rec.powerdead)
		else
			pl.spenddead = 0
			pl.dying = 6
		end

		pl.lastshit = game.time
		pl.lastdeath = game.time

	end


	if pl.dying==6 and game.fadein == nil then
		inv_ground_add (pl.xt,pl.yt,item_make(45)) --corpse
		pl.dying=nil
		player_reset ()
		stats_reset ()
		stat_spend ("power",95)
		pl.isdead = nil
		--quest_reset (1)
		--quest_cd (30)
		pl.inv = {}
		inv_add (item_make(26))
	end

	--dump (game.fadein)


	--crafting
	if pl.unrest>0 then
		local recovery = 100
		pl.unrest = pl.unrest - recovery
		game.time = game.time + recovery
		game.recovery = game.time
		stat_spend ("water",recovery * 0.001)
		stat_spend ("food",recovery * cf.rec.food)
		stat_spend ("arms",recovery * 0.003)
		stat_spend ("filth",recovery * 0.0005)
		stat_recovery ("heat",recovery * 0.000277)
		stat_recovery ("power",recovery * cf.rec.power)
		game.moved = 1
		
	end


	-- resting
	if pl.rest>0 then
		
		if pl.stats.food.hp<10 then
			pl.rest = 0
			textwall (msg.game[5])
		end
		
		if pl.stats.body.pc==100 and pl.stats.arms.pc==100 and pl.resttillhealed then
			pl.rest = 0
			pl.resttillhealed = nil
		end

		if pl.rest>0 then
			local recovery = 64

			if pl.restquality==0 then
				recovery = 640
				achi_add (33,640/time.h)
			end

			pl.rest = pl.rest - recovery

			game.time = game.time + recovery
			game.recovery = game.time
			--stat_spend ("heat",recovery * 0.0005)

			stat_recovery ("arms",recovery * 0.03 * (pl.restquality+(pl.restqualityb or 0)))
			stat_recovery ("body",recovery * 0.002 * (pl.restquality+(pl.restqualityb or 0)))
			stat_recovery ("power",recovery * cf.rec.power)

			if pl.restquality==0 then
				recovery = 64
			end

			if pl.restquality~=0 or pl.stats.food.hp>15 then
				stat_spend ("food",recovery * cf.rec.food)
			end

			if pl.restquality~=0 or pl.stats.water.hp>15 then
				stat_spend ("water",recovery * 0.002)
			end
			
			pl.state = 'zzz'
			pl.flip = 1

		end


		if pl.rest <= 0 then
			textwall (msg.game[4],true,{[1] = (pl.restquality+(pl.restqualityb or 0))})
			pl.rest = 0
		end

		buff_tick ()
		ttl_checks (game.ttl_list)

	end





	if pl.rest<=0 and pl.unrest<=0 and pl.spenddead<=0 then

		-- hunger and recovery
		if game.time > game.recovery + 32 then

			pl.restquality = 1
			local recovery = game.time - game.recovery
			game.recovery = game.time

			stat_spend ("food",recovery * cf.rec.food)
			stat_spend ("water",recovery * 0.004)
			
			if pl.iscarry then
				--stat_spend ("arms",recovery * 0.01)
			else
				stat_recovery ("arms",recovery * 0.03)
			end

			stat_recovery ("power",recovery * cf.rec.power)
			stat_spend ("filth",recovery * 0.001)
		
			if pl.stats.food.hp<1 or pl.stats.water.hp<1 then
				stat_spend ("body",recovery * 0.01)
			end
		end

		--disasters
		if pl.disastercd < game.time then	
			pl.disastercd = game.time + cf.disastercd
			disaster_do ()
		end

	end



	-- dying
	if pl.stats.body.hp<=0 and pl.dying==nil then

		local how = function (x,y)
			if readmap (x,y,'b')==123 then
				return true
			end
		end

		local x,y = find_block (pl.tx,pl.ty,how,123)

		if x then
			writemap (x,y,0)
			pl.truex = x*32-16
			pl.truey = y*32-32
			vi.xtile = x
			vi.ytile = y
			coord_true2screen (pl)
			camera_move ()
			camera_fix ()
			pl.stats.body.hp = 6
			buff_remove_all ()
		else
			player_die ()
		end

	end

	-- moving
	if pl.dying == nil then

		if game.craft == false and game.achishow==nil then
			if is_pressed("\\") and IS_DEVELOPMENT then
				moving_editor()
			else
				if pl.rest<=0 then
					moving()
				else
					game.moved = true
				end
			end
		end

	end



	--holding cob
	pl.cob = nil
	pl.iscob = pl.iscarry and stone[pl.iscarry.b] and stone[pl.iscarry.b].coby

	if pl.state == "idle_carry" and pl.iscob then

		local r = px2tile (mouse_x,mouse_y)
		if readmap (r.x, r.y, 'b') == 0 then
			
			local x = pl.xt - r.x
			local y = pl.yt - r.y

			if x<=1 and x>=-1 and
			y<=2 and y>=-1 and
			not ((x==0 and y==0) or (x==0 and y==1)) then

				if pl.flip==-1 and x<0 then pl.flip=1 end
				if pl.flip==1 and x>0 then pl.flip=-1 end

				if stone[pl.iscarry.b].coby==1 then

					if maptile (r.x+1,r.y,'col')~=0 or
					maptile (r.x-1,r.y,'col')~=0 or
					maptile (r.x,r.y-1,'col')~=0 or
					maptile (r.x,r.y+1,'col')~=0 then

						pl.cob = {r.x, r.y}

					end
				end


				if stone[pl.iscarry.b].coby==2 then
					
					if maptile (r.x,r.y-1,'col')~=0 then

						pl.cob = {r.x, r.y}

					end
				end



			end

		end

	end



	--shitting
	if pl.state == "idle" then

		if pl.unrest<=0 and pl.rest<=0 and pl.lastshit + time.d < game.time and inv_ground_count(pl.xt,pl.yt)==0 then

			sound_add ('shit', 45)

			pl.lastshit = game.time
			inv_ground_add (pl.xt,pl.yt,item_make(20))
			textwall (msg.game[25])

			for i,v in pairs(pl.shit) do
				inv_ground_add (pl.xt,pl.yt,item_make(i))
			end

			pl.shit = {}

		end

	end

	-- debug
	if is_pressed("backspace") and game.dbg[1] then

		ttl_checks (game.ttl_list)

		stat_recovery ("water",1000 * 0.005)
		stat_recovery ("food",1000 * 0.003)

		--stat_recovery ("power",recovery * 0.001)
		--1/(60*60*24) = 0.0000115741
		--1/(60*60) =--0.000277
		--stat_recovery ("power",1000 * cf.rec.power)
		

		game.time = game.time + 1000

	end


	camera_move()


	-- mobs 
	local mobst = 0
	mobs_remove_prototypes(mobs)

	for i,v in pairs(mobs) do	

		if v.light then

			lights['mob_'..i] = lights['mob_'..i] or {}
			lights['mob_'..i].x = v.x --+ ani[v.type][v.ani_status].xoff
			lights['mob_'..i].y = v.y 
			lights['mob_'..i].p = v.light[1]
			lights['mob_'..i].l = {v.light[2],v.light[3],v.light[4]}

		end

		local sound = v.sound 

		if sound == nil and creature[v.id] and creature[v.id].proto then
			sound = creature[v.id].proto.sound
		end
		
		if sound and (v.sleep==nil or v.sleep==0) then

			local hd = math.abs (pl.tx-v.tx)
			local wd = math.abs (pl.ty-v.ty)

			if hd<screen.x/3 and wd<screen.y/3 and mobst<5 then

				mobst = mobst + 1
			
				sound_add ('mob_'..i, sound, {x = v.tx, y = v.ty, play = 1})

				if v.hp<=0 then
					sound_volume ('mob_'..i, -0.3)
				end

			end

		end

		mobs[i].n = i

		local cola = mobs[i].coltype or 'mob'
		col_add (cola..'_'..i,v,v.ani_status,(v.colname or v.type),cola,i)
		creature[v.id].ai (v,i)

	end


	fishing_update ()


	-- animation
	-- new state

	--print (pl.state..currentFrame)
	--love.timer.sleep(0.1)

	frameTime = frameTime + dt * 100 * (pl.anispeed or 1)
	cycleTime = cycleTime + frameTime

	-- out of bounds
	if gr[pl.state]['dur'][currentFrame] == nil then
		currentFrame = 1
		cycleTime = 0
		frameTime = 0
	end

	if pl.oldstate ~= pl.state then
		currentFrame = 1
		cycleTime = 0
		frameTime = 0
	end

	-- new frame
	if frameTime >= gr[pl.state]['dur'][currentFrame] then
		if gr[pl.state]['dur'][currentFrame] > 0 then

			frameTime = frameTime - gr[pl.state]['dur'][currentFrame]


			local rt

			if aniReverce and gr[pl.state].reversable then

				aniReverceStart = aniReverceStart or currentFrame
				aniReverce = aniReverce + 1
				currentFrame = aniReverceStart - aniReverce
				
				--print ('frame..'..currentFrame)

				if currentFrame>0 then

					if gr[pl.state]['add'] and gr[pl.state]['add'][currentFrame] then
						pl.x = pl.x - gr[pl.state]['add'][currentFrame][1]*pl.flip
						pl.y = pl.y - gr[pl.state]['add'][currentFrame][2]
					end
				else
					rt = true
				end

			else

				currentFrame = gr[pl.state]['ani'][currentFrame]

				if gr[pl.state]['add'] and gr[pl.state]['add'][currentFrame] then
					pl.x = pl.x + gr[pl.state]['add'][currentFrame][1]*pl.flip
					pl.y = pl.y + gr[pl.state]['add'][currentFrame][2]
				end

			end

				if type(currentFrame) == "string" or rt then
				
				local exitfr = 1
				if gr[pl.state]['exitfr'] then
					exitfr = gr[pl.state]['exitfr']
				end

				pl.state = currentFrame
				currentFrame = exitfr

				if rt then
					pl.state = 'idle'
					currentFrame = 1
				end

				frameTime = 0
				cycleTime = 0
				aniReverce = nil
				aniReverceStart = nil
			end

		else
			currentFrame = 1
			frameTime = 0
			cycleTime = 0
		end
	end

	-- out of bounds
	if currentFrame > gr[pl.state]['cnt'] then
		currentFrame = 1
		frameTime = 0
		cycleTime = 0
	end

	pl.oldstate = pl.state


--x,y,ttl,text,vs,xs
for k,v in pairs(sct) do

	if coord_true2screen (v) == false then coord_screen2true (v) end

	local s = (#sct-k)*0.4
	if s<0 then s=0 end

	v.y = v.y - dt*(v.ys or 40) - s
	v.x = v.x + dt*(v.xs or 0) + 2 * math.sin (v.y/6)
	v.ttl = v.ttl - dt

	coord_screen2true (v)
	if v.ttl<0 then sct[k] = nil end

end


proj_update ()


-- inventory ttl
if game.moved then
	inv_tick_ttl()
end

	
-- screen checks
game.checked = false
game.fchecked = false

for ix=-1,screen.x+1 do
for iy=-1,screen.y+1 do
	x = vi.xtile+ix+1
	y = vi.ytile+iy+1
	--writemap (x,y,4)
	checks (x,y,{real = true})


end
end

if game.checked then game.ttlcheck = game.dt + game.deltacheck end
if game.fchecked then game.firecheck = game.dt + 0.5 end

dispenser ()


if pl.state == "idle" or pl.state=='buttscratch' or pl.state == 'idle_carry' then

	ttl_checks (game.ph_list,{cnt = 1})

	pl.idlecnt = pl.idlecnt + dt
	if pl.idlecnt > 4 then
		ttl_checks (game.ttl_list)
	end
else
	pl.idlecnt = 0
end

--dump (tablecount (lights))
--dump (lights['373_439'])

-- world animation
for k,v in pairs(worldani) do

	if ani[v.ani_name].walk.light then

		local l = ani[v.ani_name].walk.light 

		lights['ani_'..k] = lights['ani_'..k] or {}
		lights['ani_'..k].x = v.x
		lights['ani_'..k].y = v.y
		lights['ani_'..k].p = l[1]
		lights['ani_'..k].l = {l[2],l[3],l[4]}	

	end

	if ani[v.ani_name].walk.cnt == v.ani_frame then

		if k=='boom' or k=='shrapnel' then

			
			if k=='shrapnel' then
				--
			else
				grenade (v.tx+1, v.ty+1)
			end

			local anvil = tile2px (v.tx+1, v.ty+1)
			coord_screen2true (anvil)
			col_add ('boom',anvil,'','boom','props')
			
			local m = collide_check ('boom','mob',{arr=1})

			if m and #m>0 then
				local dmg = 50/#m

				for i,v in ipairs(m) do
					mob_hit (v.n, dmg)	
				end
				
			end

			local m = collide_check ('boom','player')

			if m then
				player_hit (50)
			end

		end


		
		worldani[k]=nil
	end

	--grenade (r.x,r.y)

end




if is_pressed('ralt') then

	if ctrshow then
		ctrshow = nil
		altold = is_pressed('ralt')
	end
		if altold==nil then
			altshow = not altshow
			altold = is_pressed('ralt')
		end
	
else
	if altold == true then
		altold = nil
	end
end


--altshow = 
-- or (togo.down<=0 and is_pressed ('s') and not is_pressed('space'))

local cn = (is_pressed('lctrl') or is_pressed('rctrl'))

if cn then
	
		if ctrold==nil then

			if altshow then
				--altshow = nil
			end	

			ctrshow = not ctrshow
			ctrold = cn
		end
	
else
	if ctrold == true then
		ctrold = nil
	end
end


--ctrshow and 

if pl.inv[pl.invselect] then
	game.altitem = pl.inv[pl.invselect].i
else
	game.altitem = nil
end


if altshow then
	game.altitem = nil
end


if love.mouse.isDown(3) then
	game.altitem = nil
end

--dump (togo)

--print (pl.state)

end

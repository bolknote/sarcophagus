-- SCREEN
--------------------------------------------------

-- love.graphics.olddraw = love.graphics.draw

-- function love.graphics.draw (...)

-- 	local ar = ...
-- 	table.insert(ar, 1, texture)
-- 	love.graphics.olddraw (ar)

-- end

function gameplay_save_on_quit_allowed()
	return not GAME_CRASHED
		and os.getenv("SARCOPHAGUS_SMOKE_TEST") == nil
		and type(world) == "table"
		and next(world) ~= nil
		and type(game) == "table"
		and type(pl) == "table"
		and game.savepos ~= nil
		and game.mapgenning == nil
		and love.update ~= love.menu_update
		and not pl.isdead
end

function love.quit ()
	if quit_after_save then
		(oldprint or print) ('exit')
		return
	end

	-- Route a normal window close or Cmd+Q through the same checked save path
	-- as the in-game menu. Returning true cancels this immediate quit; a short
	-- countdown lets the queued save preview reach the next rendered frame.
	if gameplay_save_on_quit_allowed() and save_and_quit then
		save_and_quit()
		return true
	end

	(oldprint or print) ('exit')
end

function testproj_kill ()
	testthrow = 0
	for k,v in pairs(proj) do
		if v.proj == 15 then
			proj[k] = nil
		end
	end
end

function grenade (x,y)

	inv_ground_add (x,y,item_make (50)) 

	for i=x-1,x+1 do
	for ii=y-1,y+1 do

		local g = maptile (i,ii,'gather')
		local b = readmap (i,ii,'b')
		if g and g~=0 and b~=0 then


			if (stone[b] and stone[b].digtoinv or 0)>0 then
				inv_ground_add (i,ii,item_make (stone[b].digtoinv)) 
				achi_add (24,1)
			end

			if stone[b] and stone[b].loot then
				inv_ground_add (i,ii,item_make (loot_make(stone[b].loot)))
				achi_add (24,1)
			end

			writemap (i,ii,0)
		end
		
	end	
	end
end

function new_worldani (name, id, add)

	worldani[name] = worldani[name] or {}

	ani_new (worldani[name], id)

	add = add or {}

	for k,v in pairs(add) do
		worldani[name][k] = v
	end

	return worldani[name]
end



function tablecheck(orig)

    local orig_type = type(orig)
    local copy

   -- print (orig_type)

    
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do

        	--print (type(orig_value))

        if type(orig_value) == 'cdata' then
        	print (orig_key)
        	dump (orig)
	    	orig_value = 1000
	   	 end


            copy[tablecheck(orig_key)] = tablecheck(orig_value)
        end
        setmetatable(copy, tablecheck(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
	end
    return copy
end


function love.resize(w, h)
  screen_res ()
end

function img_load (name)
	
	--return love.graphics.newImage ("assets/sprites/"..name)

	if quadlist[name] then
	 	local q = quadlist[name]
	 	return love.graphics.newQuad(q.x, q.y, q.w, q.h, quad:getDimensions())
	end

end


function screen_full ()

	if game.invertstereo then
		love.audio.setOrientation(0, 0, 1, 0,1,0)
	else
		love.audio.setOrientation(0, 0, 1, 0,-1,0)
	end

	love.window.setFullscreen(game.fullscreen or false)
	screen_res ()

	vi.mobspawndist = screen.x + 1

	game.mastervolume = game.mastervolume or 100
	love.audio.setVolume(game.mastervolume*0.01)

end

function screen_res ()
	

	local h = 14
	local w = 8

	screen = {}
	screen.width, screen.height, screen.flags = love.window.getMode ()

	screen.txt = screen.height - h*14 --y coord of text

	screen.inv = screen.width - w*36

	screen.txtwidth = math.floor ((screen.width - w*36 - w*13)/w)
	if screen.txtwidth<15 then screen.txtwidth=15 end

	screen.txtcraft = math.floor (screen.width/w) - screen.txtwidth - 9

	vi.textwall_w = screen.txtwidth * w - 50
	text_canvas = love.graphics.newCanvas(vi.textwall_w,vi.textwall_h)
	draw_textwall ()


	--local ew = width - w*36
	local ew = screen.width - w*18
	local eh = screen.height - h*15 

	vi.vixmax = ew/2 + ew/10 - w*18
	vi.vixmin = ew/2 - ew/10 + w*18

	vi.viymax = eh/2 + eh/10
	vi.viymin = eh/2 - eh/10

	vi.viymax = eh/2
	vi.viymin = eh/2

	screen.x =  math.floor (screen.width / 32) + 3
	screen.y =  math.floor (screen.height / 32) + 3

	if game.gr2x then
		vi.vixmax = vi.vixmax / 2
		vi.vixmin = vi.vixmin / 2
		vi.viymax = vi.viymax / 2
		vi.viymin = vi.viymin / 2

		screen.x = math.ceil (screen.x/2)
		screen.y = math.ceil (screen.y/2)

	end



end



function camera_fix ()

	local fix

	while fix==nil do

		fix = true
		if vi.xoffset>=32 then
			vi.xoffset = vi.xoffset - 32
			vi.xtile = vi.xtile + 1
			fix = nil
		end

		if vi.xoffset<=-32 then
			vi.xoffset = vi.xoffset + 32
			vi.xtile = vi.xtile - 1
			fix = nil
		end

		if vi.yoffset>=32 then
			vi.yoffset = vi.yoffset - 32
			vi.ytile = vi.ytile + 1
			fix = nil
		end

		if vi.yoffset<=-32 then
			vi.yoffset = vi.yoffset + 32
			vi.ytile = vi.ytile - 1
			fix = nil
		end

		vi.x = vi.xtile * cf.w + vi.xoffset
		vi.y = vi.ytile * cf.h + vi.yoffset
	end

end

function camera_move ()
	
	local d = 0
	local up

	-- camera
	-- scroll right
	--repeat

	if pl.x > vi.vixmax then

		up = true

		d = math.ceil ((pl.x - vi.vixmax)/40)
		pl.x = pl.x - d
		vi.xoffset = vi.xoffset + d

		if vi.xoffset>=32 then
			vi.xoffset = vi.xoffset - 32
			vi.xtile = vi.xtile + 1
		end
	end

	-- scroll left
	if pl.x < vi.vixmin and vi.xtile>0 then

		up = true
		d = math.ceil ((pl.x - vi.vixmin)/40)
		pl.x = pl.x - d
		vi.xoffset = vi.xoffset + d

		if vi.xoffset<=-32 then
			vi.xoffset = vi.xoffset + 32
			vi.xtile = vi.xtile - 1
		end
	end

	-- scroll down
	if pl.y > vi.viymax then

		up = true
		d = math.ceil ((pl.y - vi.viymax)/40)
		pl.y = pl.y - d
		vi.yoffset = vi.yoffset + d

		if vi.yoffset>=32 then
			vi.yoffset = vi.yoffset - 32
			vi.ytile = vi.ytile + 1
		end
	end

	-- scroll up
	if pl.y < vi.viymin and vi.ytile>0 then

		up = true
		d = math.ceil ((pl.y - vi.viymin)/40)
		pl.y = pl.y - d
		vi.yoffset = vi.yoffset + d

		if vi.yoffset<=-32 then
			vi.yoffset = vi.yoffset + 32
			vi.ytile = vi.ytile - 1
		end
	end

	-- screen coords
	vi.x = vi.xtile * cf.w + vi.xoffset
	vi.y = vi.ytile * cf.h + vi.yoffset


	vi.cammoving = d+1
	

end


function coord_screen2true (ct)

	local r = px2tile (ct.x,ct.y)

	ct.truex = vi.xtile * cf.w + vi.xoffset + ct.x
	ct.truey = vi.ytile * cf.h + vi.yoffset + ct.y

	ct.lx = 24 - math.floor ((r.x * cf.w) - ct.truex)
	ct.ly = 26 - math.floor ((r.y * cf.h) - ct.truey)

	--print (ct.lx.." "..ct.ly)

	ct.tx = r.x
	ct.ty = r.y


end

function coord_true2screen (ct)

	if ct.truex==nil then return false end

	ct.tx = math.floor (ct.truex/cf.w)
	ct.ty = math.floor (ct.truey/cf.h)

	ct.txl = ct.truex - ct.tx*cf.w
	ct.tyl = ct.truey - ct.ty*cf.h
	
	ct.x = (ct.tx - vi.xtile)*cf.w - vi.xoffset + (ct.truex - ct.tx*cf.w)
	ct.y = (ct.ty - vi.ytile)*cf.h - vi.yoffset + (ct.truey - ct.ty*cf.h)
	ct.tx = ct.tx + 1
	ct.ty = ct.ty + 1

	return true
end

function is_onscreen(t)
	-- body
end


function tile2px (x,y)

	local w = 32
	local h = 32

	x = (x-1)*w - vi.xtile * w - vi.xoffset
	y = (y-1)*h - vi.ytile * h - vi.yoffset

	return {x = x, y = y, x2 = x+w, y2 = y+h}
	
end


function px2tile (x,y)

	local w = 32
	local h = 32

	x = x + vi.xoffset
	x = math.floor (x/w)+1 + vi.xtile
	y = y + vi.yoffset
	y = math.floor (y/h)+1 + vi.ytile

	return {x = x, y = y}, x, y
	
end


function water_add (x,y,water,str,force)
	
	str = str or 'w'
	local w = (readmap (x,y,str) or 0)

		if w < 10000 or force then

			w = w + water
			water = 0

			--and w<10001
			if w>9900 then -- overflow
				water = w - 10000
				w = 10000
			end

			writemap (x,y,w,str)

		end

	if water<100 then water = 0 end

	return water

end


-- map.w = water_eq (x-1,y, map.w,1)

function dirt_eq (x,y,water,o,str)

	if water~=nil then
	
		water = water or 0
		str = str or 'dr'

		local w = (readmap (x,y,str) or water)
		local w2 = math.ceil ((water + w)/2)

		if w2>200 then w2=200 end

		--print (w2.." "..o)
		writemap (x,y,w2,str)
		return w2

	end

end

function water_eq (x,y,water,o,str)
	
	water = water or 0
	str = str or 'w'
	local w = (readmap (x,y,str) or 0)

	if w>100 and math.floor (w/10) == math.floor (water/10) then return math.ceil (water) end

	local w2 = math.ceil ((water + w)/2)
	writemap (x,y,w2,str)

	if w2<100 then w2 = 0 end


	--print (math.abs (water-w2))

	return w2

end



-- MAP
--------------------------------------------------

function maptile(x,y,mode)

	mode = mode or 'col'
	
	if world[y] and world[y][x] then
		
		local tile = world[y][x].b

		if tile == 0 or tile == nil then

			if mode=="all" then return {},world[y][x] else return 0 end

		end

		if mode=="all" then 
			return (stone[tile] or {}),world[y][x] 
			else
				
				if mode=='col' and game.pass and stone[tile][game.pass] then 
					return 0
				end

				return stone[tile][mode] or 0

			end -- normal return

	else
		if mode=='all' then
			return {},{}
		else
			return 0,{}
		end
	end



end


function neibors (x,y)
	
	local r = 1
	local s = ''
	local c = 0
	local sf = {}
	local add = ""
	local a = {}

	for ix=r*(-1),r do
		for iy=r*(-1),r do

			if ix == 0 and iy == 0 then
			else
				local tile, map = maptile (x+iy,y+ix,"all")
				
				if map then
					if map.b == 0 or tile.col==0 then
						if map and map.n == 255 then
							add = '1'
						else
							add = '0'
						end
					else
						add = '1'
					end

					s = s..add

					table.insert (a, add)

				end

			end
		end
	end

	-- 123
	-- 405
	-- 678

	--dump (a[1])

	local cr = maptile (x,y,"cr")

	if cr==1 then

		if a[4]=="0" and a[2]=="0" then
			table.insert (sf,1)
		else
			table.insert (sf,0)
		end

		if a[2]=="0" and a[5]=="0" then
			table.insert (sf,1)
		else
			table.insert (sf,0)
		end

		if a[5]=="0" and a[7]=="0" then
			table.insert (sf,1)
		else
			table.insert (sf,0)
		end

		if a[7]=="0" and a[4]=="0" then
			table.insert (sf,1)
		else
			table.insert (sf,0)
		end

	end



	--return s
	s = tonumber(s, 2) 
	if s==0 then s=nil end
	return s,sf

end

function readmap (x,y,mode)

	if world == nil then
		return 0
	end

	if y<0 or x<0 then return false end
	if world[y] == nil or world[y][x] == nil then return false end

	if mode then return world[y][x][mode]
		else
			return tablecopy (world[y][x])
		end

end


function room_storetime (q, pc)

	if q==nil then return 1 end

	q = q * 0.1

	if pc then
		q = q * 100
		return string.format("%.0f", q)
	end

	q = 1/(1+q)
	--print (q)

	return q

end

function room_clear (x,y)
	
	local function clear (dir)
		if dir~=nil then
			for k,v in pairs(dir) do
				--dump (v)
				writemap (v[1],v[2],nil,'room')
			end
		end
	end

	clear (readmap (x,y,'rooml'))
	clear (readmap (x,y,'roomr'))

	writemap (x,y,nil,'rooml')
	writemap (x,y,nil,'roomr')

end



function room_fill (x,y,dir)

	local tofill = {}
	tofill[x.."_"..y] = {x,y}
	local dirs = {
		{0,-1}, --up
		{1,0},
		{0,1},
		{-1,0}
	}

	::recheck::

	local unchecked = nil
	local cnt = 0
	local borders = 0
	local border = 0
	local walls = {}

	for k,v in pairs(tofill) do
		for i,vv in ipairs(dirs) do
			
			if maptile (v[1]+vv[1],v[2]+vv[2],'col')==0 then
				if tofill[v[1]+vv[1].."-"..v[2]+vv[2]]==nil then
					tofill[v[1]+vv[1].."-"..v[2]+vv[2]] = {v[1]+vv[1],v[2]+vv[2]}
					unchecked = 1
				end
			else
				if walls[v[1]+vv[1].."-"..v[2]+vv[2]]==nil then
					local br = readmap (v[1]+vv[1],v[2]+vv[2],'b')
					if br ~= 183 then
						borders = borders + (cf.bricks[br] or 1)
						border = border + 1
						walls[v[1]+vv[1].."-"..v[2]+vv[2]]=1
					end
				end
			end

		end
		cnt = cnt + 1
	end

	if cnt>100 then return end

	if unchecked then
		goto recheck
	end

	cnt = cnt + 1
	--print (cnt)
	

	return tofill, borders/border, cnt


end


function createblock (b)
	local z = {}
	z.b = b
		if stone[b] and stone[b].ttl then
			z.t = game.time
		end
	return z
end

function writemap (x,y,z,mode)

	mode = mode or 'b' -- i,t

	if y<0 or x<0 then return false end
	if world[y] == nil then world[y] = {} end
	if world[y][x] == nil then world[y][x] = {} end
	
	if mode=="clear" then
		cleartable (world[y][x])
		writemap (x,y,z)
		return true
	end

	if mode == "all" then

		world[y][x] = tabledeepcopy (z)
		game.ttl_list[x.."-"..y] = {x,y}
		return true
		
	else

		world[y][x][mode] = z

		if mode == "f" then
			game.ttl_list[x.."-"..y] = {x,y}
		end

		if mode == "b" then

			if stone[z] and stone[z].ttl then
				writemap (x,y,game.time,'t')
				game.ttl_list[x.."-"..y] = {x,y}
			else
				writemap (x,y,nil,'t')
			end

		end

		return z

	end

end





-- BLOCKS
--------------------------------------------------


function cob_pick ()


	

end



function growup (x,y,z,w)

	local tile, map = maptile (x,y-1,"all")

	if w and readmap (x,y,'b')~=w then
		return false
	end

	if map.b == nil or map.b == 0 or map.b == 96 or map.b == 17 or map.b == 36 or map.b == 37 or map.b == 85 then
		writemap (x,y-1,z)
		return true
	end

	return false
end


function grow (x,y,w,z)

	local tile, map = maptile (x,y,"all")

	if map.b == w then
		writemap (x,y,z)
		return true
	end

	return false

end

function water_ground (x,y,z)
	local e = readmap (x,y,"wt")
	local wt = maptile (x,y,'absorb') or 0
	if wt>0 then
		e = e or 0
		writemap (x,y,e+z,'wt')
	end
end


function lookaround (x,y,z,r)
	for i,v in ipairs(z) do
		for ix=r*(-1),r do
			for iy=r*(-1),r do
				if ix == 0 and iy == 0 then
				else
				if readmap (x+ix,y+iy,'b')==v then return x+ix,y+iy end
				end
			end
		end
	end
	return nil
end

function luxaround (x,y,z,r)
	local c = 0
	for i,v in ipairs(z) do
		for ix=r*(-1),r do
			for iy=r*(-1),r do
				--if ix == 0 and iy == 0 then
				--else
				if readmap (x+ix,y+iy,'b')==v then 
					c = c + r/math.dist (0, 0, ix, iy)  
				--end
				end
			end
		end
	end
	if c>5 then c=5 end
	return c
end

function has_light_c (x,y,b,d)

	local x1,y1 = lookaround (x,y,{b},d)
	if x1 then
		--local dist = math.dist (x, y, x1,y1)
		--if dist <= d then return true end
		return true
	end

end

function has_light (x,y)

	local lux = luxaround (x,y,{5},2) +
	luxaround (x,y,{6},3) +
	luxaround (x,y,{7},4) +
	luxaround (x,y,{104},3) +
	luxaround (x,y,{132},7) +
	luxaround (x,y,{193},3)

	if lux == 0 then return nil else return lux end

end

function fertilize (x,y,z)

	local b = readmap (x,y,"b")
	local e = readmap (x,y,"e")
	e = e or 0
	writemap (x,y,e+z,'e')

	if z<0 and e<=0 then
		return
	end

	return true

end


-- PLANTS
--------------------------------------------------

function plant_dig (x,y,s)
	local s = stone[s].plant

	local stage = readmap (x,y,'stage') or 1

	for i,v in ipairs(s.loot[stage]) do
		inv_add (item_make(v))
	end

	-- if stage == s.dead then
	-- 	textwall (msg.game[31]) --died
	-- end

end

function plant_grow (x,y,s)

	local vr = readmap (x,y,'vr')

	if vr==nil then
		if love.math.random (0,100)<40 then
			writemap (x,y,1,'vr')
		else
			writemap (x,y,-1,'vr')
		end
	end


	local plant = stone[s].plant

	local wt = readmap (x,y+1,'wt') or 0
	local e = readmap (x,y+1,'e') or 0
	local mu = readmap (x,y+1,'mu') or 0
	local bb = readmap (x,y+1,'b') or 0
	

	local stage
	local age = readmap (x,y,'age') or 1
	local room = readmap (x,y,'room')
	local w = readmap (x,y,'w') or 0
	local neg = readmap (x,y,'neg') or 0
	local haslight = has_light (x,y) or 0


	local problem
	if plant.flood and w>plant.flood then problem = 1 end
	if wt<=0 and plant.wt>0 then problem = 2 end
	if e<plant.e then problem = 3 end
	if plant.light and haslight<=0 then problem = 4 end
	if bb==48 then problem = 6 end
	if age>=plant.dead then problem = 5 end
	if plant.growable and not in_array (plant.growable, bb) then
		problem = 7
	end
	if plant.indoors and room==nil then problem = 10 end

	if problem then
		if neg==0 then
			neg = game.time
		end
	else
		neg = 0
	end

	--freezing to death
	if plant.freeze and game.time-neg>plant.freeze and problem==6 then
		age = plant.dead
	end

	if neg>0 and game.time-neg>plant.neg then
		age = plant.dead
	end

	if problem==nil then

		local spend

		if age<plant.stages-1 then

			--growing

			age = age + plant.step 
			--age = age + (plant.step * (haslight-1) * 0.1)

			local mumu = 1
			
			if mu>0 then
				mu = mu - plant.step
				mumu = 0.7
			end

			if mu<0 then mu = 0 end

			wt = wt - plant.wt * mumu
			e = e - plant.e * mumu * 2
			neg = 0

		else

			age = age + plant.laststep

		end

	end


	if mu<=0 then mu = nil end
	if e<=0 then e = nil end
	if wt<=0 then wt = nil end

	stage = math.floor(age)
	if stage>plant.dead then
		stage = plant.dead
	end
	

	writemap (x,y,has_light (x,y),'lux')

	writemap (x,y,age,'age')
	writemap (x,y,stage,'stage')
	writemap (x,y+1,wt,'wt')
	writemap (x,y+1,e,'e')
	writemap (x,y+1,mu,'mu')
	writemap (x,y,neg,'neg')
	writemap (x,y,problem,'problem')
	
end

-- z = blocks, r = radius, w = what
function plant_spores (x,y,z,r,w)

	for i,v in ipairs(z) do
		for ix=r*(-1),r do
		for iy=r*(-1),r do

			if ix == 0 and iy == 0 then
			else
				if readmap (x+ix,y+iy,'b')==v and readmap (x+ix,y+iy-1,'b')==0 then 
					writemap (x+ix,y+iy-1, w) 
					return x+ix,y+iy-1
				end
			end

		end
		end
	end

end

-- COLLIDE
--------------------------------------------------

function collide_check (who,t,mode)

	local a = {}
	if type(who) == 'string' then
		who = colliders[who]
	end

	for k,v in pairs(colliders) do
		if v.type == t then

			--dump (who)
			--dump (v)
			--print (who.w.."--"..v.x.." "..who.x.."-"..v.w.." "..who.h.."-"..v.y.." "..who.y.."-"..v.h)
			
			if (who.w<v.x or who.x>v.w) or (who.h<v.y or who.y>v.h) then
			else
				
				if mode==nil then
					return v
				end

				if mode and mode.name and mode.name==v.name then
					return v
				end

				if mode and mode.arrname and in_array (mode.arrname,v.name) then
					return v
				end



				if mode and mode.arr then
					table.insert (a,v)
				end
			end
		end
	end

	if mode and mode.arr then return a end

end



function col_add (id,obj,state,name,t,num)
	
	local oldname = name
	if state and cols[name.."_"..state] then
		name = name.."_"..state
	end

	if obj.d and cols[name.."_"..obj.d] then
		name = name.."_"..obj.d
	end

	local c

	if obj.flip == -1 and oldname=='player' then

		c = {
		x = obj.truex + (cols[name][3] + cols[name][1]) * (-1), 
		y = obj.truey + cols[name][2], 
		w = obj.truex + cols[name][3] + ((cols[name][3] + cols[name][1]) * (-1)),
		h = obj.truey + cols[name][2]+cols[name][4], 
		name = name, --5
		type = t,--6
		n = num
		}

	else
		
		if obj.truex==nil then
			oldprint (dumpvar (obj))
		end

		c = {
		x = obj.truex + cols[name][1], 
		y = obj.truey + cols[name][2], 
		w = obj.truex + cols[name][1]+cols[name][3],
		h = obj.truey + cols[name][2]+cols[name][4], 
		name = name, --5
		type = t,
		n = num --6
		}
	end

	if id and id~='' then colliders[id] = c end
	
	return c

end

local function nearest_collision_offset(offsets)
	if #offsets == 0 then
		return nil
	end
	return math.min(unpack(offsets)) - 1
end


-- collide (obviously)
function tocollide (points, pass)

	--pass = pass or game.pass
	
	dumpout=""
	local togo = {up = {}, down = {}, right = {}, left = {}, y ={}, x={}}


	for i,v in ipairs(points) do
		local x = v.x
		local y = v.y
		local mode = v.mode or {}
		

		local r = px2tile (x,y)
		local tile = tile2px (r.x, r.y)

		if maptile (r.x,r.y) == 1 then --hit
			table.insert (togo.y, 32 - (y - tile.y2)*-1)
			table.insert (togo.x, 32 - (x - tile.x2)*-1)
		end


		--up
		if mode.up
			then
			local r = px2tile (x,y)
			local tile = tile2px (r.x, r.y-1)

			if maptile (r.x,r.y-1) == 0 or (pass and maptile (r.x,r.y-1, pass) == 1)--cango
				then
				table.insert (togo.up, (tile.y2 - y - 32)*-1)
			else
				table.insert (togo.up, (tile.y2 - y)*-1)	
			end
		end

		--down
		if mode.down
			then
			local r = px2tile (x,y)
			local tile = tile2px (r.x, r.y+1)

			if maptile (r.x,r.y+1) == 0 or (pass and maptile (r.x,r.y+1, pass) == 1) --cango
				then
				table.insert (togo.down, tile.y2 - y)
			else
				table.insert (togo.down, tile.y2 - y - 32)	
			end
		end


		--right
		if mode.right
			then
			local r = px2tile (x,y)
			local tile = tile2px (r.x, r.y)

			if maptile (r.x+1,r.y) == 0 or (pass and maptile (r.x+1,r.y, pass) == 1) --cango
				then
				table.insert (togo.right, tile.x2 - x + 32)
			else
				table.insert (togo.right, tile.x2 - x)
			end
		end


		--left
		if mode.left
			then
			local r = px2tile (x,y)
			local tile = tile2px (r.x-1, r.y)

			if maptile (r.x-1,r.y) == 0 or (pass and maptile (r.x-1,r.y, pass) == 1) --cango
				then
				table.insert (togo.left, (tile.x2 - x - 32)*-1)
			else
				table.insert (togo.left, (tile.x2 - x)*-1)
			end

		end

	end
	
	if #togo.x>0 then
	togo.x = (math.max (unpack(togo.x)))
	if togo.x < 16 then togo.x = togo.x *(-1) end 
	if togo.x > 16 then togo.x = 32-togo.x end
	else
		togo.x = nil
	end	
	
	if #togo.y>0 then
	togo.y = (math.max (unpack(togo.y)))
	if togo.y < 16 then togo.y = togo.y *(-1) end 
	if togo.y > 16 then togo.y = 32-togo.y end
	else
		togo.y = nil
	end	
	
	
	
	togo.up = nearest_collision_offset(togo.up)
	togo.down = nearest_collision_offset(togo.down)
	togo.left = nearest_collision_offset(togo.left)
	togo.right = nearest_collision_offset(togo.right)


		if togo.x then
		--	dump (togo)
		end

	return togo

end



function cd_passed (a,name,n)

	if a[name]==nil then
		a[name] = game.dt + n
		return nil
	end

	if a[name] then 
		if a[name]< game.dt then 
			a[name] = nil
			return true
		end
		return nil
	end

end



function cooldown (a,name,mode,rand)

	--mode:set
	rand = rand or 0

	if type(mode)=='number' then
		a[name.."_cd"] = game.dt + mode
		return true
	end

	if mode == "set" then
		a[name.."_cd"] = game.dt + a[name]
		return true
	end

	a[name.."_cd"] = a[name.."_cd"] or game.dt

	if a[name.."_cd"] and a[name.."_cd"] < game.dt then
		
		if mode==nil then
			a[name.."_cd"] = game.dt + a[name] + math.floor(a[name]*love.math.random (0,rand))
		end
		--mode:check
		return true
	end
	return false
end





-- INVENTORY
--------------------------------------------------

function loot_make (l)
	
	if l then 						

		local t = 0
		local t2 = 0
		for k,v in ipairs (l) do
			t = t + v.p
		end

		local rn = love.math.random (0,t)

		for k,v in ipairs(l) do
			t2 = t2 + v.p
			if rn <= t2 then
				return v.i
			end
		end
	end

end

function item_firing (x,y,tile,map, temp, time, to)

	local tneed = map.de/temp -- temperature
	writemap (x,y,tneed,'tneed')

	if tneed>1 then
		tneed = 1
		local cd = map.cd or 0
		cd = cd + dt

		local done = cd/(time/2) -- time

		if done>=1 then 
			--writemap (x,y,to,'clear') --new jug
			writemap (x,y,to) --new jug
			writemap (x,y,nil,'tneed')
			writemap (x,y,nil,'cd')
			writemap (x,y,nil,'done')
			
			return true
		end

		writemap (x,y,cd,'cd')
		writemap (x,y,done,'done')

	end

end

function item_make (i,pc)

	item_unlock (i)

	-- Id
	-- Durability
	-- Name
	-- Created
	-- Ticks

	pc = pc or 1
	if item[i] == nil then return nil end
	
	local it = {}
	it.i = i
	it.d = item[i].durability
	it.n = item[i].name
	
	if item[i].ttl then
		it.c = game.time
		it.t = item[i].ttl*pc
	end

	if item[i].tool then
		it.tool = tablecopy (item[i].tool)
	end

	return it

end


function inv_item (slot, stat, write)

	if pl.inv[slot] then
		if write then
			pl.inv[slot][stat] = write
			return true
		else
			return pl.inv[slot][stat]
		end
	end

	return false
end


function itemstat (i,stat)
	
	if i==nil then return nil end

	if type (i) ~= 'table' then
		i = item[tonumber (i)]
	end

	if i then
		if i.tool and i.tool[stat] then return i.tool[stat] end
		if i[stat] then return i[stat] end
	end

	if type (i) == 'table' then
		return itemstat (i.i, stat)
	end

end

function tool_damage_per_second(tool)
	if type(tool) ~= "table" then return 0 end

	local minimum = tonumber(tool.dmgmin)
	local maximum = tonumber(tool.dmgmax)
	if minimum == nil and maximum == nil then return 0 end

	minimum = minimum or maximum
	maximum = maximum or minimum
	local speed = tonumber(tool.digspeed) or 1
	if speed <= 0 then speed = 1 end

	return ((minimum + maximum) / 2) / speed
end


function next_numeric_id(values)
	local maximum = 0
	for key in pairs(values or {}) do
		if type(key) == "number" and key > maximum and key == math.floor(key) then
			maximum = key
		end
	end
	return maximum + 1
end


function inv_itemstat (slot,stat)

	local item = pl.inv[slot]
	return itemstat (item, stat)

end


function inv_add (it,mode)

	mode = mode or {}
	if it==nil then return nil end

	for i=1,pl.invsize do
		if pl.inv[i]==nil then

			pl.inv[i] = it

			pl.invselect = i

			if pl.inv[pl.invselect]==nil then
				pl.invselect = i
			end

			if mode.select then
				pl.invselect = i
			end

			if item[pl.inv[i].i].ontake then
				item[pl.inv[i].i].ontake ()
			end

			if mode and mode.verbose then
				textwall (msg.game[21],false,{[1] = item[pl.inv[i].i].name})
			end

			inv_compact ()
			item_unlock (it.i)
			return i
		end
	end

	item_unlock (it.i)
	if mode.pick then
		textwall (msg.game[44],true)
	end
	return inv_ground_add (pl.xt, pl.yt, it,mode)
	
end


function inv_count ()
	local c = 0
	local max = 0

	for i,v in pairs(pl.inv) do
		if type(i)=='number' then
			c = c + 1
			if i>max then max = i end
		end
	end

	return c,max

end

function inv_compact_old ()
	local e = 0
	local last = 0

	for i=1,pl.invsize do
		if pl.inv[i] then last = i end
	end

	for i=1,last do
		if pl.inv[i]==nil and e==0 then 
			e = i 
		end
	end

	if last~=0 and e~=0 and last~=e then
		pl.inv[e] = tabledeepcopy (pl.inv[last])
		pl.inv[last] = nil

		if pl.invselect==last then pl.invselect = e end
	end

end


function item_score (it)

	if it==nil then return 0 end

	if item[it.i].score then
		return item[it.i].score
	end

	local s = 0
	for i,v in ipairs({'dig','cut','chop','smash','pierce','dmgmin','dmgmax'}) do
		s = s + (itemstat(it,v) or 0)
	end


	if item[it.i].onuse then
		s = s + 50
	end

	if s>0 then s = s + 1000 end

	s = s + (itemstat(it,'calories') or 0)*0.001
	if s>0 then s = s + 100 end

	if item[it.i].onburydie then 
		s = s + 10
	end

	s = s + it.i*0.001

	return s

end

function item_score_sort (k1,k2)
	return item_score (k1) > item_score (k2)
end


function inv_tick_ttl ()
	local entries = {}
	for _, value in pairs(pl.inv or {}) do
		entries[#entries + 1] = value
	end

	for _, value in ipairs(entries) do
		local slot
		for key, current in pairs(pl.inv or {}) do
			if current == value then
				slot = key
				break
			end
		end

		local definition = value and item[value.i]
		if slot and definition then
			local elapsed = game.time - (value.c or game.time)
			value.t = (value.t or definition.ttl or 0) - elapsed * (definition.tti or 0)
			value.c = game.time

			if value.t <= 0 then
				local handled
				if definition.oninvdie then
					handled = definition.oninvdie()
				end

				if handled == nil then
					if definition.invdie and definition.invdie ~= 0 then
						textwall(msg.game[23], false, {
							[1] = definition.name,
							[2] = item[definition.invdie].name,
						})
						pl.inv[slot] = item_make(definition.invdie)
					else
						textwall(msg.game[24], false, { [1] = definition.name })
						inv_remove(slot)
					end
				end
			end
		end
	end
end


function inv_overflow ()
	local slots = {}
	for slot in pairs(pl.inv or {}) do
		if type(slot) == "number" and slot > pl.invsize then
			slots[#slots + 1] = slot
		end
	end
	table.sort(slots)

	for _, slot in ipairs(slots) do
		local dropped = inv_remove(slot, { noc = true })
		if dropped then inv_ground_add(pl.tx, pl.ty, dropped) end
	end
	if #slots > 0 then inv_compact() end
	return #slots
end


function inv_resize(delta)
	pl.invsize = math.max(0, (pl.invsize or 0) + delta)
	if delta < 0 then inv_overflow() end
	return pl.invsize
end

function inv_show ()

	pl.inv_show_c = 0
	pl.inv_show = {}

	for i=1,pl.invsize do
		if pl.inv[i] then
			
			table.insert (pl.inv_show, i)

			if i==pl.invselect then
				pl.inv_show_c = #pl.inv_show
			end

		end
	end

	for i,k in ipairs(cf.eq) do
		if pl.inv[k] then
			
			table.insert (pl.inv_show, k)

			if k==pl.invselect then
				pl.inv_show_c = #pl.inv_show
			end

		end
	end

end

function inv_compact ()


	local selected = pl.inv[pl.invselect]
	local newinv = {}

	for i=1,pl.invsize do
		if pl.inv[i] then
			newinv[#newinv + 1] = pl.inv[i]
		end
	end

	table.sort (newinv,item_score_sort)

	for i=1,pl.invsize do
		pl.inv[i] = newinv[i]
		if pl.inv[i] == selected then
			pl.invselect = i
		end
	end


	inv_show ()


end



function inv_remove (i, mode)

	mode = mode or {}

	if pl.inv[i] then

		game.justremoved = pl.inv[i].i

		local l = pl.inv[i]
		pl.inv[i] = nil

		if item[l.i].ondrop then
			item[l.i].ondrop ()
		end

		if type(i)=='number' then

			local is = nil

			for i=1,pl.invsize do
				if pl.inv[i] and pl.inv[i].i == l.i then
					pl.invselect = i
					is = true
				end
			end

			if mode.noc==nil then inv_compact () end

			if is == nil then

				while pl.inv[pl.invselect]==nil and pl.invselect>0 do
					pl.invselect = pl.invselect - 1
				end

				while pl.inv[pl.invselect]==nil and pl.invselect<9 do
					pl.invselect = pl.invselect + 1
				end


			end

		else

			if item[l.i].onunequip then
				item[l.i].onunequip ()
			end

		end


		return l

	end
	return nil
end


function inv_ground_count (x,y)
	if world[y] and world[y][x] and world[y][x].i then
		return #world[y][x].i
	end
	return 0
end

function inv_find(z,to)
	
	if type(z) == "table" then
		for i,v in ipairs(z) do
			local r = inv_find (v)
			if r~=nil then return r end
		end
		return nil
	end

	if pl.inv==nil then return nil end

	for k,v in pairs(pl.inv) do
		if v.i==z then
			if to then 
				pl.inv[k] = item_make(to)
			end
		 	return k 
		end
	end

	return nil

end


function inv_ground_find(x,y,z)
	
	if type(z) == "table" then
		for i,v in ipairs(z) do
			local r = inv_ground_find (x,y,v)
			if r~=nil then return r end
		end
		return nil
	end
	
	local inv = world[y][x].i
	if inv==nil then return nil end

	for k,v in pairs(inv) do
		if v.i==z then return v end
	end

	return nil
end

function inv_ground_find_i(x,y,z)
	
	if type(z) == "table" then
		for i,v in ipairs(z) do
			local r = inv_ground_find_i (x,y,v)
			if r~=nil then return r end
		end
		return nil
	end

	local inv = world[y][x].i
	if inv==nil then return nil end

	for k,v in pairs(inv) do
		if v.i==z then return k end
	end

	return nil
end


function inv_ground_find_r (x,y,z,r)
	for ix=x-r,x+r do
		for iy=y-r,y+r do

			if inv_ground_find_i (ix,iy,z) then
				return ix,iy
			end
		
		end
	end
end


function inv_ground_replace (x,y,i,it)
	if world[y] and world[y][x] and world[y][x].i[i] then

		if it == nil then
			inv_ground_remove (x,y,i)
			return false
		end

		world[y][x].i[i] = it
		return true

	end

	return false
	
end


function inv_ground_add (x,y,it,mode)

	mode = mode or {}

	if type(mode.items) == "table" then
		for k,v in pairs(mode.items) do inv_ground_add (x,y,v) end 
	end

	if world[y] and world[y][x] and it~=nil then

		if world[y][x].i == nil then world[y][x].i = {} end

		if mode.groundlast then
			table.insert (world[y][x].i,it)
			else
			table.insert (world[y][x].i,1,it)
			end
		game.ttl_list[x.."-"..y] = {x,y}
		return it

	else
		return nil
	end

end

function inv_ground_remove (x,y,i)

	if world[y] and world[y][x] and world[y][x].i then
		local r = table.remove (world[y][x].i,i)
		if #world[y][x].i == 0 then 
			world[y][x].i = nil 
			world[y][x].io = nil 
			if (maptile (x,y,'ttl') or 0)==0 then
				game.ttl_list[x.."-"..y] = nil
			end
		end
		return r
	else
		return nil
	end

end


function item_wear (i,pc)

	if i==nil or i.i==nil then
		return nil,nil
	end

	if item[i.i].ttl then
		i.t = math.ceil (i.t - item[i.i].ttl*pc)
	end

	return i
end


-- PLAYER AND STATS
--------------------------------------------------

function give_legacy (inv)

	local how = function (x,y)
		local g = readmap (x,y,'g') or 0
		if g==-1 then
			return true
		end
	end

	local x,y = find_block (pl.startx, pl.starty+5,how,20)
	writemap (x,y,49)
	
	for k,v in pairs(inv) do
		if v.i~=26 and v.i~=27 and v.i~=284 and v.i~=285 then 
			inv_ground_add (x,y,v)
		end
	end 

end



function player_pos_reset (x,y)
	vi.xoffset = 0
	vi.yoffset = 0
	pl.x = 16
	pl.y = 32*4+6
	vi.xtile   = x or pl.startx
	vi.ytile   = y or pl.starty
	coord_screen2true (pl)
	camera_move ()
	camera_fix ()
end

function player_pos_port (x,y)
	vi.xoffset = 0
	vi.yoffset = 0

	local r = tile2px (x,y)

	pl.x = r.x
	pl.y = r.y
	--vi.xtile   = x
	--vi.ytile   = y
	coord_screen2true (pl)
	camera_move ()
	camera_fix ()
end

function player_reset ()
	
	pl.inv = {}

	player_pos_reset ()
	pl.state = 'idle'
	--player_pos_reset ()
	stat_spend ('power', 75)
	shader:send("dying", 0)
	sound_kill ('heartbeat')
	sound_add ('born',13)

	ani_setstatus (game.start,'born')
	writemap (pl.tx,pl.ty,0,'n')
	love.audio.setVolume(1)

end

function player_rest (x,y,q,h)


	pl.resttillhealed = true
	local r = readmap (x,y,'room') or 0
	
	pl.rest = time.h*h
	game.fadein = 0.5
	pl.restquality = q+r*0.1

	local de = readmap (pl.xt, pl.yt,"de") or 0
	if de>5 then
		pl.restquality = pl.restquality + 0.2
	end

	achi_set (10,pl.restquality*100)

	--game.autosave = true
	--game_save (game.savepos)
	--game.screenshot = true


end


function drink_dirt (dirt)

	if dirt==nil then return end

	if dirt>50 then
		achi_add (29,1)
	end

	if love.math.random (0,100)<30 then return end

	local r = love.math.random (0,dirt)
	if r>70 and pl.buffs[17]==nil then
		buff_add (17) --dizzy
		return
	end

	local r = love.math.random (0,dirt)
	if r>60 and pl.buffs[15]==nil then
		buff_add (15) --fever
		return
	end

	local r = love.math.random (0,dirt)
	if r>50 and pl.buffs[16]==nil then
		buff_add (16) --diarrhoea
		return
	end

	local r = love.math.random (0,dirt)
	if r>40 and pl.buffs[2]==nil then
		buff_add (2) -- poison
		return
	end

	local r = love.math.random (0,dirt)
	if r>25 and pl.buffs[3]==nil then
		buff_add (3) --food poison
		return
	end

end

function player_die ()

		pl.rest = 0
		pl.unrest = 0
		pl.isdead = true
		pl.score = math.ceil (pl.score / 2)
		pl.daylived = math.floor ((game.time - (pl.lastdeath or 0))/time.d)

		pl.lastdeath = game.time


		shader:send("dying", 0)
		sound_kill ('heartbeat')
		sound_killall ()

		pl.deaths = pl.deaths + 1
		pl.dying = 1
		
		sct = {}
--		pl.noflashlight = true

		pl.spenddead = time.h
		pl.stats.body.hp = 0

		for k,v in pairs(pl.inv) do

				if v.i~=26 and v.i~=27 and v.i~=284 and v.i~=285 then --flashlight

					local it = inv_remove(k,{noc=true})

					if item[it.i] and item[it.i].ttl then
						--it.t = it.t - math.floor (item[it.i].ttl*(pl.deaths*0.1))
					end
				
					inv_ground_add (pl.xt,pl.yt,it)
				end
			
		end


		diet_recovery (200)

		--shitting
		for i,v in ipairs(pl.shit) do
			inv_ground_add (pl.xt,pl.yt,item_make(i))
		end
		pl.shit = {}
		buff_remove (1)
		pl.unrest = time.min*5
		
		ttl_checks (game.ttl_list)
		buff_remove_all ()

		--stats_reset ()
		--inv_add (item_make(26))


end

function stats_reset ()

	pl.stats = {}
	pl.stats.arms = {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0.05, currentgrow = 0, maxgrow = 100}
	pl.stats.filth ={hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0}
	pl.stats.body = {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0.05, currentgrow = 0, maxgrow = 100}
	pl.stats.food = {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0.05, currentgrow = 0, maxgrow = 100}
	pl.stats.water= {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0.05, currentgrow = 0, maxgrow = 100}
	pl.stats.power= {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0}
	pl.stats.heat = {hp = 100, maxhp = 100, lvl = 0, pc = 100, d = 0, grow = 0, currentgrow = 0, maxgrow = 100}

	pl.stats.faith= {hp = 0, maxhp = 100, lvl = 0, pc = 0, d = 0}

	pl.dishes = {}
	achi_ini ()
	achi_reset ()

end

function player_hit (hp,what)

	if pl.isdead then return end

	achi_trigger ('on_hit',hp)

	for k,v in pairs(pl.inv) do
		if type(k)~='number' and pl.inv[k] and item[pl.inv[k].i].onstruck then
			hp = item[pl.inv[k].i].onstruck((hp or 0),what)
			pl.inv[k].t = pl.inv[k].t - 1 --durability hit
		end
	end

	pl.digcount = -1
	stat_spend ('body',hp)
	hp = math.ceil (hp)
	if hp>=1 then
		sound_add ('hit',6,{volume = (100-pl.stats.body.pc)*0.1})
		hp = hp * (-1)
		table.insert (sct,{x=pl.x+love.math.random(-8,8),y=pl.y-32,text=text_color("{#e43b44ff}"..hp),ttl=0.8,xs=pl.flip*-1*(love.math.random(5,30))})
	end
	-- pl.stats.body.hp = pl.stats.body.hp - hp
	--pl.stats.body.d = pl.stats.body.d - hp
end


function player_regen (hp,what)

	stat_recovery ('body',hp)
	--sound_add ('hit',6,{volume = (100-pl.stats.body.pc)*0.1})

	hp = math.ceil (hp)
	if hp>=1 then
		table.insert (sct,{x=pl.x+love.math.random(-8,8),y=pl.y-32,text=text_color("{#3e8948ff}+"..hp),ttl=1.8,xs=pl.flip*-1*(love.math.random(5,30))})
	end

end

function reduce (a)
	if a then 
		a = a - 1
		if a<1 then a = nil end
	end
	return a
end

function diet_recovery (n)
	for k,v in pairs(cf.diet) do
		pl.diet[v] = pl.diet[v] - n
		if pl.diet[v] < 0 then pl.diet[v]=0 end
	end
end

function stat_spend (stat,h)
	-- pl.stats.arms = {hp = 100, maxhp = 100, lvl = 0}

	if h==nil then return end

	if pl.dying then 
		return
	end

	if h>=1 then
		game.lasthit = stat
	else
		game.lasthit = ""
	end


	if h>9 and stat~='body' then
		table.insert (sct,{ys=20,xs=-10,font=2,x=pl.x+love.math.random(-30,-20),y=pl.y-32,text=text_color("{#f77622ff}-"..math.floor(h).." "..msg.stats[stat]),ttl=2.1,xs=pl.flip*-1*(love.math.random(5,40))})
	end


	pl.stats[stat].hp = pl.stats[stat].hp - h

	if
		pl.stats[stat].hp > pl.stats[stat].maxhp then
		pl.stats[stat].hp = pl.stats[stat].maxhp 
	end

	if pl.stats[stat].hp<=0 and pl.stats[stat].hp+h>0 and stat == 'arms' then
		buff_add (7,'keep')
		textwall (msg.game[43])
	end

	if stat == 'food' then
		diet_recovery (h/6)
	end

	if stat == 'body' and pl.stats[stat].hp<=10 then
		shader:send("dying", 1)
		sound_add ('heartbeat',24)
	end

	if pl.stats[stat].hp<0 and stat ~= 'body' and stat~= 'power' and stat ~= 'filth' then
		if pl.unrest==0 then
			player_hit (math.ceil(-1*pl.stats[stat].hp))
		end
	end

	if pl.stats[stat].hp<0 then
		pl.stats[stat].hp = 0
	end

	pl.stats[stat].pc = math.floor (pl.stats[stat].hp/pl.stats[stat].maxhp*100)
end

function player_score (score)
	pl.score = pl.score + (score/(pl.deaths+1))
	pl.savedscore = (pl.savedscore or 0) + (score/(pl.deaths+1))
end

function stat_recovery (stat,h,arr)

	
	if stat=='power' and pl.isdead==nil then
		player_score (h*50)
		achi_set (26,math.ceil(pl.stats[stat].hp))
	end

	if (h>9 or stat=='faith') and stat~='body' and pl.isdead==nil then
		table.insert (sct,{ys=20,font=2,x=pl.x+love.math.random(10,20),y=pl.y-32,text=text_color("{#63c74dff}+"..math.floor(h).." "..msg.stats[stat]),ttl=2.1,xs=pl.flip*-1*(love.math.random(5,40))})
	end

	pl.stats[stat].hp = pl.stats[stat].hp + h

	if
		pl.stats[stat].hp > pl.stats[stat].maxhp then
		pl.stats[stat].hp = pl.stats[stat].maxhp 
	end

	if stat == 'body' and pl.stats[stat].hp>10 then
		shader:send("dying", 0)
		sound_kill ('heartbeat')
	end

	pl.stats[stat].pc = math.floor (pl.stats[stat].hp/pl.stats[stat].maxhp*100)

	--2remove
	pl.stats[stat].currentgrow = pl.stats[stat].currentgrow or 0
	pl.stats[stat].maxgrow = pl.stats[stat].maxgrow or 100


	if pl.stats[stat].pc>30 and pl.stats[stat].pc<70 and pl.stats[stat].grow then
		local gr = pl.stats[stat].grow * h * (pl.stats[stat].hp/pl.stats[stat].maxhp)
		pl.stats[stat].currentgrow = pl.stats[stat].currentgrow + gr
		if pl.stats[stat].currentgrow<pl.stats[stat].maxgrow then
			pl.stats[stat].maxhp = pl.stats[stat].maxhp + gr
		end
	end

end



function consume_cal (it,consume)


	local bad = 0
	local i = it.i
	local age = 1-it.t/item[i].ttl
	local cal = item[i].calories

	local multi


	if pl.dishes==nil or pl.dishes[i]==nil then
		multi = true
		cal = cal*2	
	end

	age = math.floor (age * cal/2)
	cal = cal - age
	local oldcal = cal


	local cal2 = 0
	local recal = 0

	if item[i].diet and pl.buffs[11]==nil then

		--second type
		if item[i].diet[2] and item[i].diet[2]~='freezable' then

			cal2 = cal * 0.33
			cal = cal - cal2

			pl.diet[item[i].diet[2]] = pl.diet[item[i].diet[2]] or 0
			local diet = pl.diet[item[i].diet[2]] or 0

			if diet ~= 100 then bad = bad + 1 end

			diet = (130 - diet)/100
			cal2 = cal2 * diet

			if consume then
				pl.diet[item[i].diet[2]] = pl.diet[item[i].diet[2]] + cal2
				if pl.diet[item[i].diet[2]]>100 then
					pl.diet[item[i].diet[2]]=100
				end
			end

		end

		pl.diet[item[i].diet[1]] = pl.diet[item[i].diet[1]] or 0
		local diet = pl.diet[item[i].diet[1]] or 0

		if diet ~= 100 then bad = bad + 1 end

		diet = (130 - diet)/100
		cal = cal * diet


		--print (pl.diet[item[i].diet[1]])

		if consume then
			pl.diet[item[i].diet[1]] = pl.diet[item[i].diet[1]] + cal
			if pl.diet[item[i].diet[1]]>100 then
				pl.diet[item[i].diet[1]]=100
			end
		end
		
		if multi then
			cal2 = 0
			cal = oldcal
		end

		recal = cal + cal2
		
		local d = math.ceil (recal-oldcal)

		age = age*(-1)

		if d>0 then d = "+"..d end
		if age==0 then age = "" end
		if d==0 then d = "" end

		return age, d, recal, multi, bad

	end

	if consume then
		 buff_remove (11)
	end

	return "","",oldcal


end



-- -- editor chunk maps
-- function love.mousepressed (x,y,button)
-- 	if button==1 and game.dbg[2] then
		
-- 		if edit.fin then
-- 			edit = {}
-- 		end

-- 		edit.x = x
-- 		edit.y = y
-- 	end
-- end

-- function love.mousereleased (x,y,button)
-- 	if button==1 and game.dbg[2] then
-- 		edit.fin = 1
-- 		game.pause = true
-- 	end
-- end

-- function love.mousemoved (x,y)
-- 	if edit.x and not edit.fin and game.dbg[2] then
-- 		edit.w = x - edit.x
-- 		edit.h = y - edit.y
-- 		edit.x2 = x
-- 		edit.y2 = y
-- 		--dump (edit)
-- 	end
-- end



function savefiles ()

	local str = ""
	for i=1,9 do
		local info = game_save_slot_info and game_save_slot_info(i)
		str = str.."\n"
		if info==nil then
			str = str..i.."] -----------------"
		else
			str = str..i.."] "..I18N.format_datetime(msg, info.modtime)
		end
	end
	return str

end

function game_migrate ()

	pl.inv = pl.inv or {}
	pl.invsize = pl.invsize or 9
	pl.invselect = pl.invselect or 1
	pl.stats = pl.stats or {}
	pl.visited = pl.visited or {}
	pl.ferted = pl.ferted or {}
	pl.disastercd = pl.disastercd or 0
	pl.disaster = pl.disaster or {}
	for name, config in pairs(cf.disaster or {}) do
		pl.disaster[name] = pl.disaster[name] or {
			cd = config.ini,
			cnt = 0,
		}
		pl.disaster[name].cd = pl.disaster[name].cd or config.ini
		pl.disaster[name].cnt = pl.disaster[name].cnt or 0
	end

	-- Older builds could leave items above invsize after a bag or temporary
	-- capacity buff was removed. Recover those hidden items onto the ground.
	inv_overflow()
	inv_compact ()
	achi_ini ()
	pl.stats.faith = pl.stats.faith or {hp = 0, maxhp = 100, lvl = 0, pc = 0, d = 0}

end


local save_slot_formats = {
	{ suffix = ".sav", compressed = false, priority = 1 },
	{ suffix = ".sav.bak", compressed = false, priority = 2 },
	{ suffix = ".save", compressed = true, priority = 3 },
}

local function save_slot_candidates(name)
	local candidates = {}
	for _, format in ipairs(save_slot_formats) do
		local filename = tostring(name) .. format.suffix
		local info = love.filesystem.getInfo(filename, "file")
		if info then
			candidates[#candidates + 1] = {
				filename = filename,
				compressed = format.compressed,
				priority = format.priority,
				info = info,
			}
		end
	end

	table.sort(candidates, function(left, right)
		local left_time = left.info.modtime or 0
		local right_time = right.info.modtime or 0
		if left_time == right_time then
			return left.priority < right.priority
		end
		return left_time > right_time
	end)

	return candidates
end

function game_save_slot_info(name)
	local candidate = save_slot_candidates(name)[1]
	if candidate then
		return candidate.info, candidate.filename
	end
	return nil
end

function game_delete_save(name)
	local removed = false
	for _, suffix in ipairs({ ".sav", ".sav.bak", ".save", ".png" }) do
		local filename = tostring(name) .. suffix
		if love.filesystem.getInfo(filename) then
			removed = love.filesystem.remove(filename) or removed
		end
	end
	return removed
end

local function write_with_backup(filename, data)
	local previous = love.filesystem.read(filename)
	if previous then
		local backed_up, backup_error = love.filesystem.write(filename .. ".bak", previous)
		if not backed_up then
			return false, backup_error or "could not write backup"
		end
	end

	local written, write_error = love.filesystem.write(filename, data)
	if not written then
		return false, write_error or "could not write file"
	end
	return true
end

local function decode_metasave(serialized)
	local decompressed = love.data.decompress("string", "gzip", serialized)
	local values = binser.deserialize(decompressed)
	if type(values) ~= "table" or type(values[1]) ~= "table" then
		error("invalid metadata payload")
	end
	return values[1]
end


function game_loadinfo ()
	for _, filename in ipairs({ "info.save", "info.save.bak" }) do
		local save = love.filesystem.read(filename)
		if save then
			local decoded, metasave = pcall(decode_metasave, save)
			if decoded then
				game.metasave = metasave
				return true
			end
		end
	end

	game.metasave = {}
	return false

end

function game_saveinfo ()
	game.metasave = game.metasave or {}
	game.metasave.score = game.metasave.score or 0

	if pl.score>(game.metasave.hiscore or 0) then
		game.metasave.hiscore = pl.score
	end

	game.metasave.inv = pl.inv
	game.metasave.lastscore = pl.score
	game.metasave.savedscore = pl.savedscore
	game.metasave.oldtimes = game.time
	game.metasave.gamepos = game.savepos
	


	local encoded, save = pcall(function()
		local serialized = binser.serialize(game.metasave)
		return love.data.compress("string", "gzip", serialized)
	end)
	if not encoded then
		return false, save
	end

	return write_with_backup("info.save", save)

end



function game_autosave (name)
	local m = love.thread.getChannel( 'saveinfo' ):pop()
	love.thread.getChannel('saveinfo'):push('busy')

	if m~='busy' then
		if savethread then
			savethread:release( )
		end
		savethread = love.thread.newThread('src/save.lua')
		savethread:start(name,world, vi, pl, game, tips, disp, cf, mobs)
	else
		love.thread.getChannel('saveinfo'):push('busy')
	end

	love.graphics.captureScreenshot(name..".png")

end

function table_save (name,a,deterministic)
	local BlobWriter = require('src.BlobWriter')
	blob = BlobWriter()
	if deterministic then
		blob:writeDeterministic(a)
	else
		blob:write(a)
	end
	local save = blob:tostring()
	love.filesystem.write (name, save)
end

function table_load (name)

	local BlobReader = require('src.BlobReader')
	local save = love.filesystem.read(name)

	a = {}
	if save then
		local blob = BlobReader(save)
		a = blob:read()
	end

	return a

end


function game_save (name)
	local encoded, save = pcall(function()
		local BlobWriter = require("src.BlobWriter")
		local blob = BlobWriter()
		blob:write(world)
			:write(vi)
			:write(pl)
			:write(game)
			:write(tips)
			:write(disp)
			:write(cf)
			:write(mobs)
		return blob:tostring()
	end)

	if not encoded then
		textwall(msg.persistence.save_failed, false)
		return false, save
	end

	local written, write_error = write_with_backup(tostring(name) .. ".sav", save)
	if not written then
		textwall(msg.persistence.save_failed, false)
		return false, write_error
	end

	game.lastsave = (game.dt or 0) + 60 * 10
	local metadata_saved, metadata_error = game_saveinfo()
	if not metadata_saved and oldprint then
		oldprint("Could not save game metadata: " .. tostring(metadata_error))
	end

	love.graphics.captureScreenshot(tostring(name) .. ".png")
	textwall(msg.game[1], false)
	return true
end


local function decode_game_save(serialized, compressed)
	if compressed then
		serialized = love.data.decompress("string", "gzip", serialized)
	end

	local BlobReader = require("src.BlobReader")
	local blob = BlobReader(serialized)
	local state = {
		world = blob:read(),
		vi = blob:read(),
		pl = blob:read(),
		game = blob:read(),
		tips = blob:read(),
		disp = blob:read(),
		saved_cf = blob:read(),
		mobs = blob:read(),
	}

	for _, key in ipairs({ "world", "vi", "pl", "game", "tips", "disp", "saved_cf", "mobs" }) do
		if type(state[key]) ~= "table" then
			error("invalid " .. key .. " section")
		end
	end
	if next(state.world) == nil then
		error("empty world section")
	end

	return state
end

local function activate_game_save(state)
	local previous = {
		world = world,
		vi = vi,
		pl = pl,
		game = game,
		tips = tips,
		disp = disp,
		ncf = ncf,
		mobs = mobs,
	}

	world = state.world
	vi = state.vi
	pl = state.pl
	game = state.game
	tips = state.tips
	disp = state.disp
	ncf = state.saved_cf
	mobs = state.mobs

	local migrated, migration_error = pcall(function()
		game_migrate()
		game_loadinfo()
		game.lastsave = (game.dt or 0) + 60 * 10
		game.craft = false
	end)
	if migrated then
		return true
	end

	world = previous.world
	vi = previous.vi
	pl = previous.pl
	game = previous.game
	tips = previous.tips
	disp = previous.disp
	ncf = previous.ncf
	mobs = previous.mobs
	return false, migration_error
end

function game_load (name)
	local errors = {}
	local candidates = save_slot_candidates(name)
	if #candidates == 0 then
		return false, "save slot is empty"
	end

	for _, candidate in ipairs(candidates) do
		local save, read_error = love.filesystem.read(candidate.filename)
		if save then
			local decoded, state = pcall(decode_game_save, save, candidate.compressed)
			if decoded then
				local activated, activation_error = activate_game_save(state)
				if activated then
					return true
				end
				errors[#errors + 1] = candidate.filename .. ": " .. tostring(activation_error)
			else
				errors[#errors + 1] = candidate.filename .. ": " .. tostring(state)
			end
		else
			errors[#errors + 1] = candidate.filename .. ": " .. tostring(read_error)
		end
	end

	return false, table.concat(errors, "; ")
end
	

function ini_quad ()

	if IS_DEVELOPMENT then
		--collecting quad
		local files = love.filesystem.getDirectoryItems('/assets/sprites')
		local images = {}

		for i,v in ipairs(files) do
			if v~=".DS_Store" then
				local f = {}
				f.name = v
				f.img = love.graphics.newImage ("assets/sprites/"..v)
				f.w, f.h = f.img:getPixelDimensions( )
				table.insert (images,f)
			end
		end

		table.sort (images, function (k1,k2) 
		if k1.h~=k2.h then
			return k1.h > k2.h 
		else
			return k1.name < k2.name
		end

		end)

		quadlist = {}
		local cnt = 1
		local x = 1
		local y = 1
		local nl = 0
		local dimmax = 1024
		-- The atlas is a source texture, not a display-sized render target.
		-- Letting a Retina window apply its DPI scale here creates a 2048x2048
		-- image while quad coordinates still describe a 1024x1024 atlas. Every
		-- sprite is then sampled from the wrong rectangle (the title and menu
		-- animation are the most obvious casualties).
		quad = love.graphics.newCanvas(dimmax,dimmax,{dpiscale = 1})
		love.graphics.setCanvas(quad)

		for i,v in ipairs(images) do

			if x + v.w > dimmax then
				x = 1
				y = y + nl + 1
				nl = 0
			end

			if nl==0 then
				nl = v.h
			end

			assert(y + v.h <= dimmax, "sprite atlas overflow at "..v.name)

			love.graphics.draw (v.img,x,y)
			quadlist[v.name] = 
			{
				x = x,
				y = y,
				w = v.w,
				h = v.h,
			}

			x = x + v.w + 1

		end

		table_save ('quad.table',quadlist,true)

		love.graphics.setCanvas()
		local atlas_data = quad:newImageData()
		filedata = atlas_data:encode('png','quad.png')
		quad = love.graphics.newImage(atlas_data)
		images = nil

	else

		quadlist = table_load ('quad.table')
		quad = love.graphics.newImage('quad.png')

	end

end
	


function spiral_ini (x,y)

	spiral = {

		dir = {
			{1,0},
			{0,1},
			{-1,0},
			{0,-1},
		},

		dir_n = 1,
		step = 1,
		step_l = 1,
		x = x,
		y = y,
		it = 0

	}

end


function spiral_spin (maxstep)

	spiral.it = spiral.it + 1
	if spiral.dir_n>4 then 
		spiral.dir_n = 1
		spiral.step = spiral.step + 2
		spiral.step_l = spiral.step 
		spiral.x = spiral.x-1
		spiral.y = spiral.y-1
	end

	local d = love.math.random (1,maxstep)

	if d>spiral.step_l then
		d = spiral.step_l
	end

	spiral.step_l = spiral.step_l - d

	spiral.x = spiral.x+spiral.dir[spiral.dir_n][1]*d
	spiral.y = spiral.y+spiral.dir[spiral.dir_n][2]*d

	if spiral.step_l<1 then
		spiral.dir_n = spiral.dir_n + 1 
		spiral.step_l = spiral.step 
	end

	return spiral.x, spiral.y, spiral.it


end

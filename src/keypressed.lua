-- function love.joystickadded (j)
-- 	joystic = j
-- end

-- function love.joystickremoved(j)
-- 	local joysticks = love.joystick.getJoysticks() or {}
-- 	joystick = joysticks[1]
-- end


function block_inspect ()

		if msg.stone[pl.inspect].info==nil then return end

		local str = ""

		sound_add ('wonder', 27)

		str = message (msg.game[22],{[1] = msg.stone[pl.inspect].name, [2] = msg.stone[pl.inspect].info})
		str = str.." "
		
		if msg.stone[pl.inspect].tips then

			if tips['s'..pl.inspect]==nil then
				str = str..msg.dispenser[8].."\n"
			else
				str = str..msg.dispenser[7].."\n"
			end

			for i,v in ipairs(msg.stone[pl.inspect].tips) do
				if i>=(tips['s'..pl.inspect] or 0) then
					str = str.."{#5a6988ff}— "..locked_txt(v)..msg.game[39].."\n"
				else
					str = str.."— "..v.."\n"
				end
			end


		end

		if msg.stone[pl.inspect].tips==nil or (tips['s'..pl.inspect] or 0)>#msg.stone[pl.inspect].tips then
			if stone[pl.inspect].transform or stone[pl.inspect].transformi then
				str = str..message (msg.dispenser[9],{[1] = stone[pl.inspect].transformpower})
			end
		end

		textwall (str,true)
end



function love.wheelmoved(x, y)


	if love.mouse.getY()>screen.txt then

		local h = textlog:getHeight()

		if h>vi.textwall_h then
			pl.logoffset = pl.logoffset + y*4
		end

		draw_textwall ()

	else

		if pl.inv_show[pl.inv_show_c+y] then
			pl.invselect = pl.inv_show[pl.inv_show_c+y]
			if game.network_client and not NETWORK_REMOTE_ACTION then
				multiplayer_send_select_action(pl.invselect, pl.inv[pl.invselect])
			end
		end

		inv_show ()

		-- if type(pl.invselect)=='number' then
		-- 	pl.invselect = pl.invselect + y
		-- 	if pl.invselect<1 then pl.invselect = 1 end
		-- 	if pl.inv[pl.invselect]==nil then pl.invselect = 1 end
		-- 	pl.invpage = math.ceil (pl.invselect/9) - 1
		-- 	craft_ini ()
		-- else
		-- 	love.keypressed('0','0')
		-- end
		
	end

end



function love.textinput(t)
    if game.inputing and t~='`' then
    	game.textinput = game.textinput or ""
    	game.textinputold = game.textinputold or ""
		game.textinputold = game.textinput
    	game.textinput = game.textinput..t
        textwall ((game.textinputinfo or "")..game.textinput.."_",true)
    end

end

function textinput ()

	game.textinput = ""
	game.inputing = nil

end


console = {}


console.save = function (f)

	if edit.fin then

			local r = px2tile (edit.x, edit.y)
			local r2 = px2tile (edit.x2, edit.y2)
			local w = {}

	 		for i=r.x,r2.x do
 			w[(i-r.x+1)] = w[(i-r.x+1)] or {}
 				for ii=r.y,r2.y do
 				
 					w[(i-r.x+1)][(ii-r.y+1)] = tablecopy (world[ii][i])
 					writemap (i,ii,0,'clear')

 				end
 			end

 			print ("{#ffee00ff}saved "..f..'.map')
 			local save = binser.serialize(w)
			love.filesystem.write(f..'.map', save)

			print ("x:"..(r2.x-r.x).." y:"..(r2.y-r.y))
			game.pause = false
			edit = {}
			

	end

end


console.load = function (f)

	local r = px2tile (mouse_x, mouse_y)
	local w = {}

	local l = chunk_load (f)
	chunk_map (r.x,r.y,l)

	game.pause = false
	edit = {}

end


console.reload = function (f)
	development_reload_assets()

end


console.godmode = function (f)
	if f == 'on' then
		print 'god mode on'
		game.dbg[1] = true

		game.items = {}
		for k,v in pairs(item) do
			table.insert (game.items,k)
		end

		game.blocks = {}
		for k,v in pairs(stone) do
			table.insert (game.blocks,k)
		end

	else
		print 'god mode off'
		game.dbg[1] = nil
	end
end


console.arms = function (f)
	if game.dbg[1] then
		local f = (tonumber (f) or 0)
		pl.stats.arms.hp = f
		stat_recovery ('arms',0)
	end
end

console.hp = function (f)
	if game.dbg[1] then
		local f = (tonumber (f) or 0)
		pl.stats.body.hp = f
		stat_recovery ('body',0)
	end
end

console.power = function (f)
	if game.dbg[1] then
		local f = (tonumber (f) or 0)
		pl.stats.power.hp = f
		stat_recovery ('power',0)
	end
end

console.food = function (f)
	if game.dbg[1] then
		local f = (tonumber (f) or 0)
		pl.stats.food.hp = f
		stat_recovery ('food',0)
	end
end

console.b = function (f)
	if game.dbg[1] then
		local f = (tonumber (f) or 0)
		buff_add (f)
	end
end

console.d = function (f)
	if game.dbg[1] then
		local f = (tonumber (f) or 0)
		game.dbg[f] = not game.dbg[f]
	end
end

console.m = function (f)
	if game.dbg[1] then
		local r = px2tile (mouse_x, mouse_y)
		local f = (tonumber (f) or 0)
		mob_create (r.x,r.y,f)
	end
end

console.s = function (f)
	
	if game.dbg[1] then

		local r = px2tile (mouse_x, mouse_y)
	
		if f=="fire" then
			inv_add (item_make (41))
			inv_ground_add (r.x, r.y, item_make (37)) 
			inv_ground_add (r.x, r.y, item_make (15)) 
			inv_ground_add (r.x, r.y, item_make (108)) 
		end

		if f=="soil" then
			writemap (r.x, r.y, 13) 
			writemap (r.x, r.y, 300, 'e') 
			writemap (r.x, r.y, 300, 'wt') 
		end

	end
end

console.f = function (f)

		-- filter items
		game.items = {}
		for k,v in pairs(item) do
			local l = string.lower (v.name)
			local m = string.match (l, f)
			if m then
				table.insert (game.items,k)
			end
		end

		game.blocks = {}
		for k,v in pairs(stone) do
			local l = string.lower (v.name)
			local m = string.match (l, f)
			if m then
				table.insert (game.blocks,k)
			end
		end

		currentBlock = 1
		currentItem = 1
end

-- keypress

function gui_mouse_position(x, y)
	-- The doubled canvas contains only the world. GUI is drawn afterwards in
	-- window coordinates, which are also used by mouse events.
	return x, y
end

local function gui_mouse_row(rows, x, y)
	for _, row in ipairs(rows or {}) do
		if x >= row.x and x < row.x+row.width
			and y >= row.y and y < row.y+row.height then
			return row
		end
	end
end

function inventory_gui_mousepressed(x, y)
	local gui_x, gui_y = gui_mouse_position(x, y)
	local row = gui_mouse_row(game.inventory_action_mouse_rows, gui_x, gui_y)
	if row and row.hold then
		game.gui_throw_down = true
		return true
	end
	if row and row.key and love.keypressed then
		love.keypressed(row.key, row.key)
		return true
	end

	row = gui_mouse_row(game.inventory_mouse_rows, gui_x, gui_y)
	if row and pl.inv[row.slot] then
		if game.network_client and not NETWORK_REMOTE_ACTION then
			multiplayer_send_select_action(row.slot, pl.inv[row.slot])
		end
		pl.invselect = row.slot
		inv_show ()
		craft_ini ()
		return true
	end

	row = gui_mouse_row(game.ground_mouse_rows, gui_x, gui_y)
	if row then
		if game.network_client and not NETWORK_REMOTE_ACTION then
			multiplayer_send_pickup_action(row.ground_item)
			return true
		end
		inventory_pick_ground_item(row.index, row.ground_item)
		inv_show ()
		craft_ini ()
		return true
	end

	return false
end

function love.mousepressed (x, y, button, istouch, presses)
	
	if world==nil then return end

	mousetruemoved_last = 0

	if button==1 and inventory_gui_mousepressed(x, y) then
		game.gui_mouse_down = true
		return
	end

	--print (button.." "..presses)
	--4 drop 5 up
	if button==3 then
		love.keypressed ('tab','tab')
	end

	if button==4 then
		love.keypressed ('z','z')
	end

	if button==5 then
		love.keypressed ('q','q')
	end


	if button==1 and game.dbg[2] then
		
		if edit.fin then
			edit = {}
		end

		edit.x = x
		edit.y = y
	end

end



function love.mousemoved (x,y)
	mousemoved = true
	mousemoved_last = 0
	mousetruemoved_last = 0

	if edit.x and not edit.fin and game.dbg[2] then
		edit.w = x - edit.x
		edit.h = y - edit.y
		edit.x2 = x
		edit.y2 = y
		--dump (edit)
	end

end 


function love.mousereleased (x,y,button)
	if button==1 then
		game.gui_mouse_down = nil
		game.gui_throw_down = nil
	end

	if world==nil then return end

	if button==1 and game.dbg[2] then
		edit.fin = 1
		game.pause = true
	end

end



local arrow_movement = {
	up = "w",
	down = "s",
	left = "a",
	right = "d",
}

local network_authoritative_keys = {
	q = true,
	z = true,
	tab = true,
	p = true,
	r = true,
	v = true,
	m = true,
	u = true,
	["return"] = true,
}

function network_client_waits_for_authority(key)
	if network_authoritative_keys[key] then return true end
	local numeric = tonumber(key)
	return numeric ~= nil and (
		is_pressed("lshift") or is_pressed("rshift")
	)
end

function normalize_gameplay_key(key, developer_arrow)
	if arrow_movement[key] and not developer_arrow then
		return arrow_movement[key]
	end
	return key
end

function gameplay_key_from_event(key, scancode)
	-- Q takes the first ground item while Z drops the selected inventory item.
	-- Prefer an actual Latin Q/Z reported by the active layout, but keep the
	-- physical scancode fallback so the shortcuts still work in Cyrillic mode.
	if key == "q" or key == "z" then
		return key
	end
	return scancode or key
end

local function inventory_has_free_numeric_slot()
	for slot=1,pl.invsize do
		if pl.inv[slot]==nil then return true end
	end
	return false
end

function inventory_pick_ground_item(index, expected_item)
	local x, y = pl.xt, pl.yt
	if x==nil or y==nil or not (world[y] and world[y][x]) then
		return false
	end

	local ground = world[y][x].i
	if not ground then return false end

	if expected_item and ground[index]~=expected_item then
		index = nil
		for candidate, ground_item in ipairs(ground) do
			if ground_item==expected_item then
				index = candidate
				break
			end
		end
	end
	if not index or not ground[index] then return false end

	if not inventory_has_free_numeric_slot() then
		textwall (msg.game[44],true)
		return false
	end

	local hasgloves = pl.inv.a and pl.inv.a.i==357
	local de = readmap (x,y,"de") or 0
	if de>cf.deadfire and not hasgloves then
		player_hit (cf.firehit)
		textwall (msg.game[6])
		return false
	end

	local picked = inv_ground_remove (x,y,index)
	if not picked then return false end
	return inv_add (picked,{pick=1})~=nil
end

function inventory_drop_selected_item()
	if type(pl.invselect) ~= "number" or not pl.inv[pl.invselect] then
		return false
	end

	-- The ground panel and the pick-up action use xt/yt.  tx/ty can briefly
	-- point at another tile while movement/camera coordinates are settling.
	local x, y = pl.xt, pl.yt
	if x == nil or y == nil then
		x, y = pl.tx, pl.ty
	end
	if x == nil or y == nil or not (world[y] and world[y][x]) then
		return false
	end

	local maximum = maptile(x, y, "itemcount") or 0
	if maximum == 0 then maximum = cf.itemmax end
	if inv_ground_count(x, y) >= maximum then
		textwall(msg.game[14])
		return false
	end

	local dropped = inv_remove(pl.invselect)
	if not dropped then return false end
	return inv_ground_add(x, y, dropped) ~= nil
end

function inventory_z_action()
	if pl.iscarry or type(pl.invselect) ~= "number" or not pl.inv[pl.invselect] then
		return false
	end

	local selected = pl.inv[pl.invselect]
	local definition = item[selected.i]
	if not definition then return false end

	local put = definition.put
	if put ~= nil then
		if put == 0 then
			textwall(msg.game[37])
			return false
		end

		ithrow = 0
		pl.canthrow = 0
		pl.iscarry = createblock(put)
		pl.iscarry.ittl = selected.t
		inv_remove(pl.invselect)
		return true
	end

	return inventory_drop_selected_item()
end

function reset_failed_prayer_faith()
	-- The original failure message says that faith falls to zero, but routing
	-- that reset through stat_spend makes the missing amount damage the body.
	local accumulated = math.max(0, tonumber(pl.stats.faith.hp) or 0)
	pl.stats.faith.hp = 0
	pl.stats.faith.pc = 0
	return accumulated
end

function development_reload_requested(key, control_down, development)
	return development and control_down and key == "f7"
end

function development_reload_assets()
	-- Reloaded content files contain their canonical English names. Preserve
	-- the language of the current session and apply it again after every file
	-- has been rebuilt, even if the reload also replaced src/msg.lua.
	local active_language = LANGUAGE

	ini_quad ()
	lurker.scan()

	local reload_stones = assert(loadfile('src/stones.lua'))
	reload_stones()

	local reload_animations = assert(loadfile('src/ani.lua'))
	reload_animations()

	if active_language then
		language_set(active_language, false)
	end

	screen_res ()
end

function love.keypressed(key,s)
	if multiplayer_handle_approval_key(key, s) then return end
	if multiplayer_handle_host_key(key, s) then return end

	--print (s)
	if exit then return end

	mousemoved = nil
	mousemoved_last = 0
	
	if pl.isdead then return end
	if game and game.network_client and not NETWORK_REMOTE_ACTION then
		local network_key = gameplay_key_from_event(key, s)
		multiplayer_send_key_action(key, s)
		if network_client_waits_for_authority(network_key) then return end
	end

	key = gameplay_key_from_event(key, s)

	local developer_arrow = IS_DEVELOPMENT and game.dbg and game.dbg[1] and (
		love.keyboard.isScancodeDown("lctrl")
		or love.keyboard.isScancodeDown("rctrl")
	)
	key = normalize_gameplay_key(key, developer_arrow)

	if key == ']' or key == '=' then

		if pl.inv_show[pl.inv_show_c+1] then
			pl.invselect = pl.inv_show[pl.inv_show_c+1]
		end

		inv_show ()
	end


	if key == '[' or key == '-' then
		
		if pl.inv_show[pl.inv_show_c-1] then
			pl.invselect = pl.inv_show[pl.inv_show_c-1]
		end

		inv_show ()
	end



	if game.craft~=true and (key == '`') then
		game.textinput = ""
		game.inputing = not game.inputing

		if not game.inputing then
			textwall ("", true)
		end

		key = "" 
	end
	

	if key == 'escape' and not game.inputing then

		if game.craft then
			game.craft = false
			return
		end

		if game.achishow then
			game.achishow = nil
			return
		end

		esc_menu ()
		return
	end

	if game.inputing then

		if key == 'escape' then
			game.inputing = nil
			game.textinput = ""
			textwall ("",false)
			return
		end

		if key == "return" then
			game.inputing = nil
			textwall ((game.textinputinfo or "")..game.textinput.." ↵",true)

			local f,s = string.match (game.textinput, "([^ ]+) (.*)")

			if f and console[f] and s then
				console[f] (s)
			end

			if f == nil then
				console.f (game.textinput)
			end

			return	

		end

		if key == "backspace" then
			local byteoffset = utf8.offset(game.textinput, -1)
	 
	        if byteoffset then
	            game.textinput = string.sub(game.textinput, 1, byteoffset - 1)
	        end
		end

		textwall ((game.textinputinfo or "")..game.textinput.."_",true)
		return

	end


	if key == "c" and pl.iscarry==nil then

		if game.craft==false then

			craft_reset ()

			if is_pressed('lshift') then
				craft.multitem = true
			end

			craft_itemsget ()
			craft_str ()

			if craft.str~="" then
				game.craft = true
			end

		else
			game.craft = false
		end

	end

	
-- save
	if key == "f6" and IS_DEVELOPMENT then
		textwall (msg.game[3],true)
		game_save (game.savepos)
		game.screenshot = true
		--game.autosave = true

	end

	if key == 'f8' or key == 'n' then

		game.achishow = not game.achishow or nil
		game.achipage = game.achipage or 1

		--achievements 
		--game.achishow == nil and 
		if pl.quests[16] == nil and pl.quest == 0 then 
			quest_cd (1.5)
			quest_start (16) 
		end

	end


	if game.achishow then
		game.achipage = achievement_page_after_key(
			game.achipage,
			key,
			#msg.achitypes
		)

	end

	if key=='m' then
	
		--dump (pl.inv_show_c)
		--dump (pl.invselect)
		--dump (pl.inv_show[start+k])
		--print '-'
		

		pl.state = 'ave'
		inv_ground_sort (pl.xt,pl.yt)

	end

	local control_down = love.keyboard.isScancodeDown("lctrl")
		or love.keyboard.isScancodeDown("rctrl")
	if development_reload_requested(key, control_down, IS_DEVELOPMENT) then
		development_reload_assets()
		return
	end

	-- load
	if key == "f9" and IS_DEVELOPMENT then
		game_load (game.savepos)
		game.pause = nil
		game.escmenu = nil
	end



	if key == '/' then

		-- game.minimap = not game.minimap
		-- print (tostring (game.minimap))
		-- if game.minimaplast ~= game.time then
		-- 	game.minimaplast = game.time
		-- 	draw_minimap ()
		-- end

		game.hidelog = not game.hidelog or nil

	end


	local kp = tonumber (key)

	
	if kp and kp~=0 and not is_pressed('lshift') then

		--local k = pl.inv_show_c - pl.invselect_k + kp

		-- if pl.inv_show[k] then
		-- 	pl.invselect = pl.inv_show[k]
		-- end

		if pl.inv[kp] then
			pl.invselect = kp
		end

		inv_show ()

		craft_ini ()

	end

	if kp and is_pressed('lshift') then
		inv_add(inv_ground_remove (pl.xt, pl.yt,kp))
	end

	if key=="q" then

		if pl.iscarry and stone[pl.iscarry.b].digtoinv and stone[pl.iscarry.b].digtoinv~=0 then
			
			local item = item_make(stone[pl.iscarry.b].digtoinv)
			if pl.iscarry.ittl then
				item.ttl = pl.iscarry.ittl
			end
			pl.iscarry = nil
			pl.candrop = nil
			inv_add (item)
		else
			inventory_pick_ground_item(1)
		end
		
	end

	if key=="tab" then
		local i = inv_ground_remove (pl.xt, pl.yt,1)
		inv_ground_add(pl.xt,pl.yt,i,{groundlast = true})		
	end


	-- drop and put
	if key=='z' and type(pl.invselect)=='number' and pl.inv[pl.invselect] then

		--dump (togo.down)

		if (togo.down or 0)>1 then return end

		inventory_z_action()

		inv_show ()


	end	

	

	if key=="0" then

		if type(pl.invselect)=='number' then 

			cf.eqs.n = pl.invselect --last one

			for i=1,#cf.eq do
				if pl.inv[cf.eq[i]]~=nil then
					pl.invselect = cf.eq[i]
					break
				end
			end

		else

			pl.invselect = cf.eqs[pl.invselect]

			while pl.inv[pl.invselect]==nil and type(pl.invselect)~='number' do
				pl.invselect = cf.eqs[pl.invselect]
			end

		end

	end




	if key=="p" then
		
		if pl.inv[pl.invselect] and item[pl.inv[pl.invselect].i] and item[pl.inv[pl.invselect].i].equip then

			textwall (msg.game[45])

			local n = type(pl.invselect)
			local i = item[pl.inv[pl.invselect].i].equip
			local it = inv_remove (pl.invselect, {noc = 1}) --remove selected
			
			--unequip old
			if pl.inv[i] then
				inv_add (inv_remove(i,{noc = 1}))
			end

			if n=='number' then 

				pl.inv[i] = it 
				--pl.invselect = i

				if item[it.i].onequip then
					item[it.i].onequip ()
				end

			else
				inv_add (it)
			end

		end

		inv_compact ()
	end

	
	
	-- info
	if key=="i" and pl.invselect and pl.inv[pl.invselect] and msg.item[pl.inv[pl.invselect].i].info then
		textwall (msg.game[22], false, {[1] = msg.item[pl.inv[pl.invselect].i].name,
		[2] = msg.item[pl.inv[pl.invselect].i].info})

		sound_add ('wonder', 27)

		if msg.item[pl.inv[pl.invselect].i].tips then

			local str = ""

			if tips['i'..pl.inv[pl.invselect].i]==nil then
				str = msg.dispenser[8].."\n"
			else
				str = msg.dispenser[7].."\n"
			end

			for i,v in ipairs(msg.item[pl.inv[pl.invselect].i].tips) do
				if i>=(tips['i'..pl.inv[pl.invselect].i] or 0) then
					str = str.."{#5a6988ff}— "..locked_txt(v)..msg.game[39].."\n"
				else
					str = str.."{#e4a672ff}— "..v.."\n"
				end
			end

			textwall (str)
		end

		if msg.item[pl.inv[pl.invselect].i].tips==nil or (tips['i'..pl.inv[pl.invselect].i] or 0)>#msg.item[pl.inv[pl.invselect].i].tips then
			if item[pl.inv[pl.invselect].i].transform or item[pl.inv[pl.invselect].i].transformi then
				textwall (msg.dispenser[9],false, {[1] = item[pl.inv[pl.invselect].i].transformpower})
			end
		end

	end


	-- dietary info
	if key=="i" and pl.invselect and pl.inv[pl.invselect] and item[pl.inv[pl.invselect].i].calories then
		
		sound_add ('wonder', 27)
		textwall (diet_info(pl.inv[pl.invselect],1))
	
	end

	


	-- if key=="u" and (is_pressed('lshift') or is_pressed('rshift')) then --consume

	-- 	local str = ""
	-- 	str = msg.gui.diet[2].."\n"
	-- 	for i,v in pairs(cf.diet) do
	-- 		str = str..draw_20cal (pl.diet[v],msg.gui.diet[v]).."\n"
	-- 	end

	-- 	str = str..msg.gui.diet[3]

	-- 	textwall (str, true)
	

	-- end	






	--inspect
	if key=="o" and pl.inspect then

		block_inspect ()

	end

	if key=="r" then --empty
		
		if pl.inv[pl.invselect] and item[pl.inv[pl.invselect].i] and item[pl.inv[pl.invselect].i].onempty then
			
			if item[pl.inv[pl.invselect].i].onempty (pl.xt, pl.yt,pl.invselect) then
				inv_remove (pl.invselect)
			end

		end
	end

	if key=="v" then --drinking
		local w = readmap (pl.xt,pl.yt,'w') or 0
		if w>200 then
			local drunk

			while w and pl.stats.water.hp<pl.stats.water.maxhp and w > 0 do
				w = w - 50
				stat_recovery ("water", cf.watersip)
				stat_recovery ("arms", cf.watersip*0.2)
				drunk = 1
				if w < 0 then w = nil end
				writemap (pl.xt,pl.yt,w,'w')
			end

			if drunk then
				drink_dirt (readmap (pl.xt,pl.yt,'dr'))
			end

		end
	end





	if key=="v" and is_pressed ('space')==false and pl.canuse then
		tile,map = maptile (pl.xt, pl.yt,"all")
		if tile.onuse then
			tile.onuse (pl.xt, pl.yt)
		end
	end

	if key=='v' then
		--dump (pl.canuse)
	end


	-- if key == "return" then
	-- 	game.pause = not game.pause
	-- 	print (game.pause)
	-- end

	--log (item[pl.inv[pl.invselect].i])


	


	-- editor
	r = px2tile (mouse_x,mouse_y)

	if game.dbg[1] then
		if is_pressed("g") then writemap(r.x,r.y,game.blocks[currentBlock]) end
		if is_pressed("h") then writemap(r.x,r.y,0,'clear') end
		if is_pressed("j") then inv_add(item_make(game.items[currentItem])) end
		if is_pressed("k") then inv_remove (pl.invselect) end
	end
	
	
	if key == "up" and IS_DEVELOPMENT then
		currentBlock = currentBlock + 1
		if game.blocks[currentBlock] == nil then currentBlock = 1 end
	end

	if key == "down" and IS_DEVELOPMENT then
		currentBlock = currentBlock - 1
		if currentBlock<1 then currentBlock = #game.blocks end
	end

	if key == "left" and IS_DEVELOPMENT then
		currentItem = currentItem - 1
		if currentItem<1 then currentItem = #game.items end
	end


	if key == "right" and IS_DEVELOPMENT then
		currentItem = currentItem + 1
		if game.items[currentItem] == nil then currentItem = 1 end
	end



	--quests
	if key == "f1" then

		pl.state = 'ave'

		pl.questtexted = true
		--if pl.questnexttexting==nil then
			if pl.quest and msg.quest[pl.quest] then

				local str = msg.dispenser[13]
				for i,v in ipairs(msg.quest[pl.quest]) do
					str = str..msg.dispenser[6]..v.."{#ffffffff}\n"
				end
				textwall (str)
			else
				textwall (msg.dispenser[12])
			end
		--end

		--quest_cd (0)

	end

	
	--diet
	if key == "f2" then

		local str = ""
		str = msg.gui.diet[2].."\n"
		for i,v in pairs(cf.diet) do
			str = str..draw_20cal (pl.diet[v],msg.gui.diet[v]).."\n"
		end

		str = str..msg.gui.diet[3]

		textwall (str, true)

	end


	if key == 'f3' then
		player_hit (3)
		textwall (msg.game[38])
	end


	if key == "f10" and game.dbg[1] then
		game.dbg[2] = not game.dbg[2]
	end

	if key == "f12" and game.dbg[1] then
		game.dbg[4] = not game.dbg[4]
	end



	if key == 'f5' then
		love.graphics.captureScreenshot(game.time..".png")
		textwall (msg.game[41]..love.filesystem.getSaveDirectory())
	end

	if key == 'f4' then
		textwall (msg.keyinfo,true)
		--dump (has_light(pl.tx,pl.ty))
	end

	if key == 'f7' and is_pressed ('rshift') and IS_DEVELOPMENT then

		buff_add (1)
		buff_add (4)
		buff_add (8)

	end


	if key == 'f7' then
		local prayer_chance = math.ceil(pl.stats.faith.hp)

		if love.math.random (0,99) < prayer_chance then

			stat_spend ('faith', 100)
			buff_remove (2)
			buff_add (9)

			if pl.stats.body.hp<=10 then
				stat_recovery ('body', 200)
				return
			end

			if pl.stats.food.pc<=10 then
				stat_recovery ('food', 200)
				buff_add (14) -- well fed
				return
			end


			local dist = math.dist (pl.tx, pl.ty, pl.startx, pl.starty)
			if dist>100 then
				game.fadein = 0.3
				player_pos_reset ()
				return
			end

			--tuber
			local how = function (x,y)
				local w = readmap (x,y,'b') or 0
				if w==189 then
					return true
				end
			end

			local x,y = find_block (pl.xt, pl.yt,how,400)
			if x==nil then
				inv_add (item_make(333))
				return
			end



			--chard
			local how = function (x,y)
				local w = readmap (x,y,'b') or 0
				if w==135 then
					return true
				end
			end

			local x,y = find_block (pl.xt, pl.yt,how,400)
			if x==nil then
				inv_add (item_make(176))
				return
			end


			--cactus
			local how = function (x,y)
				local w = readmap (x,y,'b') or 0
				if w==128 then
					return true
				end
			end

			local x,y = find_block (pl.xt, pl.yt,how,100)
			if x==nil then
				inv_add (item_make(174))
				return
			end

			if love.math.random (0,100)<30 and pl.iscarry == nil then
				pl.iscarry = createblock (49)
			end

			buff_add (25)


		else
			reset_failed_prayer_faith()
			textwall (msg.game[42],false,{[1] = prayer_chance})
		end


	end

	if key == 'f4' and game.dbg[1] then


		--disaster_ini ()


		--dump (k2j)
		--dump (j2k)

		--dump (mobs)
		--dump (pl.quests)
		--dump (pl.quest)
		--dump (pl.killed)



		function disp_time(time)
		  local days = math.floor(time/86400)
		  local hours = math.floor(math.mod(time, 86400)/3600)
		  local minutes = math.floor(math.mod(time,3600)/60)
		  local seconds = math.floor(math.mod(time,60))
		  return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
		end

		print (disp_time(game.dt))





		local t = {}
		for k,v in pairs(mobs) do
			t[v.type] = (t[v.type] or 0) + 1
		end

		--dump (allsounds)

		--dump (t)
		--print (#mobs)

		--dump (hex_color("#f6757aff"))

		--oldprint (

		types = {}
		



	mobs = tablecheck (mobs)
	--mobs = {}

	dump (types)
--


	end









	if game.craft and pl.inv[pl.invselect] then

		if key == "w" then
			craft_up ()
		end

		if key == "s" then
			craft_down ()
		end

		craft_str ()

		if key == "return" then
			craft_do (craft.item_recipies[craft.pointer])
			return
		end

		--return

	end




	if (key=="u" or key=='return') and is_pressed('lshift')==false and is_pressed('rshift')==false then --consume
		
		if pl.inv[pl.invselect] and item[pl.inv[pl.invselect].i] and item[pl.inv[pl.invselect].i].calories then

				sound_add ('eating', 28)

				if item[pl.inv[pl.invselect].i].calories>=35 then
					buff_add (14)
				end

				if pl.stats.filth.pc<35 then
					buff_add (3)
				end

				textwall (diet_info(pl.inv[pl.invselect],4))
				local age, d, r, m, bad = consume_cal(pl.inv[pl.invselect], true)

				if bad==0 then
					buff_add (27, 'add', 1)
				end

				pl.dishes = pl.dishes or {}
				pl.dishes[pl.inv[pl.invselect].i] = (pl.dishes[pl.inv[pl.invselect].i] or 0) + 1


				achi_trigger ('on_eat',pl.inv[pl.invselect].i, item[pl.inv[pl.invselect].i].calories, r)

				stat_recovery ("food",r)



				local onet = item[pl.inv[pl.invselect].i].oneat 

				inv_remove (pl.invselect) 

				if onet then
					onet (pl.xt, pl.yt)
				end

				
				--pl.unrest = pl.unrest + time.min*10


			key=""

		end
	end


	if (key=="u" or key=='return') and is_pressed('lshift')==false and is_pressed('rshift')==false then --use
		
		if pl.inv[pl.invselect] and item[pl.inv[pl.invselect].i] and item[pl.inv[pl.invselect].i].onuse then
			
			if item[pl.inv[pl.invselect].i].onuse (pl.xt, pl.yt, pl.invselect) then
				inv_remove (pl.invselect)
			end

		end
	end



end

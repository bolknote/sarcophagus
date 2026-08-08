function love.load()

	local joysticks = love.joystick.getJoysticks() or {}
	joystick = joysticks[1]
		

	min_dt = 1/30
   	next_time = love.timer.getTime()

	if IS_DEVELOPMENT then
		moving_editor = loadfile('tools/dev/moving_editor.lua')
	end
	
	
	-- Gohu contains fixed bitmap strikes. Asking FreeType for a Retina-sized
	-- strike (for example 28 px for the logical 14 px font) fails on macOS.
	-- Keep the font textures at their authored pixel density and let LÖVE's
	-- high-DPI backbuffer scale them with nearest-neighbour filtering.
	local pixel_font_dpi_scale = 1
	font = love.graphics.newFont("assets/fonts/GohuFont-Medium.ttf",14,"normal",pixel_font_dpi_scale)
	font2 = love.graphics.newFont("assets/fonts/GohuFont-Medium.ttf",11,"normal",pixel_font_dpi_scale)
	font3 = love.graphics.newFont("assets/fonts/PressStart2P.ttf",12,"normal",pixel_font_dpi_scale)
	font:setFilter("nearest","nearest")
	font2:setFilter("nearest","nearest")
	font3:setFilter("nearest","nearest")

	
	
	textlog = love.graphics.newText(font, "")

	log ("",true)

	shader = love.graphics.newShader('assets/shaders/lighting.glsl')
	shader:send("f",1)
	shader:send("am", DEFAULT_AMBIENT_LIGHT)
	shader:send("ci",0)
	shader:send("dying", 0)


	shader2 = love.graphics.newShader('assets/shaders/noise.glsl')

	mouse_x = love.mouse.getX()
	mouse_y = love.mouse.getY()

	-- do_map ()
	-- ani_new (game.start, 'start')
	-- player_reset ()
	stats_reset ()
	screen_res ()

	--game.menu = ""
	
	--load menu
	game_loadinfo ()

	
	love.old_keypressed = love.keypressed
	love.old_update = love.update
	love.old_draw =  love.draw

	love.keypressed = love.menu_keypressed
	love.update = love.menu_update
	love.draw =  love.menu_draw

	love.joy_load ()





	-- sprites
	spt = {}
	spt.room = img_load("room.png")
	spt.smoke = img_load("smoke.png")
	spt.water = img_load("water.png")
	spt.smoke_d = img_load("smoke_d.png")
	spt.inv = img_load("inv.png")
	spt.wasted = {
		en = img_load("wasted.png"),
		ru = img_load("wasted_ru.png"),
	}
	spt.sarco = img_load("sacro.png")
	spt.invg = img_load("inv_g.png")
	spt.bobber = img_load("bobber.png")
	spt.fish = img_load("fish.png")

	spt.back = img_load("back.png")
	spt.back2 = img_load("back2.png")
	


	operatingSystemName = love.system.getOS()
	if (operatingSystemName ~= "iOS" and operatingSystemName ~= "Android") then 
		spt.wcursor = love.mouse.newCursor("assets/cursors/cursor5.png", 1, 1)
		spt.icursor = love.mouse.newCursor("assets/cursors/cursor4.png", 2, 2)
		spt.cursor = love.mouse.newCursor("assets/cursors/cursor3.png", 2, 2)
		spt.dcursor = love.mouse.newCursor("assets/cursors/cursor1.png", 2, 2)
		spt.cursora = {}
		spt.cursora[1] = love.mouse.newCursor("assets/cursors/cursora1.png", 2, 2)
		spt.cursora[2] = love.mouse.newCursor("assets/cursors/cursora2.png", 2, 2)
		spt.cursora[3] = love.mouse.newCursor("assets/cursors/cursora3.png", 2, 2)
		spt.throwcursor = {}
		spt.throwcursor[1] = love.mouse.newCursor("assets/cursors/throw_cursor1.png", 10, 10)
		spt.throwcursor[2] = love.mouse.newCursor("assets/cursors/throw_cursor2.png", 10, 10)
		spt.throwcursor[3] = love.mouse.newCursor("assets/cursors/throw_cursor3.png", 10, 10)
		spt.throwcursor[4] = love.mouse.newCursor("assets/cursors/throw_cursor4.png", 10, 10)
		spt.throwcursor[5] = love.mouse.newCursor("assets/cursors/throw_cursor5.png", 10, 10)

		love.mouse.setCursor( spt.cursor )
	end

	
	--z_canvas = love.graphics.newCanvas()


	--SpriteBatch = love.graphics.newSpriteBatch (quad)
	gr2x = love.graphics.newCanvas()
	block_canvas = love.graphics.newCanvas()
	water_canvas = love.graphics.newCanvas()
	

	minimap_canvas = love.graphics.newCanvas(cf.wmax,cf.wmax)
	text_canvas = love.graphics.newCanvas(vi.textwall_w,vi.textwall_h)


	function stencil_block()
   		
   		love.graphics.setColor (1,1,1,1)

   		for ix=-1,45 do
		for iy=-2,25 do

			x = vi.xtile+ix+1
			y = vi.ytile+iy+1

			if world[y] and world[y][x] then

				local wb = world[y][x]

				if wb.b then
					
					local yadd

					if wb.f then
						yadd = wb.f
					else
						yadd = 0
					end

					--if (not game.dbg[2] and pl.buffs[4]==nil) and wb.n==255 and wb.g and wb.g>0 then

						local x=32*ix-vi.xoffset
						local y=32*iy-vi.yoffset+yadd

						if wb.nn then

							--print (wb.n)

							love.graphics.setLineStyle('rough')
							love.graphics.setLineWidth (1)
							local h = 4

							--if wb.nn[1]==1 then love.graphics.line(x, y, x+32, y) end
							
							-- if wb.nn[1]==1 then love.graphics.line(x, y+h, x, y, x+h, y) end
							-- if wb.nn[2]==1 then love.graphics.line(x+32, y+h, x+32, y, x+32-h, y) end
							-- if wb.nn[3]==1 then love.graphics.line(x+32, y+32-h, x+32, y+32, x+32-h, y+32) end
							-- if wb.nn[4]==1 then love.graphics.line(x, y+32-h, x, y+32, x+h, y+32) end

							x = x - 2
							y = y - 2

							if wb.nn[1]==1 then love.graphics.rectangle("fill", x, y, 2,2) end
							if wb.nn[2]==1 then love.graphics.rectangle("fill", x+34, y, 2,2) end
							if wb.nn[3]==1 then love.graphics.rectangle("fill", x+34, y+34, 2,2) end
							if wb.nn[4]==1 then love.graphics.rectangle("fill", x, y+34, 2,2) end

						end


	--love.graphics.stencil(stencil_block, "replace", 1)
    --love.graphics.setStencilTest("less",1)


						--love.graphics.rectangle()
						--love.graphics.draw (quad, stone[1].spr,32*ix-vi.xoffset,32*iy-vi.yoffset+yadd,0,2,2)

					--end

				end
			end
		end
		end

   		


	end


	oldprint (love.filesystem.getSaveDirectory())
	oldprint ("stones: "..#stone)
	oldprint ("items: "..#item)
	oldprint ("recipies: "..#craft.recipies)

	textwall (msg.game[35])
	

	


	--

	disaster_ini ()

	--mark craftable
	for k,v in pairs(craft.recipies) do
		for ii,vv in pairs(v.items) do
			item[ii].craftable = true
		end
	end





	--calculate calories

	for re=1,2 do

		oldprint "-----------------------"

		for k,v in pairs(craft.recipies) do

			local cal = 0
			local cnt = 0

			for ii,vv in pairs(v.items) do
				cal = cal + (item[ii].calories or item[ii].hcalories or 0)*vv
				cnt = cnt + 1
				cal = cal + 1*vv
			end

			if v.block then
				cal = cal + 10
			end

			--cal = math.floor (cal * 1.1)

			if v.result then

				for res,v1 in pairs(v.result) do

					if item[res]==nil then
						oldprint (res)
					end
					
					if item[res].calories then
						local rescal = item[res].calories*v1

						--if rescal and cnt>1 and cal > rescal then
						if cnt>1 and cal~=0 and (rescal/cal)<1 then
							oldprint (item[res].name.."	"..rescal.."	"..cal)
							item[res].calories = math.floor (cal/v1)

						end

					end
				end
			end

			
		end

	end



r, pl.xt, pl.yt = px2tile (pl.x, pl.y)





	local sublime = ""
	local sitem = ""
	local sblock = ""
	--names from localization
	do	
		local textlog = love.graphics.newText(font, "")	
		for i,v in ipairs(msg.item) do

			textlog:setf (v.name,1000,'left')
			local h = textlog:getHeight()
			local w = textlog:getWidth()/8
			--print (v.name.." "..w.."\n")
			sitem = sitem.. '"'..v.name..'", '
			item[i].name = v.name
			--oldprint (v.name.."\n")
			item[i].w = w

			sublime = sublime..'{ "trigger": "item:'..item[i].name..'", "contents": "'..i..'" },'.."\n"


		end
	end

	sitem = "["..sitem.. '"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",]'


	--names from localization
	do	
		local textlog = love.graphics.newText(font, "")	
		for i,v in ipairs(msg.stone) do
			textlog:setf (v.name,1000,'left')
			local h = textlog:getHeight()
			local w = textlog:getWidth()/8
			sblock = sblock.. '"'..v.name..'", '
			--print (v.name.." "..w.."\n")
			stone[i].name = v.name
			stone[i].w = w

			sublime = sublime..'{ "trigger": "block:'..stone[i].name..'", "contents": "'..i..'" },'.."\n"

		end
	end

	sblock = "["..sblock.. '"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",]'



	sublime = '{"scope": "source.lua", "completions": ['..sublime..']}'

	if IS_DEVELOPMENT then
		love.filesystem.write ('sar.sublime-completions', sublime)
	end


	sublime = 
	'item = '..sitem.."\n"..
	'block = '..sblock.."\n"..
	"import sublime, sublime_plugin, re\n"..
	"class CountWordsInSelectionCommand(sublime_plugin.EventListener):\n"..
	"	def on_selection_modified(self, view):\n"..
	"		msg = view.substr(view.sel()[0])\n"..
	"		try:\n"..
	"			msg = int (msg)\n"..
	"			msg = 'i: ' + item[msg-1]+'<br>b: '+block[msg-1]\n"..
	"			view.show_popup(msg)\n"..
	"		except ValueError as verr:\n"..
	"			pass"

	if IS_DEVELOPMENT then
		love.filesystem.write ('sarco.py', sublime)
	end


	-- local s = ""

	-- for i,v in ipairs(item) do
	
	-- 	if v.desc then
	-- 		s = s.."msg.item["..i.."] = { name = '"..v.name.."',\ndesc = '"..v.desc.."', }\n"
	-- 		else
	-- 		s = s.."msg.item["..i.."] = { name = '"..v.name.."', }\n"
	-- 		end
	

	-- end

	-- oldprint (s)



	-- local s = ""

	-- for i,v in ipairs(stone) do
	
	-- 		s = s.."msg.stone["..i.."] = { name = '"..v.name.."', }\n"
	

	-- end

	-- oldprint (s)

	--inv_add (item_make(101))
	--inv_add (item_make(26))


	--ani_new (cursor,'cursor')
	--cursor.ani_size = 1
	


	--buff_add (8)
	--inv_add (item_make(26))


	game.items = {}
	for k,v in pairs(item) do
		table.insert (game.items,k)
	end

	game.blocks = {}
	for k,v in pairs(stone) do
		table.insert (game.blocks,k)
	end

	-- for k,v in pairs(item) do
	-- 	if v.tool and v.tool.dmgmin then
	-- 		oldprint (v.name.."	"..v.tool.dmgmin.."	"..v.tool.dmgmax.."	"..(v.tool.digspeed or 1))
	-- 	end
	-- end
	



end

function love.menu_keypressed(key,scan)

	
	if startgen then return end

	if scan=='q' then
		love.event.quit()
	end


	if scan=='c' then
		love.joy_ini ()
		love.keypressed = love.joy_keypressed
		love.update = love.joy_update
		love.draw =  love.joy_draw
	end

	if scan == 'h' then
		love.system.openURL("https://acerbial.itch.io/sarcophagus")
	end

	if scan == 'o' then
		love.system.openURL("https://discord.gg/j7c2ytY")
	end

	
	if scan == 'l' then
		legacy = true
		scan = 'return'
	end


	if scan == 'return' then

		sound_add ('button',20,{kill = 1})

		if game.files[game.savepos] ~= "-----------------" then
		
			local o = game.savepos

			if game_load (game.savepos) then

				game.escmenu=nil
				game.savepos = o
				
				game.save = nil
				game.load = nil
				game.pause = nil
				love.keypressed = love.old_keypressed
				love.update = love.old_update
				love.draw =  love.old_draw
				screen_full ()
				game.moved = true
			
			end

		else
			startgen = true
			strprog = ""
			love.mouse.setCursor (spt.wcursor)
			mapthread = love.thread.newThread('mapthread.lua')
			mapthread:start()
			game.mapgenning = true
			love.thread.getChannel( 'geninfo' ):clear()
		end

	end

	if scan == 'w' then

		sound_add ('button',4,{kill = 1})

		game.savepos = game.savepos - 1
		if game.savepos<1 then
			game.savepos = 9
		end
		read_screenshot (game.savepos)
	end

	if scan == 's' then

		sound_add ('button',4,{kill = 1})
		
		game.savepos = game.savepos + 1
		if game.savepos>9 then
			game.savepos = 1
		end
		read_screenshot (game.savepos)
	end

	if scan == 'backspace' and
		(is_pressed('lshift') or is_pressed('rshift')) then

		sound_add ('button',20,{kill = 1})

		game.menu = nil
		love.filesystem.remove(game.savepos..".sav")
		love.filesystem.remove(game.savepos..".png")
	end


end


function read_screenshot (n)

	local info = love.filesystem.getInfo(n..".png")
	if info then
		screenshot = love.graphics.newImage (n..".png")
	else
		screenshot = nil
	end
end


function love.menu_update(d)

	dt = d

	sound_update ()

	if game.menu==nil then

		stradd = ""
		game.savepos = game.savepos or game.metasave.gamepos or 1
		read_screenshot (game.savepos)
		
		game.files = {}

		for i=1,9 do
		local info = love.filesystem.getInfo(i..".sav")
		if info==nil then
			game.files[i] = "-----------------"
		else
			game.files[i] = os.date("%c", info.modtime)
		end
		end
		
		game.menuani = {}
		game.menuani.x = 90
	    game.menuani.y = 110
	    ani_new (game.menuani, 'marsh')



	 --    game.menuani2 = {}
		-- game.menuani2.x = 50
	 --    game.menuani2.y = 50
	 --    ani_new (game.menuani2, 'marsh')
	 --    game.menuani2.ani_size = 4


	 --   	game.menuani3 = {}
		-- game.menuani3.x = 120
	 --    game.menuani3.y = 50
	 --    ani_new (game.menuani3, 'snake')
	 --    game.menuani3.ani_size = 4

	 --    game.menuani4 = {}
		-- game.menuani4.x = 190
	 --    game.menuani4.y = 50
	 --    ani_new (game.menuani4, 'spider')
	 --    game.menuani4.ani_size = 4


	 --    game.menuani6 = {}
		-- game.menuani6.x = 260
	 --    game.menuani6.y = 60
	 --    ani_new (game.menuani6, 'louse')
	 --    game.menuani6.ani_size = 4

	 --    game.menuani8 = {}
		-- game.menuani8.x = 330
	 --    game.menuani8.y = 60
	 --    ani_new (game.menuani8, 'spinner')
	 --    game.menuani8.ani_size = 4

	 --    game.menuani9 = {}
		-- game.menuani9.x = 400
	 --    game.menuani9.y = 60
	 --    ani_new (game.menuani9, 'slime')
	 --    game.menuani9.ani_size = 4


	 --   	game.menuani10 = {}
		-- game.menuani10.x = 470
	 --    game.menuani10.y = 60
	 --    ani_new (game.menuani10, 'robot')
	 --    game.menuani10.ani_size = 4



		
	end

	game.menu = ""
	game.menu = game.menu.."Pick game slot:\n\n"

	game.menuani.y = 173+game.savepos*14

	for i=1,9 do
		
		if game.savepos==i then
			game.menu = game.menu.."{#f77622ff}  "..game.files[i].."\n"
		else
			game.menu = game.menu.."{#ffffffff}  "..game.files[i].."\n"
		end

	end
	
	game.menu = game.menu.."{#ffffffff}\n\n"

	if game.files[ game.savepos] ~= "-----------------" then
		game.menu = game.menu.."Press {#fee761ff}W{#ffffffff},{#fee761ff}S{#ffffffff} to select, {#fee761ff}Enter{#ffffffff} to load a game or {#fee761ff}Backspace+Shift{#ffffffff} to delete."
	else
		game.menu = game.menu.."Press {#fee761ff}W{#ffffffff},{#fee761ff}S{#ffffffff} to select, {#fee761ff}Enter{#ffffffff} to start a new game."

		if game.metasave.inv and #game.metasave.inv>1 then
			game.menu = game.menu.."\nPress {#fee761ff}L{#ffffffff} to start a new game with „{#63c74dff}legacy support{#ffffffff}“."
		end
	end

	game.menu = game.menu.."\nPress {#fee761ff}Q{#ffffffff} to switch worlds."

	game.menu = game.menu.."\n\n{#feae34ff}"

	if stradd~="" then
		game.menu = "{#feae34ff}"..stradd
	end

	if startgen==nil then
	game.menu = game.menu.."\n\n\n\n\n"
	game.menu = game.menu.."{#888888ff}───────────────────────────────────────────\n\n"
	game.menu = game.menu.."{#ffffffff}Press {#fee761ff}H{#ffffffff} to visit homepage.".."\n"
	game.menu = game.menu.."{#ffffffff}Press {#fee761ff}O{#ffffffff} to visit discord channel.".."\n"
	game.menu = game.menu.."{#ffffffff}Press {#fee761ff}C{#ffffffff} to configure keys/joystick.\n(Plug joystick in before running the game).".."\n\n\n"
	game.menu = game.menu.."{#d87644ff}A game by Dmitry Smirnov [spectator.ru]\n"
	--game.menu = game.menu.."{#aaaaaaff}Version "..game_version.." (latest is "..server_version..")\n"
	
	if server_version~=game_version and server_version~="" then
		game.menu = game.menu.."{#aaaaaaff}Version "..game_version.." {#fee761ff}\n\n» "..server_version.." is available! «\n"
	else
		game.menu = game.menu.."{#aaaaaaff}Version "..game_version.."\n"
	end
	
	else
		game.menu = "{#feae34ff}"
	end


	--game.menu = game.menu..dumpvar (game.metasave)


	local info = love.thread.getChannel( 'geninfo' ):pop()

	if info then

		pc = math.ceil (info) - info
		info = math.ceil (info)

		
		if info==1 and strprog~='' then
			strprog = ''
		end

		if pc==0 then
			strprog = strprog..msg.mapgen[info].."\n"
		end
		--strprog = strprog..info.."\n"


	end

	oldinfo = info

	-- starting new game
	if info==11 then

		strprog = ""
		startgen = nil

		pl.starty = tonumber (love.thread.getChannel( 'gendata' ):pop())
		pl.startx = tonumber (love.thread.getChannel( 'gendata' ):pop())

		world = love.thread.getChannel( 'gendata' ):pop()
	
	    game.start = {}
	    game.start.truex = pl.startx * cf.w - 32
	    game.start.truey = pl.starty * cf.h + 32

	    vi.xtile   = pl.startx
	    vi.ytile   = pl.starty

	    pl.startheight1 = pl.starty + 1
	    pl.startheight2 = pl.starty + 12

	    love.keypressed = love.old_keypressed
		love.update = love.old_update
		love.draw =  love.old_draw

		if legacy then

			legacy = nil
			give_legacy (game.metasave.inv)

			if game.metasave.savedscore and game.metasave.savedscore>0 then
				pl.score = (game.metasave.savedscore or 0)*(-1)
			else
				pl.score = (game.metasave.lastscore or 0)*(-1)
			end

			pl.savedscore = math.abs(pl.score)

		else
			pl.score = 0
			pl.savedscore = 0
		end

		ani_new (game.start, 'start')
		achi_ini ()
		player_reset ()
		screen_full ()
		screen_res ()
		inv_show ()

		--love.window.maximize ()

		game.fadeout = 1000
		game.fadein = 0.5
		love.mouse.setCursor (spt.cursor)

		game.menu = nil
		game.mapgenning = nil
		game.moved = true

		--oldprint (dumpvar(game))	
		--dump (game)


	end

end

function love.menu_draw()

	
	if screenshot and startgen==nil then
		love.graphics.draw(screenshot, 700, 0, 0)
--		love.graphics.draw(screenshot, 0, 0, 0)

	end


	love.graphics.setColor (0,0,0,0.9)
	love.graphics.rectangle("fill", 0, 100-14, 700, 350)

	
	love.graphics.setColor (255,255,255,100)
	
	if startgen==nil then
		ani_draw (game.menuani, dt)
		-- ani_draw (game.menuani2, dt)
		-- ani_draw (game.menuani3, dt)
		-- ani_draw (game.menuani4, dt)
		-- ani_draw (game.menuani6, dt)
		-- ani_draw (game.menuani8, dt)

		-- ani_draw (game.menuani9, dt)


		-- ani_draw (game.menuani10, dt)
		-- if is_pressed "rshift" then
		-- 	ani_setstatus (game.menuani2,'die')
		-- 	ani_setstatus (game.menuani3,'die')
		-- 	ani_setstatus (game.menuani4,'die')
		-- 	ani_setstatus (game.menuani6,'die')
		-- 	ani_setstatus (game.menuani9,'die')
		-- 	ani_setstatus (game.menuani8,'spin')
		-- 	ani_setstatus (game.menuani10,'die')
		-- else
		-- 	ani_setstatus (game.menuani2,'walk', true)
		-- 	ani_setstatus (game.menuani3,'walk', true)
		-- 	ani_setstatus (game.menuani4,'walk', true, true)
		-- 	ani_setstatus (game.menuani6,'walk', true)
		-- 	ani_setstatus (game.menuani8,'walk', true)
		-- 	ani_setstatus (game.menuani9,'walk', true)
		-- 	ani_setstatus (game.menuani10,'walk', true)
		-- end


	end

	
	--love.graphics.setFont(font4)
	--love.graphics.printf(text_color("{#181425ff}Sarcophagus\n{#5a6988ff}"), 42+love.math.random (0,2), 32+love.math.random (0,2),700)

	love.graphics.draw (quad, spt.sarco,32,45,0,1,1)
		

	--love.graphics.printf(text_color("{#be4a2fff}Sarcophagus\n{#5a6988ff}"), 40, 30,700)

	love.graphics.setFont(font2)
	love.graphics.printf(text_color("{#3a4466ff}— from the Greek sarx meaning “flesh”, and phagein - “to eat”{#ffffffff}"), 35, 105,700)
	

	love.graphics.setFont(font)
	
	local str = game.menu

	if strprog and str then
		str = str..strprog
		if pc and pc>0 then
			str = str..draw_progress(1-pc).." "..math.floor ((1-pc)*100)
		end
	end

	-- if str then
	-- 	str = str..dumpvar (game.metasave)
	-- 	game.metasave.inv = nil
	-- end


	love.graphics.printf(text_color(str), 100, 150,700)

	



	--love.graphics.printf(dumpvar (sounds), 100, 520,700)


	



end


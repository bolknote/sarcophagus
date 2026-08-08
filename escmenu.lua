
function esc_menu ()

	
	escmenu =
	{
		[1] = {
		f = function ()
			esc_menu ()
		end
		},


		[2] = {
		f = function ()
			game_save (game.savepos)
			game.screenshot = nil	
			esc_menu ()
			exit = 10
		end
		},

		
		[4] = {
		value = 'fullscreen', 
		type = 'bool',
		f = function ()
			screen_full ()
		end
		},
		
		[5] = {
		value = 'gr2x', 
		type = 'bool',
		f = function ()
			screen_full ()
		end
		},

		[7] = {
		value = 'invertstereo', 
		type = 'bool',
		f = function ()
			screen_full ()
		end
		},

		[8] = {
		value = 'mastervolume', 
		type = 'val',
		def = 100,
		f = function (s)

		if s=="a" then
			game.mastervolume = game.mastervolume-5
		end

		if s=="d" then
			game.mastervolume = game.mastervolume+5
		end

		game.mastervolume = math.min (game.mastervolume,100)
		game.mastervolume = math.max (game.mastervolume,0)
		
		screen_full ()

			
		end
		},

		[10] = {
		value = 'nosave', 
		type = 'bool',
		},


		[11] = {
		f = function ()
			love.system.openURL("https://discord.gg/j7c2ytY")
		end
		},

	
	}

	if game.escmenu==nil then

		--sound_killall ()
		game.escmenu = 1
		love.oldkeypressed = love.keypressed
		love.keypressed = esc_menu_keypress
		game.pause = true

	else

		love.keypressed = love.oldkeypressed
		game.escmenu=nil	
		game.pause = nil

	end

end




function esc_menu_draw ()

	if game.escmenu==nil or escmenu==nil then 
		game.escmenu=nil
		return 
	end

	local he = #msg.escmenu+6 --menu height
	local we = 42 --menu weight
	


	local h = 14
	local w = 8
	local gx = (screen.width-w*we)/2
	local gy = (screen.height-h*he)/2


	local str = ""

	for i,v in ipairs(msg.escmenu) do
		
		if game.escmenu==i then
			str = str.."{#f77622ff}» "
		else
			str = str.."{#ffffffff}  "
		end

		if escmenu[i] then

			if escmenu[i].type and escmenu[i].type == 'bool' then
				if game[escmenu[i].value] then
					str = str.."{#ffffffff}[{#63c74dff}■{#ffffffff}] "
				else
					str = str.."{#ffffffff}[ ] "
				end
			else
				if escmenu[i].type==nil then
					str = str.."    "
				end
			end

			if escmenu[i].type and escmenu[i].type == 'val' then
				game[escmenu[i].value] = game[escmenu[i].value] or escmenu[i].def
				str = str.."    ←["..game[escmenu[i].value].."]→ "
			
			end

		end

		str = str..v
		if v == "" then str = str.."{#262b44ff}───────────────────────" end

	
		str = str.."\n"

	end


	local border = 
	"┌[ESC]─"..string.rep("─",we-10).."┐\n"..
	string.rep("│"..string.rep(" ",we-4).."│\n",he-3)..
	"└"..string.rep("─",we-4).."┘\n"


	love.graphics.setColor (0,0,0,0.9)
	love.graphics.rectangle("fill", gx, gy, w*we, h*he)
	love.graphics.setColor (1,1,1,1)
	
	love.graphics.printf(border,gx+w*1,gy+h*0.5,400)

	love.graphics.printf(text_color (str),gx+w*6,gy+h*3,400)


end



function esc_menu_keypress (key,s)
	
	local max = #msg.escmenu

	if s=='escape' then
		esc_menu ()
	end

	if s=='w' then

		sound_add ('button',4,{kill = 1})
		game.escmenu = game.escmenu - 1
		if msg.escmenu[game.escmenu]==nil or msg.escmenu[game.escmenu] == "" then game.escmenu = game.escmenu - 1 end
		if game.escmenu<1 then game.escmenu = max end

	end

	if s=='s' then
		
		sound_add ('button',4,{kill = 1})
		game.escmenu = game.escmenu + 1
		if msg.escmenu[game.escmenu]==nil or msg.escmenu[game.escmenu] == "" then game.escmenu = game.escmenu + 1 end
		if game.escmenu>max then game.escmenu = 1 end
	
	end

	if (s=='d' or s=='a' or s=='return' or s=='space') then

		sound_add ('button',20,{kill = 1})
		
		if escmenu[game.escmenu] then

			if escmenu[game.escmenu].type and escmenu[game.escmenu].type == 'bool' then

				if game[escmenu[game.escmenu].value] then
					game[escmenu[game.escmenu].value] = nil
				else
					game[escmenu[game.escmenu].value] = true
				end
			end

			if escmenu[game.escmenu].f then
				escmenu[game.escmenu].f (s)
			end

		end


	end


end
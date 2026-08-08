function love.joy_keypressed (key,scan,value,what,num)

	if value and type(value)=='number' and math.abs(value)~=1 then
		return
	end

	if scan=='escape' then
		love.joy_load ()
		joy_tomenu ()
	end

	if scan=='backspace' then
		step = step + 1
		return
	end

	what = what or 'key'

	if joy_setup[step]~=nil then


		if k2j[scan] == nil then

			k2j[scan] = {joy_setup[step],what,num,value}
			j2k[joy_setup[step]] = {scan,what,num,value}
			step = step + 1

		end

	end

end




function joy_tomenu ()
	game.joysetup = nil
	love.keypressed = love.menu_keypressed
	love.update = love.menu_update
	love.draw =  love.menu_draw
end





function love.joy_update (d)

	str = ""
	step = step or 1
	str = msg.joystick.title


	for i=1,#joy_setup do
		
		if i<step then
			local k
			if j2k[joy_setup[i]] then
				k = j2k[joy_setup[i]][1]
			else
				k = joy_setup[i]
			end

			str = str..msg.key[joy_setup[i]].." - "..k.."\n"
		end
		
		if i==step then
			str = str..message(msg.joystick.bind, {
				[1] = msg.key[joy_setup[step]],
				[2] = joy_setup[step],
			})
		end

	end

	str = str..msg.joystick.footer


	if step == #joy_setup then
		love.joy_save ()
		joy_tomenu ()
	end

	if j2k then
		--str = str..dumpvar (j2k)
	end

--		str = str.."\n\n{#777777ff}[k] - rarely used, not advised to bind on joystick{#ffffffff}"

end







function love.joy_draw ()

	love.graphics.setFont(font)

	if str then
		love.graphics.printf(text_color(str), 100, 100,700)
	end

end



function love.joy_ini ()

	step = 1
	k2j = {}
	j2k = {}

	joy_setup =
	{
		'w','s','a','d','space',
		'q','z','tab',']','[',
		'e','r','rshift',
		'kp8','kp2','kp4','kp6',
		'lctrl','ralt','lalt',
		'c','v','return','i',
		'f1', 'f2', 'f3', 'f4'
	}

	-- joy_setup =
	-- {
	-- 	'w','s','a','d','space','z','q',
	-- 	'kp8','kp2','kp4','kp6',
	-- }

	game.joysetup=true


end




function love.joy_save ()


	local BlobWriter = require('src.BlobWriter')
	blob = BlobWriter()

	blob:write(k2j)
	:write(j2k)

	local save = blob:tostring()
	save = love.data.compress ('string', 'gzip', save)
	love.filesystem.write ('joy.stick', save)

end





function love.joy_load ()


	local BlobReader = require('src.BlobReader')
	local save = love.filesystem.read('joy.stick')

	if save then
		save = love.data.decompress('string', 'gzip', save)
		local blob = BlobReader(save)

		if blob then
			k2j = blob:read()
			j2k = blob:read()
		end
	else

		j2k = j2k or {}
		k2j = k2j or {}

	end


end



function joy_on_press (key,scan,value,what,num)

	--print ("scan::"..key)

	if k2j[scan] and game.joysetup==nil then
		--dump (k2j[scan])
		love.keypressed (k2j[scan][1],k2j[scan][1],value,what,num)
	else
		love.keypressed (key,scan,value,what,num)
	end

end


local movement_arrow = {
	w = "up",
	s = "down",
	a = "left",
	d = "right",
}

local function developer_arrow_modifier()
	return IS_DEVELOPMENT and game and game.dbg and game.dbg[1] and (
		love.keyboard.isScancodeDown("lctrl")
		or love.keyboard.isScancodeDown("rctrl")
	)
end

--(love.keyboard.isScancodeDown('rctrl')
function is_pressed (str)
	-- Arrow keys are permanent secondary movement controls. In development
	-- builds Ctrl+arrow remains reserved for the old item/block selector.
	local arrow = movement_arrow[str]
	if arrow and not developer_arrow_modifier()
		and love.keyboard.isScancodeDown(arrow) then
		mousemoved_last = 0
		return true
	end

	--pressed default key (not rebind)
	if k2j[str]==nil and love.keyboard.isScancodeDown(str) then
		if str~='r' then mousemoved_last = 0 end
		return true
	end


	local ret = false
	--print ('scan:'..str)
	if j2k[str] then

		--dump (j2k[str])

		--j2k[scan] = {joy_setup[step],what,num,value}
		--1 return value
		--2 what (button,axis)
		--3 num (#axis)
		--4 value


		if joystick then

			if j2k[str][2]=='button' then
				ret = joystick:isDown(j2k[str][3])
			end


			if j2k[str][2]=='axis' then
				local a = joystick:getAxis(j2k[str][3])

				if j2k[str][3]<5 then

					if (j2k[str][4]<0 and a<-0.3) or
						(j2k[str][4]>0 and a>0.3) then
							mousemoved_last = 0
							return true,a
					end

				else
					if a>0 then
						--mousemoved_last = 0
						return true,a
					end
				end 
			end

			if j2k[str][2]=='hat' then
				local a = joystick:getHat(j2k[str][3])
				ret = string.gmatch(a, j2k[str][4])
			end

		end

		if j2k[str][2]=='key' then
			ret = love.keyboard.isScancodeDown(j2k[str][1])
		end

		if ret and str~='r' then mousemoved_last = 0 end
		return ret

	end

	--print (str)
	ret = love.keyboard.isScancodeDown(str)

	if ret and str~='r' then mousemoved_last = 0 end
	return ret
	

end



function love.joystickpressed (joystick, button)
	--print (button)
	joy_on_press ('b'..button,'b'..button,1,'button',button)
end


function love.joystickaxis (joystick, axis, value)
	
	
	--print (axis.." "..value)
	local s = ""

	if value>0 then
		s = 'p'
	elseif value<0 then
		s = 'm'
	else
		return
	end


	if math.abs (value)==1 then
 		if axis>4 then s='' end --4 axis ought to be enough for most people
		joy_on_press ('a'..axis..s, 'a'..axis..s, value,'axis',axis)
 	end

end



function love.joystickhat (joystick, hat, direction)

	if direction=='c' then 
		return
	end

	if string.len (direction)==1 then
		joy_on_press ('h'..hat..direction, 'h'..hat..direction,1,'hat',hat)
	else
		joy_on_press ('h'..hat..string.sub (direction,1,1), 'h'..hat..string.sub (direction,1,1),1,'hat',hat)
		joy_on_press ('h'..hat..string.sub (direction,2,2), 'h'..hat..string.sub (direction,2,2),1,'hat',hat)
	end

end

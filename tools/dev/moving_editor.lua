

	-- speed

	-- collide
	local points = {}
	table.insert (points, {x=pl.x+col.x,y=pl.y+col.y,mode={up = true, down = true,left = true, right = true}}) --левый верхний
	table.insert (points, {x=pl.x+col.x+col.w,y=pl.y+col.y,mode={up = true, down = true,left = true, right = true}}) -- правый верхний

	table.insert (points, {x=pl.x+col.x+col.w,y=pl.y+col.y+col.h/2,mode={up = true, down = true,left = true, right = true}}) -- правый средний
	table.insert (points, {x=pl.x+col.x,y=pl.y+col.y+col.h/2,mode={up = true, down = true,left = true, right = true}}) -- левый средний

	table.insert (points, {x=pl.x+col.x+col.w,y=pl.y+col.y+col.h,mode={up = true, down = true,left = true, right = true}}) --правый нижний
	table.insert (points, {x=pl.x+col.x,y=pl.y+col.y+col.h,mode={up = true, down = true,left = true, right = true}}) -- левый нижний
	
	local togo = tocollide (points)

	pl.state = "jump"
	local step = 1000*dt
	--dumpout = "";
	
	if is_pressed("d") then
		pl.x = pl.x + step
		pl.flip = 1
	end

	if is_pressed("a") then
		pl.x = pl.x - step
		pl.flip = -1
	end

	if is_pressed("w") then
		pl.y = pl.y - step
	end

	if is_pressed("s") then
		pl.y = pl.y + step
	end

	

	

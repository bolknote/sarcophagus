function fishing_start (x,y)

	if fishing==nil then

		if inv_find(6,0) then

			fishing = {}
			fishing = tile2px (x,y) 
			fishing.x = fishing.x + 64*pl.flip
			fishing.delta = 0

			fishing.move = pl.flip
			coord_screen2true (fishing)

			fishing.oldtx = fishing.tx
			fishing.oldty = fishing.ty 

			fishing.cnt = 0
			fishing.wobble = 0
			fishing.bounce = 0
			pl.state = 'fishing'

		else
			textwall (msg.item[289].txt[8])
		end

	else

		if fishing.wobble~=0 then
			inv_add (item_make(290))
			textwall (msg.item[289].txt[7])
			fishing=nil
			return 
		else
			textwall (msg.item[289].txt[6])
			fishing=nil
			return 
		end

	end

end


function fishing_update ()
	if fishing==nil then return end
	coord_true2screen (fishing)

	if fishing.moving then
		fishing.old = fishing.x
		fishing.delta = fishing.delta + fishing.move * dt * 5
	end

	if math.abs (fishing.delta)<1 and fishing.moving then return end

	if fishing.hx then
		pl.restquality=1
		pl.rest = pl.rest + 5 --2 min one block

		--time pass
		fishing.wait = fishing.wait - 1
		--print (fishing.wait)

		if fishing.wait<0 then
			--fishing.wobble = 12
			fishing.wobble = 20

			local f = (readmap (fishing.hx, fishing.hy,'fish') or 0)-1
			if f<1 then f = nil end
			writemap (fishing.hx, fishing.hy, f, 'fish')
			fishing.wait = 100000
		end

		--print (love.math.random (0,1000))
	else
		pl.restquality=1
		pl.rest = pl.rest + 5 --10 min one block

		--no fish found
		if fishing.bounce>2 then
			fishing = nil
			textwall (msg.item[289].txt[9])
			return
		end
	end

	if fishing.delta>0 then
		fishing.x = fishing.x + 1
	else
		fishing.x = fishing.x - 1
	end

	if fishing.wobble>0 then
		fishing.wobble = fishing.wobble - dt * 100 --75
		if fishing.wobble<0 then 
			fishing.wobble = 0 
			fishing.away = true
		end
	end

	if fishing.oldtx ~= fishing.tx or fishing.oldty ~= fishing.ty then

			if fishing.away then
				fishing = nil
				textwall (msg.item[289].txt[5])
				return
			end
			
			fishing.cnt = fishing.cnt + 1

			if fishing.hx==nil then
				textwall (msg.item[289].txt[3]..string.rep(".",fishing.cnt), true)
			else
				textwall (msg.item[289].txt[4]..string.rep(".",fishing.cnt), true)
			end

			for i=0,10 do
				if readmap (fishing.tx,fishing.ty+i,'fish') then

					--print 'hasfish'

					if fishing.hx==nil then
						fishing.hx = fishing.tx
						fishing.hy = fishing.ty+i
						fishing.cnt = 0
						fishing.wait = love.math.random (35,200)
					end

				end
			end

			fishing.oldtx = fishing.tx
			fishing.oldty = fishing.ty 
	end
	

	local w2 = (readmap (fishing.tx, fishing.ty,'w') or 0) 
	local w = w2 + (readmap (fishing.tx, fishing.ty+1,'w') or 0)

	local col = maptile (fishing.tx, fishing.ty-1, 'col') or 0

	--bounce
	if (col == 1 or w2<1000) and fishing.moving then
		fishing.bounce = fishing.bounce + 1
		fishing.x = fishing.old
		fishing.x = fishing.x - math.floor (fishing.delta)*2
		fishing.move = fishing.move*(-1)
		fishing.moving = nil
		coord_screen2true (fishing)
		fishing.delta = 0
		return
	end

	fishing.delta = 0

	if col==1 and w<1000 then --not enougt water
		textwall (msg.item[289].txt[2])
		fishing = nil
		return
	end

	if w2<1000 and col==0 then --fall down
		fishing.y = fishing.y + 8
	end

	if w2>=1000 then
		local r = tile2px (fishing.tx, fishing.ty)
		local a = 32 - ((math.floor ((w2/10000)*32)))
		--if a>31 then a = 0 end
		fishing.y = r.y + a
		fishing.moving = true
		fishing.old = fishing.x
	end


	if fishing.x>pl.x+32 and pl.flip==-1 then
		pl.flip = 1
	end

	if fishing.x<pl.x-32 and pl.flip==1 then
		pl.flip = -1
	end

	--local dist = math.dist (pl.tx, pl.ty, fishing.tx, fishing.ty)
	-- lights['fish'] = lights['fish'] or {}
	-- lights['fish'].x = fishing.x --+ ani[v.type][v.ani_status].xoff
	-- lights['fish'].y = fishing.y 
	-- lights['fish'].p = 20
	-- lights['fish'].l = {0.7, 0.3, 0.3}

	coord_screen2true (fishing)

end


function fishing_draw ()

	if fishing==nil then return end

	if pl.state == 'fishing' then

		local xo,yo

		if currentFrame == 1 then
			xo = 35
			yo = 22
		else
			xo = 35
			yo = 25
		end
	
		
		local dx = (fishing.x - xo - pl.x) / 2
		local dy = (fishing.y - pl.y) * (-0.3)

		love.graphics.setColor (0,0.58,0.91,0.8)
		love.graphics.setLineStyle ('rough')
		love.graphics.setLineWidth (1)
		local curve = love.math.newBezierCurve (pl.x+xo*(pl.flip), pl.y-yo, fishing.x-9-dx, fishing.y-9-dy, 
		fishing.x, fishing.y-9+fishing.wobble)
		love.graphics.line(curve:render())
		
		love.graphics.setColor (0,0.58,0.91,0.2)
		local curve = love.math.newBezierCurve (2+pl.x+xo*(pl.flip), pl.y-yo, fishing.x-9-dx, 2+fishing.y-9-dy, 
		fishing.x, fishing.y-9+fishing.wobble)
		love.graphics.line(curve:render())


		love.graphics.setColor (1,1,1,1)
		love.graphics.draw (quad, spt.bobber,fishing.x-9, fishing.y-9+fishing.wobble,0,2,2)	
	end


	--textwall ("{#ffffffff}"..dx.." "..dy)

end




function find_block (x,y,how,max)

	max = max or 100

	for i=3,max do
		
		local sx = x - math.floor (i/2)
		local sy = y - math.floor (i/2)

		for y=0,i do

			if how (sx+y,sy) then return sx+y,sy end
			if how (sx+y,sy+i) then return sx+y,sy+i  end
			if how (sx,sy+y) then return sx,sy+y end
			if how (sx+i,sy+y) then return sx+i,sy+y end

		end
	end
end


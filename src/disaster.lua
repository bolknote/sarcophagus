-- DISASTERS
--------------------------------------------------




	


function disaster_ini ()
	pl.disaster = {}
	for k,v in pairs(cf.disaster) do
		pl.disaster[k] = {}
		pl.disaster[k].cd = v.ini
		pl.disaster[k].cnt = 0
	end
end

function disaster_do ()

	--dump (pl.disaster)

	for k,v in pairs(cf.disaster) do
		if pl.disaster[k].cd<game.time then

			--random skip
			if love.math.random (0,100)>cf.disaster[k].chance then
				pl.disaster[k].cd = game.time + cf.disaster[k].cd
				return
			end

			if game.dbg[1] then print (k) end

			local done

			if k == 'frost' then

				local w = math.floor (game.time/time.w)%2

				if w==1 then

					done = frost_spawn (math.ceil (math.log (game.time/(time.d*1))))
					if done then
						pl.ferted = {}
					end

				end

			end

			if k == 'farfrost' then
				done = far_frost_spawn (1)
			end

			if k == 'amoeba' then
				done = amoeba_spawn (1)
			end

			if k == 'steal' then
				done = stealer_spawn (love.math.random (5,10))
			end

			if done then
				pl.disaster[k].cd = game.time + cf.disaster[k].cd
			end

		end
	end

	--print 'disaster'
	--frost_spawn (2)
	--pl.ferted = {}
	--stealer ()
end


function get_height (x,y)

	local cnt = 1

	while readmap (x,y-cnt,'b')==0 do
		cnt = cnt + 1
	end

	cnt = cnt - 1
	return cnt, readmap (x,y-cnt-1,'b')

end

function get_bot (x,y)

	local cnt = 1

	while maptile (x,y+cnt,'col')==0 do
		cnt = cnt + 1
	end

	cnt = cnt - 1
	return cnt, readmap (x,y-cnt+1,'b')

end



function stealer_spawn (num)
	
	num = num or 10
	local points = parse_visited (pl.visited)
	local id

	--for i,v in ipairs(points) do
	for i=1,#points do

		--local v = points [love.math.random(1,#points)]
		local v = points[i]

		v[1] = tonumber (v[1])
		v[2] = tonumber (v[2])
		
		if maptile (v[1],v[2])==0 then
			local dist = math.dist (pl.xt, pl.yt, v[1],v[2])
			if dist > 3 and dist < 20 then

				local h,w = get_bot (v[1],v[2],-1)
				v[2] = v[2] + h

				local b = readmap (v[1],v[2],'b')
				local bb = readmap (v[1],v[2]+1,'b')
				local room = readmap (v[1],v[2],'room')

				local growable = {1,8,9,31,32,99,12,13,102}

				if in_array (growable,bb) and (b==0 or b==36) and room==nil then
					writemap (v[1],v[2],174)
					writemap (v[1],v[2],num,'cnt')
					return true
				end
			end
		end
	end
	
	return --id

end

function far_frost_spawn (n)

	local n = n or 5
	local growable = {1,8,9,17,31,32,47,48,99,12,13,102}
	local points = parse_visited (pl.visited)
	local cnt = 1
	local done = nil

	while n>0 do

		cnt = cnt + 1
		local pl = love.math.random (math.ceil (#points/2), #points)

		if points[pl] then
			local x = tonumber (points[pl][1])
			local y = tonumber (points[pl][2])
			local h,w = get_height (x,y)

			if in_array (growable, w) then
				writemap (x,y-h,148)
				n = n - 1
				done = true
			end
			
		end

		if cnt > 50 then break end
	
	end

	return done

end


function amoeba_spawn (n)

	local points = parse_visited (pl.visited)
	local pl = love.math.random (math.ceil (#points/2), #points)

	if points[pl] then

		local x = tonumber (points[pl][1])
		local y = tonumber (points[pl][2])-2
	
		if readmap (x,y,'b')==0 then
			mob_create (x,y,9)
			return true
		end
			
	end

end


function frost_spawn (n)

	local n = n or 5
	local growable = {1,8,9,17,31,32,99} --47, 48
	local points = parse_visited (pl.ferted)
	local cnt = 1
	local done = nil

	while n>0 do

		cnt = cnt + 1
		local pl = love.math.random (1,#points)

		if points[pl] then
			local x = tonumber (points[pl][1])
			local y = tonumber (points[pl][2])
			local h,w = get_height (x,y)

			if in_array (growable, w) then
				writemap (x,y-h,148)
				n = n - 1
				done = true
			end
			
		end

		if cnt > 50 then break end
	
	end

	return done

end



function p_v_s (k1,k2)
	return k1[3] > k2[3]
end

function p_v_r (k1,k2)
	return (love.math.random (0,100)<50)
end

function parse_visited (arr,sort)

	a = {}

	for k,v in pairs(arr) do
		local x = string.match (k,"(%d+)_")
		local y = string.match (k, "_(%d+)")
		table.insert (a, {x,y,v})
	end

	if sort==nil then
		table.sort (a,p_v_s)
	end

	if sort=='rand' then
		table.sort (a,p_v_r)
	end
	


	return a

end

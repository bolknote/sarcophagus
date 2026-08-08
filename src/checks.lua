function ttl_gather ()

	game.ttl_list = {}

	for iy=1,cf.wmax do
	for ix=1,cf.wmax do
			
	local tile,map = maptile (ix,iy,"all")

		if map.i or tile.ttl or map.f then

			game.ttl_list[ix.."-"..iy] = {ix,iy}

		end
   
	end
	end

end


local TTL_CATCH_UP_LIMIT = 128
local TTL_CATCH_UP_BATCH = 512

function ttl_advance_block (x,y,target_time,max_cycles)
	target_time = target_time or game.time
	max_cycles = max_cycles or TTL_CATCH_UP_LIMIT

	local processed = 0
	local ok, result = pcall(function ()
		while processed < max_cycles do
			local tile,map = maptile (x,y,"all")
			local started = map.t
			local lifetime = tile.ttl

			if type(started)~="number" or type(lifetime)~="number"
				or lifetime<=0 or target_time<=started+lifetime then
				break
			end

			-- Run every missed transition at the time it should have happened.
			-- writemap and ondie callbacks can create more TTL blocks, so using the
			-- historical time also gives those blocks the correct starting time.
			game.time = started + lifetime
			writemap (x,y,tile.die)
			if tile.ondie then
				tile.ondie (x,y)
			end
			game.time = target_time
			processed = processed + 1
		end

		return processed
	end)

	game.time = target_time
	if not ok then
		error(result,0)
	end

	return result
end


function ttl_checks (arr,mode)
	local c = 0
	local catch_up_budget = TTL_CATCH_UP_BATCH

	for k,v in pairs(arr) do
		local advanced = checks(v[1],v[2],{
			update = true,
			ttl_max_cycles = math.min(TTL_CATCH_UP_LIMIT,catch_up_budget),
		}) or 0
		catch_up_budget = catch_up_budget - advanced
		c = c + 1
		
		local tile,map = maptile (v[1],v[2],"all")

		if arr[v[1].."-"..v[2]] then

			arr[v[1].."-"..v[2]][3] = arr[v[1].."-"..v[2]][3] or 5
			arr[v[1].."-"..v[2]][3] = arr[v[1].."-"..v[2]][3] - 1

			if mode and mode.cnt and arr[v[1].."-"..v[2]][3]<0 then
				arr[v[1].."-"..v[2]]=nil
				return
			end

			if map.i == nil and tile.ttl == nil and map.f == nil and
			arr[v[1].."-"..v[2]][3]<0 then
				arr[v[1].."-"..v[2]]=nil
			end



		end

		if catch_up_budget<=0 then
			break
		end

	end
	if mode and mode.ver then print ('checked '..c) end
end


function checks(x,y,mode)


	mode = mode or {}
	local ttl_processed = 0
	local tile,map = maptile (x,y,"all")

	--pumpkin fix
	if map.b == nil then
		writemap (x,y,0)
	end

	if tile and map then

		--dump (tile)
		if mode.real and tile.sound then
			sound_add (x.."_"..y,tile.sound,{x=x,y=y,z=0})	
		end

			if mode.real and game.moved then
			local n,nn = neibors(x,y)
			writemap (x,y,n,'n')
			writemap (x,y,nn,'nn')
		end

		--lights
		if tile.light and mode.real and map.n~=255 then
			local r = tile2px (x,y)
			lights[x.."_"..y] = lights[x.."_"..y] or {}
			lights[x.."_"..y].x = r.x+16
			lights[x.."_"..y].y = r.y+16
			lights[x.."_"..y].p = tile.light[1]
			lights[x.."_"..y].l = {tile.light[2],tile.light[3],tile.light[4]}
		end

		
		--fix firing
		if map.tneed and map.b==0 then
			writemap (x,y,nil,'tneed')
		end

		-- fire (cd)
		if game.dt > game.firecheck then

			if mode.real and map.tp then

				-- heat_spread (x,y,love.math.random(-1,1),love.math.random(-1,1))
				--print (x..' '..y..' '..map.tp)

				if tile.onheat then
					tile.onheat (x,y,tile,map)
				end
				
				heat_spread (x,y,0,-1)
				heat_spread (x,y,1,0)
				heat_spread (x,y,-1,0)
				heat_spread (x,y,0,1)

			end

			if map.tp and map.de and map.tp == 0 and map.de == 0 then
				writemap (x,y,nil,'de')
				writemap (x,y,nil,'tp')
			end

			game.fchecked = true

		end	


		-- if map.scent then
		-- 	map.scent = map.scent - 1
		-- 	if map.scent < 0 then map.scent = nil end
		-- 	writemap (x,y,map.w,map.scent,'scent')
		-- end

		--water check
		local str = 'w'

		watercd = (watercd or 0) + dt

		if map.w then -- flow down


			if map.fish and map.w<6000 then
				map.fish = nil
			end

			--print (watercd)
			watercd = 0

			--print (map.w)
			
			-- solid block'd
			if tile.col == 1 then

				local l = maptile (x-1,y)
				local r = maptile (x+1,y)
				local w = maptile (x,y-1)

				if l==0 then
					local w = readmap (x-1,y,str) or 0
					map.w = math.floor (map.w / 2)
					w = w + map.w
					writemap (x,y,map.w,str)
					writemap (x-1,y,w,str)
					map.dr = dirt_eq (x-1,y, map.dr,2,'dr')
				end

				if r==0 then
					local w = readmap (x+1,y,str) or 0
					map.w = math.floor (map.w / 2)
					w = w + map.w
					writemap (x,y,map.w,str)
					writemap (x+1,y,w,str)
					map.dr = dirt_eq (x+1,y, map.dr,2,'dr')
				end

				if l~=0 and r~=0 and w==0 then
					local w = readmap (x,y-1,str) or 0
					map.w = math.floor (map.w / 2)
					w = w + map.w
					writemap (x,y,map.w,str)
					writemap (x,y-1,w,str)
					map.dr = dirt_eq (x,y-1, map.dr,2,'dr')
				end

			else

				--up overflow
				if map.w>10000 then
					map.w = map.w - 1000
					local u = readmap (x,y-1,str) or 0
					writemap (x,y-1,u+1000,str)
					writemap (x,y-1,map.dr,'dr')
					writemap (x,y,map.w,str)
				end


				--flow down
				if maptile (x,y+1) == 0 then	
					local l = water_add(x,y+1,map.w)
					if map.w ~= l then
						writemap (x,y,l,str)
						map.w = l

						if map.dr then map.dr = dirt_eq (x,y+1, map.dr,2,'dr') end
					
					end
				else
					-- absorb down
					local a = maptile (x,y+1,'absorb') or 0
					if a>0 then
						local wt = readmap (x,y+1,'wt') or 0
						if wt<a then
							a = a - wt
							if a>map.w then a = map.w end
							map.w = map.w - a


							--watering count
							local vs = x.."_"..y
							pl.ferted[vs] = pl.ferted[vs] or 0
							pl.ferted[vs] = pl.ferted[vs] + a


							a = a + wt
							writemap (x,y+1,a,'wt')
						end
					end
				end

				--function water_eq (x,y,water,o,str)

				if map.w>0 then --flow left and right

					local l = maptile (x-1,y)
					local r = maptile (x+1,y)
					
					if l==0 then
						if map.dr then map.dr = dirt_eq (x-1,y, map.dr,1,'dr') end
						map.w = water_eq (x-1,y, map.w,1)
						writemap (x,y,map.w,str)
					end

					if r==0 then
						if map.dr then map.dr = dirt_eq (x+1,y, map.dr,-1,'dr') end
						map.w = water_eq (x+1,y, map.w,-1)
						writemap (x,y,map.w,str)
					end

				end

			end

			if map.w < 1 then writemap (x,y,nil,str) end

		end

		-- fast checks
		if map.i then

			--lights ground inventory
			if mode.real and (tile.col==0 or tile.col==nil) and map.n~=255 then
				for i,v in ipairs(map.i) do
				if item[v.i].light then
					local r = tile2px (x,y)
					lights[x.."_"..y] = lights[x.."_"..y] or {}
					lights[x.."_"..y].x = r.x+16
					lights[x.."_"..y].y = r.y+16
					if lights[x.."_"..y].p then
						lights[x.."_"..y].p = lights[x.."_"..y].p + math.floor(item[v.i].light[1]/4)
					else
						lights[x.."_"..y].p = item[v.i].light[1]
					end	
					lights[x.."_"..y].l = {item[v.i].light[2],item[v.i].light[3],item[v.i].light[4]}		
				end
				end
			end

			-- inventory falling down
			if maptile (x,y+1,'col') == 0 and maptile (x,y,'col')==0 then
				for i,v in ipairs(map.i) do inv_ground_add (x,y+1, inv_ground_remove (x,y,i)) end
			end

		end

		-- stone checks
		if tile.check then
			tile.check (x,y)
		end


		-- tile is falling down	
		if tile.fall and readmap (x+tile.fall[1],y+tile.fall[2],'b')==0 and map.f==nil then

				if tile.falldie then
					writemap (x,y,0)
				else
					writemap (x,y,0,'f')
					map.f = 0
				end
		end


		if map.f then

			game.ph_list[x.."-"..y] = {x,y,32}
			game.ph_list[x.."-"..(y-1)] = {x,y-1,32}
			game.ph_list[x.."-"..(y+1)] = {x,y+1,32}

			--print (x..'-'..y)

			local bottomcol = maptile (x,y+1,'solid')

			if map.f and bottomcol==0 then
				map.f = map.f + cf.blockfallspeed
			end

			--checking next block
			if map.f==0 and bottomcol==1 then
				map.f = readmap(x,y+1,"f")
				writemap (x,y,map.f,"f")
				
				if not map.f then
					sound_add ('drop', 26, {x = x, y = y})
				end
				
				if not map.f and tile.onfell then
					tile.onfell (x,y)
				end

			end


			if map.f and map.f >= cf.h then

				local customfall = nil

				writemap (x,y,nil,'f')
				

				if customfall==nil then

					if bottomcol==0 then

						local de = stone[readmap (x,y+1,'b')]							
						local de2
						local de3
						
						if de and de.ondestroy then
							
							sound_add ('drop', 26, {x = x, y = y})

							de2, de3 = de.ondestroy (x,y+1,map.b)

							if de2 then
								writemap (x,y+1,de2)
							else
								writemap (x,y+1,0)
							end

							writemap (x,y+1,nil,'f')
							
							if de3 then
								writemap (x,y,de3)
							else
								writemap (x,y,0)
							end

							writemap (x,y,nil,'f')
						else

							local m = tablecopy(map)
							m.f = 0
							m.i = readmap (x,y+1,'i')
							m.w = readmap (x,y+1,'w')
							m.dr = readmap (x,y+1,'dr')
							writemap (x,y+1,m,'all')
							writemap (x,y,0,'clear') --clear
							writemap (x,y,nil,'f')
						end
					

					if tile.onfalling then
						customfall = tile.onfalling (x,y+1)
					end

					end

				end
			end

		end

		
		-- slow checks
		if game.dt > game.ttlcheck or mode.update then

		--	if x==417 then print (y) end

			if map.w==nil and map.dr then
				--local dr = readmap (x,y+1,'dr') or 0
				--writemap (x,y+1,map.dr + dr,'dr')
				map.dr = map.dr - 10
				if map.dr<0 then
					writemap (x,y,nil,'dr')
				end
			end

			
			if map.mobs then
				mob_restore (x,y)
			end


			if game.moved or mode.update then

				-- dirt
				if map.w and map.dr then
					for i=-1,1 do
						for ii=-1,1 do
							if i==0 and ii==0 then else
								local w = readmap (x+i,y+ii,'w')
								if w then
									local dr = readmap (x+i,y+ii,'dr') or 0
									if math.abs (map.dr - dr)>2 then
										map.dr = (map.dr + dr) / 2
										if map.dr>100 then
											map.dr = 100
										end
										writemap (x+i,y+ii,map.dr,'dr')
									end
								end
							end
						end
					end	
				end

				--ttl block check
				if map.t and tile.ttl then
					ttl_processed = ttl_advance_block (
						x,
						y,
						game.time,
						mode.ttl_max_cycles
					)
					tile,map = maptile (x,y,"all")
				end

				--fertility
				if map.b == 102 and map.e==nil and map.f==nil then
					writemap (x,y,100,'e')
				end

				if map.wt and map.b==0 then
					writemap (x,y,nil,'wt')
				end

				if map.e then	
						--print (map.e)						
						if map.b==1 or map.b==2 or map.b==12 or map.b==13 or map.b==102 then
							
							if map.e<100 then writemap (x,y,102) end --loam
							if map.e>100 and map.e<200 then writemap (x,y,12) end -- soil
							if map.e>200 then writemap (x,y,13) end -- rich soil
							
							if map.e<0 then 
								writemap (x,y,1)
								writemap (x,y,nil,'e') 
							end -- soid to dirt
						else
							if map.b~=48 then
								local ue = map.e
								local fd = readmap (x,y+1,'e')
								local bd = readmap (x,y+1,'b')

								if fd==nil then
									if bd==1 or bd==2 or bd==12 or bd==13 or bd==102 then
										writemap (x,y,nil,'e')
										writemap (x,y+1,ue,'e')
									end
								end
							end

						end
				end
				

				--ttl map inv check
				if map.i then

					local bury

					for k,v in pairs(map.i) do

						if map.b == 0 then
							bury = nil
						else
							if item[v.i]['bury'] then
								bury = item[v.i]['bury'][map.b]
							else
								bury = nil
							end
						end

						-- bury in water
						if bury==nil and map.w and item[v.i]['bury'] then
							bury = item[v.i]['bury'].w
							if item[v.i].onwater then
								item[v.i].onwater (x,y,map,k)
							end
						end

						-- heated
						if map.de and item[v.i].onheat then
							item[v.i].onheat (x,y,map,k)
						end


						local d = game.time - v.c
						
						-- laying in the ground
						if bury == nil then

							local autobury = item[v.i]['autobury']==1 and item[v.i]['bury'][readmap (x,y+1,"b")]
							
							if autobury then
								v.t = math.floor (v.t - d * item[v.i].ttg)
							else
								v.t = math.floor (v.t - d * item[v.i].ttg * room_storetime (map.room))
							end

							v.c = game.time
							-- autobury
							if v.t<0 and autobury then
									inv_ground_add (x,y+1,inv_ground_remove (x,y,k))
							else

								if v.t<0 then

									--print ('die '..game.time)
									local old = tabledeepcopy (v)

									local lay = item[v.i].ongrounddie 
									inv_ground_remove (x,y,k)
									inv_ground_add (x,y,item_make (item[v.i].laydie))

									if lay then
										lay (x,y,old)
										break
									end

									
								end

							end


						-- buried
						else
						
						v.t = math.floor (v.t - d * item[v.i].ttb * bury)
						v.c = game.time

						if v.t<0 then
							
							local onburydie

							if item[v.i].onburydie then
								onburydie = item[v.i].onburydie (x,y)
							end

	--							local r = inv_ground_remove (x,y,k)

							if onburydie then
								inv_ground_replace (x,y,k,item_make (onburydie))
							else
								inv_ground_replace (x,y,k,item_make (item[v.i].burydie))
							end
							----

	--							inv_ground_add (x,y,item_make (item[v.i].burydie))

						end


					end
				end
			end

		end




		game.checked = true;
			
	end
	end

	return ttl_processed
end

-- collisions
	colliders = {}
	cols = {}
	cols.player = {-7,-30,15,55}
	cols.player_strike = {10,-30,27,55}
	cols.player_pick = {5,-23,32,45}

	cols.proj = {-4,-4,8,8}
	cols.proj_web = {-6,-8,14,14}

	cols.slime = {-13,-13,28,15}
	cols.slime_90 = {0,-13,18,27} --left
	cols.slime_270 = {-15,-13,17,27} --right
	cols.slime_180 = {-15,0,28,17} 

	cols.chicken = {-13,-13,28,15}
	cols.chicken_90 = {0,-13,18,27} --left
	cols.chicken_270 = {-15,-13,17,27} --right
	cols.chicken_180 = {-15,0,28,17} 

	cols.spider = {-13,-13,26,26}
	cols.spider_die = {-9,-9,19,19}	

	cols.worm = {-5,-13,15,15}
	cols.invader = {2,5,25,18}

	
	cols.frostie = {-15,-13,28,15}
	cols.frostie_90 = {-0,-13,15,25}
	cols.frostie_270 = {-15,-13,18,25}
	cols.frostie_180 = {-12,0,28,15}
	
	cols.marsh = {-9,-10,17,17}

	cols.snake = {-15,-13,28,15}
	cols.snake_90 = {-0,-13,13,25}
	cols.snake_270 = {-10,-13,18,25} --right
	cols.snake_180 = {-15,0,28,15}


	cols.robot = {-15,-13,28,15}
	cols.robot_90 = {0,-13,18,27} --left
	cols.robot_270 = {-15,-13,17,27} --right
	cols.robot_180 = {-15,0,28,17} 
	
	cols.ameba = {-7,-5,15,10}
	cols.bigameba = {-12,-12,25,25}

	cols.skull = {-15,-13,28,15}

	cols.stealer = {-15,-13,28,15}
	cols.stealer_90 = {0,-13,18,27} --left
	cols.stealer_270 = {-15,-13,17,27} --right
	cols.stealer_180 = {-15,0,28,17} 


	cols.butler = {-15,-13,28,15}
	cols.butler_90 = {0,-13,18,27} --left
	cols.butler_270 = {-15,-13,17,27} --right
	cols.butler_180 = {-15,0,28,17} 

	cols.spinner = {-10,-20,20,20}
	cols.spinner_180 = {-10,0,20,20} 
	cols.spinner_90 = {0,-10,18,20} --left
	cols.spinner_270 = {-15,-10,17,20} --right



	cols.louse = {-15,-13,28,15}
	cols.louse_90 = {0,-13,18,27} --left
	cols.louse_270 = {-15,-13,17,27} --right
	cols.louse_180 = {-15,0,28,17} 

	cols.anvil = {0,0,32,32}

	cols.boom = {-32,-32,96,96}
	
	function projectile_item_damage(inv)
		if type(inv) ~= "table" then return 1 end

		local definition = item[inv.i]
		if type(definition) ~= "table" then return 1 end
		if type(definition.dmg) == "number" then return definition.dmg end

		local instance_tool = type(inv.tool) == "table" and inv.tool or {}
		local definition_tool = type(definition.tool) == "table" and definition.tool or {}
		local minimum = tonumber(instance_tool.dmgmin) or tonumber(definition_tool.dmgmin)
		local maximum = tonumber(instance_tool.dmgmax) or tonumber(definition_tool.dmgmax)
		if minimum == nil and maximum == nil then return 1 end

		minimum = minimum or maximum
		maximum = maximum or minimum
		if minimum > maximum then minimum, maximum = maximum, minimum end
		return love.math.random(minimum, maximum)
	end


	projes =
	{

		[1] = {
				spt = img_load("throw_inv.png"),
				onhit = function (x,y,what,m,i)
				end,
		},

		[2] = {
				spt = img_load("throw_igle.png"),
				onhit = function (x,y,what,m,i,v)
					
					if what=='critter' then
						mob_hit (m.n,10)
					end
					
					if what=='player' then
						player_hit (10)
					end
					
				end,
				dest = 1,
				coll = {'player','critter'},
				collname = 'proj',
				spin = 'none',
				--light = {12,1,1,0.9},
				pass = 'playerpass'
		},

		[3] = {
				spt = img_load("throw_stone.png"),
				--mob_hit (m)
				onhit = function (x,y,what,m,i)
					local d = projectile_item_damage(i)

					if m.n then
						mob_hit (m.n, d)
					end
				end,
				coll = {'mob'},
				collname = 'proj',
		},

		[4] = {
				spt = img_load("throw_invader.png"),
				onhit = function (x,y,what,m,i)
					player_hit (10)
				end,
				dest = 1,
				coll = {'player'},
				pass = 'playerpass',
				collname = 'proj',
				light = {32,1,1,0.9},
				spin = 'none',
		},


		[5] = { --knife
				spt = img_load("throw_knife.png"),
				--mob_hit (m)
				onhit = function (x,y,what,m,i,proj)
					local d = projectile_item_damage(i)

					if m.n then
						mob_hit (m.n, d)
					end
				end,
				coll = {'mob'},
				collname = 'proj',
		},

		[6] = { --axe
				spt = img_load("throw_axe.png"),
				--mob_hit (m)
				onhit = function (x,y,what,m,i,proj)
					local d = projectile_item_damage(i)

					if m.n then
						mob_hit (m.n, d)
					end
				end,
				coll = {'mob'},
				collname = 'proj',
				spin = 'round'
		},


		[7] = { --hammer
				spt = img_load("throw_hammer.png"),
				onhit = function (x,y,what,m,i,proj)
					local d = projectile_item_damage(i)

					if m.n then
						mob_hit (m.n, d)
					end
				end,
				coll = {'mob'},
				collname = 'proj',
				spin = 'round'
		},

		[8] = { --spear
				spt = img_load("throw_spear.png"),
				onhit = function (x,y,what,m,i,proj)
					local d = projectile_item_damage(i)

					if m.n then
						mob_hit (m.n, d)
					end
				end,
				coll = {'mob'},
				collname = 'proj',
		},

		[9] = {
				spt = img_load("throw_ice.png"),
				onhit = function (x,y,what,m,i)
					player_hit (2)
					buff_add (5,'add')
					stat_spend ('heat',5)
				end,
				dest = 1,
				coll = {'player'},
				pass = 'playerpass',
				collname = 'proj',
				light = {20,0.5,0.5,0.8}
		},

		[10] = {
				spt = img_load("throw_spinner.png"),
				onhit = function (x,y,what,m,i)
					player_hit (2)
				end,
				dest = 1,
				coll = {'player'},
				pass = 'playerpass',
				collname = 'proj',
				light = {10,0.5,0.5,0.8},
				spin = 'round'
		},

		[11] = { --spear
				spt = img_load("throw_stinger.png"),
				onhit = function (x,y,what,m,i,proj)
					local d = projectile_item_damage(i)

					if m.n then
						mob_hit (m.n, d)
					end
				end,
				coll = {'mob'},
				collname = 'proj',
		},


		[12] = {
				spt = img_load("throw_web.png"),
				onhit = function (x,y,what,m,i)
					mob_buff (mobs[m.n], 1)
				end,
				coll = {'mob'},
				collname = 'proj_web',
				spin = 'y',
				yspeed_dim = 200
		},

		[13] = {
				spt = img_load("throw_web.png"),
				onhit = function (x,y,what,m,i)
					buff_add (13,'keep')
				end,
				dest = 1,
				coll = {'player'},
				pass = 'playerpass',
				collname = 'proj_web',
				spin = 'x',
		},

		[14] = { --grenade
				spt = img_load("throw_inv.png"),
				--mob_hit (m)
				onhit = function (x,y,what,m,i,proj)
					local r = tile2px (x,y)
					item[328].onland (x,y)
					proj = nil
				end,
				coll = {'mob'},
				collname = 'proj',
				spin = 'round',
				dest = 1
		},

		[15] = {
				spt = img_load("throw_test.png"),
				dest = 1,
				coll = {},
				collname = 'proj',
				spin = 'none',
				--light = {12,1,1,0.9},
				pass = 'playerpass',
				size = 1,
				onland = function ()
					testthrow = 0
				end,
				silent = 1,
				--light = {10,0.5,0.5,0.8}
		},


		[16] = { --grenade
				spt = img_load("throw_inv.png"),
				--mob_hit (m)
				onhit = function (x,y,what,m,i,proj)
					local r = tile2px (x,y)
					item[343].onland (x,y)
					proj = nil
				end,
				coll = {'mob'},
				collname = 'proj',
				spin = 'round',
				dest = 1
		},


		[17] = { --rotten egg
				spt = img_load("throw_igle.png"),
				onhit = function (x,y,what,m,i,v)
					
					mob_buff (mobs[m.n], 2, 32*20)
					
				end,
				dest = 1,
				coll = {'mob'},
				collname = 'proj',
				spin = 'round',
				--light = {12,1,1,0.9},
				pass = 'playerpass'
		},


	}



function proj_update ()
-- projectiles update

if proj then
	for k,v in pairs(proj) do
		
		local light = v.light or projes[v.proj].light
		if v.inv then light = item[v.inv.i].light end

		if light then
			lights['p'..k] = {}
			lights['p'..k].x = v.x
			lights['p'..k].y = v.y
			lights['p'..k].p = light[1]
			lights['p'..k].l = {light[2],light[3],light[4]}		
		end

		v.bounce = v.bounce or {1,1,0,1}


		v.d = v.d or 0
		v.f = v.f or 1

		if projes[v.proj].spin==nil then
			local ya = (math.atan2 (v.xspeed,v.yspeed))
			v.d = ya * (-1)
		end

		if projes[v.proj].spin=='y' then
			v.d = 180*math.cos((v.y)/2000)
			v.d = v.d * (-1) 

			if v.xspeed<0 then 
				v.f = -1
			end
		end


		if projes[v.proj].spin=='x' then
			v.d = 180*math.cos((v.y)/3000)
			v.d = v.d * (-1) 

			if v.xspeed<0 then 
				v.f = -1
			end
		end

		if projes[v.proj].spin=='round' then
			v.d = 180*math.cos((v.x+v.y)/2000)
			v.d = v.d * (-1) 

			if v.xspeed<0 then 
				v.f = -1
			end
		end





		if coord_true2screen (v) == false then
			coord_screen2true (v)
		end

		if v.xo == nil then
			v.xo = v.x
			v.yo = v.y
		end

		if v.xspeed > 0 then
			v.x = v.x + math.min (12, v.xspeed * dt)
		else
			v.x = v.x + math.max (-12, v.xspeed * dt)
		end
		
		--v.xspeed = v.xspeed - v.xspeed*0.012 
		v.xspeed = v.xspeed - v.xspeed*0.006 

		game.pass = projes[v.proj].pass

		local togo = tocollide ({[1] = {x=v.x,y=v.y,mode={}}})
		local hit = false
		local bounce = nil

		if togo.x and togo.x > 0 then
			if v.bounce[4]==1 then
				v.xspeed = v.xspeed  * (-0.5)
				v.x = v.x + togo.x*2
				bounce = true
			else
				v.xo = v.x
				v.yo = v.y
				v.x = v.x + togo.x*2
				hit = true
			end
		end

		if togo.x and togo.x < 0 then
			if v.bounce[2]==1 then
				v.xspeed = v.xspeed  * (-0.5)
				v.x = v.x + togo.x*2
				bounce = true
			else
				v.xo = v.x
				v.yo = v.y
				v.x = v.x + togo.x*2
				hit = true
			end
		end
		
		if v.yspeed > 0 then
			v.y = v.y + math.min (12, v.yspeed * dt)
		else
			v.y = v.y + math.max (-12, v.yspeed * dt)
		end

		local togo = tocollide ({[1] = {x=v.x,y=v.y,mode={up = true, down = true, left = true, right = true}}})

		if togo.y and togo.y>0 then
			if v.bounce[1]==1 then
				v.y = v.y + togo.y * 2
				v.yspeed = v.yspeed  * (-0.5)
				bounce = true
			else
				v.xo = v.x
				v.yo = v.y
				v.y = v.y + togo.y * 2
				hit = true
			end
		end

		if togo.y and togo.y<0 then
			if v.bounce[3]==1 then
				v.y = v.y + togo.y * 2
				v.yspeed = v.yspeed  * (-0.5)
				v.xspeed = v.xspeed * 0.5
				bounce = true
			else
				v.xo = v.x
				v.yo = v.y
				v.y = v.y + togo.y * 2
				hit = true
			end
		end

		if not togo.y then
			v.yspeed = v.yspeed + (projes[v.proj].yspeed_dim or v.yspeed_dim or 400) * dt
		end
		
		if bounce then
			local s = math.abs (v.yspeed)+ math.abs (v.xspeed)
			s = s / 200
			if projes[v.proj].silent==nil then
				sound_add (v.tx.."-"..v.ty.."bounce", 17, {x=v.tx,y=v.ty, volume = s})
			end
		end

		if hit then
			local s = math.abs (v.yspeed)+ math.abs (v.xspeed)
			s = s / 200
			if projes[v.proj].silent==nil then
				sound_add (v.tx.."-"..v.ty.."hit", 18, {x=v.tx,y=v.ty, volume = s})
			end
		end

		if math.abs(v.yspeed) < 4 and math.abs(v.xspeed) < 4 then
			v.xo = v.x
			v.yo = v.y
			hit = true
		end

		if hit then
			v.xspeed = 0
			v.yspeed = 0
			
			-- local r = px2tile (v.x,v.y)
			-- writemap (r.x,r.y,1)


			if v.inv then 
				local d = true
				if item[v.inv.i].onland then
					d = item[v.inv.i].onland (v.x,v.y,v.xo,v.yo,v.inv)
				end

				if d then				
					if v.inv and item[v.inv.i].tool then
						v.inv.t = v.inv.t - (item[v.inv.i].tool.hithit or 1)
					end

					inv_ground_add (v.txo,v.tyo,v.inv) 
	
				end

			end
			
			if projes[v.proj].onland then
				projes[v.proj].onland (v.x,v.y,v.xo,v.yo,v.inv)
			end

			proj[k] = nil
		end

		coord_screen2true (v)

		--collide with ground
		local coll = projes[v.proj].coll
		if coll then

			local p = col_add ('',v,'',projes[v.proj].collname,'proj')

			--local p = col_add ('proj_'..k,v,'',projes[v.proj].collname,'proj')
			--remove


			for ii,vv in ipairs(coll) do

				local m = collide_check (p,vv)

				if m and proj[k] then

					if proj[k].hit == nil then
					
						proj[k].hit = true

						local hit = 1

						if v.inv and v.inv.tool and v.inv.tool.hithit then
							hit = v.inv.tool.hithit
						end

						if v.inv and v.inv.t then v.inv.t = v.inv.t - hit end

						if projes[v.proj].onhit then
							projes[v.proj].onhit (v.x, v.y, vv, m, v.inv, v)
						end

						if v.inv and item[v.inv.i].onhit then
							item[v.inv.i].onhit (v.x, v.y, vv, m, v.inv, v)
						end

						if projes[v.proj].dest then
							proj[k] = nil
						end

					end

				end

			end
		
		end


		
		if proj[k] and maptile(v.tx,v.ty)==0 then
			v.txo = v.tx
			v.tyo = v.ty
		end




		-- up in if
		
		
		
	end
end

end

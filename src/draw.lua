function death_title_sprite(sprites, language)
	return sprites[language] or sprites.en
end

function death_title_layout(sprite, screen_width, screen_height, language)
	local _, _, sprite_width, sprite_height = sprite:getViewport()
	local sprite_x = math.floor((screen_width - sprite_width) / 2)
	local sprite_y = math.floor(screen_height / 2 - 100)
	-- Both title sprites are 78 px high, but the English artwork has four
	-- transparent rows below its visible shadow that the Russian artwork uses.
	-- Compensate so the score begins at the same visual distance from the
	-- lettering instead of overlapping the Russian shadow.
	local score_offset = sprite_height - 6
	if language == "ru" then
		score_offset = score_offset + 4
	end

	return sprite_x, sprite_y, sprite_x + 12, sprite_y + score_offset
end

function water_render_colors(dirtiness)
	local pollution = math.max(0, math.min(1, (tonumber(dirtiness) or 0) * 0.005))

	-- Water used to be an opaque tinted rectangle. In a dark cave that hid the
	-- background almost completely, so even a pool looked like a rendering bug.
	-- Keep the clean-to-dirty hue shift, but let the cave texture show through
	-- and give the exposed surface a readable pixel highlight.
	return
		0.30 + pollution * 0.45,
		0.50 + pollution * 0.50,
		1.00 - pollution * 0.70,
		0.28 + pollution * 0.06,
		0.55 + pollution * 0.25,
		0.78 + pollution * 0.20,
		1.00 - pollution * 0.25,
		0.72
end

local function visible_player_actors()
	local result = {}
	if actors and actors.host then result[#result + 1] = actors.host end
	if actors and actors.guest and actors.guest ~= actors.host then
		result[#result + 1] = actors.guest
	end
	if #result == 0 and pl then result[1] = pl end
	return result
end

local function actor_draw_options()
	return {
		camera = vi,
		local_actor = actors and actors.local_actor or pl,
		tile_width = cf.w,
		tile_height = cf.h,
		definitions = gr,
		atlas = quad,
		blocks = stone,
		ghost_shader = ghost_shader,
	}
end

local function draw_player_layer(behind_world)
	local options = actor_draw_options()
	for _, actor in ipairs(visible_player_actors()) do
		local definition = gr[actor.state] or gr.idle
		local actor_behind = definition.z
			or (actor == pl and haswater)
			or (actor ~= pl and actor.buffs and actor.buffs[18])
		if not not actor_behind == not not behind_world then
			ActorRenderer.draw_body(actor, options)
		end
	end
end

local function draw_multiplayer_status()
	if not multiplayer or multiplayer.role == "offline" then return end
	local text
	local status = multiplayer:status()
	if multiplayer.role == "host" and multiplayer.session
		and multiplayer.session.guest then
		text = msg.network.host_status
	elseif multiplayer.role == "client" then
		if multiplayer.client_state == "playing" then
			text = msg.network.client_status
		else
			local state = msg.network.states[multiplayer.client_state]
				or multiplayer.client_state
			local reason = multiplayer.last_error
				and (msg.network.errors[tostring(multiplayer.last_error)]
					or tostring(multiplayer.last_error))
			text = state .. (reason and ("\n" .. reason) or "")
				.. "\n" .. msg.network.exit_hint
		end
	end
	if text and status.transport and (
		(multiplayer.role == "client" and multiplayer.client_state == "playing")
		or (multiplayer.role == "host" and multiplayer.session
			and multiplayer.session.guest)
	) then
		local rtt = tonumber(status.transport.rtt_ms)
		local loss = tonumber(status.transport.packet_loss_percent)
		if rtt or loss then
			local quality_label = msg.network.quality_labels[status.quality]
				or msg.network.quality_labels.unknown
			text = text .. "\n" .. message(msg.network.quality, {
				[1] = math.floor((rtt or 0) + 0.5),
				[2] = string.format("%.1f", math.max(0, loss or 0)),
				[3] = quality_label,
			})
		else
			text = text .. "\n" .. msg.network.quality_unknown
		end
	end
	if not text then return end
	text = MultiplayerProtocol.sanitize_utf8(text)
	local width = math.min(520, screen.width - 40)
	local x = (screen.width - width) / 2
	local _, line_count = text:gsub("\n", "\n")
	local height = 24 + (line_count + 1) * 14
	love.graphics.setColor(0.04, 0.06, 0.10, 0.88)
	love.graphics.rectangle("fill", x, 18, width, height)
	love.graphics.setColor(0.82, 0.90, 1, 1)
	love.graphics.printf(text, x + 10, 25, width - 20, "center")
	love.graphics.setColor(1, 1, 1, 1)
end

function draw_smooth2x_world(source)
	if not smooth2x_available() or not source then
		return false
	end

	local previous_shader = love.graphics.getShader()
	local previous_blend_mode, previous_alpha_mode = love.graphics.getBlendMode()
	local red, green, blue, alpha = love.graphics.getColor()
	local source_width, source_height = source:getDimensions()

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setBlendMode("alpha", "premultiplied")
	smooth2x_shader:send("source_size", {source_width, source_height})
	smooth2x_shader:send("sharpness", 0.30)
	love.graphics.setShader(smooth2x_shader)
	love.graphics.draw(source, 0, 0, 0, 2, 2)

	love.graphics.setShader(previous_shader)
	love.graphics.setBlendMode(previous_blend_mode, previous_alpha_mode)
	love.graphics.setColor(red, green, blue, alpha)
	return true
end

local function send_world_lights(scale)
	local count = 0
	local total_power = 0
	scale = scale or 1

	for _, light in pairs(lights) do
		if light.x
			and light.x > 0 and light.y > 0
			and light.x < screen.width and light.y < screen.height then
			count = count + 1
			local name = "lights[" .. count .. "]"
			shader:send(name .. ".position", {
				light.x * scale,
				light.y * scale,
			})
			shader:send(name .. ".diffuse", light.l)
			shader:send(name .. ".power", light.p * scale)
			total_power = total_power + light.p
		end
	end

	shader:send("num_lights", count + 1)
	return total_power
end

function love.draw()
	


	ba10_2 = ((math.floor((game.dt or 0)*10))%2)+1
	ba10_3 = ((math.floor((game.dt or 0)*10))%3)+1

	ba1_2 = ((math.floor((game.dt or 0)*0.8))%2)+1
	
	
	love.graphics.setCanvas(water_canvas)
	love.graphics.clear ()

	love.graphics.setCanvas(block_canvas)
	love.graphics.clear ()

	
	if game.gr2x then
		love.graphics.setCanvas({gr2x, stencil=true})
		love.graphics.clear ()
	else
		love.graphics.setCanvas()
	end


 
	--transform = love.math.newTransform(0, 0, 0, 1, 1, 0, 0, 0.1, 0.1)
	--love.graphics.applyTransform(transform)
    

	game_cursor = spt.cursor
	local deferred_lighting = enhanced_2x_enabled()
	local deferred_cooking_indicators = {}
	
	shader:send("ci",1)
	local p = send_world_lights(1)

	--print (n)

	-- A new character has no light-emitting items yet. Keep the authored
	-- low ambient level instead of reducing it to zero, otherwise the first
	-- playable screen is effectively black. Explicit ambient effects (for
	-- example dark vision) still take precedence.
	shader:send("am", game.ambient ~= nil and game.ambient or DEFAULT_AMBIENT_LIGHT)
	--print (p*0.00006)
	
	--local factor = math.abs(math.cos(game.dt))
	local factor = math.abs(math.cos(love.math.random (0,1)))
	shader:send("t", factor)

	--print (factor)
	shader2:send("t", math.floor(game.dt*8)%17)
--	shader2:send("t2", factor)

	
	if deferred_lighting then
		love.graphics.setShader()
	else
		love.graphics.setShader(shader)
	end

--love.graphics.setShader(shader2)
--local factor = math.floor (love.math.random (1,4))
--shader2:send("t", factor)





local x = 0
local y = 1

love.graphics.setColor (0.10,0.10,0.10,1)


local a = (math.sin (game.dt*1))*3*(vi.cammoving or 0)
local b = (math.sin (game.dt*1))*3*(vi.cammoving or 0)


--background
for ix=-1,screen.x/2 do
for iy=-1,screen.y/2 do

		local bx = vi.xtile % 4
		local by = vi.ytile % 4
		--love.graphics.draw (quad, spt.back,256*ix-vi.xoffset/2-bx*16,256*iy-vi.yoffset/2-by*16,0,2,2)
		--love.graphics.draw (quad, spt.back,128*ix-vi.xoffset/2-bx*16,128*iy-vi.yoffset/2-by*16,0,2,2)
		love.graphics.draw (quad, spt.back2, a+64*ix-vi.xoffset/2-bx*16, b+64*iy-vi.yoffset/2-by*16,0,1,1)
	
end
end

p = math.min (p,600)
p = p / 4000
--love.graphics.setColor (0.15,0.15,0.15,1)
love.graphics.setColor (p,p,p,1)


--background
for ix=-1,screen.x/2 do
for iy=-1,screen.y/2 do

		local bx = vi.xtile % 8
		local by = vi.ytile % 8
		--love.graphics.draw (quad, spt.back,256*ix-vi.xoffset/2-bx*16,256*iy-vi.yoffset/2-by*16,0,2,2)
		--love.graphics.draw (quad, spt.back,128*ix-vi.xoffset/2-bx*16,128*iy-vi.yoffset/2-by*16,0,2,2)
		love.graphics.draw (quad, spt.back,64*ix-vi.xoffset/2-bx*16,64*iy-vi.yoffset/2-by*16,0,1,1)
	
end
end


shader:send("ci",0)


	love.graphics.stencil(stencil_block, "replace", 1)
    love.graphics.setStencilTest("less",1)


love.graphics.setColor (0,0,0,1)

-- first layer
for iy=-2,screen.y do
for ix=-1,screen.x do

		x = vi.xtile+ix+1
		y = vi.ytile+iy+1

		if world[y] and world[y][x] then

			local wb = world[y][x]

			if wb.b and wb.b~=0 then

				local yadd

				if wb.f then
					yadd = wb.f
				else
					yadd = 0
				end

				if stone[wb.b].br then

					love.graphics.rectangle("fill",32*ix-vi.xoffset-2,32*iy-vi.yoffset+yadd-2, 36, 36)

				end
						
			end

		end
end
end


love.graphics.setStencilTest()

love.graphics.setColor (1,1,1,1)


if game.start.ani_status ~= 'walk' and game.fadeout==nil and game.fadein==nil then
	coord_true2screen (game.start)
	ani_draw (game.start, dt)
end

--if altshow or game.altitem or love.mouse.isDown(3) then
	game.alttexts = {}
--end
				


	for i,mob in pairs(mobs) do

		if mob.x and mob.z==nil and multiplayer_entity_visible(mob) then
			ani_draw (mob, dt)
		end

	end

	--local haswater = readmap (pl.xt,pl.yt,'w')

	if gr[pl.state].z or haswater then
		if game.start.ani_status == 'born' and game.start.ani_frame<12 then

		else
			draw_player_layer(true)
		end
	else
		-- Remote actors can be in a depth-layer animation even when the local
		-- actor is not, so the layer must still be visited.
		draw_player_layer(true)
	end


	--love.graphics.stencil(stencil_block, "replace", 1)
    --love.graphics.setStencilTest("less",1)





	-- first layer
	for iy=-2,screen.y do
	for ix=-1,screen.x do

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

					if (not game.dbg[2] and pl.buffs[4]==nil) and wb.n==255 and wb.g and wb.g>0 then

						local c = wb.g or 0
						c = 1 - c * 0.09
				
						love.graphics.setColor (c,c,c,1)
						love.graphics.draw (quad, stone[1].spr,32*ix-vi.xoffset,32*iy-vi.yoffset+yadd,0,2,2)
						
						love.graphics.setColor (1,1,1,1)
						
					
					else
						


						local invo

						if wb.i and wb.n~=255 then

							if altshow or game.altitem or love.mouse.isDown(3) then
								local a = alt_add (32*ix-vi.xoffset, 32*iy-vi.yoffset, wb.i, x)
								if a then table.insert (game.alttexts,a) end
							else

							end

							--game.altitem==nil

							if altshow ~= true then

								if mouse_t and x==mouse_t.x and y==mouse_t.y then

									local gi = game.altitem
									game.altitem=nil

									local a = alt_add (32*ix-vi.xoffset, 32*iy-vi.yoffset, wb.i, y)
									if a then table.insert (game.alttexts,a) end

									game.altitem=gi


								end

							end

							local op = #wb.i*0.05+0.5
							love.graphics.setColor (1,1,1,op)

							if wb.b==0 then
								love.graphics.draw (quad, spt.inv,32*ix-vi.xoffset,32*iy-vi.yoffset,0,2,2)
								--alttext (32*ix-vi.xoffset,32*iy-vi.yoffset)
								
							else
								--stone[wb.b]==nil or 

								if stone[wb.b] and stone[wb.b].noinv==nil and (stone[wb.b].col==nil or stone[wb.b].col==0) then
									love.graphics.draw (quad, spt.inv,32*ix-vi.xoffset,32*iy-vi.yoffset,0,2,2)
								else
									if stone[wb.b].noinv==nil then
										invo = true
									end
								end
							end

							love.graphics.setColor (1,1,1,1)

						end


						if wb.problem and wb.problem~=5 and is_pressed('lalt') then
							love.graphics.setColor (1,1,1,0.3+math.abs(math.sin(game.dt*7)))
						end

						if type (wb.b)~='number' then
							--oldprint (dumpvar (wb.b))
						end

						local draw_in_depth_layer = wb.b>0
							and stone[wb.b].zindex
							and wb.de==nil
						if draw_in_depth_layer then
							-- This layer is composited back into the world below with the
							-- lighting shader active. Applying the shader while building the
							-- layer as well would darken z-indexed objects twice in pixel mode.
							love.graphics.setShader()
							love.graphics.setCanvas({block_canvas})
						end

						if wb.b>0 then
							if stone[wb.b].ondraw then
								stone[wb.b].ondraw (32*ix-vi.xoffset,32*iy-vi.yoffset+yadd,x,y)
							else
								love.graphics.draw (quad, stone[wb.b].spr,32*ix-vi.xoffset,32*iy-vi.yoffset+yadd,0,2,2)
							end
						end


						if draw_in_depth_layer then
							if game.gr2x then
								love.graphics.setCanvas({gr2x, stencil=true})
							else
								love.graphics.setCanvas()
							end
							if deferred_lighting then
								love.graphics.setShader()
							else
								love.graphics.setShader(shader)
							end
						end

						love.graphics.setColor (1,1,1,1)

						if invo then
							love.graphics.draw (quad, spt.invg,32*ix-vi.xoffset+8,32*iy-vi.yoffset+9,0,1,1)
						end

						if wb.wt and wb.wt>0 then
							local op = wb.wt/300
							love.graphics.setColor (1,1,1,op)
							love.graphics.draw (quad, spt.water,32*ix-vi.xoffset+10,32*iy-vi.yoffset+8,0,1,1)
							love.graphics.setColor (1,1,1,1)
						end

						
						--game.showroom = 100
						if wb.room and game.showroom then
							game.showroom = game.showroom - dt*50
							--love.graphics.setColor (1,1,1,1)
							local de = world[y][x].room*100
							love.graphics.setColor (0.96, 0.45, 0.48, game.showroom*0.02)
							love.graphics.draw (quad, spt.room,32*ix-vi.xoffset,32*iy-vi.yoffset,0,1,1)
							love.graphics.setColor (1,1,1,1)
							if game.showroom<0 then game.showroom=nil end
						end


						-- temperature
						if wb.de and wb.de>0 then

							local de = world[y][x].de
							local de = math.log (de/2+1)

							de = de / 10

							writemap (x,y,de,'log')

							-- print (de.." "..dl)
							--de = de / 120

							
							--if de>0.5 then de = 0.5 end
							love.graphics.setColor (1,0.5-de/2,0,de)
							
							--love.graphics.setColor (1,1,1,de)
							--and wb.b==0
							if wb.de>cf.deadfire then
								love.graphics.draw (quad, spt.smoke_d,32*ix-vi.xoffset,32*iy-vi.yoffset,0,1,1)
							else
								love.graphics.draw (quad, spt.smoke,32*ix-vi.xoffset,32*iy-vi.yoffset,0,1,1)
							end

							love.graphics.setColor (1,1,1,1)

						end

						-- Keep the progress indicator stable between discrete heat ticks.
						if wb.tneed then
							if deferred_lighting then
								deferred_cooking_indicators[#deferred_cooking_indicators + 1] = {
									x = x,
									y = y,
									tneed = wb.tneed,
									done = wb.done,
								}
							else
								draw_cooking (x,y, wb.tneed, wb.done)
							end
						end

					end

					--love.graphics.print((ix+1).."-"..(iy+1), 32*ix, 32*iy)

				end

				--water
				if (wb.w and wb.n~=255) or draw_water then

						--love.graphics.setStencilTest()
						love.graphics.setCanvas(water_canvas)
						love.graphics.setShader(shader2)

						local dirtiness = wb.dr or draw_water_dr or 0
						draw_water_dr = wb.dr
						local fill_r, fill_g, fill_b, fill_a,
							surface_r, surface_g, surface_b, surface_a =
							water_render_colors(dirtiness)

						love.graphics.setColor(fill_r, fill_g, fill_b, fill_a)

						local h = 16

						local w = 14-math.floor ((wb.w or draw_water)/10000*16)
						if w>16 then w = 16 end
						if w<0 then w = 0 end
						
						if draw_water == nil and maptile (x-1,y,'col')==1 then
							love.graphics.setColor(fill_r, fill_g, fill_b, math.min(1, fill_a + 0.15))
							love.graphics.rectangle("fill",h*ix-math.ceil(vi.xoffset/2)-h/2,h*iy-math.ceil(vi.yoffset/2)+w, h/2, h-w)
							love.graphics.setColor(fill_r, fill_g, fill_b, fill_a)
						end

						--if pl.xt == x-1 then

						if draw_water ~= nil and wb.w==nil and maptile (x,y,'col')==1 then
							love.graphics.setColor(fill_r, fill_g, fill_b, math.min(1, fill_a + 0.15))
							love.graphics.rectangle("fill",h*ix-math.ceil(vi.xoffset/2),h*iy-math.ceil(vi.yoffset/2)+w, h/2, h-w)
							love.graphics.setColor(fill_r, fill_g, fill_b, fill_a)
						end

						--end
						
						if wb.w~=nil and (maptile (x,y+1,'col')==1 or (readmap (x,y+1,'w') or 0) > 9900) then
							draw_water = wb.w
							love.graphics.rectangle("fill",h*ix-math.ceil(vi.xoffset/2),h*iy-math.ceil(vi.yoffset/2)+w, h, h-w)
						end

						if wb.w and wb.w > 0 and (readmap(x,y-1,'w') or 0) < 100 then
							love.graphics.setColor(surface_r, surface_g, surface_b, surface_a)
							love.graphics.rectangle(
								"fill",
								h*ix-math.ceil(vi.xoffset/2),
								h*iy-math.ceil(vi.yoffset/2)+w,
								h,
								1
							)
						end

						--love.graphics.draw (quad, spt.fish,h*ix-math.ceil(vi.xoffset/2),h*iy-math.ceil(vi.yoffset/2)+w,0,0.5,0.5)


						love.graphics.setColor (255,255,255,100)
						if deferred_lighting then
							love.graphics.setShader()
						else
							love.graphics.setShader(shader)
						end

						if game.gr2x then
							love.graphics.setCanvas({gr2x, stencil=true})
						else
							love.graphics.setCanvas()
						end
						
						--love.graphics.setStencilTest("less",1)

				end

				if wb.fish then
				 	love.graphics.setColor (1,1,1,0.75)
				 	love.graphics.draw (quad, spt.fish,32*ix-vi.xoffset,32*iy-vi.yoffset,0,1,1)
				 	love.graphics.setColor (1,1,1,1)
				end

				if wb.w == nil then
						--love.graphics.setStencilTest("less",1)
						draw_water = nil
						draw_water_dr = nil
				end

				
			end
		

		
		end
	end

	--love.graphics.setStencilTest()
	love.graphics.setColor (255,255,255,100)

	love.graphics.draw (block_canvas, 0,0,0,1,1)


	local carried_options = actor_draw_options()
	for _, actor in ipairs(visible_player_actors()) do
		ActorRenderer.draw_carried(actor, carried_options)
	end

	if pl.digcount > 0 then
		draw_dig_progress (pl.digxt, pl.digyt,pl.digdone)
	end
	

	love.graphics.setColor (1,1,1,1)


	fishing_draw ()




	if gr[pl.state].z==nil and haswater==nil then
		if game.start.ani_status == 'born' and game.start.ani_frame<12 then

		else
			draw_player_layer(false)
		end
	else
		draw_player_layer(false)
	end


	love.graphics.setColor ( 0.17, 0.9, 0.96, 1)

	love.graphics.setLineWidth (2)
	for k,v in pairs(lines) do
		love.graphics.line (v)
	end
	love.graphics.setLineWidth (1)
	

	love.graphics.setColor (1,1,1,1)

	for i,mob in pairs(mobs) do

		if mob.x and mob.z==1 and multiplayer_entity_visible(mob) then
			ani_draw (mob, dt)
		end

	end



	--world ani
	for k,v in pairs(worldani) do
		if multiplayer_entity_visible(v) then
			coord_true2screen (v)
			ani_draw (v, dt)
		end
	end
	

	-- projectiles
	if proj then
		for k,v in pairs(proj) do
			if v.f and multiplayer_entity_visible(v) then
					love.graphics.draw (quad, projes[v.proj].spt, v.x, v.y, v.d, v.f*(projes[v.proj].size or 2), (projes[v.proj].size or 2), 3, 3)
				end
		end
	end


	love.graphics.draw (water_canvas, 1,1, 0, 2,2)
	


	love.graphics.setBlendMode("alpha")
	love.graphics.setShader()
	love.graphics.setColor (255,255,255,100)

	if deferred_lighting then
		-- Reconstruct and sharpen the unlit world first. Applying the authored
		-- stepped light mask before this pass turns its dithered boundary into a
		-- comb, so lighting is composited only after the image is final-sized.
		love.graphics.setCanvas(smooth2x_canvas)
		love.graphics.clear(0, 0, 0, 0)
		draw_smooth2x_world(gr2x)

		love.graphics.setCanvas()
		send_world_lights(2)
		shader:send("t", factor * 2)
		shader:send("ci", 0)
		local blend_mode, alpha_mode = love.graphics.getBlendMode()
		love.graphics.setBlendMode("alpha", "premultiplied")
		love.graphics.setShader(shader)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(smooth2x_canvas, 0, 0)
		love.graphics.setShader()
		love.graphics.setBlendMode(blend_mode, alpha_mode)

		for _, indicator in ipairs(deferred_cooking_indicators) do
			draw_cooking_smooth2x(
				indicator.x,
				indicator.y,
				indicator.tneed,
				indicator.done
			)
		end

		-- Reuse the source canvas as a transparent overlay layer. This preserves
		-- the old clipping and coordinate rules for world labels while keeping
		-- them out of both the lighting and sharpening passes.
		love.graphics.setCanvas({gr2x, stencil=true})
		love.graphics.clear(0, 0, 0, 0)
	end


for k,v in pairs(sct) do
--x,y,ttl,text
		if v.font==nil then
			love.graphics.setFont(font3)
		end

		if v.font then
			love.graphics.setFont(font)
		end

		if v.font==2 then
			love.graphics.setFont(font2)
		end

		love.graphics.setColor (0,0,0,1)
		love.graphics.printf(v.text, math.floor(v.x+1), math.floor(v.y+1), 700)
		love.graphics.printf(v.text, math.floor(v.x+1), math.floor(v.y+2), 700)
		
		
		love.graphics.setColor (1,1,1,v.ttl*3)
		love.graphics.printf(v.text, math.floor(v.x), math.floor(v.y), 700)
		
end

	love.graphics.setFont(font)
	
	local r = px2tile (mouse_x,mouse_y)

	tile,map = maptile (r.x,r.y,"all")

	if map and map.de and map.de>1 then
		local d = tile2px (r.x,r.y)
		love.graphics.setFont(font2)
		love.graphics.setColor (0,0,0,1)
		love.graphics.printf(math.floor(map.de).."°", d.x+5, d.y+5, 700)
		love.graphics.setColor (0.9,0.9,0.9,1)
		love.graphics.printf(math.floor(map.de).."°", d.x+4, d.y+4, 700)
		love.graphics.setColor (1,1,1,1)
		love.graphics.setFont(font)
	end

	--dumpout2 = dumpvar (lights)
	--dumpout2 = table.tostring (lights)
	--dumpout2 = neibors (r.x,r.y)
	--dumpout2 = game.xcheck.."-"..game.ycheck
	--dumpout2 = dumpvar (telltime(game.time))
	--dumpout2 = dumpvar (bubble)
	dumpout2 = ""

	

	if game.dbg[2] then
		local r2 = tile2px (r.x,r.y)
		love.graphics.rectangle("line", r2.x, r2.y, 32, 32)
	end


	if pl.cob then
		local r2 = tile2px (pl.cob[1],pl.cob[2])

		love.graphics.setLineWidth (1)
		
		love.graphics.setColor (1,1,1,0.5)
		love.graphics.draw (quad, stone[pl.iscarry.b].spr, r2.x, r2.y, 0, 2, 2, 0, 0)
		
		local l = math.cos (game.dt*10)
		love.graphics.setColor (l,l,l,0.7)
		love.graphics.rectangle("line", r2.x, r2.y, 32, 32)

		
		local l = math.sin (game.dt*10)
		love.graphics.setColor (l,l,l,0.7)
		love.graphics.rectangle("line", r2.x+1, r2.y+1, 30, 30)

		love.graphics.setColor (255,255,255,100)
	end

	
	if game.dbg[3] then
		textbubble ('info',r.x,r.y,dumpvar (map),0,{style=3,theme=2,pad=5,w=600})
	end




	if altshow or game.altitem or love.mouse.isDown(3) then
		alttext ()
	end

alttext ()
	
	
	


	love.graphics.setColor (255,255,255,100)
	love.graphics.setFont(font)
	if dumpout2 then
			love.graphics.printf(dumpout2, 10, 10,700)
			--love.graphics.printf('dumpout2', 10, 10,700)
	end







	if edit.x and edit.w then
		love.graphics.setColor (0,1,1,1)
		love.graphics.rectangle("line", edit.x, edit.y, edit.w, edit.h)
	end



	draw_textbubble ()
	

	


	if game.gr2x then
		love.graphics.setCanvas()
		if deferred_lighting then
			local blend_mode, alpha_mode = love.graphics.getBlendMode()
			love.graphics.setBlendMode("alpha", "premultiplied")
			love.graphics.draw (gr2x, 0,0,0,2,2)
			love.graphics.setBlendMode(blend_mode, alpha_mode)
		else
			love.graphics.draw (gr2x, 0,0,0,2,2)
		end
		--love.graphics.draw (quad, gr2x, 500,200,0,0.5,0.5)
	end



if pl.dying==nil and game.achishow==nil then

		draw_gui ()

end


if game.achishow then

	draw_fullbox ()
	local s,s2 = achi_str ()

	love.graphics.printf (s,32,32,400)
	love.graphics.printf (s2,432,32,400)


end












	if game.dbg[4] then
		love.graphics.setFont(font2)
		local s = ""
		for k,v in pairs(allsounds) do
			s = s..k.."\n"
		end
		love.graphics.printf (dumpvar (s),300,0,10000)
	end




	if pl.dying then
		local death_title = death_title_sprite(spt.wasted, LANGUAGE)
		local title_x, title_y, score_x, score_y = death_title_layout(
			death_title,
			screen.width,
			screen.height,
			LANGUAGE
		)
		love.graphics.setColor (1,1,1,1-game.fade)
		love.graphics.draw (quad, death_title,title_x,title_y,0,1,1)
		love.graphics.printf (
			msg.gui[40]..pl.daylived.."\n"..msg.gui[39]..math.floor(pl.score),
			score_x,score_y,10000)

		love.graphics.setColor (1,1,1,1)
	end
								



	if dumpout3 then
		--love.mouse.setVisible(false)
		-- love.mouse.setGrabbed(true)


		--love.graphics.draw (quad, spt.throw, mouse_x - 8, mouse_y - 8,0,1,1)

		--ani_draw (cursor,dt)

		if game.throwcd then
			local pc = math.ceil (game.throwcd/pl.throwcd * 5)
			if pc>5 then pc = 5 end
			game_cursor = spt.throwcursor[pc]
		end

		-- if pl.flip == 1 then
		-- 	textbubble ('use',mouse_x,mouse_y,'Throw',0,{px = 1, style=2,theme=1,pad=3})
		-- else
		-- 	textbubble ('use',mouse_x,mouse_y,'Throw',0,{px = 1, style=1,theme=1,pad=3})
		-- end

	end

	if game.attackcursor then
		game_cursor = spt.cursora[game.attackcursor]
	end


	-- for i,v in ipairs(chunks) do

	-- 	local c = i/#chunks


	-- 	love.graphics.setColor (1,1,1,1)
	-- 	love.graphics.rectangle ('line', 400+v.xr[1], 300+v.yr[2], 400+v.xr[2]-v.xr[1], 300+v.yr[2]-v.yr[1])

	-- 	love.graphics.setColor (c,c,c,0.5)
	-- 	love.graphics.printf(v.name,400+v.xr[1], 300+v.yr[2],10000)


	-- end

	draw_multiplayer_status()
	esc_menu_draw ()

	
	if game.dbg[2] then
		draw_cols ()
	end

	if game.pause or game.craft then
		game_cursor = spt.cursor
	end

	love.mouse.setCursor (game_cursor)


	if game.minimap then
		love.graphics.draw (minimap_canvas, 0,0,0, 0.5,0.5)
	end



	--fps
	local cur_time = love.timer.getTime()
	if next_time <= cur_time then
		next_time = cur_time
		return
	end
	love.timer.sleep(next_time - cur_time)

	--local stats = love.graphics.getStats()
	--dump (stats)
	--limits = love.graphics.getSystemLimits( )
	--dump (limits)

	

end

function status_border(top_text, bottom_prefix, body_rows)
	local top_prefix = "┌[" .. top_text .. "]"
	local frame_width = math.max(
		37,
		utf8.len(top_prefix) + 2,
		utf8.len(bottom_prefix) + 2
	)
	local inner_width = frame_width - 2

	local border = top_prefix
		.. string.rep("─", frame_width - utf8.len(top_prefix) - 1)
		.. "┐\n"
		.. string.rep("│" .. string.rep(" ", inner_width) .. "│\n", body_rows)
		.. bottom_prefix
		.. string.rep("─", frame_width - utf8.len(bottom_prefix) - 1)
		.. "┘\n"

	return border, frame_width
end

local function longest_visible_line(text)
	local plain = text:gsub("{#%x+}", "")
	local longest = 0

	for line in (plain .. "\n"):gmatch("(.-)\n") do
		longest = math.max(longest, utf8.len(line))
	end

	return longest
end

function gui_wrapped_line_count(text, wrap_width, text_font)
	local _, lines = (text_font or font):getWrap(text, wrap_width)
	return math.max(1, #lines)
end

function gui_wrapped_text_line_count(text, wrap_width, text_font)
	local plain = text:gsub("{#%x+}", ""):gsub("\n+$", "")
	if plain == "" then
		return 0
	end

	return gui_wrapped_line_count(plain, wrap_width, text_font)
end

function gui_restored_panel_origin(current_x, current_y, saved_x, saved_y)
	if saved_x ~= nil then
		return saved_x, saved_y
	end

	return current_x, current_y
end

function inventory_mode_toggle_hint(showing_equipment, equipped_count)
	if showing_equipment then
		return msg.gui[10], 2
	end

	if equipped_count > 0 then
		return msg.gui[4], 2
	end

	return "", 0
end

function inventory_z_action_label(definition)
	if definition and definition.put and definition.put ~= 0 then
		return msg.gui[47]
	end

	return msg.gui[14]
end

function ground_card_border(top, text, body_rows)
	top = top:gsub("\n$", "")
	local top_width = utf8.len(top)
	-- The card text starts seven cells after its left border. Keep one empty
	-- cell between the longest visible line and the right border.
	local frame_width = math.max(top_width, longest_visible_line(text) + 9)
	local top_without_corner, corner_count = top:gsub("┐$", "")
	assert(corner_count == 1, "ground card top must end with a right corner")

	local border = top_without_corner
		.. string.rep("─", frame_width - top_width)
		.. "┐\n"
		.. string.rep("│" .. string.rep(" ", frame_width - 2) .. "│\n", body_rows)
		.. "└" .. string.rep("─", frame_width - 2) .. "┘\n"

	return border, frame_width
end

function ground_card_action_hint(is_carrying, can_use_ground, ground_definition)
	if is_carrying then
		return "Space", msg.gui[14]
	end

	if can_use_ground then
		return "V", msg.gui[27]
	end

	if ground_definition and ground_definition.gather then
		if (ground_definition.digtoinv or 0) > 0 then
			return "Space", msg.gui[45]
		end
		return "Space", msg.gui[46]
	end

	return nil, nil
end

function ground_gather_requirements(gather)
	local requirements = {}

	for tool, level in pairs(gather or {}) do
		if level ~= 0 then
			requirements[#requirements + 1] = craft_tool_tag(tool)..":"..level
		end
	end

	table.sort(requirements)
	if #requirements == 0 then
		return ""
	end

	return " {#3e8948ff}("..table.concat(requirements, ", ")..")"
end

function draw_gui ()

-- GUI
--if pl.isdead==nil then

	local h = 14
	local w = 8

	local gx = 1150
	local gx = screen.inv

	local gy = 0



	local s = ""
	for k,v in pairs(pl.buffs) do
		local p = ((v.ttl-game.time)/buff[k].ttl)*100
		s = s..msg.buff[k].name

	if v.cnt then
		s = s.." ("..v.cnt..")"
	end

		s = s.." "..draw_pc (p).."\n"
	end

	if s~="" then love.graphics.printf(text_color(s),gx-400,gy+h*0.5,400-w*2, 'right') end





local invstr = ""
local invstrdur = ""
local einvstr = ""
local einvstrdur = ""
local icnt = 0
local ecnt = 0
local scnt = 0



for k=1,9 do

	--pl.inv_show_c = 0
	--pl.inv_show = {}

--		local v = pl.inv[k+pl.invpage*9] or {}
		
		local start = 0
		if pl.inv_show_c>5 then
			start = pl.inv_show_c - 5
		end

		pl.invselect_d = start

		-- if pl.invsize<k+pl.invpage*9 then 
		-- 	break
		-- end

		--print (k+pl.invpage*9)

		local v = pl.inv[pl.inv_show[start+k]] or {}

		local n
		if item[v.i] then
			n = item[v.i].name
		end

		local ks = (k+start).."]"

		if pl.inv_show[start+k] then
			if type(pl.inv_show[start+k])~='number' or n==nil then
				ks = "  "
			end
		end

		if k+start>9 then
			ks = "  "
		end

		--dump (pl.inv_show[start+k])

		local item_line_count = 1

		if n then

			n = draw_itemname (pl.inv[pl.inv_show[start+k]])
			local marker = pl.invselect==pl.inv_show[start+k]
				and (ctrshow and "■" or "·")
				or " "
			local plain_name = item[v.i].name
			if item[v.i].transform or item[v.i].transformi then
				plain_name = plain_name .. " ≈"
			end
			item_line_count = gui_wrapped_line_count(
				ks .. marker .. plain_name,
				210,
				font
			)

			if pl.invselect==pl.inv_show[start+k] then
				pl.invselect_k = k
				scnt = icnt + item_line_count

				if ctrshow then
					invstr = invstr.."{#ffffffff}"..ks.."■"..n.."{#ffffffff}"
				else
					invstr = invstr.."{#ffffffff}"..ks.."·"..n.."{#ffffffff}"
				end
			else
				invstr = invstr.."{#fee761ff}"..ks.." "..n.." "
			end
		else
			-- n = "-------"
			-- if pl.invselect==pl.inv_show[start+k] then
			-- 	pl.invselect_k = k
			-- 	scnt = k
			-- 	invstr = invstr.."{#63c74dff}"..ks.."]{#3f2832ff}."..n..""
			-- else
			-- 	invstr = invstr.."{#fee761ff}"..ks.."] {#3f2832ff}"..n.." "
			-- end
		end


		if v.t then
			local p = math.floor (v.t/item[v.i].ttl*100)
			if item[v.i].w==nil then item[v.i].w = #item[v.i].name end
			invstrdur = invstrdur.."                           "..draw_pc (p)
		end
		invstrdur = invstrdur..string.rep("\n", item_line_count)

		invstr = invstr.."\n"
	
		icnt = icnt + item_line_count

end

--if type(pl.invselect)~='number' and pl.inv[pl.invselect] then
	local eqc = 0

	for k,ev in ipairs(cf.eq) do

		local v = pl.inv[ev]

		if v then

			local n = item[v.i].name
			local prefix = pl.invselect==ev and ev.." [" or ev.."  "
			local suffix = pl.invselect==ev and "]" or " "
			local item_line_count = gui_wrapped_line_count(
				prefix .. n .. suffix,
				210,
				font
			)

			if pl.invselect==ev then
				scnt = ecnt + item_line_count
				einvstr = einvstr.."{#5a6988ff}"..ev.." {#63c74dff}["..n.."]"
			else
				einvstr = einvstr.."{#5a6988ff}"..ev.."  {#ead4aaff}"..n.." "
			end

			if v.t then
				local p = math.floor (v.t/item[v.i].ttl*100)
				if item[v.i].w==nil then item[v.i].w = #item[v.i].name end
				einvstrdur = einvstrdur.."                           "..draw_pc (p)
			end
			einvstrdur = einvstrdur..string.rep("\n", item_line_count)

			einvstr = einvstr.."\n"

			ecnt = ecnt + item_line_count
			eqc = eqc + 1
		end

	end
--end




local il


if type(pl.invselect)~='number' and pl.inv[pl.invselect] then
	local toggle_hint, toggle_rows = inventory_mode_toggle_hint(true, ecnt)
	invstr = einvstr..toggle_hint
	invstrdur = einvstrdur
	

	icnt = ecnt + toggle_rows
	il = msg.gui[2]
else
	local toggle_hint, toggle_rows = inventory_mode_toggle_hint(false, ecnt)
	invstr = invstr..toggle_hint
	icnt = icnt + toggle_rows

	local is = pl.invsize..""
	if #is==1 then is="0"..is end
	is=is.."/"
	if #pl.inv<10 then
		is = is..'0'
	end
	is=is..#pl.inv
	il = msg.gui[3].."("..is..")══╗"
end

	-- cf.eq = {'r','l','h','b','g','f','l'}
	-- cf.eqs = {r = 'l', l = 'h', h = 'b', b = 'g', g = 'f', f = 'l', l = 'r'}
	-- cf.eqname = {'Hand','hand','Head','Body','Legs','Foot','Belt'}



--gy = gy + 165


if icnt > 0 then
--	if true then

	local astr = ""
	local acnt = 0
	local dstr = ""
	local dcnt = 0
	local comp 



		local it = pl.inv[pl.invselect]

		if it and it.tool then

			-- if type(pl.invselect)=='number' then
			-- 	dstr = dstr..msg.gui[22]
			-- 	dcnt = dcnt + 2
			-- end

			astr, acnt = draw_tool (it,astr,acnt)
			acnt = acnt + 1
			astr = astr.."\n"

		else
			if it then
				dstr = dstr.."\n"
			end
		end


		if it and it.i and item[it.i].oninfo then
			astr = astr.."{#8b9bb4ff}"..item[it.i].oninfo (pl.tx, pl.ty,it).."\n\n"
			acnt = acnt + 2
		end

		if it then

			local it = item[pl.inv[pl.invselect].i]
			
			local half = 0

			if type(pl.invselect)=='number' then
				astr = astr.."{#fee761ff}Z]{#ffffffff} "
					..inventory_z_action_label(it)
				half = half + 0.5
			end

			
			--type(pl.invselect)=='number' and
			if item[pl.inv[pl.invselect].i].throw~=nil then
				astr = astr.."{#fee761ff}R]{#ffffffff} "..msg.gui[13] -- throw
				half = half + 0.5

				if half==1 then acnt = acnt + 1; astr = astr.."\n"; half = 0 end
			end

			
			
			if type(pl.invselect)=='number' and item[pl.inv[pl.invselect].i].onempty~=nil then
				astr = astr.."{#fee761ff}R]{#ffffffff} "..msg.gui[20] -- empty
				half = half + 0.5

				if half==1 then acnt = acnt + 1; astr = astr.."\n"; half = 0 end
			end


			if it.calories then
				astr = astr.."{#fee761ff}U]{#ffffffff} "..msg.gui[15]
				half = half + 0.5

				if half==1 then acnt = acnt + 1; astr = astr.."\n"; half = 0 end
			end

			if it.onuse then
				astr = astr.."{#fee761ff}U]{#ffffffff} "..msg.gui[19]
				half = half + 0.5

				if half==1 then acnt = acnt + 1; astr = astr.."\n"; half = 0 end
			end



			if it.equip then

				if type(pl.invselect)=='number' then
					astr = astr.."{#fee761ff}P]{#ffffffff} "..msg.gui[16]
				else
					astr = astr.."{#fee761ff}P]{#ffffffff} "..msg.gui[17]
				end
				half = half + 0.5

				if half==1 then acnt = acnt + 1; astr = astr.."\n"; half = 0 end
			end

			

			if item[pl.inv[pl.invselect].i].craftable then

				astr = astr.."{#fee761ff}C]{#ffffffff} "..msg.gui[28]
				half = half + 0.5

				if half==1 then acnt = acnt + 1; astr = astr.."\n"; half = 0 end

			end

			if msg.item[pl.inv[pl.invselect].i].info or
				item[pl.inv[pl.invselect].i].calories then

				astr = astr.."{#fee761ff}I]{#ffffffff} "..msg.gui[24]
				half = half + 0.5
			end

			if half>0 then acnt = acnt + 1; astr = astr.."\n"; half = 0 end

			if type(pl.invselect)~='number' then 
				astr = astr.."\n"
			end

		end

	if astr ~= "" then
		-- Localized tool statistics and action labels can wrap inside the
		-- 210-pixel details column. Size the frame from the lines that LÖVE
		-- will actually draw, rather than from the unwrapped source rows.
		acnt = gui_wrapped_text_line_count(astr, 210, font)
	end

	icnt = icnt + 2


--table.inserts (out, text_color (hpstr))
-- U+250x	─	━	│	┃	┄	┅	┆	┇	┈	┉	┊	┋	┌	┍	┎	┏
-- U+251x	┐	┑	┒	┓	└	┕	┖	┗	┘	┙	┚	┛	├	┝	┞	┟
-- U+252x	┠	┡	┢	┣	┤	┥	┦	┧	┨	┩	┪	┫	┬	┭	┮	┯
-- U+253x	┰	┱	┲	┳	┴	┵	┶	┷	┸	┹	┺	┻	┼	┽	┾	┿
-- U+254x	╀	╁	╂	╃	╄	╅	╆	╇	╈	╉	╊	╋	╌	╍	╎	╏
-- U+255x	═	║	╒	╓	╔	╕	╖	╗	╘	╙	╚	╛	╜	╝	╞	╟
-- U+256x	╠	╡	╢	╣	╤	╥	╦	╧	╨	╩	╪	╫	╬	╭	╮	╯
-- U+257x	╰	╱	╲	╳	╴	╵	╶	╷	╸	╹	╺	╻	╼	╽	╾	╿
-- Notes
-- 1.^ As of Unicode version 11.0


local time = os.date ("%H:%M",os.time())


if #pl.inv>0 or ecnt>0 then

	local border
	
	if acnt == 0 then
		border = 
		il.."\n"..
		string.rep(" ║                                ║\n",icnt)..
		" ╚═══════════════════════ "..time.." ══╝\n"

		if dcnt > 0 then
			border = border..
			" ┌────────────────────────────────┐\n"..
			string.rep(" │                                │\n",dcnt)..
			" └────────────────────────────────┘\n"
		end

	end

	if acnt > 0 and dcnt == 0 then
		border = 
		il.."\n"..

		string.rep(" ║                                ║\n",scnt)..
		"┌╢                                ║\n"..
		string.rep("│║                                ║\n",icnt-scnt-1)..

		"│╚═══════════════════════ "..time.." ══╝\n"..

		"│┌────────────────────────────────┐\n"..
		"└┤                                │\n"..
		string.rep(" │                                │\n",acnt-1)..
		" └────────────────────────────────┘\n"
	end

	if acnt > 0 and dcnt > 0 then
		border = 
		il.."\n"..

		string.rep(" ║                                ║\n",scnt)..
		"┌╢                                ║\n"..
		string.rep("│║                                ║\n",icnt-scnt-1)..

		"│╚═══════════════════════ "..time.." ══╝\n"..

		"│┌────────────────────────────────┐\n"..
		"└┤                                │\n"..
		string.rep(" │                                │\n",acnt-1)..
		" └────────────────────────────────┘\n"..
		" ┌────────────────────────────────┐\n"..
		string.rep(" │                                │\n",dcnt)..
		" └────────────────────────────────┘\n"
	end

	--invstr = invstr..scnt
	if astr ~="" then
		invstr = invstr.."\n\n\n"..astr
	end



		love.graphics.setColor (0,0,0,0.9)
		
		local hf = icnt+4
		if acnt > 0 then hf = hf + acnt + 0.5 end
		if dcnt > 0 then hf = hf + dcnt + 1 end
		
		love.graphics.rectangle("fill", gx, gy, w*36, h*(hf))
		love.graphics.setColor (1,1,1,1)

		love.graphics.printf(border,gx,gy+h*0.5,400)
		love.graphics.printf(text_color (invstr),gx+w*3,gy+h*2.5,210)
		love.graphics.printf(text_color (invstrdur),gx+w*3,gy+h*2.5,400)
		



gy = gy + h*(hf)+7
icnt = icnt + 2

end
end











	local ground
	local groundn
	-- These coordinates are only valid for the current frame. Keeping them in
	-- globals made the ground inventory jump back to a previous frame's height
	-- when the hovered block disappeared or the selected item panel grew.
	local gxold
	local gyold

	pl.inspect = nil

	local ginvstr = ""
	local ginvstrdur = ""
	local gicnt = 0


	-- mouse look

	local farground = true
	local r = px2tile (mouse_x,mouse_y)

	
	if pl.iscarry then
		ground = pl.iscarry.b
		border = msg.gui[25]
		farground = nil
	else

		if pl.canuse then
			r.x = pl.tx
			r.y = pl.ty
			farground = nil
		end

		--t = math.abs (pl.xt - r.x)+math.abs (pl.yt - r.y)

		--if t<3 then
			ground = readmap (r.x,r.y,'b')
			groundn = readmap (r.x,r.y,'n')
			border = "┌────────────────────────────────┐\n"
		--end
	end


	if readmap (r.x,r.y,'w') then

			if pl.candrink==nil then
				pl.candrink = message (msg.gui[44],{[1] = math.ceil(readmap (r.x,r.y,'dr') or 0)})	
			end

			ground = 145
			groundn = readmap (r.x,r.y,'n')
			border = "┌────────────────────────────────┐\n"
			str = pl.candrink

	end


	if ground and ground~=0 and stone[ground] and stone[ground].noinfo ==nil 
		and groundn~=255 then


		local str


		str ="{#c0cbdcff}"..stone[ground].name
		--str = str..r.x.."-"..r.y

		if stone[ground].transform or stone[ground].transformi then
			str = str.." {#c0cbdcff}≈{#ffffffff}"
		end

		--str=str.."\n"..tostring(has_light (r.x,r.y))


		str = str..ground_gather_requirements(stone[ground].gather)


		local cnt = 2
		local e = readmap (r.x,r.y,'e')
		local wt = readmap (r.x,r.y,'wt')
		local mu = readmap (r.x,r.y,'mu')
		local problem = readmap (r.x,r.y,'problem')
		

		if problem then
			str = str.."\n"..msg.plantproblem[problem]
			cnt = cnt + 1
		end


		if e then
			str = str.."\n{#8b9bb4ff}"..msg.gui[31]..draw_pc (e/3,'full')
			cnt = cnt + 1
		end

		if wt then
			str = str.."\n{#8b9bb4ff}"..msg.gui[32]..draw_pc (wt/3,'full')
			cnt = cnt + 1
		end	


		if mu then
			str = str.."\n{#8b9bb4ff}"..msg.gui[35]..draw_pc ((mu*100)/12,'full')
			cnt = cnt + 1
		end	

		local action_key, action_hint = ground_card_action_hint(
			pl.iscarry ~= nil,
			pl.canuse,
			stone[ground]
		)
		if action_key then
			str = str.."\n{#fee761ff}"..action_key.."]{#ffffffff} "..action_hint
			cnt = cnt + 1
		end

		if msg.stone[ground].info then
			str = str.."\n{#fee761ff}O]{#ffffffff} "..msg.gui[24]
			pl.inspect = ground
			game_cursor = spt.icursor
		end


		if stone[ground].oninfo and pl.iscarry==nil then
			str = str.."\n"..stone[ground].oninfo (r.x, r.y)
			cnt = cnt + 1
		end


		if pl.candrink and ground == 145 then
			str = pl.candrink
		end



			gxold = gx
			gyold = gy

			gx = 0
			gy = screen.txt - (cnt+5)*h

		local ground_frame_width
		border, ground_frame_width = ground_card_border(border, str, cnt + 1)

			--love.graphics.setColor (0.05,0.03,0.05, 0.5)
			love.graphics.setColor (0,0,0,0.9)
			local hf = gicnt+5
			
			love.graphics.rectangle("fill", gx, gy, w*(ground_frame_width+2), h*(4+cnt))
			love.graphics.setColor (1,1,1,1)


			if stone[ground].ondraw then
				stone[ground].ondraw (gx+21, gy+27, r.x, r.y)
			else
				love.graphics.draw (quad, stone[ground].spr, gx+21, gy+27, 0,2,2)
			end



			love.graphics.printf(border,gx+w*1,gy+h*0.5,w*(ground_frame_width+1))
			love.graphics.printf(
				text_color(str),
				gx+w*8,
				gy+27,
				w*(ground_frame_width-8)
			)

	
		gy = gy + h*(cnt+4)


		end




	gx, gy = gui_restored_panel_origin(gx, gy, gxold, gyold)


	local ginvstr = ""
	local ginvstrdur = ""
	local gicnt = 0


local ground = readmap (pl.xt,pl.yt,'i')

if mousemoved==nil then

	game_cursor = spt.dcursor
	
end




if ground and #ground>0 then

	local border

	for i,v in ipairs(ground) do

		if i==10 then
			ginvstr = ginvstr.."{#fee761ff}   {#ead4aaff}.......\n"
			gicnt = gicnt + 1
			break
		end

		local plain_name = item[v.i].name
		if item[v.i].transform or item[v.i].transformi then
			plain_name = plain_name .. " ≈"
		end
		local item_line_count = gui_wrapped_line_count(
			i .. ") " .. plain_name,
			w * 32,
			font
		)

		ginvstr = ginvstr.."{#d87644ff}"..i..") {#ead4aaff}"..draw_itemname(v)

		if v.t then
			local p = math.floor (v.t/item[v.i].ttl*100)
			ginvstrdur = ginvstrdur.."                           "..draw_pc (p)
		end
		ginvstrdur = ginvstrdur..string.rep("\n", item_line_count)

		ginvstr = ginvstr.."\n"
		gicnt = gicnt + item_line_count

	end

	
	local l = ""..#ground
	if #l == 1 then l = "0"..l end

	border = 
	msg.gui[18].."("..l..")────┐\n"..
	string.rep("│                                │\n",gicnt+2)


	if farground then
		--border = border..msg.gui[26]
		border = border..msg.gui[11]
	else
		if #ground==1 then
			border = border..msg.gui[11]
		else
			border = border..msg.gui[11]
		end
	end
		

	love.graphics.setColor (0,0,0,0.9)
	local hf = gicnt+5
	
	love.graphics.rectangle("fill", gx, gy, w*36, h*(hf))
	love.graphics.setColor (1,1,1,1)

	love.graphics.printf(text_color(border),gx+w*1,gy+h*0.5,400)
	love.graphics.printf(text_color (ginvstr),gx+w*3,gy+h*2.5,w*32)
	love.graphics.printf(text_color (ginvstrdur),gx+w*3,gy+h*2.5,w*32)




gy = gy + h*(hf)

end










			--love.graphics.printf(out,820,20,260)




			love.graphics.printf(("fps:"..tostring(love.timer.getFPS())), screen.width-100, screen.height-30,700)
			
			

			if game.dbg[2] then

				local r = px2tile (mouse_x,mouse_y)
				tile,map = maptile (r.x,r.y,"all")

				dump (has_light (r.x,r.y))

				love.graphics.setFont(font2)
				love.graphics.printf(r.x.." "..r.y.." "..dumpvar (map), 10, 200,700)
				love.graphics.setFont(font)

			end









------------------------------------ stat menu



	local h = 14
	local w = 8
	local gx = 0
	local gy = 0



--	local gy = 590

--local t = "Time: "..telltime(game.time).." † "..pl.deaths

local t = telltime(game.time).." †"..pl.deaths..""
local sc = math.floor(pl.score).."]──["..message(msg.ui.location, {
	[1] = pl.tx-pl.startx-1,
	[2] = pl.ty-pl.starty-5,
})
local faith = 0

if altshow then
	faith = 1
end

		local border, status_frame_width = status_border(
			t,
			msg.gui[38] .. sc .. "]",
			8 + faith
		)


	--fps:"..tostring(love.timer.getFPS()).."\n"..

	local hpstr = 
	draw_health (msg.gui[8],'arms').."\n"..
	draw_health (msg.gui[7],'body').."\n"..
	
	draw_health (msg.gui[5],'food').."\n"..
	draw_health (msg.gui[6],'water').."\n"..
	draw_health (msg.gui[9],'filth').."\n"..
	

	draw_health (msg.gui[30],'heat').."\n"..

	
	draw_health (msg.gui[29],'power').."\n"

	if faith>0 then
		hpstr = hpstr..draw_health (msg.gui[42],'faith').."\n"
	end



	love.graphics.setColor (0,0,0,0.7)
		love.graphics.rectangle("fill", gx, gy, w*status_frame_width, h*11+faith*h)
	love.graphics.setColor (1,1,1,1)

	love.graphics.printf(border,gx+w*1,gy+h*0.5,400)
	love.graphics.printf(text_color (hpstr),gx+w*3,gy+h*2,400)

	gx = gx + 300


	if game.dbg[1] then
		gy = gy + 8
		if stone[game.blocks[currentBlock]] then

			if stone[game.blocks[currentBlock]].spr==nil then
				oldprint (game.blocks[currentBlock])
			end

			love.graphics.draw (quad, stone[game.blocks[currentBlock]].spr, gx, gy,0,2,2)
		end

		if item[game.items[currentItem]] then
			love.graphics.printf(item[game.items[currentItem]].name, gx, gy+50, 700)
		end
	end




if game.hidelog == nil or game.craft or love.mouse.getY()>screen.txt then


	local gx = 0
	-- local gy = 7
	local gy = 590
	local gy = screen.txt

	local he = 120
	local he = screen.txtwidth


	if game.craft and craft.len then
		
		local shad = 0
		if game.shaken then
			shad = math.cos (game.shaken) * 7
		end

		local add_h = 2

		if craft.len-6>0 then
			add_h = add_h + craft.len - 6
		end

		local add_w = 41

		local add_w = screen.txtcraft

		gy = gy - h * add_h

		local header = msg.gui[34]
		local border =
		header..string.rep("─",math.max(0, he+add_w+6-utf8.len(header))).."┐\n"..
		string.rep("│   "..string.rep(" ",he+add_w).."  │\n",11+add_h)..
		"└───────"..string.rep("─",he-2+add_w).."┘\n"

		love.graphics.setColor (0,0,0,0.9)
		love.graphics.rectangle("fill", gx, gy, w*(he+9+add_w), h*(14+add_h))
		love.graphics.setColor (unpack(hex_color ("#124e89ff")))

		love.graphics.printf(border,gx+w*1,gy+h*0.5,10000)
		love.graphics.setColor (1,1,1,1)
		
		love.graphics.printf(text_color (craft.str),gx+w*3+shad, gy+h*1.5+4,vi.textwall_w+add_w*w)
	else
		local header = msg.gui[33]
		local footer = msg.gui[41]
		local border =
		header..string.rep("─",math.max(0, he+6-utf8.len(header))).."┐\n"..
		string.rep("│   "..string.rep(" ",he).."  │\n",11)..
		footer..string.rep("─",math.max(0, he+6-utf8.len(footer))).."┘\n"

		love.graphics.setColor (0,0,0,0.8)
		love.graphics.rectangle("fill", gx, gy, w*(he+9), h*14)
		love.graphics.setColor (unpack(hex_color ("#124e89ff")))

		love.graphics.printf(border,gx+w*1,gy+h*0.5,10000)
		love.graphics.setColor (1,1,1,1)

		love.graphics.draw (text_canvas, gx+w*3, gy+h*1.5+4)
	end

end


end

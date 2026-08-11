local utf8lib = require("utf8")

local russian_lowercase = {
	"а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й",
	"к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф",
	"х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я",
}

local russian_uppercase = {
	"А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й",
	"К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф",
	"Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я",
}

local russian_locked_replacement = {}

local function add_russian_locked_replacements (alphabet)
	for index, letter in ipairs(alphabet) do
		local bucket_start = math.floor((index - 1) / 6) * 6 + 1
		local replacement = alphabet[bucket_start]
		if replacement == letter then
			replacement = alphabet[index < #alphabet and index + 1 or index - 1]
		end
		russian_locked_replacement[letter] = replacement
	end
end

add_russian_locked_replacements(russian_lowercase)
add_russian_locked_replacements(russian_uppercase)

local function lock_russian_text (str)
	local result = {}
	local word_position = 0

	for _, codepoint in utf8lib.codes(str) do
		local character = utf8lib.char(codepoint)
		local replacement = russian_locked_replacement[character]
		if replacement then
			word_position = word_position + 1
			if word_position % 2 == 0 then
				character = replacement
			end
		else
			word_position = 0
		end
		result[#result + 1] = character
	end

	return table.concat(result)
end

function draw_fullbox (n)

	n = n or 43
	local h = 14
	local w = 8

	local th = screen.height/h
	local tw = screen.width/w

	local head = msg.gui[n]
	local head_length = utf8.len(head)

	local border = "┌─["..head.."]"..string.rep("─",tw-head_length-5).."┐\n"..
	string.rep("│"..string.rep(" ",tw-4).."  │\n",th-2)..
	"└"..string.rep("─",tw-2).."┘\n"

	love.graphics.setColor (0,0,0,0.9)
	love.graphics.rectangle("fill", 0, 0, screen.width, screen.height)
	love.graphics.setColor (1,1,1,1)
	love.graphics.printf(border,0,0,4000)

end


function draw_progress (pc,max)
	local str = "▮"
	if max and max == 1 then
		str = '▒'
		-- ░▒▓
	end
	pc = pc * 100
	local s = ""
	for i=1,100,3 do
		if i<pc then
			s = s.."{#3e8948ff}"..str.."{#ffffffff}"
		else
			s = s.."{#3f2832ff}"..str.."{#ffffffff}"
		end
	end

	return s
	
end

function locked_txt (str)
	local color_tags = {}
	str = string.gsub(str, "({#%x+})", function (tag)
		color_tags[#color_tags + 1] = tag
		return "\1"..#color_tags.."\2"
	end)

	str = string.gsub (str,'([a-z])[a-f]','%1a')
	str = string.gsub (str,'([a-z])[f-i]','%1f')
	str = string.gsub (str,'([a-z])[i-n]','%1i')
	str = string.gsub (str,'([a-z])[n-r]','%1n')
	str = string.gsub (str,'([a-z])[r-v]','%1r')
	str = string.gsub (str,'([a-z])[v-z]','%1v')
	str = lock_russian_text(str)
	str = string.gsub(str, "\1(%d+)\2", function (index)
		return color_tags[tonumber(index)]
	end)
	return str.." "
end

--A aB bC cD dE eF fG gH hI iJ jK kL lM mN nO oP pQ qR rS sT tU uV vW wX xY yZ z

	function diet_tags_text (diet)
		local labels = {}
		local localized = msg.gui.diet.tags or {}
		for _, tag in ipairs(diet or {}) do
			labels[#labels + 1] = "#"..(localized[tag] or tag)
		end
		if #labels == 0 then return "" end
		return " {#d87644ff}("..table.concat(labels, ", ")..")"
	end

	function diet_info (sel,wm)

		wm = wm or 1
		if item[sel.i].calories==nil then return end

		local age, d, r, multi = consume_cal(sel, nil)
		local total = math.ceil(r)

		if total == item[sel.i].calories then
			total = ""
		else
			total = "= {#63c74dff}"..total
		end

		local sq = math.floor (r/5)
		local sqd = ''
		if sq>0 then
			sqd = "= {#63c74dff}"..string.rep ("■",sq).."{#ffffffff} "
		end

		local tags = diet_tags_text(item[sel.i].diet)

		local multitxt = ''

		if multi then
			multi = "{#feae34ff}2x{#ffffffff}"
			--multitxt = msg.gui.diet[5]
		else
			multi = ''
		end

		return message (msg.gui.diet[wm], {[1] = msg.item[sel.i].name,
		[2] = tags, [3] = item[sel.i].calories,
		[4] = age,
		[5] = d,
		[6] = total,
		[7] = sqd,
		[8] = multi,
		[9] = multitxt,
		}
		)

end

function draw_cooking (x,y,t,pc)

	--t 0..1 tneed
	--       cd
	--p 0..1 done

	pc = pc or 0
	if t > 1 then t = 1 end
	if pc > 1 then pc = 1 end

	local r = tile2px (x,y)

	love.graphics.setLineStyle ('rough')
	

	love.graphics.setLineWidth (1)

	love.graphics.setColor (0,0.58,0.91,0.8)
	love.graphics.setColor (0.99,0.90,0.38,0.8)
	

	love.graphics.rectangle("line", r.x+2, r.y+2, 29, 5)

	

	love.graphics.setColor (0.07,0.30,0.53,0.5)
	love.graphics.rectangle("fill", r.x+4, r.y+2, 27, 4)

	love.graphics.setLineWidth (4)

	--love.graphics.setColor (0.96,0.46,0.13,1)
	love.graphics.setColor (0.61,0.15,0.20,1)
	
	t = math.floor (t*28)
	love.graphics.line(r.x+2,r.y+4,r.x+t+2,r.y+4)

	--love.graphics.setColor (0.75,0.75,0.86,1)
	love.graphics.setColor (0.99,0.90,0.38,1)
	
	love.graphics.setLineWidth (2)
	pc = math.floor (pc*28)
	love.graphics.line(r.x+2,r.y+5,r.x+pc+2,r.y+5)

	
	love.graphics.setColor (1,1,1,1)


end

function draw_cooking_smooth2x (x,y,t,pc)

	-- At 2x scale this HUD-like indicator is drawn directly into the
	-- final-sized frame. Keeping the two values on separate rows makes the
	-- required heat and the completed work readable without filtering either
	-- one through the low-resolution world canvas.
	t = math.max(0, math.min(1, t or 0))
	pc = math.max(0, math.min(1, pc or 0))

	local r = tile2px (x,y)
	local left = math.floor(r.x * 2) + 4
	local top = math.floor(r.y * 2) + 4
	local width = 58
	local height = 10
	local inner_left = left + 2
	local inner_top = top + 2
	local inner_width = width - 4
	local heat_width = math.floor(inner_width * t + 0.5)
	local progress_width = math.floor(inner_width * pc + 0.5)

	local old_style = love.graphics.getLineStyle()
	local old_width = love.graphics.getLineWidth()
	local red, green, blue, alpha = love.graphics.getColor()

	love.graphics.setLineStyle('smooth')
	love.graphics.setLineWidth(1.5)
	love.graphics.setColor(0.03, 0.10, 0.16, 0.88)
	love.graphics.rectangle('fill', left, top, width, height, 2, 2)
	-- Keep the frame subordinate to the actual progress bar. A saturated
	-- yellow outline looked almost luminous at the final 2x resolution.
	love.graphics.setColor(0.58, 0.51, 0.24, 0.72)
	love.graphics.rectangle('line', left, top, width, height, 2, 2)

	if heat_width > 0 then
		love.graphics.setColor(0.61, 0.15, 0.20, 1)
		love.graphics.rectangle('fill', inner_left, inner_top, heat_width, 2, 1, 1)
	end
	if progress_width > 0 then
		love.graphics.setColor(0.99, 0.90, 0.38, 1)
		love.graphics.rectangle('fill', inner_left, inner_top + 4, progress_width, 2, 1, 1)
	end

	love.graphics.setLineStyle(old_style)
	love.graphics.setLineWidth(old_width)
	love.graphics.setColor(red, green, blue, alpha)

end


function draw_itemname (it)

	if it==nil then return end

	local str = ""

	if item[it.i].craftable then str = "{#8b9bb4ff}" end
	if item[it.i].calories then str = "{#feae34ff}" end
	if item[it.i].tag=='seed' then str = "{#3e8948ff}" end
	if item[it.i].tool then str = "{#b86f50ff}" end
	

	
	if item[it.i].onburydie and item[it.i].calories==nil then str = "{#3e8948ff}" end --seed
	
	if item[it.i].f_burn then str = "{#ff0044ff}" end

	if str =='' and item[it.i].tag==nil then str = "{#ead4aaff}" end
	
	
	str = str..item[it.i].name

	if item[it.i].transform or item[it.i].transformi then
		str = str.." {#c0cbdcff}≈" 
	end

	return str

end


function draw_tool_pad (str)
	
	str = str..string.rep(" ", 13-utf8.len(str))
	return str

end

local displayed_tool_stats = {
	"dig",
	"cut",
	"chop",
	"smash",
	"pierce",
	"water",
	"oil",
	"vinegar",
	"salsa",
}


function draw_tool (it,dstr,dcnt,sep)

	sep = sep or "\n"

	--it.equip

	if it.tool == nil then return "",0 end

	local a = 0

	for _, stat in ipairs(displayed_tool_stats) do
		if it.tool[stat] then
			dstr = dstr.."{#3e8948ff}"..draw_tool_pad(msg.gui.item[stat]..it.tool[stat])
			a = 1
		end
	end


	if a==1 then
		dstr = dstr..sep
		dcnt = dcnt + 1
	end

	if it.tool.dmgmin then 
		
		dstr = dstr.."{#ff0044ff}"..draw_tool_pad(msg.gui.item.dmg..it.tool.dmgmin.."-"..it.tool.dmgmax)
		
		local dps = tool_damage_per_second(it.tool)
		dps = string.format("%.2f", dps)
		dstr = dstr.."{#ff0044aa}"..msg.gui.item.dps..dps
		
		dstr = dstr..sep
		a = 1
		dcnt = dcnt + 1
	end

	
	return dstr, dcnt


end





function mystify (txt)
	local hidden = {}
	for _, codepoint in utf8.codes(txt) do
		local character = utf8.char(codepoint)
		hidden[#hidden + 1] = character == " " and " " or "?"
	end
	return table.concat(hidden)
end



function draw_full (cur,full)
	str = ""
	for i=1,full do
		if i<=cur then
			str = str.."■"
		else
			str = str.."{#3a4466ff}■"
		end
	end

	return str
end



function draw_growpc (x,y)

	local s = readmap (x,y,'b')
	local stage = readmap (x,y,'stage') or 1

	--stone[s].plant.dead

	local opt = stone[s].plant.opt or (stone[s].plant.dead - 1)
	local seed = stone[s].plant.seed or (opt - 1)

	local str = ""
	local a = ""
	local last = ""

	for i=1,stone[s].plant.stages do

		--if i<=stage then

			if i==stone[s].plant.dead  then
				a = "{#e43b44ff}"
			else
				if i>=seed then
					a = "{#d87644ff}"
				elseif i>= opt then
					a = "{#fee761ff}"
				else
					a = "{#63c74dff}"
				end
			end

		str = str..a.."▒"

		-- ░▒▓

		if i == stage then
			last = a
		end

		--else
		--	str = str.."{#3a4466ff}▮"
		-- end

	end


str = str.."\n"..last..string.rep (" ",stage-1).."▲"

	return str
end




function draw_pc (pc, what)

	pc = math.ceil (pc / 10)

	local d = {"  ┉","  ■","  ▮"," ∙▮"," ■▮"," ▮▮","∙▮▮","■▮▮","▮▮▮"," "}

	if pc > 10 then pc = 10 end

	if what=='full' then pc = pc - 1 end

	if pc < 1 then pc = 1 end

	if pc<4 then
		return "{#9e2835ff}"..d[pc].."{#ffffffff}"
	elseif pc<7 then
		return "{#feae34ff}"..d[pc].."{#ffffffff}"
	else
		return "{#ead4aaff}"..d[pc].."{#ffffffff}"
	end

end


function draw_20cal (pc,name)


	local s = math.ceil (20 * pc/100)
	--{3e8948}

	local str = ""

	--str = str.."["	


	--  -■▮ ○━○ ▮■┉ -
	str = str..string.rep ("■", s)
	str = str..""
	-- ░▒▓

	if pc<33 then
		str = "{#9e2835ff}"..name..str.."{#ffffffff}"
	elseif pc<66 then
		str = "{#feae34ff}"..name..str.."{#ffffffff}"
	else
		str = "{#63c74dff}"..name..str.."{#ffffffff}"
	end

	--if s<20 and stat==game.lasthit then
		--str = str.."∙"
	--end

	if s<20 then
		str = str.."{#262b44ff}"
		str = str..string.rep ("■",20-s)
	end


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


	return str


end

function draw_health (name,stat)


	local num = pl.stats[stat].hp
	local pc = pl.stats[stat].pc

	local s = math.ceil (20 * pc/100)

	--{3e8948}



	local str = ""


	--str = str.."["	

	-- if s<1 then
	--	str = str.."┉"
	-- end


	--  -■▮ ○━○ ▮■┉ -
	str = str..string.rep ("■", s)
	str = str..""
	-- ░▒▓

	if pc<33 then
		str = "{#9e2835ff}"..name..str.."{#ffffffff}"
	elseif pc<66 then
		str = "{#feae34ff}"..name..str.."{#ffffffff}"
	else
		str = "{#63c74dff}"..name..str.."{#ffffffff}"
	end


	if s<20 then
		str = str.."{#262b44ff}"
		str = str..string.rep ("■",20-s)
	end

	if stat==game.lasthit then
		str = str.."{#9e2835ff}∙"
	else
		str = str.." "
	end

	if altshow then
		str = str.."{#ffffffff}"..math.ceil(pl.stats[stat].hp)
	else
		if pl.stats[stat].maxhp>=101 then
			str = str.."{#8b9bb4ff}+"..math.floor(pl.stats[stat].maxhp-100)
		end
	end



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


	return str


end


function inv_dump (out, k, v, invtrue)
	
	if v then

		if pl.invselect==k and invtrue then
				table.insert (out, {1,1,0,1})
				table.insert (out, k.."]")
				table.insert (out, {0,1,0,1})
				table.insert (out, "["..v.n.."] ")
				table.insert (out, string.rep (" ",22-#v.n))
			else
				table.insert (out, {1,0.5,0.5,1})
				if invtrue then
					table.insert (out, k.."] ")
				else
					table.insert (out, k.."} ")
				end
				table.insert (out, {1,1,0.8,1})
				table.insert (out, v.n.."  ")
				table.insert (out, string.rep (" ",22-#v.n))

			end
			
			if v.t then
				table.insert (out, {0.3,0.3,0.5,1})
				local p = math.floor (v.t/item[v.i].ttl*100)
				table.insert (out, ""..p.."% \n")
			else
				table.insert (out, "\n")
			end
	else

		table.insert (out, {0.3,0.3,0.3,1})
		table.insert (out, k..".")
		table.insert (out, " ----------\n")

	end

end



function textbubble (id,x,y,text,ttl,mode)

	if id=='dis' then
		--sound_add ('dis',1,{x = x, y = y, play = 1, dur = ttl, rewind = 0})
		sound_add ('dis',1,{dur = ttl})
	end

	local r = {}

	if mode.px then
		r.x = x
		r.y = y
	else
		r = tile2px (x,y)
	end

	if x==nil then return end

	mode = mode or {}
	ttl = ttl or 0

	style = mode.style or 1
	theme = mode.theme or 1
	mode.pad = mode.pad or 5
	local w = mode.w or 400

	text = text_color (text)
	local a = {x = math.floor(r.x), y = math.floor(r.y), text = text, ttl = game.dt + ttl, 
	pad = mode.pad, out = mode.out, outt = mode.outt }
	a.textbox = love.graphics.newText(font, "")
	a.textbox:setf (text,w,'left')
	a.h = a.textbox:getHeight()+mode.pad*2
	a.w = a.textbox:getWidth()+mode.pad*4


	if style==1 then

		a.x = a.x + 10
		a.y = a.y - a.h/2

		a.p = {

		0,
		0,

		0+a.w,
		0,

		0+a.w,
		0+a.h,

		0,
		0+a.h,

		0-10,
		0+a.h/2,

		}

	end

	if style==2 then

		a.x = a.x - a.w - 10
		a.y = a.y - math.floor (a.h/2)

		a.p = {

		0,
		0,

		0+a.w,
		0,

		0+a.w+10,
		0+a.h/2,

		0+a.w,
		0+a.h,

		0,
		0+a.h,

		}

	end

	if style == 3 then
		a.x = a.x - 3
		a.y = a.y - a.h - 16 - 7

		a.p = {

		0+10,
		0,

		0+a.w,
		0,

		0+a.w,
		0+a.h,

		0+30,
		0+a.h,

		0+20,
		0+a.h+20,

		0+10,
		0+a.h,

		0,
		0+a.h,

		0,
		0

		}
	end

	if style == 5 then
		a.x = a.x + 8
		a.y = a.y - math.floor (a.h) - 32 - 16

		a.p = {

		0+10,
		0,

		0+a.w,
		0,

		0+a.w,
		0+a.h,

		0+30,
		0+a.h,

		0+10,
		0+a.h+20,

		0+10,
		0+a.h,

		0,
		0+a.h,

		0,
		0

		}
	end



	--triangles = love.math.triangulate(a.p)
	--print (dumpvar(triangles))

	if theme == 1 then
		a.bg = hex_color ('#000000ff')
		a.tc = hex_color ('#f77622ff')
		a.lc = hex_color ('#be4a2fff')
		a.oc = hex_color ('#000000ff')
		a.oct = hex_color ('#ffffffff')
	end

	if theme == 2 then
		a.bg = hex_color ('#000000ff')
		a.tc = hex_color ('#63c74dff')
		a.lc = hex_color ('#265c42ff')
		a.oc = hex_color ('#000000ff')
		a.oct = hex_color ('#ffffffff')
	end

	if theme == 3 then
		a.bg = hex_color ('#000000ff')
		a.tc = hex_color ('#c0cbdcff')
		a.lc = hex_color ('#8b9bb4ff')
		a.oc = hex_color ('#000000ff')
		a.oct = hex_color ('#ffffffff')
	end
	

	coord_screen2true (a)
	bubble[id] = a


end

function alt_add (x,y,i,xt)

	local str = ""
	local c = 0
	local it = {}

	for k,v in ipairs(i) do
		it[v.i] = (it[v.i] or 0) + 1
	end

	for k,v in pairs(it) do
		if game.altitem==nil or game.altitem==k then

			local name = draw_itemname ({i = k})
			--msg.item[k].name

			if v>1 then
					str = str..name.." ×"..v.."\n"
				else
					str = str..name.."\n"
				end
			c = c + 1
		end
	end

	local l = c * 12

	if xt%2 == 1 then
		y = y - c*12 - (xt%3)*12
		l = l + (xt%3)*12
	else
		y = y + 12 + (xt%3)*6
		--l = l - (xt%3)*12
	end

	if str~="" then
		return {x = x+16, y = y+15, txt = text_color(str), l = l}
	end
end

function alttext ()

	for i,v in ipairs(game.alttexts) do
		love.graphics.setFont(font2)
		local txt = "stone x 2"
		love.graphics.setColor (0,0,0,1)

		v.x = v.x + 5
		love.graphics.printf (v.txt, v.x-1, v.y-1,500)
		love.graphics.printf (v.txt, v.x, v.y-1,500)
		love.graphics.printf (v.txt, v.x+1, v.y-1,500)
		love.graphics.printf (v.txt, v.x-1, v.y,500)
		love.graphics.printf (v.txt, v.x+1, v.y,500)
		love.graphics.printf (v.txt, v.x-1, v.y+1,500)
		love.graphics.printf (v.txt, v.x, v.y+1,500)
		love.graphics.printf (v.txt, v.x+1, v.y+1,500)
		v.x = v.x - 5

		
		love.graphics.setLineWidth (1)
		love.graphics.line (v.x+1,v.y,v.x,v.y+v.l)

		love.graphics.setColor (1,1,1,0.5)
		love.graphics.line (v.x,v.y,v.x,v.y+v.l)

		love.graphics.setColor (1,1,1,1)

		love.graphics.printf (v.txt, 5+v.x, v.y,500)
	end

end

function draw_textbubble ()
	
	local hs

	for k,b in pairs(bubble) do
		hs = true
		coord_true2screen (b)
		
		--love.graphics.setWireframe (true)
		love.graphics.setLineStyle ('rough')
		love.graphics.setLineWidth (1)

		local p = {}
		i = 1

		while i<#b.p do
			table.insert (p, b.p[i]+b.x)
			table.insert (p, b.p[i+1]+b.y)
			i = i + 2
		end

		love.graphics.setColor (unpack(b.bg))
		love.graphics.polygon ("fill", p)

		love.graphics.setColor (unpack(b.lc))
		love.graphics.polygon ("line", p)

		love.graphics.setColor (unpack(b.tc))
		love.graphics.draw (b.textbox, math.floor(b.x+b.pad), math.floor(b.y+b.pad))


		if b.outt then
			love.graphics.setColor (unpack(b.oct))
			love.graphics.draw (b.textbox, b.x+b.pad-1, b.y+b.pad-1)
			love.graphics.draw (b.textbox, b.x+b.pad, b.y+b.pad-1)
			love.graphics.draw (b.textbox, b.x+b.pad+1, b.y+b.pad-1)
			love.graphics.draw (b.textbox, b.x+b.pad-1, b.y+b.pad)
			love.graphics.draw (b.textbox, b.x+b.pad+1, b.y+b.pad)
			love.graphics.draw (b.textbox, b.x+b.pad-1, b.y+b.pad+1)
			love.graphics.draw (b.textbox, b.x+b.pad, b.y+b.pad+1)
			love.graphics.draw (b.textbox, b.x+b.pad+1, b.y+b.pad+1)
			love.graphics.setColor (unpack(b.tc))
			love.graphics.draw (b.textbox, b.x+b.pad, b.y+b.pad)
		end

		love.graphics.setColor (1,1,1,1)

		if b.ttl<game.dt then
			bubble[k] = nil
		end
	end

end

--shame and horror


function message (text,repl)
	if repl then
		for k,v in pairs(repl) do
			text = string.gsub(text, "_"..k.."_", v)
		end
	end

	return text
end

function textwall (text, tmp, repl)
	
	--if (game.oldtextwall or "")==text then return end
	--game.oldtextwall = text

	text = message(text, repl)

	-- The host simulates the guest in the same Lua state. Its log belongs to
	-- the remote player's HUD, while text_canvas belongs to the host window.
	-- Send the raw, localised line as a reliable actor event and do not redraw
	-- the host canvas from inside the guest actor context.
	if not NETWORK_TEXT_EVENT_APPLY and ACTIVE_ACTOR_ID == "guest"
		and multiplayer and multiplayer.role == "host" then
		if multiplayer_queue_text_event then
			multiplayer_queue_text_event(text, tmp, ACTIVE_ACTOR_ID)
		end
		return true
	end

	text = text_color ("{#ffffffff}"..text)

	if #text == 1 then
		table.insert (text,1, {1,1,1,1}) -- make first line white again
	end

	if pl.logold then
		table.remove (pl.log)
	end

	table.insert (pl.log,text)
	if #pl.log>60 then
		table.remove (pl.log,1)
		pl.logchange = true
	end

	pl.logold = tmp

	draw_textwall ()

end

oldprint = print
print = textwall


function draw_textwall ()

	--oldprint (dumpvar (pl.log))
	local t = {}

	for k,v in pairs(pl.log) do
		table.inserts (t,v)
		table.insert (t,"\n")
	end
	
	textlog:setf (t,vi.textwall_w,'left')
	local h = textlog:getHeight()
	local w = textlog:getWidth()

	if (pl.logoffset+vi.textwall_h-h)>0 then
		pl.logoffset = -1*(vi.textwall_h-h)
	end

	if (pl.logoffset<0) then
		pl.logoffset = 0
	end

	love.graphics.setCanvas(text_canvas)
	love.graphics.clear ()

	if h<vi.textwall_h then
		love.graphics.draw (textlog, 0, 0)
	else
		love.graphics.draw (textlog, 0, vi.textwall_h-h+pl.logoffset)
	end

	love.graphics.setCanvas()

end


function hex_color(str)

	local all = {}
	local f,r,g,b,a
	f,_,r,g,b,a = str:find('^#(%x%x)(%x%x)(%x%x)(%x%x)')
	table.insert (all,{tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255,tonumber(a,16)/255})
	
	if #all == 0 then
		f,_,r,g,b,a = str:find('^#(%x%x)(%x%x)(%x%x)')
		table.insert (all,{tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255,1})
	end

	return all

end

function text_color(str)

	local all = {}
	local s = string.split (str, "[^{^}]*")
	for i,v in ipairs(s) do
		if v ~= "" then

				local f,r,g,b,a
				f,_,r,g,b,a = v:find('^#(%x%x)(%x%x)(%x%x)(%x%x)')

				if not f then
					table.insert (all,v)
				else
					table.insert (all,{tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255,tonumber(a,16)/255})
				end
 
		end

	end

	return all

end


function draw_minimap ()

   	love.graphics.setCanvas(minimap_canvas)
	love.graphics.clear ()

	local size = 1

    for x = 1, cf.wmax do
        for y = 1, cf.wmax do

 		local f = 1
 		if world[y][x].b == 0 then
			f = 1
        else
            f = 0
        end

        --f = world[y][x].b

   
            love.graphics.setColor ( f, f, f, 1 )
            love.graphics.points (x,y)
            love.graphics.setColor ( 1, 1, 1, 1 )
        end
    end

    love.graphics.setCanvas()


end

function draw_dig_progress (x,y,pc)

	if pl.digxt == nil then return end

	local r = tile2px (x,y)
	x = r.x
	y = r.y

	local d = {-32, -32, -32, -32}
	local pc = math.floor (pc * 1.28)
	pc = 128 - pc
	
	local pcl = math.ceil (pc / 32)
	d[pcl] = pc-pcl*32 
	for i=1,pcl-1 do
		d[i]=0
	end

	table.insert (d,d[1])
	table.insert (d,d[2])
	table.insert (d,d[3])
	--table.insert (d,d[4])

	love.graphics.setLineWidth (1+math.atan(pc/32))

	love.graphics.setColor (0,0,0,100)
	--love.graphics.rectangle("line", x, y, 32, 32)


	if pl.digcant then
		love.graphics.setColor (0.9,0.1,0.1,1)
	else
		love.graphics.setColor (0.6-pc*0.01,0.6+pc*0.01,0,1)
	end


	local f = pl.flip if pl.digstart == 1 then f = f * -1 end
	if f == -1 then

	love.graphics.line(x+d[1+pl.digstart]+32, y, x+32, y)
	love.graphics.line(x+32, y+d[2+pl.digstart]+32, x+32, y+32)
	love.graphics.line(x+32-d[3+pl.digstart]-32, y+32, x, y+32)
	love.graphics.line(x, y+32-d[4+pl.digstart]-32, x, y)

	else

	love.graphics.line(x, y, x-d[1+pl.digstart], y)
	love.graphics.line(x, y+d[2+pl.digstart]+32, x, y+32)
	love.graphics.line(x+d[3+pl.digstart]+32, y+32, x+32, y+32)
	love.graphics.line(x+32, y+32-d[4+pl.digstart]-32, x+32, y)	
	
	
	end
	
	love.graphics.setLineWidth (1)

	--love.graphics.rectangle("line", x, y, 3, 3)


end

function draw_cols()
	for i,v in pairs(colliders) do
		love.graphics.rectangle ('line', v.x-vi.x,v.y - vi.y, v.w-v.x, v.h - v.y)
	end
end

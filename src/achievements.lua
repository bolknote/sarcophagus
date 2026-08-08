--[[

2. kill X
3. eat X
	-x
	-avg cal
4. craft X
6. growup




-- transform # items
-- going nowhere



--]]

achi = {}


function achi_reset ()

	for i,v in ipairs(achi) do
		if v.onelife then
			pl.achi[i].cnt = 0
			pl.achi[i].pc = 0
		end
	end

end


function achi_ini ()

	pl.achi = pl.achi or {}

	pl.achi.crafted = pl.achi.crafted or {}
	pl.achi.ate = pl.achi.ate or {}
	
	for i,v in ipairs(achi) do
		pl.achi[i] = pl.achi[i] or {}
	end

end

function achi_trigger (name,id,num,num2)

	for i,v in ipairs(achi) do
		if v[name] and pl.achi[i].fail==nil and pl.achi[i].fail==nil then

			v[name] (id,num,num2)

		end
	end

end

function achi_add (k,n)
	pl.achi[k].cnt = (pl.achi[k].cnt or 0) + n
	achi_check (k)
end


function achi_set (k,n)
	pl.achi[k].cnt = n
	achi_check (k)
end


--for i,v in pairs(achi) do

function achi_check (i)
	
	if pl.achi[i].done==nil then

		if achi[i].check then
			achi[i].check ()
		end

		local cnt = pl.achi[i].cnt or 0
		pl.achi[i].pc = cnt/achi[i].max

		if pl.achi[i].done then
			pl.achi[i].pc = 1
		end

		if pl.achi[i].fail then
			pl.achi[i].pc = 0
		end

		if (pl.achi[i].cnt or 0)>=achi[i].max and pl.achi[i].fail==nil then --completed
			achi_done (i)
		end

	end

end


function achi_done (i)

	if pl.achi[i].done then return end

	sound_add ('buff',39)
	pl.achi[i].done = true
	if achi[i].reward then
		achi[i].reward ()
	end

	game.achipage = achi[i].t[1]

	textwall (msg.achi.gui[2],false)
	textwall (msg.achi.gui[1],false,{[1] = msg.achi[i].name, [2] = msg.achi[i].desc})

end




function achi_pc (i)


	if pl.achi[i].done then
		return msg.achi.gui[3]
	end

	if pl.achi[i].fail then
		return msg.achi.gui[4]
	end

	local pc = pl.achi[i].pc or 0

	local str = draw_progress (pc, achi[i].max)
	if achi[i].max and achi[i].max>1 and achi[i].nonumbers==nil then

		--str = str.."{#8b9bb4ff} "..math.floor (pc*100).."%"
		str = str.."{#8b9bb4ff} ("..math.ceil(pl.achi[i].cnt or 0).."/"..achi[i].max..")"

	end
	return str

end



function achi_str ()

	local str  = {}
	local c1 = 0
	local c2 = 0


	for i,v in pairs(achi) do

		if in_array (v.t, game.achipage) then

			c1 = c1 + 1
			local sad = {}

			sad = {}
			sad.k = v.k
			sad.str = ""
	--▮■
			if pl.achi[i].done then
				sad.str = sad.str.."{#63c74dff}▮ {#e8b796ff}"
				c2 = c2 + 1
			else
				sad.str = sad.str.."{#3a4466ff}■ {#e8b796ff}"
			end


			sad.str = sad.str..msg.achi[i].name.."{#ffffffff}\n"

			if pl.achi[i] and pl.achi[i].done then
				sad.str = sad.str.."{#3a4466ff}  {#c0cbdcff}"..msg.achi[i].desc.."{#ffffffff}\n"
			else
				sad.str = sad.str.."{#3a4466ff}  {#8b9bb4ff}"..msg.achi[i].desc.."{#ffffffff}\n"
			end

			if achi[i].reward then
				if pl.achi[i].done then
					sad.str = sad.str.."{#3a4466ff}├─{#f6757aff}"..msg.achi.gui[8].."\n"
				else
					sad.str = sad.str.."{#3a4466ff}├─{#f6757aff}"..msg.achi.gui[7].."\n"
				end
			end

			sad.str = sad.str.."{#3a4466ff}│ "..achi_pc (i).."\n{#3a4466ff}└────────────────────────────────────────────────{#ffffffff}"

			table.insert (str,sad)

		end

	end

	table.sort (str, function (k1,k2) return k1.k<k2.k end)

	--rs = dumpvar (str)

	local rs = ""
	local rs2 = ""

	for i,v in pairs(str) do
		--if i%2==0 then
		if i>7 then
			rs2 = rs2..v.str..'\n'
		else
			rs = rs..v.str..'\n'
		end
	end

	rs = msg.achi.gui[5].."{#63c74dff}"..msg.achitypes[game.achipage].." {#ffffffff}("..c2.."/"..c1..")\n\n"..rs
	rs2 = msg.achi.gui[6].."\n\n"..rs2

	rs = text_color (rs)
	rs2 = text_color (rs2)

	return rs,rs2


end


achi[1] =
{
	t = {1,5},
	k = 10,
	onelife = true,
	max = 1,
	check = nil, --periodically check
	add = nil,
	reward = nil,
	on_unlock = function (id,n,this)
		if id==6 then
			achi_set (1,1)
		end
	end,

	reward = function ()
		inv_add (item_make(23))
	end,

	-- on_dug = function (id,n,this)
	-- 	if id==5 then
	-- 		achi_add (this,1)
	-- 	end
	-- end
}


achi[2] =
{
	t = {1},
	k = 20,
	max = 3,
	nonumbers = 1,
	reward = function ()
		inv_add (item_make(28))
		inv_add (item_make(347))
	end
}


achi[3] =
{
	t = {1},
	k = 30,
	onelife = true,
	max = 1,
	check = function ()
		--achi_set (3, game.time)
	end,
	on_craft = function (id)

		pl.achi.crafted[id] = (pl.achi.crafted[id] or 0) + 1
		if id=='i10' then
			achi_done (3)
		end

	end
}


achi[4] =
{
	t = {3},
	k = 40,
	onelife = true,
	max = time.d,
	nonumbers = 1,
	tick = function ()
		achi_set (4, game.time)
	end,
	check = function ()
		if (pl.deaths or 0)>0 and pl.achi[4].done==nil then
			pl.achi[4].fail = true
		end
	end,
	reward = function ()
		inv_add (item_make(340))
	end
}


achi[5] =
{
	t = {1},
	k = 50,
	onelife = true,
	max = 1,
	on_craft = function (id)

		if id=='b34' then
			achi_done (5)
		end

	end
}


achi[6] =
{
	t = {3},
	k = 60,
	onelife = true,
	max = 1000,
	on_hit = function (id)
		achi_add (6,id)
	end,
	reward = function ()
		inv_add (item_make(338))
	end
}


achi[7] =
{
	t = {1},
	k = 70,
	max = 1,
	on_craft = function (id)

		if id=='i30' then
			achi_done (7)
		end

	end
}

achi[8] =
{
	t = {1},
	k = 80,
	max = 1,
	reward = nil,
	on_unlock = function (id,n,this)
		if id==33 then
			achi_set (8,1)
		end
	end,
	reward = function ()
		inv_add (item_make(327))
		inv_add (item_make(328))
	end

}

achi[9] =
{
	t = {5},
	k = 25,
	max = 2,
	nonumbers = 1,
	on_tip = function (id,n,this)
		if id=='i183' then
			achi_set (9,2)
		end

		if id=='i184' then
			achi_set (9,1)
		end
	end,

}

achi[10] =
{
	t = {3},
	nonumbers = 1,
	k = 100,
	max = 130,
}

achi[11] =
{
	t = {4},
	k = 110,
	max = 100,
}

achi[12] =
{
	t = {3},
	k = 120,
	onelife = true,
	max = 30,
	reward = nil,
	on_tip = function (id,n,this)
		achi_add (12,1)
	end,
}


achi[13] =
{
	t = {3},
	k = 130,
	max = 150,
	reward = nil,
	tick = function (id,n,this)
		local c = tablecount (pl.unlock_i)
		achi_set (13,c)
	end,

	reward = function ()
		inv_add (item_make(345))
	end
}


achi[14] =
{
	t = {3},
	k = 140,
	max = 100,
	check = function ()
		--achi_set (3, game.time)
	end,
	on_craft = function (id)

		local c = tablecount (pl.achi.crafted)
		achi_set (14,c)

	end
}


achi[15] =
{
	t = {3},
	k = 150,
	max = 50,
	check = function ()
		--achi_set (3, game.time)
	end,
	on_eat = function (id,cal)

		pl.achi.ate[id] = (pl.achi.ate[id] or 0) + 1
		local c = tablecount (pl.achi.ate)
		achi_set (15,c)

	end
}

achi[16] =
{
	t = {2},
	k = 160,
	max = 7,
	on_craft = function (id)

		if id=='b38' then
			achi_add (16,1)
		end

	end
}


achi[17] =
{
	t = {2},
	k = 170,
	max = 12,
	on_dug = function (id,n,this)
		if id==60 then
			achi_add (17,1)
		end
	end
}

achi[18] =
{
	t = {1},
	k = 180,
	max = 1,
	on_eat = function (id,cal)

		if id==116 or id==119 then
			achi_done (18)
		end

	end
}


achi[19] =
{
	t = {2},
	k = 190,
	max = 2,
	nonumbers = 1,
	on_unlock = function (id,n,this)
		
		achi_set (19,0)

		if pl.unlock_i[48] then
			achi_add (19,1)
		end

		if pl.unlock_i[51] then
			achi_add (19,1)
		end

	end,

	-- on_dug = function (id,n,this)
	-- 	if id==5 then
	-- 		achi_add (this,1)
	-- 	end
	-- end
}


achi[20] =
{
	t = {2},
	k = 200,
	max = 3,
	on_craft = function (id)

		if id=='b124' then
			achi_add (20,1)
		end

	end,
	reward = function ()
		inv_add (item_make(339))
	end
}

achi[21] =
{
	t = {2},
	k = 210,
	max = 2,
	on_craft = function (id)

		if id=='b183' then
			achi_add (21,1)
		end

	end,
	reward = function ()
		inv_add (item_make(341))
	end
}

achi[22] =
{
	t = {2},
	k = 220,
	max = 1,
	on_craft = function (id)

		if id=='i150' then
			achi_add (22,1)
		end

	end,
	reward = function ()
		inv_add (item_make(158))
	end
}

achi[23] =
{
	t = {4},
	k = 230,
	max = 1,
	on_unlock = function (id,n,this)
		if id==122 then
			achi_set (23,1)
		end
	end,

	-- on_dug = function (id,n,this)
	-- 	if id==5 then
	-- 		achi_add (this,1)
	-- 	end
	-- end
}

achi[24] =
{
	t = {2},
	k = 230,
	max = 20,

	reward = function ()
		inv_add (item_make(327))
		inv_add (item_make(327))
		inv_add (item_make(327))
	end

}


achi[25] =
{
	t = {5},
	k = 1000,
	max = 1,
	on_unlock = function (id,n,this)
		if id==290 then
			achi_set (25,1)
		end
	end,

	-- on_dug = function (id,n,this)
	-- 	if id==5 then
	-- 		achi_add (this,1)
	-- 	end
	-- end
}


achi[26] =
{
	t = {4},
	k = 260,
	max = 100,
}

achi[27] =
{
	t = {5},
	k = 270,
	max = 7,

	reward = function ()
		inv_add (item_make(319))
		inv_add (item_make(311))
	end

}

achi[28] =
{
	t = {5},
	k = 280,
	max = 30,

	reward = function ()
		inv_add (item_make(333))
		inv_add (item_make(333))
	end

}



achi[29] =
{
	t = {4},
	k = 290,
	max = 30,

	reward = function ()
		inv_add (item_make(160))
		inv_add (item_make(160))
		inv_add (item_make(160))
		inv_add (item_make(160))
	end

}


achi[30] =
{
	t = {4},
	k = 300,
	max = 20,

	on_eat = function (id,cal, r)

		if r>=10 then
			achi_add (30,1)
		else
			achi_set (30,0)
		end

	end,

	reward = function ()
		inv_add (item_make(237))
		inv_add (item_make(199))
		inv_add (item_make(258))
	end
}

achi[31] =
{
	t = {5},
	k = 310,
	max = 20,

	reward = function ()
		inv_add (item_make(358))
		inv_add (item_make(365))
		inv_add (item_make(275))
		inv_add (item_make(38))
	end

}

achi[32] =
{
	t = {4},
	k = 320,
	max = 1,

	reward = function ()
		inv_add (item_make(183))
		inv_add (item_make(183))
		inv_add (item_make(183))
	end

}

achi[33] =
{
	t = {4},
	k = 330,
	max = 666,

	reward = function ()
		inv_add (item_make(183))
		inv_add (item_make(183))
		inv_add (item_make(183))
	end

}

achi[34] =
{
	t = {6},
	k = 340,
	max = 1,
}

achi[35] =
{
	t = {6},
	k = 350,
	max = 1,

	reward = function ()
		inv_add (item_make(80))
	end
}

achi[36] =
{
	t = {6},
	k = 360,
	max = 1,

	reward = function ()
		inv_add (item_make(358))
		inv_add (item_make(358))
	end,
}

achi[37] =
{
	t = {6},
	k = 370,
	max = 1,

	reward = function ()
		inv_add (item_make(358))
		inv_add (item_make(358))
	end,
}

achi[38] =
{
	t = {6},
	k = 380,
	max = 1,
}

achi[39] =
{
	t = {6},
	k = 390,
	max = 1,
}

achi[40] =
{
	t = {6},
	k = 400,
	max = 1,
}

achi[41] =
{
	t = {5},
	k = 410,
	max = 10,

	reward = function ()
		inv_add (item_make(21))
		inv_add (item_make(21))
		inv_add (item_make(21))
		inv_add (item_make(21))
	end

}

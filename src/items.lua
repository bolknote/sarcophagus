





function telltime (t)


	times = {}

	for i,v in ipairs(time.all) do
		local t2 = math.floor (t / v)
		t = t - t2*v
		times[i] = t2
	end

	--times[7] = t

	--dump (times)

	--return game.time
	return message(msg.ui.time, {
		[1] = string.format("%02d", times[1]),
		[2] = string.format("%02d", times[2]),
		[3] = string.format("%02d", times[3]),
		[4] = string.format("%02d", times[4]),
	})

end




item = {}


--FOOD
-------------------------------------------------------------


item[198] = { name = 'Sugar',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
transformi = 235,
transformpower = 20,
hcalories = 15,
}

item[201] = { name = 'Meat dolma',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0, 
laydie = 0,
burydie = 0,
diet = {'protein','veggies','freezable'},
calories = 10
}

item[202] = { name = 'Rice flour',
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
hcalories = 30,
}

item[203] = { name = 'Corn flour',
f_burn = 0.3,
f_heat = 700,
f_start = 100,
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
hcalories = 30,
}

item[204] = { name = 'Cooked rice',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'carbs'},
calories = 25,
oneat = function ()
	inv_add(item_make(182))
end
}

item[200] = { name = 'Sarma',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'carbs','veggies','freezable'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
end
}

item[266] = { name = 'Spider omelette',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'exotic','veggies'},
calories = 40,
oneat = function ()
	inv_add(item_make(182))
	buff_add (8)
end
}



-- fish dishes
item[291] = { name = 'Spicy fish stew',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'fish','freezable'},
calories = 60,
oneat = function ()
	inv_add(item_make(182))
	stat_recovery ('heat',20)
end
}

item[292] = { name = 'Grilled fish',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'fish','veggies'},
calories = 36,
oneat = function ()
	inv_add(item_make(182))
end
}


item[293] = { name = 'Sushi',
ttl  = time.h*3,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'carbs','fish'},
calories = 65,
oneat = function ()
	inv_add(item_make(182))
end
}

item[294] = { name = "Fisherman's pie",
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'carbs','fish','freezable'},
calories = 60,
oneat = function ()
	inv_add(item_make(182))
end
}

item[295] = { name = "Fish with noodles",
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'fish','carbs'},
calories = 65,
oneat = function ()
	inv_add(item_make(182))
	stat_recovery ('heat',20)
end
}

item[296] = { name = "Four weeds salad",
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'exotic'},
calories = 45,
oneat = function ()
	inv_add(item_make(182))
end
}

item[297] = { name = "Seaweed salad",
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'exotic'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
end
}


item[298] = { name = "Sesame seeds bread",
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {},
invdie = 0, 
laydie = 0,
burydie = 0,
diet = {'carbs','exotic'},
calories = 35,
oneat = function ()
	--inv_add(item_make(182))
end
}

item[205] = { name = 'Golubtsi',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'protein','veggies','freezable'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
end
}



item[206] = { name = 'Fresh Tomato Salad',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'veggies'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
end
}

item[207] = { name = 'Wood ash',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
}

item[211] = { name = 'Bin (apple cidre)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 165,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[352] = { name = 'Bin (vinegar)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 167,
laydie = 0,
burydie = 0,
invdie = 0, 
}

-- PICKLED

item[212] = { name = 'Apple cidre',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs'},
calories = 25,
oneat = function ()
	inv_add(item_make(210))
	stat_recovery ("water",30)
	buff_add (21)
end
}


item[213] = { name = 'Pickled carrot',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 210,
burydie = 210,
invdie = 210, 
diet = {'veggies'},
calories = 45,
oneat = function ()
	inv_add(item_make(210))
	stat_spend ("water",20)
end
}

item[262] = { name = 'Pickled chard',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 210,
burydie = 210,
invdie = 210, 
diet = {'veggies'},
calories = 30,
oneat = function ()
	inv_add(item_make(210))
	stat_spend ("water",20)
end
}

item[263] = { name = 'Power shard',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 115,
burydie = 115,
invdie = 115, 
transformi = 115,
transformpower = -7,
}


item[264] = { name = 'Stone pouch (empty)',
equip = 'b',
ttl  = time.y,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0, 

onuse = function (x,y,inv)

	local find = 31
	local to = 265

	if inv_find (find) or inv_ground_find_i(x,y,find) then
		pl.inv[pl.invselect] = item_make (to)
		pl.inv[inv].t=0

		local cnt = 0
		while pl.inv[inv].t<10 and cnt<20 do
			cnt = cnt + 1
			if inv_find(find,0) then
				pl.inv[inv].t=pl.inv[inv].t+1
			end
		end

		local cnt = 0
		while pl.inv[inv].t<10 and cnt<20 do
			cnt = cnt +1
			local i = inv_ground_find_i(x,y,find) 
			if i then
				pl.inv[inv].t=pl.inv[inv].t+1
				inv_ground_remove (x,y,i)
			end
		end

	end

	pl.invselect = inv


end,

}

item[265] = { name = 'Stone pouch',
equip = 'b',
ttl  = 10,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0, 

onthrow = function (inv)
	pl.inv[inv].t = pl.inv[inv].t - 1
	if pl.inv[inv].t <= 0 then
		pl.inv[inv] = item_make (264)
	end
	return item_make (31)
end,

onuse = function (x,y,inv)
	while pl.inv[inv].t > 0 do
		pl.inv[inv].t = pl.inv[inv].t - 1
		inv_add (item_make(31))
	end
	pl.inv[inv] = item_make (264)
	pl.invselect = inv
end,

throw = 1.2,
proj = 3,
dmg = 4,

}





item[299] = { name = 'Empty can',
ttl  = time.y,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0, 

onuse = function (x,y,inv)

	local find = 6
	local to = 300
	local max = 5

	if inv_find (find) or inv_ground_find_i(x,y,find) then

		if pl.inv[pl.invselect].i~=to then
			pl.inv[pl.invselect] = item_make (to)
			pl.inv[inv].t=0
		end

		local cnt = 0
		while pl.inv[inv].t<max and cnt<20 do
			cnt = cnt + 1
			if inv_find(find,0) then
				pl.inv[inv].t=pl.inv[inv].t+1
			end
		end

		local cnt = 0
		while pl.inv[inv].t<max and cnt<20 do
			cnt = cnt +1
			local i = inv_ground_find_i(x,y,find) 
			if i then
				pl.inv[inv].t=pl.inv[inv].t+1
				inv_ground_remove (x,y,i)
			end
		end

	end

	pl.invselect = inv

	--dump (pl.inv[inv])


end,

}

item[300] = { name = 'Can of worms',
ttl  = 5,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 299,
burydie = 299,
invdie = 299, 

onuse = item[299].onuse,

onempty = function (x,y,inv)

	if pl.inv[inv].t > 0 then
		pl.inv[inv].t = pl.inv[inv].t - 1
		inv_add (item_make(6))
	end

	if pl.inv[inv].t <= 0 then
		pl.inv[inv] = item_make (299)
		pl.invselect = inv
	end

end,

transformi = 164,
transformpower = 10,

}

item[214] = { name = 'Pickled tomatoes',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 210,
burydie = 210,
invdie = 210, 
diet = {'fruits'},
calories = 25,
oneat = function ()
	inv_add(item_make(210))
	stat_spend ("water",20)
end
}



item[301] = { name = 'Craftable mass',
ttl  = 5,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[302] = { name = 'Something to inspect',
ttl  = 5,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0, 
}


item[214] = { name = 'Pickled tomatoes',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 210,
burydie = 210,
invdie = 210, 
diet = {'fruits'},
calories = 25,
oneat = function ()
	inv_add(item_make(210))
	stat_spend ("water",20)
end
}

item[215] = { name = 'Pickled worms',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 210,
burydie = 210,
invdie = 210,  
diet = {'fat'},
calories = 25,
oneat = function ()
	inv_add(item_make(210))
	stat_spend ("water",20)
end
}


item[216] = { name = 'Pickled shrooms',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 210,
burydie = 210,
invdie = 210, 
diet = {'exotic'},
calories = 15,
oneat = function ()
	inv_add(item_make(210))
	stat_spend ("water",20)
	buff_add (4)
end
}

item[218] = { name = 'Bogberry jam',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 210,
burydie = 210,
invdie = 210, 
diet = {'fruits','carbs'},
calories = 30,
oneat = function ()
	inv_add(item_make(210))
	buff_remove (2)
	pl.shit[112] = 1
end
}


item[331] = { name = 'Broth',
ttl  = time.d*4,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'protein','freezable'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
	buff_remove (15)
end
}


item[219] = { name = 'Pumpkin & beans soup',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'veggies','protein','freezable'},
calories = 50,
oneat = function ()
	inv_add(item_make(182))
	buff_add (10)
end
}

item[241] = { name = 'Corn and tomato soup',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'carbs','fruits','freezable'},
calories = 50,
oneat = function ()
	inv_add(item_make(182))
end
}


item[242] = { name = 'Refried beans',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'protein'},
calories = 25,
oneat = function ()
	inv_add(item_make(182))
	buff_add (10)
end
}

item[243] = { name = 'Chilli beans',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'protein'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
	stat_recovery ('heat',20)
	buff_add (10)
end
}

item[244] = { name = 'Cooked beans',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'protein'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
	buff_add (10)
end
}

item[223] = { name = 'Vegan soup', --pumpkin carrot potatos
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'veggies','veggies','freezable'},
calories = 45,
oneat = function ()
	inv_add(item_make(182))
end
}


item[249] = { name = 'Chili con carne', --pumpkin carrot potatos
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'protein','veggies','freezable'},
calories = 45,
oneat = function ()
	inv_add(item_make(182))
	stat_recovery ('heat',20)
	buff_add (10)
	buff_add (10,'add')
	buff_add (10,'add')
end
}

item[250] = { name = 'Crispy breaded worms',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'fat','carbs'},
calories = 40,
oneat = function ()
	inv_add(item_make(182))
end
}

item[251] = { name = 'Deep fried worms',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'fat'},
calories = 40,
oneat = function ()
	inv_add(item_make(182))
end
}

item[252] = { name = "Worms'n'noodles",
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'fat','carbs'},
calories = 45,
oneat = function ()
	inv_add(item_make(182))
end
}

item[220] = { name = 'Grilled pumpkin',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'veggies'},
calories = 35,
}

item[240] = { name = 'Grilled corn',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs','freezable'},
calories = 30,
}

item[221] = { name = 'Candied pumpkin',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs','sugar'},
calories = 7,
}

item[248] = { name = 'Sweet pitha',
ttl  = time.w*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs','sugar'},
calories = 5,
}

item[338] = { name = 'Tough cookie',
ttl  = time.w*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs','sugar'},
calories = 50,
}

item[339] = { name = 'Instant chest',
put = 124,
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[341] = { name = 'Playperson magazine',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
onuse = function (x,y)
	player_rest (x,y,1.1,0.5)
	achi_set (32,1)
end,
}


item[344] = { name = "Cry'o'genic device",
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
onuse = function (x,y,inv)
	local time = love.math.random (20,200)
	player_rest (x,y,0,time)
	pl.inv[inv] = item_make (64)
end,
}

item[253] = { name = 'Fruit jelly',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'fat','fruits'},
calories = 40,
}


item[254] = { name = 'Steak',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'protein','fat','freezable'},
calories = 35,
}

item[255] = { name = 'Quesadilla',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs','fat'},
calories = 42,
}

item[222] = { name = 'Pumpkin pie',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs', 'veggies'},
calories = 15,
}


item[258] = { name = 'Salsa',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 210,
burydie = 210,
invdie = 210, 

tool = {
	crafthit = 5,
	salsa = 1,
},

oneat = function ()
	stat_recovery ('heat',20)
	inv_add(item_make(210))
end

}


item[256] = { name = 'Vegan burrito',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'veggies', 'carbs','freezable'},
calories = 70,
oneat = function ()
	stat_recovery ('heat',5)
	buff_add (10)
end
}


item[257] = { name = 'Burrito',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'protein', 'carbs','freezable'},
calories = 70,
oneat = function ()
	stat_recovery ('heat',5)
	buff_add (10)
end
}



--carrot
item[224] = { name = 'Carrot & apple salad',
ttl  = time.h,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'veggies','fruits'},
calories = 50,
oneat = function ()
	inv_add(item_make(182))
	buff_add (21)
end
}

item[225] = { name = 'Vegeterian pilaf',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'carbs','veggies'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
end
}

item[226] = { name = 'Pilaf',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'carbs','protein','freezable'},
calories = 30,
oneat = function ()
	inv_add(item_make(182))
end
}

item[227] = { name = 'Grilled carrot',
ttl  = time.h*5,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'veggies'},
calories = 25,
}


item[228] = { name = 'Beef stew',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'protein','veggies','freezable'},
calories = 40,
oneat = function ()
	inv_add(item_make(182))
end
}



--apple

item[229] = { name = 'Apple nut salad',
ttl  = time.h*5,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'fruits','fat'},
calories = 40,
oneat = function ()
	inv_add(item_make(182))
	buff_add (21)
end
}

item[230] = { name = 'Apple pie',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs','fruits'},
calories = 30,

oneat = function ()
	buff_add (21)
end

}

item[231] = { name = 'Fruit salad',
ttl  = time.h*5,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'fruits','exotic'},
calories = 50,
oneat = function ()
	inv_add(item_make(182))
	buff_remove (2)
end
}

item[232] = { name = 'Apple stew', --rice meat apple
ttl  = time.h*5,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'protein','fruits','freezable'},
calories = 40,
oneat = function ()
	inv_add(item_make(182))
	buff_add (21)
end
}


item[233] = { name = 'Giant chilli',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 234,
burydie = 234,
invdie = 234, 
}


item[234] = { name = 'Dry chilli',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[236] = { name = 'Chilli powder',
ttl  = time.m*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
hcalories = 10,
}


item[237] = { name = 'Ketchup',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 210,
burydie = 210,
invdie = 210, 


onuse = function (x,y,inv)
	if pl.buffs[11]==nil then
		buff_add (11)
		pl.inv[inv].t = pl.inv[inv].t - 10
		pl.yo = 0 --game.moved
	end
end,

}


item[199] = { name = 'Vinegar',
ttl  = 1000,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
tool = {
	crafthit = 50,
	vinegar = 1,
},
hcalories = -10
}


item[238] = { name = 'Tortilla', --rice meat apple
ttl  = time.w*2,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs','freezable'},
calories = 30,
}

item[246] = { name = 'Tortilla chips', --rice meat apple
ttl  = time.w*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'carbs'},
calories = 7,
}

item[247] = { name = 'Nachos', --rice meat apple
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'protein','carbs'},
calories = 12,
oneat = function ()
	stat_recovery ('heat',10)
	buff_add (10)
end
}

item[245] = { name = 'Tortilla soup',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'carbs','veggies','freezable'},
calories = 35,
oneat = function ()
	inv_add(item_make(182))
	stat_recovery ('heat',20)
end
}


item[260] = { name = 'Laghman',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 182,
burydie = 182,
invdie = 182, 
diet = {'carbs','protein'},
calories = 65,
oneat = function ()
	inv_add(item_make(182))
	stat_recovery ('heat',20)
end
}


item[261] = { name = 'Chebureki',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'fat','protein'},
calories = 30,
}


item[239] = { name = 'Rice noodles', --rice meat apple
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
hcalories = 30,
}

item[282] = { name = 'Crunchy spider legs',
ttl  = time.d*2,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 0,
burydie = 0,
invdie = 0, 
diet = {'exotic','fat'},
calories = 45,
oneat = function ()
	buff_add (8)
end
}


--SEEDS
-------------------------------------------------------------

item[235] = { name = 'Chilli seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
ongrounddie = nil,
onburydie = function (x,y) 
	growup (x,y,170) 
	fertilize (x,y,-10)
end,
}

item[196] = { name = 'Sugar beet seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
ongrounddie = nil,
onburydie = function (x,y) 
	growup (x,y,157) 
	fertilize (x,y,-10)
end,
}

item[197] = { name = 'Sugar beet',
ttl  = time.m, 
tti = 1,
ttg = 10, 
ttb = 1000, 
bury = {[102] = 1, [12] = 2, [13] = 3},
autobury = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) 
	growup (x,y,157) 
	writemap (x,y-1, 2, 'stage')
	fertilize (x,y,-10)
end,
}

item[1] = { name = 'Glowing seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 4,
ongrounddie = nil,
onburydie = function (x,y) 
	if growup (x,y,5) then
		achi_set (2,1)
	end
	fertilize (x,y,-10)
end, 
light = {24,0.7,0.7,1},
transformi = 156,
transformpower = 5,
}


item[333] = { name = 'Tuber',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 333,
onburydie = function (x,y) 
	if growup (x,y,189)==false then

	end
end, 
calories = 10,
diet = {'veggies','carbs'},
oneat = function ()
	buff_add (3,'add')
end,

ongrounddie = function (x,y, item)
	if (readmap (x,y,'de') or 0)>50 then
		inv_ground_add (x,y,item_make(334))
	end
end,

}


item[53] = { name = 'Carrot',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) 
	if growup (x,y,62) then
		writemap (x,y-1, 2, 'stage')
	end
end, 
calories = 20,
diet = {'veggies'}
}

item[38] = { name = 'Clover seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) 
	if growup (x,y,36) then
		achi_add (28,1)
	end
end, 
}

item[97] = { name = 'Apple seed',

ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 1, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) growup (x,y,91) end, 
}

item[52] = { name = 'Carrot seed',
tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 10, 
ttb = 1000, 
autobury = 1,
bury = {[102] = 3, [12] = 2, [13] = 1}, --clay
invdie = 0,    
laydie = 0,
burydie = 53,
onburydie = function (x,y) growup (x,y,62) end, 
}






item[336] = { name = 'Mashed tuber',
ttl  = time.d, 
tti = 1,
ttg = 10, 
ttb = 1000, 
bury = {[102] = 3, [12] = 2, [13] = 1},
invdie = 182,    
laydie = 182,
burydie = 182,
calories = 50,
diet = {'carbs'},
oneat = function ()
	inv_add(item_make(182))
end
}


item[335] = { name = 'Effs',
ttl  = time.w, 
tti = 1,
ttg = 10, 
ttb = 1000, 
bury = {[102] = 3, [12] = 2, [13] = 1},
invdie = 182,    
laydie = 182,
burydie = 182,
calories = 60,
diet = {'fat','carbs'},
oneat = function ()
	inv_add(item_make(182))
end
}

item[334] = { name = 'Baked Tuber',
ttl  = time.w, 
tti = 1,
ttg = 10, 
ttb = 1000, 
bury = {[102] = 3, [12] = 2, [13] = 1},
invdie = 0,    
laydie = 0,
burydie = 334,
calories = 10,
diet = {'carbs'},
}


item[337] = { name = 'Steak & fries',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1, 
bury = {[47] = 0.1},
invdie = 182,    
laydie = 182,
burydie = 182,
diet = {'protein','carbs'},
calories = 55,
oneat = function ()
	inv_add(item_make(182))
end
}



item[4] = { name = 'Glowing root',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

burydie = 4,
onburydie = function (x,y) 
	if growup (x,y,5) then
		fertilize (x,y,-5)
	end
end,

oneat = function (x,y)
	buff_add (1)
end,

calories = 20,
light = {24,0.7,0.7,1} 
}

item[174] = { name = 'Cactus seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
--bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},
bury = {[60] = 1},

invdie = 0,    
laydie = 0,
burydie = 4,
onburydie = function (x,y) 
	growup (x,y,128)
end, 
}

item[172] = { name = 'Cactus piece',
ttl  = time.w, 
tti = 1,
ttg = 1, 
ttb = 1000, 
bury = {[60] = 1},
invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) 
	growup (x,y,128)
end, 
oneat = function (x,y)
	stat_recovery ("water",10)
end,
calories = 10,
diet = {'veggies'}
}

item[173] = { name = 'Dragonfruit',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1000,
bury = {[60] = 1},
invdie = 0,
laydie = 97,
burydie = 97,
calories = 25,
oneat = function (x,y)
	pl.shit[174] = 174
	stat_recovery ("water",10)
end,
diet = {'exotic','fruits'}
}

item[259] = { name = 'Fried dragonfruit',
craft = {'component'},
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1000,
bury = {[60] = 1, [47] = 0.1},
invdie = 0,
laydie = 97,
burydie = 97,
calories = 30,
oneat = function (x,y)
	pl.shit[174] = 174
	stat_recovery ("water",10)
end,
diet = {'exotic','fruits','freezable'}
}

item[175] = { name = 'Chard',
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[102] = 1000, [12] = 1000, [13] = 1000},
invdie = 0,
laydie = 61,
burydie = 61,
calories = 7,
diet = {'veggies'},
oneat = function (x,y)
	stat_recovery ("water",10)
end,

}


item[176] = { name = 'Chard seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) growup (x,y,135) end, 
}

item[23] = { name = 'Apple',
craft = {'component'},
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 10,
bury = {[102] = 1000, [12] = 1000, [13] = 1000},
autobury = 1,
invdie = 0,
laydie = 97,
burydie = 97,
calories = 10,
diet = {'fruits'},
oneat = function (x,y)
	pl.shit[97] = 1
	stat_recovery ("water",20)
	buff_add (21)
end,
}

item[28] = { name = 'Glowing „fruit“',
craft = {'component'},
ttl  = time.w,
tti = 1,
ttg = 0.5,
ttb = 10,
bury = {[102] = 1000, [12] = 1000, [13] = 1000, [47] = 0.1},
autobury = 1,
invdie = 0,
laydie = 1,
burydie = 1,
calories = 20,
diet = {'exotic','freezable'},
oneat = function (x,y)
	pl.shit[1] = 1
	buff_add (1)
end,
light = {32,1,1,1}
}

item[102] = { name = 'Mushroom',
ttl  = time.d,
tti = 1,
ttg = 0.5,
ttb = 1,
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
calories = 20,
diet = {'exotic','freezable'},
oneat = function (x,y)
	--table.insert (pl.shit, 1)
	--table.insert (pl.shit, 1)
	buff_add (4)
end,
light = {32,1,1,0}
}


item[25] = { name = 'Firenut',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) 
	growup (x,y,24) 
end, 
light = {20,0.7,0.3,0.3},
calories = 20,
diet = {'exotic'},
oneat = function ( ... )
	buff_add (6)
end,

}


item[277] = { name = 'Kidney',
	ttl  = time.d,
	tti = 1,
	ttg = 1,
	ttb = 1,
	invdie = 0,
	laydie = 0,
	burydie = 0,
	transformi = 7,
	transformpower = -2
}

item[7] = { name = 'Beans',
	tag = 'seed',
	ttl  = time.w,
	tti = 1,
	ttg = 10,
	ttb = 100,
	bury = {[102] = 2, [12] = 4, [13] = 5},
	autobury = 1,
	invdie = 0,
	laydie = 0,
	burydie = 0,
	onburydie = function (x,y) 
		if growup (x,y,179) then
			writemap (x,y-1,5,'ttl')
		end
	end, 
	calories = 5,
	diet = {'protein'},
	oneat = function ()
		if love.math.random (0,100)<20 then buff_add (3,'add') end
	end
}



item[98] = { name = 'Magic beans',
	tag = 'seed',
	ttl  = time.w,
	tti = 1,
	ttg = 10,
	ttb = 1000,
	bury = {[102] = 1, [12] = 4, [13] = 5},
	autobury = 1,
	invdie = 0,
	laydie = 0,
	burydie = 0,
	onburydie = function (x,y) 
		growup (x,y,172)
	end, 
}



item[9] = { name = 'Giant weed nut',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) 
	fertilize (x,y,-50)
	growup (x,y,14) 
end, 
}

item[154] = { name = 'Weed nut kernel',
craft = {'component'},
ttl  = time.m,
tti = 1,
ttg = 1, 
ttb = 10, 
autobury = 0,
invdie = 0,    
laydie = 0,
burydie = 0,
calories = 10,
diet = {'fat'},
oneat = function ( ... )
	pl.lastshit = pl.lastshit - time.h
	textwall (msg.item[154].eat)
	buff_add (16)
end
}


item[155] = { name = 'Pot (hemp oil)',
f_burn = 20,
f_heat = 1000,
f_start = 200,

ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,


tool = {
	crafthit = 100,
	oil = 1,
},

hcalories = 10,


}


item[303] = { name = "Philosopher's stone",
ttl  = time.y,
tti = 0,
ttg = 0,
ttb = 0,
onuse = function (x,y,inv)
	pl.inv[inv] = item_make (5)
	textwall (msg.item[303].txt)
	stat_recovery ('arms', 100)
end,

}

item[156] = { name = 'Gardening manual',
f_burn = 20,
f_heat = 1000,
f_start = 200,
ttl  = time.y,
tti = 0,
ttg = 0,
ttb = 0,
onuse = function ( ... )
	textwall (msg.item[156].txt)
end
}

item[281] = { name = 'Firing manual',
f_burn = 20,
f_heat = 1000,
f_start = 200,
ttl  = time.y,
tti = 0,
ttg = 0,
ttb = 0,
onuse = function ( ... )
	textwall (msg.item[281].txt)
end
}


item[157] = { name = 'Plastic',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}


item[158] = { name = 'Soap',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
transformi = 152,
transformpower = -10
}


item[159] = { name = 'Chitin plate',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
}

item[160] = { name = 'Venom sack',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
calories = -10,
oneat = function ( ... )
	buff_add (2)
	buff_add (3)
end
}


item[161] = { name = 'Spider eyes',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
calories = 5,
oneat = function ( ... )
	buff_add (8)
end
}

item[162] = { name = 'frostie meat',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
calories = 10,
oneat = function ()
	stat_recovery ("heat",20)
end
}

item[163] = { name = 'Explosive shell',
f_burn = 30,
f_heat = 7000,
f_start = 100,
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
}



item[345] = { name = 'Butler Bot <year+50>',
ttl  = time.y,
put = 0,
tti = 1,
ttg = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
--bounce = {1,1,1,1},
onland = function (x,y)
	local r = px2tile (x,y)
	mob_create (r.x,r.y,16) --9
	sound_add ('click',20)
end,
throw = 1,
ongrounddie = function (x,y)
	mob_create (x,y,16)
end,
}


item[309] = { name = 'Pet rock',
ttl  = time.d*3,
put = 0,
tti = 1,
ttg = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
--bounce = {1,1,1,1},
onland = function (x,y)
	local r = px2tile (x,y)
	mob_create (r.x,r.y,15) --9
	sound_add ('rockfall',41, {x=x, y=y})
end,
throw = 1,
ongrounddie = function (x,y)
	mob_create (x,y,9)
end,
}


item[310] = { name = 'Spinner corpse',
ttl  = time.y,
tti = 1,
ttg = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
}

item[326] = { name = 'LED',
ttl  = time.y,
tti = 1,
ttg = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
}


item[346] = { name = 'Ceiling light',
ttl  = time.y,
tti = 1,
ttg = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
put = 193
}


item[347] = { name = 'Empty ceiling light',
ttl  = time.y,
tti = 1,
ttg = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
--put = 193
}

item[348] = { name = 'Sets of wires',
ttl  = time.y,
tti = 1,
ttg = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
}



item[18] = { name = 'Amoeba',
ttl  = time.d,
tti = 1,
ttg = time.d/256,
invdie = 0,    
laydie = 0,
burydie = 0,
--bounce = {1,1,1,1},
onland = function (x,y)
	local r = px2tile (x,y)
	mob_create (r.x,r.y,9) --9
end,
throw = 1,
ongrounddie = function (x,y)
	mob_create (x,y,9)
end,
}

item[164] = { name = 'Snake nut can',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
--bounce = {1,1,1,1},
onuse = function (x,y,inv)
	pl.inv[inv] = item_make (299)
	mob_create (x,y,8)
end,
}

item[165] = { name = 'Dead snake',
craft = {'component'},
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
}

item[166] = { name = 'Snake leather',
craft = {'component'},
ttl  = time.m*5,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
}



-- FODDER
---------------------------------------------

item[61] = { name = 'Mulch',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 59, 
laydie = 0,
ongrounddie = function (x,y) 
	fertilize (x,y+1,5)
	water_ground (x,y+1,10)
end,
burydie = 0,
onburydie = function (x,y) 
	fertilize (x,y,5)
	water_ground (x,y,10)
end,

onuse = function (x,y,inv)
	
	local ferable = {102,12,13}
	local mulch = readmap (x,y+1,'mu') or 0

	if mulch>=12 then
		textwall (msg.item[61].txt[3])
		return
	end

	if in_array (ferable, readmap (x,y+1,'b'))  then
		sound_add ('fert', 42)
		inv_remove (inv)
		textwall (msg.item[61].txt[1])
		mulch = mulch + 12
		writemap (x,y+1,mulch,'mu')
		pl.unrest = time.min*10
	else
		textwall (msg.item[62].txt[2])
	end

end

}


item[59] = { name = 'Fertilizer',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1000,
autobury = 1,
bury = {[102] = 1, [12] = 2, [13] = 3, }, --[1] = 1, [2] = 1, 
invdie = 0, 
laydie = 59,
burydie = 6,
onburydie = function (x,y) 
	fertilize (x,y,40)
end,

onuse = function (x,y,inv)
	
	local ferable = {102,12,13}

	if in_array (ferable, readmap (x,y+1,'b'))  then
		inv_remove (inv)
		textwall (msg.item[59].txt[1])
		fertilize (x,y+1,25)
		pl.unrest = time.min*10
		sound_add ('fert', 42)
	else
		textwall (msg.item[59].txt[2])
	end

end
}

item[187] = { name = 'Revitalizer',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1000,
autobury = 1,
bury = {[1] = 1, [2] = 1}, 
invdie = 0, 
laydie = 0,
burydie = 6,
onburydie = function (x,y) 
	writemap (x,y,101,'e')
end,

onuse = function (x,y,inv)
	
	local ferable = {1,2}

	if in_array (ferable, readmap (x,y+1,'b'))  then
		inv_remove (inv)
		textwall (msg.item[187].txt[1])
		writemap (x,y+1,101,'e')
		pl.unrest = time.min*10
	else
		textwall (msg.item[187].txt[2])
	end

end

}



item[3] = { name = 'Foliage', --Foliage
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 1, },
invdie = 37, 
laydie = 37,
onheat = function (x,y,map,k)
	map.i[k].t = map.i[k].t - 100 
end,

burydie = 0,
onburydie = function (x,y) 
	fertilize (x,y,5)
	water_ground (x,y,10)
end,
}



--FLAMMABLE
------------------------------------------------------------------------


item[37] = { name = 'Hay',
f_burn = 10,
f_heat = 300,
f_start = 200,
craft = {'component'},
ttl  = time.m,
tti = 0,
ttg = 1,
ttb = 30,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0, 
laydie = 0,
burydie = 6,
onburydie = function (x,y) 
	fertilize (x,y,5)
end,
onwater = function (x,y,map,k)
	--inv_ground_replace (x,y,k,item_make (61)) 
end,
}

item[107] = { name = 'Wood shavings',
f_burn = 10,
f_heat = 400,
f_start = 200,
craft = {},
ttl  = time.m,
tti = 0,
ttg = 1,
ttb = 10,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0, 
laydie = 0,
burydie = 0,
onburydie = function (x,y) 
	fertilize (x,y,10)
end,

onwater = function (x,y,map,k)
	inv_ground_replace (x,y,k,item_make (61)) 
end,

ongrounddie = function (x,y) 

	local bury = {[102] = 1, [12] = 2, [13] = 3}
	local de = readmap (x,y+1,'b')

	if bury[de] then
		inv_ground_add (x,y,item_make(61)) --mulch
	end

end,

}

item[15] = { name = 'Twig',
f_burn = 7,
f_heat = 400,
f_start = 300,
craft = {'component'},
ttl  = time.m,
tti = 0,
ttg = 1,
ttb = 1,
bury = {w = 30},
invdie = 0,    
laydie = 0,
burydie = 147,
onburydie = function (x,y) 
	local dr = readmap (x,y,'dr') or 0
	local w = readmap (x,y,'w') or 0

	if w>0 then
		dr = dr + 5
		w = w - 200
		writemap (x,y,dr,'dr')
		writemap (x,y,w,'w')
	end

end,
}


item[147] = { name = 'Hemp fiber',
f_burn = 10,
f_heat = 300,
f_start = 200,
craft = {'component'},
ttl  = time.y*3,
tti = 0,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0,    
laydie = 0,
burydie = 0,
}

item[148] = { name = 'Ruined hemp fiber',
f_burn = 10,
f_heat = 300,
f_start = 200,
ttl  = time.y*3,
tti = 0,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0,    
laydie = 0,
burydie = 0,
}


item[149] = { name = 'Hemp thread',
craft = {'component'},
ttl  = time.y*3,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0,    
laydie = 0,
burydie = 0,
}

item[150] = { name = 'Rope',
craft = {'component'},
ttl  = time.y*5,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0,    
laydie = 0,
burydie = 0,
}

item[151] = { name = 'Spider leg',
f_burn = 10,
f_heat = 0,
f_start = 1000,
craft = {'component','inspire'},

tool = {

	dmgmin = 3,
	dmgmax = 6,
	hithit = time.d/10
},

ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0,    
laydie = 0,
burydie = 0,
}

item[152] = { name = 'Hook',
craft = {'forgable','component'},
ttl  = time.y*5,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
}

item[153] = { name = 'Wooden frame',
f_burn = 10,
f_heat = 400,
f_start = 300,
craft = {'component'},
ttl  = time.y*5,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0,    
laydie = 0,
burydie = 0,
}


item[110] = { name = 'Dry moss',
f_burn = 10,
f_heat = 300,
f_start = 200,
craft = {'component'},
bury = {},
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
onwater = function (x,y,map,k)
	inv_ground_replace (x,y,k,item_make (109)) 
end,
onuse = function (x,y,inv)
	if pl.buffs[7] then
		buff_remove (7)
		pl.inv[inv] = nil
	else
		textwall (msg.item[110].use)
	end
end

}

item[171] = { name = 'Manna',
craft = {},
bury = {},
ttl  = time.h,
tti = 1,
ttg = 1,
ttb = 1,
calories = 20,
diet = {'exotic'},
invdie = 0,    
laydie = 0,
oneat = function ()
	buff_add (9,'keep')
end,

}

item[109] = { name = 'Moss',
put = 108,
craft = {},
bury = {},
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 1,
calories = 5,
diet = {'exotic'},
invdie = 110,    
laydie = 110,
}

item[111] = { name = 'Peat',
f_burn = 0.3,
f_heat = 700,
f_start = 300,
craft = {'component'},
bury = {},
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1
}



item[2] = { name = 'Stick',
f_burn = 5,
f_heat = 500,
f_start = 400,
craft = {'component'},
bury = {},
c_add = {
	digspeed = 0.1, 
},

equip = 'r',
tool = {
	digspeed = 0.90, 
	dighands = 0.90,
	dig = 1,
	smash = 1,

	dighit = 1,
	hithit = 1, --na

	crafthit = 20,
	craftspeed = 0,


	dmg = 3, --na
	dmgmin = 1, --na
	dmgmax = 3, --na
	dmgtype = 'b', --na // pierece, slash, blunt

},

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
transformi = 53,
transformpower = 10,
}

item[106] = { name = 'Wooden handle',
f_burn = 5,
f_heat = 500,
f_start = 400,
craft = {'component'},
bury = {},
c_add = {
},
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 10,
}

item[287] = { name = 'Masterwork handle',
f_burn = 5,
f_heat = 500,
f_start = 400,
craft = {'component'},
bury = {},
c_add = {
},
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 10,
}

item[105] = { name = 'Timber',
craft = {'component'},
f_burn = 2,
f_heat = 900,
f_start = 300,
bury = {},
ttl  = time.y*2,
tti = 1,
ttg = 1,
ttb = 10,
}

item[286] = { name = 'Apple timber',
f_burn = 2,
f_heat = 900,
f_start = 300,
bury = {},
ttl  = time.y*2,
tti = 1,
ttg = 1,
ttb = 10,
}

item[43] = { name = 'Firewood log',
craft = {'component'},
f_burn = 1,
f_heat = 1000,
f_start = 500,
bury = {},
ttl  = time.y*5,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 33,
ongrounddie = function (x,y, item)
	inv_ground_add (x,y,item_make(33))
end
}

item[120] = { name = 'Apple log',
f_burn = 2,
f_heat = 800,
f_start = 500,
bury = {},
ttl  = time.y*5,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 33,
}

item[108] = { name = 'Firewood',
f_burn = 2,
f_heat = 1000,
f_start = 300,
craft = {},
bury = {},
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
laydie = 33,
throw = 0.6,
proj = 1
}


item[33] = { name = 'Charcoal',
f_burn = 0.8,
f_heat = 2500,
f_start = 300,
ttl  = time.y*2,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 207,
burydie = 0,

onuse = function (x,y,inv)
	buff_add (22)
	pl.inv[inv] = nil
end,
throw = 0.6,
proj = 1

}

item[46] = { name = 'Coal',
ttl = 10000,
craft = {'ore'},
f_burn = 0.3,
f_heat = 5000,
f_start = 300,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
throw = 0.6,
proj = 1
}

item[87] = { name = 'Coke',
ttl = 10000,
f_burn = 0.2,
f_heat = 7000,
f_start = 400,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
}

item[354] = { name = 'The burning man',
craft = {'component'},
ttl = 1000,
f_burn = 10,
f_heat = 6000,
f_start = 10,
tti = 0,
ttg = 0,
ttb = 0,

onheat = function (x,y,map,k)
	if map.de and map.de>10 and readmap (x,y,'b')==0 then
		writemap (x,y,55)
	end
end,

ongrounddie = function (x,y) 
	stat_recovery ('faith', 20)
end,


}

item[88] = { name = 'Sulfur',
craft = {'component'},
ttl = 1000,
f_burn = 20,
f_heat = 7000,
f_start = 100,
tti = 0,
ttg = 0,
ttb = 0,

onheat = function (x,y,map,k)
	if map.de and map.de>100 and readmap (x,y,'b')==0 then
		writemap (x,y,55)
	end
end,

}

item[54] = { name = 'Skull cup (empty)',
craft = {'inspire'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'l',

onuse = function (x,y,inv)

	local f = 100
	local w = readmap (pl.xt,pl.yt,'w') or 0
	if w==0 then textwall (msg.game[9]) return false end

	sound_add ('bubble',34)

	if w < f then
		f = w
		w = nil
	else
		w = w - f
	end

	writemap (pl.xt,pl.yt,w,'w')
	local i = item_make (55)
	i.dr = readmap (pl.xt,pl.yt,'dr')
	pl.inv[inv] = i

end
}

item[55] = { name = 'Skull cup (water)',
craft = {'inspire'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 54, 


onuse = function (x,y,inv)
	pl.yo = 0 --game.moved
	local s
	while pl.stats.water.hp<pl.stats.water.maxhp and pl.inv[inv].t > 0 do
		pl.inv[inv].t = pl.inv[inv].t - 10
		stat_recovery ("water", cf.watersip*2)
		s = true
	end
	if s then 
		textwall (msg.game[10]) 
		drink_dirt (pl.inv[inv].dr)
	end
end,

onempty = function (x,y,inv)

	sound_add ('pour',35)

	local dr = (pl.inv[inv].dr or 0) + (readmap (x,y,'dr') or 0)
	writemap (x,y,dr,'dr')

	local w = readmap (x,y,'w') or 0
	writemap (x,y,pl.inv[inv].t+w,'w')
	local i = item_make (54)
	pl.inv[inv] = i
	return false
end,

oninfo = function (x,y,inv)
	local dr = inv.dr or 0
	local str = message (msg.gui[36],{[1] = math.ceil(dr)})
	return str
end


}

item[56] = { name = 'Pot (empty)',
craft = {'inspire'},
ttl  = time.w,
tti = 0,
ttg = 1,
ttb = 0,

onuse = function (x,y,inv)

	local f = 500
	local w = readmap (pl.xt,pl.yt,'w') or 0
	if w==0 then textwall (msg.game[9]) return false end

	sound_add ('bubble',34)

	if w < f then
		f = w
		w = nil
	else
		w = w - f
	end

	writemap (pl.xt,pl.yt,w,'w')

	local i = item_make (57)
	i.dr = readmap (pl.xt,pl.yt,'dr')
	pl.inv[inv] = i


end
}

item[57] = { name = 'Pot (water)',
craft = {'inspire'},
ttl  = 500,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 56,

tool = {
	crafthit = 200,
	water = 1,
},

onuse = function (x,y,inv)
	pl.yo = 0 --game.moved
	local s
	while pl.stats.water.hp<pl.stats.water.maxhp and pl.inv[inv].t > 0 do
		pl.inv[inv].t = pl.inv[inv].t - 10
		stat_recovery ("water", cf.watersip*2)
		s = true
	end
	if s then 
		drink_dirt (pl.inv[inv].dr)
		textwall (msg.game[10]) 
	end
end,

onempty = function (x,y,inv)

	sound_add ('pour',35)

	local dr = (pl.inv[inv].dr or 0) + (readmap (x,y,'dr') or 0)
	writemap (x,y,dr,'dr')

	local w = readmap (x,y,'w') or 0
	writemap (x,y,pl.inv[inv].t+w,'w')
	local i = item_make (56)
	pl.inv[inv] = i
	return false
end,

oninfo = function (x,y,inv)
	local dr = inv.dr or 0
	local str = message (msg.gui[36],{[1] = math.ceil(dr)})
	return str
end,

transformi = 188,
transformpower = 30,

}

item[58] = { name = 'Bone dust',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 10,
autobury = 1,
bury = {[102] = 1, [1] = 1, [2] = 1, [12] = 2, [13] = 3, },
onburydie = function (x,y) 
	fertilize (x,y,20)
end,
}




------------------------------------------------
-- SMELTABLE and BARS

item[121] = { name = 'Ruined ore',
craft = {'inspire'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, 
laydie = 0,
}

item[60] = { name = 'Copper ore',
craft = {'ore'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, 
laydie = 121,
onheat = function (x,y,map,k)
	if map.de>200 then
		map.i[k].t = map.i[k].t - 1 
	end
end,
}

item[64] = { name = 'Limestone',
craft = {'ore'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}

item[78] = { name = 'Tin ore',
craft = {'ore'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 121,
onheat = function (x,y,map,k)
	if map.de>200 then
		map.i[k].t = map.i[k].t - 1 
	end
end,
}

item[79] = { name = 'Copper bar',
craft = {'bar'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}

item[80] = { name = 'Tin bar',
craft = {'bar'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}

item[85] = { name = 'Bronze bar',
craft = {'bar'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}

item[86] = { name = 'Tumbaga bar',
craft = {'bar'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}

item[131] = { name = 'Gold ore',
craft = {'ore'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
burydie = 0,
laydie = 121,
onheat = function (x,y,map,k)
	if map.de>200 then
		map.i[k].t = map.i[k].t - 1 
	end
end,
}


item[21] = { name = 'Gold bar',
craft = {'bar'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
laydie = 0,
burydie = 0,
}

------------------------------------------------
-- CRUCIBLES

item[66] = { name = 'Crucible (raw)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 66,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[67] = { name = 'Crucible (empty)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
put = 67,
}

item[68] = { name = 'Crucible (copper ore)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 68,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (60))
	inv_add (item_make (60))
	inv_add (item_make (60))
	inv_add (item_make (60))
	return false
end

}


item[69] = { name = 'Crucible (copper & tin)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 69,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (60))
	inv_add (item_make (60))
	inv_add (item_make (60))
	inv_add (item_make (78))
	return false
end

}

item[70] = { name = 'Crucible (tin ore)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 70,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (78))
	inv_add (item_make (78))
	inv_add (item_make (78))
	inv_add (item_make (78))
	return false
end

}

item[71] = { name = 'Crucible (limestone)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 71,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (64))
	return false
end
}


item[208] = { name = 'Crucible (sand)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 162,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[209] = { name = 'Crucible (glass)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 163,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[210] = { name = 'Bottle',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[72] = { name = 'Crucible (coal)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 72,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (46))
	inv_add (item_make (46))
	inv_add (item_make (46))
	inv_add (item_make (46))
	return false
end

}

item[73] = { name = 'Crucible (copper)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 73,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (79))
	inv_add (item_make (59))
	return false
end,

transform = 78,
transformpower = 20,

}


item[132] = { name = 'Crucible (gold ore)',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 118,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (131))
	inv_add (item_make (131))
	inv_add (item_make (131))
	inv_add (item_make (131))
	return false
end

}

item[133] = { name = 'Crucible (gold)',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 119,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (21))
	inv_add (item_make (59))
	return false
end

}

item[74] = { name = 'Crucible (bronze)',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 74,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (85))
	return false
end

}

item[75] = { name = 'Crucible (tin)',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 75,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (80))
	inv_add (item_make (59))
	return false
end
}

item[76] = { name = 'Crucible (cement)',
craft = {'glue'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 76,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[77] = { name = 'Crucible (coke)',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 77,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (87))
	return false
end
}

item[81] = { name = 'Crucible (pyrite)',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 81,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (36))
	inv_add (item_make (36))
	inv_add (item_make (36))
	inv_add (item_make (36))
	return false
end

}

item[82] = { name = 'Crucible (sulfur)',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 82,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (88))
	inv_add (item_make (59))
	return false
end

}

item[83] = { name = 'Crucible (bronze & gold)',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 83,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (85))
	inv_add (item_make (85))
	inv_add (item_make (21))
	inv_add (item_make (21))
	return false
end

}

item[84] = { name = 'Crucible (tumbaga)',

ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
put = 82,
laydie = 0,
burydie = 0,
invdie = 0, 

onempty = function (x,y,inv)
	pl.inv[inv] = item_make (67) --empty crucuble
	inv_add (item_make (86))
	return false
end

}

------------------------------------------------
-- CLAY

item[8] = { name = 'Clay',
craft = {'glue','clay'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}

item[62] = { name = 'Brick (raw)',
craft = {''},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 63,
onheat = function (x,y,map,k)
	if map.de>100 then
		map.i[k].t = map.i[k].t - 1 
	end
end,
}


item[329] = { name = 'Grenade shell (raw)',
craft = {''},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 330,
onheat = function (x,y,map,k)
	if map.de>100 then
		map.i[k].t = map.i[k].t - 1 
	end
end,
}


item[330] = { name = 'Grenade shell',
craft = {''},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 330,
}



item[304] = { name = 'Clay bullet (raw)',
craft = {''},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 305,
onheat = function (x,y,map,k)
	if map.de>100 then
		map.i[k].t = map.i[k].t - 1 
	end
end,

}

item[63] = { name = 'Brick',
craft = {'component'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}


item[181] = { name = 'Bowl (raw)',
craft = {''},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 182,
onheat = function (x,y,map,k)
	if map.de>100 then
		map.i[k].t = map.i[k].t - 1 
	end
end,

}

item[182] = { name = 'Bowl',
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}

item[65] = { name = 'Fossil',

bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
}




item[47] = { name = 'Jug (empty)',

ttl  = 4000,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
put = 57,
onuse = function (x,y,inv)
	local w = readmap (pl.xt,pl.yt,'w') or 0
	if w==0 then
		textwall (msg.game[9])
		return false
	end

	sound_add ('bubble',34)

	local f = 4000
	if w < 4000 then
		f = w
	w = nil
	else
		w = w - 4000
	end

	writemap (pl.xt,pl.yt,w,'w')

	local i = item_make (48)
	i.dr = readmap (pl.xt,pl.yt,'dr')
	i.t = f
	pl.inv[inv] = i

end,

-- ontake = function () pl.slowed = pl.slowed - 0.3 end,
-- ondrop = function () pl.slowed = pl.slowed + 0.3 end,

}

item[48] = { name = 'Jug (water)',

ttl  = 4000,
tti = 0,
ttg = 0,
ttb = 0,
put = 58,
laydie = 0,
burydie = 0,
invdie = 47, 

tool = {
	crafthit = 200,
	water = 2,
},

onuse = function (x,y,inv)
	local s
	while pl.stats.water.hp<pl.stats.water.maxhp and pl.inv[inv].t > 0 do
		if pl.inv[inv].t>0 then
			pl.inv[inv].t = pl.inv[inv].t - 10
			stat_recovery ("water", cf.watersip*2)
			s = true
		end
	end
	if s then 
		textwall (msg.game[10]) 
		drink_dirt (pl.inv[inv].dr)
	end
end,

onempty = function (x,y,inv)

	sound_add ('pour',35)

	local dr = (pl.inv[inv].dr or 0) + (readmap (x,y,'dr') or 0)
	writemap (x,y,dr,'dr')

	local w = readmap (x,y,'w') or 0
	writemap (x,y,pl.inv[inv].t+w,'w')
	local i = item_make (47)
	pl.inv[inv] = i
	return false

end,

oninfo = function (x,y,inv)
	local dr = inv.dr or 0
	local str = message (msg.gui[36],{[1] = math.ceil(dr)})
	return str
end

-- ontake = function () pl.slowed = pl.slowed - 0.3 end,
-- ondrop = function () pl.slowed = pl.slowed + 0.3 end,

}



item[51] = { name = 'Jug (sand)',
craft = {'component'},
ttl  = 4000,
tti = 0,
ttg = 0,
ttb = 0,
put = 61,
laydie = 0,
burydie = 0,
invdie = 47, 

onempty = function (x,y,inv)

	if pl.iscarry == nil then

		pl.iscarry = createblock (60)
		pl.inv[inv] = item_make (47)
		return false

	end

	return false

end,

-- ontake = function () pl.slowed = pl.slowed - 0.3 end,
-- ondrop = function () pl.slowed = pl.slowed + 0.3 end,

}

item[185] = { name = 'Bin (raw)',

ttl  = 4000,
tti = 0,
ttg = 0,
ttb = 0,
put = 150,
laydie = 0,
burydie = 0,
invdie = 0, 
}

item[186] = { name = 'Bin (empty)',

ttl  = 4000,
tti = 0,
ttg = 0,
ttb = 0,
put = 151,
laydie = 0,
burydie = 0,
invdie = 0, 
}



item[49] = { name = 'Jug (raw)',

ttl  = 4000,
tti = 0,
ttg = 0,
ttb = 0,
put = 59,
laydie = 0,
burydie = 0,
invdie = 47, 
}

item[50] = { name = 'Ceramic scraps',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0
}



--PLANTS
------------------------------------------------------------------------

item[40] = { name = 'Ice chunk',
ttl  = time.h*2,
tti = 1,
ttg = 1,
ttb = 1,
ongrounddie = function (x,y) 
	local w = readmap (x,y,'w') or 0
	writemap (x,y,love.math.random (100,1000)+w,'w')
end,
invdie = 0, 
laydie = 0,
burydie = 0,
calories = 0,
onheat = function (x,y,map,k)
	map.i[k].t = map.i[k].t - 1 
end,
oneat = function ()
	stat_recovery ("water",50)
	stat_spend ("heat",20)
end
}

item[41] = { name = 'Fire striker',
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, 
laydie = 0,
burydie = 0,
onuse = function (x,y, k)

	if readmap (x,y,'b')==37 then --haystack
		inv_ground_add (x,y,item_make(37))
		writemap (x,y,55)
		return
	end

	if readmap (x,y,'b')==39 then --haystack
		inv_ground_add (x,y,item_make(37))
		inv_ground_add (x,y,item_make(37))
		inv_ground_add (x,y,item_make(37))
		inv_ground_add (x,y,item_make(37))
		inv_ground_add (x,y,item_make(37))
		inv_ground_add (x,y,item_make(37))
		inv_ground_add (x,y,item_make(37))
		inv_ground_add (x,y,item_make(39))
		writemap (x,y,55)
		return
	end

	if readmap (x,y,'b')==196 then --The Wicker Man
		inv_ground_add (x,y,item_make(354))
		writemap (x,y,55)
		return
	end

	if readmap (x,y,'b')~=0 and readmap (x,y,'b')~=55 then
		textwall (msg.item[41].txt[2])
		return
	end

	writemap (x,y,55)
	pl.inv[k].t = pl.inv[k].t - 10
	textwall (msg.item[41].txt[1])
	
end,
transformi = 281,
transformpower = 3
}

item[42] = { name = 'Wire',
craft = {'component', 'string','forgable'},
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, 
laydie = 0,
burydie = 0,
}

item[104] = { name = 'Spidersilk thread',
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, 
laydie = 0,
burydie = 0,
}


item[311] = { name = 'Silk',
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, 
laydie = 0,
burydie = 0,
}



item[39] = { name = 'Needle',
craft = {'component'},
ttl  = 3000,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, 
laydie = 0,
burydie = 6,
}


item[169] = { name = 'Sewing kit',
craft = {},
tool = {
	crafthit = 20,
},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, 
laydie = 0,
burydie = 0,
}



item[170] = { name = 'Snake leather boots',
craft = {},
equip = 'f',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,

onequip = function ()
	pl.slowed = pl.slowed + 0.1
	pl.stats.heat.maxhp = pl.stats.heat.maxhp + 25
	pl.stats.heat.hp = pl.stats.heat.hp + 25
end,
onunequip = function ()
	pl.slowed = pl.slowed - 0.1
	pl.stats.heat.maxhp = pl.stats.heat.maxhp + 25
	pl.stats.heat.hp = pl.stats.heat.hp + 25
end,

}


item[356] = { name = 'Moss-stuffed boots',
craft = {},
equip = 'f',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,

onequip = function ()
	pl.stats.heat.maxhp = pl.stats.heat.maxhp + 250
	pl.stats.heat.hp = pl.stats.heat.hp + 250
end,
onunequip = function ()
	pl.stats.heat.maxhp = pl.stats.heat.maxhp + 250
	pl.stats.heat.hp = pl.stats.heat.hp + 250
end,

}


item[357] = { name = 'Fireproof gloves',
craft = {},
equip = 'a',
ttl  = time.m*3,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,

onequip = function ()
	pl.stats.heat.maxhp = pl.stats.heat.maxhp + 25
	pl.stats.heat.hp = pl.stats.heat.hp + 25
end,
onunequip = function ()
	pl.stats.heat.maxhp = pl.stats.heat.maxhp + 25
	pl.stats.heat.hp = pl.stats.heat.hp + 25
end,

}


-------------------------------------------------------------
-- wear

item[195] = { name = 'Piupiu skirt',
craft = {},
equip = 'g',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,

onequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp + 25
	pl.stats.body.maxhp = pl.stats.body.maxhp + 20
	pl.stats.heat.maxhp = pl.stats.heat.maxhp + 20
end,
onunequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp + 25
	pl.stats.body.maxhp = pl.stats.body.maxhp - 20
	pl.stats.heat.maxhp = pl.stats.heat.maxhp - 20
end,
}


item[312] = { name = 'Skintight trousers',
craft = {},
equip = 'g',
ttl  = time.w*2,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onequip = function ()
	pl.jumpyslow = pl.jumpyslow + 0.3
	pl.jumpxslow = pl.jumpxslow + 0.3
	pl.stats.body.maxhp = pl.stats.body.maxhp + 10
end,
onunequip = function ()
	pl.jumpyslow = pl.jumpyslow - 0.3
	pl.jumpxslow = pl.jumpxslow - 0.3
	pl.stats.body.maxhp = pl.stats.body.maxhp - 10
end,
}


item[368] = { name = 'Cargo pants',
craft = {},
equip = 'g',
ttl  = time.m*2,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onequip = function ()
	pl.invsize = pl.invsize + 5
end,
onunequip = function ()
	pl.invsize = pl.invsize - 5
end,
}


item[313] = { name = 'Slick gloves',
craft = {},
equip = 'a',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onequip = function ()
	pl.craftspeed = (pl.craftspeed or 0) - 0.1
	pl.stats.body.maxhp = pl.stats.body.maxhp + 5
end,
onunequip = function ()
	pl.craftspeed = (pl.craftspeed or 0) + 0.1
	pl.stats.body.maxhp = pl.stats.body.maxhp - 5
end,
}



item[314] = { name = 'Breathing T-shirt',
craft = {},
equip = 'a',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onequip = function ()
	pl.digspend = (pl.digspend or 1) - 0.2
	pl.stats.body.maxhp = pl.stats.body.maxhp + 5
end,
onunequip = function ()
	pl.digspend = (pl.digspend or 1) + 0.2
	pl.stats.body.maxhp = pl.stats.body.maxhp - 5
end,
}


item[340] = { name = 'Survival t-shirt',
craft = {},
equip = 'a',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp + 15
end,
onunequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp - 15
end,
}


item[315] = { name = 'Bandage',
ttl  = 10,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
invdie = 0, 

onuse = function (x,y,inv)
	if pl.inv[inv].t > 0 and pl.buffs[23]==nil then
		pl.inv[inv].t = pl.inv[inv].t - 1
		buff_add (23)
		buff_remove (7)
	end
end,

}


item[316] = { name = 'Silk socks',
craft = {},
equip = 'a',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onequip = function ()
	pl.restqualityb = (pl.restqualityb or 0) + 0.15
	pl.stats.body.maxhp = pl.stats.body.maxhp + 5
end,
onunequip = function ()
	pl.restqualityb = (pl.restqualityb or 0) - 0.15
	pl.stats.body.maxhp = pl.stats.body.maxhp - 5
end,
}


item[16] = { name = 'Liana',
craft = {'string'},
ttl  = 10000,
tti = 0,
ttg = 2,
ttb = 2,
--bury = {[102] = 1, [12] = 2, [13] = 3, },
invdie = 3,    
laydie = 6,
burydie = 3,
}






-- TOOLS
-- dig
-- cut
-- chop
-- smash
-- pierce
---------------------------------------------------------

item[5] = { name = 'Stone',
craft = {'component','smash'},
bury = {},
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 10,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.90, 
	dighands = 0.90,
	dig = 1,
	smash = 1,

	dighit = 1,
	hithit = 1, --na

	crafthit = 20,
	craftspeed = 0,


	dmg = 3, --na
	dmgmin = 1, --na
	dmgmax = 3, --na
	dmgtype = 'b', --na // pierece, slash, blunt

},
throw = 0.7,
proj = 3
}

item[11] = { name = 'Bone',
craft = {'component'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 95,
equip = 'r',
tool = {
	digspeed = 0.80, 
	dighit = 1,
	dighands = 0.9,
	smash = 1,
	dig = 1,
	dmgmin = 1, --na
	dmgmax = 3, --na
},
}




item[96] = { name = 'Spike',
craft = {'component','inspire'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
laydie = 0,
burydie = 0,
tool = {

	digspeed = 1.5, 
	dighands = 3,
	pierce = 1,
	dig = 2,

	dighit = 20,
	hithit = 1, --na

	crafthit = 10,
	craftspeed = 0,

	dmg = 3, --na
	dmgmin = 1, --na
	dmgmax = 3, --na
	dmgtype = 'p', --na // pierece, slash, blunt

},
}


item[10] = { name = 'Sharp stone',
craft = {'component','cut','inspire'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 10,
laydie = 0,
burydie = 0,
c_add = {}, -- add stats
tool = {
	digspeed = 0.85, 
	dighands = 0.9,
	dig = 1,
	cut = 1,

	dighit = 1,
	hithit = 1,     --na

	crafthit = 10,
	craftspeed = 0, -- %

	dmg = 5,        --na
	dmgmin = 1,     --na
	dmgmax = 5,     --na
	dmgtype = 's',  --na // pierece, slash, blunt
},
throw = 1.2,
proj = 5
}


item[342] = { name = 'Blink dagger',
bury = {},
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 10,
laydie = 0,
burydie = 0,
c_add = {}, -- add stats
tool = {
	digspeed = 0.85, 
	dighands = 0.9,
	cut = 2,

	dighit = 1,
	hithit = 1,     --na

	crafthit = 10,
	craftspeed = 0, -- %

	dmg = 5,        --na
	dmgmin = 5,     --na
	dmgmax = 6,     --na
	dmgtype = 's',  --na // pierece, slash, blunt
},
throw = 1.2,
proj = 5,

onland = function (x,y)
	local r = px2tile (x,y)

	if maptile (r.x,r.y,'col')==0 and maptile (r.x,r.y-1,'col')==0 then
		player_pos_port (r.x, r.y)
	end

	return true
end,

light = {32,0.5,0.5,1}

}

-----------------------METAL TOOLS------------
----------------------------------------------

item[319] = { name = 'Sting',
bury = {},
ttl  = 150,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {

	digspeed = 0.70, 
	dighands = 0.70,
	cut = 1,

	dighit = 1,
	hithit = 1,

	crafthit = 2,
	craftspeed = -0.1,

	dmgmin = 7,
	dmgmax = 7,
	dmgtype = 's', --na // pierece, slash, blunt

},

light = {64,1,1,0.7}

}


item[317] = { name = 'Copper sword',
bury = {},
ttl  = 150,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {

	digspeed = 0.90, 
	dighands = 0.90,
	cut = 1,

	dighit = 1,
	hithit = 1,

	crafthit = 2,
	craftspeed = -0.1,

	dmgmin = 5,
	dmgmax = 7,
	dmgtype = 's', --na // pierece, slash, blunt

},
}




item[128] = { name = 'Copper knife',
craft = {'component','cut','forgable'},
bury = {},
ttl  = 150,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
c_add =
{
	dmgmin = 1,
	dmgmax = 1,
},
tool = {

	digspeed = 0.85, 
	dighands = 0.85,
	dig = 2,
	cut = 2,

	dighit = 1,
	hithit = 1,

	crafthit = 2,
	craftspeed = -0.1,

	dmgmin = 2,
	dmgmax = 5,
	dmgtype = 's', --na // pierece, slash, blunt

},
throw = 1.2,
proj = 5,

onequip = function ()
	pl.slowed = pl.slowed + 0.1
end,
onunequip = function ()
	pl.slowed = pl.slowed - 0.1
end,


}


item[129] = { name = 'Bronze knife',
craft = {'component','cut','forgable'},
bury = {},
ttl  = 500,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
c_add =
{
	dmgmin = 3,
	dmgmax = 3,
},
tool = {

	digspeed = 0.85, 
	dighands = 0.85,
	dig = 2,
	cut = 3,

	dighit = 10,
	hithit = 1,

	crafthit = 2,
	craftspeed = -0.2,

	dmgmin = 3,
	dmgmax = 6,
	dmgtype = 's', --na // pierece, slash, blunt

},
throw = 1.2,
proj = 5,

onequip = function ()
	pl.slowed = pl.slowed + 0.15
end,
onunequip = function ()
	pl.slowed = pl.slowed - 0.15
end,

}

item[130] = { name = 'Tumbaga knife',
craft = {'component','cut','forgable'},
bury = {},
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
c_add =
{
	dmgmin = 5,
	dmgmax = 5,
},
tool = {

	digspeed = 0.80, 
	dighands = 0.80,
	dig = 2,
	cut = 4,

	dighit = 10,
	hithit = 1,

	crafthit = 2,
	craftspeed = -0.3,

	dmgmin = 4,
	dmgmax = 7,
	dmgtype = 's', --na // pierece, slash, blunt

},
throw = 1.2,
proj = 5,

onequip = function ()
	pl.slowed = pl.slowed + 0.2
end,
onunequip = function ()
	pl.slowed = pl.slowed - 0.2
end,

}

--135


item[30] = { name = 'Adze',
craft = {'chop', 'inspire'},
ttl  = 150,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.75, 
	dighit = 1,
	dighands = 0.80,
	crafthit = 5,
	dig = 2,
	dmgmin = 2,
	dmgmax = 4,
	chop = 1,
},
onequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp + 15
	pl.stats.arms.hp = pl.stats.arms.hp + 15
end,
onunequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp - 15
	pl.stats.arms.hp = pl.stats.arms.hp - 15
end,
throw = 1.1,
proj = 6
}

item[177] = { name = 'Bone axe',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.50, 
	dighit = 1,
	dighands = 0.80,
	crafthit = 10,
	pierce = 2,
	dmgmin = 5,
	dmgmax = 6,
	chop = 1,
},
throw = 1.1,
proj = 6
}

item[134] = { name = 'Copper axe',
craft = {'chop','forgable'},
ttl  = 200,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.90, 
	dighit = 1,
	dighands = 0.90,
	crafthit = 7,
	dig = 2,
	dmgmin = 4,
	dmgmax = 5,
	chop = 2,
	craftspeed = -0.1,
},
throw = 1.1,
proj = 6
}

item[135] = { name = 'Bronze axe',
craft = {'chop','forgable'},
ttl  = 300,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.80, 
	dighit = 1,
	dighands = 0.80,
	crafthit = 5,
	dig = 2,
	dmgmin = 6,
	dmgmax = 7,
	chop = 3,
	craftspeed = -0.3,
},
throw = 1.1,
proj = 6
}


item[136] = { name = 'Tumbaga axe',
craft = {'chop','forgable'},
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.70, 
	dighit = 1,
	dighands = 0.70,
	crafthit = 5,
	dig = 2,
	dmgmin = 8,
	dmgmax = 10,
	chop = 4,
	craftspeed = -0.5,
},
throw = 1.1,
proj = 6
}



item[19] = { name = 'Stone hammer',
craft = {'smash','inspire'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.80, 
	dighit = 1,
	crafthit = 5,
	dighands = 0.85,
	smash = 2,
	dmgmin = 2,
	dmgmax = 3,
},
onequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp + 10
	pl.stats.body.hp = pl.stats.body.hp + 10
end,
onunequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp - 10
	pl.stats.body.hp = pl.stats.body.hp - 10
end,
throw = 1,
proj = 7
}


item[137] = { name = 'Copper hammer',
craft = {'smash','forgable'},
ttl  = 150,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.75, 
	dighit = 1,
	crafthit = 5,
	dighands = 0.75,
	smash = 3,
	dmgmin = 4,
	dmgmax = 5,
	craftspeed = -0.1,
},
onequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp + 20
	pl.stats.body.hp = pl.stats.body.hp + 20
end,
onunequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp - 20
	pl.stats.body.hp = pl.stats.body.hp - 20
end,
throw = 1,
proj = 7
}


item[138] = { name = 'Bronze hammer',
craft = {'smash','forgable'},
ttl  = 500,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.70, 
	dighit = 1,
	crafthit = 5,
	dighands = 0.75,
	smash = 4,
	dmgmin = 6,
	dmgmax = 7,
	craftspeed = -0.3,
},
onequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp + 40
	pl.stats.body.hp = pl.stats.body.hp + 40
end,
onunequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp - 40
	pl.stats.body.hp = pl.stats.body.hp - 40
end,
throw = 1,
proj = 7
}

item[139] = { name = 'Tumbaga hammer',
craft = {'smash','forgable'},
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.65, 
	dighit = 1,
	crafthit = 5,
	dighands = 0.75,
	smash = 5,
	dmgmin = 7,
	dmgmax = 8,
	craftspeed = -0.5,
},
onequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp + 80
	pl.stats.body.hp = pl.stats.body.hp + 80
end,
onunequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp - 80
	pl.stats.body.hp = pl.stats.body.hp - 80
end,
throw = 1,
proj = 7
}



item[95] = { name = 'Broken bone',
craft = {'inspire'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 58, --dust
equip = 'r',
tool = {
	digspeed = 0.9, 
	dighit = 1,
	dighands = 0.85,
	pierce = 1,
	dig = 1,
	dmgmin = 1,
	dmgmax = 2,
},
}

item[167] = { name = 'Snake fang',
craft = {'inspire'},
ttl  = 50,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,    
laydie = 0,
burydie = 0,

tool = {
	digspeed = 0.9, 
	dighit = 1,
	dighands = 0.95,
	pierce = 1,
	dig = 1,
	dmgmin = 1,
	dmgmax = 3,
},

}

item[168] = { name = 'Bone pickaxe',
craft = {'forgable'},
ttl  = 50,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,    
laydie = 0,
burydie = 0,

tool = {
	digspeed = 0.5, 
	dighit = 1,
	dighands = 0.85,
	pierce = 3,
	dig = 1,
	dmgmin = 1,
	dmgmax = 4,
},

}


item[140] = { name = 'Copper pickaxe',
craft = {'forgable'},
ttl  = 150,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, --dust
equip = 'r',
tool = {
	digspeed = 0.8, 
	dighit = 2,
	dighands = 0.85,
	pierce = 2,
	dig = 1,
	dmgmin = 1,
	dmgmax = 3,
},
onequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp + 15
	pl.stats.arms.hp = pl.stats.arms.hp + 15
end,
onunequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp - 15
	pl.stats.arms.hp = pl.stats.arms.hp - 15
end,
}

item[141] = { name = 'Bronze pickaxe',
craft = {'forgable'},
ttl  = 500,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, --dust
equip = 'r',
tool = {
	digspeed = 0.7, 
	dighit = 2,
	dighands = 0.85,
	pierce = 3,
	dig = 1,
	dmgmin = 1,
	dmgmax = 6,
},
onequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp + 30
	pl.stats.arms.hp = pl.stats.arms.hp + 30
end,
onunequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp - 30
	pl.stats.arms.hp = pl.stats.arms.hp - 30
end,
}

item[142] = { name = 'Tumbaga pickaxe',
craft = {'forgable'},
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, --dust
equip = 'r',
tool = {
	digspeed = 0.6, 
	dighit = 2,
	dighands = 0.80,
	pierce = 4,
	dig = 1,
	dmgmin = 1,
	dmgmax = 10,
},
onequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp + 60
	pl.stats.arms.hp = pl.stats.arms.hp + 60
end,
onunequip = function ()
	pl.stats.arms.maxhp = pl.stats.arms.maxhp - 60
	pl.stats.arms.hp = pl.stats.arms.hp - 60
end,
}


item[124] = { name = 'Shovel',
ttl  = 200,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.50, 
	dighit = 1,
	dighands = 0.50,
	dmgmin = 3,
	dmgmax = 3,
	dig = 3,
},
	
onequip = function ()
	pl.digslowed = (pl.digslowed or 1) + 0.5
	pl.digspend = (pl.digspend or 1) - 0.2
end,
onunequip = function ()
	pl.digslowed = (pl.digslowed or 1) - 0.5
	pl.digspend = (pl.digspend or 1) + 0.2
end,

}


item[178] = { name = 'Copper shovel',
ttl  = 200,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.60, 
	dighit = 1,
	dighands = 0.60,
	dmgmin = 3,
	dmgmax = 3,
	dig = 2,
	digstat = 'legs'
},

onequip = function ()
	pl.digslowed = (pl.digslowed or 1) + 0.3
	pl.digspend = (pl.digspend or 1) - 0.1
end,
onunequip = function ()
	pl.digslowed = (pl.digslowed or 1) - 0.3
	pl.digspend = (pl.digspend or 1) + 0.1
end,

}

item[179] = { name = 'Bronze shovel',
ttl  = 500,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.50, 
	dighit = 1,
	dighands = 0.50,
	dmgmin = 3,
	dmgmax = 3,
	dig = 3,
	digstat = 'legs'
},

onequip = function ()
	pl.digslowed = (pl.digslowed or 1) + 0.4
	pl.digspend = (pl.digspend or 1) - 0.2
end,
onunequip = function ()
	pl.digslowed = (pl.digslowed or 1) - 0.4
	pl.digspend = (pl.digspend or 1) + 0.2
end,

}

item[180] = { name = 'Tumbaga shovel',
ttl  = 1000,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {
	digspeed = 0.40, 
	dighit = 1,
	dighands = 0.40,
	dmgmin = 3,
	dmgmax = 3,
	dig = 4,
	digstat = 'legs'
},

onequip = function ()
	pl.digslowed = (pl.digslowed or 1) + 0.5
	pl.digspend = (pl.digspend or 1) - 0.3
end,
onunequip = function ()
	pl.digslowed = (pl.digslowed or 1) - 0.5
	pl.digspend = (pl.digspend or 1) + 0.3
end,


}


item[143] = { name = 'Nail',
craft = {'component','forgable'},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0, --dust
}



item[144] = { name = 'Spear',
ttl  = 50,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
equip = 'r',
tool = {

	dmgmin = 0,
	dmgmax = 15,
},
throw = 1.4,
proj = 8
}

item[306] = { name = 'Crude spear',
ttl  = 30,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
equip = 'r',
tool = {

	dmgmin = 2,
	dmgmax = 8,
},
throw = 1.2,
proj = 8
}


item[145] = { name = 'Spiked club',
ttl  = 200,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
equip = 'r',
tool = {

	dmgmin = 6,
	dmgmax = 6,
	digspeed = 1.2,
},
throw = 1.4,
proj = 8
}


item[349] = { name = 'Nunchucks',
ttl  = 300,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
equip = 'r',
tool = {

	dmgmin = 1,
	dmgmax = 1,
	digspeed = 0.2,
},
}


item[146] = { name = 'Weightened club',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
equip = 'r',
tool = {

	dmgmin = 7,
	dmgmax = 7,
},
throw = 1.4,
proj = 8
}

item[288] = { name = 'Quarterstaff',
ttl  = 200,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
equip = 'r',
tool = {

	digspeed = 1.5,
	dmgmin = 5,
	dmgmax = 14,
},
}

item[289] = { name = 'Fishing pole',
ttl  = 200,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
onuse = function (x,y,inv)

	pl.inv[inv].t = pl.inv[inv].t - 1

	if (readmap (pl.tx,pl.ty,'w') or 0)>0 then
		textwall (msg.item[289].txt[1])
		return
	end
	
	fishing_start (x,y)
end
}

item[101] = { name = 'Grappling hook',
score = 9999,
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
put = 11,
bounce = {0,0,0,0},
throw = 1.3,
onland = function (x,y,ox,oy)
	local r = px2tile (x,y)

	--
	if readmap (r.x,r.y,'b')==0 and readmap (r.x,r.y+1,'b')==0 then
		writemap (r.x,r.y,11,'b')
		
		if maptile (r.x+1,r.y,'solid')==1 or maptile (r.x-1,r.y,'solid')==1 then
			writemap (r.x,r.y,nil,'f')
			for i=r.y+1,r.y+10 do
				if readmap (r.x,i,'b')==0 then
					writemap (r.x,i,10)
				else
					break
				end
			end
		end
	else
		inv_ground_add (r.x,r.y,item_make (101))
	end

end,
}

--98

item[29] = { name = 'Flint',
craft = {'component'},
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 10,
laydie = 0,
burydie = 0,
throw = 1,
proj = 3
}





--STONES
------------------------------------------------------------------

item[305] = { name = 'Ceramic bullet',
craft = {'component'},
ttl  = 5,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 50,
burydie = 0,
throw = 1.1,
proj = 3,
dmg = 6,
}


item[31] = { name = 'Small stone',
craft = {'component'},
ttl  = 2,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
throw = 1.1,
proj = 3,
dmg = 4,
}

item[32] = { name = 'Nanoblock',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
throw = 1.5,
bounce = {0,0,0,0},
onland = function (x,y,ox,oy)
	local r = px2tile (x,y)
	if readmap (r.x, r.y,'b')==0 then
		writemap (r.x,r.y,4,'b')
	else
		inv_ground_add (r.x,r.y,item_make(32))
	end
	return false
end,
}

item[36] = { name = 'Pyrite',
craft = {'component','ore'},
ttl  = time.m,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
laydie = 121,
onheat = function (x,y,map,k)
	if map.de>200 then
		map.i[k].t = map.i[k].t - 1 
	end
end,
}

item[365] = { name = 'Little chick',
ttl  = time.min*5,
tti = 1,
ttg = time.min,
ttb = time.min,
invdie = 0,
laydie = 0,
ongrounddie = function (x,y)
	mob_create (x,y,18)
end,
oninvdie = function ()
	mob_create (pl.xt,pl.yt,18)
	sound_add ('chick', 44, {x = pl.tx, y = pl.ty, play = 1})
end,
}

item[358] = { name = 'Chicken',
ttl  = time.min*5,
tti = 1,
ttg = time.min,
ttb = time.min,
invdie = 0,
laydie = 0,
ongrounddie = function (x,y)
	mob_create (x,y,17)
end,
oninvdie = function ()
	mob_create (pl.xt,pl.yt,17)
	sound_add ('chick', 44, {x = pl.tx, y = pl.ty, play = 1})
end,
}

item[366] = { name = 'Dead chicken',
ttl  = time.d*2,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
ongrounddie = function (x,y, item)

if (readmap (x,y,'de') or 0)>50 then
	inv_ground_add (x,y,item_make(116))
else
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
end

end, 

oneat = function ()
	if love.math.random (0,100)<70 then buff_add (3,'add') end
end,

onheat = function (x,y,map,k)
	if map.de>100 then
		map.i[k].t = map.i[k].t - item[map.i[k].i].ttl * 0.1
		map.i[k].burn = (map.i[k].burn or 0) + 1
	end
end,

calories = 20,
diet = {'protein','freezable'},
}

item[359] = { name = 'Chicken egg',
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 363,
laydie = 363,
ongrounddie = function (x,y)

	local de = readmap (x,y,'de') or 0
	if love.math.random (0,100)<30 or de>0 then
		achi_add (41,1)
		mob_create (x,y,18)
	else
		inv_ground_add (x,y,item_make(362))
	end
end,

onheat = function (x,y,map,k)
	if map.de<100 then
		map.i[k].t = map.i[k].t - 1000
	else
		map.i[k] = nil
		inv_ground_add (x,y,item_make(360))
	end
end,

oninvdie = function ()
	mob_create (pl.xt,pl.yt,17)
end,
diet = {'protein','fat'},
calories = 7,
}


item[360] = { name = 'Boiled egg',
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,
laydie = 0,
diet = {'protein','fat'},
calories = 12,
oneat = function ()
	inv_add (item_make(361))
end,
}

item[367] = { name = 'Omelette',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1, 
invdie = 182, 
laydie = 182,
burydie = 182,
diet = {'protein','fat'},
calories = 40,
oneat = function ()
	inv_add(item_make(182))
end
}


item[361] = { name = 'Egg shell',
bury = {},
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
}

item[362] = { name = 'Chicken shit',
bury = {},
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
ongrounddie = function (x,y) 
	fertilize (x,y+1,10)
end,
}

item[363] = { name = 'Rotten egg',
bury = {},
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
throw = 1.2,
proj = 17
}

item[364] = { name = 'Feathers',
bury = {},
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
}


item[6] = { name = 'Worm',
bury = {[102] = 1, [1] = 1, [2] = 1, [12] = 2, [13] = 3, [47] = 0, [35] = 0},
ttl  = time.h,
tti = 1,
ttg = time.h/32,
ttb = 10,
ongrounddie = function (x,y)
	mob_create (x,y,3)
end,
oninvdie = function ()
	mob_create (pl.xt,pl.yt,3)
end,
calories = 5,
diet = {'protein','freezable'},
transformi = 23,
transformpower = 10,
}

item[279] = { name = 'Pwned worm',
ttl  = time.h,
tti = 1,
ttg = 1,
ttb = 1,
calories = 1,
diet = {'fat'},
}


item[99] = { name = 'Huge worm',
bury = {[102] = 1, [1] = 1, [2] = 1, [12] = 2, [13] = 3, [47] = 0},
ttl  = time.h,
tti = 1,
ttg = time.h/64,
ttb = 10,
ongrounddie = function (x,y)
	mob_create (x,y,4)
end,
calories = 30,
diet  = {'fat','freezable'},
transform = 92,
transformpower = 20,
}


item[12] = { name = 'Skull',
craft = {'component'},
ttl  = time.d,
tti = 0,
ttg = 1,
ttb = 0,
--equip = "l",

ongrounddie = function (x,y)
	mob_create (x,y,12)
	textwall (msg.item[12].txt[1])
end,

transform = 89,
transformpower = 10,
}

item[13] = { name = 'Sinew',
craft = {'string','inspire'},
ttl  = time.w,
tti = 0,
ttg = 1, 
ttb = 10, 
bury = {[102] = 1, [1] = 1, [2] = 1, [12] = 2, [13] = 3, [47] = 0},
invdie = 3,    
laydie = 3,
burydie = 3, -- die while buried
}

------------------------------ MEATS

item[290] = { name = 'Cavebass',
ttl  = time.d*2,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
calories = 45,
diet = {'protein','freezable'},
}


item[14] = { name = 'Raw meat',
craft = {'component'},
ttl  = time.d*2,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
ongrounddie = function (x,y, item)

if (readmap (x,y,'de') or 0)>50 then
	inv_ground_add (x,y,item_make(116))
else
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
	inv_ground_add (x,y,item_make(6),{groundlast = true})
end

end, 
oneat = function ()
	if love.math.random (0,100)<70 then buff_add (3,'add') end
end,



onheat = function (x,y,map,k)
	if map.de>100 then
		map.i[k].t = map.i[k].t - item[map.i[k].i].ttl * 0.1
		map.i[k].burn = (map.i[k].burn or 0) + 1
	end
end,

calories = 20,
diet = {'protein','freezable'},
}


item[116] = { name = 'Burned meat',
ttl  = time.d*4,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
calories = 25,
diet = {'protein','freezable'},
}

item[117] = { name = 'Salt-cured meat',
ttl  = time.m*3,
tti = 1,
ttg = 1, 
ttb = 1, 
invdie = 0,
laydie = 0,
burydie = 0,
calories = 20,
diet = {'protein'},
oneat = function (x,y)
	stat_spend ("water",20)
end
}


item[353] = { name = 'Doctor sausage',
ttl  = time.m,
tti = 1,
ttg = 1, 
ttb = 1, 
invdie = 0,
laydie = 0,
burydie = 0,
calories = 20,
diet = {'protein','freezable'},
oneat = function (x,y)
	buff_remove (21)
end

}


item[118] = { name = 'Clay-covered meat',
ttl  = time.d,
tti = 1,
ttg = 1, 
ttb = 1, 
invdie = 0,
laydie = 0,
burydie = 0,
ongrounddie = function (x,y)
	if (readmap (x,y,'de') or 0) > 50 then
		inv_ground_add (x,y,item_make(119))
	end
end,

onheat = function (x,y,map,k)
	if map.de>100 then
		map.i[k].t = map.i[k].t - item[map.i[k].i].ttl * 0.1
		map.i[k].burn = (map.i[k].burn or 0) + 1
	end
end,

}

item[119] = { name = 'Clay-roasted meat',
ttl  = time.d,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
calories = 50,
diet = {'protein','freezable'},
}

item[267] = { name = 'Filth colon',
ttl  = time.d,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 6,
burydie = 0,
}

item[268] = { name = 'Large intestine',
ttl  = time.w,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
}

item[269] = { name = 'Snake skin',
ttl  = time.w,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
}

item[270] = { name = 'Sling',
ttl  = time.w*2,
equip = 'r',
tti = 1,
ttg = 1, 
ttb = 1, 
invdie = 0,
laydie = 0,
burydie = 0,
sling = {items = {31,265,305}, add=1.6},
}

item[271] = { name = 'Sling +1',
ttl  = time.w*2,
equip = 'r',
tti = 1,
ttg = 1, 
ttb = 1, 
invdie = 0,
laydie = 0,
burydie = 0,
sling = {items = {5,31,265,305}, add=2},
}


item[350] = { name = 'Crown of thorns',
ttl  = 10000,
equip = 'h',
tti = 0,
ttg = 0, 
ttb = 0, 
invdie = 0,
laydie = 0,
burydie = 0,
onstruck = function (hp,what)
	if what and what.type then
		mob_hit (what.n, 1)
	end
	return hp
end,

onequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp + 25
end,
onunequip = function ()
	pl.stats.body.maxhp = pl.stats.body.maxhp + 25
end,

light = {64,1,1,0.2},

}

item[351] = { name = 'Snake ring',
ttl  = 10000,
equip = 'a',
tti = 0,
ttg = 0, 
ttb = 0, 
invdie = 0,
laydie = 0,
burydie = 0,
onstruck = function (hp,what)
	if what and what.type and love.math.random (0,100)<5 then
		mob_buff (mobs[what.n], 2)
	end
	return hp
end,

onequip = function ()
	pl.stats.water.maxhp = pl.stats.water.maxhp + 25
	pl.stats.body.maxhp = pl.stats.body.maxhp + 25
	pl.invsize = pl.invsize + 2
end,
onunequip = function ()
	pl.stats.water.maxhp = pl.stats.water.maxhp + 25
	pl.stats.body.maxhp = pl.stats.body.maxhp + 25
	pl.invsize = pl.invsize - 2
end,

light = {64,1,1,0.2},

}


item[272] = { name = 'Chitin armor',
ttl  = 1000,
equip = 'b',
tti = 0,
ttg = 0, 
ttb = 0, 
invdie = 0,
laydie = 0,
burydie = 0,
onstruck = function (hp,what)
	return hp * 0.8
end
}


item[323] = { name = 'Abdominal armor',
ttl  = 1000,
equip = 'b',
tti = 0,
ttg = 0, 
ttb = 0, 
invdie = 0,
laydie = 0,
burydie = 0,
onstruck = function (hp,what)
	return hp * 0.9
end
}

item[324] = { name = 'Kiribati armor',
ttl  = 1000,
equip = 'b',
tti = 0,
ttg = 0, 
ttb = 0, 
invdie = 0,
laydie = 0,
burydie = 0,
onstruck = function (hp,what)
	if hp>1 then hp = hp - 1 end
	return hp
end
}

item[325] = { name = 'Copper armor',
ttl  = 1000,
equip = 'b',
tti = 0,
ttg = 0, 
ttb = 0, 
invdie = 0,
laydie = 0,
burydie = 0,
onstruck = function (hp,what)
	if hp>1 then
		return hp * 0.75
	else
		return hp
	end
end,

onequip = function ()
	pl.invsize = pl.invsize - 2
	inv_overflow ()
end,
onunequip = function ()
	pl.invsize = pl.invsize + 2
end,

}

item[44] = { name = 'Slime corpse',
craft = {'component'},
ttl  = time.d,
tti = 1,
ttg = 2, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
ongrounddie = function (x,y) 
inv_ground_add (x,y,item_make(6),{groundlast = true})
inv_ground_add (x,y,item_make(6),{groundlast = true})
inv_ground_add (x,y,item_make(6),{groundlast = true})
end, 
ontake = function () pl.slowed = pl.slowed - 0.2 end,
ondrop = function () pl.slowed = pl.slowed + 0.2 end,
}

item[280] = { name = 'Robot shell',
ttl  = time.y,
tti = 1,
ttg = 1, 
ttb = 1, 
invdie = 0,
laydie = 0,
burydie = 0,
ontake = function () pl.slowed = pl.slowed - 0.2 end,
ondrop = function () pl.slowed = pl.slowed + 0.2 end,
}

item[45] = { name = 'Corpse',
craft = {'component'},
--ttl  = time.w,
ttl  = time.w,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
oneat = function (x,y)
	pl.unrest = time.h
	game.fadein = 0.5
	inv_ground_add (x,y,item_make(11))
	inv_ground_add (x,y,item_make(11))
	inv_ground_add (x,y,item_make(12))
	inv_ground_add (x,y,item_make(13))
end,
ongrounddie = function (x,y) 
inv_ground_add (x,y,item_make(6))
inv_ground_add (x,y,item_make(6))
inv_ground_add (x,y,item_make(6))
inv_ground_add (x,y,item_make(11))
inv_ground_add (x,y,item_make(95))
inv_ground_add (x,y,item_make(11))
inv_ground_add (x,y,item_make(11))
inv_ground_add (x,y,item_make(12))
end, 
ontake = function () pl.slowed = pl.slowed - 0.4 end,
ondrop = function () pl.slowed = pl.slowed + 0.4 end,
calories = 50,
diet = {'protein'},
}

item[103] = { name = 'Spider corpse',
craft = {'component'},
ttl  = time.m,
tti = 1,
ttg = 5, 
ttb = 1, 
bury = {[47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 0,
ontake = function () pl.slowed = pl.slowed - 0.2 end,
ondrop = function () pl.slowed = pl.slowed + 0.2 end,
}

item[273] = { name = 'Stone louse corpse',
craft = {'component'},
ttl  = time.w,
tti = 1,
ttg = 1, 
ttb = 1, 
invdie = 0,
laydie = 0,
burydie = 0,
ontake = function () pl.slowed = pl.slowed - 0.1 end,
ondrop = function () pl.slowed = pl.slowed + 0.1 end,

ongrounddie = function (x,y, item)
	mob_create (x,y,15)
end, 

}


item[274] = { name = 'Stinger',
ttl  = 50,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
equip = 'r',
tool = {

	dmgmin = 3,
	dmgmax = 5,
},
throw = 1.4,
proj = 11
}

item[278] = { name = 'Poisoned stinger',
ttl  = 50,
tti = 0,
ttg = 0,
ttb = 0,
invdie = 0,
equip = 'r',
tool = {
	dmgmin = 3,
	dmgmax = 5,
},
throw = 1.4,
proj = 11,
onhit = function (x,y,what,m,i)
	mob_buff (mobs[m.n], 2)
end
}


item[89] = { name = "Web",
craft = {'component'},
ttl  = time.d,
tti = 1,
ttg = 5, 
ttb = 10, 
invdie = 0,
laydie = 0,
burydie = 0,
}

item[90] = { name = "Web piece",
craft = {'component'},
ttl  = time.y,
tti = 1,
ttg = 5, 
ttb = 10, 
invdie = 0,
laydie = 0,
burydie = 0,
}

item[91] = { name = "Pumpkin",
craft = {'component'},
ttl  = time.w*2,
put = 90,
tti = 1,
ttg = 1, 
ttb = 10, 
bury = {[102] = 1, [1] = 1, [2] = 1, [12] = 2, [13] = 3},
invdie = 59,
laydie = 0,
burydie = 0,
}

item[92] = { name = "Jack-o'-lantern",
craft = {'component'},
ttl  = time.d,
put = 89,
tti = 1,
ttg = 1, 
ttb = 10, 
bury = {[102] = 1, [1] = 1, [2] = 1, [12] = 2, [13] = 3},
invdie = 59,
laydie = 94,
burydie = 59,
}

item[93] = { name = "Pumpkin piece",
craft = {'component'},
ttl  = time.d,
tti = 1,
ttg = 1, 
ttb = 1, 
bury = {[102] = 10, [1] = 10, [2] = 10, [12] = 20, [13] = 30, [47] = 0.1},
invdie = 59,
laydie = 59,
burydie = 59,
calories = 25,
diet = {'veggies','freezable'},
}

item[94] = { name = 'Pumpkin seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) growup (x,y,88) end, 
}

item[100] = { name = 'Corn seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) growup (x,y,100) end, 
}


item[188] = { name = 'Rice portion',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
--oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) growup (x,y,154) end, 
hcalories = 20
}

item[189] = { name = 'Rice seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) growup (x,y,154) end, 
}


item[190] = { name = 'Tomato',
ttl  = time.d*4, 
tti = 1,
ttg = 1, 
ttb = time.d,
bury = {[102] = 1, [12] = 2, [13] = 3, },
autobury = 1,
invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) growup (x,y,155) end, 
oneat = function (x,y)
	pl.shit[191] = 1
	stat_recovery ("water",10)
end,
calories = 5,
diet = {'veggies','fruits'},
}

item[191] = { name = 'Tomato seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},

invdie = 0,    
laydie = 0,
burydie = 0,
onburydie = function (x,y) growup (x,y,155) end, 
}


item[194] = { name = 'Seaweed',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,
laydie = 0,
burydie = 0,
calories = 10,
diet = {'exotic'},
}

item[355] = { name = 'Dandelion',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,
laydie = 0,
burydie = 0,
calories = 10,
diet = {'exotic'},
}

item[275] = { name = 'Spider egg',
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 0,
invdie = 0,
laydie = 0,
burydie = 0,
ongrounddie = function (x,y, item)
	mob_create (x,y,2)
end, 

oneat = function ( ... )
	buff_add (8)
end,

calories = 20,
diet = {'exotic'},

transformi = 359,
transformpower = 10,

}

item[276] = { name = 'Throwing web',
craft = {'component','smash'},
bury = {},
ttl  = 100,
tool = {
	hithit = 1, --na
	dmgmin = 1,
	dmgmax = 3,
},
tti = 0,
ttg = 0,
ttb = 0,
invdie = 10,
laydie = 0,
burydie = 0,
throw = 0.7,
proj = 12,
bounce = {0,0,0,0},
}

item[126] = { name = 'Corn',
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[102] = 1000, [12] = 1000, [13] = 1000, [47] = 0.1},
invdie = 0,
laydie = 0,
burydie = 100,
calories = 20,
diet = {'carbs','freezable'},
oneat = function (x,y)
	pl.shit[100] = 1
end,

ongrounddie = function (x,y, item)
	if (readmap (x,y,'de') or 0)>50 then
		inv_ground_add (x,y,item_make(127))
	end
end, 

onheat = function (x,y,map,k)
	if map.de>100 then
		map.i[k].t = map.i[k].t - item[map.i[k].i].ttl * 0.1
		map.i[k].burn = (map.i[k].burn or 0) + 1
	end
end
}


item[217] = { name = 'Nixtamalized corn',
ttl  = time.d,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,
laydie = 0,
}



item[127] = { name = 'Popcorn',
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0,
laydie = 0,
calories = 30,
diet = {'carbs'},
}

item[318] = { name = 'Antidote',
bury = {[107] = 1, [47] = 0.1},
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 5,
calories = 0,
oneat = function ( ... )
	buff_remove (2)
end,
}

item[112] = { name = 'Berries',
bury = {[107] = 1, [47] = 0.1},
ttl  = time.d*3,
tti = 1,
ttg = 1,
ttb = 5,
calories = 10,
diet = {'fruits'},
onburydie = function (x,y) growup (x,y,112) end, 
oneat = function ( ... )
	buff_remove (2)
	pl.shit[113] = 1
end,
transformi = 190,
transformpower = 10,
}

item[113] = { name = 'Bog-berry seed',

tag = 'seed',
ttl  = time.m, 
tti = 1,
ttg = 30, 
ttb = time.m/time.h, 
autobury = 1,
oninfo = function (x,y,inv) return msg.game[46] end,
--bury = {[102] = 1, [12] = 2, [13] = 3, [47] = 0},
bury = {[107] = 1},

onburydie = function (x,y) growup (x,y,112) end, 
}

item[114] = { name = 'Dead pixel',
craft = {'component'},
bury = {[52] = 1},
autobury = 1,
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = time.w,
onburydie = function (x,y) growup (x,y,117) end, 
}

item[122] = { name = 'Water chip',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
transformi = 123,
transformpower = 20,
}

item[123] = { name = 'G.E.C.K.',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
onuse = function (x,y,inv)
	pl.inv[inv] = nil
	inv_add (item_make (125))
	inv_add (item_make (124))
	inv_add (item_make(38))
	inv_add (item_make(100))
	inv_add (item_make(100))
	inv_add (item_make(176))
	inv_add (item_make(59))
	inv_add (item_make(156))
	inv_add (item_make(35))
end
}

item[125] = { name = 'Briefcase',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
equip = "l",
onequip = function ()
	textwall (msg.game[33])
	pl.invsize = pl.invsize + 7
end,
onunequip = function ()
	pl.invsize = pl.invsize - 7
end,
}


item[115] = { name = 'Pinch of salt',
craft = {'component'},
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
transformi = 196,
transformpower = 30,
hcalories = 10
}

item[17] = { name = 'Token Of Value',
desc = 'Bring it to The Machine',
craft = {'component'},
ttl  = 10000,
tti = 0,
ttg = 0,
ttb = 0,
light = {64,1,1,0.7}
}

item[20] = { name = 'Feces',
ttl  = time.w,
tti = 1,
ttg = 1,
ttb = 10,
invdie = 0,
laydie = 0,
burydie = 0,
transformi = 131,
transformpower = 10,
throw = 1,
oneat = function ()
	inv_add (item_make (20))
	stat_spend ('food',10)
	textwall (msg.item[20].txt[1])
	buff_add (26)
end,
calories = 1
}



item[22] = { name = 'Bread',
ttl  = time.w,
tti = 1,
ttg = 0.5,
ttb = 10,
invdie = 0,
laydie = 0,
burydie = 0,
calories = 20,
diet = {'carbs'},
}



item[24] = { name = 'Basket',
f_burn = 1,
f_heat = 400,
f_start = 300,
craft = {'inspire'},
ttl  = time.w*2,
tti = 0,
ttg = 0,
ttb = 0,
equip = "l",
onequip = function ()
	textwall (msg.game[33])
	pl.invsize = pl.invsize + 5
end,
onunequip = function ()
	pl.invsize = pl.invsize - 5
end,
}

item[283] = { name = 'Rope belt',
ttl  = time.m*2,
tti = 0,
ttg = 0,
ttb = 0,
equip = "t",
onequip = function ()
	textwall (msg.game[33])
	pl.invsize = pl.invsize + 3
end,
onunequip = function ()
	pl.invsize = pl.invsize - 3
end,
}

item[26] = { name = 'Flashlight',
score = 100000,
ttl  = time.h*24, 
tti = 1,
ttg = 1, 
ttb = 0, 
invdie = 27,    
laydie = 27,
bounce = {1,1,1,1}, -- throwing bounce
throw = 1.5,
onequip = nil,
onunequip = nil,
light = {75,0.9,0.9,0.9},
onland = function (x,y,ox,oy,inv)
	inv_add (inv)
	return false
end,
}

item[27] = { name = 'Drained flashlight',
score = 100000,
ttl  = time.h, 
tti = 0,
ttg = 1, 
ttb = 0, 
invdie = 0,    
laydie = 0,
bounce = {1,1,1,1}, -- throwing bounce
onequip = nil,
onunequip = nil,
light = {40,0.2,0.5,0.2},
transformi = 26,
transformpower = 2,
ongrounddie = function ( ... )
	pl.noflashlight = true
end
}

item[332] = { name = 'Haed assploded',
score = 100000,
ttl  = time.d*7,
equip = 'h',
tti = 1,
ttg = 1, 
ttb = 0, 
invdie = 0,    
laydie = 0,
onequip = nil,
onunequip = nil,
light = {80,1,1,1},
}


item[284] = { name = 'Headlight',
score = 100000,
ttl  = time.h*12, 
equip = 'h',
tti = 1,
ttg = 1, 
ttb = 0, 
invdie = 285,    
laydie = 285,
onequip = nil,
onunequip = nil,
light = {80,1,1,1},
transformi = 26,
transformpower = 3,
}

item[285] = { name = 'Drained headlight',
score = 100000,
ttl  = time.h, 
equip = 'h',
tti = 0,
ttg = 1, 
ttb = 0, 
invdie = 0,    
laydie = 0,
bounce = {1,1,1,1}, -- throwing bounce
onequip = nil,
onunequip = nil,
light = {40,0.2,0.5,0.2},
transformi = 284,
transformpower = 3,
ongrounddie = function ( ... )
	pl.noflashlight = true
end
}

item[34] = { name = 'Big Fucking Stone',
craft = {'component'},
ttl  = 10000,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
put = 33,
onland = function (x,y,ox,oy)
	local r = px2tile (x,y)
	writemap (r.x,r.y,34,'b')
	return false
end,
ontake = function () pl.slowed = pl.slowed - 0.3 end,
ondrop = function () pl.slowed = pl.slowed + 0.3 end,
}
	
item[35] = { name = 'Instant water',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
throw = 1.5,
--bounce = {0,0,0,0},
onland = function (x,y,ox,oy)
	local r = px2tile (x,y)
	local w = readmap (r.x,r.y,'w') or 0
	writemap (r.x,r.y,100000+w,'w')
	return false
end,
}


item[343] = { name = 'Shrapnel grenade',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
throw = 1,
bounce = {0,0,0,0},
--bounce = {1,1,1,1},

	onland = function (x,y,ox,oy)
	local r = px2tile (x,y)

	sound_add (x.."-"..y.."grenade", 46, {x=r.x,y=r.y})
	new_worldani ('shrapnel','assplode')

	worldani.shrapnel.truex = r.x * cf.w - 64
    worldani.shrapnel.truey = r.y * cf.h - 64
    --worldani.boom.ani_size = 1


end,
proj = 1
}


item[327] = { name = 'Hand grenade',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
throw = 1,
bounce = {0,0,0,0},
--bounce = {1,1,1,1},

	onland = function (x,y,ox,oy)
	local r = px2tile (x,y)

	sound_add (x.."-"..y.."grenade", 46, {x=r.x,y=r.y})
	new_worldani ('boom','assplode')
	worldani.boom.truex = r.x * cf.w - 64
    worldani.boom.truey = r.y * cf.h - 64
    --worldani.boom.ani_size = 1


end,
proj = 14
}


item[328] = { name = 'Bouncing grenade',
ttl  = 100,
tti = 0,
ttg = 0,
ttb = 0,
laydie = 0,
burydie = 0,
throw = 1,
--bounce = {0,0,0,0},
bounce = {1,1,1,1},

	onland = function (x,y,ox,oy)
	local r = px2tile (x,y)

	sound_add (x.."-"..y.."grenade", 46, {x=r.x,y=r.y})
	new_worldani ('boom','assplode')
	worldani.boom.truex = r.x * cf.w - 64
    worldani.boom.truey = r.y * cf.h - 64

end,
proj = 14
}


item[183] = { name = 'Wet ectoplasm',
ttl  = time.h*2,
tti = 1,
ttg = 10,
ttb = 10,
bury = {[1]=1,[2]=1,[8]=1,[17]=1,[31]=1,[32]=1,[99]=1,[12]=1,[13]=1,[103]=1},
autobury = 1,
invdie = 184,    
laydie = 184,
burydie = 0,

onburydie = function (x,y) 
	growup (x,y,147) 
end,

onheat = function (x,y,map,k)
	map.i[k].t = map.i[k].t - item[map.i[k].i].ttl * 0.1
end,

}


item[192] = { name = 'Cave jelly',
ttl  = time.m,
tti = 1,
ttg = 1,
ttb = 1,
bury = {[1]=1,[2]=1,[8]=1,[17]=1,[31]=1,[32]=1,[99]=1,[12]=1,[13]=1,[103]=1},
autobury = 1,
invdie = 184,    
laydie = 184,
burydie = 0,
onburydie = function (x,y) 
	growup (x,y,147) 
end,

calories = 10,
diet = {'fat'},


}


item[184] = { name = 'Dry ectoplasm',
ttl  = time.m,
tti = 0,
ttg = 1,
ttb = 1,
bury = {[1] = 1, [2] = 1, [102] = 1, [12] = 2, [13] = 3, },
invdie = 0,    
laydie = 0,
burydie = 0,

onwater = function (x,y,map,k)
	inv_ground_replace (x,y,k,item_make (183)) 
end,
}


item[193] = { name = 'Hearthstone',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onuse = function (x,y,inv)
	
	inv_remove (inv)
	game.fadein = 0.3
	player_pos_reset ()

end
}


item[320] = { name = 'Wormhole generator',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onuse = function (x,y,inv)
	
	if pl.stats.power.hp>5 then
		stat_spend ('power',5)
		game.fadein = 0.3
		player_pos_reset ()
	else
		textwall (msg.game[17])
	end 

end
}


item[321] = { name = 'Four leaf clover',
ttl  = time.m, 
tti = 1,
ttg = 1, 
ttb = 1000,
invdie = 0,    
laydie = 0,
burydie = 0,
ongrounddie = nil,
bounce = nil,
calories = 1,
oneat = function ()
	buff_add (love.math.random (1,#buff))
end
}


item[322] = { name = 'Lucky charm',
ttl  = 100000, 
tti = 0,
ttg = 0, 
ttb = 0,
invdie = 0,    
laydie = 0,
burydie = 0,
ongrounddie = nil,
bounce = nil,
equip = 'n',
onstruck = function (hp,what)
	if love.math.random (0,100)<8 then
		table.insert (sct,{font='norm', x=pl.x+love.math.random(-8,8),y=pl.y-50,text=text_color("{#ead4aaff}"..msg.item[322].txt[1]),ttl=1.8,xs=pl.flip*-1*(love.math.random(5,30))})
		return 0
	end
	return hp
end
}


item[307] = { name = 'Sence of direction',
ttl  = time.y,
tti = 1,
ttg = 1,
ttb = 1,
invdie = 0, 
laydie = 0,
burydie = 0,
onuse = function (x,y,inv)
	
	local how = function (x,y)
		local w = readmap (x,y,'b') or 0
		if w==49 or w==134 then
			return true
		end
	end

	local x,y = find_block (pl.xt, pl.yt,how,400)

	local str = ""


	if x then

		if x>pl.xt then str = str..(x-pl.xt).."→ " end
		if x<pl.xt then str = str.."←"..(pl.xt-x).." " end
		if x==pl.xt then str = str.."x " end
		
		if y>pl.yt then str = str..(y-pl.yt).."↓" end
		if y<pl.yt then str = str.."↑"..(pl.yt-y) end
		if y==pl.yt then str = str.."x" end
		
		textwall (msg.item[307].txt[2]..str)

	else
		textwall (msg.item[307].txt[1])
	end

end
}

item[308] = { name = 'Tail trimmer',
bury = {},
ttl  = 50,
tti = 0,
ttg = 0,
ttb = 0,
equip = 'r',
invdie = 0,
laydie = 0,
burydie = 0,
tool = {

	digspeed = 0.85, 
	dighands = 0.85,
	cut = 2,

	crafthit = 1,

	dmgmin = 0,
	dmgmax = 0,


},

}

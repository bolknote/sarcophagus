--
--
--
--
--
--


stone = {}

stone[1] = { name = 'Lifeless dirt',
	cr = 1,
	gather = {dig = 0},
	digaround = 0, -- can be dug if dig around          n/a
	digtime = 1, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 17, 
	--loot = {{i=6,p=5},{i=0,p=90}},           
	dpr = 0, -- protect bottom
	col = 1, -- collision
	br = 1,
	solid = 1,
	ttl = nil,
	die = 0,            
	ondie = function (...) end,   --                    
	ondestroy = nil, --                                 
	onfalling = nil, -- 								
	onfell = nil, --
	spr = img_load("brick1.png"),
	check = nil,
	transform = nil, --alchemy
	transformi = nil, --alchemy to i
	onstep = nil,
	onstay = nil,
}

stone[99] = { name = 'Thin lifeless dirt',
	cr = 1,
	gather = {dig = 0},
	digtime = 0.3, -- seconds
	digtoinv = 0, -- 0 - hold or item ids
	digtoid = 0, 
	col = 1, -- collision
	br = 1,
	solid = 1,
	die = 0,            
	spr = img_load("brick49.png"),
	onstepon = function (x,y,xo,yo)
		local cd = readmap (x,y,'cd') or 0
		cd = cd + 1
		writemap (x,y,cd,'cd')

		if cd>2 and readmap (x,y-1,'b')==0 then
			writemap (x,y,17,'clear')
		end
	end,
}

-- plants
---------------------------------------------------------------


stone[100] = { name = 'Corn',
	zindex = 1,
	gather = {dig = 0},
	digtime = 5, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 0, 
	col = 0, -- collision
	solid = 0,
	die = 100,  
	spr = img_load("corn6.png"),

	sprs = {
	img_load("corn1.png"),
	img_load("corn2.png"),
	img_load("corn3.png"),
	img_load("corn4.png"),
	img_load("corn5.png"),
	img_load("corn6.png"),
	img_load("corn7.png"), 
	img_load("corn8.png"),
	},

	oninfo = function (x,y)
		return draw_growpc (x,y)
	end,

	ttl = time.h*3,          
	
	plant =
	{
		stages = 8,
		opt = 6,
		seed = 7,
		dead = 8,
		loot = {
			[1] = {3},
			[2] = {3},
			[3] = {3,3},
			[4] = {3,3},
			[5] = {3,126},
			[6] = {126,126},
			[7] = {100,100,100,37},
			[8] = {37},
		},

		step = 0.1,
		laststep = 0.05,
		neg = time.d*5,
		wt = 2,
		e = 2,
		light = 1,
		flood = 1

	},

	ondig = function (x,y) return plant_dig (x,y,100) end,
	ondie = function (x,y) plant_grow (x,y,100) end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		local vr = readmap (wx,wy,'vr') or 1
		if vr==1 then
			love.graphics.draw (quad, stone[100].sprs[math.floor(stage)],x,y-32,0,2,2)
		else
			love.graphics.draw (quad, stone[100].sprs[math.floor(stage)],x+32,y-32,0,-2,2)
		end
	end,
}



stone[135] = { name = 'Chard',
	zindex = 1,
	gather = {dig = 0},
	digtime = 5, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 0, 
	col = 0, -- collision
	solid = 0,
	die = 135,   
	spr = img_load("blitva1.png"),

	sprs = {
	img_load("blitva1.png"),
	img_load("blitva2.png"),
	img_load("blitva3.png"),
	img_load("blitva4.png"),
	img_load("blitva5.png"),
	img_load("blitva6.png"),
	},

	oninfo = function (x,y)
		return draw_growpc (x,y)
	end,

	ttl = time.h*1.5,         

	plant =
	{
		stages = 6,
		opt = 4,
		seed = 5,
		dead = 6,
		loot = {
			[1] = {3},
			[2] = {175},
			[3] = {175,175},
			[4] = {175,175,175},
			[5] = {175,176,176},
			[6] = {37}
		},

		step = 0.1,
		laststep = 0.05,
		neg = time.d*2,
		wt = 2,
		e = 1,
		light = 1,
		flood = 1

	},

	ondig = function (x,y)
		return plant_dig (x,y,135)
	end,

	ondie = function (x,y) 
		plant_grow (x,y,135)
	end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		local vr = readmap (wx,wy,'vr') or 1
		if vr==1 then
			love.graphics.draw (quad, stone[135].sprs[stage],x,y,0,2,2)
		else
			love.graphics.draw (quad, stone[135].sprs[stage],x+32,y,0,-2,2)
		end

	end,
}




stone[88] = { name = 'Pumpkin',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
dpr = 1,
col = 0, -- collision
digtime = 5, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0,
die = 88, 
spr = img_load("pumpkin9.png"),
sprs = {
	img_load("pumpkin1.png"),
	img_load("pumpkin2.png"),
	img_load("pumpkin3.png"),
	img_load("pumpkin4.png"),
	img_load("pumpkin5.png"),
	img_load("pumpkin6.png"),
	img_load("pumpkin7.png"),
	img_load("pumpkin8.png"),
	img_load("pumpkin12.png"),
	img_load("pumpkin13.png"),
},

ttl = time.h*9,     

	plant =
	{
		stages = 10,
		opt = 8,
		seed = 9,
		dead = 10,
		loot = {
			[1] = {3},
			[2] = {3},
			[3] = {3,3},
			[4] = {3,3},
			[5] = {3,3},
			[6] = {3,3,3},
			[7] = {3,3,3,3},
			[8] = {91},
			[9] = {93,94,94,94},
			[10] = {37},
		},

		step = 0.2,
		laststep = 0.02,
		neg = time.d*4,
		wt = 4,
		e = 2,
		light = 1,
		flood = 1
	},



	oninfo = function (x,y)	return draw_growpc (x,y) end,
	ondig = function (x,y) return plant_dig (x,y,88) end,
	ondie = function (x,y) plant_grow (x,y,88) end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		local vr = readmap (wx,wy,'vr') or 1
		if vr==1 then
			love.graphics.draw (quad, stone[88].sprs[math.floor(stage)],x,y,0,2,2)
		else
			love.graphics.draw (quad, stone[88].sprs[math.floor(stage)],x+32,y,0,-2,2)
		end
	end,

}



stone[62] = { name = 'Carrot',
zindex = 1,
gather = {dig = 0}, 
dpr = 1,
col = 0, -- collision
digtime = 5, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 
die = 62, 
spr = img_load("carrot3.png"),
sprs = {
	img_load("carrot1.png"),
	img_load("carrot2.png"),
	img_load("carrot3.png"),
	img_load("carrot4.png"),
	img_load("carrot5.png"),
	img_load("carrot6.png"),
	img_load("carrot7.png"),
	img_load("carrot8.png"),
	img_load("carrot9.png"),
},


ttl = time.h,     

	plant =
	{
		stages = 9,
		opt = 6,
		seed = 8,
		dead = 9,
		loot = {
			[1] = {3},
			[2] = {3},
			[3] = {53},
			[4] = {53,3},
			[5] = {53,3,3},
			[6] = {53,53,3},
			[7] = {53,53,3},
			[8] = {53,53,52,52},
			[9] = {53,52,37},
		},

		step = 0.05,
		laststep = 0.02,
		neg = time.d*7,
		wt = 1,
		e = 0.8,
		light = 1,
		flood = 1
	},

oninfo = function (x,y)	return draw_growpc (x,y) end,
ondig = function (x,y) return plant_dig (x,y,62) end,
ondie = function (x,y) plant_grow (x,y,62) end, 

ondestroy = function (x,y,z)
	local stage = readmap (x,y,'stage') or 1
	if stage>2 then inv_ground_add (x,y,item_make(53)) end
	if stage>5 then inv_ground_add (x,y,item_make(53)) end
	return z
end,

ondraw = function (x,y,wx,wy)
	local stage = readmap (wx,wy,'stage') or 1
	local vr = readmap (wx,wy,'vr') or 1
	if vr==1 then
		love.graphics.draw (quad, stone[62].sprs[math.floor(stage)],x,y,0,2,2)
	else
		love.graphics.draw (quad, stone[62].sprs[math.floor(stage)],x+32,y,0,-2,2)
	end
end,

}




stone[189] = { name = 'Tuber plant',
zindex = 1,
gather = {dig = 0}, 
dpr = 1,
col = 0, -- collision
digtime = 5, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 
die = 189, 
spr = img_load("potatoes1.png"),
sprs = {
	img_load("potatoes1.png"),
	img_load("potatoes2.png"),
	img_load("potatoes3.png"),
	img_load("potatoes4.png"),
	img_load("potatoes5.png"),
},


ttl = time.h,     

plant =
{
	stages = 5,
	opt = 6,
	seed = 8,
	dead = 5,
	loot = {
		[1] = {},
		[2] = {3},
		[3] = {3},
		[4] = {3},
		[5] = {37},
		

	},

	step = 0.05,
	laststep = 0.1,
	neg = time.d,
	wt = 1,
	e = 1,
	light = 1,
	flood = 1
},

oninfo = function (x,y)	return draw_growpc (x,y) end,
ondig = function (x,y) return plant_dig (x,y,189) end,
ondie = function (x,y) 

	plant_grow (x,y,189) 

	local problem = readmap (x,y,'problem')
	local stage = readmap (x,y,'stage') or 1

	if stage>5 then
		writemap (x,y,0,'clear')
	end

	--2%
	local i = readmap (x, y+1, 'i') or {}

	if #i>7 then
		writemap (x,y,5,'stage')
	else
		if problem==nil and stage>2 and stage<5 and love.math.random (0,100)<5 then
			inv_ground_add (x, y+1, item_make(333))
		end
	end

end, 

ondestroy = function (x,y,z)
	local stage = readmap (x,y,'stage') or 1
	if stage>2 then inv_ground_add (x,y,item_make(3)) end
	if stage>5 then inv_ground_add (x,y,item_make(3)) end
	return z
end,

ondraw = function (x,y,wx,wy)
	local stage = readmap (wx,wy,'stage') or 1
	local vr = readmap (wx,wy,'vr') or 1
	if vr==1 then
		love.graphics.draw (quad, stone[189].sprs[math.floor(stage)],x,y,0,2,2)
	else
		love.graphics.draw (quad, stone[189].sprs[math.floor(stage)],x+32,y,0,-2,2)
	end
end,

}



stone[157] = { name = 'Sugar beet',
zindex = 1,
gather = {dig = 0}, 
dpr = 1,
col = 0, -- collision
digtime = 5, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 
die = 157, 
spr = img_load("beet1.png"),
sprs = {
	img_load("beet1.png"),
	img_load("beet2.png"),
	img_load("beet3.png"),
	img_load("beet4.png"),
	img_load("beet5.png"),
	img_load("beet6.png"),
	img_load("beet7.png"),
},

ttl = time.h,     

	plant =
	{
		stages = 7,
		opt = 5,
		seed = 6,
		dead = 7,
		loot = {
			[1] = {3},
			[2] = {3},
			[3] = {197},
			[4] = {197,3},
			[5] = {197,197},
			[6] = {197,196,196,196,3},
			[7] = {37,37,197},
		},

		step = 0.07,
		laststep = 0.02,
		neg = time.d*7,
		wt = 3,
		e = 1,
		light = 1,
		flood = 1
	},

oninfo = function (x,y)	return draw_growpc (x,y) end,
ondig = function (x,y) return plant_dig (x,y,157) end,
ondie = function (x,y) plant_grow (x,y,157) end, 

ondestroy = function (x,y)
	local stage = readmap (x,y,'stage') or 1
	if stage>2 then inv_ground_add (x,y,item_make(197)) end
	if stage>5 then inv_ground_add (x,y,item_make(197)) end
end,

ondraw = function (x,y,wx,wy)
	local stage = readmap (wx,wy,'stage') or 1
	local vr = readmap (wx,wy,'vr') or 1
	if vr==1 then
		love.graphics.draw (quad, stone[157].sprs[math.floor(stage)],x,y,0,2,2)
	else
		love.graphics.draw (quad, stone[157].sprs[math.floor(stage)],x+32,y,0,-2,2)
	end
end,

}



stone[128] = { name = 'Cactus',
	zindex = 1,
	fall = {0,1},
	gather = {dig = 0},
	digtime = 5, -- seconds
	digtoinv = 0,
	digtoid = 0, 
	col = 0,
	solid = 0,
	die = 128,  
	

	spr = img_load("cactus2.png"),

	sprs = {
	img_load("cactus1.png"),
	img_load("cactus2.png"),
	img_load("cactus3.png"),
	img_load("cactus4.png"),
	img_load("cactus5.png"),
	},


	ttl = time.d*3,     

	plant =
	{
		stages = 5,
		opt = 4,
		seed = 5,
		dead = 5,
		loot = {
			[1] = {172},
			[2] = {172,172},
			[3] = {172,172,172},
			[4] = {172,172,172,173},
			[5] = {174,174},
		},

		step = 1,
		laststep = 0.1,
		neg = time.d,
		wt = 0,
		e = 0,
		light = 1,
		flood = 1,
		growable = {60}
	},

	
	oninfo = function (x,y)	return draw_growpc (x,y) end,
	ondig = function (x,y) return plant_dig (x,y,128) end,
	ondie = function (x,y) 
		plant_grow (x,y,128) 
		local wt = readmap (x,y+1,'wt') or 0
		if wt>0 then
			stage = 5
			writemap (x,y,stage,'stage')
		end
	end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		local vr = readmap (wx,wy,'vr') or 1
		if vr==1 then
			love.graphics.draw (quad, stone[128].sprs[math.floor(stage)],x,y,0,2,2)
		else
			love.graphics.draw (quad, stone[128].sprs[math.floor(stage)],x+32,y,0,-2,2)
		end
	end,
}


stone[154] = { name = 'Rice',
	dpr = 1,
	gather = {dig = 0},
	digtime = 10, -- seconds
	digtoinv = 0,
	digtoid = 0, 
	col = 0,
	solid = 0,
	die = 154,  
	

	spr = img_load("rice1.png"),

	sprs = {
	img_load("rice1.png"),
	img_load("rice2.png"),
	img_load("rice3.png"),
	img_load("rice4.png"),
	img_load("rice5.png"),
	img_load("rice6.png"),
	img_load("rice7.png"),
	img_load("rice8.png"),
	img_load("rice9.png"),
	},


	ttl = time.h,     

	plant =
	{
		stages = 9,
		opt = 7,
		seed = 10,
		dead = 9,
		loot = {
			[1] = {3},
			[2] = {3},
			[3] = {3},
			[4] = {3,3},
			[5] = {3,3,3},
			[6] = {3,3,3},
			[7] = {3,3,188}, --
			[8] = {37,37,188}, --
			[9] = {37,37,37},
		},

		step = 0.07,
		laststep = 0.01,
		neg = time.d*3,
		wt = 2,
		e = 0.4,
		light = 1,
		flood = 4000,
	},

	
	oninfo = function (x,y)	return draw_growpc (x,y) end,

	ondig = function (x,y) 

	local stage = readmap (x,y,'stage') or 1

	if stage==7 or stage==8 then

		if inv_find (56,188) then
			return plant_dig (x,y,154) 
		else
			textwall (msg.stone[154].txt[1])
			return true
		end

	end

	return plant_dig (x,y,154) 

	end,
	
	ondie = function (x,y) 
		plant_grow (x,y,154) 
	end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		local vr = readmap (wx,wy,'vr') or 1
		if vr==1 then
			love.graphics.draw (quad, stone[154].sprs[math.floor(stage)],x,y,0,2,2)
		else
			love.graphics.draw (quad, stone[154].sprs[math.floor(stage)],x+32,y,0,-2,2)
		end
	end,
}




stone[155] = { name = 'Tomato',
	zindex = 1,
	dpr = 1,
	gather = {dig = 0},
	digtime = 5, -- seconds
	digtoinv = 0,
	digtoid = 0, 
	col = 0,
	solid = 0,
	die = 155,  
	

	spr = img_load("tomato1.png"),

	sprs = {
	img_load("tomato1.png"),
	img_load("tomato2.png"),
	img_load("tomato3.png"),
	img_load("tomato4.png"),
	img_load("tomato5.png"),
	img_load("tomato6.png"),
	img_load("tomato7.png"),
	img_load("tomato8.png"),
	img_load("tomato9.png"),
	},


	ttl = time.h,     

	plant =
	{
		stages = 9,
		opt = 7,
		seed = 10,
		dead = 9,
		loot = {
			[1] = {},
			[2] = {3},
			[3] = {3},
			[4] = {3},
			[5] = {3},
			[6] = {3},
			[7] = {190,190,190}, --
			[8] = {190,190,190,190,190}, --
			[9] = {37},
		},

		step = 0.05,
		laststep = 0.01,
		neg = time.d,
		wt = 1,
		e = 1,
		light = 1,
		flood = 1,
		freeze = 0,
		indoors = 1,
	},

	
	oninfo = function (x,y)	return draw_growpc (x,y) end,

	ondig = function (x,y) 

	local stage = readmap (x,y,'stage') or 1
	local dug = readmap (x,y,'dug') or 1
	
	plant_dig (x,y,155) 
	dug = dug + 1
	writemap (x,y,dug,'dug')

	if dug>5 then
		writemap (x,y,0,'clear')
	end

		if stage==8 then
			writemap (x,y,3,'stage')
			writemap (x,y,3,'age')
			return true
		end

		if stage==7 then
			writemap (x,y,4,'stage')
			writemap (x,y,4,'age')
			return true
		end

	end,
	
	ondie = function (x,y) 
		plant_grow (x,y,155) 
	end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		local vr = readmap (wx,wy,'vr') or 1
		if vr==1 then
			love.graphics.draw (quad, stone[155].sprs[math.floor(stage)],x,y,0,2,2)
		else
			love.graphics.draw (quad, stone[155].sprs[math.floor(stage)],x+32,y,0,-2,2)
		end
	end,
}



stone[170] = { name = 'Chilli',
	dpr = 1,
	gather = {dig = 0},
	digtime = 5, -- seconds
	digtoinv = 0,
	digtoid = 0, 
	col = 0,
	solid = 0,
	die = 170,  
	

	spr = img_load("chilli1.png"),

	sprs = {
	img_load("pepper1.png"),
	img_load("pepper2.png"),
	img_load("pepper3.png"),
	img_load("pepper4.png"),
	img_load("pepper5.png"),
	img_load("pepper6.png"),
	img_load("pepper7.png"),
	img_load("pepper8.png"),
	img_load("pepper9.png"),
	},


	ttl = time.h,     

	plant =
	{
		stages = 9,
		opt = 7,
		seed = 8,
		dead = 9,
		loot = {
			[1] = {},
			[2] = {3},
			[3] = {3},
			[4] = {3},
			[5] = {3},
			[6] = {3},
			[7] = {233}, --
			[8] = {233,235}, --
			[9] = {235,wo37}, --
		},

		step = 0.05,
		laststep = 0.01,
		neg = time.d,
		wt = 1,
		e = 1,
		light = 1,
		flood = 1,
		freeze = 0,
	},

	
	oninfo = function (x,y)	return draw_growpc (x,y) end,

	ondig = function (x,y) 

		plant_dig (x,y,170) 
		writemap (x,y,0)

	end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		love.graphics.draw (quad, stone[170].sprs[math.floor(stage)],x,y,0,2,2)
	end,
}

stone[147] = { name = 'Ectoplasm',
	gather = {cut = 1},
	fall = {0,1},
	dpr = 1,
	digtime = 5, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 0, 
	col = 0, -- collision
	solid = 0,
	die = 147,  
	ttl = time.h,          
	spr = img_load("potato10.png"),

	sprs = {
	img_load("potato1.png"),
	img_load("potato2.png"),
	img_load("potato3.png"),
	img_load("potato4.png"),
	img_load("potato5.png"),
	img_load("potato6.png"),
	img_load("potato7.png"),
	img_load("potato8.png"),
	img_load("potato9.png"),
	img_load("potato10.png"),
	},


	plant =
	{
		stages = 10,
		opt = 9,
		seed = 11,
		dead = 10,
		loot = {
			[1] = {183},
			[2] = {183},
			[3] = {183},
			[4] = {183},
			[5] = {183,183},
			[6] = {183,183},
			[7] = {183,183},
			[8] = {183,183},
			[9] = {192,183},
			[10] = {184,184}
		},

		step = 0.2,
		laststep = 0.05,
		neg = time.d,
		wt = 0,
		e = 0,
		light = nil,
		flood = nil,
		growable = {1,2,8,17,31,32,99,12,13,103,48}

	},

	oninfo = function (x,y)	return draw_growpc (x,y) end,
	
	onstepon = function (x,y)
		
		local stage = readmap (x,y,'stage') or 1
		if stage~=10 then return end

		pl.fell=0

			if is_pressed("w") and pl.yspeed<0 then

				sound_add ('ecto',19)

				stage = stage * 0.07

				pl.yspeed = pl.yspeed * (-1-stage)
				pl.yspeed = pl.jumpy * (-1-stage)
				--pl.xspeed = pl.xspeed * 1.3
				pl.xspeed = pl.xspeed * (1+stage)
				--pl.y = pl.y+16

			else
					
				sound_add ('ecto',19, {volume = 0.1})
				pl.yspeed = pl.yspeed / 4
				-- pl.y = pl.y + 6
				--pl.xspeed = 16

			end

		

		--pl.xspeed = pl.jumpx * pl.flip
		--print (pl.yspeed)

		
	end,

	ondig = function (x,y)

		local stage = readmap (x,y,'stage') or 1
		if stage==9 and love.math.random (0,100)<20 then
			mob_create (x, y, 9)
		end
		return plant_dig (x,y,147)

	end,

	ondie = function (x,y) 
		
		plant_grow (x,y,147)

		local stage = readmap (x,y,'stage') or 1
		local neg = readmap (x,y,'neg') or 1
		local w = readmap (x,y,'w') or 0
		

		local tr = readmap (x,y,'tr')

		if stage==5 then
			local b = readmap (x,y+1,'b')
			if b==8 then
				inv_ground_add (x,y+1,item_make(loot_make (stone[8].loot)))
			end
			writemap (x,y+1,99,'b')
		end

		if stage==6 and tr==nil then

			writemap (x,y+1,0,'b')
			writemap (x,y,1,'tr')

		end

		if stage==10 and neg>1 and w>0 then
			w = w - 100
			if w<0 then w = nil end
			writemap (x,y,147,'clear')
			writemap (x,y,w,'w')

		end

	end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		love.graphics.draw (quad, stone[147].sprs[stage],x,y,0,2,2)
	end,

	--light = {32,0.7,0.2,0.6}
}













stone[148] = { name = 'Frostbite',
	gather = {smash = 2},
	fall = {0,-1},
	digtime = 20, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 0, 
	col = 0, -- collision
	solid = 0,
	die = 148,  
	ttl = time.d*1.5,          
	spr = img_load("bolb7.png"),

	sprs = {
	img_load("bolb7.png"),
	img_load("bolb8.png"),
	img_load("bolb9.png"),
	img_load("bolb10.png"),
	},


	onheat = function (x,y,tile,map) 
		if item_firing (x,y,tile,map,1,4,0) then --temp,time,to 
			writemap (x,y,0,'clear')
			writemap (x,y,10,'w')
		end
	end,

	ondig = function (x,y) 
		local stage = readmap (x,y,'stage') or 1
		if stage==4 then
			inv_ground_add(x,y, item_make (40))
		end
		stat_spend ('heat',10)
	end,

	onfell = function (x,y)
		writemap (x,y,0)
		mob_create (x, y, 7)
	end,


	ondie = function (x,y) 
		
		local stage = readmap (x,y,'stage') or 1

		stage = stage + 1

		if stage == 2 then
			writemap (x,y-1,48)
		end

		if stage>4 then 
			writemap (x,y,0)
			mob_create (x, y, 7)
		end

		writemap (x,y,stage,'stage')

	end, 

	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		if stage>4 then stage=4 end
		love.graphics.draw (quad, stone[148].sprs[stage],x,y,0,2,2)
	end,

	light = {32,0.7,0.5,0.6}
}


stone[2] = { name = 'Dug up dirt',
cr = 1,
col = 1,
br = 1,
solid = 1,
z = 1,
gather = {dig = 0},
digtime = 0.5,
digtoinv = 0,
digtoid = 2,
ttl = time.d,
die = 1,
spr = img_load("brick2.png"),
}

stone[102] = { name = 'Loam',
cr = 1,
gather = {dig = 1},
col = 1,
br = 1,
solid = 1,
z = 1,
digtime = 2,
digtoinv = 0,
digtoid = 102,
spr = img_load("brick51.png"),
absorb = 200
}

stone[3] = { name = 'Impassable object',
col = 1,
br = 1,
solid = 1,
z = 1,
spr = img_load("brick3.png"),
}

stone[131] = { name = 'Sun', --rising
gather = {dig = 0},
digtime = 1,
digtoinv = 0,
digtoid = 131,
col = 0,
solid = 1,
z = 1,
spr = img_load("sun5.png"),
check = function (x,y) -- quick checks

	local he = readmap (x,y,'he') or 0

	if he<3 and readmap (x,y-1,'b')==0 then
		writemap (x,y,0)
		writemap (x,y,nil,'he')

		writemap (x,y-1,131)
		he = he + 1
		writemap (x,y-1,he,'he')

		return

	end

	writemap (x,y,132)
	writemap (x,y,nil,'he')

end,

light = {64,1,1,0.5},

}


stone[132] = { name = 'Sun',
gather = {dig = 0},
digtime = 1,
digtoinv = 0,
digtoid = 131,
col = 0,
solid = 1,
z = 1,
spr = img_load("sun1.png"),
sprs = {
	img_load("sun1.png"),
	img_load("sun2.png"),
	img_load("sun3.png"),
	img_load("sun4.png"),
on
},


ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[132].sprs[math.floor(game.dt*5)%3+1],x,y,0,2,2)
end,

light = {110,1,1,0.5},

}


stone[133] = { name = 'Reptiloid painting',
gather = {dig = 0},
digtime = 1,
digtoinv = 0,
digtoid = 133,
col = 0,
solid = 1,
z = 1,
spr = img_load("brick72.png"),

onfalling =  function (x,y)
	writemap (x,y,nil,'f')
	if readmap (x,y-1,'b')==0 then
		writemap (x,y,0)
		writemap (x,y-1,133)
	end
end,

}

stone[4] = { name = 'Nanoblock',
gather = {dig = 0},
digtime = 1,
digtoinv = 32,
digtoid = 0,
col = 1,
br = 1,
solid = 1,
z = 1,
spr2 = img_load("brick4.png"),
spr = img_load("brick4s.png"),
ondraw = function (x,y,wx,wy)
	if math.floor(wy+wx+(game.dt))%7 == 1 then
		love.graphics.draw (quad, stone[4].spr,x,y,0,2,2)
	else
		love.graphics.draw (quad, stone[4].spr2,x,y,0,2,2)
	end
end,
}

stone[52] = { name = 'Hi-tech stuff',
gather = {smash = 3},
loot = {{i = 114, p = 1},{i = 0, p = 10}},
digtime = 1,
digtoinv = 0,
digtoid = 0,
col = 1,
br = 1,
solid = 1,
z = 1,
spr = img_load("brick37.png"),
ondig = function (x,y)
	if lookaround (x,y,{115},10) then
		textwall (msg.stone[52].msg)
		pl.digcount = -1 
		return false
	end
end
}


stone[115] = { name = 'High-tech capsule',
gather = {dig = 2},
dpr = 1,
solid = 1,
col = 0,
die = 113,
ttl = time.m*6,
digtime = 20,
digtoinv = 122,
digtoid = 0,
spr = img_load("brick62.png"),
light = {14,0.0,1,0.0},

ondig = function (x,y)

if readmap (x,y,'disarm') ~= 'ok' then
	
	textwall (msg.stone[115].msg)
	writemap (x,y,'ok', 'disarm')

		
		local sp = 0
		for i=1,10 do

			local xa = love.math.random (1,5)
			local ya = love.math.random (-7,-3)

			if (maptile (x+xa, y+ya, 'col') or 0)==0 then
				mob_create (x+xa, y+ya,6)
				sp = sp + 1
			end

			if sp == 3 then break end
		end

	pl.digcount = -1 
	return false
end

end


}


stone[53] = { name = 'Mob spawner',
noinfo = 1,
col = 0,
solid = 0,
spr = img_load("brick41.png"),
check = function (x,y) -- quick checks
	local dist = math.dist (pl.tx, pl.ty, x, y)


	if dist<vi.mobspawndist and not game.dbg[2] --#mobs<30 and 
		and readmap (x,y,'n') ~=255 
		and pl.spenddead==0 then

		local mob = readmap (x,y,'mob')

		if type(mob) == 'number' then
			writemap (x,y,0)
			mob_create (x,y,mob)
		else
			local w = next_numeric_id(mobs)
			mobs[w] = mob
			writemap (x,y,0)
		end

	end
end,
}

stone[54] = { name = 'Base',
noinfo = 1,
col = 0,
solid = 1,
digtime = 3,
digtoinv = 0,
digtoid = 0,
spr = img_load("base_top.png"),
light = {64,1,0.7,1},

ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[54].spr,x-32,y-32,0,2,2)
end

}

stone[104] = { name = 'Base bottom',
noinfo = 1,
col = 1,
solid = 1,
digtime = 3,
digtoinv = 0,
digtoid = 0,
spr = img_load("bottom.png"),
spr2 = img_load("bottom_g.png"),
light = {64,1,0.7,1},
ondraw = function (x,y,wx,wy)
	local status = readmap (wx,wy,'status')
	if status then
		love.graphics.draw (quad, stone[104].spr2,x-32,y,0,2,2)
	else
		love.graphics.draw (quad, stone[104].spr,x-32,y,0,2,2)
	end
end,

check = function (x,y) -- quick checks
	--dispenser (x,y)
end,

}

stone[105] = { name = 'Collider',
noinfo = 1,
col = 1,
solid = 1,
spr = img_load("nah1.png"),
ondraw = function (x,y,wx,wy) end
}

stone[106] = { name = 'Solid',
noinfo = 1,
col = 0,
solid = 1,
spr = img_load("nah2.png"),
ondraw = function (x,y,wx,wy) end
}

-- stone[117] = { name = 'Random',
-- noinfo = 1,
-- col = 0,
-- solid = 1,
-- spr = img_load("brick9.png"),
-- -- ondraw = function (x,y,wx,wy)
-- -- end
-- }


stone[127] = { name = 'Manna', --down
fall = {0,1},
falldie = 1,
col = 0,
solid = 0,
gather = {dig = 0},
digtime = 2,
digtoinv = 171,
digtoid = 0,
spr = img_load("brick69.png"),
}




stone[108] = { name = 'Moss', --down
fall = {0,1},
falldie = 1,
col = 0,
solid = 0,
gather = {dig = 0},
digtime = 3,
digtoinv = 109,
digtoid = 0,
spr = img_load("brick53.png"),
die = 108,
ttl = time.d*6,

ondie = function (x,y)

	plant_spores (x,y,{107,111},5,101)

	growable = {1,2,8,17,99,12,13,102}
	if
		in_array (growable, readmap (x,y+1,'b')) then
		writemap (x,y+1,107)	
	end

end,

onstep = function (x,y)
	--writemap (x,y,1,'w')
end,

}


stone[101] = { name = 'Shroom',
fall = {0,1},
gather = {dig = 0},
digtime = 1, -- seconds
digtoinv = 102, -- 0 - hold or item id
digtoid = 0, 
col = 0, -- collision
solid = 0,
die = 101,
ttl = time.w,       
ondie = function (x,y)
	plant_spores (x,y,{107,111},7,108)
end,
spr = img_load("brick30.png"),
spr2 = img_load("brick29.png"),
light = {50,0.6,0.6,0.0},
ondraw = function (x,y,wx,wy)
	if (game.dt/2+wx)%3 < 1 then
		love.graphics.draw (quad, stone[101].spr,x,y,0,2,2)
	else
		love.graphics.draw (quad, stone[101].spr2,x,y,0,2,2)
	end
end,

}


stone[174] = { name = 'Vagina',
unstack = 1,
gather = {chop = 3},
digtime = 10, -- seconds
digtoinv = 14, -- 0 - hold or item id
digtoid = 0, 
col = 0, -- collision
solid = 0,
die = 174,
ttl = 32,       

onstay = function (x,y)
	player_hit (1)
end,

-- check = function (x,y)

-- 	local f = readmap (x,y,'f') or 0
-- 	f = f + 1
-- 	if f>32 then
-- 		f = 0
-- 	end
-- 	writemap (x,y,f,'f')
	
-- end,

spr = img_load("snake22.png"),
sprs = 
{
img_load("snake22.png"),
img_load("snake23.png"),
img_load("snake24.png"),
},

light = {32,0.6,0.3,0.6},

ondraw = function (x,y,wx,wy)
	local c = 1+math.floor(game.dt*6+wx)%3
	local f = readmap (x,y,'f') or 0
	love.graphics.draw (quad, stone[174].sprs[c],x,y+f,0,2,2)
	
		-- love.graphics.draw (quad, stone[174].spr2,x,y,0,2,2)
end,

check = function (x,y)
	local cnt = readmap (x,y,'cnt') or 3
	local rise = readmap (x,y,'rise')

	if rise==nil then
		local f = readmap (x,y,'f') or 32
		f = f - dt*10
		if f<0 then 
			f=0
			writemap (x,y,1,'rise')
		end
		writemap (x,y,f,'f')
	end

	if rise then
		if cnt<-2 then
			local f = readmap (x,y,'f') or 0
			f = f + dt*10
			writemap (x,y,f,'f')
			if f>32 then
				writemap (x,y,0,'clear')
				writemap (x,y,36)
			end
		end
	end
end,

ondie = function (x,y)

	local cnt = readmap (x,y,'cnt') or 3
	cnt = cnt - 1
	writemap (x,y,cnt,'cnt')
	if cnt>=0 then	
		mob_create (x,y,13)
	end

end

}

stone[109] = { name = 'Moss', --right
fall = {1,0},
falldie = 1,
col = 0,
solid = 0,

gather = {dig = 0},
digtime = 3,
digtoinv = 109,
digtoid = 0,

spr = img_load("brick54.png"),


}

stone[110] = { name = 'Moss', --left
fall = {-1,0},
falldie = 1,
col = 0,
solid = 0,

gather = {dig = 0},
digtime = 3,
digtoinv = 109,
digtoid = 0,

spr = img_load("brick55.png"),
}


stone[107] = { name = 'Peat',
cr = 1,
solid = 1,
col = 1,
br = 1,
gather = {chop = 1},
digtime = 3,
digtoinv = 0,
digtoid = 2,
ttl = time.w,
die = 107,

ondug = function ()
	inv_add(item_make(111))
end,

spr = img_load("brick56.png"),


ondie = function (x,y)
	if readmap (x,y-2,'b')==0 then
		if mob_search (x,y,30,5)<3 then
			mob_create (x,y-2,5)
		end
	end
end


}

stone[111] = { name = 'Compressed Peat',
	cr = 1,
solid = 1,
col = 1,
br = 1,

gather = {chop = 2},
digtime = 3,
digtoinv = 0,
digtoid = 107,

ondug = function ()
	inv_add(item_make(111))
end,


spr = img_load("brick52.png"),
}


stone[112] = { name = 'Young bog-berry',
	dpr = 1,
	solid = 1,
	col = 0,
	die = 113,
	ttl = time.w,
	digtime = 3,
	digtoinv = 0,
	digtoid = 0,
	spr = img_load("brick58.png"),
}


	stone[113] = { name = 'Bog-berry',
	gather = {chop = 2},
	dpr = 1,
	solid = 1,
	col = 0,
	die = 114,
	ttl = time.w,
	digtime = 3,
	digtoinv = 0,
	digtoid = 112,
	spr = img_load("brick59.png"),
	
	ondig = function (x,y)
		inv_add (item_make(15))
		inv_add (item_make(15))
		inv_add (item_make(15))
		inv_add (item_make(15))
	end,

}


	stone[114] = { name = 'Bog-berry with berries',
	gather = {dig = 0},
	dpr = 1,
	solid = 1,
	col = 0,
	digtime = 3,
	digtoinv = 0,
	digtoid = 0,
	spr = img_load("brick60.png"),
	ondig = function (x,y)
		inv_add (item_make(112))
		writemap (x,y,113)
		return true
	end,
	onuse = function (x,y)
		inv_add (item_make(112))
		writemap (x,y,113)
	end,
}

	stone[116] = { name = 'Broken image',
	gather = {dig = 0},
	solid = 1,
	col = 1,
	die = 116,
	digtime = 1,
	digtoinv = 0,
	digtoid = 116,
	spr = img_load("brick61.png"),
	onfalling =  function (x,y)
		writemap (x,y,nil,'f')
		if readmap (x,y-1,'b')==0 then
			writemap (x,y,0)
			writemap (x,y-1,116)
		end
	end,
	transformi = 0,
	transformpower = -50,


}


stone[117] = { name = 'Binary tree',
	gather = {dig = 0},
	digtime = 10, -- seconds
	digtoinv = 114, -- 0 - hold or item id
	digtoid = 0, 
	col = 0, -- collision
	solid = 0,
	spr = img_load("brick63.png"),
	ondraw = function (x,y,wx,wy)
		local stage = readmap (wx,wy,'stage') or 1
		love.graphics.draw (quad, stone[117].spr,x,y-32,0,2,2)
	end,
}

stone[55] = { name = 'Fire',
col = 0,
solid = 0,
z = 2,
fall = {0,1},
spr = img_load("fire1.png"),
sprs = {
img_load("fire1.png"),
img_load("fire2.png"),
img_load("fire3.png"),
img_load("fire4.png"),
img_load("fire5.png"),
},
ondraw = function (x,y,wx,wy)
	local a =  (math.floor((game.dt*6)%4)+1)
	love.graphics.draw (quad, stone[55].sprs[a],x,y,0,2,2)
end,

check = function (x,y) -- quick checks
	fire (x,y)
end,

light = {64,0.8,0.8,0.4},

t_speed = 100,
t_cap = 300

}
--52


stone[17] = { name = 'Heap of dirt',
fall = {0,1},
col = 0,
solid = 0,
z = 1,
gather = {dig = 0},
fall = {0,1},
digtime = 0.5,
digtoinv = 0,
digtoid = 17,
ttl = 10000,
die = 0,
spr = img_load("brick2h.png"),
ondestroy = function (x,y,z)
if z==17 then return 2 end
if z==2 then return 2,17 end
return z,0
end,
onstay = function (x,y)
	world[y][x].t = world[y][x].t - 100
	multiplayer_record_cell(x, y)
end
}


stone[153] = { name = 'Toxic heap',
fall = {0,1},
col = 0,
solid = 0,
z = 1,
gather = {dig = 0},
fall = {0,1},
digtime = 0.5,
digtoinv = 0,
digtoid = 153,
ttl = time.d,
die = 153,
spr = img_load("brick86.png"),
ondestroy = function (x,y,z)
if z==17 then return 153 end
if z==153 then return 149 end
return z,153
end,
onstep = function (x,y)
	player_hit (1)
	stat_spend ('filth',10)
end,

onheat = function (x,y,tile,map)
	if item_firing (x,y,tile,map,100,1,0) then --temp, time, to
		writemap (x,y,0)
	end
end,

ondie = function (x,y)
growable = {1,2,8,17,99,12,13,102,48}
	if
		in_array (growable, readmap (x,y+1,'b')) then
		writemap (x,y+1,149)	
	end
end

}

stone[149] = { name = 'Toxic waste',
fall = {0,1},
cr = 1,
col = 1,
br = 1,
solid = 1,
z = 1,
gather = {dig = 0},
--fall = {0,1},
digtime = 0.5,
digtoinv = 0,
digtoid = 149,
ttl = time.d,
--ttl = time.min,
die = 149,
spr = img_load("brick87.png"),

onheat = function (x,y,tile,map)
	if item_firing (x,y,tile,map,100,1,0) then --temp, time, to
		writemap (x,y,0,'clear')
		inv_ground_add (x,y,item_make(88))
	end
end,

ondie = function (x,y)
	--growable = {1,2,8,17,31,32,99,12,13,103}
	growable = {1,2,8,17,99,12,13,102,48}

	if
		in_array (growable, readmap (x+1,y,'b')) then
		writemap (x+1,y,149)	
	elseif
		in_array (growable, readmap (x-1,y,'b')) then
		writemap (x-1,y,149)	
	elseif in_array (growable, readmap (x,y+1,'b')) then
		writemap (x,y+1,149)
	elseif in_array (growable, readmap (x,y-1,'b')) then
		writemap (x,y-1,149)
	elseif readmap (x,y-1,'b')==149 then
		--writemap (x,y-1,0)
	end

	-- if readmap (x,y-1,'b') == 149 and readmap (x,y-2,'b')==0 then
	-- 	writemap (x,y-1,0)
	-- end


	-- if
	-- 	readmap (x-1,y,'b')==149 and
	-- 	readmap (x+1,y,'b')==149 and
	-- 	readmap (x,y+1,'b')==149 then
	-- 	writemap (x,y,0)
	-- end
		

		
end,
onstepon = function (x,y)
	player_hit (1)
	stat_spend ('filth',10)
end,

}


stone[32] = { name = 'Dense ground',
cr = 1,
gather = {pierce = 1}, 
digtime = 2, -- seconds
digtoid = 1, 
col = 1,
br = 1,
solid = 1,
spr = img_load("brick24.png")
}

stone[31] = { name = 'Dense ground',
cr = 1,
gather = {pierce = 2}, 
digtime = 2, -- seconds
digtoid = 32, 
col = 1,
br = 1,
solid = 1,
spr = img_load("brick23.png"),

ondig = function (x,y) 
	if love.math.random (0,100)<10 then
		inv_ground_add(x,y, item_make (88))
	end
end,

}



stone[103] = { name = 'Rock',
cr = 1,
gather = {pierce = 3}, 
digtime = 2, -- seconds
digtoid = 1, 
col = 1,
br = 1,
solid = 1,
spr = img_load("brick50.png"),

loot = {{i=36,p=10}, -- 
{i=60,p=10}, -- {i=31,p=10}, -- 
{i=5,p=10}, -- 
{i=193,p=10}, -- 
{i=34,p=10}, -- 
},

}




stone[34] = { name = 'Stone Table',
zindex = 1,
unstack = 1,
fall = {0,1},
gather = {dig = 0}, 
digtime = 2, -- seconds
digtoid = 0, --33
digtoinv = 34, 
col = 0,
solid = 1,
spr = img_load("brick26.png"),
ondig = function (x,y) 
	inv_ground_add(x,y, item_make (5))
	inv_ground_add(x,y, item_make (5))
	inv_ground_add(x,y, item_make (5))
	inv_ground_add(x,y, item_make (5))
end,
onuse = function (x,y)
	achi_done (34)
	craft_reset ()
	craft.multitem = true
	craft.reqblock = 34
	craft_itemsget ()
	craft_str ()
	if craft.str~="" then
		game.craft = true
	else
		textwall (msg.game[29])
	end
end,

}








-----------------------------------------------
-- COMPOSITES AND ORES

stone[63] = { name = 'Copper ore',
cr = 1,
gather = {pierce = 1}, 
digtime = 5, -- seconds
digtoid = 17, 
loot = {{i=36,p=10}, -- pyrite
{i=60,p=90}, -- ore
},
col = 1, -- collision
br = 1,
solid = 1,

spr2 = img_load("brick24.png"),
spr = img_load("copper.png"),

ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[63].spr2,x,y,0,2,2)
	love.graphics.draw (quad, stone[63].spr,x+4*((wx+wy)%4),y+4*((wx+wy)%5),0,2,2)
end,

ttl = time.d,
die = 63,

ondie = function (x,y)

	local h = function (x,y)
		local b =readmap (x,y,'b')
		local n =readmap (x,y,'n')

		if b==0 and n~=255 then
			return true
		end

	end

	local fx,fy = find_block (x,y,h,3)

	if fx and mob_search (fx,fy,30,14)<3 then
		mob_create (fx,fy-2,14)
	end
end

}

stone[79] = { name = 'Tin ore',
cr = 1,
gather = {pierce = 2}, 
digtime = 5, -- seconds
digtoid = 17, 
loot = {{i=36,p=10}, -- pyrite
{i=78,p=90}, -- ore
},
col = 1, -- collision
br = 1,
solid = 1,

spr2 = img_load("brick23.png"),
spr = img_load("tin.png"),

ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[79].spr2,x,y,0,2,2)
	love.graphics.draw (quad, stone[79].spr,x+4*((wx+wy)%3),y+4*((wx+wy)%4),0,2,2)
end
}


stone[80] = { name = 'Coal',
cr = 1,
gather = {pierce = 3}, 
digtime = 5, -- seconds
digtoid = 17, 
loot = {{i=46,p=10}, -- coal
},
col = 1, -- collision
br = 1,
solid = 1,

spr2 = img_load("brick50.png"),
spr = img_load("coal.png"),

ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[80].spr2,x,y,0,2,2)
	love.graphics.draw (quad, stone[80].spr,x+7*((wx+wy)%3),y+3*((wx+wy)%4),0,2,2)
end
}

stone[8] = { name = 'Some stones',
cr = 1,
gather = {dig = 0}, 
digtime = 3, -- seconds
digtoid = 17, 
loot = {{i=36,p=10}, -- pyrite
{i=29,p=12}, -- flint
{i=31,p=20}, -- small stone
{i=5,p=40}, -- hammerstone
{i=193,p=4}, --hearthstone
{i=303,p=2}, --philosopher's stone
{i=309,p=4} --pet rock
},
col = 1, -- collision
br = 1,
solid = 1,
ttl = nil,
spr2 = img_load("brick1.png"),
spr = img_load("stone.png"),

ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[8].spr2,x,y,0,2,2)
	love.graphics.draw (quad, stone[8].spr,x+4*((wx+wy)%4),y+3*((wx+wy)%5),0,2,2)
end
}

stone[175] = { name = 'Some minerals',
fall = {0,-1},
gather = {smash = 2}, 
digtime = 3, -- seconds
digtoid = 0, 
loot = {{i=36,p=10}, -- pyrite
{i=29,p=10}, -- flint
{i=31,p=10}, -- small stone
{i=5,p=10}, -- hammerstone
{i=193,p=2}, --hearthstone
{i=60,p=10}, --copper ore
{i=79,p=4} --tin ore
},
col = 0, -- collision
solid = 1,
ttl = nil,
spr = img_load("brick92.png"),

ondig = function (x,y)
	inv_add (item_make(loot_make (stone[175].loot)))
	inv_add (item_make(loot_make (stone[175].loot)))
	inv_add (item_make(60)) --copper
end,

onfell = function (x,y)
	writemap (x,y,0)
	inv_ground_add (x,y, (item_make(loot_make (stone[175].loot))))
end,

}


stone[176] = { name = 'Some minerals',
fall = {0,-1},
gather = {smash = 2}, 
digtime = 3, -- seconds
digtoid = 0, 
loot = {{i=36,p=10}, -- pyrite
{i=29,p=10}, -- flint
{i=31,p=10}, -- small stone
{i=5,p=10}, -- hammerstone
{i=193,p=2}, --hearthstone
{i=60,p=10}, --copper ore
{i=79,p=4} --tin ore
},
col = 0, -- collision
solid = 1,
ttl = nil,
spr = img_load("brick93.png"),

ondig = function (x,y)
	inv_add (item_make(loot_make (stone[175].loot)))
	inv_add (item_make(loot_make (stone[175].loot)))
	inv_add (item_make(60)) --copper
end,

onfell = function (x,y)
	writemap (x,y,0)
	inv_ground_add (x,y, (item_make(loot_make (stone[175].loot))))
end,

}


stone[177] = { name = 'Stone louse',
gather = {dig = 0}, 
digtime = 3, -- seconds
digtoid = 17, 
digtoinv = 0,
col = 1, -- collision
br = 1,
solid = 1,
ttl = nil,
ttl = time.min,
die = 177,
spr = img_load("woodlouse10.png"),

ondig = function (x,y)
	mob_create (x,y,15)
end,

ondie = function (x,y)
	local n = readmap (x,y,'n') or 0
	if n~=255 and love.math.random (0,10)<3 then
		if maptile (x+1,y)==0 or maptile (x-1,y)==0 or maptile (x,y+1)==0 or maptile (x,y-1)==0 then
			writemap (x,y,0)
			mob_create (x,y,15)
		end
	end
end

}

stone[9] = { name = 'Clay',
cr = 1,
gather = {dig = 1}, 
	ondug = function (x,y)
			mob_create (x,y,3) 
	end,
digtime = 10, -- seconds
digtoid = 102, 
loot = {{i=8,p=100}}, -- array of items                
col = 1, -- collision
br = 1,
solid = 1,
spr = img_load("brick36.png"),
absorb = 100
}


stone[136] = { name = 'Pure clay',
cr = 1,
gather = {dig = 1}, 
digtime = 5, -- seconds
digtoid = 0,              
col = 1, -- collision
br = 1,
solid = 1,
spr = img_load("brick74.png"),
absorb = 100,
ondig = function (x,y)
	inv_add (item_make(8))
	inv_add (item_make(8))
end,
}

stone[137] = { name = 'Cement door',
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 137,              
col = 1,
br = 1,
playerpass = 1,
solid = 1,
spr = img_load("brick75.png"),
t_speed = 1,
t_cap = 2000,

	ondig = function (x,y)

		local s = 0

		while readmap (x,y+s,'b')==137 do
			s = s - 1
		end 

		for i=y+s,y+s+2 do
			if readmap (x,i,'b')==137 then
				writemap (x,i,0)
			end
		end

		pl.iscarry = createblock (137)
		pl.digcount = -1 
		return false

	
	end,   

	onfell = function (x,y)
		for i=1,1 do

			if readmap (x,y-i,'b')==0 then
				writemap (x,y-i,137)
			else
				break
			end
		end
	end

}

stone[183] = { name = 'Door',
noinv = 1,
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 183,              
col = 1,
playerpass = 1,
solid = 1,

onstep = function (x,y)

	local oldr = readmap (x,y,'roomr')
	local oldl = readmap (x,y,'rooml')

	room_clear (x,y)

	local fill,b,fd = room_fill (x+1,y,2)
	local fill2,b2,fd2 = room_fill (x-1,y,4)

	if fill and fill2 then
		for i,v in pairs(fill) do
			if fill2[v[1].."_"..v[2]] then
				--print 're'
				return
			end
		end
	end

	if fd and fd > 32 then
		fill = nil
	end

	if fd2 and fd2 > 32  then
		fill2 = nil
	end

	local str = ""

	if fill then
		for i,v in pairs(fill) do
			writemap (v[1],v[2],b,'room')
		end

		writemap (x,y,fill,'roomr')

		if b then
			str = message (msg.stone[183].txt[1],{[1] = string.format("%.2f", b), [2] = room_storetime (b,true)})
			if oldr == nil then
				game.showroom = 50
			end
		end

	else
		str = message (msg.stone[183].txt[6])
	end

	if fill2 then
		for i,v in pairs(fill2) do
			writemap (v[1],v[2],b2,'room')
		end

		writemap (x,y,fill2,'rooml')

		if b2 then
			if str~="" then str="\n"..str end
			str = message (msg.stone[183].txt[2],{[1] = string.format("%.2f", b2), [2] = room_storetime (b2,true)})..str
			if oldl == nil then
				game.showroom = 50
			end
		end

	
	else
		if str~="" then str="\n"..str end
		str = message (msg.stone[183].txt[5])..str
	end


	if str~="" then
		textwall (str, true)
	end
	
end,

onuse = function (x,y)

	if readmap (x,y-1,'b')==183 and readmap (x,y+1,'b')==183 then
		return
	end


	writemap (x,y,195)

	if readmap (x,y-1,'b')==183 then
		writemap (x,y-1,195)
	elseif readmap (x,y+1,'b')==183 then
		writemap (x,y-1,183)
	end

	game.showroom = 50
	local oldr = readmap (x,y,'roomr')
	local oldl = readmap (x,y,'rooml')

	if oldr==nil and oldl==nil then
		textwall (msg.stone[183].txt[4],true)
	else
		local a = ""
		for i,v in pairs(cf.bricks) do
			a = a.."{#ead4aaff}"..msg.stone[i].name.."{#ffffffff} x "..v.."   "
		end
		textwall (msg.stone[183].txt[3].." "..a,true)
		
	end
end,

spr = img_load("brick98.png"),

	ondig = function (x,y)

		room_clear (x,y-1)
		room_clear (x,y)
		room_clear (x,y+1)

		local s = 0

		while readmap (x,y+s,'b')==183 do
			s = s - 1
		end 

		for i=y+s,y+s+2 do
			if readmap (x,i,'b')==183 then
				writemap (x,i,0)
			end
		end

		pl.iscarry = createblock (183)
		pl.digcount = -1 
		return false

	
	end,   

	onfell = function (x,y)
		for i=1,1 do

			if readmap (x,y-i,'b')==0 then
				writemap (x,y-i,183)
			else
				break
			end
		end
	end

}


stone[195] = { name = 'Open door',
noinv = 1,
--gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 183,              
col = 0,
--playerpass = 1,
solid = 1,


onuse = function (x,y)

	if readmap (x,y-1,'b')==183 and readmap (x,y+1,'b')==183 then
		return
	end
		
	writemap (x,y,183)

	if readmap (x,y-1,'b')==195 then
		writemap (x,y-1,183)
	elseif readmap (x,y+1,'b')==183 then
		writemap (x,y-1,195)
	end


end,

spr = img_load("brick111.png"),

}


stone[138] = { name = 'Mini-Machine',
fall = {0,1},
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 138,  
bridge = 1,            
col = 1,
solid = 1,
noinv = true,
spr = img_load("brick76.png"),
spr2 = img_load("brick77.png"),

check = function (x,y)

	local cd = readmap (x,y,'cd') or 5
	if x==pl.tx and y==pl.ty+1 then
		cd = cd - dt
		textwall (msg.stone[138].txt[1]..math.floor(cd),true)
	else
		cd = 5
	end

	if cd<1 then
		game.fadein = 0.3
		cd = nil
		player_pos_reset ()
	end

	writemap (x,y,cd,'cd')

end,

ondraw = function (x,y,wx,wy)
	if (game.dt*7)%2 < 1 then
		love.graphics.draw (quad, stone[138].spr,x,y,0,2,2)
	else
		love.graphics.draw (quad, stone[138].spr2,x,y,0,2,2)
	end
end,

}


stone[139] = { name = 'Cauldron (raw)',
fall = {0,1},
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 139,  
col = 0,
solid = 0,
spr = img_load("brick78.png"),
onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,140) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[140] = { name = 'Cauldron',
unstack = 1,
fall = {0,1},
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 140,  
col = 0,
solid = 1,
spr = img_load("brick79.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,50,5,141) --temp,time,to 
end,
t_speed = 400,
t_cap = 4000

}

stone[141] = { name = 'Cauldron (hot)',
unstack = 1,
fall = {0,1},
die = 140,
ttl = time.h*4,
--gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 141,  
col = 0,
solid = 1,
spr = img_load("brick80.png"),

ondie = function (x,y) 
	local de = readmap (x,y,'de') or 0
	if de>0 then
		writemap (x,y,141)
	end
end,

onuse = function (x,y)
	achi_done (36)
	craft_reset ()
	craft.multitem = true
	craft.reqblock = 141
	craft_itemsget ()
	craft_str ()
	if craft.str~="" then
		game.craft = true
	else
		textwall (msg.game[29])
	end
end,

t_speed = 5,
t_cap = 4000

}


stone[142] = { name = 'Firewood table',
zindex = 1,
unstack = 1,
fall = {0,1},
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 142,  
col = 0,
solid = 1,
--climb = 1,
spr = img_load("brick82.png"),

onuse = function (x,y)
	achi_done (38)
	craft_reset ()
	craft.multitem = true
	craft.reqblock = 142
	craft_itemsget ()
	craft_str ()
	if craft.str~="" then
		game.craft = true
	else
		textwall (msg.game[29])
	end
end,

}

stone[143] = { name = "Gleb's table",
unstack = 1,
fall = {0,1},
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 143,  
col = 0,
solid = 1,
spr = img_load("brick81.png"),
}



stone[145] = { name = "Bottle",
unstack = 1,
fall = {0,1},
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 145,  
col = 0,
solid = 1,
spr = img_load("brick84.png"),
}

stone[146] = { name = "Stone mill",
zindex = 1,
fall = {0,1},
gather = {dig = 0}, 
digtime = 1, -- seconds
digtoid = 146,  
col = 0,
solid = 1,
spr = img_load("brick85.png"),

onuse = function (x,y)
	achi_done (39)
	craft_reset ()
	craft.multitem = true
	craft.reqblock = 146
	craft_itemsget ()
	craft_str ()
	if craft.str~="" then
		game.craft = true
	else
		textwall (msg.game[29])
	end
end,

}

stone[38] = { name = 'Cob',
cr = 1,
coby = 1,
gather = {dig = 0}, 
col = 1, -- collisionѳ
br = 1,
ttl = time.h*3,
die = 121,
solid = 1,
digtime = 2, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 38, 
spr = img_load("brick16.png"),
onfalling =  function (x,y)
	
	if maptile (x+1,y,'col')~=0 or maptile (x-1,y,'col')~=0 or
		maptile (x,y-1,'col')~=0 then
			writemap (x,y,nil,'f')
	end

end,

t_speed = 3,
t_cap = 2000
}


stone[121] = { name = 'Dry cob',
cr = 1,
gather = {smash = 3}, 
col = 1,
br = 1, 
solid = 1,
digtime = 3,
digtoinv = 8,
digtoid = 0, 
spr = img_load("brick64.png"),
t_speed = 3,
t_cap = 2000
}


stone[171] = { name = 'Skull on a stick',
gather = {dig = 0}, 
col = 0, 
solid = 0,
digtime = 3,
digtoinv = 0,
digtoid = 171, 
spr = img_load("skull.png"),
light = {20,1,0.6,0.6},

ttl = time.d,
die = 171,

ondie = function (x,y)
	writemap (x,y,1,'faith')
end,

onstep = function (x,y)
	faith = readmap (x,y,'faith')
	if faith then
		stat_recovery ('faith',faith)
		writemap (x,y,nil,'faith')
	end
end,


onuse = function (x,y)
	local d = readmap (x,y,'deaths') or -1
	if d~=pl.deaths then
		textwall (msg.stone[171].txt[1])
		writemap (x,y,pl.deaths, 'deaths')

		local add = 5

		local g= {'body','arms','food','water','heat'}

		for k,v in pairs(g) do

			--2remove
			pl.stats[v].currentgrow = pl.stats[v].currentgrow or 0
			pl.stats[v].maxgrow = pl.stats[v].maxgrow or 100
	
			if pl.stats[v].currentgrow<pl.stats[v].maxgrow then
				pl.stats[v].maxhp = pl.stats[v].maxhp + add
				pl.stats[v].currentgrow = pl.stats[v].currentgrow + add
			end

		end

	else
		textwall (msg.stone[171].txt[2+love.math.random(0,1)])
	end
end
}


stone[56] = { name = 'Stonework',
cr = 1,
coby = 1,
gather = {dig = 0}, 
ttl = time.h*3,
die = 122,
col = 1, -- collision
br = 1,
solid = 1,
digtime = 3, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 56, 
spr = img_load("brick6.png"),
onfalling =  function (x,y)
	
	if maptile (x+1,y,'col')~=0 or maptile (x-1,y,'col')~=0 or
		maptile (x,y-1,'col')~=0 then
			writemap (x,y,nil,'f')
	end

end,

t_speed = 7,
t_cap = 2000
}


stone[122] = { name = 'Dry stonework',
cr = 1,
gather = {smash = 4}, 
col = 1, -- collision
br = 1,
solid = 1,
digtime = 3, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("brick65.png"),

ondug = function (x,y)
	inv_add (item_make(5))
	inv_add (item_make(5))
	inv_add (item_make(5))
	inv_add (item_make(31))
end,

t_speed = 7,
t_cap = 2000
}


stone[123] = { name = 'Clay golem',
fall = {0,1},
gather = {dig = 0}, 
col = 0, 
solid = 0,
digtime = 3, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 123, 
spr = img_load("brick66.png"),

ttl = time.d,
die = 123,

ondie = function (x,y)
	writemap (x,y,1,'faith')
end,

onstep = function (x,y)
	faith = readmap (x,y,'faith')
	if faith then
		stat_recovery ('faith',faith)
		writemap (x,y,nil,'faith')
	end
end,



ondestroy = function (x,y,z) 

	if stone[z].col then
		return z,123
	end
end,

onuse = function ()
	textwall (msg.stone[123].txt[1])
	quest_start (14)
	quest_cd (5)
end,

t_speed = 7,
t_cap = 2000
}


stone[124] = { name = 'Chest',
zindex = 1,
fall = {0,1},
gather = {dig = 0}, 
col = 0, 
solid = 1,
unstack = 1,
digtime = 3, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 124, 
spr = img_load("brick67.png"),
noinv = true,
cont = true,
itemcount = 30,
onstep = function (x,y)
	if world[y][x].i then
		local c = #world[y][x].i
		if c<stone[124].itemcount then
			for k,v in pairs(world[y][x].i) do
				local i = inv_find (v.i)

				if i then
					inv_ground_add (x,y,inv_remove(i))
					c = c + 1
					if c>stone[124].itemcount then
						break
					end
				end
				
			end
		end
	end
end,

ondig = function (x,y)
	if world[y][x].i and #world[y][x].i>stone[124].itemcount then
		player_hit (1)
		textwall (msg.game[26])
		return true
	end
end,

t_speed = 7,
t_cap = 2000
}

stone[64] = { name = 'Brick wall',
cr = 1,
coby = 1,
gather = {smash = 4}, 
col = 1, -- collision
br = 1,
solid = 1,
digtime = 3, -- seconds
digtoinv = 64, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("brick44.png"),

t_speed = 1,
t_cap = 2000

}



stone[65] = { name = 'Limestone',
gather = {pierce = 2}, 
col = 1, -- collision

solid = 1,
digtime = 10, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 65, 
spr = img_load("brick45.png"),
onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,
onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>4 then
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (64))
		inv_ground_add(x,y, item_make (64))
		inv_ground_add(x,y, item_make (64))
		inv_ground_add(x,y,item_make(loot_make({{i=65,p=1},{i=0,p=5}}))) 
	end
	writemap (x,y,nil,'ft')
end,

t_speed = 5,
t_cap = 3000
}


stone[66] = { name = 'Crucible (raw)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 0.5, -- seconds
digtoinv = 66, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible1.png"),
onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,67) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[67] = { name = 'Crucible (empty)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 67, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible2.png"),
}

stone[68] = { name = 'Crucible (copper ore)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 68, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible3.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,73) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[118] = { name = 'Crucible (gold ore)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 132, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible3.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,200,4,119) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[119] = { name = 'Crucible (gold)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 133, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible8.png"),
}

stone[69] = { name = 'Crucible (copper & tin)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 69, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible4.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,74) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[70] = { name = 'Crucible (tin ore)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 70, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible5.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,75) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}


stone[71] = { name = 'Crucible (limestone)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 71, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible6.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,76) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[162] = { name = 'Crucible (sand)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 208, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible13.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,163) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[163] = { name = 'Crucible (glass)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 209, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible10.png"),
t_speed = 100,
t_cap = 4000
}

stone[72] = { name = 'Crucible (coal)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 72, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible7.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,77) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}


stone[73] = { name = 'Crucible (copper)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 73, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible8.png"),

transform = 78,
transformpower = 20,

}

stone[74] = { name = 'Crucible (bronze)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 74, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible9.png"),
}

stone[75] = { name = 'Crucible (tin)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 75, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible10.png"),
}

stone[76] = { name = 'Crucible (cement)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 76, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible11.png"),
}

stone[77] = { name = 'Crucible (coke)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 77, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible12.png"),
}

stone[81] = { name = 'Crucible (pyrite)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 81, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible10.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,82) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[82] = { name = 'Crucible (sulfur)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 82, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible12.png"),
}

stone[83] = { name = 'Crucible (bronze & gold)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 83, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible3.png"),

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,100,4,84) --temp,time,to 
end,
t_speed = 100,
t_cap = 4000
}

stone[84] = { name = 'Crucible (tumbaga)',
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 84, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("crucible9.png"),
}

stone[78] = { name = 'Anvil',
zindex = 1,
unstack = 1,
fall = {0,1},
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 4, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 78, 
spr = img_load("brick47.png"),
onuse = function (x,y)
	achi_done (35)
	craft_reset ()
	craft.multitem = true
	craft.reqblock = 78
	craft_itemsget ()
	craft_str ()
	if craft.str~="" then
		game.craft = true
	else
		textwall (msg.game[29])
	end
end,

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,

onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>0 then

		local anvil = tile2px (x,y)
		coord_screen2true (anvil)
		col_add ('anvil',anvil,'','anvil','props',78)
		
		local m = collide_check ('anvil','mob')

		if m and m.n>0 then
			local dmg = ft*5
			mob_hit (m.n, dmg)
		end
		colliders['anvil'] = nil

	end
	writemap (x,y,nil,'ft')

end

}


stone[57] = { name = 'Jug (empty)',
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 47, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("brick42.png"),

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,

onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>2 then
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (50)) -- scraps
		--local w = readmap (x,y,'w') or 0
		--writemap (x,y,4000+w,'w')
	end
	writemap (x,y,nil,'ft')
end,
}


stone[150] = { name = 'Bin (raw)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 0.5, -- seconds
digtoinv = 185, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("bin1.png"),

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,

onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>2 then
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (50)) -- scraps
		--local w = readmap (x,y,'w') or 0
		--writemap (x,y,4000+w,'w')
	end
	writemap (x,y,nil,'ft')
end,

onheat = function (x,y,tile,map) 
item_firing (x,y,tile,map,100,4,151) --temp,time,to 
end,

-- ondraw = function (x,y,wx,wy)
-- 	love.graphics.draw (quad, stone[150].spr,x,y+3,0,2,2)
-- end,

t_speed = 100,
t_cap = 4000

}

stone[151] = { name = 'Bin (empty)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 186, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("bin2.png"),

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,

onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>2 then
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (50)) -- scraps
		--local w = readmap (x,y,'w') or 0
		--writemap (x,y,4000+w,'w')
	end
	writemap (x,y,nil,'ft')
end,

-- ondraw = function (x,y,wx,wy)
-- 	love.graphics.draw (quad, stone[150].spr,x,y+3,0,2,2)
-- end,

}


stone[160] = { name = 'Bin (rice flour)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 160, 
die = 160,
spr = img_load("bin4.png"),
ttl = time.d,

onstep = function (x,y)

	local cnt = readmap (x,y,'cnt')

	for a = 1,6 do
		local i = inv_find ({202})
		if i then
			if cnt<12 then
				inv_remove(i)
				cnt = cnt + 1
			end
		end
	end

	writemap (x,y,cnt,'cnt')
	
end,

onuse = function (x,y)
	local cnt = readmap (x,y,'cnt') or 12
	if cnt>0 then
		inv_add (item_make(202))
		cnt = cnt - 1
		writemap (x,y,cnt,'cnt')
		if cnt==0 then 
			writemap (x,y,151)
		end
	end
end,


oninfo = function (x,y)
	local cnt = readmap (x,y,'cnt') or 12
	return draw_full (cnt,12)
end

}




stone[164] = { name = 'Bin (making cidre)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 164, 
die = 165,
spr = img_load("bin6.png"),
ttl = time.d,
}

stone[165] = { name = 'Bin (apple cidre)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 211, -- 0 - hold or item id
digtoid = 0, 
die = 165,
spr = img_load("bin7.png"),
ttl = time.d,
}

stone[166] = { name = 'Bin (making vinegar)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 166, 
die = 167,
spr = img_load("bin6.png"),
ttl = time.d,
}

stone[167] = { name = 'Bin (vinegar)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 352, -- 0 - hold or item id
digtoid = 0, 
die = 165,
spr = img_load("bin7.png"),
ttl = time.d,
}


stone[168] = { name = 'Bin (nixtamalization)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 168, 
die = 169,
spr = img_load("bin6.png"),
ttl = time.d,
}

stone[169] = { name = 'Bin (nixtamalized corn)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
die = 169,
spr = img_load("bin7.png"),
ttl = time.d,
ondig = function (x,y)
	writemap (x,y,151)
	inv_add (item_make(217))
	inv_add (item_make(217))
	inv_add (item_make(217))
	inv_add (item_make(217))
	inv_add (item_make(217))
	inv_add (item_make(217))
	inv_add (item_make(217))
	inv_add (item_make(217))
	inv_add (item_make(217))
	inv_add (item_make(217))
	return true
end
}


stone[161] = { name = 'Bin (corn flour)',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 161, 
die = 161,
spr = img_load("bin5.png"),
ttl = time.d,

onstep = function (x,y)

	local cnt = readmap (x,y,'cnt')

	for a = 1,6 do
		local i = inv_find ({203})
		if i then
			if cnt<12 then
				inv_remove(i)
				cnt = cnt + 1
			end
		end
	end

	writemap (x,y,cnt,'cnt')
	
end,

onuse = function (x,y)
	local cnt = readmap (x,y,'cnt') or 12
	if cnt>0 then
		inv_add (item_make(203))
		cnt = cnt - 1
		writemap (x,y,cnt,'cnt')
		if cnt==0 then 
			writemap (x,y,151)
		end
	end
end,


oninfo = function (x,y)
	local cnt = readmap (x,y,'cnt') or 12
	return draw_full (cnt,12)
end

}

stone[152] = { name = 'Worm bin',
zindex = 1,
unstack = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 152, 
die = 152,
spr = img_load("bin3.png"),
sprs = 
{
	img_load("bin3.png"),
	img_load("bin8.png"),

},

ondraw = function (x,y,wx,wy)
	local cnt = readmap (wx,wy,'cnt') or 0
	if cnt>4 then
		love.graphics.draw (quad, stone[152].sprs[1],x,y,0,2,2)
	else
		love.graphics.draw (quad, stone[152].sprs[2],x,y,0,2,2)
	end
end,



ttl = time.d,

nonuse = function (x,y)

	local cnt = readmap (x,y,'cnt') or 0
	if cnt<8 then
		textwall (msg.stone[152].txt[1])
	else
		textwall (msg.stone[152].txt[2])
	end
end,

onstep = function (x,y)

	local cnt = readmap (x,y,'cnt') or 0
	if cnt == 0 then
		writemap (x,y,152)
	end

	for a = 1,8 do
		local i = inv_find ({3,37})
		if i then
			if cnt<8 then
				inv_remove(i)
				cnt = cnt + 1
			end
		end
	end

	writemap (x,y,cnt,'cnt')

end,

ondie = function (x,y)
	local cnt = readmap (x,y,'cnt') or 0
	if cnt>=4 then
		inv_ground_add (x,y,item_make(59))
		cnt = cnt - 4
		writemap (x,y,cnt,'cnt')
		if cnt~=0 then mob_create (x,y,3) end
	end
end,


oninfo = function (x,y)
	local cnt = readmap (x,y,'cnt') or 0
	return draw_full (cnt,8)
end

}


stone[58] = { name = 'Jug (water)',
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 48, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("brick42_w.png"),

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,

onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>2 then
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (50)) -- scraps
		local w = readmap (x,y,'w') or 0
		writemap (x,y,4000+w,'w')
	end
	writemap (x,y,nil,'ft')
end,

transformi = 189,
transformpower = 10,

}


--firing 
stone[59] = { name = 'Jug (raw)',
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 49, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("brick42_r.png"),
onheat = function (x,y,tile,map) item_firing (x,y,tile,map,100,4,57) --temp,time,to 
end,
}


stone[60] = { name = 'Sand',
cr = 1,
gather = {dig = 0}, 
fall = {0,1},
col = 1, -- collision
br = 1,
solid = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("brick43.png"),
slide = 0.01,
ttl = time.d,
die = 60,

onheat = function (x,y,tile,map)
	if item_firing (x,y,tile,map,100,10,185) then --temp, time, to

	end
end,

ondig = function ()
	
	if inv_find (47,51) then
		return nil
	else
		textwall (msg.game[11])
	end

	return true
end,
ondie = function (x,y)

	if (readmap (x,y-1,'w') or 0)>6000 and readmap (x,y-1,'b')==0 and lookaround (x,y,{144},5)==nil then
		writemap (x,y-1,144)
	end

	local dr = readmap (x,y-1,'dr')
	if dr then
		dr = dr / 2
		if dr<10 then dr = 10 end
		writemap (x,y-1,dr,'dr')
	end

end,
absorb = 3000,
t_speed = 40,
t_cap = 100000
}


stone[144] = { name = "Seaweed",
fall = {0,1},
gather = {cut = 2}, 
digtime = 1, -- seconds
digtoid = 144,  
col = 0,
solid = 1,
die = 144,
spr = img_load("brick83.png"),
ttl = time.d,
onfell = function (x,y)
	local w = readmap (x,y,'w')
	if (w and w<5000) or w==nil then
		writemap (x,y,0)
		inv_ground_add (x,y,item_make (194))
	end
end,   --  
ondie = function (x,y)

	if readmap (x,y+1,'b')~=60 then
		return
	end

	local xa = love.math.random (-1,1)
	local ya = love.math.random (-1,1)

	local w = readmap (x+xa,y+ya,'w')
	local b = readmap (x+xa,y+ya,'b')

	if b==0 and w and w>5000 then
		writemap (x+xa,y+ya,144)
		writemap (x+xa,y+ya, (readmap (x+xa,y+ya,'fish') or 0)+1, 'fish')
	end

end,
}


stone[61] = { name = 'Jug (sand)',
gather = {dig = 0}, 
fall = {0,1},
col = 0, -- collision
solid = 1,
digtime = 1, -- seconds
digtoinv = 51, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("brick42_s.png"),

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,

onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>2 then
		writemap (x,y,60)
		inv_ground_add(x,y, item_make (50)) -- scraps
		local w = readmap (x,y,'w') or 0
		writemap (x,y,4000+w,'w')
	end
	writemap (x,y,nil,'ft')
end,

}


stone[35] = { name = 'Stone Block',
gather = {dig = 0}, 
digtime = 0.2, -- seconds
digtoid = 35,
digtoinv = 0, 
col = 1,
solid = 1,
spr = img_load("brick27.png"),
onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,
onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0

	if ft>0 then
		local anvil = tile2px (x,y)
		coord_screen2true (anvil)
		col_add ('anvil',anvil,'','anvil','props',78)
		
		local m = collide_check ('anvil','mob')

		if m and m.n>0 then
			local dmg = ft*5
			mob_hit (m.n, dmg)
		end
		colliders['anvil'] = nil
	end


	if ft>6 then
		writemap (x,y,33)
		inv_ground_add(x,y, item_make (31))
		inv_ground_add(x,y, item_make (5))
		inv_ground_add(x,y, item_make (31))
		inv_ground_add(x,y, item_make (5))
	end
	writemap (x,y,nil,'ft')
end,

t_speed = 300,
t_cap = 30000

}


stone[33] = { name = 'Big Fucking Stone',
unstack = 1,
fall = {0,1},
gather = {dig = 0}, 
digtime = 2, -- seconds
digtoid = 0, 
digtoinv = 34,col = 0, solid = 0,
spr = img_load("brick25.png"),
ondestroy = function (x,y,z) 
	if z == 33 then return 35 end
	if z==17 then return 1,33 else return z,33 end
	--inv_ground_add(x,y-1, item_make (34))
end,

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,
onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>6 then
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (36)) -- pyrite
		inv_ground_add(x,y, item_make (31))
		inv_ground_add(x,y, item_make (5))
		inv_ground_add(x,y, item_make (31))
		inv_ground_add(x,y, item_make (5))
	end
	writemap (x,y,nil,'ft')
end,

t_speed = 200,
t_cap = 2000

}

stone[51] = { name = 'Chair',
zindex = 1,
fall = {0,1},
unstack = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 0.5, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 51, 
spr = img_load("brick40s.png"),
onuse = function (x,y)
	player_rest (x,y,1,2)
end,
}

stone[39] = { name = 'Haystack',
ttl = time.m*6,
zindex = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 3, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 39, 
spr = img_load("brick28.png"),
onuse = function (x,y)
	player_rest (x,y,1.2,3)
end,
transformi = 39,
transformpower = 10,
onheat = function (x,y,tile,map)
	if map.de and map.de>75 then
		inv_ground_add(x,y, item_make (37))
		inv_ground_add(x,y, item_make (39))
		writemap (x,y,55)
	end
end,

}


stone[125] = { name = 'Moss bed',
fall = {0,1},
unstack = 1,
ttl = time.y,
gather = {dig = 0}, 
col = 0, -- collision
solid = 1,
digtime = 3, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 125, 
spr = img_load("brick68.png"),
onuse = function (x,y)
	player_rest (x,y,1.3,4)
end,
}


stone[12] = { name = 'Soil',
cr = 1,
col = 1,
br = 1,
solid = 1,
z = 1,
gather = {dig = 2},
digtime = 3,
digtoinv = 0,
digtoid = 12,
spr = img_load("brick7.png"),
transformi = 38,
transformpower = 10,
absorb = 300
}

stone[13] = { name = 'Rich Soil',
cr = 1,
col = 1,
br = 1,
solid = 1,
z = 1,
gather = {dig = 2},
digtime = 3,
digtoinv = 0,
digtoid = 13,
spr = img_load("brick8.png"),
tansformi = 7,
transformpower = 10,
absorb = 300
}




-----------------------------------------------------
--SYSTEM

function digger (x,y,z)

	local tile, map = maptile (x,y,"all")
	local diggable = {1,8,9,17,31,32,47,48,99}

	if map and map.b and in_array (diggable, map.b) then
		writemap (x,y,z)
		writemap (x,y,255,'n')
		return true
	end

	return false

end

stone[40] = { name = 'Up',
col = 0,
solid = 1,
spr = img_load("up.png"),
ttl = 0,
die = 0,
ondie = function (x,y) 
	digger (x,y-1,40)
	writemap (x,y,0,'n')
	writemap (x,y,255,'n')
	return true
end,
--ondraw = function (x,y,wx,wy)
--end
}

stone[41] = { name = 'Right',
col = 0,
solid = 1,
spr = img_load("right.png"),
ttl = 0,
die = 0,
ondie = function (x,y) 
	digger (x+1,y,41)
	writemap (x,y,0,'n')
	writemap (x,y,255,'n')
	return true
end,
--ondraw = function (x,y,wx,wy)
--end
}


stone[42] = { name = 'Down',
col = 0,
solid = 1,
spr = img_load("down.png"),
ttl = 0,
die = 0,
ondie = function (x,y) 
	digger (x,y+1,42)
	writemap (x,y,0,'n')
	writemap (x,y,255,'n')
	return true
end,
--ondraw = function (x,y,wx,wy)
--end
}

stone[43] = { name = 'Left',
col = 0,
solid = 1,
spr = img_load("left.png"),
ttl = 0,
die = 0,
ondie = function (x,y) 
	digger (x-1,y,43)
	writemap (x,y,0,'n')
	writemap (x,y,255,'n')
	return true
end,
--ondraw = function (x,y,wx,wy)
--end
}

stone[44] = { name = 'Digger',
col = 0,
solid = 1,
spr = img_load("digger.png"),
ttl = 4,
die = 0,
ondie = function (x,y) 

	local xa = readmap (x,y,'xa') or 0
	local ya = readmap (x,y,'ya') or 1
	local cnt = readmap (x,y,'cnt') or 4
	local total = readmap (x,y,'total') or 0


	cnt = cnt - 1
	total = total + 1

	if total>10 then 
		writemap (x,y,0,'clear')
		return false 
	end


	if cnt < 0 or not digger (x+xa,y+ya,44) then

		cnt = love.math.random (2,10)

		if ya>0 then

			if love.math.random (0,100)<=50 then
				xa = -1
			else
				xa = 1
			end

			ya = 0

		else

			cnt = 3
			ya = 1
			xa = 0

		end

		writemap (x,y,44)
		writemap (x,y,xa,'xa')
		writemap (x,y,ya,'ya')
		writemap (x,y,cnt,'cnt')
		writemap (x,y,total,'total')
		return true


	else
	
		digger (x+xa,y+ya-1,0)
		writemap (x+xa,y+ya,xa,'xa')
		writemap (x+xa,y+ya,ya,'ya')
		writemap (x+xa,y+ya,cnt,'cnt')
		writemap (x+xa,y+ya,total,'total')

	end



end,
--ondraw = function (x,y,wx,wy)
--end
}



stone[89] = { name = "Jack-o'-lantern",
die = 0,
gather = {dig = 0}, 
ttl = time.d,
digtoinv = 92,
digtime = 1,
col = 0,
solid = 1,
unstack = 1,
fall = {0,1},
spr2 = img_load("pumpkin10.png"),
spr = img_load("pumpkin11.png"),
ondraw = function (x,y,wx,wy)
	if math.floor(wy+wx+(game.dt)*2)%2 == 1 then
	love.graphics.draw (quad, stone[89].spr,x,y,0,2,2)
	else
	love.graphics.draw (quad, stone[89].spr2,x,y,0,2,2)
	end
end,
ondie = function (x,y) 
	inv_ground_add(x,y, item_make (59)) --fertilizer
	inv_ground_add(x,y, item_make (94)) --fertilizer
	inv_ground_add(x,y, item_make (94)) --seed
end,

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,

onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>2 then
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (93)) -- piece
		inv_ground_add(x,y, item_make (93)) -- piece
		inv_ground_add(x,y, item_make (94)) -- seed
		--local w = readmap (x,y,'w') or 0
		--writemap (x,y,4000+w,'w')
	end
	writemap (x,y,nil,'ft')
end,

light = {44,0.6,0.6,0}
}


stone[90] = { name = "Pumpkin",
ttl = time.m,
gather = {dig = 0}, 
digtoinv = 91,
digtime = 1,
col = 0,
solid = 1,
unstack = 1,
fall = {0,1},
spr = img_load("pumpkin9.png"),
ondie = function (x,y) 
	inv_ground_add(x,y, item_make (59)) --fertilizer
	inv_ground_add(x,y, item_make (94)) --seed
	inv_ground_add(x,y, item_make (94)) --seed
end,

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,

onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>2 then
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (93)) -- piece
		inv_ground_add(x,y, item_make (93)) -- piece
		inv_ground_add(x,y, item_make (94)) -- seed
		inv_ground_add(x,y, item_make (94)) -- seed
		inv_ground_add(x,y, item_make (94)) -- seed
		--local w = readmap (x,y,'w') or 0
		--writemap (x,y,4000+w,'w')
	end
	writemap (x,y,nil,'ft')
end,


}


stone[5] = { name = 'Young glowin tree',
zindex = 1,
dpr = 1,
col = 0, -- collision
digtime = 3, -- seconds
digtoinv = 2, -- 0 - hold or item id
digtoid = 0, 
ttl = time.d,
die = 6, 
spr = img_load("lample0.png"),
light = {32,0.6,0.6,1},
ondie = function (x,y) 
	achi_set (2,2)
	writemap (x,y+1,5,'e')
	if grow (x,y-1,0,53) then
		writemap (x,y-1,1,'mob')
	end
end,
}


stone[193] = { name = 'Ceiling light',
coby = 2,
gather = {dig = 0}, 
col = 0, -- collision
digtime = 3, -- seconds
digtoinv = 346, -- 0 - hold or item id
--digtoid = 193, 
ttl = time.w*2,
die = 194, 
spr = img_load("brick108.png"),
sprs = 
{
img_load("brick108.png"),
img_load("brick110.png"),

},

light = {64,0.99,0.9,0.38},
--light = text_color ("#fee761ff")

onfalling =  function (x,y)
	
	if maptile (x,y-1,'col')~=0 then
		writemap (x,y,nil,'f')
	end

end,

ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[193].sprs[ba1_2],x,y,0,2,2)
end,

}

stone[194] = { name = 'Empty ceiling light',
coby = 2,
gather = {dig = 0}, 
col = 0, -- collision
digtime = 3, -- seconds
digtoinv = 347, -- 0 - hold or item id
digtoid = 193, 
ttl = time.d,
die = 194, 
spr = img_load("brick109.png"),
--light = {64,0.99,0.9,0.38},
--light = text_color ("#fee761ff")

onfalling =  function (x,y)
	
	if maptile (x,y-1,'col')~=0 then
		writemap (x,y,nil,'f')
	end

end,

}


stone[6] = { name = 'Glowin tree',
zindex = 1,
dpr = 1,
col = 0, -- collision
digtime = 3, -- seconds
digtoinv = 2, -- 0 - hold or item id
digtoid = 0, 
ttl = time.d,
die = 7, 
spr = img_load("lample1.png"),
light = {64,0.7,0.7,1},
ondie = function (x,y)
	achi_set (2,3)
end

}

stone[7] = { name = 'Mature glowin tree',
zindex = 1,
gather = {cut = 1}, 
dpr = 1,
col = 0, -- collision
digtime = 7, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
ttl = time.w*2,
die = 126, 
spr = img_load("lample2.png"),

sprs = 
{
	img_load("lample2.png"),
	img_load("lample4.png"),
},

ondie = function (x,y) 
	if grow (x,y-1,0,53) then
		writemap (x,y-1,9,'mob')
	end
end, 
-- ondestroy = function (x,y,z) 
-- 	inv_ground_add(x,y, item_make (28))
-- 	inv_ground_add(x,y, item_make (3))
-- 	return z,0
-- end,
ondig = function (x,y)
	mob_hostile ('slime')
	writemap (x,y,153)
	inv_add (item_make(28))
	return true
end,
ondug = function (x,y)
	

end,
light = {110,1,1,1},
--sound = 16

ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[7].sprs[ba1_2],x,y,0,2,2)
end,

}


stone[126] = { name = 'Dying glowin tree',
zindex = 1,
gather = {dig = 0}, 
unstack = 1,
dpr = 1,
col = 0, -- collision
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 153, 
ttl = time.d,
die = 153, 
spr = img_load("lample3.png"),
ondie = function (x,y) 
	local i = inv_ground_find_i (x,y+1,4)
	inv_ground_remove (x,y+1,i)
end, 
ondig = function ()
	mob_hostile ('slime')
end,
light = {40,0.4,0.4,0.4}
}


stone[197] = { name = 'Dandelion',
zindex = 1,
fall = {0,1},
falldie = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 0,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
loot = {
	{i=0,p=10},
	{i=3,p=20},
	{i=355,p=10},
}, 
digtoid = 0, 
ttl = time.d-time.h,
spr = img_load("clover2.png"),
die = 197,            
ondie = function (x,y) 

	if readmap (x+1,y,'b')==197 or readmap (x-1,y,'b')==197 then
		writemap (x,y,36)
		return
	end

	if has_light (x,y) then
		local xp,yp = plant_spores (x,y,{102,12,13,1,2},7,197)
		if xp and has_light (xp,yp)==nil then
			writemap (xp,yp,0)
		end

		writemap (x,y+1,nil,'wt')
	else
		writemap (x,y,197)
	end

	fertilize (x,y+1,-3)

end,
}

stone[36] = { name = 'Clover',
zindex = 1,
fall = {0,1},
falldie = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 0,
digtime = 1, -- seconds
digtoinv = 3, -- 0 - hold or item id
loot = {
	{i=38,p=10},
	{i=0,p=100},
	{i=321,p=2}, --4 leaf
	{i=175,p=1}, --chard

}, 
digtoid = 0, 
ttl = time.d,
spr = img_load("clover.png"),
die = 36,            
ondie = function (x,y) 

	if love.math.random (0,100)<10 then
		writemap (x,y,197)
		return
	end

	if has_light (x,y) then
		local xp,yp = plant_spores (x,y,{102,12,13,1,2},5,36)
		if xp and has_light (xp,yp)==nil then
			writemap (xp,yp,0)
		end

		writemap (x,y+1,nil,'wt')
	else
		writemap (x,y,37)
	end

	fertilize (x,y+1,1)


end,
}

stone[37] = { name = 'Withered clover',
fall = {0,1},
falldie = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 0,
loot = {{i=38,p=1},{i=0,p=4}},
digtime = 3, -- seconds
digtoinv = 37, -- 0 - hold or item id
digtoid = 0, 
ttl = time.h,
spr = img_load("clover_withered.png"),
die = 37,            
ondie = function (x,y) 

	if has_light (x,y) then 
		writemap (x,y,36)
	end

end,
}





stone[10] = { name = 'Rope',
col = 0, -- collision
solid = 0,
climb = 1,
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("rope1.png"),

}

stone[11] = { name = 'Grappling hook',
coby = 1,
gather = {dig = 0}, 
col = 0, -- collision
solid = 0,
--climb = 1,
digtime = 0.7, -- seconds
digtoinv = 101, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("rope2.png"),

sprs = {
	img_load("rope3.png"),
	img_load("rope2.png"),	
},
ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[11].sprs[(readmap(wx,wy,'spr') or 2)],x,y,0,2,2)
end,

ondestroy = function (x,y,z)
	inv_ground_add(x,y,item_make(101))
	for i=y+1,y+10 do
		if readmap (x,i,'b')==10 then
			writemap (x,i,0)
		end
	end

	return z,0
end,

check = function (x,y)

	-- if maptile (x,y+1,'solid')==1 then
	-- 	writemap (x,y,0)
	-- 	inv_ground_add(x,y,item_make(101))
	-- end

	if maptile (x+1,y,'solid')==1 then
		writemap (x,y,1,'spr')
	else
		if maptile (x-1,y,'solid')==1 then
			writemap (x,y,2,'spr')
		else
			if readmap (x,y,'f')==nil then
				stone[11].ondug (x,y)
				writemap (x,y,0)
				inv_ground_add(x,y,item_make(101))
			end
		end
	end
end,

onfalling = function (x,y)
	
	if maptile (x+1,y,'solid')==1 or maptile (x-1,y,'solid')==1 then
		writemap (x,y,nil,'f')
		for i=y+1,y+10 do
			if readmap (x,i,'b')==0 then
				writemap (x,i,10)
			else
				break
			end
		end
	end
end,

onfell = function (x,y)
	writemap (x,y,0)
	inv_ground_add(x,y,item_make(101))
end,

onuse = function (x,y)
	writemap (x,y,0)
	inv_add (item_make(101))
	for i=y+1,y+10 do
		if readmap (x,i,'b')==10 then
			writemap (x,i,0)
		end
	end
	return true
end,

ondug = function (x,y)
	for i=y+1,y+10 do
		if readmap (x,i,'b')==10 then
			writemap (x,i,0)
		end
	end
	return true
end



}

stone[14] = { name = 'Giant Weed',
gather = {chop = 1}, 
col = 0, -- collision
solid = 0,
digtime = 3, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 

ttl = time.d,
spr = img_load("weed1.png"),
die = 14,
ondie = function (x,y) 
	if has_light (x,y) then
		growup (x,y,14)
		growup (x+1,y,14)
		growup (x-1,y,14)
		writemap (x,y,15)
	end
end,

ondie_old = function (x,y) 
	if has_light (x,y) then
		if growup (x,y,14)==false then
			if growup (x+1,y,14)==false then
				if growup (x-1,y,14)==false then
					if love.math.random (0,100)<40 then writemap (x,y,15) end
				end
			end
		end
	end
end   
}


stone[15] = { name = 'Mature Giant Weed',
	gather = {chop = 2}, 
	col = 0, -- collision
	solid = 0,
	digtime = 7, -- seconds
	digtoinv = 15, -- 0 - hold or item id
	digtoid = 0, 
	
	ttl = time.h*8,
	spr = img_load("weed2.png"),
	die = 15,            
	ondie = function (x,y) 

		if maptile (x,y-1) == 1 then 
			writemap (x,y,16) 
		else

			if love.math.random (0,100)<10 then
				writemap (x,y,1,'f')
			else
				if love.math.random (0,100)<5 then
					writemap (x,y,0)
				end

				if love.math.random (0,100)<2 then
					writemap (x,y,16,'b') -- seed
				end

				if love.math.random (0,100)<5 then
				
					if mob_search (x,y,30,2)<2 then --spider overpopulation
						mob_create (x,y,2)
					end

				end

				if love.math.random (0,100)<2 then
					if mob_search (x,y,30,9)<3 then --amoeba overpopulation
						mob_create (x,y,9)
					end
				end

			end
			
		end

	end,

	onfell = function (x,y)
	inv_ground_add(x,y,item_make(3)) 
	inv_ground_add(x,y,item_make(15))
		writemap(x,y,0)
	end    
}

stone[16] = { name = 'Giant Weed Seeds',
gather = {chop = 1}, 
col = 0, -- collision
solid = 1,
digtime = 3, -- seconds
digtoinv = 9, -- 0 - hold or item id
digtoid = 0, 

ttl = time.w,
spr = img_load("weed3.png"),
die = 16,   
ondie = function (x,y)
	writemap (x,y,1,'f')
end,
onfell = function (x,y)

	inv_ground_add(x,y,item_make(9)) 
	inv_ground_add(x,y,item_make(3)) 
	inv_ground_add(x,y,item_make(15)) 
	
	-- seed 1:5 (9)
	writemap(x,y,0)
	
end    
}


stone[45] = { name = 'Ice shards',
t_speed = 2000,
t_cap = 100,
gather = {smash = 1},
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
digtime = 10,
loot = {
{i=38,p=10}, --clover
{i=9,p=10}, --giant weed
{i=175,p=1}}, --chard

ondug = function (x,y) 
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(1)) 
	mob_create (x,y,7)
end,
-- 1,38,25,7,9
col = 0,
solid = 1,
spr = img_load("brick32.png"),
die = 0,
light = {25,0.3,0.3,0.7},
onheat = function (x,y,tile,map)
	if item_firing (x,y,tile,map,10,1,0) then --temp, time, to
		local w = readmap (x,y,'w') or 0
		inv_ground_add(x,y,item_make(loot_make(stone[45].loot)))
		writemap (x,y,10000+w,'w')
	end
end
}


stone[46] = { name = 'Icicle',
t_speed = 2000,
t_cap = 100,
fall = {0,-1},
gather = {smash = 2},
digtoinv = 0,
digtoid = 0, 
digtime = 10,
col = 0,
solid = 0,
spr = img_load("brick33.png"),
die = 0,
ondug = function (x,y) 
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(9)) 
end,
onfell = function (x,y)
	writemap (x,y,0)
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(40)) 
	inv_ground_add(x,y,item_make(9)) 
end,

onheat = function (x,y,tile,map)
	if item_firing (x,y,tile,map,10,1,0) then --temp, time, to
		local w = readmap (x,y,'w') or 0
		inv_ground_add(x,y,item_make(9)) --weed
		writemap (x,y,0)
		writemap (x,y,10000+w,'w')
	end
end,
}


stone[47] = { name = 'Ice cube',
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
gather = {pierce = 1},
digtime = 7,
digtoinv = 0,
digtoid = 47,
col = 1,
solid = 1,
spr = img_load("brick34.png"),
die = 0,
cold = 0.7,
onheat = function (x,y,tile,map)
	if item_firing (x,y,tile,map,10,10,0) then --temp, time, to
		local w = readmap (x,y,'w') or 0
		writemap (x,y,0)
		writemap (x,y,10000+w,'w')
	end
end,

ondig = function (x,y) 
	if love.math.random (0,100)<5 then
		inv_ground_add(x,y,item_make(40)) 
		inv_ground_add(x,y,item_make(40)) 
		inv_ground_add(x,y,item_make(40)) 
		inv_ground_add(x,y,item_make(40)) 
		writemap (x,y,0)
		textwall (msg.stone[47].txt[1])
		return true
	end
end,

onfalling = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	ft = ft + 1
	writemap (x,y,ft,'ft')
	writemap (x,y-1,nil,'ft')
end,
onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>3 then
		inv_ground_add(x,y,item_make(40))
		inv_ground_add(x,y,item_make(40))
		inv_ground_add(x,y,item_make(40))
		inv_ground_add(x,y,item_make(40))
		--textwall (msg.stone[47].txt[1])
		writemap (x,y,0)
	end
	writemap (x,y,nil,'ft')
end,

slide = 0.98,
onstepon = function (x,y,xo,yo)
	
	if pl.moving == 'right' or pl.xspeed>0 then
		if pl.xspeed==0 then
			pl.xspeed = 3
		else
			pl.xspeed = pl.xspeed + 0.1
		end
	end

	if pl.moving == 'left' or pl.xspeed<0 then
		if pl.xspeed==0 then
			pl.xspeed = -3
		else
			pl.xspeed = pl.xspeed - 0.1
		end
	end
	

end
}





stone[185] = { name = 'Glass',
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
coby = 1,
gather = {dig = 0},
digtime = 7,
digtoinv = 0,
digtoid = 185,
col = 1,
solid = 1,
spr = img_load("brick100.png"),
die = 0,


onfalling =  function (x,y)
	if maptile (x+1,y,'col')~=0 or maptile (x-1,y,'col')~=0 or
		maptile (x,y-1,'col')~=0 then
			writemap (x,y,nil,'f')
	end
end,


onfell = function (x,y)
	local ft = readmap (x,y,'ft') or 0
	if ft>7 then
		writemap (x,y,0)
	end
	writemap (x,y,nil,'ft')
end,

slide = 0.99,

onstepon = function (x,y,xo,yo)
	
	if pl.moving == 'right' or pl.xspeed>0 then
		if pl.xspeed==0 then
			pl.xspeed = 4
		else
			pl.xspeed = pl.xspeed + 0.2
		end
	end

	if pl.moving == 'left' or pl.xspeed<0 then
		if pl.xspeed==0 then
			pl.xspeed = -4
		else
			pl.xspeed = pl.xspeed - 0.2
		end
	end
	

end
}




stone[198] = { name = 'Calories burner',
--loot = {{i=332,p=1}},
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
gather = {dig = 0},
digtime = 7,
digtoinv = 0,
digtoid = 186,
col = 0,
solid = 1,
spr = img_load("brick113.png"),
ttl = time.d,
die = 186,

ondie = function (x,y)
	writemap (x,y,7,'faith')
end,

onstep = function (x,y)
	faith = readmap (x,y,'faith')
	if faith then
		stat_recovery ('faith',faith)
		writemap (x,y,nil,'faith')
	end
end,

t_speed = 300,
t_cap = 30000

}



stone[186] = { name = 'Haed Sculpture',
loot = {{i=332,p=1}},
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
gather = {dig = 0},
digtime = 7,
digtoinv = 0,
digtoid = 186,
col = 0,
solid = 1,
spr = img_load("brick101.png"),

ttl = time.d,
die = 186,

ondie = function (x,y)
	writemap (x,y,7,'faith')
end,

onstep = function (x,y)
	faith = readmap (x,y,'faith')
	if faith then
		stat_recovery ('faith',faith)
		writemap (x,y,nil,'faith')
	end
end,

t_speed = 300,
t_cap = 30000

}



stone[190] = { name = 'Huītzilōpōchtli altar',
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
gather = {dig = 0},
digtime = 7,
digtoinv = 0,
digtoid = 186,
col = 0,
solid = 1,
spr = img_load("brick106.png"),

onuse = function (x,y)
	writemap (x,y,191)
	player_hit (5)
	if love.math.random (0,100)<50 then
		buff_add (22)
	else
		buff_add (9)
	end
end

}

stone[191] = { name = 'Huītzilōpōchtli altar', --full
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
gather = {dig = 0},
digtime = 7,
digtoinv = 0,
digtoid = 186,
col = 0,
solid = 1,
spr = img_load("brick105.png"),

ttl = time.d,
die = 191,

ondie = function (x,y)
	writemap (x,y,10,'faith')
end,

onstep = function (x,y)
	faith = readmap (x,y,'faith')
	if faith then
		stat_recovery ('faith',faith)
		writemap (x,y,nil,'faith')
		writemap (x,y,190)
	end
end,

}


stone[192] = { name = 'Sandbox', --full
gather = {dig = 0},
digtime = 7,
digtoinv = 0,
digtoid = 186,
col = 0,
solid = 1,
spr = img_load("brick107.png"),

ttl = time.d,
die = 192,

ondie = function (x,y)
	writemap (x,y,7,'faith')
end,

onstep = function (x,y)
	faith = readmap (x,y,'faith')
	if faith then
		pl.unrest = (pl.unrest or 0) + time.h*3
		stat_recovery ('faith',faith)
		writemap (x,y,nil,'faith')
	end
end,

}

stone[187] = { name = 'Lingam statue',
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
unstack = 1,
gather = {dig = 0},
digtime = 7,
digtoinv = 0,
digtoid = 187,
col = 0,
solid = 1,
spr = img_load("brick103.png"),

ttl = time.d,
die = 187,

ondie = function (x,y)
	writemap (x,y,5,'faith')
end,

onstep = function (x,y)
	faith = readmap (x,y,'faith')
	if faith then
		stat_recovery ('faith',faith)
		writemap (x,y,nil,'faith')
	end
end,


ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[187].spr,x,y-14,0,2,2)
end,


}



stone[196] = { name = 'The Wicker Man',
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
unstack = 1,
gather = {dig = 0},
digtime = 7,
digtoinv = 0,
digtoid = 196,
col = 0,
solid = 1,
spr = img_load("brick112.png"),

ttl = time.d,
die = 196,


ondraw = function (x,y,wx,wy)
	love.graphics.draw (quad, stone[196].spr,x,y-28,0,2,2)
end,


}


stone[188] = { name = 'Stone sculpture',
-- t_speed = 2000,
-- t_cap = 100,
--fall = {0,1},
digtime = 7,
digtoinv = 0,
digtoid = 186,
col = 0,
solid = 0,
spr = img_load("brick104.png"),

onstep = function (x,y)
	sound_add ('rockfall',41, {x=x, y=y})
	stat_recovery ('faith',5)
	writemap (x,y,0)
	inv_ground_add (x,y,item_make(5))
	inv_ground_add (x,y,item_make(5))
	inv_ground_add (x,y,item_make(31))
	inv_ground_add (x,y,item_make(31))
	inv_ground_add (x,y,item_make(29))
	

end,




}


stone[48] = { name = 'Frozen dirt',
cr = 1,
cold = 0.5,
col = 1,
br = 1,
solid = 1,
z = 1,
slide = 0.96,
gather = {dig = 2},
digtime = 5,
digtoinv = 0,
digtoid = 48,
die = 1,

onheat = function (x,y,tile,map)
	local e = readmap (x,y,'e')
	if item_firing (x,y,tile,map,3,1,1) then --temp, time, to
		if e then
			writemap (x,y,e,'e')
		end
	end
end,

ondie = function (x,y)

	-- if lookaround(x,y,{45,46,47,48},1) then
	-- 	writemap (x,y,48)
	-- else
	-- 	--local w = readmap (x,y-1,'w') or 0
	-- 	--writemap (x,y,3000+w,'w')
	-- end

end,
spr = img_load("brick35.png"),

transformi = 40,
transformpower = 10

}

stone[49] = { name = 'Skeleton',
col = 0,
solid = 0,
fall = {0,1},
gather = {dig = 0},
digtime = 2,
digtoinv = 0,
digtoid = 49,
-- loot = {{i=11,p=1}},
spr = img_load("brick39.png"),
onfell = function (x,y)
		writemap (x,y,0)
		--inv_ground_add(x,y, item_make (12)) -- skull
		mob_create (x,y,12)
		inv_ground_add(x,y, item_make (95)) -- broken bone
		inv_ground_add(x,y, item_make (11)) -- bone
		inv_ground_add(x,y, item_make (11)) -- bone
		inv_ground_add(x,y, item_make (11)) -- bone

		--inv_ground_add(x,y, item_make (13)) -- sinew

		local i = {
		{i=128,p=1},
		{i=134,p=1},
		{i=137,p=1},
		{i=140,p=3},
		{i=178,p=1},

		{i=315,p=1}, --bandage
		{i=299,p=1}, --empty can
		{i=164,p=1}, --snake can
		{i=289,p=1}, --fishing pole
		{i=327,p=1}, --grenade
		


		

		}
		inv_ground_add(x,y, item_make(loot_make(i),0.5))

end,
-- ondraw = function (x,y,wx,wy)
-- 	if readmap (wx+1,wy,'b') ~= 0 then
-- 	love.graphics.draw (quad, stone[49].spr,x,y,0,2,2)
-- 	else
-- 	love.graphics.draw (quad, stone[49].spr,x,y,0,-2,2,16)
-- 	end
-- end
}


stone[134] = { name = 'Animal remains',
col = 0,
solid = 0,
fall = {0,1},
gather = {dig = 0},
digtime = 2,
digtoinv = 0,
digtoid = 0,
-- loot = {{i=11,p=1}},
spr = img_load("brick73.png"),
ondug = function (x,y)
		writemap (x,y,0)
		inv_ground_add(x,y, item_make (11)) -- bone
		inv_ground_add(x,y, item_make (11)) -- bone
		inv_ground_add(x,y, item_make (11)) -- bone
		inv_ground_add(x,y, item_make (176)) -- bone
		inv_ground_add(x,y, item_make (176)) -- bone
		inv_ground_add(x,y, item_make (176)) -- bone
end,
}


-- stone[50] = { name = 'Nuclear heater',
-- col = 0,
-- solid = 1,
-- fall = {0,1},
-- z = 1,
-- slide = 0.1,
-- gather = {dig = 0},
-- digtime = 2,
-- digtoinv = 0,
-- digtoid = 50,
-- spr = img_load("brick38.png"),
-- light = {24,0.4,0.4,0.1},
-- onuse = function (x,y)

-- 	local cdt = time.d*2
-- 	local cd = readmap (x,y,'cd') or game.time
-- 	local charges = readmap (x,y,'charges') or 7

-- 	if cd<=game.time and charges>0 then
-- 		writemap (x,y,50,'de')
-- 		writemap (x,y,40000,'tp')
-- 		--heat_spread (x,y,0,-1)
-- 		writemap (x,y,game.time+cdt,'cd')
-- 		charges = charges - 1
-- 		writemap (x,y,charges,'charges')

-- 		if charges==0 then
-- 		end
-- 	else
-- 		cd = (cd-game.time)/cdt*100-10
-- 		textwall (msg.game[17],false,{[1] = draw_pc(cd)})
-- 	end
-- end,

-- oninfo = function (x,y)
-- 	local cd = readmap (x,y,'cd') or game.time
-- 	local cdt = time.d*2
-- 	local charges = readmap (x,y,'charges') or 7


-- 	if cd>game.time then
-- 		cd = (cd-game.time)/cdt*100-10
-- 		return message (msg.game[17],{[1] = draw_pc(cd)})

-- 	else
-- 		return message (msg.game[32],{[1] = charges})
-- 	end
-- end,

-- t_speed = 100,
-- t_cap = 40000
-- }


stone[50] = { name = 'Pyrite heater',
col = 0,
solid = 1,
fall = {0,1},
z = 1,
slide = 0.1,
gather = {dig = 0},
digtime = 2,
digtoinv = 0,
digtoid = 50,
spr = img_load("brick38.png"),
light = {24,0.4,0.4,0.1},
onuse = function (x,y)

		local i = inv_find (36)

		if i then
			inv_remove(i)
			local de = readmap (x,y,'de') or 0
			local tp = readmap (x,y,'tp') or 0
			

			writemap (x,y,de+50,'de')
			writemap (x,y,tp+20000,'tp')
		else
			textwall (msg.stone[50].txt[1])
		end

end,


t_speed = 100,
t_cap = 20000
}


stone[156] = { name = 'Depleted heater',
col = 0,
solid = 1,
fall = {0,1},
z = 1,
slide = 0.1,
gather = {dig = 0},
digtime = 2,
digtoinv = 0,
digtoid = 156,
spr = img_load("brick89.png"),
t_speed = 100,
t_cap = 40000
}

stone[158] = { name = 'Comal',
unstack = 1,
col = 0,
solid = 1,
fall = {0,1},
z = 1,
slide = 0.1,
gather = {dig = 0},
digtime = 2,
digtoinv = 0,
digtoid = 158,
spr = img_load("brick90.png"),
t_speed = 100,
t_cap = 4000,

onheat = function (x,y,tile,map) 
	item_firing (x,y,tile,map,50,5,159) --temp,time,to 
end,

}

stone[159] = { name = 'Comal (hot)',
unstack = 1,
ttl = time.h*4,	
die = 158,
col = 0,
solid = 1,
fall = {0,1},
z = 1,
slide = 0.1,
gather = {dig = 0},
digtime = 20,
digtoinv = 0,
digtoid = 158,
spr = img_load("brick91.png"),
t_speed = 5,
t_cap = 40000,

onuse = function (x,y)
	achi_done (37)
	craft_reset ()
	craft.multitem = true
	craft.reqblock = 159
	craft_itemsget ()
	craft_str ()
	if craft.str~="" then
		game.craft = true
	else
		textwall (msg.game[29])
	end
end,

}



stone[18] = { name = 'Water',
col = 0,
solid = 0,
dpr = 0,
z = 1,
die = 0,
ttl = 32,
--spr = img_load("brick11.png"),
spr = img_load("empty.png"),
ondie = function (x,y)
	writemap (x,y,love.math.random (9000,10000),'w')
	writemap (x,y,love.math.random (50,100),'dr')
end,
}

stone[120] = { name = 'Much water',
col = 0,
solid = 0,
dpr = 0,
z = 1,
die = 120,
ttl = 32,
--spr = img_load("brick12.png"),
spr = img_load("empty.png"),

ondie = function (x,y)
	local w = readmap (x,y,'w') or 0
	local cnt = readmap (x,y,'cnt') or 0

	if w==10000 then 
		writemap (x,y,144)
		writemap (x,y,1,'f')
		return 
	end

	if w<9000 then
		cnt = cnt + 1
		writemap (x,y,love.math.random(50,100),'dr')
		writemap (x,y,10000,'w')
		writemap (x,y,cnt,'cnt')
		writemap (x,y,120)
	else
		--writemap (x,y,144)
	end

	if cnt>25 then
		writemap (x,y,144)
		writemap (x,y,1,'f')
	end
end
}

stone[19] = { name = 'Salt',
cr = 1,
gather = {pierce = 2},
digtime = 5, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 20, 
digtoinv = 0,

col = 1,
br = 1,
solid = 1,
z = 1,
die = 0,
spr = img_load("brick9.png"),
ondug = function (x,y)
	writemap (x,y,20)
	return 20
end
}


stone[20] = { name = 'A heap of salt',
fall = {0,1},
col = 0,
solid = 0,
z = 1,
gather = {dig = 0},
die = 0,
spr = img_load("brick10.png"),

digtime = 3, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 20, 


onuse = function (x,y)
	local left = readmap (x,y,'left') or 15
	left = left - 1
	inv_add (item_make(115))
	writemap (x,y,left,'left')
	if left<=0 then
		writemap (x,y,0)
		pl.xo = 0
	end
end

}





------------------

stone[91] = 
{
	name = 'Apple sapling',
	zindex = 1,
	unstack = 1,
	ttl = time.d,
	gather = {cut = 1}, 
	col = 0, -- collision
	climb = 0,
	solid = 1,
	dpr = 1,
	digtime = 10, -- seconds
	digtoinv = 2, -- 0 - hold or item id
	digtoid = 0, 
	spr = img_load("apple1.png"),
	die = 92,   

	ondie = function (x,y)
		writemap (x,y,92)
	end,
}

stone[92] = 
{
	name = 'Apple sapling',
	zindex = 1,
	unstack = 1,
	ttl = time.d*3,
	gather = {dig = 2}, 
	col = 0, -- collision
	climb = 0,
	solid = 1,
	dpr = 1,
	digtime = 10, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 92, 
	spr = img_load("apple2.png"),
	die = 0,   
	ondie = function (x,y)
		
		local growable = {13}
		local wt = readmap (x,y+1,'wt')

		if wt and readmap (x,y,'b') == 0 and readmap (x,y-1,'b') == 0 and has_light (x,y) and in_array (growable, readmap (x,y+1,'b'))  then
			writemap (x,y,93)
			writemap (x,y-1,94)
			writemap (x,y+1,1,'e')
			writemap (x,y+1,102)
		else
			writemap (x,y,92)
		end
	end,
}

stone[93] = 
{
	name = 'Apple',
	zindex = 1,
	ttl = time.w,
	gather = {chop = 2}, 
	col = 0, -- collision
	climb = 0,
	solid = 1,
	dpr = 1,
	digtime = 10, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 0, 
	spr = img_load("apple3.png"),
	die = 93,   
	ondig = function (x,y)
		
		if readmap (x,y-1,'b') == 94 then
			local stage = readmap (x,y-1,'stage') or 1
			if stage>1 then inv_ground_add (x,y,item_make(23)) end
			if stage>2 then inv_ground_add (x,y,item_make(23)) end
			if stage>3 then inv_ground_add (x,y,item_make(23)) end
			writemap (x,y-1,0,'clear')
		end
		
		inv_add (item_make (120)) 	
		--inv_add (item_make (120)) 	
		--inv_add (item_make (120))

		inv_ground_add (x,y,item_make(3))
		inv_ground_add (x,y,item_make(3))

		mob_create (x,y,8)

	end,

	onuse = function (x,y)
		pl.unrest = 100
		local stage = readmap (x,y-1,'stage') or 1
		textwall (msg.game[15])

		if stage>1 and love.math.random (0,100)<10 then
			mob_create (x,y,8)
		end

		if stage>1 then inv_ground_add (x,y,item_make(23)) end
		if stage>2 then inv_ground_add (x,y,item_make(23)) end
		if stage>3 then inv_ground_add (x,y,item_make(23)) end
		writemap (x,y-1,1,'stage')

	end,
}

stone[94] = { name = 'Apple crown',
col = 0, -- collision
digtime = 1, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
climb = 0,
solid = 1,
ttl = time.w,
die = 94, 
spr = img_load("apple4.png"),
sprs = {
	img_load("apple4.png"),
	img_load("apple5.png"),
	img_load("apple6.png"),
	img_load("apple7.png"),
},

ondie = function (x,y) 
	local stage = readmap (x,y,'stage') or 1
	if has_light (x,y) then --light, water
		stage = stage + 1
		if stage>4 then stage = 4 end
		writemap (x,y,stage,'stage')
	end
end, 

ondraw = function (x,y,wx,wy)
	local stage = readmap (wx,wy,'stage') or 1
	love.graphics.draw (quad, stone[94].sprs[stage],x-12,y,0,2,2)
end,

}


stone[95] = { name = 'Spiny',
	fall = {0,1},
	--gather = {chop = 2}, 
	gather = {chop = 1}, 
	col = 0, -- collision
	solid = 0,
	digtime = 7, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 0, 
	spr = img_load("brick48.png"),
	onstay = function (x,y)
		player_hit (1,'arms')
	end,
	onstep = function (x,y)
		--textwall (msg.game[16])
		player_hit (1)
	end,
	ondig = function (x,y)
		inv_add (item_make(96)) --spike
		inv_add (item_make(15)) --twig
		if love.math.random (0,100)<5 then
			inv_add (item_make(174)) --nut
		end
	end,
	onheat = function (x,y,tile,map) 
		if readmap (x-1,y,'b')==55 or readmap (x+1,y,'b')==55 then
			inv_ground_add (x,y,item_make(15))
			inv_ground_add (x,y,item_make(96))
			writemap (x,y,55)
			local max = math.max (readmap(x-1,y,'max') or 0, readmap(x+1,y,'max') or 0)
			writemap (x,y,max,'max')
		end
	end,
}



stone[96] = { name = 'Bean',
gather = {dig = 0}, 
fall = {1,0},
col = 0, -- collision
solid = 0,
digtime = 2, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
loot = {{i=7,p=20},{i=98,p=1}},
ttl = time.d*3,
spr = img_load("bean3.png"),
die = 0,            
ondie = function (x,y)
	inv_ground_add (x,y,item_make (7))
end,
onfell = function (x,y)
	writemap (x,y,0)
	inv_ground_add(x,y, item_make (7))
end,   --      --  
}


stone[172] = { name = 'Bean top',
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
climb = 1,
fall = {0,1},
onfell = function (x,y)
	writemap (x,y,0)
	inv_ground_add(x,y, item_make (3))
end,   --      --  
digtime = 10, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 
die = 172,
ttl = time.h*8,
spr = img_load("bean5.png"),
ondie = function (x,y)

	writemap (x,y,nil,'problem')

	local ys = y + 1
	local l = 0
	local cnt = 0

	
	for i = 1,33 do
		r = readmap (x,y+i,'b')
		if r==97 or r==98 then
			l = l + (has_light (x,y+i) or 0)
			cnt = cnt + 1
		else
			break
		end
	end

	l = l / cnt

	if cnt>=32 then
		writemap (x,y,9,'problem')
		return
	end

	if l<1 then
		writemap (x,y,4,'problem')
		return
	end


	writemap (x,y,nil,'problem')

	if growup (x,y,172) then

		if (x+y)%5 == 1 then
			writemap (x,y,98) --w beans
			writemap (x,y,1,'magic')
		else
			
			if love.math.random (0,100)<50 then
				writemap (x,y,97)
			else
				writemap (x,y,173)
			end
			

		end

	end

end
}

stone[97] = { name = 'Bean vine',
zindex = 1,
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
climb = 1,
fall = {0,1},
onfell = function (x,y)
	writemap (x,y,0)
	inv_ground_add(x,y, item_make (3))
end,   --    
ondestroy = function (x,y,z)
	inv_ground_add(x,y, item_make (3))
	return z
end,   --  
digtime = 10, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 
die = 173,
ttl = time.h*3,
spr = img_load("bean1.png"),
}


stone[173] = { name = 'Bean vine', --variation
zindex = 1,
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
climb = 1,
fall = {0,1},
onfell = function (x,y)
	writemap (x,y,0)
	inv_ground_add(x,y, item_make (3))
end,   --    
ondestroy = function (x,y,z)
	inv_ground_add(x,y, item_make (3))
	return z
end,   --  
digtime = 10, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 
die = 97,
ttl = time.h*2,
spr = img_load("bean6.png"),
}


stone[98] = { name = 'Bean vine', --with beans (magic)
zindex = 1,

gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
climb = 1,
fall = {0,1},
onfell = function (x,y)
	writemap (x,y,0)
	--inv_ground_add(x,y, item_make (3))
end,   --    
ondestroy = function (x,y,z)
	if love.math.random (0,100)<50 then inv_ground_add(x,y, item_make (3)) end
	return z
end,   --  
digtime = 10, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 
die = 98,
ttl = time.d,
spr = img_load("bean2.png"),
ondie = function (x,y)
	
	if in_array ({102,1,2,12,13}, readmap (x,y+1,'b'))  then --groundunder
		fertilize (x,y+1,3)
	end

	local ttl = readmap (x,y,'ttl') or 4
	local b = readmap (x-1,y,'b')


	if (b==0 or b==36 or b==37) and not has_light (x,y) then
		writemap (x,y,4,'problem')
		return
	end

	if (b~=0 and b~=36 and b~=37 and b~=96) and has_light (x,y) then
		writemap (x,y,8,'problem')
		return
	end

	if (b==0 or b==36 or b==37) and has_light (x,y) then

		ttl = ttl - 1
		writemap (x,y,ttl,'ttl')

		if ttl>0 then	
			writemap (x-1,y,96)
			writemap (x,y,nil,'problem')
		else
			writemap (x,y,97)
		end

	end


end
}


stone[179] = { name = 'Bean vine', --with beans (normal)
zindex = 1,
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
climb = 0,
fall = {0,1},
onfell = function (x,y)
	writemap (x,y,0)
	--inv_ground_add(x,y, item_make (3))
end,   --    
ondestroy = function (x,y,z)
	if love.math.random (0,100)<50 then inv_ground_add(x,y, item_make (3)) end
	return z
end,   --  
digtime = 10, -- seconds
digtoinv = 3, -- 0 - hold or item id
digtoid = 0, 
die = 179,
ttl = time.d,
spr = img_load("bean2.png"),
ondie = function (x,y)
	
	if in_array ({102,1,2,12,13}, readmap (x,y+1,'b'))  then --groundunder
		fertilize (x,y+1,3)
	end

	local ttl = readmap (x,y,'ttl') or 4
	local b = readmap (x-1,y,'b')


	if (b==0 or b==36 or b==37) and not has_light (x,y) then
		writemap (x,y,4,'problem')
		return
	end

	if (b~=0 and b~=36 and b~=37 and b~=96) and has_light (x,y) then
		writemap (x,y,8,'problem')
		return
	end

	if (b==0 or b==36 or b==37) and has_light (x,y) then

		ttl = ttl - 1
		writemap (x,y,ttl,'ttl')

		if ttl>0 then	
			writemap (x-1,y,96)
			writemap (x,y,nil,'problem')
		else
			writemap (x,y,182)
		end

	end


end
}


stone[182] = { name = 'Dead beans', --with beans (normal)
zindex = 1,
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
climb = 0,
fall = {0,1},
onfell = function (x,y)
	writemap (x,y,0)
	--inv_ground_add(x,y, item_make (3))
end,   --    
ondestroy = function (x,y,z)
	inv_ground_add(x,y, item_make (37))
	return z
end,   --  
digtime = 5, -- seconds
digtoinv = 37, -- 0 - hold or item id
digtoid = 0, 
die = 182,
ttl = time.d,
spr = img_load("bean4.png"),

}


stone[184] = { name = 'Power loom',
unstack = 1,
fall = {0,1},
gather = {dig = 0}, 
digtime = 1,
digtoid = 184,
col = 0, -- collision
solid = 0,
climb = 0,
die = 184,
ttl = time.d,
spr = img_load("brick99.png"),

onuse = function (x,y)
	achi_done (40)
	craft_reset ()
	craft.multitem = true
	craft.reqblock = 184
	craft_itemsget ()
	craft_str ()
	if craft.str~="" then
		game.craft = true
	else
		textwall (msg.game[29])
	end
end,

}


stone[24] = 
{
	name = 'Firewood sapling',
	ttl = time.d*5,
	gather = {dig = 0}, 
	col = 0, -- collision
	climb = 0,
	solid = 1,
	dpr = 1,
	digtime = 1, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 24, 
	spr = img_load("brick17.png"),
	die = 0,   
	ondestroy = function (x,y,z) 	
		return 24,z
	end,
	ondie = function (x,y)
		local b = readmap (x,y+1,'b')
		--if b==102 or b==12 or b == 13 then
			if readmap (x,y,'b') == 0 and readmap (x,y-1,'b') == 0 then
				writemap (x,y,25)
				writemap (x,y-1,27)
				writemap (x,y+1,21)
			end
		--end
	end,
	light = {24,0.8,0.3,0.3}
}

stone[21] = { name = 'Roots',
cr = 1,
ttl = time.d,
gather = {chop = 2}, 
col = 1, -- collision
solid = 1,
digtime = 20, -- seconds
digtoinv = 108, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("brick13.png"),
die = 21,            
ondie = function (x,y) 
local g = {
{0,1},{-1,1},{1,1},
{0,2},{-1,2},{1,2},{2,2},{-2,2},
{0,3},{-1,3},{1,3},{2,3},{-2,3},
{0,4},{-1,4},{1,4},{3,4},{-3,4},
{0,5}
}

if readmap (x,y-1,'b') == 0  then
	grow (x,y,21,22)
	for i,v in ipairs(g) do
		grow (x+v[1],y+v[2],30,22)
	end

end

for i,v in ipairs(g) do
	if grow (x+v[1],y+v[2],1,30) or grow (x+v[1],y+v[2],2,30) or 
	grow (x+v[1],y+v[2],31,30) or grow (x+v[1],y+v[2],102,30) or
	grow (x+v[1],y+v[2],9,30) or grow (x+v[1],y+v[2],8,30)
	then 
		return true 
	end
end


end    
}


stone[180] = { name = 'Dirty filter',
	gather = {dig = 0}, 
	col = 1, -- collision
	solid = 1,
	digtime = 1, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 181, 
	spr = img_load("brick96.png"),
}

-- robot body
-- clay x 2
-- ash
-- lime
-- sand

stone[181] = { name = 'Filter',
	cr = 1,
	noinv = 1,
	gather = {dig = 2}, 
	col = 1, -- collision
	solid = 1,
	digtime = 1, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 181, 
	spr = img_load("brick97.png"),
	ttl = time.min,
	die = 181,
	ondie = function (x,y)
		local w = readmap (x,y-1,'w') or 0
		local w2 = math.floor (w * 0.1)
		local w3 = readmap (x,y+1,'w') or 0
		local dr = readmap (x,y-1,'dr') or 0
		local thisdr = readmap (x,y,'drt') or 0

		if w2>10 and w3<(10000-w2) then
			writemap (x,y-1,w-w2,'w')
			w3 = w3 + w2
			writemap (x,y+1,w3,'w')

			dr = dr * (w2 / 10000)
			thisdr = thisdr + dr

			--print (thisdr)
			writemap (x,y,thisdr,'drt')

		end

	end,
}

stone[30] = { name = 'Roots',
	cr = 1,
	gather = {chop = 2}, 
	col = 1, -- collision
	solid = 1,
	digtime = 20, -- seconds
	digtoinv = 108, -- 0 - hold or item id
	digtoid = 0, 
	spr = img_load("brick14.png"),
}

stone[22] = { name = 'Dying roots',
	ttl = time.w,
	gather = {chop = 3}, 
	col = 1, -- collision
	solid = 1,
	digtime = 20, -- seconds
	digtoinv = 108, -- 0 - hold or item id
	digtoid = 0, 
	
	spr = img_load("brick14.png"),
	die = 23,              
}

stone[23] = { name = 'Dry roots',
	coby = 1,
	gather = {chop = 3}, 
	col = 0, -- collision
	solid = 1,
	climb = 1,
	digtime = 1, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 23, 
	
	spr = img_load("brick15.png"),
	die = 0,   
	ondestroy = function (x,y,z) 
	return z,23
	end,

	onfalling =  function (x,y)
	
	if maptile (x+1,y,'col')~=0 or maptile (x-1,y,'col')~=0 or
		maptile (x,y-1,'col')~=0 then
			writemap (x,y,nil,'f')
	end

	if readmap (x+1,y,'b')==23 or readmap (x-1,y,'b')==23 or
		readmap (x,y-1,'b')==23 then
			writemap (x,y,nil,'f')
	end
	
	
	end,
}

stone[129] = { name = 'Bone ladder',
	gather = {dig = 0}, 
	col = 0, -- collision
	solid = 1,
	climb = 1,
	digtime = 1, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 129, 
	
	spr = img_load("brick70.png"),
	die = 0,

	ondig = function (x,y)

		local s = 0

		while readmap (x,y+s,'b')==129 do
			s = s - 1
		end 

		for i=y+s,y+s+4 do
			if readmap (x,i,'b')==129 then
				writemap (x,i,0)
			end
		end

		pl.iscarry = createblock (129)
		pl.digcount = -1 
		return false

	
	end,   

	onfell = function (x,y)
		for i=1,3 do

			if readmap (x,y-i,'b')==0 then
				writemap (x,y-i,129)
			else
				break
			end
		end
	end

}




stone[130] = { name = 'Wooden ladder',
	gather = {dig = 0}, 
	col = 0, -- collision
	solid = 1,
	climb = 1,
	digtime = 1, -- seconds
	digtoinv = 0, -- 0 - hold or item id
	digtoid = 130, 
	
	spr = img_load("brick71.png"),
	die = 0,

	ondig = function (x,y)

		local s = 0

		while readmap (x,y+s,'b')==130 do
			s = s - 1
		end 

		for i=y+s,y+s+5 do
			if readmap (x,i,'b')==130 then
				writemap (x,i,0)
			end
		end

		pl.iscarry = createblock (130)
		pl.digcount = -1 
		return false
	
	end,   

	onfell = function (x,y)
		for i=1,4 do

			if readmap (x,y-i,'b')==0 then
				writemap (x,y-i,130)
			else
				break
			end
		end
	end

}



stone[25] = 
{
	name = 'Firewood',
	gather = {chop = 1}, 
	col = 0, -- collision
	solid = 1,
	fall = {0,1},
	climb = 0,
	digtime = 10, -- seconds
	digtoinv = 43, -- 0 - hold or item id
	digtoid = 0, 
	
	spr = img_load("brick18.png"),
	die = 0,   
	ondestroy = function (x,y,z) 	
		return 25,z
	end
}

stone[26] = 
{
	name = 'Firewood',
	fall = {0,1},
	gather = {chop = 1}, 
	col = 0, -- collision
	solid = 1,
	climb = 0,
	digtime = 10, -- seconds
	digtoinv = 43, -- 0 - hold or item id
	digtoid = 0, 
	
	spr = img_load("brick19.png"),
	die = 0,   
	ondestroy = function (x,y,z) 	
		return 26,z
	end
}




stone[27] = 
{
	name = 'Firewood crown',
	--unstack = 1,
	ttl = time.w,
	fall = {0,1},
	gather = {chop = 1}, 
	col = 0, -- collision
	solid = 1,
	climb = 1,
	digtime = 1, -- seconds
	digtoinv = 25, -- 0 - hold or item id
	loot = {{i=25,p=1}}, 
	digtoid = 0, 
	spr = img_load("brick20.png"),
	die = 27,   
	ondestroy = function (x,y,z) 	
		return 27,z
	end,
	ondie = function (x,y)
		
		if readmap (x,y-1,'b') == 0 and readmap (x,y+4+x%3,'b')~=25 and not lookaround(x,y,{27},1) then

			local g
			local l = readmap (x,y+1,'b') 

			if l==29 then writemap (x,y,28) g = true end
			if l==28 then writemap (x,y,29) g = true end

			if l==26 or l==25 then
				if x%3 == 1 then
					g = true 
					writemap (x,y,28)
				else
					g = true 
					writemap (x,y,29)
				end
			end

			--writemap (x,y,26)
			if g then
				writemap (x,y-1,27)
			end

		end
	end,

	light = {32,0.7,0.3,0.3}

}

stone[28] = 
{
	name = 'Firewood',
	fall = {0,1},
	gather = {chop = 1}, 
	col = 0, -- collision
	solid = 1,
	climb = 0,
	digtime = 10, -- seconds
	digtoinv = 43, -- 0 - hold or item id
	digtoid = 0, 
	
	spr = img_load("brick21.png"),
	die = 0,   
	ondestroy = function (x,y,z)
		inv_ground_add(x,y, item_make (2)) 	
		return 26,z
	end,
	ondig = function ()
		inv_add (item_make(2))
	end
}

stone[29] = 
{
	name = 'Firewood',
	fall = {0,1},
	gather = {chop = 1}, 
	col = 0, -- collision
	solid = 1,
	climb = 0,
	digtime = 10, -- seconds
	digtoinv = 43, -- 0 - hold or item id
	digtoid = 0, 
	
	spr = img_load("brick22.png"),
	die = 0,   
	ondestroy = function (x,y,z) 	
		inv_ground_add(x,y, item_make (2))
		return 26,z
	end,
	ondig = function ()
		inv_add (item_make(2))
	end
}

stone[178] = { name = 'Web sack',
ttl = time.d*5,
die = 0,
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
digtime = 5, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("web_c.png"),
ondig = function ()
	mob_hostile ('spider')
	inv_add (item_make(275))
	inv_add (item_make(90))
end,
ondie = function (x,y)
	
	if mob_search (x,y,30,2)<3 then --overpopulation
		mob_create (x,y-2,2)
	else
		writemap (x,y,178)
	end
	
end,
ondraw = function (x,y,wx,wy)
	love.graphics.setColor (1,1,1,0.75)
	love.graphics.draw (quad, stone[178].spr,x,y,0,2,2)
	love.graphics.setColor (1,1,1,1)
end
}

stone[85] = { name = 'Web',
ttl = time.d,
die = 0,
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
digtime = 5, -- seconds
digtoinv = 0, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("web.png"),
ondig = function ()
	mob_hostile ('spider')
	inv_add (item_make(104))
end,
ondraw = function (x,y,wx,wy)
	love.graphics.setColor (1,1,1,0.3)
	love.graphics.draw (quad, stone[85].spr,x,y,0,2,2)
	love.graphics.setColor (1,1,1,1)
end
}

stone[86] = { name = 'Webstring',
climb = 1,
ttl = time.min*3,
die = 0,
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
digtime = 2, -- seconds
digtoinv = 90, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("webstring.png"),
ondig = function (x,y)
	
	local w = y-1
	while readmap (x,w,'b')==86 do
		writemap (x,w,0)
		w = w - 1
	end

	local w = y+1
	while readmap (x,w,'b')==86 or readmap (x,w,'b')==87 do
		writemap (x,w,0)
		w = w + 1
	end

end,

ondraw = function (x,y,wx,wy)
	love.graphics.setColor (1,1,1,0.3)
	love.graphics.draw (quad, stone[86].spr,x,y,0,2,2)
	love.graphics.setColor (1,1,1,1)
end
}

stone[87] = { name = 'Webstring',
ttl = time.min*3,
die = 0,
gather = {cut = 1}, 
col = 0, -- collision
solid = 0,
digtime = 2, -- seconds
digtoinv = 90, -- 0 - hold or item id
digtoid = 0, 
spr = img_load("webstring2.png"),

ondraw = function (x,y,wx,wy)
	love.graphics.setColor (1,1,1,0.3)
	love.graphics.draw (quad, stone[87].spr,x,y,0,2,2)
	love.graphics.setColor (1,1,1,1)
end,

ondig = function (x,y)
	
	local w = y-1
	while readmap (x,w,'b')==86 do
		writemap (x,w,0)
		w = w - 1
	end

	local w = y+1
	while readmap (x,w,'b')==86 or readmap (x,w,'b')==87 do
		writemap (x,w,0)
		w = w + 1
	end

end,

}



--30

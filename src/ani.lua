
	

	-- animation load
	------------------------------------------------------

	function grload (name)
		for i=1,gr[name]['cnt'] do
			local name2 = name
			table.insert(gr[name]['spr'], img_load(name2 .. i .. ".png"))
		end
	end

	function pl_state (name, force, actor)
		actor = ActorState.ensure(actor or pl)
		if gr[name].unbr==nil or force then
			actor.oldstate = actor.state
			actor.state = name
			ActorState.reset_animation(actor, nil, { preserve_reverse = true })
			return true
		end
	end

	function pl_getstate (name, actor)
		actor = actor or pl
		return gr[actor.state][name]
	end

	gr = {}

	gr.walk = {}
	gr.walk.spr = {}
	gr.walk.cnt = 12
	gr.walk.dur = {7,7,7,7,7,7,7,7,7,7,7,7}
	gr.walk.ani = {2,3,4,5,6,7,8,9,10,11,12,1} -- reverse, jump, ?
	--gr.walk.ani = {2,3,4,5,6,7,8,9,10,1} -- reverse, jump, ?
	grload ('walk')

	gr.ave = {}
	gr.ave.spr = {}
	gr.ave.cnt = 9
	gr.ave.dur = {30,20,20,20,20,40,300,20,20}
	gr.ave.ani = {2,3,4,5,6,7,8,9,'idle'} -- reverse, jump, ?
	--gr.walk.ani = {2,3,4,5,6,7,8,9,10,1} -- reverse, jump, ?
	grload ('ave')

	gr.fishing = {}
	gr.fishing.spr = {}
	gr.fishing.cnt = 2
	gr.fishing.dur = {200,200}
	gr.fishing.ani = {2,1} -- reverse, jump, ?
	--gr.walk.ani = {2,3,4,5,6,7,8,9,10,1} -- reverse, jump, ?
	grload ('fishing')


	gr.walk_carry = {}
	gr.walk_carry.spr = {}
	gr.walk_carry.cnt = 12
	gr.walk_carry.dur = {10,10,10,10,10,10,10,10,10,10,10,10}
	gr.walk_carry.ani = {2,3,4,5,6,7,8,9,10,11,12,1} -- reverse, jump, ?


	gr.walk_carry.stoneadd = 
	{
		[3] = {-2,0},
		[4] = {-2,2},
		[5] = {-2,2},
		[6] = {0,2},

		[10] = {2,2},
		[11] = {2,2},
		[12] = {2,2},
	}

	grload ('walk_carry')


	gr.zzz = {}
	gr.zzz.spr = {}
	gr.zzz.cnt = 2
	gr.zzz.dur = {100,100,150,150}
	gr.zzz.ani = {2,1} -- reverse, jump, ?

	
	grload ('zzz')

	gr.idle = {}
	gr.idle.spr = {}
	gr.idle.cnt = 4
	gr.idle.dur = {150,150,150,150}
	gr.idle.ani = {2,3,4,5} -- reverse, jump, ?

	gr.idle.add = 
	{
		[2] = {1,0},
		[4] = {-1,0},
	}
	
	grload ('idle')



	gr.headup = {}
	gr.headup.spr = {}
	gr.headup.cnt = 2
	gr.headup.dur = {150,150}
	gr.headup.ani = {2,1} -- reverse, jump, ?

	grload ('headup')

	gr.headdown = {}
	gr.headdown.spr = {}
	gr.headdown.cnt = 2
	gr.headdown.dur = {150,150}
	gr.headdown.ani = {2,1} -- reverse, jump, ?

	grload ('headdown')

	gr.buttscratch = {}
	gr.buttscratch.spr = {}
	gr.buttscratch.cnt = 11
	gr.buttscratch.dur = {20,20,20,20,20,20,20,150,10,10,10}
	gr.buttscratch.ani = {2,3,4,5,6,7,8,9,10,11,'idle'} -- reverse, jump, ?

	gr.buttscratch.add = 
	{
		[2] = {-1,0},
		[3] = {1,0},
		[4] = {-1,0},
		[5] = {1,0},
		[6] = {-1,0},
		[7] = {1,0},
		
		

	}
	
	grload ('buttscratch')


	gr.hang = {}
	gr.hang.nofall = 1
	gr.hang.spr = {}
	gr.hang.cnt = 3
	gr.hang.dur = {10,100,100}
	gr.hang.ani = {2,3,2,3} -- reverse, jump, ?
	grload ('hang')

	gr.stepup = {}
	gr.stepup.nofall = 1
	gr.stepup.spr = {}
	gr.stepup.cnt = 4
	gr.stepup.dur = {10,10,10,10,10}
	gr.stepup.ani = {2,3,4,'walk'} -- reverse, jump, ?
	gr.stepup.exitfr = 6

	gr.stepup.add = 
	{
		[1] = {3,-12},
		[2] = {3,-12},
		[3] = {7,-10},
		[4] = {7,-10},
				
	}

	gr.stepup.reversable = 1

	grload ('stepup')


	gr.stepupb = {}
	gr.stepupb.nofall = 1
	gr.stepupb.spr = {}
	gr.stepupb.cnt = 4
	gr.stepupb.dur = {10,10,10,10,10}
	gr.stepupb.ani = {2,3,4,'walk'} -- reverse, jump, ?
	gr.stepupb.exitfr = 12

	gr.stepupb.add = 
	{
		[1] = {3,-12},
		[2] = {3,-12},
		[3] = {7,-10},
		[4] = {10,-10},
	}

	gr.stepup.reversable = 1

	grload ('stepupb')


	gr.pullup = {}
	gr.pullup.nofall = 1
	gr.pullup.spr = {}
	gr.pullup.cnt = 6
	gr.pullup.dur = {10,10,10,10,10,10,10}
	--gr.pullup.dur = {50,50,50,50,50,50}
	gr.pullup.exitfr = 8
	gr.pullup.reversable = 1



	gr.pullup.ani = {2,3,4,5,6,'walk'} -- reverse, jump, ?

	gr.pullup.add = 
	{
		[2] = {0,-12},
		[3] = {7,-10},
		[4] = {7,-14},
		[5] = {10,-20},
		[6] = {0,0},
		[7] = {0,0},


	}

	grload ('pullup')


	gr.climb = {}
	gr.climb.spr = {}
	gr.climb.cnt = 8
	gr.climb.dur = {10,10,10,10,10,10,10,10}
	gr.climb.ani = {2,3,4,5,6,7,8,1} -- reverse, jump, ?

	gr.climb.stoneadd = 
	{
		[2] = {0,-2},
		[3] = {0,-3},
		[4] = {0,-2},

		[6] = {0,2},
		[7] = {0,3},
		[8] = {0,2},
	}

	--gr.climb.z = 1
	grload ('climb')

	gr.idle_carry = {}
	gr.idle_carry.spr = {}
	gr.idle_carry.cnt = 4
	gr.idle_carry.dur = {50,50,50,50}
	gr.idle_carry.ani = {2,3,4,5} -- reverse, jump, ?
	grload ('idle_carry')


	gr.flex = {}
	gr.flex.spr = {}
	gr.flex.cnt = 16
	gr.flex.dur = {10,10,10,10,100,10,10,10,10,10,10,10,50,40,100,10,10}
	gr.flex.ani = {2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,'idle_carry'} -- reverse, jump, ?

	gr.flex.stoneadd = 
	{
		[1] = {0,-2},
		[2] = {0,-7},
		[3] = {0,-15},
		[4] = {0,-5},
	}

	grload ('flex')


	gr.jump = {}
	gr.jump.spr = {}
	gr.jump.cnt = 3
	gr.jump.dur = {10,10,100,100}
	gr.jump.ani = {2,3,4,3} -- reverse, jump, ?
	grload ('jump')

	gr.jump_carry = {}
	gr.jump_carry.spr = {}
	gr.jump_carry.cnt = 3
	gr.jump_carry.dur = {10,10,100,100}
	gr.jump_carry.ani = {2,3,4,3} -- reverse, jump, ?
	grload ('jump_carry')

	gr.fall = {}
	gr.fall.spr = {}
	gr.fall.cnt = 3
	gr.fall.dur = {10,10,50}
	gr.fall.ani = {2,3,2} -- reverse, jump, ?
	grload ('fall')

	gr.fall_carry = {}
	gr.fall_carry.spr = {}
	gr.fall_carry.cnt = 3
	gr.fall_carry.dur = {10,10,50}
	gr.fall_carry.ani = {2,3,2} -- reverse, jump, ?

	gr.fall_carry.stoneadd = 
	{
		[1] = {3,-2},
		[2] = {5,-4},
		[3] = {6,-4},
		[4] = {4,-2},
	}

	grload ('fall_carry')

	gr.dying = {}
	gr.dying.spr = {}
	gr.dying.cnt = 10
	gr.dying.dur = {20,15,15,15,100,20,20,40,100000,100000}
	gr.dying.ani = {2,3,4,5,6,7,8,9,10} -- reverse, jump, ?

	gr.dying.add = 
	{
		[6] = {8,0},
		[7] = {2,0},
		[8] = {2,0},
		[9] = {0,0},
	}


	grload ('dying')

	
	gr.dig = {}
	gr.dig.spr = {}
	gr.dig.cnt = 7
	gr.dig.dur = {10,10,10,20,20,20,20}
	gr.dig.ani = {2,3,4,5,6,7,4} -- reverse, jump, ?

	gr.dig.add = 
	{
	--	[2] = {3,0},
	--	[3] = {3,0},
		[4] = {1,0},
		[5] = {1,0},
		[6] = {-1,0},
		[7] = {-1,0},
	}


	grload ('dig')

	gr.pick = gr.dig

	gr.kick = {}
	gr.kick.spr = {}
	gr.kick.cnt = 14
	gr.kick.dur = {30,15,15,10,10,15,10,10, 10,10,10,10,07,07}
	gr.kick.ani = {2,3,4,5,6,7, 8,9,10, 11, 12, 13, 14, 2, 2, 12,13,14, 2} -- reverse, jump, ?

	gr.kick.add = 
	{
		[5] = {4,0},
		[10] = {4,0},
		[14] = {4,0},

	}

	grload ('kick')


	-- gr.kick_down = {}
	-- gr.kick_down.spr = {}
	-- gr.kick_down.cnt = 7
	-- gr.kick_down.dur = {7,20,15,10,10,15,10,10}
	-- gr.kick_down.ani = {2,3,4,5,6,7,2} -- reverse, jump, ?
	-- grload ('kick_down')

	-- gr.kick = gr.kick_down



	ani = {}


	ani.assplode = {}
	ani.assplode.walk =
	{
		spt = 	{ 
					img_load("assplosion1.png"),
					img_load("assplosion2.png"),
					img_load("assplosion3.png"),
					img_load("assplosion4.png"),
					img_load("assplosion5.png"),
					img_load("assplosion6.png"),
					img_load("assplosion6.png"),
				},
		cnt = 7,
		time = {0.1, 0.1, 0.1, 0.1, 0.15, 0.20, 666},
		rep = 1,
		exit = 'walk',
		xoff = 0,
		yoff = 0,
		unbr = 1,
		uncont = 1,
		light = {120,1,1,1},
	}


	ani.start = {}
	ani.start.walk =
	{
		spt = 	{ 
					img_load("beam20.png"), 
				},
		cnt = 1,
		time = {1},
		rep = 1,
		exit = '',
		xoff = 0,
		yoff = 0,
	}

	ani.start.born =
	{
		spt = 	{ 
					img_load("beam1.png"), 
					img_load("beam2.png"), 
					img_load("beam3.png"), 
					img_load("beam4.png"), 
					img_load("beam5.png"), 
					img_load("beam6.png"),
					img_load("beam7.png"),
					img_load("beam6.png"),
					img_load("beam7.png"),
					img_load("beam6.png"),
					img_load("beam7.png"),
					img_load("beam8.png"),
					img_load("beam9.png"),
					img_load("beam10.png"),
					img_load("beam11.png"),
					img_load("beam12.png"),
					img_load("beam13.png"),
					img_load("beam14.png"),
					img_load("beam15.png"),
					img_load("beam16.png"),
					img_load("beam17.png"),
					img_load("beam18.png"),
					img_load("beam19.png"),
					img_load("beam20.png"),
				},
		cnt = 24,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 
		0.3, 0.3, 0.3, 0.3, 0.3, 0.3,
		0.1, 0.1,  0.1, 0.12,
		0.15, 0.12, 0.11, 0.12, 0.11, 1.2, 0.2, 0.2},
		rep = 0,
		exit = 'walk',
		xoff = 0,
		yoff = 0,
		unbr = 1,
		uncont = 1
	}

	ani.start.transform =
	{
		spt = 	{ 
					img_load("analyzebeam1.png"), 
					img_load("analyzebeam2.png"), 
					img_load("analyzebeam3.png"), 
					img_load("analyzebeam4.png"), 
					img_load("analyzebeam5.png"),
					img_load("analyzebeam6.png"),
				},
		cnt = 6,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1,},
		rep = 1,
		exit = '',
		xoff = 0,
		yoff = 0,
	}


	ani.start.analyze =
	{
		spt = 	{ 
					img_load("greenbeam1.png"), 
					img_load("greenbeam2.png"), 
					img_load("greenbeam3.png"), 
					img_load("greenbeam4.png"), 
					img_load("greenbeam5.png"),
					img_load("greenbeam6.png"),
				},
		cnt = 6,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1,},
		rep = 1,
		exit = '',
		xoff = 0,
		yoff = 0,
	}


	ani.invader = {}

	ani.invader.walk =
	{
		spt = 	{ 
					img_load("invader1.png"), 
					img_load("invader2.png")
				},
		cnt = 2,
		time = {0.5,0.5},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 0,
		yoff = 0,
	}

	ani.invader.die =
	{
		spt = 	{ 
					img_load("invader3.png"), 
					img_load("invader4.png"),
					img_load("invader5.png")
				},
		cnt = 3,
		time = {0.3,0.3,0.3},
		rep = 1,
		exit = '',
		--unbr = 1,
		uncont = 1,
		xoff = 0,
		yoff = 0,
	}


	ani.slime = {}

	ani.slime.walk =
	{
		spt = 	{ 
					img_load("igle1.png"), 
					img_load("igle2.png"),
					img_load("igle18.png"),
					img_load("igle2.png"),
				},


		cnt = 4,
		time = {0.33,0.33,0.33, 0.3},

		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 9,
		yoff = 15,
	}

	ani.slime.sleep =
	{
		spt = 	{ 
					img_load("igle3.png"), 
					img_load("igle4.png")
				},
		cnt = 2,
		time = {1,1.5},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 15,
	}

	ani.slime.attack =
	{
		spt = 	{ 
					img_load("igle5.png"), 
					img_load("igle6.png"),
					img_load("igle7.png"),
					img_load("igle19.png"),
					img_load("igle8.png"),
					img_load("igle9.png"),
					img_load("igle10.png"),
					--img_load("igle11.png")
				},
		cnt = 7,
		time = {0.2, 0.2, 0.1, 0.25, 0.2, 0.2, 0.2, 0.2},
		rep = 0,
		exit = 'walk',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 15,
	}

	ani.slime.die =
	{
		spt = 	{ 
					img_load("igle12.png"), 
					img_load("igle13.png"),
					img_load("igle14.png"),
					img_load("igle15.png"),
					img_load("igle16.png"),
				},
		cnt = 5,
		time = {0.5, 0.2, 0.3, 0.5, 6},
		rep = 2,
		exit = '',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 15,
		blink = 5
	}

	

	ani.chicken = {}

	ani.chicken.walk =
	{
		spt = 	{ 
					img_load("chicken1.png"), 
					img_load("chicken2.png"),
					img_load("chicken3.png"),
					img_load("chicken4.png"),
				},


		cnt = 4,
		time = {0.1, 0.1, 0.1, 0.1},

		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 14,
	}

	ani.chicken.eat =
	{
		spt = 	{ 
					img_load("chicken5.png"), 
					img_load("chicken6.png"),
					img_load("chicken7.png"),
					img_load("chicken8.png"),
				},
		cnt = 4,
		time = {0.1, 0.1, 0.1, 0.1},
		rep = 0,
		exit = 'walk',
		unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 14,
		norotate = 1,
	}

	ani.chicken.fly =
	{
		spt = 	{ 
					img_load("chicken9.png"), 
					img_load("chicken10.png"),
				},
		cnt = 2,
		time = {0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 14,
		norotate = 1,
	}

	ani.chicken.attack =
	{
		spt = 	{ 
					img_load("igle5.png"), 
					img_load("igle6.png"),
					img_load("igle7.png"),
					img_load("igle19.png"),
					img_load("igle8.png"),
					img_load("igle9.png"),
					img_load("igle10.png"),
					--img_load("igle11.png")
				},
		cnt = 7,
		time = {0.2, 0.2, 0.1, 0.25, 0.2, 0.2, 0.2, 0.2},
		rep = 0,
		exit = 'walk',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 14,
	}

	ani.chicken.die =
	{
		spt = 	{ 

					img_load("chicken11.png"), 
					img_load("chicken12.png"),
				},
		cnt = 2,
		time = {0.1, 0.1},
		rep = 1,
		exit = '',
		unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 14,
		blink = 5
	}


	ani.frostie = {}
	ani.frostie.walk =
	{
		spt = 	{ 
				--	img_load("crawler1.png"), 
				--	img_load("crawler2.png"),

				img_load("bolb1.png"), 
				img_load("bolb2.png"),
				img_load("bolb3.png"),
					

				},
		cnt = 3,
		time = {0.4, 0.4, 0.4},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 14
	}


	ani.frostie.attack =
	{
		spt = 	{ 
				--	img_load("crawler1.png"), 
				--	img_load("crawler2.png"),

				img_load("bolb4.png"), 
				img_load("bolb5.png"),
				img_load("bolb6.png"),

				},
		cnt = 3,
		time = {0.2, 0.2, 0.2},
		rep = 0,
		exit = 'walk',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 14
	}

	ani.frostie.die =
	{
		spt = 	{ 
				--	img_load("crawler1.png"), 
				--	img_load("crawler2.png"),

				img_load("bolb11.png"), 
				img_load("bolb12.png"),
				img_load("bolb13.png"),
				img_load("bolb14.png"),
				img_load("bolb15.png"),
				img_load("bolb16.png"),
				img_load("bolb17.png"),
				},

		cnt = 7,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 3.2},
		rep = 0,
		exit = 'walk',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 14
	}


	ani.butler = {}

	ani.butler.spawn =
	{
		spt = 	{ 
					img_load("snake18.png"), 
					img_load("snake19.png"), 
					img_load("snake20.png"),
					img_load("snake21.png"),
					
				},

		cnt = 4,
		time = {1, 0.2, 0.2, 0.1, 0.1, 0.1},
		rep = 0,
		exit = 'walk',
		--unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 13,
	}

	ani.butler.walk =
	{
		spt = 	{ 
					img_load("butler1.png"), 
					img_load("butler2.png"), 
					img_load("butler3.png"), 
					img_load("butler4.png"), 
					
				},

		cnt = 4,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 13,
	}

	ani.butler.carrywalk =
	{
		spt = 	{ 
					-- img_load("snake1.png"), 
					-- img_load("snake2.png"), 
					-- img_load("snake3.png"), 
					-- img_load("snake4.png"), 
					-- img_load("snake5.png"), 
					-- img_load("snake6.png"), 

					img_load("butler5.png"), 
					img_load("butler6.png"), 
					img_load("butler7.png"), 
					img_load("butler8.png"), 
					
				},

		cnt = 4,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 13,
	}


	ani.butler.die =
	{
		spt = 	{ 
					img_load("snake13.png"), 
					img_load("snake14.png"), 
					img_load("snake15.png"), 
					img_load("snake16.png"), 
					img_load("snake17.png"),   
				},
		cnt = 5,
		time = {0.2, 0.2, 0.2, 0.6, 3},
		rep = 0,
		exit = '',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 13,
		blink = 5
	}




	ani.stealer = {}

	ani.stealer.spawn =
	{
		spt = 	{ 
					img_load("snake18.png"), 
					img_load("snake19.png"), 
					img_load("snake20.png"),
					img_load("snake21.png"),
					
				},

		cnt = 4,
		time = {1, 0.2, 0.2, 0.1, 0.1, 0.1},
		rep = 0,
		exit = 'walk',
		--unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 13,
	}

	ani.stealer.walk =
	{
		spt = 	{ 
					img_load("snake1.png"), 
					img_load("snake2.png"), 
					img_load("snake3.png"), 
					img_load("snake4.png"), 
					img_load("snake5.png"), 
					img_load("snake6.png"), 
					
				},

		cnt = 6,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 13,
	}

	ani.stealer.carrywalk =
	{
		spt = 	{ 
					-- img_load("snake1.png"), 
					-- img_load("snake2.png"), 
					-- img_load("snake3.png"), 
					-- img_load("snake4.png"), 
					-- img_load("snake5.png"), 
					-- img_load("snake6.png"), 

					img_load("snake7.png"), 
					img_load("snake8.png"), 
					img_load("snake9.png"), 
					img_load("snake10.png"), 
					img_load("snake11.png"), 
					img_load("snake12.png"), 
					
				},

		cnt = 6,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 13,
	}


	ani.stealer.die =
	{
		spt = 	{ 
					img_load("snake13.png"), 
					img_load("snake14.png"), 
					img_load("snake15.png"), 
					img_load("snake16.png"), 
					img_load("snake17.png"),   
				},
		cnt = 5,
		time = {0.2, 0.2, 0.2, 0.6, 3},
		rep = 0,
		exit = '',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 13,
		blink = 5
	}


	ani.snake = {}
	ani.snake.walk =
	{
		spt = 	{ 
					img_load("snakie1.png"), 
					img_load("snakie2.png"), 
					img_load("snakie3.png"), 
					img_load("snakie4.png"), 
					img_load("snakie5.png"), 
					img_load("snakie6.png"), 
					
				},

		cnt = 6,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 13,
	}

	ani.snake.attack =
	{
		spt = 	{ 
					img_load("snakie7.png"), 
					img_load("snakie8.png"), 
					
				},
		cnt = 2,
		time = {0.1, 0.1},
		rep = 0,
		exit = 'walk',
		--unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 13,
	}

	ani.snake.die =
	{
		spt = 	{ 
					img_load("snakie9.png"), 
					img_load("snakie10.png"), 
					img_load("snakie11.png"), 
					img_load("snakie12.png"),
					img_load("snakie13.png"),  
				},
		cnt = 5,
		time = {0.2, 0.2, 0.2, 0.6, 5},
		rep = 1,
		exit = '',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 13,
		blink = 5,
	}


	ani.snake.sleep =
	{
		spt = 	{ 
					img_load("snakie14.png"), 
					img_load("snakie15.png"), 
				},
		cnt = 2,
		time = {0.6, 0.8},
		rep = 1,
		exit = '',
		uncont = 1,
		xoff = 8,
		yoff = 13,
	}



	ani.louse = {}
	ani.louse.walk =
	{

				spt = 	{ 

					img_load("woodlouse1.png"), 
					img_load("woodlouse2.png"), 
					img_load("woodlouse3.png"), 
					img_load("woodlouse4.png"), 
					
				},

		cnt = 4,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 9,
		yoff = 15,
	}

	ani.louse.attack =
	{

				spt = 	{ 

					img_load("woodlouse5.png"), 
					img_load("woodlouse6.png"), 
					img_load("woodlouse7.png"),
					img_load("woodlouse8.png"), 
					img_load("woodlouse6.png"),  					
				},

		cnt = 5,
		time = {0.05, 0.03, 0.03, 0.2, 0.05, 0.1},
		rep = 0,
		exit = 'walk',
		unbr = 1,
		--uncont = 1,
		xoff = 9,
		yoff = 15,
	}

	ani.louse.block =
	{
		spt = 	{ 

			img_load("woodlouse5.png"), 
			img_load("woodlouse9.png"), 
				
		},

		cnt = 2,
		time = {0.2, 0.1, 0.03, 0.2, 0.05, 0.1},
		rep = 0,
		exit = 'walk',
		unbr = 1,
		uncont = 1,
		xoff = 9,
		yoff = 15,
	}


	ani.louse.die =
	{
		spt = 	{ 

			img_load("woodlouse11.png"), 
			img_load("woodlouse12.png"), 
			img_load("woodlouse13.png"),
				
		},

		cnt = 3,
		time = {0.2, 0.2, 5},
		rep = 1,
		exit = '',
		unbr = 1,
		uncont = 1,
		xoff = 9,
		yoff = 15,
		blink = 3,
	}







	ani.spinner = {}
	ani.spinner.walk =
	{

				spt = 	{ 
					img_load("spinner1.png"), 
					img_load("spinner2.png"), 
					img_load("spinner3.png"), 
					img_load("spinner4.png"), 
					img_load("spinner5.png"), 
					img_load("spinner6.png"), 

					-- img_load("woodlouse1.png"), 
					-- img_load("woodlouse2.png"), 
					-- img_load("woodlouse3.png"), 
					-- img_load("woodlouse4.png"), 
					
				},

		cnt = 6,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 16,
	}

	ani.spinner.jump =
	{

				spt = 	{ 
					img_load("spinner10.png"), 
					img_load("spinner11.png"), 
					img_load("spinner12.png"), 
				},

		cnt = 3,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 0,
		exit = 'walk',
		unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 16,
	}


	ani.spinner.spin =
	{

				spt = 	{ 
					img_load("spinner7.png"), 
					img_load("spinner8.png"), 
					img_load("spinner9.png"), 
 
					
				},

		cnt = 3,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 16,
	}

	ani.spinner.sleep =
	{

				spt = 	{ 
					img_load("spinner13.png"), 
					img_load("spinner14.png"), 
					img_load("spinner15.png"), 
					img_load("spinner14.png"), 
					
				},

		cnt = 3,
		time = {0.4, 0.4, 0.4, 0.9, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 16,
	}


	ani.robot = {}
	ani.robot.walk =
	{

				spt = 	{ 
					img_load("digger1.png"), 
					img_load("digger2.png"), 
					img_load("digger3.png"), 
					img_load("digger4.png"), 
					img_load("digger5.png"), 
					img_load("digger6.png"), 
					
				},

		cnt = 6,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 13,
	}




	ani.robot.attack =
	{
		spt = 	{ 
					img_load("snakie7.png"), 
					img_load("snakie8.png"), 

					
				},
		cnt = 2,
		time = {0.1, 0.1},
		rep = 0,
		exit = 'walk',
		--unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 13,
	}

	ani.robot.die =
	{
		spt = 	{ 
					img_load("digger9.png"), 
					img_load("digger10.png"), 
					img_load("digger11.png"), 
					img_load("digger12.png"), 
					img_load("digger13.png"), 
					img_load("digger14.png"), 
				},
		cnt = 6,
		time = {0.1, 0.1, 0.1, 0.1, 0.1, 3, 0.6, 3},
		rep = 1,
		exit = '',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 13,

		blink = 6
	}


	ani.robot.sleep =
	{
		spt = 	{ 
					img_load("digger7.png"), 
					img_load("digger8.png"), 
				},
		cnt = 2,
		time = {0.6, 0.8},
		rep = 1,
		exit = '',
		uncont = 1,
		xoff = 8,
		yoff = 13,
	}

	

	ani.worm = {}
	ani.worm.walk =
	{
		spt = 	{ 
					img_load("worm1.png"), 
					img_load("worm2.png"),
					img_load("worm3.png"),
					img_load("worm4.png"),
					img_load("worm5.png"),
					img_load("worm6.png"),
					img_load("worm7.png"),
					img_load("worm8.png"),
				},
		cnt = 8,
		time = {0.2, 0.2, 0.25, 0.3, 0.2, 0.2, 0.2, 0.3},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8,
		yoff = 15,
	}


	ani.worm.eat =
	{
		spt = 	{ 
					img_load("worm7.png"),
					img_load("worm6.png"),
				},
		cnt = 2,
		time = {0.4, 0.4},
		rep = 1,
		exit = '',
		--unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 15,
	}

	ani.worm.gone =
	{
		spt = 	{ 
					img_load("worm9.png"),
					img_load("worm10.png"),
					img_load("worm11.png"),
					img_load("worm12.png"),
					img_load("worm13.png"),
				},
		cnt = 5,
		time = {0.3, 0.3, 0.3, 0.3, 1},
		rep = 0,
		exit = '',
		unbr = 1,
		uncont = 1,
		xoff = 8,
		yoff = 15,
	}



	ani.spider = {}
	ani.spider.walk =
	{
		spt = 	{ 
					img_load("spider1.png"), 
					img_load("spider2.png"), 
					img_load("spider3.png"), 
					img_load("spider4.png"), 
				},
		cnt = 4,
		time = {0.25, 0.3, 0.25, 0.3},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
	}

	ani.spider.sleep =
	{
		spt = 	{ 
					img_load("spider5.png"), 
					img_load("spider6.png"), 
					img_load("spider7.png"), 
				},
		cnt = 3,
		time = {0.4, 0.4, 0.4,},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
	}

	ani.spider.slide =
	{
		spt = 	{ 
					img_load("spider8.png"), 
				},
		cnt = 1,
		time = {0.4, 0.4, 0.4,},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
	}

	ani.spider.attack =
	{
		spt = 	{ 
					img_load("spider9.png"), 
					img_load("spider10.png"), 
				},
		cnt = 2,
		time = {0.1, 0.3,},
		rep = 0,
		exit = 'walk',
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
		unbr = 1,
		uncont = 1,
	}


	ani.spider.die =
	{
		spt = 	{ 
					img_load("spider11.png"), 
					img_load("spider12.png"), 
					img_load("spider13.png"), 
					img_load("spider14.png"), 
					img_load("spider15.png"),
					img_load("spider16.png"), 
				},
		cnt = 6,
		time = {0.5, 0.3, 0.3, 0.3, 0.3, 4},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
		unbr = 1,
		uncont = 1,
		blink = 6,
	}


	ani.marsh = {}
	ani.marsh.walk =
	{
		spt = 	{ 
					img_load("marshlight1.png"), 
					img_load("marshlight2.png"), 
					img_load("marshlight3.png"), 
					img_load("marshlight4.png"), 
					img_load("marshlight5.png"), 
					img_load("marshlight6.png"), 
					img_load("marshlight7.png"), 
					img_load("marshlight8.png"), 
					img_load("marshlight9.png"), 
					img_load("marshlight10.png"), 
					img_load("marshlight11.png"), 
					img_load("marshlight12.png"), 
		 

				},
		cnt = 12,
		time = {0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, },
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
	}


	ani.skull = {}
	ani.skull.walk =
	{
		spt = 	{ 
					img_load("skull2.png"), 
					img_load("skull3.png"), 
					img_load("skull4.png"), 
					img_load("skull5.png"), 
				},
		cnt = 4,
		time = {0.6, 0.6, 0.6, 0.6},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
	}


	ani.skull.die =
	{
		spt = 	{ 
					img_load("skull6.png"), 
					img_load("skull7.png"), 
					img_load("skull8.png"),   
					img_load("skull9.png"),  
				},
		cnt = 4,
		time = {0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		unbr = 1,
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
	}


	ani.ameba = {}
	ani.ameba.walk =
	{
		spt = 	{ 
					img_load("jellyfish1.png"), 
					img_load("jellyfish2.png"), 
					img_load("jellyfish3.png"), 
					img_load("jellyfish4.png"), 
				},
		cnt = 4,
		time = {0.2, 0.2, 0.2, 0.2},
		rep = 1,
		exit = '',
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
	}

	ani.ameba.die =
	{
		spt = 	{ 
					img_load("jellyfish5.png"), 
					img_load("jellyfish6.png"), 
					img_load("jellyfish7.png"), 
					img_load("jellyfish8.png"),  
				},
		cnt = 4,
		time = {0.1, 0.1, 0.1, 0.1, 0.1},
		rep = 1,
		exit = '',
		unbr = 1,
		--unbr = 1,
		--uncont = 1,
		xoff = 8, --8
		yoff = 8, --15
	}


	ani.marsh.die =
	{
		spt = 	{ 
					img_load("marshlight13.png"), 
					img_load("marshlight14.png"), 
					img_load("marshlight15.png"), 
					img_load("marshlight16.png"), 
					img_load("marshlight17.png"), 
					img_load("marshlight18.png"), 
					img_load("marshlight19.png"), 
					img_load("marshlight20.png"), 
 
				},
		cnt = 8,
		time = {0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 2,},
		rep = 1,
		exit = '',
		unbr = 1,
		--uncont = 0,
		xoff = 8, --8
		yoff = 8, --15
	}



	function ani_new (obj, name)

		obj.ani_name = name
		obj.ani_frame = 1
		obj.ani_frametime = 0
		obj.ani_status = 'walk'
		obj.ani_step = 1
		obj.ani_size = obj.ani_size or 2
		obj.d = obj.d or 0
		obj.flip = obj.flip or 1
	
	end	






	function ani_draw (obj, dt)

		--oldprint (dumpvar (obj))

		if obj.ani_status=="" then return end

		local ani = ani[obj.ani_name][obj.ani_status] 

		obj.ani_frametime = obj.ani_frametime + dt

		
		if obj.ani_frametime>ani.time[obj.ani_frame] then

			--obj.ani_frametime = 0
			--oldprint (obj.ani_frametime)

			obj.ani_frame = obj.ani_frame + 1
			
			if obj.ani_frame > ani.cnt then

				if ani.rep == 1 then
					obj.ani_frame = 1
					obj.ani_frametime = obj.ani_frametime - ani.time[obj.ani_frame]
				else

				if ani.rep == 0 then
					ani_setstatus (obj,ani.exit,true)
					--obj.ani_frametime = obj.ani_frametime - ani.time[obj.ani_frame]
				end
				
				if ani.rep == 2 then
					obj.ani_frame = obj.ani_frame - 1
				end

				end

			else
				obj.ani_frametime = 0
			end

			

		end


	--print (obj.x..' '..obj.y)
	--print (obj.ani_frame.." "..obj.ani_status)

	if ani.blink and ani.blink==obj.ani_frame and obj.ani_frametime>1
		and (math.floor (obj.ani_frametime*7)%2)==0 then
		love.graphics.setColor (1,1,1,0.3)
	else
		love.graphics.setColor (1,1,1,1)
	end

	if ani.norotate then
		love.graphics.draw(quad, ani.spt[obj.ani_frame], math.floor(obj.x), math.floor(obj.y), 0, 
		obj.ani_size*obj.flip, obj.ani_size, ani.xoff, ani.yoff)
	else
		love.graphics.draw(quad, ani.spt[obj.ani_frame], math.floor(obj.x), math.floor(obj.y), math.rad (obj.d), 
		obj.ani_size*obj.flip, obj.ani_size, ani.xoff, ani.yoff)
	end

	love.graphics.setColor (1,1,1,1)
		
	end


	function ani_setstatus (obj,name, force)

		if name==nil then return end
		local ani = ani[obj.ani_name][obj.ani_status] 
		if ani == nil then return end

		if obj.ani_status~=name then

			if ani.unbr and force==nil then
				return false
			end

			obj.ani_frame = 1
			obj.ani_frametime = 0
			obj.ani_status = name
			obj.ani_step = 1


		end
	end

	function ani_getstatus (obj,mode)
		local ani = ani[obj.ani_name][obj.ani_status] 

		if ani and mode then
			return ani[mode]
		else
			return ani
		end
	end

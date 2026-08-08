	


	time = {}

	time.min = 50
	time.h = time.min*60
	time.d = time.h * 28
	time.w = time.d * 7
	time.m = time.w * 4
	time.y = time.m * 12


	--time.y, time.m, time.w, 

	time.all = {time.w, time.d, time.h, time.min}

	dumpout = ""
	dumprex = 0
	dumprey = 0
	
	delay = {}
	mobs = {}
	lights = {}
	proj = {}
	lines = {}
	bubble = {}
	tips = {}
	disp = {}
	edit = {}
	sct = {}
	--x,y,ttl,text
	

	-- player collision
	col = {}
	col.x = -7
	col.y = -30
	col.w = 15
	col.h = 55

	
	--player
	pl = {}	


	-- config
	cf = {}
	cf.w = 32
	cf.h = 32
	cf.blockfallspeed = 8
	cf.eq = {'r','l','h','b','g','f','t','a','n','e'}
	cf.eqs = {r = 'l', l = 'h', h = 'b', b = 'g', g = 'f', f = 't', t = 'a', a = 'n', n = 1} --cf.eqs.n
	cf.eqname = {'Hand','hand','Head','Body','Legs','Foot','Belt','Arms',"Neck"}

	cf.deadfire = 100 -- deadly temp
	cf.firehit = 1 -- hit by staning in fire
	cf.watersip = 5 -- thirst recovery per 10

	cf.itemmax = 20

	cf.bricks =
	{
		[56] = 2,
		[122] = 2, --stonework

		[12] = 3, --soil
		[13] = 4, --rich soil

		[38] = 3,
		[121] = 3, --cob

		[35] = 4, --stone block

		[64] = 7, -- brickwall

		[183] = 5,

		[47] = 6 --ice
	}

	-- camera
	vi = {}
	vi.xoffset = 0
	vi.yoffset = 0
	vi.x = 0
	vi.y = 0
	vi.w = 800
	vi.h = 800

	--start
	vi.xtile   = 360
	vi.ytile   = 380
	


	pl.startheight1 = 430
	pl.startheight2 = 437

	
	cf.rec = {}
	cf.rec.power = 1/84000
	cf.rec.food = 0.0015
	cf.rec.powerdead = 0.000277

	-- world size
	cf.wmax = 400

	pl.startx = cf.wmax/2
	pl.starty = cf.wmax/2


	-- camera scroll
	vi.vixmax = 850
	vi.vixmin = 550
	vi.viymax = 400
	vi.viymin = 300


	vi.textwall_h = 140
	vi.textwall_w = 700

	vi.mobspawndist = 30



	--saveable data
	-- player
	
	pl.log = {}
	pl.logoffset = 0



	-- coby block
	cf.cob_pick = 
	{
		{-1,0},
		{-1,1},
		{1,0},
		{1,1}
	}


	pl.diet = {
		veggies = 0,
		fruits = 0,
		carbs = 0,
		protein = 0,
		exotic = 0,
		fat = 0,
		fish = 0,
		--[spices] = 0,	
	}

	cf.diet = 
	{
		'carbs','protein','fat','veggies','fruits','exotic','fish'

	}

	pl.score = 0
	pl.savedscore = 0

	pl.unlock_i = {} -- discovered items
	pl.unlock_c = {} -- discovered crafting
	pl.unlocking_c = 0

	pl.visited = {}
	pl.ferted = {}

	pl.killed = {} --mobs killed

	pl.deaths = 0
	pl.idlecnt = 0
	pl.bufftick = 0

	pl.inv = {}
	pl.invsize = 9
	pl.invselect = 1
	pl.invpage = 0
	
	pl.x = 660
	pl.y = 180
	pl.wxt = 0
	pl.wyt = 0
	pl.xto = 0
	pl.yto = 0
	pl.xo = 0
	pl.yo = 0

	pl.moving = ""
	pl.xspeed = 0
	pl.yspeed = 0

	pl.speed = 75
	pl.jumpx = 3
	pl.jumpy = 9.5

	pl.jumpxslow = 1
	pl.jumpyslow = 1

	pl.speedstat = 1
	pl.speeds = {90, 80, 70}
	pl.jumpxs = {3.5, 3, 2}
	--pl.jumpys = {10.5, 10, 9.5}
	pl.jumpys = {10, 9.5, 9}





	



	pl.jumpcarry = 0.8 -- carring multiplier
	pl.walkcarry = 0.8 -- carring multiplier
	
	pl.slowed = 1
	pl.rest = 0
	pl.unrest = 0
	pl.spenddead = 0


	pl.disastercd = 0
	cf.disastercd = time.h

	cf.disaster = {}

	cf.disaster.frost = {
		ini = time.w*2,
		cd = time.d,
		chance = 100,
	}

	cf.disaster.farfrost = {
		ini = time.w,
		cd = time.d,
		chance = 100,
	}

	cf.disaster.steal = {
		ini = time.d * 5,
		cd = time.d,
		chance = 50,
	}

	cf.disaster.amoeba = {
		ini = time.d * 7,
		cd = time.d,
		chance = 90,
	}
	


	pl.restquality = 1
	pl.canuse = nil

	--flags
	pl.fell = 0
	pl.jumpleft = 0  	
	pl.isjump = 0
	pl.is = {}
	pl.state = "idle"
	pl.oldstate = 'idle'
	pl.digdone = 0
	pl.digspeed = 1
	pl.digcount = 0
	pl.digcountup = 0
	pl.digstart = 0
	pl.iscarry = nil
	pl.flip = 1
	pl.kicktime = 0.5

	--stats_reset ()

	
	pl.shit = {}
	pl.buffs = {}
	pl.lastshit = 0

	-- projectilesd
	pl.degree = 135
	pl.travel = 0
	pl.throw = 0
	pl.throwcd = 1
	pl.attackcd = 1
	pl.throwmax = 400
	pl.canthrow = 1


	worldani = {}

	game = {}
	game.gr2x = true
	game.fullscreen = true
	
	cursor = {}
	verbose = {}
	verbose.take = true
	verbose.drop = true
	
	game.version = game_version
	game.dbg = {}
	game.disaster = 0
	game.lasthit = ""
	game.justremoved = 0
	game.minimap = false
	game.minimaplast = 0
	game.moved = false
	game.firecheck = 0

	game.pause = nil
	game.craft = false
	game.state = ""
	game.time = 0
	game.recovery = 0
	game.fade = 0

	game.dt = 0
	game.ttlcheck = 0
	game.deltacheck = 3 -- how often (sec)
	game.xcheck = 1
	game.ycheck = 1
	game.digdone = 0

	game.ttl_list = {}
	game.ph_list = {}
	game.textinput = ""
	game.textinputinfo = ""
	game.inputing = nil


	currentBlock = 1
	currentItem = 1
	currentFrame = 1
	frameTime = 0
	cycleTime = 0

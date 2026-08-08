function heat_spread (x,y,xp,yp)

	local tile, map = maptile (x,y,"all")
	local tp = map.tp or 0
	local c = tile.t_cap or 0 
	local d1 = map.de or 0

	local tile2, map2 = maptile (x+xp,y+yp,"all")
	local s = tile2.t_speed or 0
	local c2 = tile2.t_cap or 0
	local tp2 = map2.tp or 0
	local d2 = map2.de or 0

	local fade

	if math.abs (d1)>math.abs(d2) then

		if s == 0 then
			if (map2.b==0 or map2.b==nil) and map.i==nil then 
				s = 10 
			else
				s = 50 --was 30
			end
		end

		if c == 0 then
			if map.b==0 or map.b==nil then 
				c = 1000
			else
				c = 2000
			end
		end


		if c2 == 0 then
			if (map2.b==0 or map2.b==nil) and map.i==nil then 
				c2 = 1000 
			else
				c2 = 2000
			end
		end

	
		s = s * 2
		local del = d1/(d2+0.1)
		if del>1 then 
			del = 1 + math.log (del+1)/2
			--print (del)
			s = s * del
		end

		if tp>0 and tp<=s then
			s = tp 
		end

		-- if map2.b==35 and  map.b==55 then
		-- 	print (s)
		-- end

		if tp>=s then

			tp = tp - s
			tp2 = tp2 + s - 2

			local d1 = tp/c*100
			local d2 = tp2/c2*100

			if tp<0 then
				tp = nil
				d1 = nil
			end

			writemap (x,y,d1,'de')
			writemap (x+xp,y+yp,d2,'de')
			writemap (x,y,tp,'tp')
			writemap (x+xp,y+yp,tp2,'tp')
		else
			fade = true
		end
	
	else
			--fade = true
	end

	if fade then
		tp = tp - 0.1
		if tp<0.1 then 
			tp = nil 
			writemap (x,y,nil,'de')
		end
		writemap (x,y,tp,'tp')
	end

end



function fire (x,y)

	local cd = readmap (x,y,'cd') or 0

	if cd<game.dt then

		cd = game.dt + 1
		writemap (x,y,cd,'cd')
		local tp = readmap (x,y,'tp') or 0
		local old = readmap (x,y,'max') or 200
		if old == 0 then old = 200 end

		local w = readmap (x,y,'w')
		if w then
			writemap (x,y,nil,'tp')
			writemap (x,y,nil,'de')
			writemap (x,y,0)
			return false
		end


		
		local i = world[y][x].i
		local max = 0

		if i then
			local b = {}

			--f_burn = 1,
			--f_heat = 400,
			--f_start = 200,


			for k,v in pairs(i) do

				--print (old.." "..item[v.i].f_start)

				if item[v.i].f_burn and item[v.i].f_start<=old then -- flamable
					if b[v.i]==nil then --is burning
						b[v.i] = true
						if max<item[v.i].f_heat then max=item[v.i].f_heat end --temp
						--local left = (item[v.i].f_heat - tp) / item[v.i].f_heat
						--print (left)
						--if left<0 then left = 1 end
						--v.t = v.t - item[v.i].ttl/100*item[v.i].f_burn*left --dur
						v.t = v.t - item[v.i].ttl/100*item[v.i].f_burn --dur w/o left
					end
				end
			end

				writemap (x,y,max,'tp')
				writemap (x,y,max,'max')
				writemap (x,y,max,'de')
				heat_spread (x,y,0,-1)
				heat_spread (x,y,0,1)
			
		end

		if max == 0 then
			writemap (x,y,nil,'tp')
			writemap (x,y,nil,'de')
			writemap (x,y,0)
		end



	end


end


--quest = {}
--quest[1]

function quest_start (n)
	pl.quest = n
	pl.questing = true
	pl.questtexted = nil
	pl.questtexting = true
end

function quest_set (n)

	pl.quests[pl.quest] = true
	pl.quest = 0
	pl.queststep = 1
	pl.questing = nil
	pl.questtexted = nil
	pl.questtexting = true
	
end

function quest_reset (n)

	if n then
		pl.quests[n] = nil
	end
	pl.quest = 0
	pl.queststep = 1
	pl.questing = nil
	pl.questtexted = nil
	
end


function quest_cd (n)
	n = n or 30
	writemap (pl.startx+1,pl.starty+6,'done','status')
	writemap (pl.startx+1,pl.starty+6,n,'questcd')
	writemap (pl.startx+1,pl.starty+6,nil,'cd')
end


function quest_remove (x,y,i,cnt)
	for i=1,cnt do
		inv_ground_remove (x,y,inv_ground_find_i (x,y,i))
	end
end

function quest (x,y)


--	pl.questx = x
--	pl.questy = y

--	x = pl.startx+1
--	y = pl.starty+5


	if pl.noflashlight and inv_find (26)==nil and inv_find (27)==nil then
		inv_ground_add (x,y-1,item_make(26))
		--pl.quests[1] = nil
		pl.noflashlight = nil
	end

	if game.craft or game.pause then return end


	pl.quest = pl.quest or 1
	pl.quests = pl.quests or {}

	pl.queststep = pl.queststep or 1
	local dist = math.ceil (math.dist (x,y,pl.xt,pl.yt))
	local cd = readmap (x,y,'questcd') or 10

	-- has items
	local itemcnt = {}
	local i = readmap (x,y-1,"i")
	if i~=nil and pl.questtexting==nil then

		-- items
		local i = readmap (x,y-1,'i')
		if i then
			for k,v in pairs(i) do
				itemcnt[v.i] = (itemcnt[v.i] or 0) + 1
			end
		end

	end

	-- quest cd
	if cd>0 and (pl.xt~=x or pl.questtexting) then
		cd = cd - dt
		if cd<0 then cd = 0 end
		writemap (x,y,cd,'questcd')
		return
	end

--[[	if pl.questnexttexting and dist<7 then --quest started from away
		pl.questnexttexting = nil
		pl.questtexting = true
	end

	
]]--

	
	if (dist<2 or dist>5) and pl.questtexting==nil then return end --too far

	if pl.questing and i==nil and pl.questtexting then

		if msg.quest[pl.quest]==nil or pl.queststep>#msg.quest[pl.quest] then
			pl.queststep = 1
			pl.questtexting = nil
			pl.questtexted = true
			quest_cd ()
		else

			pl.questtexting = true
			cd = utf8.len(msg.quest[pl.quest][pl.queststep])*0.1

			textbubble ('dis',x+0.5,y+1.5,msg.quest[pl.quest][pl.queststep],cd,{style=5,theme=3,pad=10,w=300,out=1})
			textwall (msg.dispenser[6]..msg.quest[pl.quest][pl.queststep])

			pl.queststep = pl.queststep + 1
			writemap (x,y,cd,'questcd')
		end

	end


	-- flashlight
	if pl.quests[1]==nil and pl.questing==nil and game.time>32 then
		pl.quest = 1
		pl.questtexting = true
		pl.questing = true
		quest_cd (1)
	end

	if pl.quest == 1 and pl.quests[1]==nil and pl.questtexted then
		inv_ground_add (x,y-1,item_make(26))
		quest_cd ()
		quest_set ()
		return true
	end


	-- [2] find ice shard
	if pl.quests[4]==nil and pl.quest == 0 then
		quest_start (4)
	end

	if pl.quest == 4 and pl.questtexted then
		quest_cd ()
		quest_set ()
		buff_add (9)
		return true
	end


	-- [13] day survive
	local pld = math.floor ((game.time - (pl.lastdeath or 0))/time.d)

	if pl.quest == 0 and pl.quests[13]==nil and pld>1 and pl.quest ~= 13 then
		quest_start (13)
	end

	if pl.quest == 13 and pl.questtexted then
		writemap (x,y-1,124)
		inv_ground_add (x,y-1,item_make(212))
		quest_cd ()
		quest_set ()
		return true
	end


	-- [2] chair
	if pl.quests[2]==nil and pl.quest == 0 
	and (pl.stats.body.pc<30 or pl.stats.arms.pc<30) then
		quest_start (2)
	end

	if pl.quest == 2 and pl.questtexted then
		writemap (x,y-1,51)
		quest_cd ()
		quest_set ()
		return true
	end


	-- inspect quest
	if pl.quests[3]==nil and pl.quest == 0
	and (game.time>time.d*1) then
		quest_start (3)
	end

	-- give item
	if pl.quest == 3 and pl.questtexted then
		inv_ground_add (x,y-1,item_make(301))
		quest_cd ()
		quest_set ()
		return true
	end


	-- 7 stones
	if pl.quests[2] and pl.quests[5]==nil and pl.quest == 0 then
		quest_start (5)
	end


	if pl.quest==5 and itemcnt[5] and itemcnt[5] == 7 then
		quest_remove (x,y-1,5,7) --i,cnt
		--writemap (x,y-1,124)
		inv_ground_add (x,y-1,item_make(22))
		inv_ground_add (x,y-1,item_make(22))
		inv_ground_add (x,y-1,item_make(292))
		quest_cd ()
		quest_set ()
		buff_add (24) --buff
		return true
	end


	-- [6] silent type
	if pl.quests[5] and pl.quests[6]==nil and pl.quest == 0 then
		quest_start (6)
	end

	if pl.quest==6 and pl.questtexted then
		quest_set ()
		quest_cd ()
		local m = mob_create (x,y-2,5)
		mobs[m].hp = 1
	end


	-- heater
	if 	pl.quests[7]==nil and pl.quest == 0
	and (pl.stats.heat.hp<20) then
		quest_start (7)
	end

	if pl.quest == 7 and itemcnt[36] and itemcnt[36] == 3 then
		quest_remove (x,y-1,36,3) --i,cnt
		writemap (x,y-1,50)
		quest_cd ()
		quest_set ()
		buff_add (24) --buff
		return true
	end


	-- robot shells
	if pl.quests[8]==nil and pl.unlock_i[280] and pl.quest == 0 then
		quest_start (8)
	end


	if pl.quest == 8 and tips.i280 and itemcnt[280] and itemcnt[280]==3 then
		quest_remove (x,y-1,280,3) --i,cnt
		writemap (x,y-1,138)
		quest_cd ()
		quest_set ()
		buff_add (24) --buff
		return true
	end


--	dump (pl.quest)
--	dump (pl.quests[9])

--quest_start (9)

	-- louse tails
	if pl.quest==0 and pl.quests[9]==nil and pl.killed[15] then
		quest_start (9)
		inv_ground_add (x,y-1,item_make(308))
		quest_cd (1)
		return
	end

	if pl.quest==9 and pl.questtexted then
		
	end

	-- 5 stingers
	if pl.quest == 9 and itemcnt[274] and itemcnt[274]==5 then
		quest_remove (x,y-1,274,5) --i,cnt
		quest_set ()
		quest_start (10)
		buff_add (24) --buff
		return true
	end


	if pl.quest == 10 and pl.questtexted  then

		inv_ground_add (x,y-1,item_make(273))
		inv_ground_add (x,y-1,item_make(273))
		inv_ground_add (x,y-1,item_make(273))
		inv_ground_add (x,y-1,item_make(273))
		inv_ground_add (x,y-1,item_make(273))
		inv_ground_add (x,y-1,item_make(315))
		inv_ground_add (x,y-1,item_make(307))

			
		quest_cd ()
		quest_set ()

	end

	
	--kill spiders
	if pl.quest==0 and pl.quests[11]==nil and  pl.quests[8] then
		quest_start (11)
		quest_cd (1)
	end


	if pl.quest == 11 and itemcnt[159] and itemcnt[159]==5 then
		quest_remove (x,y-1,159,5) --i,cnt
		quest_set ()
		quest_cd ()
		inv_ground_add (x,y-1,item_make(319))
		inv_ground_add (x,y-1,item_make(318))
		inv_ground_add (x,y-1,item_make(315))
		inv_ground_add (x,y-1,item_make(266))
		buff_add (24) --buff
		return true
	end


	--talk
	if pl.quest==0 and pl.quests[12]==nil and  pl.quests[11] then
		quest_start (12)
	end

	if pl.quest == 12 and pl.questtexted  then
		quest_cd ()
		quest_set ()
		writemap (x,y-1,124)
	end
	


	-- achievements
	if pl.quest == 16 and pl.questtexted  then
		quest_cd ()
		quest_set ()
	end



	--ore
	if pl.quest==0 and pl.quests[15]==nil and pl.unlock_i[60] and readmap (x,y-1,'b')==0 then
		quest_start (15)
	end

	if pl.quest == 15 and pl.questtexted  then
		writemap (x,y-1,78)
		inv_ground_add (x,y-1,item_make(281))
		quest_cd ()
		quest_set ()
	end



	-- golem talk
	if pl.quest == 14 and pl.questtexted then
		quest_cd ()
		quest_set ()
		return true
	end
	


	


end

function dispenser (x,y)


	-- dispenser_cd = (dispenser_cd or 0) + dt
	-- if dispenser_cd<0.5 then return end
	-- dispenser_cd = 0

	x = pl.startx+1
	y = pl.starty+6
	

	if game.start.ani_status=='transform' or game.start.ani_status=='analyze' then
		sound_add ('shepard',38,{x=x,y=y})
	else
		sound_stop ('shepard')
	end

	local i = readmap (x,y-1,"i")
	local b = readmap (x,y-1,"b")
	local cd = readmap (x,y,'cd')
	local status = readmap (x,y,'status') or ''

	if i and #i>1 and status=='failed' then status="" end

	if status=="" and quest (x,y) then
		return
	end


	-- empty
	if (i==nil and b==0) then 
		ani_setstatus (game.start,'walk')
		writemap (x,y,nil,'status')
		return 
	else
		--writemap (x,y,10,'questcd')
	end


	--One item at a time
	if status=="" and i~=nil and #i>1 then

		if  #i<3 and pl.quest==0 then 
			textbubble ('dis',x+0.5,y+1.5,msg.dispenser[5],2,{style=5,theme=1,pad=10,w=300,out=1})
		end

		return
	end

	-- if i~=nil and #i>1 and status~="" then
	-- 	writemap (x,y,nil,'status')
	-- 	writemap (x,y,0,'questcd')
	-- end

	--You are standing too close. Move.
	if status == "" and math.abs (pl.xt-x)<2 and math.abs (pl.yt-y)<5 then
		ani_setstatus (game.start,'walk')
		writemap (x,y,nil,'cd')
		textbubble ('dis',x+0.5,y+1.5,msg.dispenser[3],2,{style=5,theme=1,pad=10,w=300,out=1})
		return
	end


	

	if (i or b>0) and cd==nil then cd = 5 end
	cd = cd - dt
	writemap (x,y,cd,'cd')

	if status=='done' and cd>0 then
		ani_setstatus (game.start,'transform')
		return
	end

	if status=='done' and cd<0 then
		ani_setstatus (game.start,'walk')
		return
	end

	if status=='failed' then
		ani_setstatus (game.start,'walk')
		return
	end

	-- analyze cd
	if cd>0 and (status=="" or status=='analyze') then 
		writemap (x,y,'analyze','status')
		ani_setstatus (game.start,'analyze')
		textbubble ('dis',x+0.5,y+1.5,message(msg.dispenser[1]..string.rep(".",(game.dt*3)%4),{[1] = math.floor(cd)}),2,{style=5,theme=2,pad=10,w=300,out=1})
		return 
	end

	writemap (x,y,nil,'cd')


	local remove

	if b>0 then
		
		local lasttip = true
		if msg.stone[b] and msg.stone[b].tips then

			tips['s'..b] = tips['s'..b] or 1
		
			if tips['s'..b] > #msg.stone[b].tips then
				lasttip = true
			else
				--audio[1]:play ()
				textbubble ('dis',x+0.5,y+1.5,msg.stone[b].tips[tips['s'..b]],5,{style=5,theme=3,pad=10,w=300,out=1})
				textwall (msg.dispenser[10],false,{[1] = msg.stone[b].name})
				textwall (msg.dispenser[6]..msg.stone[b].tips[tips['s'..b]])
				tips['s'..b] = tips['s'..b] +  1

				achi_trigger ('on_tip','s'..b)

				local toinv = stone[b].digtoinv
				if toinv and toinv~=0 then
					tips['i'..toinv] = (tips['i'..toinv] or 1) + 1
					achi_trigger ('on_tip','i'..toinv)
				end



				lasttip = false
				remove = true
				writemap (x,y,'done','status')
				writemap (x,y-1,0,'clear')
				stat_recovery ('power',10)

				if tips['s'..b] <= #msg.stone[b].tips-1 then
					textwall (msg.dispenser[14])
				end

			end

		end


		if lasttip then
			local ni = stone[b].transformi
			local n =  stone[b].transform

			local p = stone[b].transformpower or 0

			if pl.stats.power.hp<p then
				textbubble ('dis',x+0.5,y+1.5,msg.dispenser[11],10,{style=5,theme=1,pad=10,w=300,out=1})
				writemap (x,y,'failed','status')
				textwall (msg.dispenser[6]..msg.dispenser[11])
				return
			end

			if ni then
				remove = true
				writemap (x,y-1,0)
				inv_ground_add(x,y-1,item_make(ni))

				textwall (msg.dispenser[6]..(msg.stone[b].transform or msg.dispenser[2]))
				textbubble ('dis',x+0.5,y+1.5,(msg.stone[b].transform or msg.dispenser[2]),4,{style=5,theme=2,pad=10,w=300,out=1})
				
				stat_spend ("power",p)
				writemap (x,y,'done','status')
				writemap (x,y,nil,'cd')
			end

			if n then
				remove = true
				writemap (x,y-1,n)
				textwall (msg.dispenser[6]..msg.dispenser[2])
				textbubble ('dis',x+0.5,y+1.5,msg.dispenser[2],4,{style=5,theme=2,pad=10,w=300,out=1})
				
				stat_spend ("power",p)
				writemap (x,y,'done','status')
				writemap (x,y,nil,'cd')
			end
		

			if remove then 
				disp['s'..b] = disp['s'..b] or 0
				disp['s'..b] = disp['s'..b] +  1
				return
			else
				writemap (x,y,'failed','status')
				textwall (msg.dispenser[6]..msg.dispenser[4]) 
				textbubble ('dis',x+0.5,y+1.5,msg.dispenser[4],3,{style=5,theme=1,pad=10,w=300,out=1})
			end
		end

	end


	if i then
		for k,v in pairs(i) do

			local lasttip = true
			if msg.item[v.i] and msg.item[v.i].tips then

				tips['i'..v.i] = tips['i'..v.i] or 1
			
				if tips['i'..v.i] > #msg.item[v.i].tips then
					lasttip = true
				else
					--audio[1]:play ()
					--sound_add ('dis',1,{play = 1, dur = 5})

					inv_ground_remove (x,y-1,k)
					textbubble ('dis',x+0.5,y+1.5,msg.item[v.i].tips[tips['i'..v.i]],5,{style=5,theme=3,pad=10,w=300,out=1})
					textwall (msg.dispenser[10],false,{[1] = msg.item[v.i].name})
					textwall (msg.dispenser[6]..msg.item[v.i].tips[tips['i'..v.i]])
					tips['i'..v.i] = tips['i'..v.i] +  1
					achi_trigger ('on_tip','i'..v.i)

					local toinv = item[v.i].put
					if toinv and toinv~=0 then
						tips['s'..toinv] = (tips['s'..toinv] or 1) + 1
						achi_trigger ('on_tip','s'..toinv)
					end
					

					lasttip = false
					writemap (x,y,'done','status')
					writemap (x,y-1,0)
					stat_recovery ('power',5)

					if tips['i'..v.i] <= #msg.item[v.i].tips then
						textwall (msg.dispenser[14])
					end
				end

			end

			if lasttip then

				local ni = item[v.i].transformi
				local n = item[v.i].transform

				local p = item[v.i].transformpower or 0

				if pl.stats.power.hp<p then
					textbubble ('dis',x+0.5,y+1.5,msg.dispenser[11],10,{style=5,theme=1,pad=10,w=300,out=1})
					writemap (x,y,'failed','status')
					textwall (msg.dispenser[6]..msg.dispenser[11])
					return
				end
				
				if ni then
					remove = true
					inv_ground_remove (x,y-1,k)
					inv_ground_add (x,y-1,item_make(ni))
					textwall (msg.dispenser[6]..(msg.item[v.i].transform or msg.dispenser[2]))
					textbubble ('dis',x+0.5,y+1.5,(msg.item[v.i].transform or msg.dispenser[2]),4,{style=5,theme=2,pad=10,w=300,out=1})
					
					stat_spend ("power",p)
					writemap (x,y,'done','status')
					writemap (x,y,nil,'cd')
					return
				end

				if n then
					remove = true
					inv_ground_remove (x,y-1,k)
					writemap (x,y-1,0)
					writemap (x,y-1,n)
					textwall (msg.dispenser[6]..(msg.item[v.i].transform or msg.dispenser[2]))
					textbubble ('dis',x+0.5,y+1.5,(msg.item[v.i].transform or msg.dispenser[2]),4,{style=5,theme=2,pad=10,w=300,out=1})
					
					stat_spend ("power",p)
					writemap (x,y,'done','status')
					writemap (x,y,nil,'cd')
					return
				end
			
				if remove then
					disp['i'..v.i] = disp['i'..v.i] or 0
					disp['i'..v.i] = disp['i'..v.i] +  1
					return
				else
					writemap (x,y,'failed','status')
					textwall (msg.dispenser[6]..msg.dispenser[4]) 
					textbubble ('dis',x+0.5,y+1.5,msg.dispenser[4],3,{style=5,theme=1,pad=10,w=300,out=1})
	
					--inv_ground_add (x-1,y-1,inv_ground_remove (x,y-1,k))
				end
			end

		end
	end

	
	




end
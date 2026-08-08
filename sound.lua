allsounds = {}
sounds = {}

sounds[1] =
{
	--s = love.audio.newSource("sound/pctalk.ogg",'static'),
	s = love.audio.newSource("sound/printer.ogg", 'stream'),
	volume = 1,
	rolloff = 0.6,
	--relative = 1,
}


sounds[2] =
{
	s = love.audio.newSource("sound/slime.ogg", 'static'),
	volume = 1,
	rolloff = 0.4,
	--rolloff = 1,
	dur = 1,
	clone = 1,
}


sounds[3] =
{
	s = love.audio.newSource("sound/bow.ogg", 'static'),
	volume = 1,
	autoplay = 1,
	rolloff = 0.4,
	--rolloff = 1,
	--dur = 1,
	clone = 1,
}

sounds[4] =
{
	s = love.audio.newSource("sound/tick.ogg",'static'),
	volume = 1,
	autoplay = 1,
	--rolloff = 1,
	dur = 0.5,
	relative = 1,
}


sounds[5] =
{
	s = love.audio.newSource("sound/gravel.ogg",'static'),
	autoplay = 1,
	--autokill = 1,
	--rolloff = 1,
	--loop = 1,
	volume = 0.1,
	--relative = 1
}

-- https://freesound.org/people/dersuperanton/sounds/437650/
sounds[6] =
{
	-- s = 
	-- {
	-- 	love.audio.newSource("sound/hit.ogg",'static'),
	-- 	love.audio.newSource("sound/hit2.ogg",'static'),
	-- 	love.audio.newSource("sound/hit3.ogg",'static'),
	-- 	love.audio.newSource("sound/hit4.ogg",'static'),
	-- 	love.audio.newSource("sound/hit5.ogg",'static'),
	-- },

	s = {
		love.audio.newSource("sound/dmg.ogg",'static'),
		love.audio.newSource("sound/dmg2.ogg",'static'),
	},

	
	
	volume = 1,
	autoplay = 1,
	volume = 0.5,
	relative = 1,
	rpitch = {30,15}
}


-- -15 db
sounds[7] =
{
	s = love.audio.newSource("sound/lift.ogg",'static'),
	autoplay = 1,
	relative = 1,
	--volume = 0.3
	rpitch = {5,40}
}

sounds[8] =
{
	s = love.audio.newSource("sound/land.ogg",'static'),
	relative = 1,
	autoplay = 1,
	volume = 0.3,
	rpitch = {50,100}
}

sounds[9] =
{
	s = love.audio.newSource("sound/jump.ogg",'static'),
	relative = 1,
	autoplay = 1,
	volume = 0.25,
	rpitch = {15,20}

}

sounds[10] =
{
	s = love.audio.newSource("sound/cave.ogg",'stream'),
	loop = 1,
	autoplay = 1,
	volume = 0.25,
}

--https://freesound.org/people/klankbeeld/sounds/249634/
sounds[11] =
{
	s = love.audio.newSource("sound/cave2.ogg",'stream'),
	loop = 1,
	autoplay = 1,
	volume = 0.5,
}

sounds[12] =
{
	s = love.audio.newSource("sound/spider.ogg",'static'),
	volume = 1,
	--aa = 5,
	--ad = {1,15},
	--rolloff = 0.1,
	--relative = 1,
	dur = 1,
	--rseek = 12,
	clone = 1,
}


sounds[13] = --120%
{
	s = love.audio.newSource("sound/shimmer.ogg",'stream'),
	volume = 0.2,
	autoplay = 1,
	--rolloff = 0.4
	dur = 20,
	relative = 1
}

--Gravel_Ice_Shoes_Walking.wav 130%
-- -15% db
sounds[14] =
{
	s = love.audio.newSource("sound/climb.ogg",'static'),
	autoplay = 1,
	--autokill = 1,
	--rolloff = 1,
	loop = 1,
	volume = 1,
	relative = 1
}


sounds[15] =
{
	s = love.audio.newSource("sound/amoeba.ogg",'static'),
	volume = 1,
	autoplay = 1,
	--rolloff = 2,
	loop = 1,
	--rseek = 12,
	--rolloff = 1,
	dur = 1,
	clone = 1,
	--relative = 1,
}

sounds[16] =
{
	s = love.audio.newSource("sound/led.ogg",'static'),
	volume = 0.5,
	--ad = {1,10},
	rolloff = 1,
	dur = 1,
	loop = 1,
	autoplay = 1,
	clone = 1,
	--relative = 1
}

sounds[17] =
{
	s = love.audio.newSource("sound/bounce.ogg",'static'),
	volume = 1,
	--rolloff = 0.5,
	--loop = 1,
	dur = 1,
	autoplay = 1,
	--clone = 1,
}

sounds[18] =
{
	s = love.audio.newSource("sound/hit.ogg",'static'),
	volume = 1,
	--rolloff = 0.5,
	--loop = 1,
	--relative = 1,
	autoplay = 1,
}

sounds[19] =
{
	s = love.audio.newSource("sound/ecto.ogg",'static'),
	volume = 1,
	dur = 1,
	autoplay = 1,
	relative = 1,
}


sounds[20] =
{
	s = love.audio.newSource("sound/click.ogg",'static'),
	volume = 1,
	autoplay = 1,
	relative = 1
}

sounds[21] =
{
	s = love.audio.newSource("sound/whoosh.ogg",'static'),
	volume = 0.3,
	autoplay = 1,
	relative = 1,
	rpitch = {30,30}
}

sounds[22] =
{
	s = love.audio.newSource("sound/whoosh2.ogg",'static'),
	volume = 0.3,
	autoplay = 1,
	relative = 1,
	rpitch = {30,30}
}

sounds[23] =
{
	s = love.audio.newSource("sound/whoosh3.ogg",'static'),
	volume = 0.2,
	autoplay = 1,
	relative = 1,
	rpitch = {30,30}
}

-- https://freesound.org/people/Nimbyc/sounds/87058/
sounds[24] =
{
	s = love.audio.newSource("sound/heartbeat.ogg",'stream'),
	volume = 0.7,
	autoplay = 1,
	--relative = 1,
}

sounds[25] =
{
	s = love.audio.newSource("sound/dig.ogg",'static'),
	volume = 1,
	autoplay = 1,
	relative = 1,
	loop = 1,
}


sounds[26] =
{
	s = love.audio.newSource("sound/drop.ogg",'static'),
	volume = 1,
	autoplay = 1,
	--relative = 1,
	--relative = 1,
}

sounds[27] =
{
	s = love.audio.newSource("sound/wonder.ogg",'static'),
	volume = 1,
	autoplay = 1,
	relative = 1,
	--relative = 1,
}

sounds[28] =
{
	s = love.audio.newSource("sound/eating.ogg",'static'),
	volume = 1,
	autoplay = 1,
	relative = 1,
	--relative = 1,
}

sounds[29] =
{
	s = love.audio.newSource("sound/cello.ogg",'stream'),
	volume = 0.4,
	autoplay = 1,
	--relative = 1,
	--relative = 1,
}


--step
sounds[30] =
{
	s = love.audio.newSource("sound/leaves01.ogg",'static'),
	autoplay = 1,
	--autokill = 1,
	--rolloff = 1,
	volume = 0.05,
	--relative = 1
	rpitch = {50,100}
}


--step
sounds[31] =
{
	s = love.audio.newSource("sound/leaves02.ogg",'static'),
	autoplay = 1,
	--autokill = 1,
	--rolloff = 1,
	volume = 0.05,
	--relative = 1
	rpitch = {50,100}
}


sounds[32] =
{
	s = love.audio.newSource("sound/splash.ogg",'static'),
	autoplay = 1,
	--autokill = 1,
	--rolloff = 1,
	volume = 0.5,
	relative = 1
}


-- https://freesound.org/people/Rhedcerulean/sounds/31432/
sounds[33] =
{
	s = love.audio.newSource("sound/underwater.ogg",'stream'),
	autoplay = 1,
	--autokill = 1,
	--rolloff = 1,
	volume = 1,
	relative = 1,
	loop = 1
}


sounds[34] =
{
	s = love.audio.newSource("sound/bubble.ogg",'static'),
	autoplay = 1,
	volume = 1,
	relative = 1
}

sounds[35] =
{
	s = love.audio.newSource("sound/pour.ogg",'static'),
	autoplay = 1,
	volume = 1,
	relative = 1
}

sounds[36] =
{
	s = love.audio.newSource("sound/stonelouse.ogg",'static'),
	volume = 1,
	--aa = 5,
	--ad = {1,15},
	--rolloff = 0.1,
	--relative = 1,
	dur = 1,
	--rseek = 12,
	clone = 1,
}


sounds[37] =
{

	s = love.audio.newSource("sound/frostie.ogg",'static'),
	volume = 0.5,
	--aa = 5,
	--ad = {1,15},
	--rolloff = 0.1,
	--relative = 1,
	dur = 5,
	--rseek = 12,
	clone = 1,
	loop = 1
}



sounds[38] =
{
	s = love.audio.newSource("sound/shepard.ogg",'stream'),
	volume = 1,
	autoplay = 1,
	--rolloff = 0.4
	dur = 20,
	--relative = 1
}

sounds[39] =
{
	s = love.audio.newSource("sound/positive.ogg",'static'),
	volume = 1,
	autoplay = 1,
	relative = 1,
	--relative = 1,
}

sounds[40] =
{
	s = love.audio.newSource("sound/negative.ogg",'static'),
	volume = 1,
	autoplay = 1,
	relative = 1,
	--relative = 1,
}

sounds[41] =
{
	s = love.audio.newSource("sound/explode.ogg",'static'),
	volume = 1,
	autoplay = 1,
	--relative = 1,
	rolloff = 0.1,
}

sounds[41] =
{
	s = love.audio.newSource("sound/rockfall.ogg",'stream'),
	volume = 1,
	autoplay = 1,
	--relative = 1,
	rolloff = 0.1,
}

sounds[42] =
{
	s = love.audio.newSource("sound/fert.ogg",'stream'),
	volume = 1,
	autoplay = 1,
	relative = 1,
	--relative = 1,
}

sounds[43] =
{
	s = love.audio.newSource("sound/craft.ogg",'stream'),
	volume = 1,
	autoplay = 1,
	relative = 1,
	--relative = 1,
}

sounds[44] =
{
	s = love.audio.newSource("sound/chicken.ogg", 'static'),
	volume = 1,
	rolloff = 0.4,
	--rolloff = 1,
	dur = 1,
	clone = 1,
}

sounds[45] =
{
	s = love.audio.newSource("sound/fart.ogg",'stream'),
	volume = 0.5,
	autoplay = 1,
	relative = 1,
	--relative = 1,
}

function sound_killall ()
	for k,v in pairs(allsounds) do
		sound_kill (k)
	end
end

function sound_add (name,id, arr)
	--{x,y,play,dur}

	--dump (sounds)
	--if true then return end

	--print (name)
	--dump (arr)

	--print ('add '..name)

	arr = arr or {}

	if arr.kill then
		sound_kill (name)
	end

	-- new or update
	if allsounds[name]==nil or
		(allsounds[name] and allsounds[name].id~=id) then

			allsounds[name] = allsounds[name] or {}		

			
			--needs cloning
			if sounds[id].clone then

				if type(sounds[id].s)=='table'	then
					allsounds[name].s = sounds[id].s[love.math.random(1,#sounds[id].s)]:clone()
				else
					allsounds[name].s = sounds[id].s:clone()
					allsounds[name].clone = true
				end

			else

				if type(sounds[id].s)=='table'	then
					allsounds[name].s = sounds[id].s[love.math.random(1,#sounds[id].s)]
				else
					allsounds[name].s = sounds[id].s
				end

			end


			allsounds[name].id = id
			allsounds[name].volume = sounds[id].volume
			

			allsounds[name].s:setVolume ((sounds[id].volume or 1))

			--allsounds[name].s:setPitch (0.5)

			if sounds[id].rseek then
				allsounds[name].s:seek(love.math.random(0,sounds[id].rseek),'seconds')
			end


			local Source = allsounds[name].s


			if sounds[id].rolloff then
				Source:setRolloff((arr.rolloff or 0.4))
			end

			if sounds[id].loop then
				Source:setLooping(true)
			end

			if sounds[id].relative then
				Source:setRelative(true)
				--Source:setPosition (0, 0, 0)
			end

			if sounds[id].aa then
				Source:setAirAbsorption(sounds[id].aa)
			end

			if sounds[id].ad then
				Source:setAttenuationDistances(sounds[id].ad[1], sounds[id].ad[2])
			end

			if arr.play or sounds[id].autoplay then
				Source:play()
			end
			
	end

 	local Source = allsounds[name].s

	if Source:isPlaying()==false then
		Source:play()

		--random pitch
	 	if sounds[id].rpitch then
			local r = 1+love.math.random (-1*sounds[id].rpitch[1],sounds[id].rpitch[2])*0.01
			Source:setPitch(r)
			--print ('pitch'..r)
		end

	end


	if arr.volume then
		Source:setVolume (arr.volume)
	end

	if arr.x then
		allsounds[name].x = arr.x
		allsounds[name].y = arr.y
		Source:setPosition (arr.x, arr.y, 0)
	end

	if arr.dur or sounds[id].dur then
		allsounds[name].dur = (arr.dur or sounds[id].dur)
	end

end

function sound_position (name,x,y)
	Source = allsounds[name].s
	Source:setPosition (x, y, 0)
end

function sound_update ()
	for k,v in pairs(allsounds) do
		
		if v.dur then

			v.dur = v.dur - dt

			if v.dur<=0 then
				v.s:stop ()
				v.dur = nil
				sound_kill(k)
				return
			end

		end

		-- if v.s:isPlaying()==false then
		-- 	allsounds[k]=nil
		-- end

	end
end


function sound_play (name)
	if allsounds[name]==nil then return end
	local Source = allsounds[name].s
	if Source then
		Source:play()
	end
end

function sound_volume (name,add)
	if allsounds[name]==nil then return end
	local Source = allsounds[name].s
	local v = (allsounds[name].volume or 1)
	if Source then
		v = v + add*dt
		Source:setVolume (v)
		allsounds[name].volume = v
	end
end

function sound_kill (name)
	if allsounds[name]==nil then return end
	local Source = allsounds[name].s
	if Source then
		Source:stop()
		if allsounds[name].clone then
			--Source:release ()
		end
	end
	allsounds[name] = nil
end


function sound_stop (name)
	if allsounds[name]==nil then return end

	--print ('stop '..name)


	local Source = allsounds[name].s
	if Source then
		Source:stop()
	end
end

function sound_pause (name)
	if allsounds[name]==nil then return end
	local Source = allsounds[name].s
	if Source then
		Source:pause()
	end
end
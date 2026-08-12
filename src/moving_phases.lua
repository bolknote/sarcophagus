local MovingPhases = {}

function MovingPhases.prepare()
	if pl.state ~= "ave" and pl.state ~= "stepup" and pl.state ~= "stepupb"
		and pl.state ~= "fell" and pl.state ~= "jump" and pl.state ~= "hang"
		and pl.state ~= "pullup" and pl.state ~= "buttscratch"
		and pl.state ~= "dying" and pl.state ~= "flex" then
		pl.state = "idle"
	end
	if pl.idlecnt > 7 and pl.state == "idle" and pl.iscarry == nil then
		pl.state = "buttscratch"
		pl.idlecnt = -love.math.random(5, 10)
	end
	if pl.idlecnt > 7 and pl.state == "idle" and pl.iscarry then
		pl.state = "flex"
		pl.idlecnt = -love.math.random(5, 10)
	end

	local slow = pl.slowed
	if (is_pressed("rshift") or is_pressed("lshift"))
		and pl.stats.arms.pc >= 33 then
		slow = slow + 1
		pl.turbox = pl.x
	else
		pl.turbox = nil
	end
	if slow < 0 then slow = 0.2 end
	if pl.stats.arms.pc < 33 then
		pl.speedstat = 3
	elseif pl.stats.arms.pc < 66 then
		pl.speedstat = 2
	else
		pl.speedstat = 1
	end
	local speed_index = pl.speedstat
	pl.speed = pl.speeds[speed_index]
	pl.jumpx = pl.jumpxs[speed_index] + pl.jumpxs[speed_index] * ((slow - 1) / 2)
	pl.jumpy = pl.jumpys[speed_index]
	local step = pl.speed * dt * slow
	if pl.iscarry and step > 1 then step = step * pl.walkcarry end

	local points = {
		{ x = pl.x + col.x / 2, y = pl.y + col.y,
			mode = { up = true, down = true, left = true, right = true } },
		{ x = pl.x + col.x + col.w, y = pl.y + col.y + col.h / 2,
			mode = { up = true, down = true, left = true, right = true } },
		{ x = pl.x + col.x, y = pl.y + col.y + col.h / 2,
			mode = { up = true, down = true, left = true, right = true } },
		{ x = pl.x + col.x + col.w, y = pl.y + col.y + col.h,
			mode = { up = true, down = true, left = true, right = true } },
		{ x = pl.x + col.x, y = pl.y + col.y + col.h,
			mode = { up = true, down = true, left = true, right = true } },
	}
	togo = tocollide(points)
	return step, slow
end

function MovingPhases.finalize()
	if pl.state == "walk" and pl.iscarry then pl.state = "walk_carry" end
	if pl.state == "jump" and pl.iscarry then pl.state = "walk_carry" end
	if pl.state == "idle" and pl.iscarry then pl.state = "idle_carry" end
	if pl.state == "jump" and pl.iscarry then pl.state = "jump_carry" end
	if pl.state == "fall" and pl.iscarry then pl.state = "fall_carry" end

	if pl.state == "idle" then
		game.idle = (game.idle or 0) + dt
	else
		game.idle = 0
	end
	if fishing and pl.state == "idle" then pl.state = "fishing" end
	if pl.state ~= "idle" and pl.state ~= "fishing" and fishing then fishing = nil end
	if pl.state == "pullup" and pl.buffs[17] and pl.animation.frame == 1
		and math.random(0, 100) < 5 then
		pl.jumpleft = 0
		pl.state = "fall"
	end
	if pl.state == "idle" and mousetruemoved_last < 1 then
		pl.flip = pl.x > mouse_x and -1 or 1
	end
	if pl.state == "idle" and mousetruemoved_last < 1 and mouse_y < pl.y - 50 then
		pl.state = "headup"
	end
	if pl.state == "idle" and mousetruemoved_last < 1 and mouse_y > pl.y + 50 then
		pl.state = "headdown"
	end

	coord_screen2true(pl)
	col_add("player", pl, pl.state, "player", "player")
	if pl.turbox and pl.turbox ~= pl.x and pl.state ~= "fall"
		and pl.state ~= "jump" then
		stat_spend("arms", math.abs(pl.turbox - pl.x) * 0.05)
	end
	if pl.stats.body.hp > 0 and togo.down == 0 then
		pl.ltx = pl.tx
		pl.lty = pl.ty
	end
	game.pass = nil
end

return MovingPhases

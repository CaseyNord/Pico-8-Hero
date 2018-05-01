pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--goals
--variable scope in functions
--fix level clear after brick explode
--juicyness
--	serve preview
--	particles
--		brick particles
--		death particles
--		collision particles
--level setup
--	screen shake
--	arrow animation
--	text blinking
--high score 
--game complete

--[[

game notes:

-only one powerup can be active at a time
-this is because of the kind property, it is setup to where only one can be active at a time
-this could possible be changed if the decision is made to make it possible to have multiple certain
-powerups active simultaneously

-multibass has a weird behavior where it doesn't always seem to split on pickup.
-i think this has to do with how the array deletes elements and how the rnd() function
-is generating random numbers.  Look into this

]]

function _init()
	cls()

	ball =	{
		radius = 2,
		colour = 10
	}

	paddle = {
		x = 30,
		y = 120,
		dx = 0,
		speed = 2.5,
		width = 24,
		defaultwidth = 24,
		height = 3,
		colour = 7,
		sticky --intialized in serveball()
	}

	brick = {
		width = 9,
		height = 4,
		colour = {
			b = 14,
			i = 6,
			h = 15,
			s = 9,
			z = 8,
			p = 12
		}
	}

	pill = {
		speed = 0.6,
		width = 8,
		height = 6
	}

	powerup = {
		multiplier = 1,
		kind = 0,
		timer = {
			slowdown, --intialized in serveball()
			expand, --intialized in serveball()
			reduce, --intialized in serveball()
			megaball --intialized in serveball()
		}
	}

	player = {
		points, --initialized in startgame()
		combo, --initialized in startgame()
		lives --initialized in startgame()
	}

	manager = {
		mode = "startmenu",
		levelnumber, --initialized in startgame()
		debug = false,
		debugvalue = 0 --change value at --top screen banner
	}
	
	playarea = {
		left = 2,
		right = 125,
		ceiling = 9,
		floor = 135
	}

	level = {
		--x = empty space
		--/ = new row
		--b = normal brick
		--i = indestructable brick
		--h = hardened brick
		--s = exploding brick
		--p = powerup brick
		
		"i9i//h9h//b9b//p9p", --test level
		"////xb8xxb8", --lvl 1
		"//xbxbxbxbxbxxbxbxbxbxbxxbxbxbxbxbxxbxbxbxbxbx", --lvl 2
		"//b9bb9bb9bb9b", --lvl 3
		"/bxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxb", --lvl 4
		"ib3xb3iib3xb3i/ib3xb3iib3xb3i/ib3xb3iib3xb3i", --lvl 5
		"ib3xb3iibbsbxbsbbi/ib3xb3iibsbbxbbsbi/ib3xb3iibbsbxbsbbi", --lvl 6
		--"////x4b/i9x", --bonus lvl?

		--""
	}
end

function _update60()
	if manager.mode ==  "game" then
		update_game()
	elseif manager.mode == "startmenu" then
		update_startmenu()
	elseif manager.mode == "levelover" then
		update_levelover()
	elseif manager.mode == "gameover" then
		update_gameover()
	end
end

function _draw()
	if manager.mode ==  "game" then
		draw_game()
	elseif manager.mode == "startmenu" then
		draw_startmenu()
	elseif manager.mode == "levelover" then
		draw_levelover()
	elseif manager.mode == "gameover" then
		draw_gameover()
	end
end

function startmenu()
	manager.mode = "startmenu"
end

function update_startmenu()
	if btnp(5) then
		startgame()
	end
end

function draw_startmenu()
	rectfill(0,0,128,128,5)
	print("breakout",48,50,7)
	print("press ❎ to start",31,70)
end

function startgame()
	manager.mode = "game"
	manager.levelnumber = 1
	player.points = 0
	player.combo = 0 --combo chain multiplier
	player.lives = 3
	buildbricks(level[manager.levelnumber])
	serveball()
end

function update_game()
	local buttonispressed = false
	local nextx, nexty
	
	--left
	if btn(0) then
		paddle.dx = paddle.speed * -1
	 	buttonispressed = true
		stickyaim(-1)
	end	
	--right
	if btn(1) then
		paddle.dx = paddle.speed
		buttonispressed = true
		stickyaim(1)
	end

	--launch ball off paddle
	if  btnp(5) then
		releasecurrentsticky()
	end
	
	--paddle friction slowdown
	if not (buttonispressed) then
		paddle.dx /= 1.2
	end
	
	--paddle speed
	paddle.x += paddle.dx

	--expand/reduce paddle powerups
	if powerup.timer.expand > 0 then
		paddle.width = flr(paddle.defaultwidth * 1.5)
	elseif powerup.timer.reduce > 0 then
		paddle.width = flr(paddle.defaultwidth / 2)
		powerup.multiplier = 2
	else
		paddle.width = paddle.defaultwidth
		powerup.multiplier = 1
	end

	--stop paddle at screen edge
 	paddle.x =	mid(2,paddle.x,125-paddle.width)

	for i=#ballobj,1,-1 do
		updateball(i)
	end

	--move pills
	for i=#pillobj,1,-1 do --counts backwards so you don't collide when deleting objects
		pillobj[i].y+=pill.speed
		if pillobj[i].y > playarea.floor then
			del(pillobj,pillobj[i])
		elseif boxcollide(pillobj[i].x,pillobj[i].y,pill.width,pill.height,paddle.x,paddle.y,paddle.width,paddle.height) then
			sfx(10)
			powerupget(pillobj[i].kind)
			del(pillobj,pillobj[i])
		end
	end

	checkforexplosions()

	if levelfinished() then
		_draw() --final draw to clear last brick
		levelover()
	end

	--powerup clock update
	if powerup.timer.slowdown > 0 then
		powerup.timer.slowdown -=1
	end
	if powerup.timer.expand > 0 then
		powerup.timer.expand -=1
	end
	if powerup.timer.reduce > 0 then
		powerup.timer.reduce -=1
	end
	if powerup.timer.megaball > 0 then
		powerup.timer.megaball -=1
	end
end

function draw_game()
	cls(1)

	--draw balls
	for i=1,#ballobj do
		circfill(ballobj[i].x,ballobj[i].y,ball.radius,ball.colour)
	
		if ballobj[i].sticky then
			--serve preview
			line(ballobj[i].x+ballobj[i].dx*4,ballobj[i].y+ballobj[i].dy*4,ballobj[i].x+ballobj[i].dx*6,ballobj[i].y+ballobj[i].dy*6,ball.colour)
		end
	end

	--draw paddle
	rectfill(paddle.x,paddle.y,paddle.x+paddle.width,paddle.y+paddle.height,paddle.colour)
	
	--draw bricks
	for i=1,#brickobj do
		if brickobj[i].visible then
			local brickcolour
			if brickobj[i].kind == "b" then
				brickcolour = brick.colour.b
			elseif brickobj[i].kind == "i" then
				brickcolour = brick.colour.i
			elseif brickobj[i].kind == "h" then
				brickcolour = brick.colour.h
			elseif brickobj[i].kind == "s" then
				brickcolour = brick.colour.s
			elseif brickobj[i].kind == "zz" or brickobj[i].kind == "z" then
				brickcolour = brick.colour.z
			elseif brickobj[i].kind == "p" then
				brickcolour = brick.colour.p
			end
			rectfill(brickobj[i].x,brickobj[i].y,brickobj[i].x+brick.width,brickobj[i].y+brick.height,brickcolour)
		end
	end

	--draw pills
	for i=1,#pillobj do
		if pillobj[i].kind == 5 then
			palt(0,false) --display black (0)
			palt(15,true) --don't display creme (15)
		end
		spr(pillobj[i].kind,pillobj[i].x,pillobj[i].y)
		palt() --reset palette
	end

	--top screen banner
	rectfill(0,0,128,6,0)
	if manager.debug then
		manager.debugvalue = powerup.timer
		print("debug:"..manager.debugvalue,0,0,7)
	else
		print("lives:"..player.lives,0,0,7)
		print("points:"..player.points,68,0,7)
		print("combo:"..player.combo,34,0,7)
	end
end

function levelover()
	manager.mode = "levelover"
end

function update_levelover()
	if btnp(5) then
		nextlevel()
	end
end

function draw_levelover()
	--cls()
	rectfill(0,49,127,62,0)
	print("stage clear!",40,50,7)
	print("press ❎ to continue",24,57,6)
end

function nextlevel()
	manager.levelnumber += 1
	if manager.levelnumber > #level then
		--game has been completed
		return startmenu()
	end
	manager.mode = "game"
	player.combo = 0 --combo chain multiplier
	player.lives = 3
	buildbricks(level[manager.levelnumber])
	serveball()
end

function gameover()
	manager.mode = "gameover"
end

function update_gameover()
	if btnp(5) then
		startgame()
	end
end

function draw_gameover()
	--cls()
	rectfill(0,49,127,62,0)
	print("gameover!",48,50,7)
	print("press ❎ to restart",28,57,6)
end

function levelfinished()
	if #brickobj == 0 then return false end --don't finish level if explicitly empty
	for i=1,#brickobj do
		if brickobj[i].visible and brickobj[i].kind != "i" then
			return false
		end
	end
	return true
end

function updateball(_i)
	local _ballobj = ballobj[_i]
	--stick ball to paddle
	if _ballobj.sticky then
		_ballobj.x = paddle.x + stickyx
		_ballobj.y = paddle.y - ball.radius - 1
	else
		--regular ball physics/slowdown powerup
		if powerup.timer.slowdown > 0 then
			nextx = _ballobj.x + (_ballobj.dx / 2)
			nexty = _ballobj.y + (_ballobj.dy / 2)
		else
			nextx = _ballobj.x + _ballobj.dx
			nexty = _ballobj.y + _ballobj.dy
		end

		--check walls
		if nextx > playarea.right or nextx < playarea.left then
			nextx = mid(playarea.left,nextx,playarea.right)
			_ballobj.dx = -_ballobj.dx
		sfx(01)
		end
		--check ceiling
		if nexty < playarea.ceiling then
			nexty = mid(playarea.ceiling,nexty,playarea.floor)
			_ballobj.dy = -_ballobj.dy
		sfx(01)
		end

		--checks for paddle collision	
		if hitbox(nextx,nexty,paddle.x,paddle.y,paddle.width,paddle.height) then
			--find out which direction to deflect
			if deflection(_ballobj.x,_ballobj.y,_ballobj.dx,_ballobj.dy,paddle.x,paddle.y,paddle.width,paddle.height) then	
				--ball hits paddle on the side
				_ballobj.dx = -_ballobj.dx
				--resets ball position to edge of paddle on collision to prevent strange behavior
				if _ballobj.x < paddle.x+paddle.width/2 then
					--left
					nextx = paddle.x - ball.radius
				else
					--right
					nextx = paddle.x + paddle.width + ball.radius
				end
			else
				--ball hits paddle on the top/bottom
				_ballobj.dy = -_ballobj.dy
				--sets ball to top of paddle to prevent it getting stuck inside
				if _ballobj.y > paddle.y then
					--bottom
					nexty = paddle.y + paddle.height + ball.radius
				else
					--top
					nexty = paddle.y - ball.radius
					--change angle
					if abs(paddle.dx) > 2 then
						if sign(paddle.dx) == sign(_ballobj.dx) then
							--flatten angle
							setangle(_ballobj,mid(0,_ballobj.angle-1,2))
						else
							if _ballobj.angle == 2 then
								--reverse direction because angle is already increased
								_ballobj.dx *= -1
							else
								--increase angle
								setangle(_ballobj,mid(0,_ballobj.angle+1,2))
							end
						end
					end
				end
			end
			player.combo = 0 --resets combo when ball hits paddle
			sfx(01)

			--catch powerup
			if paddle.sticky and _ballobj.dy < 0 then
				releasecurrentsticky()
				paddle.sticky = false
				_ballobj.sticky = true
				stickyx = _ballobj.x - paddle.x
			end
		end
		
		--checks for brick collision
		local brickhit = false --ensures correct reflection when two bricks hit at same time

		for i=1,#brickobj do
			if brickobj[i].visible and hitbox(nextx,nexty,brickobj[i].x,brickobj[i].y,brick.width,brick.height) then
				--find out which direction to deflect
				if not(brickhit) then
					if powerup.kind == 6 and brickobj[i].kind == "i" or powerup.kind != 6 then
						--find out which direction to deflect
						if deflection(_ballobj.x,_ballobj.y,_ballobj.dx,_ballobj.dy,brickobj[i].x,brickobj[i].y,brick.width,brick.height) then	
							_ballobj.dx = -_ballobj.dx
						else
							_ballobj.dy = -_ballobj.dy
						end
					end
				end
				--brick is hit
				brickhit = true
				hitbrick(i,true)
			end
		end	

		--update coordinates to move ball
		_ballobj.x = nextx
		_ballobj.y = nexty
		
		--check floor
		if nexty > playarea.floor then
			sfx(00)
			if #ballobj > 1 then
				del(ballobj,_ballobj)
			else
				player.lives -= 1
				if player.lives < 0 then
					gameover()
				else
					serveball()
				end
			end
		end	
	end
end

function releasecurrentsticky()
	for i=1,#ballobj do
		if ballobj[i].sticky then
			ballobj[i].x = mid(playarea.left,ballobj[i].x,playarea.right)
			ballobj[i].sticky = false
		end
	end
end

function stickyaim(_sign)
	for i=1,#ballobj do
		if ballobj[i].sticky then
			ballobj[i].dx = abs(ballobj[i].dx)*_sign
		end
	end
end

function powerupget(_powerup)
	if _powerup == 1 then
		--slowdown
		powerup.kind = 1
		powerup.timer.slowdown = 600
	elseif _powerup == 2 then
		--lifeup
		powerup.kind = 0
		player.lives += 1
	elseif _powerup == 3 then
		--catch
		powerup.kind = 3
		paddle.sticky = true
		--prevents 'handoff' if a ball is already stuck to paddle
		for i=1,#ballobj do
			if ballobj[i].sticky then
				paddle.sticky = false
			end
		end
	elseif _powerup == 4 then
		--expand
		powerup.kind = 4
		powerup.timer.reduce = 0
		powerup.timer.expand = 600
	elseif _powerup == 5 then
		--reduce
		powerup.kind = 5
		powerup.timer.expand = 0
		powerup.timer.reduce = 600
	elseif _powerup == 6 then
		--megaball
		powerup.kind = 6
		powerup.timer.megaball = 600
	elseif _powerup == 7 then
		--multiball
		powerup.kind = 7
		multiball()
	end
end

function addbrick(_index,_kind)
	local _brickobj = {}
	_brickobj.x = 4+((_index-1)%11)*(brick.width+2)
	_brickobj.y = 20+flr((_index-1)/11)*(brick.height+2)
	_brickobj.visible = true
	_brickobj.kind = _kind
	add(brickobj,_brickobj)
end

function buildbricks(_lvl)
	local _character, _last, _j, _k
	brickobj = {} --change

	_j = 0
	for i=1,#_lvl do
		_j += 1
		_character = sub(_lvl,i,i)
		if _character == "b"
		or _character == "i"
		or _character == "h"
		or _character == "s"
		or _character == "p" then
			_last = _character
			addbrick(_j,_character)
		elseif _character == "x" then
			_last = "x"
		elseif _character == "/" then
			_j = (flr((_j-1)/11)+1)*11
		elseif _character >= "1" and _character <= "9" then
			for _k=1,_character+0 do
				if _last == "b"
				or _last == "i"
				or _last == "h"
				or _last == "s"
				or _last == "p" then
					addbrick(_j,_last)
				elseif _last == "x" then
					--create empty space
				end
				_j += 1
			end
			_j -= 1 --prevents skipping a line
		end
	end
end

function hitbrick(_i,_combo)
	if brickobj[_i].kind == "b" then
		sfx(02+player.combo)
		brickobj[_i].visible = false
		player.points += 10*(player.combo+1)*powerup.multiplier
		combo(_combo)
	elseif brickobj[_i].kind == "i" then
		sfx(09)
	elseif brickobj[_i].kind == "h" then
		if powerup.timer.megaball > 0 then
			sfx(02+player.combo)
			brickobj[_i].visible = false
			player.points += 10*(player.combo+1)*powerup.multiplier
			combo(_combo)
		else
			sfx(09)
			brickobj[_i].kind = "b"
		end
	elseif brickobj[_i].kind == "s" then
		sfx(02+player.combo)
		brickobj[_i].kind = "zz"				
		player.points += 10*(player.combo+1)*powerup.multiplier
		combo(_combo)
	elseif brickobj[_i].kind == "p" then
		sfx(02+player.combo)
		brickobj[_i].visible = false				
		player.points += 10*(player.combo+1)*powerup.multiplier
		combo(_combo)
		spawnpill(brickobj[_i].x,brickobj[_i].y)
	end
end

function resetpills()
	--empty pill tables
	pillobj = {}
end

function spawnpill(_brickx,_bricky)
	local _pillobj = {}
	_pillobj.x = _brickx
	_pillobj.y = _bricky
	_pillobj.kind = flr(rnd(7))+1
	
	--[[ test powerups
	t = flr(rnd(2))
	if t == 1 then
		_pillobj.kind = 3
	else
		_pillobj.kind = 7
	end
	]]

	add(pillobj,_pillobj)
end

function combo(_istrue)
	if _istrue then
		player.combo += 1
		player.combo = mid(1,player.combo,6) --make sure combo doesn't exceed 7
	end
end

function checkforexplosions()
	for i=1,#brickobj do
		if brickobj[i].kind == "z" then
			brickexplode(i)
		end
	end
	for i=1,#brickobj do
		if brickobj[i].kind == "zz" then
			brickobj[i].kind = "z"
		end
	end
end

function brickexplode(_i)
	brickobj[_i].visible=false
	for j=1,#brickobj do
		if j !=_i 
		and brickobj[j].visible 
		and abs(brickobj[j].x-brickobj[_i].x) <= (brick.width+2)
		and abs(brickobj[j].y-brickobj[_i].y) <= (brick.height+2)
		then
			hitbrick(j,false)
		end
	end 
end

function newball()
	local _ball = {}
	_ball.x = 0
	_ball.y = 0
	_ball.dx = 0
	_ball.dy = 0
	_ball.angle = 1
	_ball.sticky = false
	return _ball
end

function copyball(_ball)
	local newball = {}
	newball.x = _ball.x
	newball.y = _ball.y
	newball.dx = _ball.dx
	newball.dy = _ball.dy
	newball.angle = _ball.angle
	newball.sticky = _ball.sticky
	return newball
end

function multiball()
	--there is a bug here where the random function doesn't seem to always return
	--a valid ball to split, meaning sometimes a multiball pickup won't do anything
	local _ballobjindex = flr(rnd(#ballobj))+1
	local _ogball = copyball(ballobj[_ballobjindex]) --index a random ball 
	local _ball2 = _ogball 
	--local _ball3 = copyball(ballobj[1])
	
	if _ogball.angle == 0 then
		setangle(_ball2,0)
		--setangle(_ball3,2)
	elseif _ogball.angle == 1 then
		setangle(_ogball)
		setangle(_ball2,2)
		--setangle(_ball3,0)
	else
		setangle(_ball2,0)
		--setangle(_ball3,1)
	end

	_ball2.stuck = false --prevents unwanted paddle sticking behavior
	ballobj[#ballobj+1] = _ball2
	--ballobj[#ballobj+1] = _ball3
end

function serveball()
	ballobj = {}
	ballobj[1] = newball()
	ballobj[1].x = paddle.x+flr(paddle.width/2)
	ballobj[1].y = paddle.y-ball.radius
	ballobj[1].dx = 1
	ballobj[1].dy = -1
	ballobj[1].angle = 1 
	ballobj[1].sticky = true

	paddle.sticky = false
	stickyx = flr(paddle.width/2) --necessary here for catch powerup

	player.combo = 0
	powerup.kind = 0
	powerup.timer.slowdown = 0
	powerup.timer.expand = 0
	powerup.timer.reduce = 0
	powerup.timer.megaball = 0
	resetpills();
end

function setangle(_ball,_angle)
	_ball.angle = _angle
	if _angle == 2 then
		_ball.dx = 0.60*sign(_ball.dx)
		_ball.dy = 1.40*sign(_ball.dy)
	elseif angle == 0 then
		_ball.dx = 1.40*sign(_ball.dx)
		_ball.dy = 0.60*sign(_ball.dy)
	else
		_ball.dx = 1*sign(_ball.dx)
		_ball.dy = 1*sign(_ball.dy)
	end
end

function sign(_number)
	if _number < 0 then
		return -1
	elseif _number > 0 then
		return 1
	else
		return 0
	end
end

--collosion detection
function hitbox(_bx,_by,_x,_y,_width,_height)
	if (_by-ball.radius > _y + _height) then
		return false
	end
	if (_by+ball.radius < _y) then
		return false
	end
	if (_bx-ball.radius > _x + _width) then
		return false
	end
	if (_bx+ball.radius < _x) then
		return false
	end
	return true
end

--checks for collision between colliding boxes (pill/paddle)
function boxcollide(_bx1,_by1,_width1,_height1,_bx2,_by2,_width2,_height2)
	if (_by1 > _by2 + _height2) then
		return false
	end
	if (_by1 + _height1 < _by2) then
		return false
	end
	if (_bx1 > _bx2 + _width2) then
		return false
	end
	if (_bx1 + _width1 < _bx2) then
		return false
	end
	return true
end

--checks for correct angle deflection
function deflection(_bx,_by,_bdx,_bdy,_tx,_ty,_tw,_th)
	local _slope = _bdy / _bdx
	local _cx, _cy

	if _bdx == 0 then
		--moving vertically
		return false
	elseif _bdy == 0 then
		--moving horizontally
		return true
	elseif _slope > 0 and _bdx > 0 then
		_cx = _tx - _bx
		_cy = _ty - _by
		return _cx > 0 and _cy/_cx < _slope
	elseif _slope < 0 and _bdx > 0 then
		_cx = _tx - _bx
		_cy = _ty + _th - _by
		return _cx > 0 and _cy/_cx >= _slope
	elseif _slope > 0 and _bdx < 0 then
		_cx = _tx + _tw - _bx
		_cy = _ty + _th - _by
		return _cx < 0 and _cy/_cx <= _slope
	else
		_cx = _tx + _tw - _bx
		_cy = _ty - _by
		return _cx < 0 and _cy/_cx >= _slope
	end
end

__gfx__
0000000006777760066666600677776006777760f677776f06777760067777600000000000000000000000000000000000000000000000000000000000000000
00000000659949556575775565b33b5565c1c1556508805565e22255658222550000000000000000000000000000000000000000000000000000000000000000
00700700559499555575775555b3bb5555cc1c555508085555e22255558828550000000000000000000000000000000000000000000000000000000000000000
00077000559949555575775555b3bb5555cc1c555508805555e2e255558828550000000000000000000000000000000000000000000000000000000000000000
00077000559499555575575555b33b5555c1c1555508085555e2e255558828550000000000000000000000000000000000000000000000000000000000000000
00700700059999500577775005bbbb5005cccc50f500005f05eeee50058888500000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00050000184501644014440114300f4300d4300c4300a430094300843006430054300343003430014000140000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000183601836018350183301832018310210001e0001a0001600001000010000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002436024360243502433024300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002436028360283502833028300280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000263602a3602a3502a3302a3002c3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000283602d3602d3502d3302d3002c3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002a36032360323503233032300143000930015400000001340012400114001040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002b36034360343503433034300143000930015400000001340012400114001040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002b360373603735037330373003a3000930015400000001340012400114001040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200003c560367603675036730367003a3000930015400000001340012400114001040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001d7501f75021750257502b7503f3303f32038310017000370000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

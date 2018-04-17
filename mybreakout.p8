pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--goals
--variable scope in functions
--fix level clear after brick explode
--powerups
--	speed down
--	expand/reduct
--	megaball
--	multiball
--juicyness
--	particles
--	screen shake
--	arrow animation
--	text blinking
--high score 
--game complete

--[[

	--game notes--
-picking up a powerup immediately cancels any other powerup
-lives reset each time a stage changes

  ]]

function _init()
	cls()

	ball =	{
		x = 1,
		y = 40,
		dx, --initialized in serveball()
		dy, --initialized in serveball()
		angle = 1,
		radius = 2,
		colour = 10
	}

	paddle = {
		x = 30,
		y = 120,
		dx = 0,
		speed = 2.5,
		width = 24,
		height = 3,
		colour = 7,
		sticky = true
	}

	brick = {
		x = {},
		y = {},
		visible = {},
		type = {},
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
		x = {},
		y = {},
		visible = {},
		type = {},
		speed = 0.6,
		width = 8,
		height = 6
	}

	powerup = {
		type = 0,
		clock = 0
	}

	player = {
		points, --initialized in startgame()
		combo, --initialized in startgame()
		lives --initialized in startgame()
	}

	manager = {
		mode = "startmenu",
		levelnumber, --initialized in startgame()
		debug = true ,
		debugvalue = 0 --change value at --top screen banner
	}

	level = {
		--x = empty space
		--/ = new row
		--b = normal brick
		--i = indestructable brick
		--h = hardened brick
		--s = exploding brick
		--p = powerup brick
		
		"b9b//p9p", --test level
		--"////xb8xxb8", --lvl 1
		--"//xbxbxbxbxbxxbxbxbxbxbxxbxbxbxbxbxxbxbxbxbxbx", --lvl 2
		--"//b9bb9bb9bb9b", --lvl 3
		--"/bxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxb", --lvl 4
		--"ib3xb3iib3xb3i/ib3xb3iib3xb3i/ib3xb3iib3xb3i", --lvl 5
		--"ib3xb3iibbsbxbsbbi/ib3xb3iibsbbxbbsbi/ib3xb3iibbsbxbsbbi", --lvl 6
		--"////x4b/i9x", --bonus lvl?

		--""
	}

	playarea = {
		left = 2,
		right = 125,
		ceiling = 9,
		floor = 135
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
		if paddle.sticky then
			ball.dx = -1
		end
	end	
	--right
	if btn(1) then
		paddle.dx = paddle.speed
		buttonispressed = true
		if paddle.sticky then
			ball.dx = 1
		end
	end

	--launch ball off paddle
	if paddle.sticky and btnp(5) then
		paddle.sticky = false
	end
	
	--friction
	if not (buttonispressed) then
		paddle.dx /= 1.2
	end
	
	--paddle speed
	paddle.x += paddle.dx

	--stop paddle at screen ddge
 	paddle.x =	mid(2,paddle.x,125-paddle.width)
	
	--stick ball to paddle
	if paddle.sticky then
		stickyballposition()
		ball.dy = -1 --ensures serve preview points in correct direction
	else
		--regular ball physics
		nextx = ball.x + ball.dx
		nexty = ball.y + ball.dy
		
		--check walls
		if nextx > playarea.right or nextx < playarea.left then
			nextx = mid(playarea.left,nextx,playarea.right)
			ball.dx = -ball.dx
		sfx(01)
		end
		--check ceiling
		if nexty < playarea.ceiling then
			nexty = mid(playarea.ceiling,nexty,playarea.floor)
			ball.dy = -ball.dy
		sfx(01)
		end

		--checks for paddle collision	
		if hitbox(nextx,nexty,paddle.x,paddle.y,paddle.width,paddle.height) then
			--find out which direction to deflect
			if deflection(ball.x,ball.y,ball.dx,ball.dy,paddle.x,paddle.y,paddle.width,paddle.height) then	
				--ball hits paddle on the side
				ball.dx = -ball.dx
				--resets ball position to edge of paddle on collision to prevent strange behavior
				if ball.x < paddle.x+paddle.width/2 then
					--left
					nextx = paddle.x - ball.radius
				else
					--right
					nextx = paddle.x + paddle.width + ball.radius
				end
			else
				--ball hits paddle on the top/bottom
				ball.dy = -ball.dy
				--sets ball to top of paddle to prevent it getting stuck inside
				if ball.y > paddle.y then
					--bottom
					nexty = paddle.y + paddle.height + ball.radius
				else
					--top
					nexty = paddle.y - ball.radius
					--change angle
					if abs(paddle.dx) > 2 then
						if sign(paddle.dx) == sign(ball.dx) then
							--flatten angle
							setangle(mid(0,ball.angle-1,2))
						else
							if ball.angle == 2 then
								--reverse direction because angle is already increased
								ball.dx *= -1
							else
								--increase angle
								setangle(mid(0,ball.angle+1,2))
							end
						end
					end
				end
			end
			player.combo = 0 --resets combo when ball hits paddle
			sfx(01)

			--catch powerup
			if powerup.type == 3 then
				paddle.sticky = true
			end
		end
		
		--checks for brick collision
		local brickhit = false --ensures correct reflection when two bricks hit at same time

		for i=1,#brick.x do
			if brick.visible[i] and hitbox(nextx,nexty,brick.x[i],brick.y[i],brick.width,brick.height) then
				--find out which direction to deflect
				if not(brickhit) then
					--find out which direction to deflect
					if deflection(ball.x,ball.y,ball.dx,ball.dy,brick.x[i],brick.y[i],brick.width,brick.height) then	
						ball.dx = -ball.dx
					else
						ball.dy = -ball.dy
					end
				end
				--brick is hit
				brickhit = true
				hitbrick(i,true)
			end
		end	

		ball.x = nextx
		ball.y = nexty
		
		--check floor
		if nexty > playarea.floor then
			sfx(00)
			player.lives -= 1
			if player.lives < 0 then
				gameover()
			else
				serveball()
			end
		end	
	end

	--move pills
	for i=1,#pill.x do
		if pill.visible[i] then
			pill.y[i]+=pill.speed
			if pill.y[i] > playarea.floor then
				pill.visible[i] = false
			end
			if boxcollide(pill.x[i],pill.y[i],pill.width,pill.height,paddle.x,paddle.y,paddle.width,paddle.height) then
				sfx(10)
				powerupget(pill.type[i])
				pill.visible[i] = false
			end
		end
	end

	checkforexplosions()

	if levelfinished() then
		_draw() --final draw to clear last brick
		levelover()
	end

	--powerup clock update
	if powerup.clock >= 0 then
		powerup.clock -= 1 
		if powerup.clock <= 0 then
			powerup.type = 0
		end
	end
end

function draw_game()
	cls(1)
	circfill(ball.x,ball.y,ball.radius,ball.colour)
	rectfill(paddle.x,paddle.y,paddle.x+paddle.width,paddle.y+paddle.height,paddle.colour)

	--serve preview
	if paddle.sticky then
		line(ball.x+ball.dx*4,ball.y+ball.dy*4,ball.x+ball.dx*6,ball.y+ball.dy*6,ball.colour)
	end
	
	--draw bricks
	for i=1,#brick.x do
		if brick.visible[i] then
			local brickcolour
			if brick.type[i] == "b" then
				brickcolour = brick.colour.b
			elseif brick.type[i] == "i" then
				brickcolour = brick.colour.i
			elseif brick.type[i] == "h" then
				brickcolour = brick.colour.h
			elseif brick.type[i] == "s" then
				brickcolour = brick.colour.s
			elseif brick.type[i] == "zz" or brick.type[i] == "z" then
				brickcolour = brick.colour.z
			elseif brick.type[i] == "p" then
				brickcolour = brick.colour.p
			end
			rectfill(brick.x[i],brick.y[i],brick.x[i]+brick.width,brick.y[i]+brick.height,brickcolour)
		end
	end

	--draw pills
	for i=1,#pill.x do
		if pill.visible[i] then
			if pill.type[i] == 5 then
				palt(0,false) --display black (0)
				palt(15,true) --don't display creme (15)
			end
			spr(pill.type[i],pill.x[i],pill.y[i])
			palt() --reset palette
		end
	end

	--top screen banner
	rectfill(0,0,128,6,0)
	if manager.debug then
		manager.debugvalue = powerup.clock
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
	if #brick.visible == 0 then return false end --don't finish level if explicitly empty
	for i=1,#brick.visible do
		if brick.visible[i] and brick.type[i] != "i" then
			return false
		end
	end
	return true
end

function resetpills()
	--empty pill tables
	pill.x = {}
	pill.y = {}
	pill.visible = {}
	pill.type = {}
end

function powerupget(_powerup)
	powerup.clock = 600
	if _powerup == 1 then
		--slow down
		powerup.type = 1
	elseif _powerup == 2 then
		--life up
		powerup.type = 0
		player.lives += 1
	elseif _powerup == 3 then
		--catch
		powerup.type = 3
	elseif _powerup == 4 then
		--expand
		powerup.type = 4
	elseif _powerup == 5 then
		--reduce
		powerup.type = 5
	elseif _powerup == 6 then
		--megaball
		powerup.type = 6
	elseif _powerup == 7 then
		--multiball
		powerup.type = 7
	end
end

function addbrick(_index,_type)
	add(brick.x,4+((_index-1)%11)*(brick.width+2))
	add(brick.y,20+flr((_index-1)/11)*(brick.height+2))
	add(brick.visible,true)
	add(brick.type,_type)
end

function buildbricks(lvl)
	local character, last, j, k

	j = 0
	for i=1,#lvl do
		j += 1
		character = sub(lvl,i,i)
		if character == "b"
		or character == "i"
		or character == "h"
		or character == "s"
		or character == "p" then
			last = character
			addbrick(j,character)
		elseif character == "x" then
			last = "x"
		elseif character == "/" then
			j = (flr((j-1)/11)+1)*11
		elseif character >= "1" and character <= "9" then
			for k=1,character+0 do
				if last == "b"
				or last == "i"
				or last == "h"
				or last == "s"
				or last == "p" then
					addbrick(j,last)
				elseif last == "x" then
					--create empty space
				end
				j += 1
			end
			j -= 1 --prevents skipping a line
		end
	end
end

function hitbrick(_i,_combo)
	if brick.type[_i] == "b" then
		sfx(02+player.combo)
		brick.visible[_i] = false
		player.points += 10*(player.combo+1)
		combo(_combo)
	elseif brick.type[_i] == "i" then
		sfx(09)
	elseif brick.type[_i] == "h" then
		sfx(09)
		brick.type[_i] = "b"
	elseif brick.type[_i] == "s" then
		sfx(02+player.combo)
		brick.type[_i] = "zz"				
		player.points += 10*(player.combo+1)
		combo(_combo)
	elseif brick.type[_i] == "p" then
		sfx(02+player.combo)
		brick.visible[_i] = false				
		player.points += 10*(player.combo+1)
		combo(_combo)
		spawnpill(brick.x[_i],brick.y[_i])
	end
end

function spawnpill(_brickx,_bricky)
	add(pill.x,_brickx)
	add(pill.y,_bricky)
	add(pill.visible,true)
	--add(pill.type,flr(rnd(7))+1)
	add(pill.type,3)

--[[
	works in pico-8 but probably not best practice...

	pill.x[#pill.x+1] = _brickx
	pill.y[#pill.y+1] = _bricky
	pill.visible[#pill.visible+1] = true
	pill.type[#pill.type+1] = _pilltype
  ]]
end

function combo(_istrue)
	if _istrue then
		player.combo += 1
		player.combo = mid(1,player.combo,6) --make sure combo doesn't exceed 7
	end
end

function checkforexplosions()
	for i=1,#brick.x do
		if brick.type[i] == "z" then
			brickexplode(i)
		end
	end
	for i=1,#brick.x do
		if brick.type[i] == "zz" then
			brick.type[i] = "z"
		end
	end
end

function brickexplode(_i)
	brick.visible[_i]=false
	for j=1,#brick.x do
		if j !=_i 
		and brick.visible[j] 
		and abs(brick.x[j]-brick.x[_i]) <= (brick.width+2)
		and abs(brick.y[j]-brick.y[_i]) <= (brick.height+2)
		then
			hitbrick(j,false)
		end
	end 
end

function serveball()
	stickyballposition()
	ball.dx = 1
	ball.dy = -1
	ball.angle = 1
	paddle.sticky = true
	player.combo = 0
	powerup.type = 0
	powerup.clock = 0
	resetpills();
end

function stickyballposition()
	ball.x = paddle.x + flr(paddle.width/2)
	ball.y = paddle.y - ball.radius - 1
end

function setangle(angle)
	ball.angle = angle
	if angle == 2 then
		ball.dx = 0.60*sign(ball.dx)
		ball.dy = 1.40*sign(ball.dy)
	elseif angle == 0 then
		ball.dx = 1.40*sign(ball.dx)
		ball.dy = 0.60*sign(ball.dy)
	else
		ball.dx = 1*sign(ball.dx)
		ball.dy = 1*sign(ball.dy)
	end
end

function sign(number)
	if number < 0 then
		return -1
	elseif number > 0 then
		return 1
	else
		return 0
	end
end

--collosion detection
function hitbox(bx,by,x,y,width,height)
	if (by-ball.radius > y + height) then
		return false
	end
	if (by+ball.radius < y) then
		return false
	end
	if (bx-ball.radius > x + width) then
		return false
	end
	if (bx+ball.radius < x) then
		return false
	end
	return true
end

--checks for collision between colliding boxes (pill/paddle)
function boxcollide(bx1,by1,width1,height1,bx2,by2,width2,height2)
	if (by1 > by2 + height2) then
		return false
	end
	if (by1 + height1 < by2) then
		return false
	end
	if (bx1 > bx2 + width2) then
		return false
	end
	if (bx1 + width1 < bx2) then
		return false
	end
	return true
end

--checks for correct angle deflection
function deflection(bx,by,bdx,bdy,tx,ty,tw,th)
	local slope = bdy / bdx
	local cx, cy

	if bdx == 0 then
		--moving vertically
		return false
	elseif bdy == 0 then
		--moving horizontally
		return true
	elseif slope > 0 and bdx > 0 then
		cx = tx - bx
		cy = ty - by
		return cx > 0 and cy/cx < slope
	elseif slope < 0 and bdx > 0 then
		cx = tx - bx
		cy = ty + th - by
		return cx > 0 and cy/cx >= slope
	elseif slope > 0 and bdx < 0 then
		cx = tx + tw - bx
		cy = ty + th - by
		return cx < 0 and cy/cx <= slope
	else
		cx = tx + tw - bx
		cy = ty - by
		return cx < 0 and cy/cx >= slope
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

pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--goals
--levels
--	level finished
--	next level
--different bricks
--powerups
--juicyness
--	particles
--	screen shake
--	arrow animation
--	text blinking
--high score 

function _init()
	cls()

	ball =	{
		x = 1,
		y = 40,
		dx = 1,
		dy = 1,
		angle = 1,
		radius = 2,
		color = 10
	}

	paddle = {
		x = 30,
		y = 120,
		dx = 0,
		speed = 2.5,
		width = 24,
		height = 3,
		color = 7,
		sticky = true
	}

	brick = {
		x = {},
		y = {},
		visible = {},
		width = 9,
		height = 4,
		color = 14
	}

	player = {
		points, --initiallized in startgame()
		combo, --initiallized in startgame()
		lives --initiallized in startgame()
	}

	manager = {
		mode = "startmenu",
		debug = ""
	}

	level = {
		empty = "",
		one = "b9bb9bb9bb9bb9bb9b",
		two = "bxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbx",
		three = "xb3xb3xbbxbbxbbxbb/xb3xb3xbbxbbxbbxbb/xb3xb3xbbxbbxbbxbb"
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
		update_startgame()
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
		draw_startgame()
	elseif manager.mode == "gameover" then
		draw_gameover()
	end
end

function startgame()
	manager.mode = "game"
	player.points = 0
	player.combo = 0 --combo chain multiplier
	player.lives = 3
	buildbricks(level.one)
	serveball()
end

function update_startgame()
	if btn(5) then
		startgame()
	end
end

function draw_startgame()
	rectfill(0,0,128,128,5)
	print("breakout",48,50,7)
	print("press ❎ to start",31,70)
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
		ball.x = paddle.x + flr(paddle.width/2)
		ball.y = paddle.y - ball.radius - 1
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
				player.points += 10*(player.combo+1)
				player.combo += 1
				player.combo = mid(1,player.combo,6) --make sure combo doesn't exceed 7
				brick.visible[i] = false
				sfx(02+player.combo)
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
end

function draw_game()
	cls(1)
	circfill(ball.x,ball.y,ball.radius,ball.color)
	rectfill(paddle.x,paddle.y,paddle.x+paddle.width,paddle.y+paddle.height,paddle.color)

	--serve preview
	if paddle.sticky then
		line(ball.x+ball.dx*4,ball.y-ball.dy*4,ball.x+ball.dx*6,ball.y-ball.dy*6,ball.color)
	end
	
	--draw bricks
	for i=1,#brick.x do
		if brick.visible[i] then
			rectfill(brick.x[i],brick.y[i],brick.x[i]+brick.width,brick.y[i]+brick.height,brick.color)
		end
	end

function levelover()
	manager.mode = "levelover"
end

function gameover()
	manager.mode = "gameover"
end

function update_gameover()
	--cls()
	if btn(5) then
		startgame()
	end
end

	rectfill(0,0,128,6,0)
	if manager.debug != "" then
		print("debug:"..manager.debug,0,0,7)
	else
		print("lives:"..player.lives,0,0,7)
		print("points:"..player.points,68,0,7)
		print("combo:"..player.combo,34,0,7)
	end
end

function draw_gameover()
	--cls()
	rectfill(0,49,127,62,0)
	print("gameover!",48,50,7)
	print("press ❎ to restart",28,57,6)
end

function buildbricks(lvl)
	local character, last, j, k

	j = 0
	for i=1,#lvl do
		j += 1
		character = sub(lvl,i,i)
		if character == "b" then
			last = "b"
			add(brick.x,4+((j-1)%11)*(brick.width+2))
			add(brick.y,20+flr((j-1)/11)*(brick.height+2))
			add(brick.visible,true)
		elseif character == "x" then
			last = "x"
		elseif character == "/" then
			j = (flr((j-1)/11)+1)*11
		elseif character >= "1" and character <= "9" then
			--manager.debug = character
			for k=1,character+0 do
				if last == "b" then
					add(brick.x,4+((j-1)%11)*(brick.width+2))
					add(brick.y,20+flr((j-1)/11)*(brick.height+2))
					add(brick.visible,true)
				elseif last == "x" then
					--create empty space
				end
				j += 1
			end
			j -= 1 --prevents skipping a line
		end
	end
end

function serveball()
	paddle.sticky = true
	ball.x = paddle.x + flr(paddle.width/2)
	ball.y = paddle.y - ball.radius - 1
	ball.dx = 1
	ball.dy = 1
	ball.angle = 1
	player.combo = 0
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

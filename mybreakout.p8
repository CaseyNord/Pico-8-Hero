pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- goals --
--variable scope in functions
--fix level clear after brick explode
--juicyness
--	particles
--	- death particles
--	- collision particles
-- 	- pickup particles
--	- explosions
--high score 
--ui
--	powerup messages
--	powerup percentage bar
--better collision
--gameplay tweaks
--	- smaller paddle
--game complete

--[[

game notes:

-only one powerup can be active at a time
-this is because of the kind property, it is setup to where only one can be active at a time
-this could possible be changed if the decision is made to make it possible to have multiple certain
-powerups active simultaneously

]]

-->8
-- init --

function _init()
	cls()

	ball={
		radius=2,
		colour=10
	}

	paddle={
		x=30,
		y=120,
		dx=0,
		speed=2.5,
		width=24,
		base_width = 24,
		height=3,
		colour=7,
		sticky --intialized in serve_ball()
	}

	brick={
		width=9,
		height=4,
		colour={
			b=14,
			i=6,
			h=15,
			s=9,
			z=8,
			p=12
		}
	}

	pill={
		speed=0.6,
		width=8,
		height=6
	}

	powerup={
		multiplier=1,
		type=0,
		timer={
			slowdown, --intialized in serve_ball()
			expand, --intialized in serve_ball()
			reduce, --intialized in serve_ball()
			megaball --intialized in serve_ball()
		}
	}

	player={
		points, --initialized in start_game()
		combo, --initialized in start_game()
		lives --initialized in start_game()
	}

	manager={
		mode="startmenu",
		level_number, --initialized in start_game()
		debug=false
	}
	
	playarea={
		left=2,
		right=125,
		ceiling=9,
		floor=135
	}

	level={
		--x = empty space
		--/ = new row
		--b = normal brick
		--i = indestructable brick
		--h = hardened brick
		--s = exploding brick
		--p = powerup brick
		
		"b9bx9xb9bx9xb9b",
		"s9s/xixbbpbbxix/hphphphphph/bsbsbsbsbsb",
		"b9b/xixbbpbbxix/hphphphphph",
		"i9i//h9h//b9b//p9p", --test level one
		"////xb8xxb8", --lvl 1
		"//xbxbxbxbxbxxbxbxbxbxbxxbxbxbxbxbxxbxbxbxbxbx", --lvl 2
		"//b9bb9bb9bb9b", --lvl 3
		"/bxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxb", --lvl 4
		"ib3xb3iib3xb3i/ib3xb3iib3xb3i/ib3xb3iib3xb3i", --lvl 5
		"ib3xb3iibbsbxbsbbi/ib3xb3iibsbbxbbsbi/ib3xb3iibbsbxbsbbi", --lvl 6
		--"////x4b/i9x", --bonus lvl?
		--"" --empty level?
	}

	-- global effect variables --
	shake=0
	countdown=-1
	arrow_anim_spd=30
	arrow_frame=0
	arrow_mult_01=1
	arrow_mult_02=1
	gameover_countdown=-1
	blink_frame=0
	blink_speed=9
	blink_color=7
	blink_seq_index=1
	blink_seq_01={3,11,7,11}
	blink_seq_02={0,5,6,7,6,5}
	fade_percentage=0

	--global particle table
	--(particles are handled by functions)
	ptcl={}

	last_hit_x=0
	last_hit_y=0
end

-->8
-- update --

function _update60()
	if manager.mode=="startmenu" then
		blink(blink_seq_01)
	elseif manager.mode=="gameover" then
		blink(blink_seq_02)
	end

	--always update particles so they can always be used!
	update_particles()
	screen_shake()

	if manager.mode=="game" then
		update_game()
	elseif manager.mode=="startmenu" then
		update_start_menu()
	elseif manager.mode=="levelover" then
		update_level_over()
	elseif manager.mode=="gameoverwait" then
		update_gameoverwait()
	elseif manager.mode=="gameover" then
		update_gameover()
	end
end

-- update functions --

function update_start_menu()
	--blinking effects at game start
	if countdown<0 then
		if btnp(5) then
			countdown=80
			blink_speed=1
			sfx(11)
		end
	else
	countdown-=1
	fade_percentage=(80-countdown)/80
		if countdown<=0 then
			countdown=-1
			blink_speed=9
			pal()
			start_game()
		end
	end
end

function update_level_over()
	if btnp(5) then
		next_level()
	end
end

function update_gameoverwait()
    gameover_countdown-=1
    if gameover_countdown<=0 then
        gameover_countdown=-1
        manager.mode="gameover"
    end
end

function update_gameover()
	--blinking effects at gameover
	if gameover_countdown<0 then
		if btnp(5) then
			gameover_countdown=80
			blink_speed=1
			sfx(11)
		end
	else
		gameover_countdown-=1
		fade_percentage=(80-gameover_countdown)/80
		if gameover_countdown<= 0then
			gameover_countdown=-1
			blink_speed=9
			pal()
			start_game()
		end
	end
end

function update_game()
	--todo: menu may not currently appear when game is cleared because
	--		it doesn't have fade if.  check into this.  if that is the
	--		case write this into a method so it can be called there too
	--fade in game
	if fade_percentage~=0 then
		fade_percentage-=0.05
		if fade_percentage<0 then
			fade_percentage=0
		end
	end

	local _button_is_pressed=false
	--left
	if btn(0) then
		paddle.dx=paddle.speed*-1
	 	_button_is_pressed=true
		sticky_aim(-1)
	end	
	--right
	if btn(1) then
		paddle.dx=paddle.speed
		_button_is_pressed=true
		sticky_aim(1)
	end

	--launch ball off paddle
	if  btnp(5) then
		release_current_sticky()
	end
	
	--paddle friction slowdown
	if not (_button_is_pressed) then
		paddle.dx/=1.2
	end
	
	--paddle speed
	paddle.x+=paddle.dx

	--expand/reduce paddle powerups
	if powerup.timer.expand>0 then
		paddle.width=flr(paddle.base_width*1.5)
	elseif powerup.timer.reduce>0 then
		paddle.width=flr(paddle.base_width/2)
		powerup.multiplier=2
	else
		paddle.width=paddle.base_width
		powerup.multiplier=1
	end

	--stop paddle at screen edge
 	paddle.x=mid(2,paddle.x,125-paddle.width)

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
			get_powerup(pillobj[i].type)
			del(pillobj,pillobj[i])
		end
	end

	check_for_explosions()

	if level_finished() then
		_draw() --final draw to clear last brick
		level_over()
	end

	--powerup clock update
	if powerup.timer.slowdown>0 then
		powerup.timer.slowdown-=1
	end
	if powerup.timer.expand>0 then
		powerup.timer.expand-=1
	end
	if powerup.timer.reduce>0 then
		powerup.timer.reduce-=1
	end
	if powerup.timer.megaball>0 then
		powerup.timer.megaball-=1
	end

	--animate brick rebound
	animate_bricks()

end

function updateball(_i)
	local _ballobj=ballobj[_i]
	local _nextx,_nexty

	--stick ball to paddle
	if _ballobj.sticky then
		_ballobj.x=paddle.x+stickyx
		_ballobj.y=paddle.y-ball.radius-1
	else
		--regular ball physics/slowdown powerup
		if powerup.timer.slowdown>0 then
			_nextx=_ballobj.x+(_ballobj.dx/2)
			_nexty=_ballobj.y+(_ballobj.dy/2)
		else
			_nextx=_ballobj.x+_ballobj.dx
			_nexty=_ballobj.y+_ballobj.dy
		end

		--check walls
		if _nextx>playarea.right or _nextx<playarea.left then
			_nextx=mid(playarea.left,_nextx,playarea.right)
			_ballobj.dx=-_ballobj.dx
		sfx(01)
		end
		--check ceiling
		if _nexty<playarea.ceiling then
			_nexty=mid(playarea.ceiling,_nexty,playarea.floor)
			_ballobj.dy=-_ballobj.dy
		sfx(01)
		end

		--checks for paddle collision
		if hitbox(_nextx,_nexty,paddle.x,paddle.y,paddle.width,paddle.height) then
			--find out which direction to deflect
			if deflection(_ballobj.x,_ballobj.y,_ballobj.dx,_ballobj.dy,paddle.x,paddle.y,paddle.width,paddle.height) then	
				--ball hits paddle on the side
				_ballobj.dx=-_ballobj.dx
				--resets ball position to edge of paddle on collision to prevent strange behavior
				if _ballobj.x<paddle.x+paddle.width/2 then
					--left
					_nextx=paddle.x-ball.radius
				else
					--right
					_nextx=paddle.x+paddle.width+ball.radius
				end
			else
				--ball hits paddle on the top/bottom
				_ballobj.dy=-_ballobj.dy
				--sets ball to top of paddle to prevent it getting stuck inside
				if _ballobj.y>paddle.y then
					--bottom
					_nexty=paddle.y+paddle.height+ball.radius
				else
					--top
					_nexty=paddle.y-ball.radius
					--change angle
					if abs(paddle.dx)>2 then
						if sign(paddle.dx)==sign(_ballobj.dx) then
							--flatten angle
							set_angle(_ballobj,mid(0,_ballobj.angle-1,2))
						else
							if _ballobj.angle==2 then
								--reverse direction because angle is already increased
								_ballobj.dx*=-1
							else
								--increase angle
								set_angle(_ballobj,mid(0,_ballobj.angle+1,2))
							end
						end
					end
				end
			end
			player.combo=0 --resets combo when ball hits paddle
			sfx(01)

			--catch powerup
			if paddle.sticky and _ballobj.dy<0 then
				release_current_sticky()
				paddle.sticky=false
				_ballobj.sticky=true
				stickyx=_ballobj.x-paddle.x
			end
		end
		
		--checks for brick collision
		local _brick_hit=false --ensures correct reflection when two bricks hit at same time

		for i=1,#brickobj do
			if brickobj[i].visible and hitbox(_nextx,_nexty,brickobj[i].x,brickobj[i].y,brick.width,brick.height) then
				--find out which direction to deflect
				if not(_brick_hit) then
					if powerup.type==6 and brickobj[i].type=="i" or powerup.type~=6then
						--save velocity of ball to apply to particles to launch
						--them in the same direction
						last_hit_x=_ballobj.dx
						last_hit_y=_ballobj.dy
						
						--find out which direction to deflect
						if deflection(_ballobj.x,_ballobj.y,_ballobj.dx,_ballobj.dy,brickobj[i].x,brickobj[i].y,brick.width,brick.height) then	
							_ballobj.dx=-_ballobj.dx
						else
							_ballobj.dy=-_ballobj.dy
						end
					end
				end
				--brick is hit
				_brick_hit=true
				hit_brick(i,true)
			end
		end	

		--update coordinates to move ball
		_ballobj.x=_nextx
		_ballobj.y=_nexty

		--update ball trail
		spawn_trail(_nextx,_nexty)
		
		--check floor
		if _nexty>playarea.floor then
			sfx(00)
			--lose multiball
			if #ballobj>1 then
				shake+=0.1
				del(ballobj,_ballobj)
			else
				--death
				shake+=0.3
				player.lives-=1
				if player.lives<0 then
					gameover()
				else
					serve_ball()
				end
			end
		end	
	end
end

-->8
-- draw --

function _draw()
	if manager.mode=="game" then
		draw_game()
	elseif manager.mode=="startmenu" then
		draw_start_menu()
	elseif manager.mode=="levelover" then
		draw_level_over()
	elseif manager.mode=="gameoverwait" then
		draw_game()
	elseif manager.mode=="gameover" then
		draw_gameover()
	end

	--screenfade
	pal()
	if fade_percentage~=0 then	
		fadepal(fade_percentage)
	end
end

-- draw functions --

function draw_start_menu()
	rectfill(0,0,128,128,5)
	print("breakout",48,50,7)
	print("press ❎ to start",31,70,blink_color)
end

function draw_level_over()
	rectfill(0,49,127,62,0)
	print("stage clear!",40,50,7)
	print("press ❎ to continue",24,57,6)
end

function draw_gameover()
	rectfill(0,49,127,62,0)
	print("gameover!",48,50,7)
	print("press ❎ to restart",28,57,blink_color)
end

function draw_game()
	rectfill(0,0,127,127,1)

	--draw bricks
	for i=1,#brickobj do
		local _b=brickobj[i]
		if _b.visible or _b.flash>0 then
			local _brick_colour
			if _b.flash>0 then
				_brick_colour=7
				_b.flash-=1
			elseif _b.type=="b" then
				_brick_colour = brick.colour.b
			elseif _b.type=="i" then
				_brick_colour = brick.colour.i
			elseif _b.type=="h" then
				_brick_colour = brick.colour.h
			elseif _b.type=="s" then
				_brick_colour = brick.colour.s
			elseif _b.type=="zz" or _b.type=="z" then
				_brick_colour = brick.colour.z
			elseif _b.type=="p" then
				_brick_colour = brick.colour.p
			end
			local _bx=_b.x+_b.offset_x
			local _by=_b.y+_b.offset_y
			rectfill(_bx,_by,_bx+brick.width,_by+brick.height,_brick_colour)
		end
	end

	--draw particles
	draw_particles()

	--draw pills
	for i=1,#pillobj do
		if pillobj[i].type==5 then
			palt(0,false) --display black (0)
			palt(15,true) --don't display creme (15)
		end
		spr(pillobj[i].type,pillobj[i].x,pillobj[i].y)
		palt() --reset palette
	end

	--draw balls
	for i=1,#ballobj do
		circfill(ballobj[i].x,ballobj[i].y,ball.radius,ball.colour)
	
		if ballobj[i].sticky then
			--animated serve preview dots
			animate_arrow()
			--dot one
			pset(ballobj[i].x+ballobj[i].dx*4*arrow_mult_01,
			     ballobj[i].y+ballobj[i].dy*4*arrow_mult_01,
				 ball.colour)
			--dot two
			pset(ballobj[i].x+ballobj[i].dx*4*arrow_mult_02,
			     ballobj[i].y+ballobj[i].dy*4*arrow_mult_02,
				 ball.colour)
			--serve preview line (not getting used)
			-- line(ballobj[i].x+ballobj[i].dx*4*arrow_mult,
			--      ballobj[i].y+ballobj[i].dy*4*arrow_mult,
			-- 	 ballobj[i].x+ballobj[i].dx*6*arrow_mult,
			-- 	 ballobj[i].y+ballobj[i].dy*6*arrow_mult,
			-- 	 ball.colour)
		end
	end

	--draw paddle
	rectfill(paddle.x,paddle.y,paddle.x+paddle.width,paddle.y+paddle.height,paddle.colour)

	--top screen banner (ui)
	rectfill(0,0,128,6,0)
	if manager.debug then
		manager.debug_value=powerup.timer
		print("cpu:"..stat(1),0,0,7)
	else
		print("lives:"..player.lives,0,0,7)
		print("points:"..player.points,68,0,7)
		print("combo:"..player.combo,34,0,7)
	end
end

-->8
-- functions --

--game management

function start_menu()
	manager.mode="startmenu"
end

function start_game()
	manager.mode="game"
	manager.level_number=1
	player.points=0
	player.combo=0 --combo chain multiplier
	player.lives=3
	build_bricks(level[manager.level_number])
	serve_ball()
end

function level_over()
	manager.mode="levelover"
end

function next_level()
	manager.level_number+=1
	if manager.level_number>#level then
		--game has been completed
		return start_menu()
	end
	manager.mode="game"
	player.combo=0 --combo chain multiplier
	player.lives=3
	build_bricks(level[manager.level_number])
	serve_ball()
end

function gameover()
	manager.mode="gameoverwait"
	gameover_countdown=60
	blink_frame=0 --resetting this prevents a green frame from appearing
	blink_speed=11
end

function level_finished()
	if #brickobj==0 then return false end --don't finish level if explicitly empty
	for i=1,#brickobj do
		if brickobj[i].visible and brickobj[i].type~="i" then
			return false
		end
	end
	return true
end

--ball mechanics

function serve_ball()
	ballobj={}
	ballobj[1]=new_ball()
	ballobj[1].x=paddle.x+flr(paddle.width/2)
	ballobj[1].y=paddle.y-ball.radius
	ballobj[1].dx=1
	ballobj[1].dy=-1
	ballobj[1].angle=1 
	ballobj[1].sticky=true

	paddle.sticky=false
	stickyx=flr(paddle.width/2) --necessary here for catch powerup

	player.combo=0
	powerup.type=0
	powerup.timer.slowdown=0
	powerup.timer.expand=0
	powerup.timer.reduce=0
	powerup.timer.megaball=0
	reset_pills();
end

function sticky_aim(_sign)
	for i=1,#ballobj do
		if ballobj[i].sticky then
			ballobj[i].dx=abs(ballobj[i].dx)*_sign
		end
	end
end

function release_current_sticky()
	for i=1,#ballobj do
		if ballobj[i].sticky then
			ballobj[i].x=mid(playarea.left,ballobj[i].x,playarea.right)
			ballobj[i].sticky=false
		end
	end
end

function combo(_istrue)
	if _istrue then
		player.combo+=1
		player.combo=mid(1,player.combo,6) --make sure combo doesn't exceed 7
	end
end

function new_ball()
	local _ball={}
	_ball.x=0
	_ball.y=0
	_ball.dx=0
	_ball.dy=0
	_ball.angle=1
	_ball.sticky=false
	return _ball
end

function copy_ball(_ball)
	local _new_ball={}
	_new_ball.x=_ball.x
	_new_ball.y=_ball.y
	_new_ball.dx=_ball.dx
	_new_ball.dy=_ball.dy
	_new_ball.angle=_ball.angle
	_new_ball.sticky=_ball.sticky
	return _new_ball
end

function multi_ball()
	--todo: there is a bug here where the random function doesn't seem to always return
	--a valid ball to split, meaning sometimes a multiball pickup won't do anything
	local _ballobjindex=flr(rnd(#ballobj))+1
	local _ogball=copy_ball(ballobj[_ballobjindex]) --index a random ball 
	local _ball2=_ogball 
	--local _ball3 = copy_ball(ballobj[1])
	
	if _ogball.angle==0 then
		set_angle(_ball2,2)
		--set_angle(_ball3,2)
	elseif _ogball.angle==1 then
		set_angle(_ogball,0)
		set_angle(_ball2,2)
		--set_angle(_ball3,0)
	else
		set_angle(_ball2,0)
		--set_angle(_ball3,1)
	end

	_ball2.stuck=false --prevents unwanted paddle sticking behavior
	ballobj[#ballobj+1]=_ball2
	--ballobj[#ballobj+1]=_ball3
end

--powerups

function spawn_pill(_brickx,_bricky)
	local _pillobj={}
	_pillobj.x=_brickx
	_pillobj.y=_bricky
	--_pillobj.type=flr(rnd(7))+1
	_pillobj.type=3
	--[[ test powerups
	t=flr(rnd(2))
	if t==1 then
		_pillobj.type=3
	else
		_pillobj.type=7
	end
	]]
	
	add(pillobj,_pillobj)
end

function reset_pills()
	--empty pill tables
	pillobj={}
end

function get_powerup(_powerup)
	if _powerup==1 then
		--slowdown
		powerup.type=1
		powerup.timer.slowdown=600
	elseif _powerup==2 then
		--lifeup
		powerup.type=0
		player.lives+=1
	elseif _powerup==3 then
		--catch
		powerup.type=3
		paddle.sticky=true
		--prevents 'handoff' if a ball is already stuck to paddle
		for i=1,#ballobj do
			if ballobj[i].sticky then
				paddle.sticky=false
			end
		end
	elseif _powerup==4 then
		--expand
		powerup.type=4
		powerup.timer.reduce=0
		powerup.timer.expand=600
	elseif _powerup==5 then
		--reduce
		powerup.type=5
		powerup.timer.expand=0
		powerup.timer.reduce=600
	elseif _powerup==6 then
		--megaball
		powerup.type=6
		powerup.timer.megaball=600
	elseif _powerup==7 then
		--multiball
		powerup.type=7
		multi_ball()
	end
end

--not collision, rather managing what happens gamewise when bricks are hit
function hit_brick(_i,_combo)
	local flash_timer=10

	--regular brick
	if brickobj[_i].type=="b" then
		sfx(02+player.combo)
		shatter_brick(brickobj[_i],last_hit_x,last_hit_y)
		brickobj[_i].flash=flash_timer
		brickobj[_i].visible=false
		player.points+=10*(player.combo+1)*powerup.multiplier
		combo(_combo)
	--invincible brick
	elseif brickobj[_i].type=="i" then
		sfx(09)
	--hardened brick
	elseif brickobj[_i].type=="h" then
		if powerup.timer.megaball>0 then
			sfx(02+player.combo)
			brickobj[_i].visible=false
			player.points+=10*(player.combo+1)*powerup.multiplier
			combo(_combo)
		else
			sfx(09)
			brickobj[_i].type="b"
		end
	--explosion brick
	elseif brickobj[_i].type=="s" then
		sfx(02+player.combo)
		brickobj[_i].type="zz"				
		player.points+=10*(player.combo+1)*powerup.multiplier
		combo(_combo)
	--powerup brick
	elseif brickobj[_i].type=="p" then
		sfx(02+player.combo)
		shatter_brick(brickobj[_i],last_hit_x,last_hit_y)
		brickobj[_i].flash=flash_timer
		brickobj[_i].visible=false				
		player.points+=10*(player.combo+1)*powerup.multiplier
		combo(_combo)
		spawn_pill(brickobj[_i].x,brickobj[_i].y)
	end
end

function check_for_explosions()
	for i=1,#brickobj do
		if brickobj[i].type=="z" and brickobj[i].visible then
			brick_explode(i)
			--brick explosion effect
			shake+=0.2
			if shake>1 then
				shake=1
			end
		end
	end
	for i=1,#brickobj do
		if brickobj[i].type=="zz" then
			brickobj[i].type="z"
		end
	end
end

function brick_explode(_i)
	brickobj[_i].visible=false
	for j=1,#brickobj do
		if j~=_i 
		and brickobj[j].visible 
		and abs(brickobj[j].x-brickobj[_i].x)<=(brick.width+2)
		and abs(brickobj[j].y-brickobj[_i].y)<=(brick.height+2)
		then
			hit_brick(j,false)
		end
	end
end

function set_angle(_ball,_angle)
	_ball.angle=_angle
	if _angle==2 then
		_ball.dx=0.60*sign(_ball.dx)
		_ball.dy=1.40*sign(_ball.dy)
	elseif angle==0 then
		_ball.dx=1.40*sign(_ball.dx)
		_ball.dy=0.60*sign(_ball.dy)
	else
		_ball.dx=1*sign(_ball.dx)
		_ball.dy=1*sign(_ball.dy)
	end
end

function sign(_number)
	if _number<0 then
		return -1
	elseif _number>0 then
		return 1
	else
		return 0
	end
end

function add_brick(_index,_type)
	local _brickobj={}
	_brickobj.x=4+((_index-1)%11)*(brick.width+2)
	_brickobj.y=20+flr((_index-1)/11)*(brick.height+2)
	_brickobj.offset_x=0
	_brickobj.offset_y=-(128+rnd(128))
	_brickobj.dx=0
	_brickobj.dy=rnd(64)
	_brickobj.visible=true
	_brickobj.flash=0
	_brickobj.type=_type
	add(brickobj,_brickobj)
end

function build_bricks(_lvl)
	local _character,_last,_j,_k
	brickobj={} --change

	_j=0
	for i=1,#_lvl do
		_j+=1
		_character=sub(_lvl,i,i)
		if _character=="b"
		or _character=="i"
		or _character=="h"
		or _character=="s"
		or _character=="p" then
			_last=_character
			add_brick(_j,_character)
		elseif _character=="x" then
			_last="x"
		elseif _character=="/" then
			_j=(flr((_j-1)/11)+1)*11
		elseif _character>="1" and _character<="9" then
			for _k=1,_character+0 do
				if _last=="b"
				or _last=="i"
				or _last=="h"
				or _last=="s"
				or _last=="p" then
					add_brick(_j,_last)
				elseif _last=="x" then
					--create empty space
				end
				_j+=1
			end
			_j-=1 --prevents skipping a line
		end
	end
end

--collosion detection
function hitbox(_bx,_by,_x,_y,_width,_height)
	if _by-ball.radius>_y+_height then
		return false
	end
	if _by+ball.radius<_y then
		return false
	end
	if _bx-ball.radius>_x+_width then
		return false
	end
	if _bx+ball.radius<_x then
		return false
	end
	return true
end

--checks for collision between colliding boxes (pill/paddle)
function boxcollide(_bx1,_by1,_width1,_height1,_bx2,_by2,_width2,_height2)
	if _by1>_by2+_height2 then
		return false
	end
	if _by1+_height1<_by2 then
		return false
	end
	if _bx1>_bx2+_width2 then
		return false
	end
	if _bx1+_width1<_bx2 then
		return false
	end
	return true
end

--checks for correct angle deflection
function deflection(_bx,_by,_bdx,_bdy,_tx,_ty,_tw,_th)
	local _slope=_bdy/_bdx
	local _cx,_cy

	if _bdx==0 then
		--moving vertically
		return false
	elseif _bdy==0 then
		--moving horizontally
		return true
	elseif _slope>0 and _bdx>0 then
		_cx=_tx-_bx
		_cy=_ty-_by
		return _cx>0 and _cy/_cx<_slope
	elseif _slope<0 and _bdx>0 then
		_cx=_tx-_bx
		_cy=_ty+_th-_by
		return _cx>0 and _cy/_cx>=_slope
	elseif _slope>0 and _bdx<0 then
		_cx=_tx+_tw-_bx
		_cy=_ty+_th-_by
		return _cx<0 and _cy/_cx<=_slope
	else
		_cx=_tx+_tw-_bx
		_cy=_ty-_by
		return _cx<0 and _cy/_cx>=_slope
	end
end

-->8
-- juicyness --

function screen_shake()
	local _x=16-rnd(32)
	local _y=16-rnd(32)

	_x*=shake
	_y*=shake

	camera(_x,_y)

	shake*=0.95
	if shake<0.05 then
		shake=0
	end
end

function blink(_blinksequence)
	blink_frame+=1
	if blink_frame>blink_speed then
		blink_frame=0
		blink_seq_index+=1
		if blink_seq_index>#_blinksequence then
			blink_seq_index=1
		end
		blink_color=_blinksequence[blink_seq_index]
	end
end

function animate_arrow()
	arrow_frame+=1
	if arrow_frame>arrow_anim_spd then
		arrow_frame=0
	end
	arrow_mult_01=1+(2*(arrow_frame/arrow_anim_spd))

	local _arrow_frame_2=arrow_frame+(arrow_anim_spd/2)
	if _arrow_frame_2>arrow_anim_spd then
		_arrow_frame_2=_arrow_frame_2-arrow_anim_spd
	end
	arrow_mult_02=1+(2*(_arrow_frame_2/arrow_anim_spd))
end

function fadepal(_perc)
	-- by krystman [#34135#]
	-- create fade by altering
	-- color palette
	-- 0 means normal
	-- 1 is completely black

	-- first we take our argument
	-- and turn it into a 
	-- percentage number (0-100)
	-- also making sure its not
	-- out of bounds  
	local _p=flr(mid(0,_perc,1)*100)

	-- these are helper variables
	local _kmax,_col,_dpal,_j,_k

	-- this is a table to do the
	-- palette shifiting. it tells
	-- what number changes into
	-- what when it gets darker
	-- so number 
	-- 15 becomes 14
	-- 14 becomes 13
	-- 13 becomes 1
	-- 12 becomes 3
	-- etc...
	_dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}

	-- now we go trough all colors
	for _j=1,15 do
		--grab the current color
		_col=_j

		--now calculate how many
		--times we want to fade the
		--color.
		--this is a messy formula
		--and not exact science.
		--but basically when kmax
		--reaches 5 every color gets 
		--turns black.
		_kmax=(_p+(_j*1.46))/22

		--now we send the color 
		--through our table kmax
		--times to derive the final
		--color
		for _k=1,_kmax do
			_col=_dpal[_col]
		end

		--finally, we change the
		--palette
		pal(j,col,1)
	end
end

-->8
-- particles --

function add_particle(_x,_y,_dx,_dy,_type,_lifespan,_color)
	local _p={}
	_p.x=_x
	_p.y=_y
	_p.dx=_dx
	_p.dy=_dy
	_p.type=_type
	_p.lifespan=_lifespan
	_p.age=0	
	_p.color=0 --this is also used to index chunks for type 3
	_p.color_array=_color
	_p.rotate_tmr=0
	_p.rotate=0
	add(ptcl,_p)
end

function update_particles()
	for i=#ptcl,1,-1 do
		local _p=ptcl[i]
		_p.age+=1
		if _p.age>_p.lifespan then
			del(ptcl,ptcl[i])
		--also destroy offscreen particles	
		elseif _p.x<-20 or _p.x>148 then
			del(ptcl,ptcl[i])
		elseif _p.y<-20 or _p.y>148 then
			del(ptcl,ptcl[i])
		else
			--change colors
			if #_p.color_array==1 then
				_p.color=_p.color_array[1]
			else
				--dynamically determine color array index based
				--on lifespand and array size
				local _color_index=_p.age/_p.lifespan
				_color_index=flr(_color_index*#_p.color_array)+1
				_p.color=_p.color_array[_color_index]
			end

			--apply gravity
			if _p.type==1 or _p.type==3 then
				_p.dy+=0.05
			end

			--rotate
			if _p.type==3 then
				_p.rotate_tmr+=1
				if _p.rotate_tmr>3 then
					_p.rotate_tmr=0
					_p.rotate+=1
					if _p.rotate>=4 then
						_p.rotate=0
					end
				end
			end	

			--move particle
			_p.x+=_p.dx
			_p.y+=_p.dy
		end
	end
end

function draw_particles()
	for i=1,#ptcl do
		local _p=ptcl[i]
		--pixel particles
		if _p.type==0 or _p.type==1 then
			pset(_p.x,_p.y,_p.color)
		elseif _p.type==3 then
			local _fx,_fy
			if _p.rotate==2 then
				_fx=false
				_fy=true
			elseif _p.rotate==3 then
				_fx=true
				_fy=true
			elseif _p.rotate==4 then
				_fx=true
				_fy=false
			else
				_fx=false
				_fy=false
			end
			spr(_p.color,_p.x,_p.y,1,1,_fx,_fy)
		end
	end
end

function animate_bricks()
	for i=1,#brickobj do
		local _b=brickobj[i]
		if _b.visible or _b.flash>0 then
			--see if brick is moving
			if _b.dx~=0 or _b.dy~=0 or _b.offset_y~=0 or _b.offset_x~=0 then
				--apply velocity
				_b.offset_x+=_b.dx
				_b.offset_y+=_b.dy

				--pull speed back so brick wants to return to zero
				_b.dx-=_b.offset_x/10
				_b.dy-=_b.offset_y/10

				--dampening
				if abs(_b.dx)>_b.offset_x then
					_b.dx=_b.dx/1.3
				end

				--snap to original position if close
				if abs(_b.dy)>_b.offset_y then
					_b.dy=_b.dy/1.3
				end
				
				if abs(_b.offset_x)<0.2 and abs(_b.dx)<0.2 then
					_b.offset_x=0
					_b.dx=0
				end

				if abs(_b.offset_y)<0.2 and abs(_b.dy)<0.2 then
					_b.offset_y=0
					_b.dy=0
				end
			end
		end
	end
end

function shatter_brick(_brick,_vx,_vy)
	shake=0.06
	sfx(13)
	_brick.dx=_vx*1 --multiplier can be increased to make brick hits fly further
	_brick.dy=_vy*1
	for _x=0,brick.width do
		for _y=0,brick.height do
			if rnd()<0.5 then
				local _angle=rnd()
				local _dx=sin(_angle)*rnd(2)+(_vx*0.5)
				local _dy=cos(_angle)*rnd(2)+(_vy*0.5)
				add_particle(_brick.x+_x,_brick.y+_y,_dx,_dy,1,120,{7,6,5})
			end
		end
	end

	local _chunks=1+flr(rnd(10))
	if _chunks>0 then
		for i=1,_chunks do
			local _angle=rnd()
			local _dx=sin(_angle)*rnd(2)+(_vx*0.5)
			local _dy=cos(_angle)*rnd(2)+(_vy*0.5)
			local _spr=16+flr(rnd(15))
			add_particle(_brick.x,_brick.y,_dx,_dy,3,80,{_spr})
		end
	end
end

function spawn_trail(_x,_y)
	--use trig to make sure particles spawn *around* ball
	--(not in a square around the ball)
	if rnd()<0.5 then
		local _angle=rnd()
		local _offset_x=sin(_angle)*ball.radius*0.5
		local _offset_y=cos(_angle)*ball.radius*0.5
		add_particle(_x+_offset_x,_y+_offset_y,0,0,0,15+rnd(15),{10,9})
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000070700000777000000070000000000000000000000070000000000000000000000000000007000000000000000070000000700000000000
00007700007700000077770000077700000777000077000000077700000777000007700000077000000070000007700000077700000770000007777000000000
00077700000770000007700000007000007770000070000000000700000000000007700000070000000770000007700000077000000777000007777000000000
00007000000000000007000000000000000000000000000000000000000000000000000000070000007700000000000000000000000707000077770000000000
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
0008000013017130171f0271f027140271402721037210371503715047230472304717057170572505725057105070e5070c5070b5070a507085070750705507035070350701507150071600718007190071c007
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003d6302d6301f6301a630126200f6150d6240a615096140861507614006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

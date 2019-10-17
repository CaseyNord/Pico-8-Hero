pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- goals --
--return to main menu from gameover
--ui
--	powerup messages
--	powerup percentage bar
--gameplay tweaks
--	- smaller paddle
--level design	
--good to have:
--sound:
--	- level over finale
--  - start screen music
--  - game win music
--better collision

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

	cartdata("nord_breakout_1")
	manager={
		mode="startmenu",
		level_number=1,
		debug=false
	}

	-- globals --
	debug_var=""
	shake=0
	countdown=-1
	arrow_anim_spd=30
	arrow_frame=0
	arrow_mult_01=1
	arrow_mult_02=1
	gameover_countdown=-1
	gameover_restart=false
	blink_frame=0
	blink_speed=9
	blink_green=7
	blink_green_index=1
	blink_seq_green={3,11,7,11}
	blink_orange=7
	blink_orange_index=1
	blink_seq_orange={10,9,7,9}
	blink_white=7
	blink_white_index=1
	blink_seq_white={5,6,7,6}
	fade_percentage=1

	--set up high score
	high_score={}
	ini1={}
	ini2={}
	ini3={}
	high_score_highlight={true,false,false,false,false}
	--reset_high_score()
	load_high_score()
	high_score_chars={"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
	high_score_x=128
	high_score_dx=128
	log_high_score=false
	confirm_initials=false

	initials={1,1,1}
	selected_initial=0

	level={
		--x = empty space
		--/ = new row
		--b = normal brick
		--i = indestructable brick
		--h = hardened brick
		--s = exploding brick
		--p = powerup brick

		--"s9s"
		-- "s9s//sbsbsbsbsbs//sbsbsbsbsbs//s9s",	
		-- "b9bv9vx9xp9px9xb9bv9vx9xp9p",
		-- "b9bx9xb9bx9xb9b",
		 "s9s/xixbbpbbxix/hphphphphph/bsbsbsbsbsb"
		-- "b9b/xixbbpbbxix/hphphphphph",
		-- "i9i//h9h//b9b//p9p", --test level one
		-- "////xb8xxb8", --lvl 1
		-- "//xbxbxbxbxbxxbxbxbxbxbxxbxbxbxbxbxxbxbxbxbxbx", --lvl 2
		-- "//b9bb9bb9bb9b", --lvl 3
		-- "/bxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxbxb", --lvl 4
		-- "ib3xb3iib3xb3i/ib3xb3iib3xb3i/ib3xb3iib3xb3i", --lvl 5
		-- "ib3xb3iibbsbxbsbbi/ib3xb3iibsbbxbbsbi/ib3xb3iibbsbxbsbbi", --lvl 6
		--"////x4b/i9x", --bonus lvl?
		--"" --empty level?
	}

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

	playarea={
		left=2,
		right=125,
		ceiling=9,
		floor=127
	}

	--global particle table
	ptcl={}
	
	last_hit_x=0 --used with particles
	last_hit_y=0 --used with particles
end

-->8
-- update --

function _update60()
	blink()

	--always update particles so they can always be used!
	update_particles()
	--same with screen shake!
	screen_shake()

	if manager.mode=="game" then
		update_game()
	elseif manager.mode=="startmenu" then
		update_start_menu()
	elseif manager.mode=="levelover" then
		update_level_over()
	elseif manager.mode=="leveloverwait" then
		update_level_over_wait()
	elseif manager.mode=="gameoverwait" then
		update_gameoverwait()
	elseif manager.mode=="gameover" then
		update_gameover()
	elseif manager.mode=="win" then
		update_win()
	elseif manager.mode=="winwait" then
		update_win_wait()
	end
end

-- update functions --

function update_start_menu()
	fade_in()

	--slide in high score list
	if high_score_x~=high_score_dx then
		high_score_x+=(high_score_dx-high_score_x)*0.2
		if abs(high_score_dx-high_score_x)<0.3 then
			high_score_x=high_score_dx
		end
	end
	
	--blinking effects at game start
	if countdown<0 then
		if btnp(5) then
			countdown=80
			blink_speed=1
			sfx(11)
		end
		if btnp(0) then
			if high_score_dx~=0 then
				sfx(20)
			end
			high_score_dx=0
		end
		if btnp(1) then
			if high_score_dx~=128 then
				sfx(20)
			end
			high_score_dx=128
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
	
function update_level_over_wait()
    gameover_countdown-=1 --todo: change name of gameover countdown to something like transition_countdown
    if gameover_countdown<=0 then
        gameover_countdown=-1
        manager.mode="levelover"
    end
end

--todo: this code is repeated both here and in update_gameover... refactor into function and see if possible to pass functions
function update_level_over()
	--blinking effects at level over
	if gameover_countdown<0 then
		if btnp(5) then
			gameover_countdown=80
			blink_speed=1
			sfx(15)
		end
	else
		gameover_countdown-=1
		fade_percentage=(80-gameover_countdown)/80
		if gameover_countdown<= 0then
			gameover_countdown=-1
			blink_speed=9
			pal()
			next_level()
		end
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
		if btnp(4) then
			gameover_countdown=80
			blink_speed=1
			sfx(11)
			gameover_restart=true
		end
		if btnp(5) then
			gameover_countdown=80
			blink_speed=1
			sfx(11)
			gameover_restart=false
		end
	else
		gameover_countdown-=1
		fade_percentage=(80-gameover_countdown)/80
		if gameover_countdown<= 0 then
			gameover_countdown=-1
			blink_speed=9
			pal()
			if gameover_restart then
				start_game()
			else
				--make sure high score menu is hidden
				high_score_x=128
				high_score_dx=128
				start_menu()
			end
		end
	end
end

function update_win_wait()
    gameover_countdown-=1 --todo: change name of gameover countdown to something like transition_countdown
    if gameover_countdown<=0 then
        gameover_countdown=-1
        manager.mode="win"
    end
end

function update_win()
	--blinking effects at level over
	if gameover_countdown<0 then
		if log_high_score then -- show high score interface
			if btnp(0) then --move cursor left
				sfx(17)
				if confirm_initials then
					sfx(19)
					confirm_initials=false
				end
				selected_initial-=1
				if selected_initial<1 then
					selected_initial=3 --todo: selected_initial can be initial_index?
				end
			end
			if btnp(1) then --move cursor right
				sfx(17)
				if confirm_initials then
					sfx(19)
					confirm_initials=false
				end
				selected_initial+=1
				if selected_initial>3 then
					selected_initial=1
				end
			end
			if btnp(2) then --advance chars backward
				sfx(16)
				if confirm_initials then
					sfx(19)
					confirm_initials=false
				end
				initials[selected_initial]-=1
				if initials[selected_initial]<1 then
					initials[selected_initial]=#high_score_chars
				end
			end
			if btnp(3) then --advance chars forward
				sfx(16)
				if confirm_initials then
					sfx(19)
					confirm_initials=false
				end
				initials[selected_initial]+=1
				if initials[selected_initial]>#high_score_chars then
					initials[selected_initial]=1
				end
			end
			if btnp(4) then
				sfx(19)
				confirm_initials=false
			end
			if btnp(5) then
				if confirm_initials then
					add_high_score(player.points,initials[1],initials[2],initials[3])
					save_high_score()
					gameover_countdown=80
					blink_speed=1
					sfx(15)
				else
					sfx(18)
					confirm_initials=true
				end
			end
		else -- show standard end screen
			blink_speed=8
			if btnp(5) then
				gameover_countdown=80
				sfx(15)
			end
		end
	else
		gameover_countdown-=1
		fade_percentage=(80-gameover_countdown)/80
		if gameover_countdown<=0 then
			gameover_countdown=-1
			blink_speed=9 --set speed back for main menu
			pal()
			high_score_x=128
			high_score_dx=0
			start_menu()
		end
	end
end

function update_game()
	fade_in()

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

	for i=#pillobj,1,-1 do --counts backwards so you don't collide when deleting objects
		--move pills
		pillobj[i].y+=pill.speed
		--check for pill falling off stage
		if pillobj[i].y>playarea.floor then
			del(pillobj,pillobj[i])
		--check for pill/paddle collision
		elseif boxcollide(pillobj[i].x,pillobj[i].y,pill.width,pill.height,paddle.x,paddle.y,paddle.width,paddle.height) then
			sfx(10)
			get_powerup(pillobj[i].type)
			spawn_pill_puft(pillobj[i].x,pillobj[i].y,pillobj[i].type)
			del(pillobj,pillobj[i])
		end
	end

	check_for_explosions()

	if level_finished() then
		_draw() --final draw to clear last brick
		if manager.level_number>=#level then
			win_game()
		else
			level_over()
		end
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
			spawn_puft(_nextx,_nexty)
		end
		--check ceiling
		if _nexty<playarea.ceiling then
			_nexty=mid(playarea.ceiling,_nexty,playarea.floor)
			_ballobj.dy=-_ballobj.dy
			sfx(01)
			spawn_puft(_nextx,_nexty)
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
			spawn_puft(_nextx,_nexty)

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
		if powerup.timer.megaball>0 then
			spawn_mega_trail(_nextx,_nexty)
		else
			spawn_trail(_nextx,_nexty)
		end
		
		--check floor
		if _nexty>playarea.floor then
			sfx(00)
			spawn_death(_ballobj.x,_ballobj.y)
			--lose multiball
			if #ballobj>1 then
				shake+=0.1
				del(ballobj,_ballobj)
			else
				--death
				shake+=0.3
				player.lives-=1
				if player.lives<0 then
					player.lives=0
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
	elseif manager.mode=="leveloverwait" then
		draw_game()
	elseif manager.mode=="gameoverwait" then
		draw_game()
	elseif manager.mode=="gameover" then
		draw_gameover()
	elseif manager.mode=="win" then
		draw_win()
	elseif manager.mode=="winwait" then
		draw_game()
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
	--print cover art
	palt(14,true)
	spr(64,36+(high_score_x-128),20,7,4)
	palt()
	print("by lazy devs",40+(high_score_x-128),54,1)
	print("bit.ly/lazydevs",34+(high_score_x-128),60,1)
	print_high_score(high_score_x)
	print("press ❎ to start",31,70,blink_green)
	if high_score_x==128 then
		print("press ⬅️ for high scores",17,85,3)
	end
	print("casey nord - 2019",30,122,1)
end

function draw_level_over()
	rectfill(0,49,127,62,0)
	print("stage clear!",40,50,7)
	print("press ❎ to continue",24,57,blink_green)
end

function draw_gameover()
	rectfill(0,49,127,69,0)
	print("gameover!",48,50,7)
	local _col1,_col2
	if gameover_countdown<0 then
		_col1=blink_white
		_col2=blink_white
	else
		if gameover_restart then
			_col1=blink_white
			_col2=5
		else
			_col1=5
			_col2=blink_white
		end
	end
	print("press ❎ to restart",28,57,_col1)
	cprint("press 🅾️ for main menu",64,_col2,1)
end

function draw_win()
	if log_high_score then
		-- one so transition to high score input
		local _y=30
		rectfill(0,_y,128,_y+60,12)
		cprint("★congratulations!★",_y+4,5,2)
		cprint("you have beaten the game",_y+16,7)
		cprint("and earned a high score!",_y+22,7)
		cprint("enter your initials",_y+28,7)
		local _colors={7,7,7} -- set colors of initials
		if confirm_initials then
			_colors={blink_orange,blink_orange,blink_orange}
		else
			_colors[selected_initial]=blink_orange -- blink selected initial
		end
		print(high_score_chars[initials[1]],59,_y+40,_colors[1])
		print(high_score_chars[initials[2]],63,_y+40,_colors[2])
		print(high_score_chars[initials[3]],67,_y+40,_colors[3])
		if confirm_initials then
			cprint("press ❎ to confirm",_y+52,blink_orange,1)
		else
			cprint("press ⬅️➡️❎🅾️ to set",_y+52,6,4)
		end
	else
		-- won but no high score
		local _y=30
		rectfill(0,_y,128,_y+48,12)
		cprint("★congratulations!★",_y+4,5,2)
		cprint("you have beaten the game",_y+16,7)
		cprint("see if you can get",_y+22,7)
		cprint("a higher score!",_y+28,7)
		cprint("press ❎ for main menu",_y+40,blink_orange,1)
	end
end

function draw_game()
	rectfill(0,0,127,127,1)

	--draw bricks
	local _use_sprite=false
	local _spr_index_x
	for i=1,#brickobj do
		local _b=brickobj[i]
		if _b.visible or _b.flash>0 then
			local _brick_colour
			if _b.flash>0 then
				_brick_colour=7
				_b.flash-=1
			elseif _b.type=="b" then
				_use_sprite=false
				_brick_colour=14
			elseif _b.type=="i" then
				_use_sprite=true
				_spr_index_x=74
			elseif _b.type=="h" then
				_use_sprite=true
				_spr_index_x=94
			elseif _b.type=="s" then
				_use_sprite=true
				_spr_index_x=64
			elseif _b.type=="zz" or _b.type=="z" then
				_brick_colour=7
			elseif _b.type=="p" then
				_use_sprite=true
				_spr_index_x=84
			end
			local _bx=_b.x+_b.offset_x
			local _by=_b.y+_b.offset_y
			if _use_sprite then
				palt(0,false)
				sspr(_spr_index_x,0,10,5,_bx,_by)
				palt()
				_use_sprite=false
			else
				rectfill(_bx,_by,_bx+brick.width,_by+brick.height,_brick_colour)
			end
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
		local _ball_color=10
		if powerup.timer.megaball>0 then
			_ball_color=8
		end
		circfill(ballobj[i].x,ballobj[i].y,ball.radius,_ball_color)

	
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
		print("cpu:"..stat(1),0,1,7)
		print(debug_var,64,1,7)
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
	player.points=0
	player.combo=0 --combo chain multiplier
	player.lives=3
	build_bricks(level[manager.level_number])
	serve_ball()
end

function level_over()
	manager.mode="leveloverwait"
	gameover_countdown=60
	blink_frame=0 --resetting this prevents a green frame from appearing
	blink_speed=16
end

function next_level()
	manager.level_number+=1
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
	blink_speed=6
	reset_high_score_highlight(true)
end

function win_game()
	manager.mode="winwait"
	gameover_countdown=60
	blink_frame=0 --resetting this prevents a green frame from appearing
	blink_speed=16

	--check if player earned high score
	if player.points>high_score[5] then
		log_high_score=true
		selected_initial=1 --make sure cursor starts on first char
	else
		log_high_score=false
		reset_high_score_highlight(true)
	end
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
		--todo: at combo 7 can it say 'max', and shake on each hit? (maybe use bump brick?)
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
	_pillobj.type=flr(rnd(7))+1
	--_pillobj.type=3
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
		powerup.timer.megaball=100
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
		bump_brick(brickobj[_i],last_hit_x,last_hit_y,0.4)
		brickobj[_i].flash=flash_timer
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
		shatter_brick(brickobj[_i],last_hit_x,last_hit_y)
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
		if brickobj[i].type=="zz" then
			brickobj[i].type="z"
		end
	end

	for i=1,#brickobj do
		if brickobj[i].type=="z" and brickobj[i].visible then
			--brick explosion effect
			brick_explode(i)
			spawn_explosion(brickobj[i].x,brickobj[i].y)
			if shake<0.4 then
				shake+=0.1
			end
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

--collision detection
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

function blink()
	blink_frame+=1
	if blink_frame>blink_speed then
		blink_frame=0

		blink_green_index+=1
		if blink_green_index>#blink_seq_green then
			blink_green_index=1
		end
		blink_green=blink_seq_green[blink_green_index]
		
		blink_orange_index+=1
		if blink_orange_index>#blink_seq_orange then
			blink_orange_index=1
		end
		blink_orange=blink_seq_orange[blink_orange_index]
		
		blink_white_index+=1
		if blink_white_index>#blink_seq_white then
			blink_white_index=1
		end
		blink_white=blink_seq_white[blink_white_index]
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

-- must be called after fadepal to fade screen back in!
function fade_in()
	if fade_percentage~=0 then
		fade_percentage-=0.05
		if fade_percentage<0 then
			fade_percentage=0
		end
	end
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
		pal(_j,_col,1)
	end
end

-->8
-- particles --

--type 0 - static pixel
--type 1 - gravity pixel
--type 2 - ball of smoke
--type 3 - rotating sprite

function add_particle(_x,_y,_dx,_dy,_type,_lifespan,_color,_size)
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
	_p.size=_size
	_p.original_size=_size
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

			--shrink
			if _p.type==2 then
				local _shrink_mult=1-(_p.age/_p.lifespan)
				_p.size=_shrink_mult*_p.original_size
			end

			--friction
			if _p.type==2 then
				_p.dx=_p.dx/1.2
				_p.dy=_p.dy/1.2
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
		elseif _p.type==2 then
			circfill(_p.x,_p.y,_p.size,_p.color)
		--rotating sprite
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

function bump_brick(_brick,_vx,_vy,_mult)
	_brick.dx=_vx*_mult --multiplier can be increased to make brick hits fly further
	_brick.dy=_vy*_mult
end

function shatter_brick(_brick,_vx,_vy)
	--screenshake and sound
	if shake<0.05 then
		shake+=0.06
	end
	sfx(13)

	bump_brick(_brick,_vx,_vy,1)
	for _x=0,brick.width do
		for _y=0,brick.height do
			if rnd()<0.5 then
				local _angle=rnd()
				local _dx=sin(_angle)*rnd(2)+(_vx*0.5)
				local _dy=cos(_angle)*rnd(2)+(_vy*0.5)
				add_particle(_brick.x+_x,_brick.y+_y,_dx,_dy,1,120,{7,6,5},0)
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
			add_particle(_brick.x,_brick.y,_dx,_dy,3,80,{_spr},0)
		end
	end
end

function spawn_trail(_x,_y)
	--use trig to make sure particles spawn *around* ball
	--(not in a square around the ball)
	--for i=0,5 do  --try this for a cool fire tail effect!
	if rnd()<0.5 then
		local _angle=rnd()
		local _offset_x=sin(_angle)*ball.radius*0.5
		local _offset_y=cos(_angle)*ball.radius*0.5
		add_particle(_x+_offset_x,_y+_offset_y,0,0,0,15+rnd(15),{10,9},0)
	end
end

function spawn_mega_trail(_x,_y)
	--use trig to make sure particles spawn *around* ball
	--(not in a square around the ball)
	--for i=0,5 do  --try this for a cool fire tail effect!
	local _angle=rnd()
	local _offset_x=sin(_angle)*ball.radius
	local _offset_y=cos(_angle)*ball.radius
	add_particle(_x+_offset_x,_y+_offset_y,0,0,2,45+rnd(15),{8,2,0},1+rnd(1))
end

--small puft (paddle and walls)
function spawn_puft(_x,_y)
	--use trig to make sure particles spawn *around* ball
	--(not in a square around the ball)
	for i=0,5 do
		local _angle=rnd()
		local _dx=sin(_angle)*0.5
		local _dy=cos(_angle)*0.5
		add_particle(_x,_y,_dx,_dy,2,15+rnd(15),{6,7},1+rnd(2))
	end
end

--colored puft
function spawn_pill_puft(_x,_y,_pill)
	--use trig to make sure particles spawn *around* ball
	--(not in a square around the ball)
	for i=0,20 do
		local _angle=rnd()
		local _dx=sin(_angle)*(1+rnd(2))
		local _dy=cos(_angle)*(1+rnd(2))
		local _color={8,8,8,4,2,0}
					
		if _pill == 1 then
		-- slowdown -- orange
		_color={9,9,4,4,0}
		elseif _pill == 2 then
		-- life -- white
		_color={7,7,6,5,0}
		elseif _pill == 3 then
		-- catch -- green
		_color={11,11,3,3,0}
		elseif _pill == 4 then
		-- expand -- blue
		_color={12,12,5,5,0}
		elseif _pill == 5 then
		-- reduce -- black
		_color={0,0,5,5,6}
		elseif _pill == 6 then
		-- megaball -- red
		_color={8,8,4,2,0}
		else
		-- multiball -- yellow
		local _color={10,10,9,4}
		end

		add_particle(_x,_y,_dx,_dy,2,20+rnd(15),_color,1+rnd(3))
	end
end

--death particles
function spawn_death(_x,_y)
	--use trig to make sure particles spawn *around* ball
	--(not in a square around the ball)
	for i=0,20 do
		local _angle=rnd()
		local _dx=sin(_angle)*(2+rnd(4))
		local _dy=cos(_angle)*(2+rnd(4))
		local _color={10,10,9,4,0}

		add_particle(_x,_y,_dx,_dy,2,80+rnd(15),_color,3+rnd(6))
	end
end

--explosions
function spawn_explosion(_x,_y)
	--use trig to make sure particles spawn *around* ball
	--(not in a square around the ball)
	sfx(12)

	--first smoke
	for i=0,20 do
		local _angle=rnd()
		local _dx=sin(_angle)*(rnd(4))
		local _dy=cos(_angle)*(rnd(4))
		local _color={0,0,5,5,6}

		add_particle(_x,_y,_dx,_dy,2,80+rnd(15),_color,3+rnd(6))
	end
	
	--fireball
	for i=0,30 do
		local _angle=rnd()
		local _dx=sin(_angle)*(1+rnd(4))
		local _dy=cos(_angle)*(1+rnd(4))
		local _color={7,10,9,8,5}

		add_particle(_x,_y,_dx,_dy,2,30+rnd(15),_color,2+rnd(4))
	end
end

-->8
-- ui --

function cprint(_string,_y,_col,_spec_chars)
	local _offset=_spec_chars or 0
	_offset*=2
	local _x=(128-#_string*4)*0.5
	print(_string,_x-_offset,_y,_col)
end

function print_high_score(_x)
	rectfill(_x+29,8,_x+99,16,8)
	print("high scores",_x+43,10,7)
	for i=1,5 do
		--rank
		print(i.." - ",_x+30,14+7*i,1)
		--name
		local _color=7
		if high_score_highlight[i] then
			_color=blink_white
		end
		local _name=high_score_chars[ini1[i]]..high_score_chars[ini2[i]]..high_score_chars[ini3[i]]
		print(_name,_x+45,14+7*i,_color)
		--score
		local _score=" "..high_score[i]
		print(_score,_x+100-(#_score*4),14+7*i,_color)
	end
end


-- high score --

function add_high_score(_score,_c1,_c2,_c3)
	add(high_score,_score)
	add(ini1,_c1)
	add(ini2,_c2)
	add(ini3,_c3)
	reset_high_score_highlight()
	add(high_score_highlight,true)
	sort_high_score()
end

function sort_high_score()
	for i=1,#high_score do
		local j=i
		while j>1 and high_score[j-1]<high_score[j] do
			swap_entries(high_score,j)
			swap_entries(ini1,j)
			swap_entries(ini2,j)
			swap_entries(ini3,j)
			swap_entries(high_score_highlight,j)
			j-=1
		end
	end
end

function swap_entries(_table,_i)
	_table[_i],_table[_i-1]=_table[_i-1],_table[_i]
end

function save_high_score()
	local _slot=1
	--save a 1 to first slot so it can be checked to verify tht data exists
	dset(0,1)
	for i=1,5 do
		dset(_slot,high_score[i])
		dset(_slot+1,ini1[i])
		dset(_slot+2,ini2[i])
		dset(_slot+3,ini3[i])
		_slot+=4
	end
end

function load_high_score()
	local _slot=1
	if dget(0)==1 then
		--if data exists, load it
		for i=1,5 do
			high_score[i]=dget(_slot)
			ini1[i]=dget(_slot+1)
			ini2[i]=dget(_slot+2)
			ini3[i]=dget(_slot+3)
			_slot+=4
		end
		sort_high_score()
		reset_high_score_highlight(true)
	else
		--file must be empty so...
		reset_high_score()	
	end
end

function reset_high_score_highlight(_first_entry)
	for i=1,#high_score_highlight do
		high_score_highlight[i]=false
	end
	if _first_entry then
		high_score_highlight[1]=true
	end
end

function reset_high_score()
	--create default data
	high_score={10,300,200,400,1000}
	ini1={5,3,4,2,1}
	ini2={5,3,4,2,1}
	ini3={5,3,4,2,1}
	save_high_score()
end

__gfx__
0000000006777760067777600677776006777760f677777f06777760067777605aa55aa55a776666666677766667777777777777000000000000000000000000
00000000559949955576777555b33bb555c1c1c5550880055582228555a9aaa59900990099ddddddd6ddccddddddcceeeeeeeeee000000000000000000000000
00700700559499955576777555b3bbb555cc1cc5550808055582228555a9aaa59009900990dddd6dddddccddccddcceeeeeeeeee000000000000000000000000
00077000559949955576777555b3bbb555cc1cc5550880055582828555a99aa50099009900d6ddddddd6ccddddddcceeeeeeeeee000000000000000000000000
00077000559499955576677555b33bb555c1c1c5550808055582828555a99aa504400440045555555555ddd5555ddddddddddddd000000000000000000000000
00700700059999500577775005bbbb5005cccc50f500005f0588885005aaaa500000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000070700000777000000070000000000000000000000070000000000000000000000000000007000000000000000070000000700000000000
00007700007700000077770000077700000777000077000000077700000777000007700000077000000070000007700000077700000770000007777000000000
00077700000770000007700000007000007770000070000000000700000000000007700000070000000770000007700000077000000777000007777000000000
00007000000000000007000000000000000000000000000000000000000000000000000000070000007700000000000000000000000707000077770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeee7eeeeeeeeeeeeeeeeeee7eeeeeeaa7aaa9ae000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeee77eeeeeeeeeeeeeeeeeeeeeeeeaa7aaa9ae000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeee77eeeeeeeeeeeeeeeeeeeeeeeaaaaa99ae000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeee767eeeeeeeeeeeeeeeeeeee7eaaaa999ae000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeee777eeeeeeeeeeeeeeeeeee7eea9999aee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeee7777eeeeeeeeeeeeeeeeee77eeaaaaeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeee777eeeee7eeeeeeeeeee777eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeee767eeeee7e7ee7ee7e77777777eeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeee777eeeeeeeeeeeeee7777777eeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeee767ee7eeee7e77ee777777eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeee7eee777eee77eee77ee77777eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeee767ee777eeeee77777eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeee7ee777ee777eeee7777eeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee767ee77e7ee777eee7eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeee77e7eeee767eeeeee777eee77eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeee77eeee7ee767e77ee77ee7e77eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeee77eeeeeeeeeeee77e77ee7eeeeeeeee7eee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeee7ee7e777eeee7777eeee777eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeee77eeeeeeeeeee777eeee77777eee777ee7ee77e000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeee777777eeeeee77777777777eeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
11111ee11111ee11111eee111ee111e111ee111ee111e11111111111000000000000000000000000000000000000000000000000000000000000000000000000
177771e177771e177771e17771e1771771e17771e177177117777771000000000000000000000000000000000000000000000000000000000000000000000000
1ddddd11ddddd11dddd11ddddd11dd1dd11ddddd11dd1dd11dddddd1000000000000000000000000000000000000000000000000000000000000000000000000
1dd1dd11dd1dd11dd11e1dd1dd11dd1dd11dd1dd11dd1dd1111dd111000000000000000000000000000000000000000000000000000000000000000000000000
166661e166666116661e1666661166661e16616611661661ee1661ee000000000000000000000000000000000000000000000000000000000000000000000000
1666661166661e16661e1666661166661e16616611661661ee1661ee000000000000000000000000000000000000000000000000000000000000000000000000
1771771177177117711e1771771177177117717711771771ee1771ee000000000000000000000000000000000000000000000000000000000000000000000000
177777117717711777711771771177177117777711777771ee1771ee000000000000000000000000000000000000000000000000000000000000000000000000
177771e177177117777117717711771771e17771ee17771eee1771ee000000000000000000000000000000000000000000000000000000000000000000000000
11111ee111e11e11111e111e111111e111ee111eeee111eeee1111ee000000000000000000000000000000000000000000000000000000000000000000000000
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
00030000166631b663286633466138661126511065124651276520c6520b6421c6421d6420b642096420f642106420764206642096420a6320463203632066320863501614006150061400611006110061100611
000400003d6302d6301f6301a630126200f6150d6240a615096140861507614006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000290502905035040350402403024030240302403029050290503503035030240202402024020240202903029030350203502024010240102401024015035070350701507150071600718007190071c007
000300002805128051310303103036030390301f0301f0302803128031310303103036030390301f0101f01028010280103101031010360103901010010100102801028010310103101036010390161001610016
000300001c7101e7101d7000670000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300001071012710127000670000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000300002805128051310303103036000390001f0001f0002800028000310003100036000390001f0001f00028000280003100031000360003900010000100002800028000310003100036000390001000010000
010300003103031030280512805128000280001f0001f0002800028000310003100036000390001f0001f00028000280003100031000360003900010000100002800028000310003100036000390001000010000
00010000086100b6100f61013610146202962028620266202462022620216200e6200b62008610066100361001610006000460004600086000a6000760001600006000a60009600076000560005600056000b600

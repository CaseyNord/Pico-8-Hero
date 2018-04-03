pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
box_x = 32
box_y = 58
box_w = 64
box_h = 12

ray_x = 0
ray_y = 0
--down right
ray_dx = 2
ray_dy = 2
--down left
--ray_dx = -2
--ray_dy = 2
--up left
--ray_dx = -2
--ray_dy = -2
--up right
--ray_dx = 2
--ray_dy = -2

debug1 = "debug"

function _init()
end

function _update()
	if btn(1) then
		ray_x += 1
	end
	if btn(0) then
		ray_x -= 1
	end
	if btn(2) then
		ray_y -= 1
	end
	if btn(3) then
		ray_y += 1
	end
end

function _draw()
	cls()
	rect(box_x,box_y,box_x+box_w,box_y+box_h,7)
	local px,py = ray_x,ray_y
	repeat
		pset(px,py,8)
		px += ray_dx
		py += ray_dy
	until px < 0 or px > 128 or py < 0 or py > 128
	if deflx_ballbox(ray_x,ray_y,ray_dx,ray_dy,box_x,box_y,box_w,box_h) then
		print("horizontal")
	else
		print("vertical")
	end
	print(debug1)
end

--not used
function hit_ballbox(bx,by,tx,ty,tw,th)
	if bx+ball_r < tx then return false end
	if by+ball_r < ty then return false end
	if bx-ball_r > tx+tw then return false end
	if by-ball_r > ty+th then return false end
	return true
end

function deflx_ballbox(bx,by,bdx,bdy,tx,ty,tw,th)
	--calculate whether to deflect
	--the ball horizontally or
	--vertically when it hits a box
	if bdx == 0 then
		--moving vertically
		return false
	elseif bdy == 0 then
		--moving horizontally
		return true
	else
 	--moving diagonally
 	--calculate slope
 	local slope = bdy / bdx
 	local cx, cy
 	--check variants
 	if slope > 0 and bdx > 0 then
 		--moving down right
 		debug1 = "q1"
 		cx = tx-bx
 		cy = ty-by
 		if (cx <= 0) then
 			return false
 		elseif (cy / cx < slope) then
 			return true
 		else
 			return false
 		end
 	elseif slope < 0 and bdx > 0 then
 		--moving up right
 		debug1 = "q4"
 		cx = tx-bx
 		cy = ty+th-by
 		if (cx <= 0) then
 			return false
 		elseif (cy / cx < slope) then
 			return false
 		else
 			return true
 		end
 	elseif slope > 0 and bdx < 0 then
 		--moving up left
 		debug1 = "q3"
 		cx = tx+tw-bx
 		cy = ty+th-by
 		if (cx >= 0) then
 			return false
 		elseif (cy / cx > slope) then
 			return false
 		else
 			return true
 		end
		elseif (slope < 0 and bdx < 0) then
			--moving left down
 		debug1 = "q2"
 		cx = tx+tw-bx
 		cy = ty-by
 		if (cx >= 0) then
 			return false
 		elseif (cy / cx < slope) then
 			return false
 		else
 			return true
 		end
 	end
 end
 	return false 
end

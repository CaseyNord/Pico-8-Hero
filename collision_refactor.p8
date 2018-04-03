pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

function deflect_paddle(bx,by,bdx,bdy,tx,ty,tw,th)
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
        return c x > 0 and cy/cx >= slope
    elseif slope > 0 and bdx < 0 then
        cx = tx + tw - bx
        cy = ty + th - by
        return cx < 0 and cy/cx <= slope
    else
        cx = tx + tw - bx
        cy = ty - by
        return cx < 0 and cy/cw >= slope
    end
end

function deflect_paddle(bx,by,bdx,bdy,tx,ty,tw,th)
	--calculates whether to deflect
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